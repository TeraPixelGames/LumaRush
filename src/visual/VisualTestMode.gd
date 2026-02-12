extends Node
class_name VisualTestMode

const PINNED_TRACK_ID := "default"

# Apply deterministic settings for stable screenshot diffs.
# Expected: bg_controller implements `set_deterministic(bool)`
static func apply_if_enabled(bg_controller: Node, particles: Node) -> void:
	if not FeatureFlags.is_visual_test_mode():
		return
	bg_controller.call("set_deterministic", true)
	if particles:
		_disable_particles_recursive(particles)

static func pinned_track_id_or_empty() -> String:
	if not FeatureFlags.is_visual_test_mode():
		return ""
	return PINNED_TRACK_ID

static func _disable_particles_recursive(node: Node) -> void:
	if node is GPUParticles2D:
		node.set("emitting", false)
	for child in node.get_children():
		if child is Node:
			_disable_particles_recursive(child)
