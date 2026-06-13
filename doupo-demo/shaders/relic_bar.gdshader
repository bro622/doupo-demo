shader_type canvas_item;

// 暗青铜底色（不透明）
uniform vec4 color_base : source_color = vec4(0.06, 0.05, 0.04, 1.0);
uniform vec4 color_accent : source_color = vec4(0.12, 0.09, 0.06, 1.0);
// 顶部细线色（暗金）
uniform vec4 line_color : source_color = vec4(0.55, 0.45, 0.25, 0.6);

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
	// 水平渐变：极微弱的明暗变化
	float gradient = UV.x;
	vec4 base = mix(color_base, color_accent, sin(gradient * 3.14159) * 0.3);

	// 细腻金属纹理（横向拉伸噪声）
	float metal = noise(UV * vec2(120.0, 4.0));
	base.rgb += metal * 0.02;

	// 顶部单细线装饰（0.5px 视觉效果）
	float top_line = smoothstep(0.06, 0.0, UV.y);
	base.rgb = mix(base.rgb, line_color.rgb, top_line * line_color.a);

	// 底部微暗过渡
	float bottom = smoothstep(1.0, 0.6, UV.y);
	base.rgb *= mix(0.9, 1.0, bottom);

	COLOR = base;
}
