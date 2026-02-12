extends Node

enum Mood { CALM, HYPE }

signal mood_changed(mood: int)

var _controller: Node
var _current_mood: int = Mood.CALM

func register_controller(controller: Node) -> void:
	_controller = controller
	if _controller and _controller.has_method("set_mood"):
		_controller.call("set_mood", _current_mood)

func set_mood(mood: int, fade_seconds: float = -1.0) -> void:
	_current_mood = mood
	if _controller and _controller.has_method("set_mood"):
		if fade_seconds >= 0.0:
			_controller.call("set_mood", _current_mood, fade_seconds)
		else:
			_controller.call("set_mood", _current_mood)
	emit_signal("mood_changed", _current_mood)

func get_mood() -> int:
	return _current_mood

func set_mood_mix(calm_weight: float, fade_seconds: float = -1.0) -> void:
	if _controller and _controller.has_method("set_mood_mix"):
		var clamped: float = clamp(calm_weight, 0.0, 1.0)
		if fade_seconds >= 0.0:
			_controller.call("set_mood_mix", clamped, fade_seconds)
		else:
			_controller.call("set_mood_mix", clamped)

func pulse_starfield() -> void:
	if _controller and _controller.has_method("pulse_starfield"):
		_controller.call("pulse_starfield")
