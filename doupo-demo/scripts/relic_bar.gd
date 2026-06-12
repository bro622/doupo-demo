## 遗物栏UI组件
## 显示已收集的遗物图标，点击打开总览
## 支持计数遗物在右下角显示当前进度
class_name RelicBar
extends HBoxContainer

## 点击遗物信号
signal relic_clicked

var _relics: Array[RelicData] = []


func update_display(relics: Array[RelicData], player: Player = null) -> void:
	_relics = relics

	# 清除旧节点
	for child in get_children():
		child.queue_free()

	if relics.is_empty():
		return

	for relic in relics:
		var container = Control.new()
		container.custom_minimum_size = Vector2(26, 26)
		container.tooltip_text = "%s (%s)\n%s" % [relic.relic_name, relic.get_rarity_name(), relic.description]

		# 遗物按钮
		var btn = Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.mouse_filter = Control.MOUSE_FILTER_PASS

		# 尝试加载遗物图片
		var has_image = false
		if relic.image_path != "" and ResourceLoader.exists(relic.image_path):
			var tex = load(relic.image_path)
			if tex:
				btn.icon = tex
				btn.expand_icon = true
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				has_image = true

		# 无图片时使用颜色方块
		if not has_image:
			var style = StyleBoxFlat.new()
			style.bg_color = relic.icon_color
			style.border_color = relic.get_rarity_color()
			style.set_border_width_all(2)
			style.corner_radius_top_left = 2
			style.corner_radius_top_right = 2
			style.corner_radius_bottom_left = 2
			style.corner_radius_bottom_right = 2
			btn.add_theme_stylebox_override("normal", style)

			var hover_style = style.duplicate()
			hover_style.bg_color = relic.icon_color.lightened(0.2)
			btn.add_theme_stylebox_override("hover", hover_style)

		btn.pressed.connect(_on_relic_button_pressed)
		container.add_child(btn)

		# 计数徽章（仅对有计数机制的遗物显示）
		if player != null:
			var counter := _get_counter(relic, player)
			if counter >= 0:
				var badge = Label.new()
				badge.text = str(counter)
				badge.add_theme_font_size_override("font_size", 10)
				badge.add_theme_color_override("font_color", Color.WHITE)
				badge.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
				badge.add_theme_constant_override("shadow_offset_x", 1)
				badge.add_theme_constant_override("shadow_offset_y", 1)
				badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
				badge.position = Vector2(-10, -12)
				badge.size = Vector2(12, 12)
				# 背景圆点
				var bg = Panel.new()
				bg.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
				bg.position = Vector2(-12, -14)
				bg.size = Vector2(16, 16)
				var bg_style = StyleBoxFlat.new()
				bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.85)
				bg_style.corner_radius_top_left = 7
				bg_style.corner_radius_top_right = 7
				bg_style.corner_radius_bottom_left = 7
				bg_style.corner_radius_bottom_right = 7
				bg.add_theme_stylebox_override("panel", bg_style)
				container.add_child(bg)
				container.add_child(badge)

		add_child(container)


## 获取遗物当前计数，-1 表示无需显示
static func _get_counter(relic: RelicData, player: Player) -> int:
	var result := _check_counter(relic.effect_type, relic.effect_value, player)
	if result >= 0:
		return result
	result = _check_counter(relic.effect_type_2, relic.effect_value_2, player)
	if result >= 0:
		return result
	result = _check_counter(relic.effect_type_3, relic.effect_value_3, player)
	return result


static func _check_counter(effect_type: RelicData.EffectType, value: int, player: Player) -> int:
	if value <= 0:
		return -1
	match effect_type:
		RelicData.EffectType.EVERY_NTH_ATTACK_BONUS:
			return player.total_attacks_this_battle % value
		RelicData.EffectType.NTH_CARD_ENERGY_AND_DRAW:
			return player.cards_played_for_relic_count % value
		RelicData.EffectType.NTH_CARD_ENERGY:
			return player.cards_played_for_relic_count % value
	return -1


func _on_relic_button_pressed() -> void:
	relic_clicked.emit()
