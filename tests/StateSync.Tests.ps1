BeforeAll {
    $managerRoot = 'C:\dev\Hearts of Iron IV Modding Manager'
    $modRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
    $rkpModPath = 'C:\Users\eetup.DESKTOP-UM7MOIP\Documents\Paradox Interactive\Hearts of Iron IV\mod\frozen_2910757018_2026-10-22'

    . (Join-Path $managerRoot 'Scripts\Vanilla\HoiVanilla.Common.ps1')
    . (Join-Path $managerRoot 'Scripts\States\HoiStateTools.Common.ps1')
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

Describe 'State Reference Summary' {
    It 'Summarises the references of a state with the same total as the detailed rows' {
        $referencesScript = 'C:\dev\Hearts of Iron IV Modding Manager\Scripts\States\Get-HoiStateReferences.ps1'
        $rows = @(& $referencesScript -StateId 1 -Type focus -PassThru)
        $summary = & $referencesScript -StateId 1 -Type focus -Summary -PassThru

        $summary.Total | Should -Be $rows.Count
        $summary.Files | Should -Be @($rows | Select-Object -ExpandProperty File -Unique).Count
        (@($summary.ByKind) | Measure-Object -Property Count -Sum).Sum | Should -Be $rows.Count
        (@($summary.TopFiles) | Measure-Object -Property Count -Sum).Sum | Should -Be $rows.Count
        $summary.TopFiles[0].Count | Should -BeGreaterOrEqual $summary.TopFiles[-1].Count
    }

    It 'Shows only the first rows of the detailed text output and says how to see more' {
        $referencesScript = 'C:\dev\Hearts of Iron IV Modding Manager\Scripts\States\Get-HoiStateReferences.ps1'
        $text = (& $referencesScript -StateId 1 -Type focus -Limit 3 | Out-String)

        $text | Should -Match 'more result\(s\) not shown \(raise -Limit\)'
    }

    It 'Prints the summary as a few lines' {
        $referencesScript = 'C:\dev\Hearts of Iron IV Modding Manager\Scripts\States\Get-HoiStateReferences.ps1'
        $lines = @(& $referencesScript -StateId 1 -Type focus -Summary -Limit 3)

        $lines.Count | Should -BeLessOrEqual 10
        $lines[0] | Should -Match '^State 1: \d+ reference\(s\) in \d+ file\(s\)$'
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

Describe 'Immersive States Expanded - Sync Entries' {
    BeforeAll {
        $effectsPath = Join-Path $modRoot 'common\scripted_effects\ise_state_sync_effects.txt'
        $effectsText = [System.IO.File]::ReadAllText($effectsPath).Replace("`r`n", "`n")

        function Get-EffectBlock {
            param([string]$Text, [string]$Name)

            $start = [regex]::Match($Text, "(?m)^$([regex]::Escape($Name))\s*=\s*\{")
            if (-not $start.Success) {
                return $null
            }
            $depth = 0
            for ($position = $start.Index + $start.Length - 1; $position -lt $Text.Length; $position++) {
                if ($Text[$position] -eq '{') { $depth++ }
                elseif ($Text[$position] -eq '}') {
                    $depth--
                    if ($depth -eq 0) {
                        return $Text.Substring($start.Index, $position - $start.Index + 1)
                    }
                }
            }
            return $null
        }

        $baseHighestId = Get-HoiHighestStateId -Folder (Join-Path (Resolve-Hoi4Install) 'history\states')
        $script:CarvedStateIds = @(Get-ChildItem -LiteralPath (Join-Path $modRoot 'history\states') -Filter '*.txt' -File | ForEach-Object {
                $idMatch = [regex]::Match([System.IO.File]::ReadAllText($_.FullName), '(?m)\bid\s*=\s*(\d+)')
                if ($idMatch.Success -and [int]$idMatch.Groups[1].Value -gt $baseHighestId) { [int]$idMatch.Groups[1].Value }
            })
    }

    It 'Registers every carved state in the claims and cores effect' {
        $block = Get-EffectBlock -Text $effectsText -Name 'ise_sync_claims_and_cores'
        $block | Should -Not -BeNullOrEmpty
        $missing = @($script:CarvedStateIds | Where-Object { $block -notmatch "(?m)^\s*$_\s*=\s*\{" })
        $missing | Should -BeNullOrEmpty -Because "state(s) $($missing -join ', ') have no entry in ise_sync_claims_and_cores"
    }

    It 'Registers every carved state in the control and owner effect' {
        $block = Get-EffectBlock -Text $effectsText -Name 'ise_sync_state_control_changed'
        $block | Should -Not -BeNullOrEmpty
        $missing = @($script:CarvedStateIds | Where-Object { $block -notmatch "(?m)^\s*$_\s*=\s*\{" })
        $missing | Should -BeNullOrEmpty -Because "state(s) $($missing -join ', ') have no entry in ise_sync_state_control_changed"
    }

    It 'Never transfers ownership of a child state just because control of its parent changed' {
        $block = Get-EffectBlock -Text $effectsText -Name 'ise_sync_state_control_changed'
        $block | Should -Not -BeNullOrEmpty
        $block | Should -Not -Match 'transfer_state'
        $block | Should -Match 'set_state_controller'
    }
}