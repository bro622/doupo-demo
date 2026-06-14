## 卡牌节点
## 可视化卡牌，支持鼠标拖拽出牌
class_name CardNode
extends Control

## 卡牌数据
var card_data: CardData

## 拖拽状态
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

## 原始位置(用于取消拖拽时恢复)
var original_position: Vector2 = Vector2.ZERO
var original_parent: Node = null
var original_index: int = -1

## 是否可打出
var can_play: bool = true
## 悬停状态
var _is_highlighted: bool = false

## 商店模式（禁用悬停放大）
var shop_mode: bool = false

## 信号
signal card_clicked(card_node)
signal detail_requested(card_data: CardData, card_global_pos: Vector2, card_size: Vector2)
signal detail_hidden()

## 悬停计时器
var _hover_timer: Timer
var _hover_delay: float = 0.3
var _detail_shown: bool = false

func _ready() -> void:
	pivot_offset = Vector2(70, 100)  # 缩放从中心点
	mouse_filter = Control.MOUSE_FILTER_STOP
	# 子节点必须IGNORE，否则会拦截鼠标事件，父节点收不到_gui_input
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 悬停信号
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	# 悬停计时器
	_hover_timer = Timer.new()
	_hover_timer.one_shot = true
	_hover_timer.timeout.connect(_on_hover_timeout)
	add_child(_hover_timer)


## 设置卡牌数据并更新显示
func setup(data: CardData) -> void:
	card_data = data
	_update_visuals()


## 更新卡牌视觉
func _update_visuals() -> void:
	if card_data == null:
		return

	# 名称（升级后加"+"并变绿）
	var name_label = $NameLabel as Label
	if card_data.upgraded:
		name_label.text = card_data.card_name + "+"
		name_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	else:
		name_label.text = card_data.card_name
		name_label.add_theme_color_override("font_color", Color.WHITE)

	# 费用
	var cost_label = $CostBadge/CostLabel as Label
	if card_data.cost < 0:
		cost_label.text = "X"
	else:
		cost_label.text = str(card_data.cost)

	# 类型
	var type_label = $TypeLabel as Label
	type_label.text = card_data.get_type_name()

	# 描述（含关键字标签）
	var desc_label = $DescLabel as RichTextLabel
	var desc_text = card_data.description
	# 添加关键字标签（黄色）
	var tags: Array[String] = []
	if card_data.exhaust:
		tags.append("[color=#FFD700]消耗[/color]")
	if card_data.ethereal:
		tags.append("[color=#FFD700]虚无[/color]")
	if card_data.innate:
		tags.append("[color=#FFD700]固有[/color]")
	if card_data.retain:
		tags.append("[color=#FFD700]保留[/color]")
	if tags.size() > 0:
		desc_text += "\n" + " ".join(tags)
	desc_label.text = desc_text

	# 卡面图片
	var art_rect = $ArtPlaceholder as TextureRect
	if card_data.image_path != "" and ResourceLoader.exists(card_data.image_path):
		art_rect.texture = load(card_data.image_path)
		art_rect.visible = true
		# 去白边 shader
		if art_rect.material == null:
			var shader = load("res://shaders/crop_art.gdshader")
			var mat = ShaderMaterial.new()
			mat.shader = shader
			art_rect.material = mat
	else:
		art_rect.texture = null
		art_rect.visible = false

	# 品质边框颜色
	var rarity_border = $RarityBorder as Panel
	var style = StyleBoxFlat.new()
	match card_data.rarity:
		CardData.CardRarity.COMMON:
			style.border_color = Color(0.7, 0.7, 0.7)  # 银白
		CardData.CardRarity.RARE:
			style.border_color = Color(0.3, 0.5, 1.0)  # 蓝色
		CardData.CardRarity.EPIC:
			style.border_color = Color(0.6, 0.3, 0.9)  # 紫色
		CardData.CardRarity.LEGENDARY:
			style.border_color = Color(1.0, 0.85, 0.2)  # 金色
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.bg_color = Color(0, 0, 0, 0)
	rarity_border.add_theme_stylebox_override("panel", style)
	# 品质边框保持默认 z_index，能量图标和数字在上面即可

	# 卡牌背景颜色
	var bg = $Background as Panel
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = _get_theme_color()
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	bg.add_theme_stylebox_override("panel", bg_style)

	# 费用徽章：用角色能量图标替代蓝色方块
	var cost_badge = $CostBadge as Panel
	cost_badge.clip_contents = true  # 裁剪子节点，防止 z_index 穿透覆盖层
	# 清除默认样式
	var empty_style = StyleBoxEmpty.new()
	cost_badge.add_theme_stylebox_override("panel", empty_style)
	# 添加能量图标 TextureRect
	var energy_icon = TextureRect.new()
	energy_icon.name = "EnergyIcon"
	var energy_path = _get_energy_icon_path()
	if energy_path != "" and ResourceLoader.exists(energy_path):
		energy_icon.texture = load(energy_path)
	energy_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	energy_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	energy_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	energy_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_badge.add_child(energy_icon)
	# 图标在第二层，数字（CostLabel）在最上层
	energy_icon.z_index = 1
	var cost_label_node = cost_badge.get_node_or_null("CostLabel")
	if cost_label_node:
		cost_label_node.z_index = 2

	# 卡牌类型对应的颜色标签
	var type_color = Color(0.5, 0.5, 0.5)
	match card_data.card_type:
		CardData.CardType.ATTACK:
			type_color = Color(0.8, 0.3, 0.3)
		CardData.CardType.SKILL:
			type_color = Color(0.3, 0.6, 0.8)
		CardData.CardType.ABILITY:
			type_color = Color(0.7, 0.5, 0.9)
	type_label.add_theme_color_override("font_color", type_color)


## 更新预览数值（含 buff/debuff 修正后的伤害/护盾/能耗）
func update_preview(player: Player, context: Dictionary = {}) -> void:
	if card_data == null:
		return

	var stats = card_data.get_preview_stats(player, context)

	# 费用预览
	var cost_label = $CostBadge/CostLabel as Label
	if stats.cost != stats.cost_base:
		cost_label.text = str(stats.cost)
		if stats.cost < stats.cost_base:
			cost_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))  # 绿色=减少
		else:
			cost_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))  # 红色=增加
	else:
		cost_label.text = str(card_data.cost)
		cost_label.add_theme_color_override("font_color", Color.WHITE)

	# 描述预览（正则替换数字 + 颜色标签）
	var desc_label = $DescLabel as RichTextLabel
	var desc = card_data.description
	var regex = RegEx.new()

	# 替换伤害数值（匹配"造成X"或"X点伤害"，兼容空格）
	if stats.damage != stats.damage_base and stats.damage_base > 0:
		var color = "green" if stats.damage > stats.damage_base else "red"
		var base_str = str(stats.damage_base)
		# 优先匹配"造成 X 点伤害"完整模式
		regex.compile("造成\\s*" + base_str + "\\s*点伤害")
		if regex.search(desc):
			desc = regex.sub(desc, "造成[color=%s]%d[/color]点伤害" % [color, stats.damage], true)
		else:
			# 匹配"造成X"
			regex.compile("造成\\s*" + base_str)
			if regex.search(desc):
				desc = regex.sub(desc, "造成[color=%s]%d[/color]" % [color, stats.damage], true)
			else:
				# 匹配"X点伤害"或"X伤害"
				regex.compile(base_str + "\\s*(点伤害|伤害)")
				if regex.search(desc):
					var match = regex.search(desc)
					var suffix = match.get_string(1)  # "点伤害" or "伤害"
					desc = regex.sub(desc, "[color=%s]%d[/color]%s" % [color, stats.damage, suffix], true)

	# 替换护盾数值（匹配"获得X"或"X点护盾"，兼容空格）
	if stats.block != stats.block_base and stats.block_base > 0:
		var color = "green" if stats.block > stats.block_base else "red"
		var base_str = str(stats.block_base)
		regex.compile("获得\\s*" + base_str + "\\s*点护盾")
		if regex.search(desc):
			desc = regex.sub(desc, "获得[color=%s]%d[/color]点护盾" % [color, stats.block], true)
		else:
			regex.compile("获得\\s*" + base_str)
			if regex.search(desc):
				desc = regex.sub(desc, "获得[color=%s]%d[/color]" % [color, stats.block], true)
			else:
				regex.compile(base_str + "\\s*点护盾")
				desc = regex.sub(desc, "[color=%s]%d[/color]点护盾" % [color, stats.block], true)

	desc_label.text = desc


## 设置可打出状态
func set_playable(playable: bool) -> void:
	can_play = playable
	if playable:
		modulate = Color.WHITE
	else:
		modulate = Color(0.5, 0.5, 0.5, 0.8)


## 弃置选择高亮状态
var _is_selected: bool = false

func is_selected() -> bool:
	return _is_selected

func set_selected(selected: bool) -> void:
	_is_selected = selected
	if selected:
		modulate = Color(1.0, 0.4, 0.4, 1.0)  # 红色高亮
		scale = Vector2(1.08, 1.08)
	else:
		modulate = Color.WHITE
		scale = Vector2.ONE


## 记录高亮前位置（用于恢复）
var _pre_highlight_pos: Vector2 = Vector2.ZERO

## 高亮卡牌(鼠标悬停)
func highlight() -> void:
	if shop_mode or is_dragging or _is_highlighted:
		return
	_is_highlighted = true
	_pre_highlight_pos = position
	var new_y = position.y - 30
	# 上边界保护
	if new_y < 0:
		new_y = 0
	position.y = new_y
	scale = Vector2(1.15, 1.15)
	z_index = 10


## 取消高亮
func unhighlight() -> void:
	if not _is_highlighted:
		return
	_is_highlighted = false
	position = _pre_highlight_pos
	scale = Vector2.ONE
	z_index = 0


## 开始拖拽
func start_drag() -> void:
	is_dragging = true
	z_index = 100
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tw.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0.9), 0.1)
	_hover_timer.stop()
	if _detail_shown:
		_detail_shown = false
		detail_hidden.emit()


## 停止拖拽
func stop_drag() -> void:
	is_dragging = false
	z_index = 0
	mouse_filter = Control.MOUSE_FILTER_STOP
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "scale", Vector2.ONE, 0.15)
	tw.parallel().tween_property(self, "modulate", Color.WHITE, 0.15)


## 设置为多目标卡牌的视觉效果
func set_multi_target_visual() -> void:
	# 多目标卡牌不需要选择目标
	pass


func _on_mouse_entered() -> void:
	if can_play:
		highlight()
	_detail_shown = false  # 确保重新进入时可以再次显示
	_hover_timer.start(_hover_delay)

func _on_mouse_exited() -> void:
	unhighlight()
	_hover_timer.stop()
	if _detail_shown:
		_detail_shown = false
		detail_hidden.emit()

func _on_hover_timeout() -> void:
	if not is_dragging and card_data != null:
		_detail_shown = true
		detail_requested.emit(card_data, global_position, size)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				card_clicked.emit(self)

## 根据卡牌类型和角色返回能量图标路径
func _get_energy_icon_path() -> String:
	# 不可打出的牌（诅咒/状态）
	if card_data.card_type == CardData.CardType.CURSE or card_data.card_type == CardData.CardType.STATUS:
		return "res://assets/ui/icons/energy_unplayable.png"
	# 角色专属牌
	match PlayerManager.character_id:
		"xiaoyan":
			return "res://assets/ui/icons/energy_xiaoyan.png"
		"xuner":
			return "res://assets/ui/icons/energy_xuner.png"
		"cailin":
			return "res://assets/ui/icons/energy_cailin.png"
	# 通用牌
	return "res://assets/ui/icons/energy_colorless.png"


## 根据当前角色返回卡牌背景主题色
func _get_theme_color() -> Color:
	match PlayerManager.character_id:
		"xuner":
			return Color(0.18, 0.15, 0.08, 1)  # 金韵
		"cailin":
			return Color(0.15, 0.08, 0.2, 1)   # 紫韵
		_:
			return Color(0.22, 0.1, 0.08, 1)   # 炎韵（萧炎/默认）
