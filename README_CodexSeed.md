# LumaRush Codex Seed Pack

This zip contains *anchor* files referenced by the Codex master prompt + TASKS.md.
They are intentionally minimal and exist to **lock behavior** for the hardest-to-implement parts:

- Feature flags + config constants (single source of truth)
- Stem-synced music layering + match-triggered combo envelope
- Ad cadence mapping helper
- Mockable ad provider interface (for GDUnit4 tests)
- Deterministic Visual Test Mode hook
- Screenshot capture helper for golden-image UAT

Drop these into your Godot repo (or let Codex create them), then have Codex implement the remaining systems
against their APIs and comments.

> NOTE: These are written for Godot 4.x (GDScript 2.0).
