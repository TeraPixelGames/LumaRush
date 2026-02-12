shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_radius : hint_range(0.0, 16.0) = 8.0;
uniform vec4 tint_color : source_color = vec4(0.08, 0.12, 0.24, 0.62);
uniform vec4 edge_color : source_color = vec4(0.9, 0.96, 1.0, 0.34);
uniform vec4 sheen_color : source_color = vec4(1.0, 1.0, 1.0, 0.22);
uniform float corner_radius : hint_range(0.0, 0.5) = 0.12;
uniform float border_width : hint_range(0.0, 0.08) = 0.012;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.28;

float rounded_box_sdf(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void fragment() {
	vec2 p = UV - vec2(0.5);
	float radius = min(0.5, corner_radius);
	float sdf = rounded_box_sdf(p, vec2(0.5), radius);
	float mask = 1.0 - smoothstep(0.0, 0.004, sdf);
	if (mask <= 0.001) {
		discard;
	}

	vec2 px = SCREEN_PIXEL_SIZE * blur_radius;
	vec4 c0 = texture(screen_texture, SCREEN_UV);
	vec4 c1 = texture(screen_texture, SCREEN_UV + vec2(px.x, 0.0));
	vec4 c2 = texture(screen_texture, SCREEN_UV + vec2(-px.x, 0.0));
	vec4 c3 = texture(screen_texture, SCREEN_UV + vec2(0.0, px.y));
	vec4 c4 = texture(screen_texture, SCREEN_UV + vec2(0.0, -px.y));
	vec4 blurred = (c0 + c1 + c2 + c3 + c4) / 5.0;

	float border = 1.0 - smoothstep(border_width, border_width + 0.02, abs(sdf));
	float top_sheen = smoothstep(0.65, 0.05, UV.y) * (1.0 - abs(UV.x - 0.5) * 1.3);
	float vignette = 1.0 - (distance(UV, vec2(0.5)) * 1.35);
	vignette = clamp(vignette, 0.0, 1.0);

	vec3 col = mix(blurred.rgb, tint_color.rgb, tint_color.a);
	col = mix(col, sheen_color.rgb, top_sheen * sheen_color.a);
	col = mix(col, edge_color.rgb, border * edge_color.a);
	col *= mix(1.0 - vignette_strength, 1.0, vignette);

	COLOR = vec4(col, mask);
}
