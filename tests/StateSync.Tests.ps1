BeforeAll {
    $modRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
    . (Join-Path $modRoot 'tools\HoiModBuild.ps1')

    $script:ToolsMissing = $null
    $managerRoot = Get-ModManagerRoot
    if (-not $managerRoot) {
        $script:ToolsMissing = 'the Modding Manager is not installed on this machine'
    } else {
        . (Join-Path $managerRoot 'Scripts\Vanilla\HoiVanilla.Common.ps1')
        . (Join-Path $managerRoot 'Scripts\States\HoiStateTools.Common.ps1')
        $script:ReferencesScript = Join-Path $managerRoot 'Scripts\States\Get-HoiStateReferences.ps1'
        $script:IntegrityScript = Join-Path $managerRoot 'Scripts\States\Test-HoiStateIntegrity.ps1'
        try {
            $script:GameRoot = Resolve-Hoi4Install
        } catch {
            $script:ToolsMissing = 'Hearts of Iron IV is not installed on this machine'
        }
    }
}

Describe 'State Reference Discovery Tooling' {
    It 'Detects Rhineland remilitarization focus references for State 42' {
        if ($script:ToolsMissing) { Set-ItResult -Skipped -Because $script:ToolsMissing; return }
        $hits = @(& $script:ReferencesScript -StateId 42 -Type focus -PassThru)

        $hits.Count | Should -BeGreaterThan 0
        $remilitarizeHits = @($hits | Where-Object { $_.Line -match 'is_demilitarized_zone|set_demilitarized_zone' })
        $remilitarizeHits.Count | Should -BeGreaterThan 0
        $remilitarizeHits[0].File | Should -BeLike '*germany.txt*'
    }

    It 'Detects Italian claims on Corsica for State 1' {
        if ($script:ToolsMissing) { Set-ItResult -Skipped -Because $script:ToolsMissing; return }
        $hits = @(& $script:ReferencesScript -StateId 1 -Type focus -PassThru)

        $hits.Count | Should -BeGreaterThan 0
        $italyHits = @($hits | Where-Object { $_.File -like '*italy.txt*' })
        $italyHits.Count | Should -BeGreaterThan 0
    }

    It 'Detects Reichskommissariats Plus puppet decisions for State 220' {
        if ($script:ToolsMissing) { Set-ItResult -Skipped -Because $script:ToolsMissing; return }
        $hits = @(& $script:ReferencesScript -StateId 220 -Mod "2910757018" -Type decision -PassThru)

        $hits.Count | Should -BeGreaterThan 0
        $rkpHits = @($hits | Where-Object { $_.File -like '*reichskommissariat.txt*' })
        $rkpHits.Count | Should -BeGreaterThan 0
    }
}

Describe 'State Reference Summary' {
    It 'Summarises the references of a state with the same total as the detailed rows' {
        if ($script:ToolsMissing) { Set-ItResult -Skipped -Because $script:ToolsMissing; return }
        $rows = @(& $script:ReferencesScript -StateId 1 -Type focus -PassThru)
        $summary = & $script:ReferencesScript -StateId 1 -Type focus -Summary -PassThru

        $summary.Total | Should -Be $rows.Count
        $summary.Files | Should -Be @($rows | Select-Object -ExpandProperty File -Unique).Count
        (@($summary.ByKind) | Measure-Object -Property Count -Sum).Sum | Should -Be $rows.Count
        (@($summary.TopFiles) | Measure-Object -Property Count -Sum).Sum | Should -Be $rows.Count
        $summary.TopFiles[0].Count | Should -BeGreaterOrEqual $summary.TopFiles[-1].Count
    }

    It 'Shows only the first rows of the detailed text output and says how to see more' {
        if ($script:ToolsMissing) { Set-ItResult -Skipped -Because $script:ToolsMissing; return }
        $text = (& $script:ReferencesScript -StateId 1 -Type focus -Limit 3 | Out-String)

        $text | Should -Match 'more result\(s\) not shown \(raise -Limit\)'
    }

    It 'Prints the summary as a few lines' {
        if ($script:ToolsMissing) { Set-ItResult -Skipped -Because $script:ToolsMissing; return }
        $lines = @(& $script:ReferencesScript -StateId 1 -Type focus -Summary -Limit 3)

        $lines.Count | Should -BeLessOrEqual 10
        $lines[0] | Should -Match '^State 1: \d+ reference\(s\) in \d+ file\(s\)$'
    }
}
Describe 'Immersive States Expanded - State Sync Architecture' {
    It 'Validates mod state integrity' {
        if ($script:ToolsMissing) { Set-ItResult -Skipped -Because $script:ToolsMissing; return }
        $report = & $script:IntegrityScript -ModPath $modRoot -PassThru

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

        if (-not $script:ToolsMissing) {
            $baseHighestId = Get-HoiHighestStateId -Folder (Join-Path $script:GameRoot 'history\states')
            $script:CarvedStateIds = @(Get-ChildItem -LiteralPath (Join-Path $modRoot 'history\states') -Filter '*.txt' -File | ForEach-Object {
                    $idMatch = [regex]::Match([System.IO.File]::ReadAllText($_.FullName), '(?m)\bid\s*=\s*(\d+)')
                    if ($idMatch.Success -and [int]$idMatch.Groups[1].Value -gt $baseHighestId) { [int]$idMatch.Groups[1].Value }
                })
        }
    }

    It 'Registers every carved state in the claims and cores effect' {
        if ($script:ToolsMissing) { Set-ItResult -Skipped -Because $script:ToolsMissing; return }
        $block = Get-EffectBlock -Text $effectsText -Name 'ise_sync_claims_and_cores'
        $block | Should -Not -BeNullOrEmpty
        $missing = @($script:CarvedStateIds | Where-Object { $block -notmatch "(?m)^\s*$_\s*=\s*\{" })
        $missing | Should -BeNullOrEmpty -Because "state(s) $($missing -join ', ') have no entry in ise_sync_claims_and_cores"
    }

    It 'Registers every carved state in the control and owner effect' {
        if ($script:ToolsMissing) { Set-ItResult -Skipped -Because $script:ToolsMissing; return }
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
