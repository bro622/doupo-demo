## 地图绘画工具栏
## 画笔/橡皮/清空三个纯图标按钮，画笔和橡皮互斥切换
## 参考 STS2 NMapDrawButton: TextureRect 子节点 + glow 纹理切换 + 三态着色
extends HBoxContainer

signal tool_changed(tool: int)
signal clear_requested

var current_tool: int = 0  # DrawingLayer.Tool.NONE

@onready var pen_btn: Button = $PenBtn
@onready var eraser_btn: Button = $EraserBtn
@onready var clear_btn: Button = $ClearBtn

## 预加载纹理（成员变量，避免 GC 回收）
var _pen_icon: Texture2D = preload("res://assets/ui/icons/tool_pen.png")
var _pen_glow: Texture2D = preload("res://assets/ui/icons/tool_pen_glow.png")
var _eraser_icon: Texture2D = preload("res://assets/ui/icons/tool_eraser.png")
var _eraser_glow: Texture2D = preload("res://assets/ui/icons/tool_eraser_glow.png")
var _clear_icon: Texture2D = preload("res://assets/ui/icons/tool_clear.png")
var _clear_glow: Texture2D = preload("res://assets/ui/icons/tool_clear_glow.png")

## 颜色常量（参考 STS2）
const INACTIVE_COLOR: Color = Color(1, 1, 1, 0.5)  # 白色 50% alpha
const PEN_ACTIVE_COLOR: Color = Color(0.34, 0.77, 1.0)   # 蓝 #57C4FF
const ERASER_ACTIVE_COLOR: Color = Color(1.0, 0.34, 0.34)  # 红 #FF5757
const CLEAR_HOVER_COLOR: Color = Color(1.0, 0.9, 0.49)    # 黄 #FFE57D

## 当前是否激活（手动 toggle 状态）
var _pen_active: bool = false
var _eraser_active: bool = false


func _ready() -> void:
	# 半透明深色背景
	var bg = Panel.new()
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.06, 0.06, 0.1, 0.85)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	bg_style.content_margin_left = 8
	bg_style.content_margin_right = 8
	bg_style.content_margin_top = 6
	bg_style.content_margin_bottom = 6
	bg.add_theme_stylebox_override("panel", bg_style)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)  # 确保在最底层

	pen_btn.pressed.connect(_on_pen_pressed)
	eraser_btn.pressed.connect(_on_eraser_pressed)
	clear_btn.pressed.connect(_on_clear_pressed)
	# 按钮完全透明（无任何样式反馈）
	var empty = StyleBoxEmpty.new()
	for btn in [pen_btn, eraser_btn, clear_btn]:
		btn.add_theme_stylebox_override("normal", empty)
		btn.add_theme_stylebox_override("hover", empty)
		btn.add_theme_stylebox_override("pressed", empty)
		btn.add_theme_stylebox_override("focus", empty)
		btn.add_theme_stylebox_override("disabled", empty)
	# 初始化图标 TextureRect
	_setup_icon(pen_btn, _pen_icon)
	_setup_icon(eraser_btn, _eraser_icon)
	_setup_icon(clear_btn, _clear_icon)
	# 连接悬停信号
	pen_btn.mouse_entered.connect(_on_pen_hover.bind(true))
	pen_btn.mouse_exited.connect(_on_pen_hover.bind(false))
	eraser_btn.mouse_entered.connect(_on_eraser_hover.bind(true))
	eraser_btn.mouse_exited.connect(_on_eraser_hover.bind(false))
	clear_btn.mouse_entered.connect(_on_clear_hover.bind(true))
	clear_btn.mouse_exited.connect(_on_clear_hover.bind(false))


## 为按钮添加 TextureRect 子节点
func _setup_icon(btn: Button, tex: Texture2D) -> void:
	var icon_rect = TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.texture = tex
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(28, 28)
	# 用锚点填充父按钮，布局系统计算完后自动居中
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE)
	icon_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	icon_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	icon_rect.self_modulate = INACTIVE_COLOR
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon_rect)


## 获取按钮的 Icon TextureRect
func _get_icon(btn: Button) -> TextureRect:
	return btn.get_node_or_null("Icon") as TextureRect


## 更新图标状态（纹理 + 着色）
func _update_icon(btn: Button, tex: Texture2D, color: Color) -> void:
	var icon = _get_icon(btn)
	if icon:
		icon.texture = tex
		icon.self_modulate = color


func _on_pen_pressed() -> void:
	if _pen_active:
		_pen_active = false
		_update_icon(pen_btn, _pen_icon, INACTIVE_COLOR)
	else:
		_pen_active = true
		_update_icon(pen_btn, _pen_glow, PEN_ACTIVE_COLOR)
	_update_tool()


func _on_eraser_pressed() -> void:
	if _eraser_active:
		_eraser_active = false
		_update_icon(eraser_btn, _eraser_icon, INACTIVE_COLOR)
	else:
		_eraser_active = true
		_update_icon(eraser_btn, _eraser_glow, ERASER_ACTIVE_COLOR)
	_update_tool()


## 根据 pen/eraser 状态决定 current_tool（画笔优先）
func _update_tool() -> void:
	if _pen_active:
		current_tool = 1  # 画笔优先
	elif _eraser_active:
		current_tool = 2
	else:
		current_tool = 0
	tool_changed.emit(current_tool)


func _on_clear_pressed() -> void:
	clear_requested.emit()


## 悬停效果（参考 STS2 NMapDrawButton.OnFocus/OnUnfocus）
func _on_pen_hover(entering: bool) -> void:
	var icon = _get_icon(pen_btn)
	if not icon:
		return
	if entering:
		if not _pen_active:
			icon.self_modulate = PEN_ACTIVE_COLOR
	else:
		if not _pen_active:
			icon.self_modulate = INACTIVE_COLOR


func _on_eraser_hover(entering: bool) -> void:
	var icon = _get_icon(eraser_btn)
	if not icon:
		return
	if entering:
		if not _eraser_active:
			icon.self_modulate = ERASER_ACTIVE_COLOR
	else:
		if not _eraser_active:
			icon.self_modulate = INACTIVE_COLOR


func _on_clear_hover(entering: bool) -> void:
	var icon = _get_icon(clear_btn)
	if not icon:
		return
	if entering:
		icon.texture = _clear_glow
		icon.self_modulate = CLEAR_HOVER_COLOR
	else:
		icon.texture = _clear_icon
		icon.self_modulate = INACTIVE_COLOR
