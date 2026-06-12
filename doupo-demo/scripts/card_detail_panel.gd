## 卡牌详情面板
## 悬停时显示在卡牌上方，展示完整效果和标签
class_name CardDetailPanel
extends PanelContainer

## 当前显示的卡牌数据
var _card_data: CardData

## UI 引用
var _name_label: Label
var _type_label: Label
var _desc_label: RichTextLabel
var _tags_label: RichTextLabel
var _cost_label: Label

## 是否正在淡出（防止重复触发）
var _is_fading: bool = false


func _init() -> void:
	# 面板样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_color = Color(0.4, 0.4, 0.5, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	add_theme_stylebox_override("panel", style)

	# 内容布局
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	# 标题行：费用 + 名称
	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(title_hbox)

	_cost_label = Label.new()
	_cost_label.add_theme_font_size_override("font_size", 16)
	title_hbox.add_child(_cost_label)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 16)
	title_hbox.add_child(_name_label)

	# 分隔线
	var sep1 = ColorRect.new()
	sep1.custom_minimum_size = Vector2(0, 1)
	sep1.color = Color(0.35, 0.35, 0.4, 0.6)
	vbox.add_child(sep1)

	# 类型行
	_type_label = Label.new()
	_type_label.add_theme_font_size_override("font_size", 13)
	_type_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(_type_label)

	# 分隔线
	var sep2 = ColorRect.new()
	sep2.custom_minimum_size = Vector2(0, 1)
	sep2.color = Color(0.35, 0.35, 0.4, 0.6)
	vbox.add_child(sep2)

	# 描述（完整版）
	_desc_label = RichTextLabel.new()
	_desc_label.bbcode_enabled = true
	_desc_label.fit_content = true
	_desc_label.custom_minimum_size = Vector2(260, 0)
	_desc_label.add_theme_font_size_override("normal_font_size", 14)
	vbox.add_child(_desc_label)

	# 关键字标签行
	_tags_label = RichTextLabel.new()
	_tags_label.bbcode_enabled = true
	_tags_label.fit_content = true
	_tags_label.add_theme_font_size_override("normal_font_size", 13)
	vbox.add_child(_tags_label)

	# 初始隐藏
	modulate = Color(1, 1, 1, 0)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50  # 必须高于卡牌悬停的 z_index=10


## 显示卡牌详情
func show_card(card_data: CardData) -> void:
	_card_data = card_data
	_is_fading = false

	# 费用
	if card_data.cost < 0:
		_cost_label.text = "X"
	else:
		_cost_label.text = str(card_data.cost)

	# 名称（升级后变绿）
	if card_data.upgraded:
		_name_label.text = card_data.card_name + "+"
		_name_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	else:
		_name_label.text = card_data.card_name
		_name_label.add_theme_color_override("font_color", Color.WHITE)

	# 类型 + 标签
	var type_text = card_data.get_type_name()
	var tag_text = ""
	if card_data.tags.size() > 0:
		tag_text = " · " + "、".join(card_data.tags)
	_type_label.text = type_text + tag_text

	# 根据类型上色
	match card_data.card_type:
		CardData.CardType.ATTACK:
			_type_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
		CardData.CardType.SKILL:
			_type_label.add_theme_color_override("font_color", Color(0.4, 0.7, 0.9))
		CardData.CardType.ABILITY:
			_type_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.9))
		CardData.CardType.CURSE:
			_type_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
		_:
			_type_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	# 描述（优先使用 detail 完整版，否则回退到 description）
	var full_desc = card_data.detail if card_data.detail != "" else card_data.description
	_desc_label.text = full_desc

	# 关键字标签
	var keywords: Array[String] = []
	if card_data.exhaust:
		keywords.append("[color=#FFD700]消耗[/color]")
	if card_data.ethereal:
		keywords.append("[color=#FFD700]虚无[/color]")
	if card_data.innate:
		keywords.append("[color=#FFD700]固有[/color]")
	if card_data.retain:
		keywords.append("[color=#FFD700]保留[/color]")
	if card_data.true_damage:
		keywords.append("[color=#FF6B6B]真实伤害[/color]")
	if card_data.aoe:
		keywords.append("[color=#87CEEB]全体[/color]")

	if keywords.size() > 0:
		_tags_label.text = " ".join(keywords)
		_tags_label.visible = true
	else:
		_tags_label.visible = false

	# 品质边框色
	var border_color = Color(0.4, 0.4, 0.5)
	match card_data.rarity:
		CardData.CardRarity.COMMON:
			border_color = Color(0.5, 0.5, 0.5)
		CardData.CardRarity.RARE:
			border_color = Color(0.3, 0.5, 1.0)
		CardData.CardRarity.EPIC:
			border_color = Color(0.6, 0.3, 0.9)
		CardData.CardRarity.LEGENDARY:
			border_color = Color(1.0, 0.85, 0.2)
	var panel_style = get_theme_stylebox("panel") as StyleBoxFlat
	panel_style.border_color = border_color

	# 淡入
	visible = true
	_fade_in()


## 淡入动画
func _fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)


## 淡出并销毁
func fade_out() -> void:
	if _is_fading:
		return
	_is_fading = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	tween.tween_callback(queue_free)
