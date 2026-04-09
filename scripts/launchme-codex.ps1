Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/lib/CodexTransform.ps1"

$repoDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$vaultDir = (Resolve-Path (Join-Path $repoDir '..')).Path

function Info([string]$msg) { Write-Host "[INFO] $msg" }
function Ok([string]$msg) { Write-Host "[OK]   $msg" }
function Warn([string]$msg) { Write-Host "[WARN] $msg" }

if (-not (Test-Path -LiteralPath (Join-Path $repoDir 'agents'))) { throw 'Missing agents/' }
if (-not (Test-Path -LiteralPath (Join-Path $repoDir 'references'))) { throw 'Missing references/' }
if (-not (Test-Path -LiteralPath (Join-Path $repoDir 'AGENTS.md'))) { throw 'Missing AGENTS.md' }

Write-Host 'Codex installer (PowerShell)'
Write-Host "Repo:  $repoDir"
Write-Host "Vault: $vaultDir"

$confirm = Read-Host 'Install to this vault path? [Y/n]'
if ($confirm -match '^[Nn]$') {
  $vaultDir = Read-Host 'Enter full vault path'
  if (-not (Test-Path -LiteralPath $vaultDir)) { throw "Directory not found: $vaultDir" }
}

$existing = Test-Path -LiteralPath (Join-Path $vaultDir '.codex')
if ($existing) {
  Warn 'Existing .codex installation found.'
  $answer = Read-Host 'Continue and overwrite core Codex files? [c/q]'
  if ($answer -notmatch '^[Cc]$') {
    Info 'Installation cancelled'
    exit 0
  }
}

$codexDir = Join-Path $vaultDir '.codex'
$agentsDir = Join-Path $codexDir 'agents'
$refsDir = Join-Path $codexDir 'references'
$skillsDir = Join-Path $codexDir 'skills'
New-Item -ItemType Directory -Force -Path $agentsDir, $refsDir, $skillsDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $vaultDir 'Meta/states') | Out-Null

$oldManifest = Join-Path $agentsDir '.core-manifest'
if (Test-Path -LiteralPath $oldManifest) {
  foreach ($oldName in Get-Content -LiteralPath $oldManifest) {
    if ([string]::IsNullOrWhiteSpace($oldName)) { continue }
    if (Test-Path -LiteralPath (Join-Path $repoDir "agents/$oldName")) { continue }
    $dst = Join-Path $agentsDir $oldName
    if (-not (Test-Path -LiteralPath $dst)) { continue }
    $depDir = Join-Path $codexDir 'deprecated'
    New-Item -ItemType Directory -Force -Path $depDir | Out-Null
    $depName = [IO.Path]::GetFileNameWithoutExtension($oldName) + '-DEPRECATED.md'
    $depPath = Join-Path $depDir $depName
    if (Test-Path -LiteralPath $depPath) { continue }
    Move-Item -LiteralPath $dst -Destination $depPath
    $depContent = Get-Content -Raw -LiteralPath $depPath
    Set-Content -LiteralPath $depPath -Value ("########`nDEPRECATED DO NOT USE`n########`n`n" + $depContent)
    Warn "Deprecated stale Codex agent: $oldName"
  }
}

$manifestLines = New-Object System.Collections.Generic.List[string]
$agentCount = 0
Get-ChildItem -LiteralPath (Join-Path $repoDir 'agents') -Filter *.md -File | ForEach-Object {
  $dst = Join-Path $agentsDir $_.Name
  Convert-ToCodexFile -SourcePath $_.FullName -DestinationPath $dst
  $manifestLines.Add($_.Name)
  $agentCount++
}
Set-Content -LiteralPath $oldManifest -Value $manifestLines
Ok "Installed $agentCount Codex agents"

$userMutable = @('agents-registry.md', 'agents.md')
$refManifest = Join-Path $refsDir '.core-manifest'
$refLines = New-Object System.Collections.Generic.List[string]
$refCount = 0
Get-ChildItem -LiteralPath (Join-Path $repoDir 'references') -Filter *.md -File | ForEach-Object {
  $name = $_.Name
  $dst = Join-Path $refsDir $name
  if ($existing -and (Test-Path -LiteralPath $dst) -and $userMutable.Contains($name)) {
    Warn "Preserving existing $name"
    $refLines.Add($name)
    return
  }
  Convert-ToCodexFile -SourcePath $_.FullName -DestinationPath $dst
  $refLines.Add($name)
  $refCount++
}
Set-Content -LiteralPath $refManifest -Value $refLines
Ok "Installed/updated $refCount Codex references"

$skillCount = 0
Get-ChildItem -LiteralPath (Join-Path $repoDir 'skills') -Directory | ForEach-Object {
  $skillFile = Join-Path $_.FullName 'SKILL.md'
  if (-not (Test-Path -LiteralPath $skillFile)) { return }
  $skillDstDir = Join-Path $skillsDir $_.Name
  New-Item -ItemType Directory -Force -Path $skillDstDir | Out-Null
  Convert-ToCodexFile -SourcePath $skillFile -DestinationPath (Join-Path $skillDstDir 'SKILL.md')
  $skillCount++
}
Ok "Installed $skillCount Codex skills"

$managedHeader = '<!-- managed-by: my-brain-is-full-crew -->'
$generatedAgents = Join-Path $codexDir 'AGENTS.generated.md'
$baseAgents = Get-Content -Raw -LiteralPath (Join-Path $repoDir 'AGENTS.md')
Set-Content -LiteralPath $generatedAgents -Value ($managedHeader + [Environment]::NewLine + $baseAgents)

$vaultAgents = Join-Path $vaultDir 'AGENTS.md'
if (Test-Path -LiteralPath $vaultAgents) {
  $existingAgents = Get-Content -Raw -LiteralPath $vaultAgents
  if ($existingAgents.Contains($managedHeader)) {
    Copy-Item -LiteralPath $generatedAgents -Destination $vaultAgents -Force
    Ok 'Updated managed AGENTS.md'
  } else {
    Warn 'Found existing unmanaged AGENTS.md'
    $a = Read-Host 'Overwrite vault AGENTS.md with Crew dispatcher? [o/s]'
    if ($a -match '^[Oo]$') {
      Copy-Item -LiteralPath $generatedAgents -Destination $vaultAgents -Force
      Ok 'Overwrote AGENTS.md'
    } else {
      Copy-Item -LiteralPath $generatedAgents -Destination (Join-Path $vaultDir 'AGENTS.crew.md') -Force
      Warn 'Wrote AGENTS.crew.md instead'
    }
  }
} else {
  Copy-Item -LiteralPath $generatedAgents -Destination $vaultAgents -Force
  Ok 'Installed AGENTS.md'
}
Remove-Item -LiteralPath $generatedAgents -Force

$mcpAnswer = Read-Host 'Set up Gmail + Google Calendar MCP (.mcp.json)? [y/N]'
if ($mcpAnswer -match '^[Yy]$') {
  $vaultMcp = Join-Path $vaultDir '.mcp.json'
  if (Test-Path -LiteralPath $vaultMcp) {
    Warn '.mcp.json already exists, not overwriting'
  } else {
    Copy-Item -LiteralPath (Join-Path $repoDir '.mcp.json') -Destination $vaultMcp
    Ok 'Created .mcp.json'
  }
}

Write-Host ''
Write-Host 'Codex setup complete.'
Write-Host "Installed to: $codexDir"
Write-Host 'Next steps:'
Write-Host '1) Open Codex CLI inside the vault folder'
Write-Host '2) Ensure AGENTS.md (or AGENTS.crew.md) is active for this vault'
Write-Host '3) Start with: Initialize my vault'
