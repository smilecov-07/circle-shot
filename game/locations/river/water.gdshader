shader_type canvas_item;

uniform sampler2D dist_texture: repeat_enable;
uniform float distortion = 0.1;
uniform float time_multiplier = 1.0;

void fragment() {
	vec2 uv_offset = texture(dist_texture, UV + TIME * time_multiplier).rg - vec2(0.5);
	COLOR = texture(TEXTURE, UV + uv_offset * distortion);
}