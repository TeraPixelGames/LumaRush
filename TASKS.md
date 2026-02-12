# LumaRush – TASKS.md (v1 Launch)

## Definition of Done (v1)
- [ ] Can install on Android device, play repeatedly, score saves
- [ ] Premium glass UI + gradient/particles + mood ramps (CALM↔HYPE)
- [ ] Tiles are glassy and show background particles through them
- [ ] Per-group Pixel Explosion pop VFX works and never blocks gameplay
- [ ] AdMob interstitial + rewarded wired and gated by streak cadence; never blocks if not loaded
- [ ] Daily streak tracked; rewarded “save streak” works only on reward-earned
- [ ] Music stems layer correctly and react to matches/combos; ads pause/resume audio cleanly
- [ ] GDUnit4 unit tests + UAT tests pass
- [ ] Golden screenshots captured and compared in deterministic mode

---

## 0) Project Setup
- [ ] Confirm Godot 4.x project settings for mobile portrait (safe area, stretch)
- [ ] Install GDUnit4
- [ ] Add AdMob plugin `godot-sdk-integrations/godot-admob`
- [ ] Create autoloads: SaveStore, StreakManager, AdManager, MusicManager, BackgroundMood, VFXManager, RunManager

---

## 1) Core Game: Board + Rules (Logic First)
- [ ] Grid, flood fill, clear, gravity, refill, no-move detection
- [ ] Spawn guarantees at least 1 move

Unit tests required.

---

## 2) UI Scenes (ScrollSort premium, glass panels)
- [ ] Boot, MainMenu (CALM), Game (HYPE), Results (CALM), Pause, SaveStreak modal

### 2.y Menu Settings: Track Selector (Persistent)
- [ ] Add a Track selector to MainMenu (inline or Settings modal):
- [ ] Displays current track name (e.g., Track 1 / Track 2)
- [ ] Allows selection from an explicit list (v1 hardcoded list) plus `OFF`
- [ ] Persist selection: SaveStore.selected_track_id (default "glassgrid")
- [ ] Changing track triggers MusicManager.set_track(track_id)

Rules:
- [ ] Track switching allowed from MainMenu only (CALM).
- [ ] If attempted in gameplay, disable control or show message.
- [ ] Selecting `OFF` mutes Music bus only (SFX unaffected).
- [ ] Selecting a track from `OFF` restores that track without desync.

Tests:
- [ ] Unit: selection persists across restart (SaveStore roundtrip)
- [ ] Unit: MusicManager loads streams from correct folder for selected track
- [ ] UAT: change track on MainMenu -> confirm selected_track_id changed and MusicManager updated
- [ ] UAT: set `OFF` then run ads pause/resume; Music stays muted

---

## 3) Background + Particles + Mood Ramps
- [ ] Procedural gradient shader; two moods; smooth ramps

---

## 4) Tiles: Glass Look + Feature Flag Blur Modes
- [ ] TILE_BLUR_MODE = LITE/HEAVY; default LITE for release

---

## 5) Clear VFX: Pixel Explosion (Option A)
- [ ] Per-group capture -> sprite overlay -> progress tween

---

## 6) Audio: 95 BPM Stem Layering + Reactive Combo Envelope
Assets:
- res://assets/stems/<track_id>/background_layer.ogg (base)
- res://assets/stems/<track_id>/hype_layer.ogg (gameplay)
- res://assets/stems/<track_id>/match_layer.ogg (match envelope)
- res://assets/stems/<track_id>/fx_layer.ogg (high-combo cymbal accent)

Spec:
- Start all stems in sync once; never restart individually.
- CALM: synth audible, others at floor
- Gameplay: fade bass in
- Match: drums snap to peak then fade; reset on each match
- High combo: fx accent with cooldown
- Ads: duck + pause/resume

Unit tests + UAT required.

### Multi-Track Support
- [ ] Support multiple tracks as folders under `res://assets/stems/<track_id>/`
- [ ] Each track must include: `background_layer.ogg`, `hype_layer.ogg`, `match_layer.ogg`, `fx_layer.ogg`
- [ ] `MusicManager.set_track(track_id)` reloads all 4 stems and restarts them synced
- [ ] Maintain current mix state after switch (CALM volumes in menu; gameplay volumes if ever supported later)
- [ ] Reserve `track_id = "off"` to mute Music bus only (do not stop/restart stems)
- [ ] Ad pause/resume respects selected `off` state (never unmute accidentally)

---

## 7) Persistence: Scores + Daily Streak
- [ ] SaveStore, StreakManager rules, tested

---

## 8) Ads: AdMob Integration + Cadence + Save Streak Rewarded
IDs:
- App ID: ca-app-pub-8413230766502262~8459082393
- Interstitial: ca-app-pub-8413230766502262/4097057758
- Rewarded: ca-app-pub-8413230766502262/8662262377

Cadence:
- streak 0–1: every 1
- 2–3: every 2
- 4–6: every 3
- 7–13: every 4
- 14+: every 5

Rewarded Save Streak:
- Only succeeds on reward-earned callback.

Mock provider required for tests.

---

## 9) Deterministic Visual Test Mode + Golden Screenshots
- [ ] Freeze drift/pulses/particles in Visual Test Mode
- [ ] Capture portrait iPhone goldens at 1170×2532
- [ ] Compare against goldens with tolerance

### Golden Screens Must Pin Track
- [ ] In Visual Test Mode, force `selected_track_id="default"` during screenshot capture
- [ ] Prevent screenshot diffs due to audio/UI labels changing

Required goldens:
- Menu CALM
- Gameplay HYPE (LITE)
- Gameplay HYPE (HEAVY)
- Results CALM
- Save Streak modal
- Pause overlay
