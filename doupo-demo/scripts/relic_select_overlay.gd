## 遗物总览覆盖层
## 显示已收集遗物的详细信息列表
extends Control

## 信号
signal overlay_closed

## 防止重复点击
var _closing: bool = false

## UI引用
@onready var backstop: ColorRect = $Backstop
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/TitleLabel
@onready var relic_list: VBoxContainer = $Panel/ScrollContainer/RelicList
@onready var close_button: Button = $Panel/CloseButton


func _ready() -> void:
	visible = false
	backstop.mouse_filter = Control.MOUSE_FILTER_STOP
	close_button.pressed.connect(_on_close_pressed)


## 显示覆盖层
func show_overlay(relics: Array[RelicData]) -> void:
	_closing = false
	title_label.text = "遗物总览 (%d)" % relics.size()

	for child in relic_list.get_children():
		child.queue_free()

	if relics.is_empty():
		var empty_label = Label.new()
		empty_label.text = "尚未获得任何遗物"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 16)
		relic_list.add_child(empty_label)
	else:
		for relic in relics:
			_create_relic_row(relic)

	visible = true
	modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)


## 创建单个遗物行
func _create_relic_row(relic: RelicData) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	# 图标（优先显示图片，无图片时用色块）
	var icon: Control
	if relic.image_path != "" and ResourceLoader.exists(relic.image_path):
		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(32, 32)
		tex_rect.texture = load(relic.image_path)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon = tex_rect
	else:
		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(32, 32)
		color_rect.color = relic.icon_color
		icon = color_rect
	row.add_child(icon)

	# 信息区域
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label = Label.new()
	name_label.text = "%s (%s)" % [relic.relic_name, relic.get_rarity_name()]
	name_label.add_theme_color_override("font_color", relic.get_rarity_color())
	name_label.add_theme_font_size_override("font_size", 16)
	info.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = relic.description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(desc_label)

	row.add_child(info)
	relic_list.add_child(row)

	# 分隔线
	var sep = HSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.2)
	relic_list.add_child(sep)


## 隐藏覆盖层
func hide_overlay() -> void:
	visible = false


## 关闭按钮
func _on_close_pressed() -> void:
	if _closing:
		return
	_closing = true
	overlay_closed.emit()
	hide_overlay()
