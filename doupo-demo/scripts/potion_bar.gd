## 药水栏UI组件
## 显示药水背包，点击使用/右键丢弃
class_name PotionBar
extends HBoxContainer

## 信号
signal potion_used(potion_index: int)
signal potion_discarded(potion_index: int)

## 药水数据
var _potions: Array[PotionData] = []
var _max_slots: int = 2

## 当前打开的弹窗
var _popup: Control = null
var _popup_canvas: CanvasLayer = null


func update_display(potions: Array[PotionData], max_slots: int = 2) -> void:
	_potions = potions
	_max_slots = max_slots

	# 清除旧节点
	for child in get_children():
		child.queue_free()

	# 创建槽位
	for i in range(_max_slots):
		if i < _potions.size() and _potions[i] != null:
			var btn = _create_potion_button(_potions[i], i)
			add_child(btn)
		else:
			var empty = _create_empty_slot()
			add_child(empty)


## 创建药水按钮
func _create_potion_button(potion: PotionData, index: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(30, 30)
	btn.tooltip_text = "%s (%s)\n%s" % [potion.potion_name, potion.get_rarity_name(), potion.description]

	# 优先显示图片，否则用纯色方块
	if potion.image_path != "" and ResourceLoader.exists(potion.image_path):
		var tex = load(potion.image_path) as Texture2D
		if tex != null:
			btn.icon = tex
			btn.expand_icon = true
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
			# 图片模式：透明背景 + 边框
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0)
			style.border_color = potion.get_rarity_color()
			style.set_border_width_all(2)
			style.corner_radius_top_left = 3
			style.corner_radius_top_right = 3
			style.corner_radius_bottom_left = 3
			style.corner_radius_bottom_right = 3
			btn.add_theme_stylebox_override("normal", style)
			var hover_style = style.duplicate()
			hover_style.border_color = potion.get_rarity_color().lightened(0.3)
			btn.add_theme_stylebox_override("hover", hover_style)
			btn.pressed.connect(_on_potion_clicked.bind(index))
			return btn

	# 降级：纯色方块
	var style = StyleBoxFlat.new()
	style.bg_color = potion.icon_color
	style.border_color = potion.get_rarity_color()
	style.set_border_width_all(2)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = potion.icon_color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.pressed.connect(_on_potion_clicked.bind(index))
	return btn


## 创建空槽位
func _create_empty_slot() -> Control:
	var rect = ColorRect.new()
	rect.custom_minimum_size = Vector2(30, 30)
	rect.color = Color(0.2, 0.2, 0.2, 0.5)
	return rect


## 药水被点击 - 弹出确认
func _on_potion_clicked(index: int) -> void:
	if index < 0 or index >= _potions.size():
		return
	if _popup != null:
		return

	var potion = _potions[index]
	_popup = _create_popup(potion, index)
	# 挂到自身（通过CanvasLayer保证不被裁剪且场景切换时自动清理）
	_popup_canvas = CanvasLayer.new()
	_popup_canvas.layer = 100
	add_child(_popup_canvas)
	_popup_canvas.add_child(_popup)
	# overlay全屏覆盖
	var vp_size = get_viewport_rect().size
	_popup.position = Vector2.ZERO
	_popup.size = vp_size
	# 面板定位到药水栏附近
	var panel = _popup.get_node_or_null("PopupPanel")
	if panel:
		panel.position = Vector2(min(vp_size.x - panel.size.x, global_position.x + 40), max(0, global_position.y - 120))


## 创建使用/丢弃弹窗
func _create_popup(potion: PotionData, index: int) -> Control:
	# 半透明遮罩层：点击即关闭
	var overlay = ColorRect.new()
	overlay.name = "PopupOverlay"
	overlay.color = Color(0, 0, 0, 0)  # 纯透明，MOUSE_FILTER_STOP 保证点击接收
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.grow_horizontal = Control.GROW_DIRECTION_BOTH
	overlay.grow_vertical = Control.GROW_DIRECTION_BOTH
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_close_popup()
	)
	# 实际弹窗面板
	var panel = PanelContainer.new()
	panel.name = "PopupPanel"
	panel.z_index = 200

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.border_color = potion.get_rarity_color()
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	# 药水名称
	var name_label = Label.new()
	name_label.text = "%s (%s)" % [potion.potion_name, potion.get_rarity_name()]
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", potion.get_rarity_color())
	vbox.add_child(name_label)

	# 描述
	var desc_label = Label.new()
	desc_label.text = potion.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)

	# 按钮行
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)

	var use_btn = Button.new()
	use_btn.text = "使用"
	use_btn.flat = true
	use_btn.add_theme_color_override("font_color", Color.WHITE)
	use_btn.add_theme_color_override("font_hover_color", Color(1, 1, 0.8))
	use_btn.pressed.connect(_on_use_pressed.bind(index))
	btn_row.add_child(use_btn)

	var discard_btn = Button.new()
	discard_btn.text = "丢弃"
	discard_btn.flat = true
	discard_btn.add_theme_color_override("font_color", Color.WHITE)
	discard_btn.add_theme_color_override("font_hover_color", Color(1, 1, 0.8))
	discard_btn.pressed.connect(_on_discard_pressed.bind(index))
	btn_row.add_child(discard_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.flat = true
	cancel_btn.add_theme_color_override("font_color", Color.WHITE)
	cancel_btn.add_theme_color_override("font_hover_color", Color(1, 1, 0.8))
	cancel_btn.pressed.connect(_close_popup)
	btn_row.add_child(cancel_btn)

	vbox.add_child(btn_row)
	panel.add_child(vbox)

	# 面板加入遮罩层，遮罩层返回
	overlay.add_child(panel)

	return overlay


## 使用按钮
func _on_use_pressed(index: int) -> void:
	_close_popup()
	potion_used.emit(index)


## 丢弃按钮
func _on_discard_pressed(index: int) -> void:
	_close_popup()
	potion_discarded.emit(index)


## 关闭弹窗
func _close_popup() -> void:
	if _popup_canvas != null:
		_popup_canvas.queue_free()
		_popup_canvas = null
	_popup = null
