shader_type canvas_item;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_radius = 2.0;
uniform vec4 tint_color : source_color = vec4(0.8, 0.9, 1.0, 0.45);
uniform float border = 0.08;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 texel = SCREEN_PIXEL_SIZE * blur_radius;
	vec4 sum = vec4(0.0);
	sum += texture(SCREEN_TEXTURE, uv + vec2(-texel.x, 0.0));
	sum += texture(SCREEN_TEXTURE, uv + vec2(texel.x, 0.0));
	sum += texture(SCREEN_TEXTURE, uv + vec2(0.0, -texel.y));
	sum += texture(SCREEN_TEXTURE, uv + vec2(0.0, texel.y));
	sum += texture(SCREEN_TEXTURE, uv);
	vec4 blurred = sum / 5.0;
	vec2 local = UV;
	float edge = smoothstep(0.0, border, local.x) * smoothstep(0.0, border, local.y) * smoothstep(0.0, border, 1.0 - local.x) * smoothstep(0.0, border, 1.0 - local.y);
	vec4 color = mix(blurred, tint_color, 0.55);
	color.a *= edge;
	COLOR = color;
}
