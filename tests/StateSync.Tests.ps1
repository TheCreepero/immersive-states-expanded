BeforeAll {
    $managerRoot = 'C:\dev\Hearts of Iron IV Modding Manager'
    $modRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
    $rkpModPath = 'C:\Users\eetup.DESKTOP-UM7MOIP\Documents\Paradox Interactive\Hearts of Iron IV\mod\frozen_2910757018_2026-10-22'

    . (Join-Path $managerRoot 'Scripts\Vanilla\HoiVanilla.Common.ps1')
}

Describe 'State Reference Discovery Tooling' {
    It 'Detects Rhineland remilitarization focus references for State 42' {
        $referencesScript = 'C:\dev\Hearts of Iron IV Modding Manager\Scripts\States\Get-HoiStateReferences.ps1'
        $hits = @(& $referencesScript -StateId 42 -Type focus -PassThru)

        $hits.Count | Should -BeGreaterThan 0
        $remilitarizeHits = @($hits | Where-Object { $_.Line -match 'is_demilitarized_zone|set_demilitarized_zone' })
        $remilitarizeHits.Count | Should -BeGreaterThan 0
        $remilitarizeHits[0].File | Should -BeLike '*germany.txt*'
    }

    It 'Detects Italian claims on Corsica for State 1' {
        $referencesScript = 'C:\dev\Hearts of Iron IV Modding Manager\Scripts\States\Get-HoiStateReferences.ps1'
        $hits = @(& $referencesScript -StateId 1 -Type focus -PassThru)

        $hits.Count | Should -BeGreaterThan 0
        $italyHits = @($hits | Where-Object { $_.File -like '*italy.txt*' })
        $italyHits.Count | Should -BeGreaterThan 0
    }

    It 'Detects Reichskommissariats Plus puppet decisions for State 220' {
        $referencesScript = 'C:\dev\Hearts of Iron IV Modding Manager\Scripts\States\Get-HoiStateReferences.ps1'
        $hits = @(& $referencesScript -StateId 220 -Mod "2910757018" -Type decision -PassThru)

        $hits.Count | Should -BeGreaterThan 0
        $rkpHits = @($hits | Where-Object { $_.File -like '*reichskommissariat.txt*' })
        $rkpHits.Count | Should -BeGreaterThan 0
    }
}

Describe 'Immersive States Expanded - State Sync Architecture' {
    It 'Validates mod state integrity' {
        $integrityScript = 'C:\dev\Hearts of Iron IV Modding Manager\Scripts\States\Test-HoiStateIntegrity.ps1'
        $report = & $integrityScript -ModPath $modRoot -PassThru

        $report.Passed | Should -BeTrue
        $report.Errors.Count | Should -Be 0
    }

    It 'Enforces UTF-8 without BOM on sync scripts' {
        $syncFiles = @(
            (Join-Path $modRoot 'common\on_actions\ise_state_sync.txt'),
            (Join-Path $modRoot 'common\scripted_effects\ise_state_sync_effects.txt')
        )

        foreach ($file in $syncFiles) {
            Test-Path -LiteralPath $file | Should -BeTrue
            $bytes = [System.IO.File]::ReadAllBytes($file)
            if ($bytes.Length -ge 3) {
                # UTF-8 BOM is 0xEF, 0xBB, 0xBF
                $hasBom = ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
                $hasBom | Should -BeFalse
            }
        }
    }
}

