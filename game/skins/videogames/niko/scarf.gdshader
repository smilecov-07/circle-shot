shader_type canvas_item;

uniform float time_multiplier = 1.0;
uniform float stretch = 7.5;
instance uniform float time_offset;
instance uniform float amplitude = 0.1;
instance uniform float tint = 1.0;

void fragment() {
	COLOR = texture(TEXTURE, vec2(UV.x, UV.y + sin(UV.x * stretch + (TIME + time_offset) * time_multiplier) * amplitude * (1.0 - UV.x)));
	COLOR.rgb *= tint;
}