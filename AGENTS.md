# Immersive States Expanded - Agent Rules

Shared rules for every mod in this tree (file encodings, build commands, engine knowledge, git) are in the Modding Manager's `../../AGENTS.md`. `CLAUDE.md` and `GEMINI.md` import this file.

## What this mod is
- Immersive States Expanded for Hearts of Iron IV.
- Standard single-root layout: `descriptor.mod`, `build.ps1`, content folders, `tests/`, `tools/`, `wiki/` at the root; `artifacts/` and `scratch/` are git-ignored.

## Mod invariants
- (mod-specific rules go here, one line each, with register citations such as `[LOAD-010]`)

## Commands beyond build.ps1
- None yet.

## Read when
| Task | Read |
|---|---|
| Publishing to the Workshop | `WORKSHOP_DESCRIPTION_GUIDELINES.md` |

## Engine Knowledge
- Engine facts live in the Modding Manager's register, reached through the user-level `hoi4-modding-knowledge` skill: search it before a new kind of file and before asking for a game launch, cite ids here, never write a fact into this repository.
- Topics this mod leans on: `encoding-and-syntax`, `loading-and-overrides`.
- `tests/Knowledge.Tests.ps1` runs the register's audit for this repository; it is a copy the Manager keeps current.