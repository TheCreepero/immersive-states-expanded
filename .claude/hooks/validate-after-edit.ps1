$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path.TrimEnd('\')
$hookInput = [Console]::In.ReadToEnd() | ConvertFrom-Json
$filePath = [string]$hookInput.tool_input.file_path
if (-not $filePath) { exit 0 }
if (-not [System.IO.Path]::IsPathRooted($filePath)) { $filePath = Join-Path $repoRoot $filePath }
$fullPath = [System.IO.Path]::GetFullPath($filePath)
if (-not $fullPath.StartsWith($repoRoot + '\', [System.StringComparison]::OrdinalIgnoreCase)) { exit 0 }
$relativePath = $fullPath.Substring($repoRoot.Length + 1).Replace('\', '/')
$extension = [System.IO.Path]::GetExtension($fullPath).ToLowerInvariant()
if (@('.txt', '.yml', '.mod', '.gui', '.gfx', '.asset') -notcontains $extension) { exit 0 }
if ($relativePath -match '^(tests|tools|wiki|scratch|artifacts|\.claude)/') { exit 0 }
$ErrorActionPreference = 'Continue'
$output = @(& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'build.ps1') -ValidateOnly *>&1 | ForEach-Object { "$_" })
if ($LASTEXITCODE -eq 0) { exit 0 }
$problems = @($output | Where-Object { $_ -match '\[ERROR\]|FAIL|error' } | Select-Object -First 20)
if ($problems.Count -eq 0) { $problems = @($output | Select-Object -Last 20) }
[Console]::Error.WriteLine("build.ps1 -ValidateOnly failed after editing ${relativePath}:")
foreach ($line in $problems) { [Console]::Error.WriteLine($line.Trim()) }
exit 2
