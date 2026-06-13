shader_type canvas_item;
uniform sampler2D ink_texture : source_color;
uniform float alpha : hint_range(0.0, 1.0) = 0.35;
void fragment() {
    vec4 tex = texture(ink_texture, UV);
    COLOR = vec4(tex.rgb, tex.a * alpha);
}
