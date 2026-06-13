shader_type canvas_item;

// 描边宽度（像素）
uniform float outline_width : hint_range(0.0, 6.0) = 2.0;
// 描边颜色（深色轮廓）
uniform vec4 outline_color : source_color = vec4(0.08, 0.06, 0.12, 1.0);
// 边缘光颜色（亮色轮廓光）
uniform vec4 rim_color : source_color = vec4(0.9, 0.85, 0.6, 0.8);
// 边缘光宽度
uniform float rim_width : hint_range(0.0, 4.0) = 1.5;
// 内发光强度
uniform float inner_glow_strength : hint_range(0.0, 1.0) = 0.3;
// 纹理尺寸（运行时自动设置）
uniform vec2 tex_size = vec2(160.0, 140.0);

void fragment() {
	vec2 pixel = 1.0 / tex_size;
	vec4 base = texture(TEXTURE, UV);
	float a = base.a;

	// === 边缘检测（采样8方向） ===
	float max_alpha = 0.0;
	float min_dist_to_edge = 999.0;

	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			if (x == 0 && y == 0) continue;
			vec2 offset = vec2(float(x), float(y)) * pixel;
			float neighbor = texture(TEXTURE, UV + offset).a;
			max_alpha = max(max_alpha, neighbor);
			if (neighbor > 0.1 && a < 0.1) {
				float dist = length(vec2(float(x), float(y)));
				min_dist_to_edge = min(min_dist_to_edge, dist);
			}
		}
	}

	// === 计算所有效果，最后统一输出 ===

	// 外描边 + 边缘光
	vec4 outline_result = vec4(0.0);
	float outline_alpha = 0.0;
	if (a < 0.1 && max_alpha > 0.1) {
		float edge_fade = smoothstep(3.0, 0.0, min_dist_to_edge);
		if (min_dist_to_edge <= rim_width + outline_width) {
			float rim_fade = smoothstep(rim_width + outline_width, outline_width, min_dist_to_edge);
			outline_result = mix(rim_color, outline_color, rim_fade);
			outline_alpha = edge_fade;
		} else {
			outline_result = outline_color;
			outline_alpha = edge_fade;
		}
	}

	// 内发光
	float glow = 0.0;
	if (a > 0.1) {
		float inner_dist = 999.0;
		for (int x = -3; x <= 3; x++) {
			for (int y = -3; y <= 3; y++) {
				vec2 offset = vec2(float(x), float(y)) * pixel;
				float neighbor = texture(TEXTURE, UV + offset).a;
				if (neighbor < 0.1) {
					float dist = length(vec2(float(x), float(y)));
					inner_dist = min(inner_dist, dist);
				}
			}
		}
		if (inner_dist < 4.0) {
			glow = (1.0 - inner_dist / 4.0) * inner_glow_strength;
		}
	}

	// === 合成输出 ===
	vec4 final_color = base;
	final_color.rgb += glow * rim_color.rgb;

	// 描边覆盖（在透明区域）
	if (a < 0.1 && max_alpha > 0.1) {
		final_color = outline_result;
		final_color.a = outline_alpha;
	}

	// 完全透明的像素
	if (a < 0.1 && max_alpha < 0.1) {
		final_color = vec4(0.0);
	}

	COLOR = final_color;
}
