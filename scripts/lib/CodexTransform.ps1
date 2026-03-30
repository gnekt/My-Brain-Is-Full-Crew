Set-StrictMode -Version Latest

function Convert-ToCodexContent {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Content
  )

  $content = $Content
  $content = $content -replace '\.claude/', '.codex/'
  $content = $content -replace '\.claude\b', '.codex'
  $content = $content -replace '\bCLAUDE\.md\b', 'AGENTS.md'
  $content = $content -replace '`Skill` tool', 'skills system'
  $content = $content -replace '`Agent` tool', 'spawn_agent tool'
  $content = $content -replace 'Skill tool', 'skills system'
  $content = $content -replace 'Agent tool', 'spawn_agent tool'
  $content = $content -replace 'AskUserQuestion', 'request_user_input'
  $content = $content -replace 'scripts/launchme\.sh', 'scripts/launchme-codex.sh'
  $content = $content -replace 'scripts/updateme\.sh', 'scripts/updateme-codex.sh'
  $content = $content -replace '`launchme\.sh`', '`launchme-codex.sh`'
  $content = $content -replace '`updateme\.sh`', '`updateme-codex.sh`'
  $content = $content -replace '\blaunchme\.sh\b', 'launchme-codex.sh'
  $content = $content -replace '\bupdateme\.sh\b', 'updateme-codex.sh'
  $content = $content -replace 'Claude Code', 'Codex CLI'
  return $content
}

function Convert-ToCodexFile {
  param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$DestinationPath
  )

  $raw = Get-Content -Raw -LiteralPath $SourcePath
  $transformed = Convert-ToCodexContent -Content $raw
  Set-Content -LiteralPath $DestinationPath -Value $transformed -NoNewline
}
