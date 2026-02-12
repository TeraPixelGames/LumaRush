# Master Codex Prompt (LumaRush v1)

You are building **LumaRush**, a Godot 4.x mobile puzzle game (Color Collapse) designed to ship v1 quickly and monetize via AdMob.

## Use the Seed Pack Code
This repo includes a **Codex Seed Pack** under `res://src/` and `res://tests/` that provides *anchor implementations* and APIs.
Do not rewrite them unless necessary. Implement the remaining systems against these APIs.

### Why the seed code exists
- Locks the exact behavior for: feature flags, stem-sync audio layering, match-driven combo envelope, ad cadence mapping, deterministic visual test mode hooks, and screenshot capture.
- Makes GDUnit4 tests deterministic and avoids flaky screenshot diffs.
- Ensures the “slot feel” audio doesn’t drift or click by never restarting stems.

## Non-negotiables
- Premium glass UI; calm white menu; hype gameplay; smooth ramps.
- Procedural gradient background (no image).
- Tiles are translucent glass and show background particles through them.
- Clear VFX uses per-group Pixel Explosion burst overlay (Option A).
- Audio stems in `res://assets/stems/` are looped and must start in sync once.
- AdMob integration uses the provided IDs; interstitial cadence reduces with streak; rewarded saves streak only on reward-earned.
- Include GDUnit4 unit tests + UAT scene tests + deterministic visual test mode + golden screenshots at 1170×2532.

## Audio specifics (use MusicManager seed)
- Call `MusicManager.start_all_synced()` once at boot.
- On Menu/Results: call `MusicManager.set_calm()`.
- On gameplay start: call `MusicManager.set_gameplay()`.
- On each valid match: call `MusicManager.on_match_made()`.
- On high combo threshold crossing: call `MusicManager.maybe_trigger_high_combo_fx()`.

### Track Selection (Main Menu)
Implement a persistent track selector in MainMenu that switches between multiple stem sets.

Folder convention:
`res://assets/stems/<track_id>/{background_layer.ogg,hype_layer.ogg,match_layer.ogg,fx_layer.ogg}`

Persistence:
- SaveStore.selected_track_id (default "glassgrid")
- Allow special `selected_track_id = "off"` to mute Music bus only.

MusicManager requirements:
- Implement `set_track(track_id)`:
- reload the 4 streams from the selected folder
- restart all stems in sync
- preserve current mix intent (CALM in menu)
- if `track_id == "off"`, mute Music bus with `AudioServer.set_bus_mute(music_bus, true)` and do not stop/restart stems
- switching from `off` back to a real track should restore bus mute=false and keep sync behavior

UX rules:
- Track switching allowed in MainMenu only (CALM)
- Disable/lock selector during gameplay for v1

Tests:
- Unit tests for persistence + correct stream paths
- UAT: select `off`/track -> verify state updates and mute state persists through ads pause/resume

## Deliverables
- Working scenes: Boot, MainMenu, Game, Results, Pause, SaveStreak modal.
- Systems: Board logic, RunManager state machine, SaveStore, StreakManager, AdManager (mockable), BackgroundMoodController, VFXManager.
- Tests: unit + UAT + golden screenshot capture + diff.

Proceed in TASKS.md order. Do not skip tests.
