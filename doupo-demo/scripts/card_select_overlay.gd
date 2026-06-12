## 卡牌选择覆盖层
## 参考StS2的NCardGridSelectionScreen，提供统一的卡牌选择UI
## 暗色背景遮挡下层交互，卡牌网格使用MOUSE_FILTER_PASS确保点击可达
extends Control

## 信号
signal card_selected(card_data)
signal overlay_closed

## 卡牌场景
var card_scene = preload("res://scenes/card.tscn")

## 防止动画期间重复点击
var _closing: bool = false

## UI引用
@onready var backstop: ColorRect = $Backstop
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/TitleLabel
@onready var hint_label: Label = $Panel/HintLabel
@onready var card_grid: GridContainer = $Panel/ScrollContainer/CardGrid
@onready var close_button: Button = $Panel/CloseButton


func _ready() -> void:
	visible = false
	backstop.mouse_filter = Control.MOUSE_FILTER_STOP
	card_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	close_button.pressed.connect(_on_close_pressed)


## 显示覆盖层
func show_overlay(p_title: String, p_hint: String, cards: Array) -> void:
	_closing = false
	title_label.text = p_title
	hint_label.text = p_hint

	for child in card_grid.get_children():
		child.queue_free()

	for card_data in cards:
		var node = card_scene.instantiate() as CardNode
		node.setup(card_data)
		node.set_playable(true)
		# bind(card_data) 使 handler 签名变为 (card_node, card_data)
		node.card_clicked.connect(_on_card_clicked.bind(card_data))
		card_grid.add_child(node)

	visible = true
	modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)


## 隐藏覆盖层(非阻塞，直接隐藏)
func hide_overlay() -> void:
	visible = false


## 卡牌被点击
func _on_card_clicked(_card_node, card_data) -> void:
	if _closing:
		return
	_closing = true
	card_selected.emit(card_data)
	overlay_closed.emit()
	hide_overlay()


## 关闭按钮
func _on_close_pressed() -> void:
	if _closing:
		return
	_closing = true
	overlay_closed.emit()
	hide_overlay()
