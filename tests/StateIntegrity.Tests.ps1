BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    . (Join-Path $script:RepoRoot 'tools\HoiModBuild.ps1')
    $script:ManagerRoot = Get-ModManagerRoot
    if ($script:ManagerRoot) {
        $script:IntegrityScript = Join-Path $script:ManagerRoot 'Scripts\States\Test-HoiStateIntegrity.ps1'
    }
}

Describe 'State Integrity' {
    It 'Passes Test-HoiStateIntegrity verification, including ids, localisation and building positions, without errors' {
        if (-not $script:ManagerRoot) { Set-ItResult -Skipped -Because 'the Modding Manager is not installed on this machine'; return }
        Test-Path -LiteralPath $script:IntegrityScript | Should -BeTrue
        $report = & $script:IntegrityScript -ModPath $script:RepoRoot -CheckLoadOrder -PassThru
        $report.Passed | Should -BeTrue
        $report.Errors.Count | Should -Be 0
    }
}
