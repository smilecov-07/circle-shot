shader_type canvas_item;

uniform vec4 change_to: source_color;
varying flat vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	if (COLOR.r - COLOR.g > 0.1)
		COLOR = change_to;
	COLOR *= modulate;
}