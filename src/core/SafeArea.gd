extends Node

var _cached_insets: Dictionary = {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}

func get_insets() -> Dictionary:
	var viewport_size: Vector2 = _viewport_size()
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return _cached_insets
	var safe_rect: Rect2 = _safe_rect_for_viewport(viewport_size)
	_cached_insets = compute_insets(viewport_size, safe_rect)
	return _cached_insets

func apply_vertical_margins(top_control: Control, bottom_control: Control, top_pad: float, bottom_pad: float) -> void:
	var insets: Dictionary = get_insets()
	if top_control != null:
		top_control.offset_top = top_pad + float(insets["top"])
	if bottom_control != null:
		bottom_control.offset_bottom = -(bottom_pad + float(insets["bottom"]))

func _viewport_size() -> Vector2:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return Vector2.ZERO
	return tree.root.get_visible_rect().size

func _safe_rect_for_viewport(viewport_size: Vector2) -> Rect2:
	var raw_rect: Rect2i = DisplayServer.get_display_safe_area()
	if raw_rect.size.x <= 0 or raw_rect.size.y <= 0:
		return Rect2(Vector2.ZERO, viewport_size)
	var direct_rect := Rect2(raw_rect.position, raw_rect.size)
	var window_size: Vector2i = DisplayServer.window_get_size()
	if window_size.x <= 0 or window_size.y <= 0:
		return direct_rect

	# Depending on platform/stretch mode, DisplayServer can return safe-area values
	# in either window pixels or viewport units. Compare both interpretations and
	# keep the one that preserves the larger visible safe area.
	var scale := Vector2(
		viewport_size.x / float(window_size.x),
		viewport_size.y / float(window_size.y)
	)
	var scaled_rect := Rect2(Vector2(raw_rect.position) * scale, Vector2(raw_rect.size) * scale)
	var viewport_rect := Rect2(Vector2.ZERO, viewport_size)
	var direct_area: float = direct_rect.intersection(viewport_rect).get_area()
	var scaled_area: float = scaled_rect.intersection(viewport_rect).get_area()
	return scaled_rect if scaled_area > direct_area else direct_rect

static func compute_insets(viewport_size: Vector2, safe_rect: Rect2) -> Dictionary:
	var full_rect := Rect2(Vector2.ZERO, viewport_size)
	var clipped: Rect2 = safe_rect.intersection(full_rect)
	if clipped.size.x <= 0.0 or clipped.size.y <= 0.0:
		return {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}
	return {
		"top": max(0.0, clipped.position.y),
		"left": max(0.0, clipped.position.x),
		"right": max(0.0, viewport_size.x - (clipped.position.x + clipped.size.x)),
		"bottom": max(0.0, viewport_size.y - (clipped.position.y + clipped.size.y)),
	}
