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
	vec2 dir = normalize(vec2(r, fract(r * 7.31)) - 0.5);
	vec2 offset = dir * progress * 0.15;
	vec4 col = texture(TEXTURE, UV + offset);
	col.a *= (1.0 - progress);
	COLOR = col;
}
