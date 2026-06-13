shader_type canvas_item;

// === 基底：米黄/淡棕羊皮纸 ===
uniform vec4 bg_color : source_color = vec4(0.72, 0.65, 0.50, 1.0);
uniform vec4 bg_secondary : source_color = vec4(0.65, 0.58, 0.42, 1.0);

// === 中间微亮 ===
uniform float center_glow_strength : hint_range(0.0, 0.2) = 0.08;

// === 纸张纤维 ===
uniform float fiber_scale : hint_range(20.0, 120.0) = 55.0;
uniform float fiber_strength : hint_range(0.0, 0.25) = 0.08;
uniform vec4 fiber_color : source_color = vec4(0.55, 0.48, 0.35, 1.0);

// === 褶皱噪声 ===
uniform float crease_scale : hint_range(3.0, 20.0) = 8.0;
uniform float crease_strength : hint_range(0.0, 0.15) = 0.06;
uniform vec4 crease_light : source_color = vec4(0.92, 0.88, 0.78, 1.0);
uniform vec4 crease_dark : source_color = vec4(0.65, 0.55, 0.40, 1.0);


// ── 噪声工具 ──

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm4(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * value_noise(p);
		p = p * 2.0 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

float fbm2(vec2 p) {
	float v = 0.0;
	float a = 0.6;
	for (int i = 0; i < 2; i++) {
		v += a * value_noise(p);
		p = p * 2.3 + vec2(5.1, 3.7);
		a *= 0.45;
	}
	return v;
}

float directional_fiber(vec2 p, float angle) {
	float c = cos(angle);
	float s = sin(angle);
	vec2 rp = vec2(p.x * c - p.y * s, p.x * s + p.y * c);
	rp.y *= 0.15;
	return fbm4(rp);
}


// ── 主函数 ──

void fragment() {
	vec2 uv = UV;
	vec3 color = bg_color.rgb;

	// 1) 基底：轻微双色变化
	float base_blend = fbm2(uv * 3.5 + 42.0);
	color = mix(color, bg_secondary.rgb, base_blend * 0.3);

	// 2) 中间微亮：模拟光照从中心散开
	vec2 center = uv - 0.5;
	float center_dist = length(center);
	float glow = smoothstep(0.7, 0.0, center_dist) * center_glow_strength;
	color += vec3(glow);

	// 3) 纸张纤维：三个交叉方向的细纤维
	float fib1 = directional_fiber(uv * fiber_scale, 0.3);
	float fib2 = directional_fiber(uv * fiber_scale * 0.8 + 20.0, 1.2);
	float fib3 = directional_fiber(uv * fiber_scale * 1.2 + 40.0, 2.5);
	float fiber = (fib1 + fib2 + fib3) / 3.0;
	float coarse_fiber = fbm4(uv * fiber_scale * 0.3 + 60.0);
	fiber = mix(fiber, coarse_fiber, 0.3);
	color = mix(color, fiber_color.rgb, fiber * fiber_strength);

	// 4) 褶皱噪声
	float crease = fbm4(uv * crease_scale + 30.0);
	float crease_light_amt = smoothstep(0.45, 0.55, crease) * crease_strength;
	float crease_dark_amt = smoothstep(0.55, 0.45, crease) * crease_strength * 0.6;
	color = mix(color, crease_light.rgb, crease_light_amt);
	color = mix(color, crease_dark.rgb, crease_dark_amt);

	COLOR = vec4(color, 1.0);
}
