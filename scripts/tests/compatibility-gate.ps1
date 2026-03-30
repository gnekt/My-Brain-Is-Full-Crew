Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoDir = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("crew-compat-" + [guid]::NewGuid().ToString('N'))
$vaultDir = Join-Path $tmpRoot 'vault'
$workDir = Join-Path $vaultDir 'My-Brain-Is-Full-Crew'

function Assert-True {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

try {
  New-Item -ItemType Directory -Force -Path $vaultDir | Out-Null
  Copy-Item -LiteralPath $repoDir -Destination $workDir -Recurse

  New-Item -ItemType Directory -Force -Path (Join-Path $vaultDir '.claude/agents') | Out-Null
  Set-Content -LiteralPath (Join-Path $vaultDir '.claude/agents/sentinel.md') -Value 'do-not-touch'
  New-Item -ItemType Directory -Force -Path (Join-Path $vaultDir '.claude/references') | Out-Null
  Set-Content -LiteralPath (Join-Path $vaultDir 'CLAUDE.md') -Value 'do-not-touch'

  Push-Location $workDir

  "y`nn" | powershell -NoProfile -ExecutionPolicy Bypass -File scripts/launchme-codex.ps1 | Out-Null
  Assert-True (Test-Path -LiteralPath (Join-Path $vaultDir '.codex/agents')) '.codex/agents missing'
  Assert-True (Test-Path -LiteralPath (Join-Path $vaultDir '.codex/skills')) '.codex/skills missing'
  Assert-True (Test-Path -LiteralPath (Join-Path $vaultDir '.codex/references')) '.codex/references missing'
  Assert-True (Test-Path -LiteralPath (Join-Path $vaultDir 'AGENTS.md')) 'AGENTS.md missing'

  $codexAgents = (Get-ChildItem -LiteralPath (Join-Path $vaultDir '.codex/agents') -Filter *.md -File).Count
  $codexSkills = (Get-ChildItem -LiteralPath (Join-Path $vaultDir '.codex/skills') -Directory).Count
  Assert-True ($codexAgents -eq 8) "Expected 8 Codex agents, got $codexAgents"
  Assert-True ($codexSkills -eq 13) "Expected 13 Codex skills, got $codexSkills"

  $bad = Get-ChildItem -LiteralPath (Join-Path $vaultDir '.codex') -Recurse -File -Include *.md,*.sh,*.ps1 |
    Select-String -Pattern '\.claude/|\bCLAUDE\.md\b|AskUserQuestion|Skill tool|Agent tool' -SimpleMatch:$false -CaseSensitive
  Assert-True (($bad | Measure-Object).Count -eq 0) 'Found unresolved Claude-specific tokens in .codex runtime'

  "c" | powershell -NoProfile -ExecutionPolicy Bypass -File scripts/updateme-codex.ps1 | Out-Null
  Assert-True (Test-Path -LiteralPath (Join-Path $vaultDir '.codex/agents')) '.codex/agents missing after Codex update'

  $sentinel = Get-Content -Raw -LiteralPath (Join-Path $vaultDir '.claude/agents/sentinel.md')
  Assert-True ($sentinel.Trim() -eq 'do-not-touch') 'Codex flow modified existing Claude sentinel file'
  $claudeRoot = Get-Content -Raw -LiteralPath (Join-Path $vaultDir 'CLAUDE.md')
  Assert-True ($claudeRoot.Trim() -eq 'do-not-touch') 'Codex flow modified existing CLAUDE.md'

  Write-Host 'compatibility-gate.ps1 passed'
}
finally {
  Pop-Location -ErrorAction SilentlyContinue
  if (Test-Path -LiteralPath $tmpRoot) {
    Remove-Item -LiteralPath $tmpRoot -Recurse -Force
  }
}
