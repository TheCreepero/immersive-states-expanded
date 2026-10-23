# Immersive States Expanded - Agent Rules

Shared rules for every mod in this tree (file encodings, build commands, engine knowledge, git) are in the Modding Manager's `../../AGENTS.md`. `CLAUDE.md` and `GEMINI.md` import this file.

## What this mod is
- Immersive States Expanded for Hearts of Iron IV.
- Standard single-root layout: `descriptor.mod`, `build.ps1`, content folders, `tests/`, `tools/`, `wiki/` at the root; `artifacts/` and `scratch/` are git-ignored.
- `tools/HoiModBuild.ps1` and `tests/Knowledge.Tests.ps1` are synced from the Modding Manager: never edit them here (a hook blocks it), and grep `tools/HoiModBuild.ps1` for the function you need instead of reading all 45 KB of it.

## Mod invariants
- The invariants in `SPEC.md` are the acceptance test for every split; no work is done until `build.ps1 -ValidateOnly`, `build.ps1 -Test` and `Test-HoiStateIntegrity.ps1 -Mod immersive-states-expanded` pass.
- New state ids start at 2000 and a state file replaces the upstream file whole [RT56-005] [LOAD-010]; a naval base needs a coastal province [EQP-005].
- Both compatches (`mods/immersive-states-expanded-rt56-compatch`, and the Reichskommissariat Plus one once created) are updated in the same work as every split.

## Workflow (subagents in `.claude/agents/`)
- Order per region: `researcher` writes `research/<region>.md` (carve proposal with province ids) -> the user approves it -> `implementer` carves, one at a time, never in parallel -> `reviewer` checks the result -> the user does the in-game check.
- The main session orchestrates; subagents cannot start subagents. Researchers for different regions may run in parallel; Implementers may not.
- `implementer` is Haiku and stops after two failed validations; hand-merging compatch conflicts, ports and victory-point edge cases are done by the main session or a Sonnet override.
- `reviewer` is read-only, has no web access, reads the git diff of this repo and the changed compatch repos plus SPEC, AGENTS, the proposal and `tests/`, and does not judge history.

## Git
- These conventions apply when the user asks for a branch or a commit; the Manager's rule still holds that nothing is committed, pushed or merged without the user's word.
- Every region gets its own feature branch from `main`, named `feat/<region-kebab-name>` (for example `feat/france`). The main session creates it before the first `implementer` run; no split work happens on `main`.
- Commit messages follow the Conventional Commits specification: `<type>(<scope>): <description>`, for example `feat(france): split Corsica into northern and southern states`. Use the region as the scope.
- Once the user has confirmed the region's rework in game, its feature branch may be merged into `main`. The merge happens only on the user's word.

## Commands beyond build.ps1
- State scripts live in the Manager's `Scripts/States` and `Scripts/Vanilla`; the `hoi4-state-modding` skill has the commands (`Get-HoiState.ps1`, `New-HoiCarvedState.ps1`, `Sync-HoiStateCompatch.ps1`, `Test-HoiStateIntegrity.ps1`).

## Read when
| Task | Read |
|---|---|
| Splitting a region | `SPEC.md`, then the region's file in `research/` |
| Publishing to the Workshop | `WORKSHOP_DESCRIPTION_GUIDELINES.md` |

## Engine Knowledge
- Engine facts live in the Modding Manager's register, reached through the user-level `hoi4-modding-knowledge` skill: search it before a new kind of file and before asking for a game launch, cite ids here, never write a fact into this repository.
- Topics this mod leans on: `encoding-and-syntax`, `loading-and-overrides`.
- `tests/Knowledge.Tests.ps1` runs the register's audit for this repository; it is a copy the Manager keeps current.