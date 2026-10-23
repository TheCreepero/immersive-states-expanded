BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:ManagerRoot = (Resolve-Path (Join-Path $script:RepoRoot '..\..')).Path
    $script:IntegrityScript = Join-Path $script:ManagerRoot 'Scripts\States\Test-HoiStateIntegrity.ps1'
}

Describe 'State Integrity' {
    It 'Passes Test-HoiStateIntegrity verification without errors' {
        Test-Path -LiteralPath $script:IntegrityScript | Should -BeTrue
        $report = & $script:IntegrityScript -ModPath $script:RepoRoot -PassThru
        $report.Passed | Should -BeTrue
        $report.Errors.Count | Should -Be 0
    }
}
