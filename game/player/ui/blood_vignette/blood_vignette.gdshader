shader_type canvas_item;

uniform sampler2D noise;
uniform float time_multiplier = 0.1;
uniform float alpha_multiplier = 0.5;
uniform float noise_scale = 1.0;
varying flat vec4 color;

void vertex() {
	color = COLOR;
}

void fragment() {
	COLOR = texture(TEXTURE, UV);
	vec2 new_uv = UV + vec2(TIME * time_multiplier);
	COLOR.a -= texture(noise, vec2(mod(new_uv.x, noise_scale), mod(new_uv.y, noise_scale)) / noise_scale).r * alpha_multiplier;
	COLOR *= color;
}
