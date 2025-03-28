shader_type canvas_item;

instance uniform vec4 color: source_color = vec4(1.0);
instance uniform float power = 1.0;
varying flat vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	COLOR = texture(TEXTURE, UV);
	COLOR.rgb = mix(COLOR.rgb, color.rgb, power);
	COLOR *= modulate;
}
