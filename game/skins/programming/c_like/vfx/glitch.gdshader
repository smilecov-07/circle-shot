shader_type canvas_item;

instance uniform float glitch = 0.0;
instance uniform float shift_glitch = 0.0;
uniform sampler2D shift_glitch_texture;
varying flat vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	float alpha = COLOR.a;
	vec2 uv = UV + vec2((texture(shift_glitch_texture, UV).r - 0.5) * shift_glitch, 0.0);
	COLOR.r = texture(TEXTURE, vec2(uv.x - glitch, uv.y)).r;
	COLOR.ga = texture(TEXTURE, uv).ga;
	COLOR.b = texture(TEXTURE, vec2(uv.x + glitch, uv.y)).b;
	COLOR *= modulate;
}