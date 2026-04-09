#!/usr/bin/env bash

opencode_json_read_file() {
  local file_path="$1"
  local file_content=""

  if ! IFS= read -r -d '' file_content < "$file_path"; then
    if [[ -n "$file_content" ]] || [[ -s "$file_path" ]]; then
      :
    else
      file_content=""
    fi
  fi

  OPENCODE_JSON_FILE_CONTENT="$file_content"
}

opencode_escape_json_string() {
  local value="$1"

  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\t'/\\t}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\n'/\\n}"

  printf '%s' "$value"
}

opencode_json_quote() {
  local value="$1"
  local escaped_value=""

  escaped_value="$(opencode_escape_json_string "$value")"
  printf '"%s"' "$escaped_value"
}

opencode_json_skip_ws() {
  local text="$1"
  local idx="$2"
  local text_len=${#text}
  local ch=""

  while [[ "$idx" -lt "$text_len" ]]; do
    ch="${text:$idx:1}"
    case "$ch" in
      ' ' | $'\t' | $'\r' | $'\n')
        idx=$((idx + 1))
        ;;
      *)
        break
        ;;
    esac
  done

  printf '%s' "$idx"
}

opencode_json_set_error() {
  OPENCODE_JSON_ERROR="$1"
  return 1
}

opencode_json_parse_string() {
  local text="$1"
  local idx="$2"
  local text_len=${#text}
  local result=""
  local ch=""
  local esc=""
  local hex=""
  local byte=""

  OPENCODE_JSON_STRING_VALUE=""
  OPENCODE_JSON_STRING_END=0

  if [[ "$idx" -ge "$text_len" ]] || [[ "${text:$idx:1}" != '"' ]]; then
    opencode_json_set_error "Expected JSON string"
    return 1
  fi

  idx=$((idx + 1))

  while [[ "$idx" -lt "$text_len" ]]; do
    ch="${text:$idx:1}"

    if [[ "$ch" == '"' ]]; then
      OPENCODE_JSON_STRING_VALUE="$result"
      OPENCODE_JSON_STRING_END=$((idx + 1))
      return 0
    fi

    if [[ "$ch" == '\\' ]]; then
      idx=$((idx + 1))
      if [[ "$idx" -ge "$text_len" ]]; then
        opencode_json_set_error "Unterminated escape sequence in JSON string"
        return 1
      fi

      esc="${text:$idx:1}"
      case "$esc" in
        '"' | '\\' | '/')
          result+="$esc"
          ;;
        b)
          result+=$'\b'
          ;;
        f)
          result+=$'\f'
          ;;
        n)
          result+=$'\n'
          ;;
        r)
          result+=$'\r'
          ;;
        t)
          result+=$'\t'
          ;;
        u)
          if [[ $((idx + 4)) -ge "$text_len" ]]; then
            opencode_json_set_error "Invalid unicode escape in JSON string"
            return 1
          fi
          hex="${text:$((idx + 1)):4}"
          if [[ ! "$hex" =~ ^[0-9A-Fa-f]{4}$ ]]; then
            opencode_json_set_error "Invalid unicode escape in JSON string"
            return 1
          fi
          if [[ "${hex:0:2}" == "00" ]]; then
            printf -v byte '\\x%s' "${hex:2:2}"
            printf -v byte '%b' "$byte"
            result+="$byte"
          else
            result+="\\u$hex"
          fi
          idx=$((idx + 4))
          ;;
        *)
          opencode_json_set_error "Unsupported escape sequence in JSON string"
          return 1
          ;;
      esac
    else
      result+="$ch"
    fi

    idx=$((idx + 1))
  done

  opencode_json_set_error "Unterminated JSON string"
  return 1
}

opencode_json_parse_literal() {
  local text="$1"
  local idx="$2"
  local literal="$3"
  local value_type="$4"
  local literal_len=${#literal}

  if [[ "${text:$idx:$literal_len}" != "$literal" ]]; then
    opencode_json_set_error "Invalid JSON literal"
    return 1
  fi

  OPENCODE_JSON_VALUE_TYPE="$value_type"
  OPENCODE_JSON_VALUE_END=$((idx + literal_len))
  OPENCODE_JSON_STRING_VALUE=""
  return 0
}

opencode_json_parse_number() {
  local text="$1"
  local idx="$2"
  local text_len=${#text}
  local end_idx="$idx"
  local ch=""
  local token=""

  while [[ "$end_idx" -lt "$text_len" ]]; do
    ch="${text:$end_idx:1}"
    case "$ch" in
      ',' | ']' | '}' | ' ' | $'\t' | $'\r' | $'\n')
        break
        ;;
      *)
        end_idx=$((end_idx + 1))
        ;;
    esac
  done

  token="${text:$idx:$((end_idx - idx))}"
  if [[ ! "$token" =~ ^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?$ ]]; then
    opencode_json_set_error "Invalid JSON number"
    return 1
  fi

  OPENCODE_JSON_VALUE_TYPE="number"
  OPENCODE_JSON_VALUE_END=$end_idx
  OPENCODE_JSON_STRING_VALUE=""
  return 0
}

opencode_json_find_value() {
  local text="$1"
  local idx="$2"
  local text_len=${#text}
  local ch=""

  idx="$(opencode_json_skip_ws "$text" "$idx")"

  if [[ "$idx" -ge "$text_len" ]]; then
    opencode_json_set_error "Unexpected end of JSON while parsing value"
    return 1
  fi

  ch="${text:$idx:1}"
  case "$ch" in
    '"')
      if ! opencode_json_parse_string "$text" "$idx"; then
        return 1
      fi
      OPENCODE_JSON_VALUE_TYPE="string"
      OPENCODE_JSON_VALUE_END=$OPENCODE_JSON_STRING_END
      return 0
      ;;
    '{')
      if ! opencode_json_skip_object "$text" "$idx"; then
        return 1
      fi
      OPENCODE_JSON_VALUE_TYPE="object"
      return 0
      ;;
    '[')
      if ! opencode_json_skip_array "$text" "$idx"; then
        return 1
      fi
      OPENCODE_JSON_VALUE_TYPE="array"
      return 0
      ;;
    t)
      opencode_json_parse_literal "$text" "$idx" true boolean
      return $?
      ;;
    f)
      opencode_json_parse_literal "$text" "$idx" false boolean
      return $?
      ;;
    n)
      opencode_json_parse_literal "$text" "$idx" null null
      return $?
      ;;
    *)
      if [[ "$ch" == '-' ]] || [[ "$ch" =~ [0-9] ]]; then
        opencode_json_parse_number "$text" "$idx"
        return $?
      fi
      ;;
  esac

  opencode_json_set_error "Unsupported JSON value"
  return 1
}

opencode_json_skip_object() {
  local text="$1"
  local idx="$2"
  local text_len=${#text}
  local key=""

  if [[ "$idx" -ge "$text_len" ]] || [[ "${text:$idx:1}" != '{' ]]; then
    opencode_json_set_error "Expected JSON object"
    return 1
  fi

  idx=$((idx + 1))

  while true; do
    idx="$(opencode_json_skip_ws "$text" "$idx")"
    if [[ "$idx" -ge "$text_len" ]]; then
      opencode_json_set_error "Existing OpenCode config ended before closing '}'"
      return 1
    fi

    if [[ "${text:$idx:1}" == '}' ]]; then
      OPENCODE_JSON_VALUE_END=$((idx + 1))
      return 0
    fi

    if ! opencode_json_parse_string "$text" "$idx"; then
      return 1
    fi
    key="$OPENCODE_JSON_STRING_VALUE"
    idx="$OPENCODE_JSON_STRING_END"
    idx="$(opencode_json_skip_ws "$text" "$idx")"

    if [[ "$idx" -ge "$text_len" ]] || [[ "${text:$idx:1}" != ':' ]]; then
      opencode_json_set_error "Expected ':' after key '$key' in existing OpenCode config"
      return 1
    fi

    idx=$((idx + 1))
    idx="$(opencode_json_skip_ws "$text" "$idx")"
    if ! opencode_json_find_value "$text" "$idx"; then
      return 1
    fi
    idx="$OPENCODE_JSON_VALUE_END"
    idx="$(opencode_json_skip_ws "$text" "$idx")"

    if [[ "$idx" -ge "$text_len" ]]; then
      opencode_json_set_error "Existing OpenCode config ended before closing '}'"
      return 1
    fi

    if [[ "${text:$idx:1}" == ',' ]]; then
      idx=$((idx + 1))
      continue
    fi

    if [[ "${text:$idx:1}" == '}' ]]; then
      OPENCODE_JSON_VALUE_END=$((idx + 1))
      return 0
    fi

    opencode_json_set_error "Expected ',' or '}' after key '$key' in existing OpenCode config"
    return 1
  done
}

opencode_json_skip_array() {
  local text="$1"
  local idx="$2"
  local text_len=${#text}

  if [[ "$idx" -ge "$text_len" ]] || [[ "${text:$idx:1}" != '[' ]]; then
    opencode_json_set_error "Expected JSON array"
    return 1
  fi

  idx=$((idx + 1))

  while true; do
    idx="$(opencode_json_skip_ws "$text" "$idx")"
    if [[ "$idx" -ge "$text_len" ]]; then
      opencode_json_set_error "Existing OpenCode config ended before closing ']'"
      return 1
    fi

    if [[ "${text:$idx:1}" == ']' ]]; then
      OPENCODE_JSON_VALUE_END=$((idx + 1))
      return 0
    fi

    if ! opencode_json_find_value "$text" "$idx"; then
      return 1
    fi
    idx="$OPENCODE_JSON_VALUE_END"
    idx="$(opencode_json_skip_ws "$text" "$idx")"

    if [[ "$idx" -ge "$text_len" ]]; then
      opencode_json_set_error "Existing OpenCode config ended before closing ']'"
      return 1
    fi

    if [[ "${text:$idx:1}" == ',' ]]; then
      idx=$((idx + 1))
      continue
    fi

    if [[ "${text:$idx:1}" == ']' ]]; then
      OPENCODE_JSON_VALUE_END=$((idx + 1))
      return 0
    fi

    opencode_json_set_error "Expected ',' or ']' while parsing JSON array"
    return 1
  done
}

opencode_json_parse_top_level_object() {
  local text="$1"
  local idx=0
  local text_len=${#text}
  local key_start=0
  local value_start=0
  local member_index=0
  local existing_index=0
  local key=""
  local trailing_idx=0

  OPENCODE_JSON_MEMBER_COUNT=0
  OPENCODE_JSON_MEMBER_KEYS=()
  OPENCODE_JSON_MEMBER_KEY_STARTS=()
  OPENCODE_JSON_MEMBER_VALUE_STARTS=()
  OPENCODE_JSON_MEMBER_VALUE_ENDS=()
  OPENCODE_JSON_MEMBER_VALUE_TYPES=()
  OPENCODE_JSON_OBJECT_START_IDX=0
  OPENCODE_JSON_OBJECT_END_IDX=0

  idx="$(opencode_json_skip_ws "$text" 0)"
  if [[ "$idx" -ge "$text_len" ]] || [[ "${text:$idx:1}" != '{' ]]; then
    opencode_json_set_error "Existing OpenCode config must be a JSON object"
    return 1
  fi

  OPENCODE_JSON_OBJECT_START_IDX=$idx
  idx=$((idx + 1))

  while true; do
    idx="$(opencode_json_skip_ws "$text" "$idx")"
    if [[ "$idx" -ge "$text_len" ]]; then
      opencode_json_set_error "Existing OpenCode config ended before closing '}'"
      return 1
    fi

    if [[ "${text:$idx:1}" == '}' ]]; then
      trailing_idx="$(opencode_json_skip_ws "$text" $((idx + 1)))"
      if [[ "$trailing_idx" -ne "$text_len" ]]; then
        opencode_json_set_error "Existing OpenCode config must not contain trailing content after the top-level object"
        return 1
      fi
      OPENCODE_JSON_OBJECT_END_IDX=$idx
      return 0
    fi

    key_start=$idx
    if ! opencode_json_parse_string "$text" "$idx"; then
      return 1
    fi
    key="$OPENCODE_JSON_STRING_VALUE"
    idx="$OPENCODE_JSON_STRING_END"

    for ((existing_index = 0; existing_index < member_index; existing_index++)); do
      if [[ "${OPENCODE_JSON_MEMBER_KEYS[$existing_index]}" == "$key" ]]; then
        opencode_json_set_error "Existing OpenCode config must not contain duplicate top-level key '$key'"
        return 1
      fi
    done

    idx="$(opencode_json_skip_ws "$text" "$idx")"
    if [[ "$idx" -ge "$text_len" ]] || [[ "${text:$idx:1}" != ':' ]]; then
      opencode_json_set_error "Expected ':' after key '$key' in existing OpenCode config"
      return 1
    fi

    idx=$((idx + 1))
    value_start="$(opencode_json_skip_ws "$text" "$idx")"
    if ! opencode_json_find_value "$text" "$value_start"; then
      return 1
    fi

    OPENCODE_JSON_MEMBER_KEYS[$member_index]="$key"
    OPENCODE_JSON_MEMBER_KEY_STARTS[$member_index]=$key_start
    OPENCODE_JSON_MEMBER_VALUE_STARTS[$member_index]=$value_start
    OPENCODE_JSON_MEMBER_VALUE_ENDS[$member_index]=$OPENCODE_JSON_VALUE_END
    OPENCODE_JSON_MEMBER_VALUE_TYPES[$member_index]="$OPENCODE_JSON_VALUE_TYPE"
    member_index=$((member_index + 1))

    idx="$(opencode_json_skip_ws "$text" "$OPENCODE_JSON_VALUE_END")"
    if [[ "$idx" -ge "$text_len" ]]; then
      opencode_json_set_error "Existing OpenCode config ended before closing '}'"
      return 1
    fi

    if [[ "${text:$idx:1}" == ',' ]]; then
      idx=$((idx + 1))
      continue
    fi

    if [[ "${text:$idx:1}" == '}' ]]; then
      trailing_idx="$(opencode_json_skip_ws "$text" $((idx + 1)))"
      if [[ "$trailing_idx" -ne "$text_len" ]]; then
        opencode_json_set_error "Existing OpenCode config must not contain trailing content after the top-level object"
        return 1
      fi
      OPENCODE_JSON_MEMBER_COUNT=$member_index
      OPENCODE_JSON_OBJECT_END_IDX=$idx
      return 0
    fi

    opencode_json_set_error "Expected ',' or '}' after key '$key' in existing OpenCode config"
    return 1
  done
}

opencode_json_parse_array_items() {
  local text="$1"
  local idx=0
  local text_len=${#text}
  local item_index=0
  local value_start=0

  OPENCODE_JSON_ITEM_COUNT=0
  OPENCODE_JSON_ITEM_TYPES=()
  OPENCODE_JSON_ITEM_RAWS=()
  OPENCODE_JSON_ITEM_STRING_VALUES=()

  idx="$(opencode_json_skip_ws "$text" 0)"
  if [[ "$idx" -ge "$text_len" ]] || [[ "${text:$idx:1}" != '[' ]]; then
    opencode_json_set_error "OpenCode config must contain a singular 'plugin' array"
    return 1
  fi

  idx=$((idx + 1))

  while true; do
    idx="$(opencode_json_skip_ws "$text" "$idx")"
    if [[ "$idx" -ge "$text_len" ]]; then
      opencode_json_set_error "Existing OpenCode config ended before closing ']'"
      return 1
    fi

    if [[ "${text:$idx:1}" == ']' ]]; then
      OPENCODE_JSON_ITEM_COUNT=$item_index
      return 0
    fi

    value_start=$idx
    if ! opencode_json_find_value "$text" "$value_start"; then
      return 1
    fi

    OPENCODE_JSON_ITEM_TYPES[$item_index]="$OPENCODE_JSON_VALUE_TYPE"
    OPENCODE_JSON_ITEM_RAWS[$item_index]="${text:$value_start:$((OPENCODE_JSON_VALUE_END - value_start))}"
    if [[ "$OPENCODE_JSON_VALUE_TYPE" == "string" ]]; then
      OPENCODE_JSON_ITEM_STRING_VALUES[$item_index]="$OPENCODE_JSON_STRING_VALUE"
    else
      OPENCODE_JSON_ITEM_STRING_VALUES[$item_index]=""
    fi
    item_index=$((item_index + 1))

    idx="$(opencode_json_skip_ws "$text" "$OPENCODE_JSON_VALUE_END")"
    if [[ "$idx" -ge "$text_len" ]]; then
      opencode_json_set_error "Existing OpenCode config ended before closing ']'"
      return 1
    fi

    if [[ "${text:$idx:1}" == ',' ]]; then
      idx=$((idx + 1))
      continue
    fi

    if [[ "${text:$idx:1}" == ']' ]]; then
      OPENCODE_JSON_ITEM_COUNT=$item_index
      return 0
    fi

    opencode_json_set_error "Expected ',' or ']' while parsing JSON array"
    return 1
  done
}

opencode_json_detect_newline() {
  local text="$1"

  if [[ "$text" == *$'\r\n'* ]]; then
    OPENCODE_JSON_NEWLINE=$'\r\n'
    return 0
  fi

  OPENCODE_JSON_NEWLINE=$'\n'
}

opencode_json_line_start() {
  local text="$1"
  local idx="$2"

  while [[ "$idx" -gt 0 ]]; do
    if [[ "${text:$((idx - 1)):1}" == $'\n' ]]; then
      break
    fi
    idx=$((idx - 1))
  done

  printf '%s' "$idx"
}

opencode_json_indentation_at() {
  local text="$1"
  local idx="$2"
  local start=""

  start="$(opencode_json_line_start "$text" "$idx")"
  printf '%s' "${text:$start:$((idx - start))}"
}

opencode_json_line_indent() {
  local text="$1"
  local idx="$2"
  local indentation=""
  local indent_only=""
  local ch=""
  local i=0
  local indentation_len=0

  indentation="$(opencode_json_indentation_at "$text" "$idx")"
  indentation_len=${#indentation}

  while [[ "$i" -lt "$indentation_len" ]]; do
    ch="${indentation:$i:1}"
    case "$ch" in
      ' ' | $'\t')
        indent_only+="$ch"
        ;;
      *)
        break
        ;;
    esac
    i=$((i + 1))
  done

  printf '%s' "$indent_only"
}

opencode_prefix_lines() {
  local text="$1"
  local prefix="$2"
  local result=""
  local remainder="$text"
  local line=""

  while [[ "$remainder" == *$'\n'* ]]; do
    line="${remainder%%$'\n'*}"
    result+="$prefix$line"$'\n'
    remainder="${remainder#*$'\n'}"
  done

  result+="$prefix$remainder"
  printf '%s' "$result"
}

opencode_build_normalized_plugin_items() {
  local array_raw="$1"
  local managed_plugin_spec="$2"
  local item_index=0
  local managed_seen=0

  OPENCODE_PLUGIN_NORMALIZED_ITEMS=()
  OPENCODE_PLUGIN_MANAGED_COUNT=0

  if ! opencode_json_parse_array_items "$array_raw"; then
    return 1
  fi

  for ((item_index = 0; item_index < OPENCODE_JSON_ITEM_COUNT; item_index++)); do
    if [[ "${OPENCODE_JSON_ITEM_TYPES[$item_index]}" == "string" ]] && [[ "${OPENCODE_JSON_ITEM_STRING_VALUES[$item_index]}" == "$managed_plugin_spec" ]]; then
      OPENCODE_PLUGIN_MANAGED_COUNT=$((OPENCODE_PLUGIN_MANAGED_COUNT + 1))
      if [[ "$managed_seen" -eq 0 ]]; then
        OPENCODE_PLUGIN_NORMALIZED_ITEMS+=("$(opencode_json_quote "$managed_plugin_spec")")
        managed_seen=1
      fi
      continue
    fi

    OPENCODE_PLUGIN_NORMALIZED_ITEMS+=("${OPENCODE_JSON_ITEM_RAWS[$item_index]}")
  done

  if [[ "$managed_seen" -eq 0 ]]; then
    OPENCODE_PLUGIN_NORMALIZED_ITEMS+=("$(opencode_json_quote "$managed_plugin_spec")")
  fi

  return 0
}

opencode_render_plugin_array() {
  local existing_raw="$1"
  local indent="$2"
  local newline="$3"
  local item_indent="${indent}  "
  local rendered="["
  local rendered_item=""
  local item_index=0
  local item_count=${#OPENCODE_PLUGIN_NORMALIZED_ITEMS[@]}

  if [[ "$existing_raw" != *$'\n'* ]] && [[ "$existing_raw" != *$'\r'* ]]; then
    for ((item_index = 0; item_index < item_count; item_index++)); do
      if [[ "$item_index" -gt 0 ]]; then
        rendered+=", "
      fi
      rendered+="${OPENCODE_PLUGIN_NORMALIZED_ITEMS[$item_index]}"
    done
    rendered+="]"
    printf '%s' "$rendered"
    return 0
  fi

  rendered+="$newline"
  for ((item_index = 0; item_index < item_count; item_index++)); do
    if [[ "$item_index" -gt 0 ]]; then
      rendered+=",$newline"
    fi
    rendered_item="$(opencode_prefix_lines "${OPENCODE_PLUGIN_NORMALIZED_ITEMS[$item_index]}" "$item_indent")"
    rendered+="$rendered_item"
  done
  rendered+="$newline$indent]"

  printf '%s' "$rendered"
}

opencode_insert_plugin_property() {
  local raw_text="$1"
  local plugin_value="$2"
  local member_count="$3"
  local object_end_idx="$4"
  local newline=""
  local gap=""
  local indent=""
  local last_member_index=0
  local object_start_idx=0

  opencode_json_detect_newline "$raw_text"
  newline="$OPENCODE_JSON_NEWLINE"

  if [[ "$member_count" -gt 0 ]]; then
    last_member_index=$((member_count - 1))
    gap="${raw_text:${OPENCODE_JSON_MEMBER_VALUE_ENDS[$last_member_index]}:$((object_end_idx - OPENCODE_JSON_MEMBER_VALUE_ENDS[$last_member_index]))}"
    if [[ "$gap" == *$'\n'* ]] || [[ "$gap" == *$'\r'* ]]; then
      indent="$(opencode_json_indentation_at "$raw_text" "${OPENCODE_JSON_MEMBER_KEY_STARTS[$last_member_index]}")"
      OPENCODE_JSON_RENDERED_TEXT="${raw_text:0:${OPENCODE_JSON_MEMBER_VALUE_ENDS[$last_member_index]}},${gap}${indent}\"plugin\": ${plugin_value}${gap}${raw_text:$object_end_idx}"
      return 0
    fi

    OPENCODE_JSON_RENDERED_TEXT="${raw_text:0:$object_end_idx}, \"plugin\": ${plugin_value}${raw_text:$object_end_idx}"
    return 0
  fi

  object_start_idx=$OPENCODE_JSON_OBJECT_START_IDX
  gap="${raw_text:$((object_start_idx + 1)):$((object_end_idx - object_start_idx - 1))}"
  if [[ "$gap" == *$'\n'* ]] || [[ "$gap" == *$'\r'* ]]; then
    if [[ -n "$gap" ]]; then
      OPENCODE_JSON_RENDERED_TEXT="${raw_text:0:$((object_start_idx + 1))}${gap}  \"plugin\": ${plugin_value}${gap}${raw_text:$object_end_idx}"
    else
      OPENCODE_JSON_RENDERED_TEXT="${raw_text:0:$((object_start_idx + 1))}${newline}  \"plugin\": ${plugin_value}${newline}${raw_text:$object_end_idx}"
    fi
    return 0
  fi

  OPENCODE_JSON_RENDERED_TEXT="${raw_text:0:$object_end_idx}\"plugin\": ${plugin_value}${raw_text:$object_end_idx}"
}

opencode_find_top_level_member_index() {
  local key="$1"
  local member_index=0

  for ((member_index = 0; member_index < OPENCODE_JSON_MEMBER_COUNT; member_index++)); do
    if [[ "${OPENCODE_JSON_MEMBER_KEYS[$member_index]}" == "$key" ]]; then
      printf '%s' "$member_index"
      return 0
    fi
  done

  printf '%s' "-1"
}

opencode_merge_config() {
  local source_config="$1"
  local target_config="$2"
  local managed_plugin_spec="$3"
  local output_path="$4"
  local raw_text=""
  local active_path="$target_config"
  local plugin_index=-1
  local existing_raw=""
  local replacement=""
  local newline=""
  local indent=""

  [[ -f "$source_config" ]] || { OPENCODE_JSON_ERROR="OpenCode build output is missing opencode.json: $source_config"; return 1; }

  if [[ -f "$target_config" ]]; then
    opencode_json_read_file "$target_config"
  else
    active_path="$source_config"
    opencode_json_read_file "$source_config"
  fi
  raw_text="$OPENCODE_JSON_FILE_CONTENT"

  if ! opencode_json_parse_top_level_object "$raw_text"; then
    return 1
  fi

  plugin_index="$(opencode_find_top_level_member_index plugin)"
  if [[ "$plugin_index" -lt 0 ]]; then
    opencode_insert_plugin_property "$raw_text" "[$(opencode_json_quote "$managed_plugin_spec")]" "$OPENCODE_JSON_MEMBER_COUNT" "$OPENCODE_JSON_OBJECT_END_IDX"
    replacement="$OPENCODE_JSON_RENDERED_TEXT"
    printf '%s' "$replacement" > "$output_path"
    return 0
  fi

  if [[ "${OPENCODE_JSON_MEMBER_VALUE_TYPES[$plugin_index]}" != "array" ]]; then
    OPENCODE_JSON_ERROR="Existing OpenCode config must use a singular 'plugin' array: $active_path"
    return 1
  fi

  existing_raw="${raw_text:${OPENCODE_JSON_MEMBER_VALUE_STARTS[$plugin_index]}:$((OPENCODE_JSON_MEMBER_VALUE_ENDS[$plugin_index] - OPENCODE_JSON_MEMBER_VALUE_STARTS[$plugin_index]))}"
  if ! opencode_build_normalized_plugin_items "$existing_raw" "$managed_plugin_spec"; then
    OPENCODE_JSON_ERROR="${OPENCODE_JSON_ERROR:-Existing OpenCode config must use a singular 'plugin' array: $active_path}"
    return 1
  fi

  if [[ "$OPENCODE_PLUGIN_MANAGED_COUNT" -eq 1 ]]; then
    printf '%s' "$raw_text" > "$output_path"
    return 0
  fi

  opencode_json_detect_newline "$raw_text"
  newline="$OPENCODE_JSON_NEWLINE"
  indent="$(opencode_json_line_indent "$raw_text" "${OPENCODE_JSON_MEMBER_KEY_STARTS[$plugin_index]}")"
  replacement="$(opencode_render_plugin_array "$existing_raw" "$indent" "$newline")"
  printf '%s' "${raw_text:0:${OPENCODE_JSON_MEMBER_VALUE_STARTS[$plugin_index]}}${replacement}${raw_text:${OPENCODE_JSON_MEMBER_VALUE_ENDS[$plugin_index]}}" > "$output_path"
}

opencode_validate_static_install() {
  local config_file="$1"
  local managed_plugin_spec="$2"
  local raw_text=""
  local plugin_index=-1
  local plugin_raw=""
  local managed_count=0
  local item_index=0

  opencode_json_read_file "$config_file"
  raw_text="$OPENCODE_JSON_FILE_CONTENT"

  if ! opencode_json_parse_top_level_object "$raw_text"; then
    return 1
  fi

  plugin_index="$(opencode_find_top_level_member_index plugin)"
  if [[ "$plugin_index" -lt 0 ]] || [[ "${OPENCODE_JSON_MEMBER_VALUE_TYPES[$plugin_index]}" != "array" ]]; then
    OPENCODE_JSON_ERROR="OpenCode config must contain a singular 'plugin' array: $config_file"
    return 1
  fi

  plugin_raw="${raw_text:${OPENCODE_JSON_MEMBER_VALUE_STARTS[$plugin_index]}:$((OPENCODE_JSON_MEMBER_VALUE_ENDS[$plugin_index] - OPENCODE_JSON_MEMBER_VALUE_STARTS[$plugin_index]))}"
  if ! opencode_json_parse_array_items "$plugin_raw"; then
    OPENCODE_JSON_ERROR="OpenCode config must contain a singular 'plugin' array: $config_file"
    return 1
  fi

  for ((item_index = 0; item_index < OPENCODE_JSON_ITEM_COUNT; item_index++)); do
    if [[ "${OPENCODE_JSON_ITEM_TYPES[$item_index]}" == "string" ]] && [[ "${OPENCODE_JSON_ITEM_STRING_VALUES[$item_index]}" == "$managed_plugin_spec" ]]; then
      managed_count=$((managed_count + 1))
    fi
  done

  if [[ "$managed_count" -ne 1 ]]; then
    OPENCODE_JSON_ERROR="OpenCode config must contain exactly one managed plugin entry '$managed_plugin_spec': $config_file"
    return 1
  fi

  return 0
}

opencode_find_first_char_index() {
  local text="$1"
  local target_char="$2"
  local text_len=${#text}
  local idx=0

  while [[ "$idx" -lt "$text_len" ]]; do
    if [[ "${text:$idx:1}" == "$target_char" ]]; then
      printf '%s' "$idx"
      return 0
    fi
    idx=$((idx + 1))
  done

  printf '%s' "-1"
}

opencode_abspath() {
  local path="$1"
  local dir=""
  local base=""

  if [[ "$path" == /* ]]; then
    printf '%s' "$path"
    return 0
  fi

  dir="$(dirname "$path")"
  base="$(basename "$path")"
  printf '%s/%s' "$(cd "$dir" 2>/dev/null && pwd -P)" "$base"
}

opencode_path_to_file_uri() {
  local path="$1"
  local absolute_path=""
  local uri="file://"
  local path_len=0
  local idx=0
  local ch=""
  local hex=""

  absolute_path="$(opencode_abspath "$path")"
  path_len=${#absolute_path}

  while [[ "$idx" -lt "$path_len" ]]; do
    ch="${absolute_path:$idx:1}"
    case "$ch" in
      [A-Za-z0-9._~/-])
        uri+="$ch"
        ;;
      *)
        printf -v hex '%02X' "'$ch"
        uri+="%${hex}"
        ;;
    esac
    idx=$((idx + 1))
  done

  printf '%s' "$uri"
}

opencode_validate_runtime_output() {
  local config_file="$1"
  local plugin_file="$2"
  local output_file="$3"
  local raw_output=""
  local json_start=-1
  local json_text=""
  local plugin_uri=""
  local config_path_abs=""
  local plugin_index=-1
  local origins_index=-1
  local plugin_raw=""
  local origins_raw=""
  local item_index=0
  local plugin_count=0
  local matched_origins=0
  local origin_raw=""
  local spec_index=-1
  local source_index=-1
  local origin_spec=""
  local origin_source=""

  opencode_json_read_file "$output_file"
  raw_output="$OPENCODE_JSON_FILE_CONTENT"
  json_start="$(opencode_find_first_char_index "$raw_output" '{')"
  if [[ "$json_start" -lt 0 ]]; then
    OPENCODE_JSON_ERROR="OpenCode debug config did not emit a JSON payload for validation"
    return 1
  fi

  json_text="${raw_output:$json_start}"
  plugin_uri="$(opencode_path_to_file_uri "$plugin_file")"
  config_path_abs="$(opencode_abspath "$config_file")"

  if ! opencode_json_parse_top_level_object "$json_text"; then
    return 1
  fi

  plugin_index="$(opencode_find_top_level_member_index plugin)"
  if [[ "$plugin_index" -lt 0 ]] || [[ "${OPENCODE_JSON_MEMBER_VALUE_TYPES[$plugin_index]}" != "array" ]]; then
    OPENCODE_JSON_ERROR="OpenCode resolved config did not load the managed plugin exactly once: expected $plugin_uri"
    return 1
  fi

  plugin_raw="${json_text:${OPENCODE_JSON_MEMBER_VALUE_STARTS[$plugin_index]}:$((OPENCODE_JSON_MEMBER_VALUE_ENDS[$plugin_index] - OPENCODE_JSON_MEMBER_VALUE_STARTS[$plugin_index]))}"
  if ! opencode_json_parse_array_items "$plugin_raw"; then
    OPENCODE_JSON_ERROR="OpenCode resolved config did not load the managed plugin exactly once: expected $plugin_uri"
    return 1
  fi

  for ((item_index = 0; item_index < OPENCODE_JSON_ITEM_COUNT; item_index++)); do
    if [[ "${OPENCODE_JSON_ITEM_TYPES[$item_index]}" == "string" ]] && [[ "${OPENCODE_JSON_ITEM_STRING_VALUES[$item_index]}" == "$plugin_uri" ]]; then
      plugin_count=$((plugin_count + 1))
    fi
  done

  if [[ "$plugin_count" -ne 1 ]]; then
    OPENCODE_JSON_ERROR="OpenCode resolved config did not load the managed plugin exactly once: expected $plugin_uri"
    return 1
  fi

  origins_index="$(opencode_find_top_level_member_index plugin_origins)"
  if [[ "$origins_index" -lt 0 ]] || [[ "${OPENCODE_JSON_MEMBER_VALUE_TYPES[$origins_index]}" != "array" ]]; then
    OPENCODE_JSON_ERROR="OpenCode resolved config did not expose plugin_origins for the managed plugin"
    return 1
  fi

  origins_raw="${json_text:${OPENCODE_JSON_MEMBER_VALUE_STARTS[$origins_index]}:$((OPENCODE_JSON_MEMBER_VALUE_ENDS[$origins_index] - OPENCODE_JSON_MEMBER_VALUE_STARTS[$origins_index]))}"
  if ! opencode_json_parse_array_items "$origins_raw"; then
    OPENCODE_JSON_ERROR="OpenCode resolved config did not expose plugin_origins for the managed plugin"
    return 1
  fi

  for ((item_index = 0; item_index < OPENCODE_JSON_ITEM_COUNT; item_index++)); do
    if [[ "${OPENCODE_JSON_ITEM_TYPES[$item_index]}" != "object" ]]; then
      continue
    fi

    origin_raw="${OPENCODE_JSON_ITEM_RAWS[$item_index]}"
    if ! opencode_json_parse_top_level_object "$origin_raw"; then
      return 1
    fi

    spec_index="$(opencode_find_top_level_member_index spec)"
    source_index="$(opencode_find_top_level_member_index source)"
    origin_spec=""
    origin_source=""

    if [[ "$spec_index" -ge 0 ]] && [[ "${OPENCODE_JSON_MEMBER_VALUE_TYPES[$spec_index]}" == "string" ]]; then
      if opencode_json_parse_string "$origin_raw" "${OPENCODE_JSON_MEMBER_VALUE_STARTS[$spec_index]}"; then
        origin_spec="$OPENCODE_JSON_STRING_VALUE"
      fi
    fi

    if [[ "$source_index" -ge 0 ]] && [[ "${OPENCODE_JSON_MEMBER_VALUE_TYPES[$source_index]}" == "string" ]]; then
      if opencode_json_parse_string "$origin_raw" "${OPENCODE_JSON_MEMBER_VALUE_STARTS[$source_index]}"; then
        origin_source="$OPENCODE_JSON_STRING_VALUE"
      fi
    fi

    if [[ "$origin_spec" == "$plugin_uri" ]] && [[ -n "$origin_source" ]] && [[ "$(opencode_abspath "$origin_source")" == "$config_path_abs" ]]; then
      matched_origins=$((matched_origins + 1))
    fi
  done

  if [[ "$matched_origins" -ne 1 ]]; then
    OPENCODE_JSON_ERROR="OpenCode resolved config did not report the managed plugin origin from the installed opencode.json"
    return 1
  fi

  return 0
}
