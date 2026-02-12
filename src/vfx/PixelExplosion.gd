extends Node2D
class_name PixelExplosion

@onready var sprite: Sprite2D = $Sprite2D

func setup(tex: Texture2D, pixel_size: float, rng_seed: float) -> void:
	sprite.texture = tex
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://src/vfx/PixelExplosion.gdshader")
	mat.set_shader_parameter("pixel_size", pixel_size)
	mat.set_shader_parameter("seed", rng_seed)
	sprite.material = mat
	_spawn_particles(tex)
	_start()

func _spawn_particles(tex: Texture2D) -> void:
	var particles := GPUParticles2D.new()
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = 0.55
	particles.amount = int(clamp((tex.get_width() * tex.get_height()) / 1800.0, 40.0, 220.0))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(tex.get_width() * 0.5, tex.get_height() * 0.5, 1.0)
	pm.initial_velocity_min = 120.0
	pm.initial_velocity_max = 260.0
	pm.gravity = Vector3(0.0, 380.0, 0.0)
	pm.scale_min = 0.18
	pm.scale_max = 0.42
	pm.color = Color(1.0, 0.97, 0.9, 0.95)
	particles.process_material = pm
	particles.position = Vector2(tex.get_width() * 0.5, tex.get_height() * 0.5)
	add_child(particles)
	particles.emitting = true

func _start() -> void:
	var mat: ShaderMaterial = sprite.material as ShaderMaterial
	if mat == null:
		queue_free()
		return
	var t := create_tween()
	t.tween_method(func(v: float) -> void:
		mat.set_shader_parameter("progress", v)
	, 0.0, 1.0, 0.5)
	t.tween_callback(Callable(self, "queue_free"))
