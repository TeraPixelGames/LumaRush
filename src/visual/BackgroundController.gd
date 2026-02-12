extends Node2D
class_name BackgroundController

@onready var bg_rect: ColorRect = $ColorRect
@onready var particles: GPUParticles2D = $Particles

var _deterministic := false
var _t := 0.0
var _mood_tween: Tween

var _calm_a := Color(0.96, 0.98, 1.0, 1.0)
var _calm_b := Color(0.82, 0.88, 1.0, 1.0)
var _hype_a := Color(0.18, 0.28, 0.5, 1.0)
var _hype_b := Color(0.55, 0.25, 0.85, 1.0)

func _ready() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://src/visual/GradientBackground.gdshader")
	mat.set_shader_parameter("color_a", _calm_a)
	mat.set_shader_parameter("color_b", _calm_b)
	bg_rect.material = mat
	bg_rect.position = Vector2.ZERO
	bg_rect.size = get_viewport_rect().size
	particles.position = bg_rect.size * 0.5
	var pm: ParticleProcessMaterial = particles.process_material
	if pm:
		pm.emission_box_extents = Vector3(bg_rect.size.x * 0.6, bg_rect.size.y * 0.6, 1.0)
	particles.emitting = true
	particles.modulate = Color(1, 1, 1, 0.35)
	set_mood(BackgroundMood.get_mood())

func _process(delta: float) -> void:
	if _deterministic:
		_t = 0.0
	else:
		_t += delta
	if bg_rect.material:
		bg_rect.material.set_shader_parameter("t", _t)
		bg_rect.material.set_shader_parameter("drift", 0.0 if _deterministic else 1.0)

func set_mood(mood: int, fade_seconds: float = 0.8) -> void:
	var to_a := _calm_a if mood == BackgroundMood.Mood.CALM else _hype_a
	var to_b := _calm_b if mood == BackgroundMood.Mood.CALM else _hype_b
	var particle_alpha: float = 0.35 if mood == BackgroundMood.Mood.CALM else 0.65
	_apply_mood_targets(to_a, to_b, particle_alpha, fade_seconds)

func set_mood_mix(calm_weight: float, fade_seconds: float = 0.8) -> void:
	var mix_t: float = clamp(calm_weight, 0.0, 1.0)
	var to_a: Color = _hype_a.lerp(_calm_a, mix_t)
	var to_b: Color = _hype_b.lerp(_calm_b, mix_t)
	var particle_alpha: float = lerp(0.65, 0.35, mix_t)
	_apply_mood_targets(to_a, to_b, particle_alpha, fade_seconds)

func _apply_mood_targets(to_a: Color, to_b: Color, particle_alpha: float, fade_seconds: float) -> void:
	if is_instance_valid(_mood_tween):
		_mood_tween.kill()
	_mood_tween = create_tween()
	_mood_tween.set_parallel(true)
	_mood_tween.tween_property(bg_rect.material, "shader_parameter/color_a", to_a, fade_seconds)
	_mood_tween.tween_property(bg_rect.material, "shader_parameter/color_b", to_b, fade_seconds)
	_mood_tween.tween_property(particles, "modulate:a", particle_alpha, fade_seconds)

func set_deterministic(enabled: bool) -> void:
	_deterministic = enabled
