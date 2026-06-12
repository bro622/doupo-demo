## 商店场景控制器
## 深色主题，两层三区网格布局
extends Control

## 信号
signal shop_completed

## 数据
var shop_items: Array[ShopManager.ShopItem] = []
var relic_items: Array[ShopManager.ShopRelicItem] = []
var potion_items: Array = []  # Array[PotionManager.ShopPotionItem]

## 覆盖层
var overlay_scene = preload("res://scenes/card_select_overlay.tscn")
var overlay_instance: Control = null

## 移除卡牌状态（每次进入商店只能移除一次）
var _card_removed: bool = false

## Tooltip
var _tooltip: Control = null

## UI引用
@onready var glass_panel: Panel = $MainContainer/GlassPanel
@onready var top_row: HBoxContainer = $MainContainer/GlassPanel/VBox/TopRow
@onready var left_zone: VBoxContainer = $MainContainer/GlassPanel/VBox/BottomRow/LeftZone
@onready var center_zone: VBoxContainer = $MainContainer/GlassPanel/VBox/BottomRow/CenterZone
@onready var right_zone: MarginContainer = $MainContainer/GlassPanel/VBox/BottomRow/RightZone
@onready var leave_button: Button = $LeaveButton

## 卡牌场景
var card_scene = preload("res://scenes/card.tscn")


func _ready() -> void:
	leave_button.pressed.connect(_on_leave_pressed)
	move_child(leave_button, get_child_count() - 1)  # 移到最上层
	_apply_panel_style(glass_panel, Color(0, 0, 0, 0), Color(0, 0, 0, 0), 12)


## 初始化商店
func setup() -> void:
	_card_removed = false
	if RunManager.shop_inventory.has("cards"):
		_load_inventory_from_save()
	else:
		shop_items = ShopManager.generate_shop_inventory()
		relic_items = ShopManager.generate_shop_relics()
		potion_items = PotionManager.generate_shop_potions()

		# 应用遗物商店折扣
		var discount = RelicManager.get_shop_discount(PlayerManager.relics)
		if discount > 0:
			for item in shop_items:
				item.price = max(1, int(item.price * (100 - discount) / 100.0))
			for item in relic_items:
				item.price = max(1, int(item.price * (100 - discount) / 100.0))
			for item in potion_items:
				item.price = max(1, int(item.price * (100 - discount) / 100.0))

		_save_inventory_to_state()

	_display_all()


## ============================================================
##  显示编排
## ============================================================

func _display_all() -> void:
	_hide_tooltip()
	_display_top_row()
	_display_left_zone()
	_display_center_zone()
	_display_right_zone()


## 上半部分：5张标准卡牌
func _display_top_row() -> void:
	for child in top_row.get_children():
		child.queue_free()

	var count = mini(shop_items.size(), 5)
	for i in range(count):
		var item = shop_items[i]
		var col = _create_card_column(item.card, item.price, item.sold, i, false)
		top_row.add_child(col)


## 左侧区块：2张特殊卡牌
func _display_left_zone() -> void:
	for child in left_zone.get_children():
		child.queue_free()

	var title = _create_section_label("卡牌")
	left_zone.add_child(title)

	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_child(row)
	left_zone.add_child(margin)

	if shop_items.size() <= 5:
		return
	for i in range(5, shop_items.size()):
		var item = shop_items[i]
		var col = _create_card_column(item.card, item.price, item.sold, i, false)
		row.add_child(col)


## 中间区块：遗物上层 + 药水下层
func _display_center_zone() -> void:
	for child in center_zone.get_children():
		child.queue_free()

	# 遗物区域
	var relic_vbox = VBoxContainer.new()
	relic_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	relic_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	relic_vbox.add_theme_constant_override("separation", 8)
	center_zone.add_child(relic_vbox)

	var relic_title = _create_section_label("遗物")
	relic_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relic_vbox.add_child(relic_title)

	var relic_row = HBoxContainer.new()
	relic_row.alignment = BoxContainer.ALIGNMENT_CENTER
	relic_row.add_theme_constant_override("separation", 12)
	relic_vbox.add_child(relic_row)

	for i in range(relic_items.size()):
		var item = relic_items[i]
		var col = _create_relic_column(item, i)
		relic_row.add_child(col)

	# 药水区域
	var potion_vbox = VBoxContainer.new()
	potion_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	potion_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	potion_vbox.add_theme_constant_override("separation", 8)
	center_zone.add_child(potion_vbox)

	var potion_title = _create_section_label("药水")
	potion_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	potion_vbox.add_child(potion_title)

	var potion_row = HBoxContainer.new()
	potion_row.alignment = BoxContainer.ALIGNMENT_CENTER
	potion_row.add_theme_constant_override("separation", 12)
	potion_vbox.add_child(potion_row)

	for i in range(potion_items.size()):
		var item = potion_items[i]
		var col = _create_potion_column(item, i)
		potion_row.add_child(col)


## 右侧区块：移除卡牌服务面板（大叉 + 价格）
func _display_right_zone() -> void:
	for child in right_zone.get_children():
		child.queue_free()

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	right_zone.add_child(vbox)

	# 大叉按钮
	var x_btn = Button.new()
	x_btn.text = "✕"
	x_btn.custom_minimum_size = Vector2(80, 80)
	x_btn.add_theme_font_size_override("font_size", 48)
	if _card_removed:
		x_btn.disabled = true
		x_btn.modulate = Color(1, 1, 1, 0.3)
	else:
		x_btn.pressed.connect(_on_removal_pressed)
	vbox.add_child(x_btn)

	# 标题
	var title = Label.new()
	title.text = "移除卡牌"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	if _card_removed:
		title.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	vbox.add_child(title)

	# 价格
	var cost = PlayerManager.get_card_removal_cost()
	var price_label = Label.new()
	if _card_removed:
		price_label.text = "本次已使用"
		price_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	else:
		price_label.text = "%d 金币" % cost
		if PlayerManager.gold < cost:
			price_label.add_theme_color_override("font_color", Color(0.7, 0.35, 0.35))
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(price_label)


## ============================================================
##  辅助创建函数
## ============================================================

## 创建卡牌列（卡牌 + 价格标签，点击卡牌直接购买）
func _create_card_column(card_data: CardData, price: int, sold: bool, index: int, is_special: bool) -> Control:
	var wrapper = Control.new()
	wrapper.custom_minimum_size = Vector2(140, 210) if not is_special else Vector2(130, 195)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 卡牌（放在wrapper内，位置在上方）
	var card_node = card_scene.instantiate() as CardNode
	card_node.setup(card_data)
	card_node.set_playable(not sold and PlayerManager.gold >= price)
	card_node.shop_mode = true
	if is_special:
		card_node.custom_minimum_size = Vector2(130, 185)
	card_node.position = Vector2.ZERO
	card_node.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 让点击穿透到覆盖按钮
	wrapper.add_child(card_node)

	# 覆盖按钮（与卡牌同尺寸，z_index更高，确保收到点击）
	var overlay_btn = Button.new()
	overlay_btn.flat = true
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0, 0, 0, 0)
	btn_style.set_content_margin_all(0)
	overlay_btn.add_theme_stylebox_override("normal", btn_style)
	overlay_btn.add_theme_stylebox_override("hover", btn_style)
	overlay_btn.add_theme_stylebox_override("pressed", btn_style)
	overlay_btn.add_theme_stylebox_override("focus", btn_style)
	overlay_btn.custom_minimum_size = card_node.custom_minimum_size
	overlay_btn.position = Vector2.ZERO
	overlay_btn.z_index = 10
	overlay_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var tip_text = "%s\n%s" % [card_data.card_name, card_data.description]
	_bind_hover(overlay_btn, wrapper, tip_text)
	if not sold:
		overlay_btn.pressed.connect(_on_buy_pressed.bind(index))
	wrapper.add_child(overlay_btn)

	# 价格标签（放在卡牌下方）
	if sold:
		var sold_label = Label.new()
		sold_label.text = "已售出"
		sold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sold_label.add_theme_font_size_override("font_size", 14)
		sold_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
		sold_label.position = Vector2(0, card_node.custom_minimum_size.y + 4)
		wrapper.add_child(sold_label)
	else:
		var price_label = Label.new()
		price_label.text = "%d 金币" % price
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_label.add_theme_font_size_override("font_size", 13)
		if PlayerManager.gold < price:
			price_label.add_theme_color_override("font_color", Color(0.7, 0.35, 0.35))
		price_label.position = Vector2(0, card_node.custom_minimum_size.y + 4)
		price_label.size = Vector2(card_node.custom_minimum_size.x, 20)
		wrapper.add_child(price_label)

	return wrapper


## 创建遗物列（色块图标 + 名称 + 价格，点击整个物品购买）
func _create_relic_column(item: ShopManager.ShopRelicItem, index: int) -> VBoxContainer:
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.alignment = BoxContainer.ALIGNMENT_CENTER

	var tip_text = "%s\n%s" % [item.relic.relic_name, item.relic.description]

	# 遗物图标（优先显示图片，无图片时用色块）
	var icon: Control
	if item.relic.image_path != "" and ResourceLoader.exists(item.relic.image_path):
		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(48, 48)
		tex_rect.size = Vector2(48, 48)
		tex_rect.texture = load(item.relic.image_path)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon = tex_rect
	else:
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(48, 48)
		var icon_style = StyleBoxFlat.new()
		icon_style.bg_color = item.relic.icon_color
		icon_style.corner_radius_top_left = 10
		icon_style.corner_radius_top_right = 10
		icon_style.corner_radius_bottom_left = 10
		icon_style.corner_radius_bottom_right = 10
		icon_style.border_color = item.relic.get_rarity_color()
		icon_style.border_width_left = 2
		icon_style.border_width_right = 2
		icon_style.border_width_top = 2
		icon_style.border_width_bottom = 2
		panel.add_theme_stylebox_override("panel", icon_style)
		icon = panel
	col.add_child(icon)

	# 名称
	var name_label = Label.new()
	name_label.text = item.relic.relic_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	col.add_child(name_label)

	# 稀有度
	var rarity_label = Label.new()
	rarity_label.text = item.relic.get_rarity_name()
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 11)
	rarity_label.add_theme_color_override("font_color", item.relic.get_rarity_color())
	col.add_child(rarity_label)

	# 价格/状态标签
	if item.sold:
		var sold_label = Label.new()
		sold_label.text = "已售出"
		sold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sold_label.add_theme_font_size_override("font_size", 13)
		sold_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
		col.add_child(sold_label)
	elif PlayerManager.has_relic(item.relic.id):
		var owned_label = Label.new()
		owned_label.text = "已拥有"
		owned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		owned_label.add_theme_font_size_override("font_size", 13)
		owned_label.add_theme_color_override("font_color", Color(0.4, 0.65, 0.4))
		col.add_child(owned_label)
	else:
		var price_label = Label.new()
		price_label.text = "%d 金币" % item.price
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_label.add_theme_font_size_override("font_size", 13)
		if PlayerManager.gold < item.price:
			price_label.add_theme_color_override("font_color", Color(0.7, 0.35, 0.35))
		col.add_child(price_label)
		# 点击整个遗物区域购买
		for child in col.get_children():
			_bind_hover(child, col, tip_text)
			if child is Label:
				child.mouse_filter = Control.MOUSE_FILTER_STOP
				child.gui_input.connect(_on_relic_item_input.bind(index))
			elif child is Panel or child is TextureRect:
				child.gui_input.connect(_on_relic_item_input.bind(index))

	return col


## 创建药水列（色块图标 + 名称 + 价格，点击整个物品购买）
func _create_potion_column(item: PotionManager.ShopPotionItem, index: int) -> VBoxContainer:
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.alignment = BoxContainer.ALIGNMENT_CENTER

	var tip_text = "%s\n%s" % [item.potion.potion_name, item.potion.description]

	# 图标（优先加载图片，回退色块）
	var icon: Control
	if item.potion.image_path != "" and ResourceLoader.exists(item.potion.image_path):
		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(44, 44)
		tex_rect.size = Vector2(44, 44)
		tex_rect.texture = load(item.potion.image_path)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var shader = load("res://shaders/rounded_icon.gdshader")
		var mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("radius", 0.25)
		tex_rect.material = mat
		icon = tex_rect
	else:
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(44, 44)
		var icon_style = StyleBoxFlat.new()
		icon_style.bg_color = item.potion.icon_color
		icon_style.corner_radius_top_left = 10
		icon_style.corner_radius_top_right = 10
		icon_style.corner_radius_bottom_left = 10
		icon_style.corner_radius_bottom_right = 10
		icon_style.border_color = item.potion.get_rarity_color()
		icon_style.border_width_left = 2
		icon_style.border_width_right = 2
		icon_style.border_width_top = 2
		icon_style.border_width_bottom = 2
		panel.add_theme_stylebox_override("panel", icon_style)
		icon = panel
	col.add_child(icon)

	# 名称
	var name_label = Label.new()
	name_label.text = item.potion.potion_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	col.add_child(name_label)

	# 价格/状态标签
	if item.sold:
		var sold_label = Label.new()
		sold_label.text = "已售出"
		sold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sold_label.add_theme_font_size_override("font_size", 13)
		sold_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
		col.add_child(sold_label)
	elif PlayerManager.potions.size() >= PlayerManager.max_potion_slots:
		var full_label = Label.new()
		full_label.text = "背包已满"
		full_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		full_label.add_theme_font_size_override("font_size", 13)
		full_label.add_theme_color_override("font_color", Color(0.7, 0.45, 0.45))
		col.add_child(full_label)
	else:
		var price_label = Label.new()
		price_label.text = "%d 金币" % item.price
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_label.add_theme_font_size_override("font_size", 13)
		if PlayerManager.gold < item.price:
			price_label.add_theme_color_override("font_color", Color(0.7, 0.35, 0.35))
		col.add_child(price_label)
		# 点击整个药水区域购买
		for child in col.get_children():
			_bind_hover(child, col, tip_text)
			if child is Label:
				child.mouse_filter = Control.MOUSE_FILTER_STOP
				child.gui_input.connect(_on_potion_item_input.bind(index))
			elif child is Panel or child is TextureRect:
				child.gui_input.connect(_on_potion_item_input.bind(index))

	return col


## 创建分区标签
func _create_section_label(text: String) -> Label:
	var label = Label.new()
	label.text = "═══ %s ═══" % text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	return label


## 面板样式（深色简洁）
func _apply_panel_style(panel: Panel, bg_color: Color, border_color: Color, radius: int) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	panel.add_theme_stylebox_override("panel", style)


## ============================================================
##  悬停交互
## ============================================================

## 为子节点绑定悬停事件（放大父列 + 显示tooltip）
func _bind_hover(child_node: Control, col: Control, tip_text: String) -> void:
	child_node.mouse_entered.connect(_on_item_hover_enter.bind(col, tip_text))
	child_node.mouse_exited.connect(_on_item_hover_exit.bind(col))


func _on_item_hover_enter(item_node: Control, tip_text: String) -> void:
	AudioManager.ui("map_hover.mp3", 0.0, AudioManager.PitchVar.SMALL)
	var tween = create_tween()
	tween.tween_property(item_node, "scale", Vector2(1.1, 1.1), 0.15)
	_show_tooltip(tip_text, item_node)


func _on_item_hover_exit(item_node: Control) -> void:
	var tween = create_tween()
	tween.tween_property(item_node, "scale", Vector2.ONE, 0.15)
	_hide_tooltip()


func _show_tooltip(text: String, anchor_node: Control) -> void:
	_hide_tooltip()

	var panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.border_color = Color(0.4, 0.4, 0.5)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_top = 6
	panel_style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", panel_style)

	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.custom_minimum_size = Vector2(200, 0)
	label.add_theme_font_size_override("normal_font_size", 13)
	# 解析 "名称\n描述" 格式，名称加粗
	var lines = text.split("\n")
	if lines.size() >= 2:
		label.text = "[b]%s[/b]\n%s" % [lines[0], lines[1]]
	else:
		label.text = text
	panel.add_child(label)

	# 添加到场景树后计算位置
	add_child(panel)
	_tooltip = panel

	# 延迟一帧等面板计算完尺寸后再定位
	await get_tree().process_frame
	if not is_instance_valid(panel):
		return
	var item_rect = anchor_node.get_global_rect()
	var panel_size = panel.size
	var screen_size = get_viewport_rect().size
	var pos_x = item_rect.position.x + (item_rect.size.x - panel_size.x) / 2.0
	var pos_y = item_rect.position.y + item_rect.size.y + 4
	# 下方空间不足时改为上方显示
	if pos_y + panel_size.y > screen_size.y - 4:
		pos_y = item_rect.position.y - panel_size.y - 4
	# 防止超出屏幕右边界
	pos_x = clampf(pos_x, 4, screen_size.x - panel_size.x - 4)
	panel.global_position = Vector2(pos_x, pos_y)


func _hide_tooltip() -> void:
	if _tooltip != null:
		_tooltip.queue_free()
		_tooltip = null


## ============================================================
##  购买/移除处理（逻辑不变）
## ============================================================

## 遗物区域点击购买（Panel/Label的gui_input信号）
func _on_relic_item_input(event: InputEvent, item_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_buy_relic_pressed(item_index)


## 药水区域点击购买（Panel/Label的gui_input信号）
func _on_potion_item_input(event: InputEvent, item_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_buy_potion_pressed(item_index)


func _on_buy_potion_pressed(item_index: int) -> void:
	if item_index >= potion_items.size():
		return
	var item = potion_items[item_index]
	if item.sold:
		return
	if PlayerManager.potions.size() >= PlayerManager.max_potion_slots:
		return
	if not PlayerManager.spend_gold(item.price):
		AudioManager.ui("deny.mp3")
		return

	PlayerManager.add_potion(item.potion)
	AudioManager.sfx("gain_potion.mp3")
	item.sold = true
	_save_inventory_to_state()
	_display_all()


func _on_buy_relic_pressed(item_index: int) -> void:
	if item_index >= relic_items.size():
		return
	var item = relic_items[item_index]
	if item.sold:
		return
	if PlayerManager.has_relic(item.relic.id):
		return
	if not PlayerManager.spend_gold(item.price):
		AudioManager.ui("deny.mp3")
		return

	item.sold = true
	PlayerManager.add_relic(item.relic)
	AudioManager.sfx("relic_get.mp3")
	_save_inventory_to_state()
	_display_all()


func _on_buy_pressed(item_index: int) -> void:
	if overlay_instance != null:
		return
	if item_index >= shop_items.size():
		return
	var item = shop_items[item_index]
	if item.sold:
		return
	if not PlayerManager.spend_gold(item.price):
		AudioManager.ui("deny.mp3")
		return

	item.sold = true
	PlayerManager.add_card_to_deck(item.card)
	AudioManager.sfx("card_deal.mp3", 0.0, AudioManager.PitchVar.SMALL)
	_save_inventory_to_state()
	_display_all()


## 移除卡牌 - 弹出覆盖层选择
func _on_removal_pressed() -> void:
	if overlay_instance != null:
		return
	AudioManager.ui("ui_click.wav")

	var cost = PlayerManager.get_card_removal_cost()
	if PlayerManager.gold < cost:
		return

	# 创建覆盖层
	overlay_instance = overlay_scene.instantiate()
	add_child(overlay_instance)

	var overlay = overlay_instance
	overlay.overlay_closed.connect(_on_overlay_closed)
	overlay.show_overlay(
		"移除卡牌",
		"选择一张卡牌从卡组中移除 (费用: %d金)" % cost,
		PlayerManager.deck
	)
	overlay.card_selected.connect(_on_card_to_remove_selected)


## 选择了要移除的卡牌
func _on_card_to_remove_selected(card) -> void:
	var cost = PlayerManager.get_card_removal_cost()
	if not PlayerManager.spend_gold(cost):
		_close_overlay()
		return

	for i in range(PlayerManager.deck.size()):
		if PlayerManager.deck[i] == card:
			PlayerManager.remove_card_from_deck(i)
			break

	_card_removed = true
	AudioManager.sfx("card_exhaust.mp3")
	_close_overlay()
	_save_inventory_to_state()
	_display_all()


func _on_overlay_closed() -> void:
	_close_overlay()


func _close_overlay() -> void:
	if overlay_instance != null:
		overlay_instance.queue_free()
		overlay_instance = null


func _on_leave_pressed() -> void:
	if overlay_instance != null:
		return
	_hide_tooltip()
	AudioManager.ui("ui_click.wav")
	shop_completed.emit()


## ============================================================
##  从RunManager保存的库存加载（逻辑不变）
## ============================================================

func _load_inventory_from_save() -> void:
	var inv = RunManager.shop_inventory

	shop_items = []
	for d in inv.get("cards", []):
		var card = CardData.from_dict(d)
		var item = ShopManager.ShopItem.new(card, d.get("price", 0))
		item.sold = d.get("sold", false)
		shop_items.append(item)

	relic_items = []
	for d in inv.get("relics", []):
		var relic = RelicDatabase.get_relic(d.get("id", -1))
		if relic != null:
			var item = ShopManager.ShopRelicItem.new(relic, d.get("price", 0))
			item.sold = d.get("sold", false)
			relic_items.append(item)

	potion_items = []
	for d in inv.get("potions", []):
		var potion = PotionDatabase.get_potion(d.get("id", -1))
		if potion != null:
			var item = PotionManager.ShopPotionItem.new(potion, d.get("price", 0))
			item.sold = d.get("sold", false)
			potion_items.append(item)


## 保存当前库存到RunManager（逻辑不变）
func _save_inventory_to_state() -> void:
	var inv = {}

	var cards = []
	for item in shop_items:
		var d = item.card.to_dict()
		d["base_price"] = d.get("base_price", item.price)  # preserve original if exists
		d["price"] = item.price
		d["sold"] = item.sold
		cards.append(d)
	inv["cards"] = cards

	var relics = []
	for item in relic_items:
		relics.append({
			"id": item.relic.id,
			"base_price": item.base_price if "base_price" in item else item.price,
			"price": item.price,
			"sold": item.sold,
		})
	inv["relics"] = relics

	var potions = []
	for item in potion_items:
		potions.append({
			"id": item.potion.id,
			"price": item.price,
			"sold": item.sold,
		})
	inv["potions"] = potions

	RunManager.shop_inventory = inv


func _find_card_in_db(card_id: String) -> CardData:
	return CardDatabase.get_card_by_id(card_id)
