## 状态显示栏
## 通用组件，显示战斗单位的状态效果图标，悬停显示tooltip
class_name StatusBar
extends HBoxContainer

## STS2 状态效果图标路径映射
const STATUS_ICON_PATHS: Dictionary = {
	"strength":     "res://assets/ui/status-icons/sts2/status_strength.png",
	"dexterity":    "res://assets/ui/status-icons/sts2/status_dexterity.png",
	"weak":         "res://assets/ui/status-icons/sts2/status_weak.png",
	"vulnerable":   "res://assets/ui/status-icons/sts2/status_vulnerable.png",
	"frail":        "res://assets/ui/status-icons/sts2/status_frail.png",
	"venom":        "res://assets/ui/status-icons/sts2/status_venom.png",
	"burn":         "res://assets/ui/status-icons/sts2/status_burn.png",
	"frozen":       "res://assets/ui/status-icons/sts2/status_frozen.png",
	"armor_break":  "res://assets/ui/status-icons/sts2/status_armor_break.png",
	"gold_seal":    "res://assets/ui/status-icons/sts2/status_gold_seal.png",
	"petrified":    "res://assets/ui/status-icons/sts2/status_petrified.png",
}


## 更新显示(传入Combatant，读取其状态属性)
func update_display(combatant: Combatant) -> void:
	# 清除旧图标
	for child in get_children():
		child.queue_free()

	if combatant == null:
		return

	# 永久力量
	if combatant.strength != 0:
		var s_color = Color(0.85, 0.2, 0.2) if combatant.strength > 0 else Color(0.5, 0.3, 0.3)
		var s_sign = "+" if combatant.strength > 0 else ""
		_create_status_icon(str(combatant.strength), s_color,
			"力量: %s%d — 攻击伤害%s%d" % [s_sign, combatant.strength, s_sign, combatant.strength],
			STATUS_ICON_PATHS.get("strength", ""))

	# 临时力量
	if combatant.temp_strength > 0:
		_create_status_icon(str(combatant.temp_strength), Color(1.0, 0.5, 0.2),
			"临时力量: %d — 攻击伤害+%d（本回合）" % [combatant.temp_strength, combatant.temp_strength],
			STATUS_ICON_PATHS.get("strength", ""))

	# 永久敏捷
	if combatant.dexterity != 0:
		var d_color = Color(0.2, 0.75, 0.3) if combatant.dexterity > 0 else Color(0.3, 0.5, 0.3)
		var d_sign = "+" if combatant.dexterity > 0 else ""
		_create_status_icon(str(combatant.dexterity), d_color,
			"敏捷: %s%d — 护盾值%s%d" % [d_sign, combatant.dexterity, d_sign, combatant.dexterity],
			STATUS_ICON_PATHS.get("dexterity", ""))

	# 临时敏捷
	if combatant.temp_dexterity > 0:
		_create_status_icon(str(combatant.temp_dexterity), Color(0.4, 0.9, 0.5),
			"临时敏捷: %d — 护盾值+%d（本回合）" % [combatant.temp_dexterity, combatant.temp_dexterity],
			STATUS_ICON_PATHS.get("dexterity", ""))

	# 燃烧（叠层DOT，回合开始受X伤后-1，无视护盾）
	if combatant.burn > 0:
		_create_status_icon(str(combatant.burn), Color(0.9, 0.4, 0.1),
			"燃烧: ×%d — 回合开始受%d点真实伤害，然后层数-1" % [combatant.burn, combatant.burn],
			STATUS_ICON_PATHS.get("burn", ""))

	# 蛇毒（与燃烧同机制）
	if combatant.venom > 0:
		_create_status_icon(str(combatant.venom), Color(0.2, 0.7, 0.3),
			"蛇毒: ×%d — 回合开始受%d点真实伤害，然后层数-1" % [combatant.venom, combatant.venom],
			STATUS_ICON_PATHS.get("venom", ""))

	# 虚弱
	if combatant.weak > 0:
		_create_status_icon(str(combatant.weak), Color(0.4, 0.5, 0.7),
			"虚弱: %d回合 — 造成的伤害-25%%" % combatant.weak,
			STATUS_ICON_PATHS.get("weak", ""))

	# 易伤
	if combatant.vulnerable > 0:
		_create_status_icon(str(combatant.vulnerable), Color(0.6, 0.2, 0.8),
			"易伤: %d回合 — 受到的伤害+50%%" % combatant.vulnerable,
			STATUS_ICON_PATHS.get("vulnerable", ""))

	# 脆弱
	if combatant.frail > 0:
		_create_status_icon(str(combatant.frail), Color(0.7, 0.6, 0.1),
			"脆弱: %d回合 — 从卡牌获得的护盾值-25%%" % combatant.frail,
			STATUS_ICON_PATHS.get("frail", ""))

	# 冰封
	if combatant.frozen > 0:
		_create_status_icon(str(combatant.frozen), Color(0.5, 0.8, 1.0),
			"冰封: ×%d — 下回合少抽%d张牌" % [combatant.frozen, combatant.frozen],
			STATUS_ICON_PATHS.get("frozen", ""))

	# 破甲
	if combatant.armor_break > 0:
		_create_status_icon(str(combatant.armor_break), Color(0.6, 0.4, 0.2),
			"破甲: ×%d — 护盾获取量减少%d%%" % [combatant.armor_break, combatant.armor_break],
			STATUS_ICON_PATHS.get("armor_break", ""))

	# 金印（萧薰儿专属）
	if combatant.gold_seal > 0:
		_create_status_icon(str(combatant.gold_seal), Color(1.0, 0.85, 0.2),
			"金印: ×%d — 达到5层时引爆：10点真实伤害+返还1点能量" % combatant.gold_seal,
			STATUS_ICON_PATHS.get("gold_seal", ""))

	# 石化
	if combatant.petrified > 0:
		_create_status_icon(str(combatant.petrified), Color(0.5, 0.4, 0.6),
			"石化: ×%d — 受到伤害增加20%%" % combatant.petrified,
			STATUS_ICON_PATHS.get("petrified", ""))

	# 能力牌被动效果（仅玩家）— 使用图标 + 叠加计数
	if combatant is Player:
		# 统计每种能力牌的数量
		var ability_counts: Dictionary = {}  # card_id -> {card, count}
		for card in combatant.in_play:
			if card.card_type == CardData.CardType.ABILITY and not card.card_name.is_empty():
				if card.id in ability_counts:
					ability_counts[card.id].count += 1
				else:
					ability_counts[card.id] = {"card": card, "count": 1}
		for entry in ability_counts.values():
			var card = entry.card
			var count = entry.count
			var desc = card.description if not card.upgraded or card.upgraded_description.is_empty() else card.upgraded_description
			var tooltip = "【%s】%s" % [card.card_name, desc]
			if count > 1:
				tooltip += " (×%d)" % count
			_create_ability_icon(card.id, count, tooltip)


## 创建单个状态图标（参考 STS2 NPower: TextureRect 图标 + 右下角数字）
## 有 icon_path 时显示图标+数字叠加，无图标时回退到原纯色方块
func _create_status_icon(text: String, color: Color, tooltip: String, icon_path: String = "") -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(24, 24)
	btn.tooltip_text = tooltip
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	if icon_path != "" and ResourceLoader.exists(icon_path):
		# 图标模式：图标 TextureRect + 右下角数字
		btn.text = ""
		var container = Control.new()
		container.set_anchors_preset(Control.PRESET_FULL_RECT)
		container.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var tex = TextureRect.new()
		tex.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.texture = load(icon_path)
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# 圆角 shader
		var shader = load("res://shaders/rounded_icon.gdshader")
		if shader:
			var mat = ShaderMaterial.new()
			mat.shader = shader
			mat.set_shader_parameter("radius", 0.15)
			tex.material = mat
		container.add_child(tex)

		# 右下角数字 badge
		var badge = Label.new()
		badge.text = text
		badge.add_theme_font_size_override("font_size", 9)
		badge.add_theme_color_override("font_color", Color.WHITE)
		badge.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		badge.add_theme_constant_override("shadow_offset_x", 1)
		badge.add_theme_constant_override("shadow_offset_y", 1)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		badge.offset_left = -14
		badge.offset_top = -14
		badge.offset_right = -2
		badge.offset_bottom = -2
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(badge)

		btn.add_child(container)
		# normal 透明，hover 显示半透明高亮背景
		var normal_style = StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("pressed", normal_style)
		btn.add_theme_stylebox_override("focus", normal_style)
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(1, 1, 1, 0.15)
		hover_style.corner_radius_top_left = 4
		hover_style.corner_radius_top_right = 4
		hover_style.corner_radius_bottom_left = 4
		hover_style.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("hover", hover_style)
	else:
		# 回退：纯色方块 + 数字（原逻辑）
		btn.text = text
		btn.add_theme_font_size_override("font_size", 11)
		var style = StyleBoxFlat.new()
		style.bg_color = color
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_stylebox_override("focus", style)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)

	add_child(btn)


## 能力牌图标路径映射
var _ability_icon_paths: Dictionary = {
	"fire_circulate": "res://assets/ui/ability-icons/焚诀运转.png",
	"rage_burning": "res://assets/ui/ability-icons/怒火中烧.png",
	"fire_script": "res://assets/ui/ability-icons/焚诀残卷.png",
	"heavenly_fire": "res://assets/ui/ability-icons/天火三玄变.png",
	"fire_resonance": "res://assets/ui/ability-icons/异火共鸣.png",
	"fire_spirit_guard": "res://assets/ui/ability-icons/火灵护体.png",
	"cauldron_soul": "res://assets/ui/ability-icons/药鼎之魂.png",
	"qi_gather": "res://assets/ui/ability-icons/斗气凝聚.png",
	"star_body": "res://assets/ui/ability-icons/星空体质.png",
	"emperor_form": "res://assets/ui/ability-icons/炎帝之姿.png",
	"green_lotus_origin": "res://assets/ui/ability-icons/青莲地心火·本源.png",
	# 萧薰儿能力牌
	"ancient_war_will": "res://assets/ui/ability-icons/古族战意.png",
	"golden_flame_resonance": "res://assets/ui/ability-icons/金焰共鸣.png",
	"emperor_seal_engrave": "res://assets/ui/ability-icons/帝炎刻印.png",
	"ancient_bloodline": "res://assets/ui/ability-icons/古族血统.png",
	"seal_resonance": "res://assets/ui/ability-icons/印记共鸣.png",
	"light_affinity": "res://assets/ui/ability-icons/光之亲和.jpg",
	"golden_lotus_guard": "res://assets/ui/ability-icons/金莲守护.png",
	"ancient_thousand_inherit": "res://assets/ui/ability-icons/古族千年传承.png",
	"formation_master": "res://assets/ui/ability-icons/阵法大师.png",
	"divine_blood": "res://assets/ui/ability-icons/神品血脉.png",
	# 美杜莎能力牌
	"venom_body": "res://assets/ui/ability-icons/毒蛇体质.png",
	"cold_blood_killer": "res://assets/ui/ability-icons/冷血杀手.png",
	"snake_soul_resonance": "res://assets/ui/ability-icons/蛇魂共鸣.png",
	"python_venom_spread": "res://assets/ui/ability-icons/蟒毒蔓延.png",
	"stance_mastery": "res://assets/ui/ability-icons/姿态精通.png",
	"python_venom_body": "res://assets/ui/ability-icons/蟒毒体质.png",
	"queen_posture": "res://assets/ui/ability-icons/女王之姿.png",
	"ancient_bloodline_cailin": "res://assets/ui/ability-icons/远古血脉.png",
	"nine_color_python_soul": "res://assets/ui/ability-icons/九彩吞天蟒之魂.png",
	"snake_queen": "res://assets/ui/ability-icons/蛇族女王.png",
}


## 创建能力图标（图标 + 右下角叠加计数）
func _create_ability_icon(card_id: String, count: int, tooltip: String, image_path: String = "") -> void:
	var container = Control.new()
	container.custom_minimum_size = Vector2(28, 28)
	container.size = Vector2(28, 28)
	container.tooltip_text = tooltip

	# 图标（圆角裁切）— 优先用卡牌插画，回退到硬编码字典
	var tex_rect = TextureRect.new()
	tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var path = ""
	if image_path != "" and ResourceLoader.exists(image_path):
		path = image_path
	else:
		path = _ability_icon_paths.get(card_id, "")
	if path != "" and ResourceLoader.exists(path):
		tex_rect.texture = load(path)
		var shader = load("res://shaders/rounded_icon.gdshader")
		var mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("radius", 0.2)
		tex_rect.material = mat
	container.add_child(tex_rect)

	# 右下角计数（仅叠加时显示）
	if count > 1:
		var badge = Label.new()
		badge.text = str(count)
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
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.8, 0.1, 0.1, 0.9)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		bg.add_theme_stylebox_override("panel", style)
		container.add_child(bg)
		container.add_child(badge)

	add_child(container)
