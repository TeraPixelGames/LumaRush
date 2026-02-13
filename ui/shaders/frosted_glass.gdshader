shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 6.0) = 2.5;
uniform vec4 overlay_color : source_color = vec4(0.08, 0.12, 0.18, 0.35);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.25;
uniform float rim_width : hint_range(0.001, 0.12) = 0.02;
uniform float corner_radius : hint_range(0.02, 0.5) = 0.12;
uniform float edge_softness : hint_range(0.001, 0.04) = 0.008;

float rounded_rect_sdf(vec2 p, vec2 half_extents, float radius) {
	vec2 q = abs(p) - half_extents + vec2(radius);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

void fragment() {
	vec4 bg = textureLod(screen_texture, SCREEN_UV, blur_amount);
	vec3 mixed = mix(bg.rgb, overlay_color.rgb, overlay_color.a);

	vec2 p = UV - vec2(0.5);
	float sdf = rounded_rect_sdf(p, vec2(0.5), corner_radius);
	float mask = 1.0 - smoothstep(0.0, edge_softness, sdf);
	float rim = (1.0 - smoothstep(0.0, rim_width, abs(sdf))) * mask;
	vec3 rim_light = vec3(0.86, 0.94, 1.0) * rim * rim_strength;

	COLOR = vec4(mixed + rim_light, mask);
}
