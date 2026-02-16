# LumaRush - TASKS.md (v1 Launch)

## Definition of Done (v1)
- [ ] Can install on Android device, play repeatedly, score saves
- [x] Premium glass UI + gradient/particles + mood ramps (CALM<->HYPE)
- [x] Tiles are glassy and show background particles through them
- [x] Per-group Pixel Explosion pop VFX works and never blocks gameplay
- [ ] AdMob interstitial + rewarded wired and gated by streak cadence; never blocks if not loaded
- [x] Daily streak tracked; rewarded "save streak" works only on reward-earned
- [x] Music stems layer correctly and react to matches/combos; ads pause/resume audio cleanly
- [ ] GDUnit4 unit tests + UAT tests pass
- [ ] Golden screenshots captured and compared in deterministic mode

---

## 0) Project Setup
- [x] Confirm Godot 4.x project settings for mobile portrait (safe area, stretch)
- [x] Install GDUnit4
- [x] Add AdMob plugin `godot-sdk-integrations/godot-admob`
- [x] Create autoloads: SaveStore, StreakManager, AdManager, MusicManager, BackgroundMood, VFXManager, RunManager

---

## 1) Core Game: Board + Rules (Logic First)
- [x] Grid, flood fill, clear, gravity, refill, no-move detection
- [x] Spawn guarantees at least 1 move
- [x] Unit tests

---

## 2) UI Scenes (ScrollSort premium, glass panels)
- [x] Boot, MainMenu (CALM), Game (HYPE), Results (CALM), Pause, SaveStreak modal

### 2.y Menu Settings: Track Selector (Persistent)
- [x] Add a Track selector to MainMenu (inline or Settings modal)
- [x] Displays current track name
- [x] Allows selection from an explicit list plus `off`
- [x] Persist selection: `SaveStore.selected_track_id` (default `glassgrid`)
- [x] Changing track triggers `MusicManager.set_track(track_id)`

Rules:
- [x] Track switching allowed from MainMenu only (CALM)
- [x] Selecting `off` mutes Music bus only (SFX unaffected)
- [x] Selecting a track from `off` restores that track without desync

Tests:
- [x] Unit: selection persists across restart (SaveStore roundtrip)
- [x] Unit: MusicManager loads streams from correct folder for selected track
- [x] UAT: change track on MainMenu updates selected track
- [ ] UAT: set `off` then run ads pause/resume; music stays muted

---

## 3) Background + Particles + Mood Ramps
- [x] Procedural gradient shader; two moods; smooth ramps

---

## 4) Tiles: Glass Look + Feature Flag Blur Modes
- [x] TILE_BLUR_MODE = LITE/HEAVY; default LITE for release

---

## 5) Clear VFX: Pixel Explosion (Option A)
- [x] Per-group capture -> sprite overlay -> progress tween

---

## 6) Audio: 95 BPM Stem Layering + Reactive Combo Envelope
Assets:
- `res://assets/stems/<track_id>/background_layer.ogg` (base)
- `res://assets/stems/<track_id>/hype_layer.ogg` (gameplay)
- `res://assets/stems/<track_id>/match_layer.ogg` (match envelope)
- `res://assets/stems/<track_id>/fx_layer.ogg` (high-combo accent)

Spec:
- [x] Start all stems in sync once; never restart individually
- [x] CALM: background audible, others at floor
- [x] Gameplay: hype fades in
- [x] Match: match layer peaks then decays; resets on each match
- [x] High combo: fx accent with cooldown
- [x] Ads: duck + pause/resume
- [x] Unit tests + UAT coverage present

### Multi-Track Support
- [x] Support multiple tracks under `res://assets/stems/<track_id>/`
- [x] `MusicManager.set_track(track_id)` reloads 4 stems and restarts synced
- [x] Maintain current mix state after switch
- [x] Reserve `track_id = "off"` to mute Music bus only
- [x] Ad pause/resume respects selected `off` state

---

## 7) Persistence: Scores + Daily Streak
- [x] SaveStore and StreakManager implemented and tested

---

## 8) Ads: AdMob Integration + Cadence + Save Streak Rewarded
IDs:
- App ID: `ca-app-pub-8413230766502262~8459082393`
- Interstitial: `ca-app-pub-8413230766502262/4097057758`
- Rewarded: `ca-app-pub-8413230766502262/8662262377`

Cadence:
- streak 0-1: every 1
- 2-3: every 2
- 4-6: every 3
- 7-13: every 4
- 14+: every 5

Rewarded Save Streak:
- [x] Only succeeds on reward-earned callback

Status:
- [x] Mock provider and cadence logic implemented
- [ ] Real device AdMob stability complete (singleton/export/load/show still under active validation)

---

## 9) Deterministic Visual Test Mode + Golden Screenshots
- [x] Freeze drift/pulses/particles in Visual Test Mode
- [x] Capture portrait iPhone target resolution at `1170x2532`
- [x] Compare against goldens with tolerance in UAT

### Golden Screens Must Pin Track
- [x] In Visual Test Mode, force `selected_track_id="default"` for capture stability
- [x] Prevent screenshot diffs due to audio/UI labels changing

Required goldens:
- [ ] Menu CALM
- [ ] Gameplay HYPE (LITE)
- [ ] Gameplay HYPE (HEAVY)
- [ ] Results CALM
- [ ] Save Streak modal
- [ ] Pause overlay

---

## Current Open Items
- [ ] Finalize AdMob on real device (first-load reliability and production fill behavior)
- [ ] Run full GDUnit4 suite and mark pass/fail from actual run output
- [ ] Generate and commit golden screenshot baselines under `tests/goldens/`

## Test Run Status (2026-02-12)
- [ ] Full GDUnit4 suite passing
- [x] Ran full suite via `addons/gdUnit4/runtest.cmd --godot_binary C:\\code\\bin\\godot.exe -a tests`
- [ ] Blocking failure fixed:
  - `tests/uat/TestPowerups.gd::test_depleted_button_reward_grants_that_powerup`
  - Runtime error: `Invalid call. Nonexistent function 'show_rewarded' in base 'Nil'`
  - Source: `src/ads/AdManager.gd:126` (`provider` is null in this path)

---

## Account + Platform Hardening (Cross-Repo)
- [x] Centralize username moderation in `terapixel-platform` identity-gateway (single policy source).
- [x] Wire Nakama username change RPC to identity moderation endpoint (server-to-server).
- [x] Keep collision check in Nakama and coin charging server-side.
- [x] Add username change audit entry shape and operational logging.
- [x] Add rename cooldown/rate-limit safeguards.
- [ ] Add end-to-end smoke test notes: rename -> submit score -> leaderboard name update.
