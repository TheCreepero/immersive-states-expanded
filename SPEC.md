# SPEC: Immersive States Expanded

> Example draft. Lines marked **[inferred]** come from the repo as it is today; lines marked **[confirm]** are guesses you need to settle.

## Goal
Split vanilla Hearts of Iron IV states into smaller, historically grounded states so the map reads closer to real 1936 administrative and regional borders, without changing the balance of any country.

## Scope
- Split existing vanilla states into new states whose ids continue the base's ids without a gap (vanilla: from 1082) [STM-001].
- The parent state keeps its vanilla id, name and victory points; the new state takes provinces from it.
- End goal is to rework the entire map, but work should be done in smaller segments of one country or region at a time (for example: France, Balkans, Scandinavia).
- To maintain gameplay balance, each split preserves the parent's total manpower, buildings, cores and owner. 
- English localisation for every new state name.

## Out of scope
- New countries, focus trees, events or decisions.
- Changes to province shapes (`map/provinces.bmp`, `definition.csv`).
- Non-English localisation.
- Balance changes: no new factories, resources or manpower beyond what the parent state had.

## Interfaces and compatibility
- Game version `1.19.*` (descriptor.mod).
- Vanilla and Road to 56 compatible, as the Workshop template claims. RT56 ships its own state files, so a compatibility patch exists at `C:\dev\Hearts of Iron IV Modding Manager\mods\immersive-states-expanded-rt56-compatch` and needs to be kept up to date with every update made to this mod. Road to 56 owns the ids 1 to 1143, so that version is a complete standalone compatch with its own ids from 1144, enabled instead of this mod and never together with it.
- Supports the local version of Reichskommissariats Plus mod via compatibility patch at `C:\dev\Hearts of Iron IV Modding Manager\mods\immersive-states-expanded-rkplus-compatch` kept up to date alongside this mod.
- Modular state synchronization via `common/on_actions/ise_state_sync.txt` (and `ise_rkplus_sync.txt`) propagates parent state events and focuses (demilitarization clearance, state transfers) to carved child states without overriding monolithic focus files [LOAD-010] [SCR-080] [SCR-082].
- Each split touches the files the engine needs for a state. Look the list up in the `hoi4-modding-knowledge` register instead of writing it here.

## Invariants (each one becomes a test)
1. Every province in a split parent appears in exactly one state.
2. New state ids are unique and continue the highest id of the base the mod sits on, without a gap [STM-001].
3. Manpower, building levels and resources of parent plus children equal the vanilla parent. Infrastructure is a level, not a quantity: the child gets the parent's level, and one level more when it is a single carved-out city (at most 5).
4. Every `STATE_<id>` used in history has a localisation key.
5. `build.ps1 -ValidateOnly`, `tests/Run-Tests.ps1` and `Test-HoiStateIntegrity.ps1 -CheckLoadOrder` pass.
6. Carved child states inherit `set_demilitarized_zone = yes` when taking provinces from a demilitarized base state [SCR-082].
7. Every state has its positions in `map/buildings.txt`, lying in its own provinces, with one of each singleton building [STM-002].
8. No localisation file of the mod has the name of a file of the game or a base mod [STM-003].

## End-to-end check
Start a 1936 game with only this mod enabled. Every split state appears on the map with its name, its owner and its cores. `error.log` has no new state, province or localisation errors compared with a vanilla run. The user will conduct the in-game checks. Reading logs is left to the agent. The map tools and the contiguity check are screens, not proof, and do not replace the in-game check.
