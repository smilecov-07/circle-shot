shader_type canvas_item;

instance uniform vec4 color : source_color = vec4(1.0);
instance uniform float power = 1.0;

void fragment() {
	float alpha = COLOR.a;
	COLOR = texture(TEXTURE, UV);
	COLOR.rgb = mix(COLOR.rgb, color.rgb, power);
	COLOR.a = alpha;
}
