shader_type canvas_item;

uniform float progress = 0.0;
uniform float pixel_size = 6.0;
uniform float seed = 0.0;

float rand(vec2 co){
	return fract(sin(dot(co.xy ,vec2(12.9898,78.233)) + seed) * 43758.5453);
}

void fragment() {
	vec2 tex_size = vec2(textureSize(TEXTURE, 0));
	vec2 pixel_uv = floor(UV * tex_size / pixel_size) * pixel_size / tex_size;
	float r = rand(pixel_uv * tex_size);
	vec2 raw_dir = vec2(r, fract(r * 7.31)) - vec2(0.5);
	float len_dir = max(length(raw_dir), 0.0001);
	vec2 dir = raw_dir / len_dir;
	vec2 offset = dir * progress * 0.15;
	vec2 sample_uv = clamp(UV + offset, vec2(0.0), vec2(1.0));
	vec4 col = texture(TEXTURE, sample_uv);
	col.a *= (1.0 - progress);
	COLOR = col;
}
