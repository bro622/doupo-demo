shader_type canvas_item;

uniform float radius : hint_range(0.0, 0.5) = 0.2;

void fragment() {
	vec2 uv = UV;
	vec2 pos = uv - 0.5;           // 中心化 [-0.5, 0.5]
	vec2 half_size = vec2(0.5);

	// SDF 圆角矩形
	vec2 d = abs(pos) - (half_size - vec2(radius));
	float dist = length(max(d, 0.0)) - radius;

	// 抗锯齿边缘
	float aa = fwidth(dist) * 1.5;
	float mask = 1.0 - smoothstep(-aa, aa, dist);

	COLOR = texture(TEXTURE, uv);
	COLOR.a *= mask;
}
