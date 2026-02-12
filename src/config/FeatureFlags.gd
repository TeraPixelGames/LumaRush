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
const GAMEPLAY_MATCHES_MAX_CALM_WEIGHT := 0.45
const HINT_PULSE_SPEED_MULTIPLIER := 0.45
const AUDIO_TRACK_ID := "glassgrid"
const AUDIO_TRACK_MANIFEST_PATH := "res://src/audio/tracks.json"
const CLEAR_HIGH_SCORE_ON_BOOT := false
const AD_RETRY_ATTEMPTS := 2
const AD_RETRY_INTERVAL_SECONDS := 0.35
const AD_PRELOAD_POLL_SECONDS := 1.25
const STARFIELD_CALM_DENSITY := 1.4
const STARFIELD_HYPE_DENSITY := 2.8
const STARFIELD_CALM_SPEED := 1.0
const STARFIELD_HYPE_SPEED := 2.0
const STARFIELD_CALM_BRIGHTNESS := 0.8
const STARFIELD_HYPE_BRIGHTNESS := 1.35
const STARFIELD_BEAT_PULSE_DEPTH := 0.2
const STARFIELD_MATCH_PULSE_SECONDS := 0.2
const STARFIELD_MATCH_PULSE_DENSITY_MULT := 1.45
const STARFIELD_MATCH_PULSE_SPEED_MULT := 1.2
const STARFIELD_MATCH_PULSE_BRIGHTNESS_MULT := 1.25
const HAPTICS_ENABLED := true
const MATCH_CLICK_HAPTIC_DURATION_MS := 14
const MATCH_CLICK_HAPTIC_AMPLITUDE := 0.35
const MATCH_HAPTIC_DURATION_MS := 26
const MATCH_HAPTIC_AMPLITUDE := 0.5
const POWERUP_UNDO_CHARGES := 2
const POWERUP_REMOVE_COLOR_CHARGES := 1
const POWERUP_SHUFFLE_CHARGES := 1
const POWERUP_FLASH_ALPHA := 0.22
const POWERUP_FLASH_SECONDS := 0.24

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

static func ad_retry_attempts() -> int:
	if ProjectSettings.has_setting("lumarush/ad_retry_attempts"):
		return max(0, int(ProjectSettings.get_setting("lumarush/ad_retry_attempts")))
	return AD_RETRY_ATTEMPTS

static func ad_retry_interval_seconds() -> float:
	if ProjectSettings.has_setting("lumarush/ad_retry_interval_seconds"):
		return max(0.05, float(ProjectSettings.get_setting("lumarush/ad_retry_interval_seconds")))
	return AD_RETRY_INTERVAL_SECONDS

static func ad_preload_poll_seconds() -> float:
	if ProjectSettings.has_setting("lumarush/ad_preload_poll_seconds"):
		return max(0.2, float(ProjectSettings.get_setting("lumarush/ad_preload_poll_seconds")))
	return AD_PRELOAD_POLL_SECONDS

static func starfield_calm_density() -> float:
	if ProjectSettings.has_setting("lumarush/starfield_calm_density"):
		return max(0.2, float(ProjectSettings.get_setting("lumarush/starfield_calm_density")))
	return STARFIELD_CALM_DENSITY

static func starfield_hype_density() -> float:
	if ProjectSettings.has_setting("lumarush/starfield_hype_density"):
		return max(0.2, float(ProjectSettings.get_setting("lumarush/starfield_hype_density")))
	return STARFIELD_HYPE_DENSITY

static func starfield_calm_speed() -> float:
	if ProjectSettings.has_setting("lumarush/starfield_calm_speed"):
		return max(0.1, float(ProjectSettings.get_setting("lumarush/starfield_calm_speed")))
	return STARFIELD_CALM_SPEED

static func starfield_hype_speed() -> float:
	if ProjectSettings.has_setting("lumarush/starfield_hype_speed"):
		return max(0.1, float(ProjectSettings.get_setting("lumarush/starfield_hype_speed")))
	return STARFIELD_HYPE_SPEED

static func starfield_calm_brightness() -> float:
	if ProjectSettings.has_setting("lumarush/starfield_calm_brightness"):
		return max(0.1, float(ProjectSettings.get_setting("lumarush/starfield_calm_brightness")))
	return STARFIELD_CALM_BRIGHTNESS

static func starfield_hype_brightness() -> float:
	if ProjectSettings.has_setting("lumarush/starfield_hype_brightness"):
		return max(0.1, float(ProjectSettings.get_setting("lumarush/starfield_hype_brightness")))
	return STARFIELD_HYPE_BRIGHTNESS

static func starfield_beat_pulse_depth() -> float:
	if ProjectSettings.has_setting("lumarush/starfield_beat_pulse_depth"):
		return clamp(float(ProjectSettings.get_setting("lumarush/starfield_beat_pulse_depth")), 0.0, 1.0)
	return STARFIELD_BEAT_PULSE_DEPTH

static func starfield_match_pulse_seconds() -> float:
	if ProjectSettings.has_setting("lumarush/starfield_match_pulse_seconds"):
		return max(0.05, float(ProjectSettings.get_setting("lumarush/starfield_match_pulse_seconds")))
	return STARFIELD_MATCH_PULSE_SECONDS

static func starfield_match_pulse_density_mult() -> float:
	if ProjectSettings.has_setting("lumarush/starfield_match_pulse_density_mult"):
		return max(1.0, float(ProjectSettings.get_setting("lumarush/starfield_match_pulse_density_mult")))
	return STARFIELD_MATCH_PULSE_DENSITY_MULT

static func starfield_match_pulse_speed_mult() -> float:
	if ProjectSettings.has_setting("lumarush/starfield_match_pulse_speed_mult"):
		return max(1.0, float(ProjectSettings.get_setting("lumarush/starfield_match_pulse_speed_mult")))
	return STARFIELD_MATCH_PULSE_SPEED_MULT

static func starfield_match_pulse_brightness_mult() -> float:
	if ProjectSettings.has_setting("lumarush/starfield_match_pulse_brightness_mult"):
		return max(1.0, float(ProjectSettings.get_setting("lumarush/starfield_match_pulse_brightness_mult")))
	return STARFIELD_MATCH_PULSE_BRIGHTNESS_MULT

static func haptics_enabled() -> bool:
	if ProjectSettings.has_setting("lumarush/haptics_enabled"):
		return bool(ProjectSettings.get_setting("lumarush/haptics_enabled"))
	return HAPTICS_ENABLED

static func match_haptic_duration_ms() -> int:
	if ProjectSettings.has_setting("lumarush/match_haptic_duration_ms"):
		return max(0, int(ProjectSettings.get_setting("lumarush/match_haptic_duration_ms")))
	return MATCH_HAPTIC_DURATION_MS

static func match_haptic_amplitude() -> float:
	if ProjectSettings.has_setting("lumarush/match_haptic_amplitude"):
		return clamp(float(ProjectSettings.get_setting("lumarush/match_haptic_amplitude")), 0.0, 1.0)
	return MATCH_HAPTIC_AMPLITUDE

static func match_click_haptic_duration_ms() -> int:
	if ProjectSettings.has_setting("lumarush/match_click_haptic_duration_ms"):
		return max(0, int(ProjectSettings.get_setting("lumarush/match_click_haptic_duration_ms")))
	return MATCH_CLICK_HAPTIC_DURATION_MS

static func match_click_haptic_amplitude() -> float:
	if ProjectSettings.has_setting("lumarush/match_click_haptic_amplitude"):
		return clamp(float(ProjectSettings.get_setting("lumarush/match_click_haptic_amplitude")), 0.0, 1.0)
	return MATCH_CLICK_HAPTIC_AMPLITUDE

static func powerup_undo_charges() -> int:
	if ProjectSettings.has_setting("lumarush/powerup_undo_charges"):
		return max(0, int(ProjectSettings.get_setting("lumarush/powerup_undo_charges")))
	return POWERUP_UNDO_CHARGES

static func powerup_remove_color_charges() -> int:
	if ProjectSettings.has_setting("lumarush/powerup_remove_color_charges"):
		return max(0, int(ProjectSettings.get_setting("lumarush/powerup_remove_color_charges")))
	return POWERUP_REMOVE_COLOR_CHARGES

static func powerup_shuffle_charges() -> int:
	if ProjectSettings.has_setting("lumarush/powerup_shuffle_charges"):
		return max(0, int(ProjectSettings.get_setting("lumarush/powerup_shuffle_charges")))
	return POWERUP_SHUFFLE_CHARGES

static func powerup_flash_alpha() -> float:
	if ProjectSettings.has_setting("lumarush/powerup_flash_alpha"):
		return clamp(float(ProjectSettings.get_setting("lumarush/powerup_flash_alpha")), 0.0, 1.0)
	return POWERUP_FLASH_ALPHA

static func powerup_flash_seconds() -> float:
	if ProjectSettings.has_setting("lumarush/powerup_flash_seconds"):
		return max(0.05, float(ProjectSettings.get_setting("lumarush/powerup_flash_seconds")))
	return POWERUP_FLASH_SECONDS
