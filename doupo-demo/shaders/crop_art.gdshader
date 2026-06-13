shader_type canvas_item;

uniform float crop_left : hint_range(0.0, 0.3) = 0.05;
uniform float crop_right : hint_range(0.0, 0.3) = 0.05;
uniform float crop_top : hint_range(0.0, 0.3) = 0.05;
uniform float crop_bottom : hint_range(0.0, 0.3) = 0.05;

void fragment() {
	vec2 uv = UV;
	uv.x = crop_left + uv.x * (1.0 - crop_left - crop_right);
	uv.y = crop_top + uv.y * (1.0 - crop_top - crop_bottom);
	COLOR = texture(TEXTURE, uv);
}
