$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path.TrimEnd('\')
$hookInput = [Console]::In.ReadToEnd() | ConvertFrom-Json
$filePath = [string]$hookInput.tool_input.file_path
if (-not $filePath) { exit 0 }
if (-not [System.IO.Path]::IsPathRooted($filePath)) { $filePath = Join-Path $repoRoot $filePath }
$fullPath = [System.IO.Path]::GetFullPath($filePath)
if (-not $fullPath.StartsWith($repoRoot + '\', [System.StringComparison]::OrdinalIgnoreCase)) { exit 0 }
$relativePath = $fullPath.Substring($repoRoot.Length + 1).Replace('\', '/')
$syncedPatterns = @('tools/*', 'tests/Knowledge.Tests.ps1')
foreach ($pattern in $syncedPatterns) {
    if ($relativePath -like $pattern) {
        [Console]::Error.WriteLine("$relativePath is synced from the Modding Manager and is overwritten on the next sync. Change it in the Manager instead, or ask the user.")
        exit 2
    }
}
exit 0
