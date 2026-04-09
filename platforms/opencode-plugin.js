import { join } from "node:path"

const PLATFORM_DIR = ".opencode"
const NOTIFY_TITLE = "My Brain Is Full - Crew"
const NOTIFY_MESSAGE = "OpenCode needs your attention"

function hookScriptPath(ctx, scriptName) {
  return join(ctx.directory, PLATFORM_DIR, "hooks", scriptName)
}

function normalizeText(value) {
  return String(value ?? "").trim()
}

function hookMessage(result, fallback) {
  return normalizeText(result.stderr) || normalizeText(result.stdout) || fallback
}

function uniqueValues(values) {
  return [...new Set(values.filter(Boolean))]
}

function patchFilePaths(patchText) {
  const paths = []

  for (const line of String(patchText ?? "").split("\n")) {
    if (line.startsWith("*** Add File: ")) {
      paths.push(line.slice("*** Add File: ".length).trim())
      continue
    }

    if (line.startsWith("*** Update File: ")) {
      paths.push(line.slice("*** Update File: ".length).trim())
      continue
    }

    if (line.startsWith("*** Delete File: ")) {
      paths.push(line.slice("*** Delete File: ".length).trim())
      continue
    }

    if (line.startsWith("*** Move to: ")) {
      paths.push(line.slice("*** Move to: ".length).trim())
    }
  }

  return uniqueValues(paths)
}

function extractToolTargets(toolName, args, metadata = undefined) {
  const files = []
  const commands = []

  if (args && typeof args === "object") {
    for (const key of ["file_path", "filePath", "path"]) {
      if (typeof args[key] === "string") {
        files.push(args[key])
      }
    }

    if (typeof args.command === "string") {
      commands.push(args.command)
    }

    if (toolName === "apply_patch" && typeof args.patchText === "string") {
      files.push(...patchFilePaths(args.patchText))
    }
  }

  if (metadata && Array.isArray(metadata.files)) {
    for (const file of metadata.files) {
      if (typeof file?.filePath === "string") {
        files.push(file.filePath)
      }
      if (typeof file?.relativePath === "string") {
        files.push(file.relativePath)
      }
    }
  }

  return {
    files: uniqueValues(files),
    commands: uniqueValues(commands),
  }
}

async function runHook(ctx, scriptName, payload) {
  const scriptPath = hookScriptPath(ctx, scriptName)

  if (!(await Bun.file(scriptPath).exists())) {
    return {
      exitCode: 0,
      stdout: "",
      stderr: `missing hook script: ${scriptPath}`,
      skipped: true,
    }
  }

  const subprocess = Bun.spawn(["bash", scriptPath], {
    cwd: ctx.directory,
    env: {
      ...process.env,
      CREW_PLATFORM_DIR: PLATFORM_DIR,
    },
    stdin: new TextEncoder().encode(JSON.stringify(payload)),
    stdout: "pipe",
    stderr: "pipe",
  })

  const [exitCode, stdout, stderr] = await Promise.all([
    subprocess.exited,
    new Response(subprocess.stdout).text(),
    new Response(subprocess.stderr).text(),
  ])

  return {
    exitCode,
    stdout,
    stderr,
    skipped: false,
  }
}

function toolPayload(toolName, toolInput, toolResponse = undefined) {
  const payload = {
    tool_name: toolName,
    tool_input: toolInput ?? {},
  }

  if (toolResponse !== undefined) {
    payload.tool_response = toolResponse
  }

  return payload
}

export const CrewHooks = async (ctx) => {
  return {
    "tool.execute.before": async (input, output) => {
      const { files, commands } = extractToolTargets(input.tool, output.args)

      for (const filePath of files) {
        const result = await runHook(
          ctx,
          "protect-system-files.sh",
          toolPayload(input.tool, { file_path: filePath }),
        )

        if (result.exitCode !== 0) {
          throw new Error(
            hookMessage(
              result,
              "OpenCode Crew blocked this operation to protect managed files.",
            ),
          )
        }
      }

      for (const command of commands) {
        const result = await runHook(
          ctx,
          "protect-system-files.sh",
          toolPayload(input.tool, { command }),
        )

        if (result.exitCode !== 0) {
          throw new Error(
            hookMessage(
              result,
              "OpenCode Crew blocked this operation to protect managed files.",
            ),
          )
        }
      }
    },

    "tool.execute.after": async (input, output) => {
      const { files, commands } = extractToolTargets(
        input.tool,
        input.args,
        output.metadata,
      )
      const warnings = []
      const toolResponse = {
        title: output.title ?? "",
        output: output.output ?? "",
        metadata: output.metadata ?? {},
      }

      for (const filePath of files) {
        const result = await runHook(
          ctx,
          "validate-frontmatter.sh",
          toolPayload(input.tool, { file_path: filePath }, toolResponse),
        )

        if (result.exitCode === 1) {
          warnings.push(
            hookMessage(result, "OpenCode Crew detected a frontmatter issue."),
          )
          continue
        }

        if (result.exitCode !== 0) {
          const message = hookMessage(
            result,
            "OpenCode Crew validate-frontmatter hook failed unexpectedly.",
          )
          console.warn(`[crew-hooks] ${message}`)
        }
      }

      for (const command of commands) {
        const result = await runHook(
          ctx,
          "validate-frontmatter.sh",
          toolPayload(input.tool, { command }, toolResponse),
        )

        if (result.exitCode === 1) {
          warnings.push(
            hookMessage(result, "OpenCode Crew detected a frontmatter issue."),
          )
          continue
        }

        if (result.exitCode !== 0) {
          const message = hookMessage(
            result,
            "OpenCode Crew validate-frontmatter hook failed unexpectedly.",
          )
          console.warn(`[crew-hooks] ${message}`)
        }
      }

      if (warnings.length > 0) {
        const warningText = uniqueValues(warnings).join("\n\n")
        const currentOutput = output.output == null ? "" : String(output.output)

        output.output = currentOutput
          ? `${currentOutput}\n\n${warningText}`
          : warningText
        output.metadata = {
          ...(output.metadata ?? {}),
          crew_frontmatter_warning: true,
        }
      }
    },

    event: async ({ event }) => {
      if (event?.type !== "session.idle") {
        return
      }

      const result = await runHook(ctx, "notify.sh", {
        title: NOTIFY_TITLE,
        message: NOTIFY_MESSAGE,
      })

      if (result.exitCode !== 0 && !result.skipped) {
        const message = hookMessage(
          result,
          "OpenCode Crew notify hook failed unexpectedly.",
        )
        console.warn(`[crew-hooks] ${message}`)
      }
    },
  }
}

export default CrewHooks
