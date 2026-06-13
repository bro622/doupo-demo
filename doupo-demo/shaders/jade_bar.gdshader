shader_type canvas_item;

// 基础颜色：深墨绿（不透明）
uniform vec4 color_dark : source_color = vec4(0.04, 0.08, 0.06, 1.0);
uniform vec4 color_light : source_color = vec4(0.06, 0.14, 0.10, 1.0);
// 高光边缘色
uniform vec4 edge_highlight : source_color = vec4(0.85, 0.75, 0.4, 0.3);
// 光线条纹
uniform float streak_speed : hint_range(0.0, 2.0) = 0.3;
// 微裂纹强度
uniform float crack_strength : hint_range(0.0, 1.0) = 0.15;

// 简单噪声
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	// 水平渐变：左深右浅
	float gradient = UV.x;
	vec4 base = mix(color_dark, color_light, gradient * 0.6);

	// 微裂纹（细线纹理）
	float crack_noise = noise(UV * vec2(80.0, 12.0));
	float crack_line = smoothstep(0.48, 0.5, crack_noise) - smoothstep(0.5, 0.52, crack_noise);
	base.rgb += crack_line * crack_strength;

	// 斜向光线条纹
	float streak = UV.x * 3.0 - UV.y * 1.5 + TIME * streak_speed;
	float streak_pattern = sin(streak * 6.283) * 0.5 + 0.5;
	streak_pattern = pow(streak_pattern, 8.0);
	base.rgb += streak_pattern * 0.04;

	// 内部反光（上半部分微亮）
	float inner_reflect = (1.0 - UV.y) * 0.08;
	base.rgb += inner_reflect;

	// 顶部金色高光边缘
	float top_edge = smoothstep(0.0, 0.12, UV.y);
	float top_highlight = (1.0 - top_edge) * 0.4;
	base.rgb = mix(base.rgb + edge_highlight.rgb * 0.3, base.rgb, top_edge);
	base.a += top_highlight * 0.15;

	// 底部微暗
	float bottom_fade = smoothstep(1.0, 0.7, UV.y);
	base.rgb *= mix(0.85, 1.0, bottom_fade);

	COLOR = base;
}
