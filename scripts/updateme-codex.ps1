Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/lib/CodexTransform.ps1"

$repoDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$vaultDir = (Resolve-Path (Join-Path $repoDir '..')).Path
$codexDir = Join-Path $vaultDir '.codex'
$agentsDir = Join-Path $codexDir 'agents'
$refsDir = Join-Path $codexDir 'references'
$skillsDir = Join-Path $codexDir 'skills'

function Info([string]$msg) { Write-Host "[INFO] $msg" }
function Ok([string]$msg) { Write-Host "[OK]   $msg" }
function Warn([string]$msg) { Write-Host "[WARN] $msg" }

if (-not (Test-Path -LiteralPath $agentsDir)) { throw "No .codex/agents found in $vaultDir. Run launchme-codex.ps1 first." }

$updateAnswer = Read-Host 'Update Codex core files in this vault? [c/q]'
if ($updateAnswer -notmatch '^[Cc]$') {
  Info 'Update cancelled'
  exit 0
}

$manifest = Join-Path $agentsDir '.core-manifest'
if (Test-Path -LiteralPath $manifest) {
  foreach ($oldName in Get-Content -LiteralPath $manifest) {
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
    Warn "Deprecated removed core agent: $oldName"
  }
}

$agentCount = 0
$manifestLines = New-Object System.Collections.Generic.List[string]
Get-ChildItem -LiteralPath (Join-Path $repoDir 'agents') -Filter *.md -File | ForEach-Object {
  $dst = Join-Path $agentsDir $_.Name
  $tmp = "$dst.tmp"
  Convert-ToCodexFile -SourcePath $_.FullName -DestinationPath $tmp
  if ((-not (Test-Path -LiteralPath $dst)) -or ((Get-FileHash -LiteralPath $tmp).Hash -ne (Get-FileHash -LiteralPath $dst).Hash)) {
    Move-Item -LiteralPath $tmp -Destination $dst -Force
    Info "Updated agent: $($_.Name)"
    $agentCount++
  } else {
    Remove-Item -LiteralPath $tmp -Force
  }
  $manifestLines.Add($_.Name)
}
Set-Content -LiteralPath $manifest -Value $manifestLines

$refManifest = Join-Path $refsDir '.core-manifest'
if (Test-Path -LiteralPath $refManifest) {
  foreach ($oldRef in Get-Content -LiteralPath $refManifest) {
    if ([string]::IsNullOrWhiteSpace($oldRef)) { continue }
    if (Test-Path -LiteralPath (Join-Path $repoDir "references/$oldRef")) { continue }
    $dst = Join-Path $refsDir $oldRef
    if (-not (Test-Path -LiteralPath $dst)) { continue }
    $depDir = Join-Path $codexDir 'deprecated'
    New-Item -ItemType Directory -Force -Path $depDir | Out-Null
    $depName = [IO.Path]::GetFileNameWithoutExtension($oldRef) + '-DEPRECATED.md'
    $depPath = Join-Path $depDir $depName
    if (Test-Path -LiteralPath $depPath) { continue }
    Move-Item -LiteralPath $dst -Destination $depPath
    Warn "Deprecated removed core reference: $oldRef"
  }
}

$userMutable = @('agents-registry.md', 'agents.md')
$refCount = 0
$refLines = New-Object System.Collections.Generic.List[string]
Get-ChildItem -LiteralPath (Join-Path $repoDir 'references') -Filter *.md -File | ForEach-Object {
  $name = $_.Name
  $dst = Join-Path $refsDir $name
  $refLines.Add($name)

  # For mutable files, merge upstream core changes while preserving custom content.
  if ((Test-Path -LiteralPath $dst) -and $userMutable.Contains($name)) {
    $customSection = @()
    $existingLines = Get-Content -LiteralPath $dst
    for ($i = 0; $i -lt $existingLines.Count; $i++) {
      if ($existingLines[$i] -match '^## Custom Agents') {
        $customSection = $existingLines[$i..($existingLines.Count - 1)]
        break
      }
    }

    $customRows = New-Object System.Collections.Generic.List[string]
    if ($name -eq 'agents-registry.md') {
      $coreNames = @('architect', 'scribe', 'sorter', 'seeker', 'connector', 'librarian', 'transcriber', 'postman')
      foreach ($line in $existingLines) {
        if ($line -notmatch '^\|') { continue }
        if ($line -match '^\|[ ]*Name[ ]*\|') { continue }
        if ($line -match '^\|[- :|]+\|?$') { continue }
        $parts = $line.Split('|')
        if ($parts.Length -lt 3) { continue }
        $agentName = $parts[1].Trim()
        if ([string]::IsNullOrWhiteSpace($agentName)) { continue }
        if ($coreNames -contains $agentName) { continue }
        $customRows.Add($line)
      }
    }

    $tmp = "$dst.tmp"
    Convert-ToCodexFile -SourcePath $_.FullName -DestinationPath $tmp

    if (($name -eq 'agents-registry.md') -and ($customRows.Count -gt 0)) {
      $tmpLines = Get-Content -LiteralPath $tmp
      $lastTableIndex = -1
      for ($i = 0; $i -lt $tmpLines.Count; $i++) {
        if ($tmpLines[$i] -match '^\|') { $lastTableIndex = $i }
      }
      if ($lastTableIndex -ge 0) {
        $merged = New-Object System.Collections.Generic.List[string]
        if ($lastTableIndex -ge 0) {
          foreach ($line in $tmpLines[0..$lastTableIndex]) { $merged.Add($line) | Out-Null }
        }
        foreach ($row in $customRows) { $merged.Add($row) | Out-Null }
        if ($lastTableIndex + 1 -lt $tmpLines.Count) {
          foreach ($line in $tmpLines[($lastTableIndex + 1)..($tmpLines.Count - 1)]) { $merged.Add($line) | Out-Null }
        }
        Set-Content -LiteralPath $tmp -Value $merged
      }
    }

    if ($customSection.Count -gt 0) {
      $tmpLines = Get-Content -LiteralPath $tmp
      $customHeaderIndex = -1
      for ($i = 0; $i -lt $tmpLines.Count; $i++) {
        if ($tmpLines[$i] -match '^## Custom Agents') {
          $customHeaderIndex = $i
          break
        }
      }
      if ($customHeaderIndex -ge 0) {
        $merged = New-Object System.Collections.Generic.List[string]
        if ($customHeaderIndex -gt 0) {
          foreach ($line in $tmpLines[0..($customHeaderIndex - 1)]) { $merged.Add($line) | Out-Null }
        }
        foreach ($line in $customSection) { $merged.Add($line) | Out-Null }
        Set-Content -LiteralPath $tmp -Value $merged
      }
    }

    if ((Get-FileHash -LiteralPath $tmp).Hash -ne (Get-FileHash -LiteralPath $dst).Hash) {
      Move-Item -LiteralPath $tmp -Destination $dst -Force
      Info "Updated reference: $name (preserved custom content)"
      $refCount++
    } else {
      Remove-Item -LiteralPath $tmp -Force
    }
    return
  }

  $tmp = "$dst.tmp"
  Convert-ToCodexFile -SourcePath $_.FullName -DestinationPath $tmp
  if ((-not (Test-Path -LiteralPath $dst)) -or ((Get-FileHash -LiteralPath $tmp).Hash -ne (Get-FileHash -LiteralPath $dst).Hash)) {
    Move-Item -LiteralPath $tmp -Destination $dst -Force
    Info "Updated reference: $name"
    $refCount++
  } else {
    Remove-Item -LiteralPath $tmp -Force
  }
}
Set-Content -LiteralPath $refManifest -Value $refLines

$skillCount = 0
Get-ChildItem -LiteralPath (Join-Path $repoDir 'skills') -Directory | ForEach-Object {
  $skillSrc = Join-Path $_.FullName 'SKILL.md'
  if (-not (Test-Path -LiteralPath $skillSrc)) { return }
  $skillDstDir = Join-Path $skillsDir $_.Name
  New-Item -ItemType Directory -Force -Path $skillDstDir | Out-Null
  $dst = Join-Path $skillDstDir 'SKILL.md'
  $tmp = "$dst.tmp"
  Convert-ToCodexFile -SourcePath $skillSrc -DestinationPath $tmp
  if ((-not (Test-Path -LiteralPath $dst)) -or ((Get-FileHash -LiteralPath $tmp).Hash -ne (Get-FileHash -LiteralPath $dst).Hash)) {
    Move-Item -LiteralPath $tmp -Destination $dst -Force
    Info "Updated skill: $($_.Name)"
    $skillCount++
  } else {
    Remove-Item -LiteralPath $tmp -Force
  }
}

$managedHeader = '<!-- managed-by: my-brain-is-full-crew -->'
$generatedAgents = Join-Path $codexDir 'AGENTS.generated.md'
$baseAgents = Get-Content -Raw -LiteralPath (Join-Path $repoDir 'AGENTS.md')
Set-Content -LiteralPath $generatedAgents -Value ($managedHeader + [Environment]::NewLine + $baseAgents)

$vaultAgents = Join-Path $vaultDir 'AGENTS.md'
if (Test-Path -LiteralPath $vaultAgents) {
  $existingAgents = Get-Content -Raw -LiteralPath $vaultAgents
  if ($existingAgents.Contains($managedHeader)) {
    Copy-Item -LiteralPath $generatedAgents -Destination $vaultAgents -Force
    Info 'Updated managed AGENTS.md'
  } else {
    Warn 'Vault AGENTS.md is unmanaged'
    $answer = Read-Host 'Overwrite unmanaged AGENTS.md? [o/s]'
    if ($answer -match '^[Oo]$') {
      Copy-Item -LiteralPath $generatedAgents -Destination $vaultAgents -Force
      Info 'Overwrote AGENTS.md'
    } else {
      Copy-Item -LiteralPath $generatedAgents -Destination (Join-Path $vaultDir 'AGENTS.crew.md') -Force
      Warn 'Wrote AGENTS.crew.md instead'
    }
  }
} else {
  Copy-Item -LiteralPath $generatedAgents -Destination $vaultAgents -Force
  Info 'Installed AGENTS.md'
}
Remove-Item -LiteralPath $generatedAgents -Force

Ok 'Codex update complete'
Write-Host "Updated: $agentCount agent(s), $skillCount skill(s), $refCount reference(s)"
