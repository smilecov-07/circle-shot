shader_type canvas_item;

uniform float time_multiplier = 1.0;
uniform float stretch = 7.5;
uniform float amplitude = 0.1;
instance uniform float time_offset;
varying flat vec4 color;

void vertex() {
	color = COLOR;
}

void fragment() {
	COLOR = texture(TEXTURE, vec2(UV.x, UV.y + sin(UV.x * stretch + (TIME + time_offset) * time_multiplier) * amplitude * (1.0 - UV.x)));
	COLOR *= color;
}