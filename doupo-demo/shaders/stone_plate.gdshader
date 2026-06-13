shader_type canvas_item;

// 天然石板基色（青灰色调）
uniform vec4 color_base : source_color = vec4(0.55, 0.53, 0.48, 1.0);
uniform vec4 color_dark : source_color = vec4(0.38, 0.36, 0.32, 1.0);
uniform vec4 color_moss : source_color = vec4(0.35, 0.42, 0.30, 1.0);

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

// 分形噪声（多层叠加）
float fbm(vec2 p) {
	float val = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		val += amp * noise(p);
		p *= 2.0;
		amp *= 0.5;
	}
	return val;
}

void fragment() {
	// === 天然石板大纹理（不规则色块）===
	float stone_fbm = fbm(UV * vec2(6.0, 4.0));
	vec4 base = mix(color_base, color_dark, stone_fbm * 0.5);

	// === 石板表面粗糙感（高频噪声）===
	float roughness = noise(UV * vec2(50.0, 35.0));
	float grain = noise(UV * vec2(120.0, 80.0));
	base.rgb += (roughness - 0.5) * 0.04;
	base.rgb += (grain - 0.5) * 0.02;

	// === 天然裂纹（不规则线）===
	// 裂纹1：斜向
	float crack1 = fbm(UV * vec2(15.0, 8.0) + vec2(3.0, 1.0));
	float crack_line1 = smoothstep(0.48, 0.50, crack1) - smoothstep(0.50, 0.52, crack1);
	// 裂纹2：横向
	float crack2 = fbm(UV * vec2(10.0, 12.0) + vec2(7.0, 4.0));
	float crack_line2 = smoothstep(0.49, 0.50, crack2) - smoothstep(0.50, 0.51, crack2);
	float cracks = max(crack_line1, crack_line2);
	// 裂纹颜色：深色凹陷
	base.rgb = mix(base.rgb, color_dark.rgb * 0.6, cracks * 0.7);

	// === 风化边缘暗化（四周）===
	float edge_x = min(UV.x, 1.0 - UV.x);
	float edge_y = min(UV.y, 1.0 - UV.y);
	float edge_dist = min(edge_x, edge_y);
	float weathering = smoothstep(0.0, 0.08, edge_dist);
	base.rgb *= mix(0.8, 1.0, weathering);

	// === 苔藓斑点（随机位置）===
	float moss_noise = fbm(UV * vec2(8.0, 6.0) + vec2(5.0, 2.0));
	float moss_mask = smoothstep(0.6, 0.7, moss_noise);
	// 只在边缘和裂缝附近长苔藓
	float moss_edge = 1.0 - smoothstep(0.0, 0.15, edge_dist);
	float moss_area = max(moss_edge, cracks * 2.0);
	moss_mask *= smoothstep(0.3, 0.6, moss_area);
	base.rgb = mix(base.rgb, color_moss.rgb, moss_mask * 0.4);

	// === 石板凹凸感（法线模拟）===
	// 根据噪声变化微调亮度，模拟凹凸
	float bump = fbm(UV * vec2(20.0, 15.0));
	float bump_light = (bump - 0.5) * 0.06;
	base.rgb += bump_light;

	// === 整体微调 ===
	// 略微偏暖
	base.rgb.r += 0.01;
	base.rgb.g -= 0.005;

	COLOR = base;
}
