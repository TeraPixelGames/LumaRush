extends Node
class_name VisualTestMode

const PINNED_TRACK_ID := "default"

# Apply deterministic settings for stable screenshot diffs.
# Expected: bg_controller implements `set_deterministic(bool)`
static func apply_if_enabled(bg_controller: Node, particles: Node) -> void:
	if not FeatureFlags.is_visual_test_mode():
		return
	bg_controller.call("set_deterministic", true)
	if particles and particles.has_method("set"):
		particles.set("emitting", false)

static func pinned_track_id_or_empty() -> String:
	if not FeatureFlags.is_visual_test_mode():
		return ""
	return PINNED_TRACK_ID
