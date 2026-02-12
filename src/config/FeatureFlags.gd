extends Node
class_name FeatureFlags

# Feature flags / config constants
enum TileBlurMode { LITE, HEAVY }

# Determinism toggles for UAT (override via ProjectSettings at runtime)
const VISUAL_TEST_MODE := false
const AUDIO_TEST_MODE := false

# Performance toggle for tiles
const TILE_BLUR_MODE := TileBlurMode.LITE
const MIN_MATCH_SIZE := 3

# Audio tuning (95 BPM stems)
const BPM := 95
const COMBO_PEAK_DB := -6.0
const COMBO_FLOOR_DB := -60.0
const COMBO_FADE_SECONDS := 1.25
const COMBO_DECAY_DELAY_SECONDS := 1.20
const COMBO_DECAY_SECONDS := 2.2
const COMBO_DECAY_TARGET_DB := COMBO_FLOOR_DB
const FX_COOLDOWN_SECONDS := 1.5
const GAMEPLAY_CALM_RETURN_DELAY_SECONDS := 1.6
const GAMEPLAY_CALM_FADE_SECONDS := 6.0
const MATCH_HINT_DELAY_SECONDS := 3.0
const GAMEPLAY_MATCHES_NORMALIZER := 12.0
const GAMEPLAY_MATCHES_MOOD_FADE_SECONDS := 0.6
const GAMEPLAY_MATCHES_MAX_CALM_WEIGHT := 0.3
const HINT_PULSE_SPEED_MULTIPLIER := 0.45
const AUDIO_TRACK_ID := "glassgrid"
const AUDIO_TRACK_MANIFEST_PATH := "res://src/audio/tracks.json"
const CLEAR_HIGH_SCORE_ON_BOOT := false

# Screenshot/UAT
const GOLDEN_RESOLUTION := Vector2i(1170, 2532) # iPhone portrait

static func is_visual_test_mode() -> bool:
	if ProjectSettings.has_setting("lumarush/visual_test_mode"):
		return ProjectSettings.get_setting("lumarush/visual_test_mode")
	return VISUAL_TEST_MODE

static func is_audio_test_mode() -> bool:
	if ProjectSettings.has_setting("lumarush/audio_test_mode"):
		return ProjectSettings.get_setting("lumarush/audio_test_mode")
	return AUDIO_TEST_MODE

static func tile_blur_mode() -> int:
	if ProjectSettings.has_setting("lumarush/tile_blur_mode"):
		return int(ProjectSettings.get_setting("lumarush/tile_blur_mode"))
	return TILE_BLUR_MODE

static func min_match_size() -> int:
	if ProjectSettings.has_setting("lumarush/min_match_size"):
		return max(2, int(ProjectSettings.get_setting("lumarush/min_match_size")))
	return MIN_MATCH_SIZE

static func combo_decay_delay_seconds() -> float:
	if ProjectSettings.has_setting("lumarush/combo_decay_delay_seconds"):
		return float(ProjectSettings.get_setting("lumarush/combo_decay_delay_seconds"))
	return COMBO_DECAY_DELAY_SECONDS

static func combo_decay_seconds() -> float:
	if ProjectSettings.has_setting("lumarush/combo_decay_seconds"):
		return float(ProjectSettings.get_setting("lumarush/combo_decay_seconds"))
	return COMBO_DECAY_SECONDS

static func combo_decay_target_db() -> float:
	if ProjectSettings.has_setting("lumarush/combo_decay_target_db"):
		return float(ProjectSettings.get_setting("lumarush/combo_decay_target_db"))
	return COMBO_DECAY_TARGET_DB

static func gameplay_calm_return_delay_seconds() -> float:
	if ProjectSettings.has_setting("lumarush/gameplay_calm_return_delay_seconds"):
		return float(ProjectSettings.get_setting("lumarush/gameplay_calm_return_delay_seconds"))
	return GAMEPLAY_CALM_RETURN_DELAY_SECONDS

static func gameplay_calm_fade_seconds() -> float:
	if ProjectSettings.has_setting("lumarush/gameplay_calm_fade_seconds"):
		return float(ProjectSettings.get_setting("lumarush/gameplay_calm_fade_seconds"))
	return GAMEPLAY_CALM_FADE_SECONDS

static func match_hint_delay_seconds() -> float:
	if ProjectSettings.has_setting("lumarush/match_hint_delay_seconds"):
		return float(ProjectSettings.get_setting("lumarush/match_hint_delay_seconds"))
	return MATCH_HINT_DELAY_SECONDS

static func gameplay_matches_normalizer() -> float:
	if ProjectSettings.has_setting("lumarush/gameplay_matches_normalizer"):
		return max(1.0, float(ProjectSettings.get_setting("lumarush/gameplay_matches_normalizer")))
	return GAMEPLAY_MATCHES_NORMALIZER

static func gameplay_matches_mood_fade_seconds() -> float:
	if ProjectSettings.has_setting("lumarush/gameplay_matches_mood_fade_seconds"):
		return max(0.0, float(ProjectSettings.get_setting("lumarush/gameplay_matches_mood_fade_seconds")))
	return GAMEPLAY_MATCHES_MOOD_FADE_SECONDS

static func gameplay_matches_max_calm_weight() -> float:
	if ProjectSettings.has_setting("lumarush/gameplay_matches_max_calm_weight"):
		return clamp(float(ProjectSettings.get_setting("lumarush/gameplay_matches_max_calm_weight")), 0.0, 1.0)
	return GAMEPLAY_MATCHES_MAX_CALM_WEIGHT

static func hint_pulse_speed_multiplier() -> float:
	if ProjectSettings.has_setting("lumarush/hint_pulse_speed_multiplier"):
		return max(0.1, float(ProjectSettings.get_setting("lumarush/hint_pulse_speed_multiplier")))
	return HINT_PULSE_SPEED_MULTIPLIER

static func audio_track_id() -> String:
	if ProjectSettings.has_setting("lumarush/audio_track_id"):
		return str(ProjectSettings.get_setting("lumarush/audio_track_id"))
	return AUDIO_TRACK_ID

static func audio_track_manifest_path() -> String:
	if ProjectSettings.has_setting("lumarush/audio_track_manifest_path"):
		return str(ProjectSettings.get_setting("lumarush/audio_track_manifest_path"))
	return AUDIO_TRACK_MANIFEST_PATH

static func clear_high_score_on_boot() -> bool:
	if ProjectSettings.has_setting("lumarush/clear_high_score_on_boot"):
		return bool(ProjectSettings.get_setting("lumarush/clear_high_score_on_boot"))
	return CLEAR_HIGH_SCORE_ON_BOOT
