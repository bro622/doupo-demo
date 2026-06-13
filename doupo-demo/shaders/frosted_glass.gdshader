shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 8.0) = 4.0;
uniform float opacity : hint_range(0.0, 1.0) = 0.65;
uniform vec4 tint_color : source_color = vec4(0.06, 0.06, 0.09, 1.0);

void fragment() {
	vec2 pixel_size = SCREEN_PIXEL_SIZE;
	vec4 color = vec4(0.0);

	// 9-tap box blur on screen texture
	float samples = 0.0;
	for (float x = -1.0; x <= 1.0; x += 1.0) {
		for (float y = -1.0; y <= 1.0; y += 1.0) {
			vec2 offset = vec2(x, y) * pixel_size * blur_amount;
			color += textureLod(screen_texture, SCREEN_UV + offset, blur_amount * 0.5);
			samples += 1.0;
		}
	}
	color /= samples;

	// 混合色调
	color = mix(color, tint_color, opacity);

	COLOR = color;
}
