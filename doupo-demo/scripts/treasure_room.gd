## 宝箱房间场景
## 点击宝箱 → 金币奖励 + 遗物选择（单人）→ 继续返回地图
extends Control

signal treasure_completed

enum Phase { CHEST_CLOSED, CHEST_OPEN, RELIC_CHOICE }

var current_phase: Phase = Phase.CHEST_CLOSED
var relic_claimed: bool = false
var leaving: bool = false
var gold_amount: int = 0
var relic_candidates: Array[RelicData] = []

@onready var chest_button: TextureButton = $ChestArea/ChestButton
@onready var gold_label: Label = $ChestArea/GoldLabel
@onready var relic_section: VBoxContainer = $RelicSection
@onready var relic_display: VBoxContainer = $RelicSection/RelicDisplay
@onready var empty_label: Label = $RelicSection/EmptyLabel
@onready var proceed_button: Button = $ProceedButton

var _chest_original_pos: Vector2
var _modulate_tween: Tween = null


func _ready() -> void:
	# 加载STS2宝箱贴图
	var chest_tex = load("res://assets/ui/treasure/stats_chest.png")
	if chest_tex:
		chest_button.texture_normal = chest_tex


func setup() -> void:
	relic_claimed = false
	leaving = false
	gold_amount = RunManager.pending_treasure_gold
	relic_candidates.clear()
	for id in RunManager.pending_treasure_relic_ids:
		var relic = RelicDatabase.get_relic(id)
		if relic != null:
			relic_candidates.append(relic)

	current_phase = Phase.CHEST_CLOSED
	chest_button.visible = true
	chest_button.disabled = false
	chest_button.modulate = Color.WHITE
	gold_label.visible = false
	relic_section.visible = false
	proceed_button.visible = false

	_chest_original_pos = chest_button.position
	if not chest_button.pressed.is_connected(_on_chest_pressed):
		chest_button.pressed.connect(_on_chest_pressed)
		chest_button.mouse_entered.connect(_on_chest_mouse_entered)
		chest_button.mouse_exited.connect(_on_chest_mouse_exited)
		proceed_button.pressed.connect(_on_proceed_pressed)


func _on_chest_pressed() -> void:
	if current_phase != Phase.CHEST_CLOSED:
		return
	current_phase = Phase.CHEST_OPEN
	chest_button.disabled = true
	AudioManager.sfx("relic_get.mp3")
	_animate_chest_open()


func _on_chest_mouse_entered() -> void:
	if current_phase == Phase.CHEST_CLOSED:
		if _modulate_tween and _modulate_tween.is_valid():
			_modulate_tween.kill()
		_modulate_tween = create_tween()
		_modulate_tween.tween_property(chest_button, "modulate", Color(1.2, 1.1, 0.8), 0.15)


func _on_chest_mouse_exited() -> void:
	if current_phase == Phase.CHEST_CLOSED:
		if _modulate_tween and _modulate_tween.is_valid():
			_modulate_tween.kill()
		_modulate_tween = create_tween()
		_modulate_tween.tween_property(chest_button, "modulate", Color.WHITE, 0.15)


func _animate_chest_open() -> void:
	# 抖动动画
	var shake = create_tween()
	for i in range(5):
		var offset_x = 6.0 if i % 2 == 0 else -6.0
		shake.tween_property(chest_button, "position:x", _chest_original_pos.x + offset_x, 0.04)
	shake.tween_property(chest_button, "position:x", _chest_original_pos.x, 0.04)
	# 缩放弹跳
	shake.tween_property(chest_button, "scale", Vector2(1.2, 1.2), 0.1)
	shake.tween_property(chest_button, "scale", Vector2(0.95, 0.95), 0.08)
	shake.tween_property(chest_button, "scale", Vector2(1.0, 1.0), 0.08)
	shake.tween_callback(_award_gold)


func _award_gold() -> void:
	PlayerManager.add_gold(gold_amount)
	RunManager.treasure_chest_opened = true

	gold_label.text = "+%d (总计: %d)" % [gold_amount, PlayerManager.gold]
	gold_label.visible = true
	gold_label.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(gold_label, "modulate", Color.WHITE, 0.3)
	_spawn_gold_particles()
	tween.tween_interval(0.3)
	tween.tween_callback(_transition_to_relic_choice)


func _spawn_gold_particles() -> void:
	var chest_center = chest_button.global_position + chest_button.size / 2.0
	var particle_texture = load("res://assets/ui/treasure/coin_explosion_coin.png")
	for i in range(12):
		var particle = TextureRect.new()
		particle.texture = particle_texture
		particle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		particle.custom_minimum_size = Vector2(16, 16)
		particle.global_position = chest_center - Vector2(8, 8)
		add_child(particle)

		var angle = randf() * TAU
		var dist = randf_range(40, 120)
		var target = chest_center + Vector2(cos(angle), sin(angle)) * dist
		var tween = create_tween().set_parallel(true)
		tween.tween_property(particle, "position", target, 0.7).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, 0.7).set_delay(0.25)
		tween.chain().tween_callback(particle.queue_free)


func _transition_to_relic_choice() -> void:
	current_phase = Phase.RELIC_CHOICE
	_display_relic_choices()


func _display_relic_choices() -> void:
	for child in relic_display.get_children():
		child.queue_free()
	relic_section.visible = true

	if relic_candidates.is_empty():
		empty_label.text = "宝箱中没有更多遗物了..."
	else:
		empty_label.text = ""
		var relic = relic_candidates[0]
		var col = _create_relic_column(relic)
		col.modulate = Color(1, 1, 1, 0)
		relic_display.add_child(col)
		var tween = create_tween()
		tween.tween_property(col, "modulate", Color.WHITE, 0.25)

	proceed_button.visible = true
	proceed_button.text = "继续"


func _create_relic_column(relic: RelicData) -> VBoxContainer:
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.custom_minimum_size = Vector2(150, 0)

	# 遗物图标（优先显示图片，无图片时用色块）
	var icon: Control
	if relic.image_path != "" and ResourceLoader.exists(relic.image_path):
		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(52, 52)
		tex_rect.texture = load(relic.image_path)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon = tex_rect
	else:
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(52, 52)
		var icon_style = StyleBoxFlat.new()
		icon_style.bg_color = relic.icon_color
		icon_style.set_corner_radius_all(10)
		icon_style.border_color = relic.get_rarity_color()
		icon_style.set_border_width_all(2)
		panel.add_theme_stylebox_override("panel", icon_style)
		icon = panel
	col.add_child(icon)

	# 名称
	var name_label = Label.new()
	name_label.text = relic.relic_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	col.add_child(name_label)

	# 稀有度
	var rarity_label = Label.new()
	rarity_label.text = relic.get_rarity_name()
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 11)
	rarity_label.add_theme_color_override("font_color", relic.get_rarity_color())
	col.add_child(rarity_label)

	# 描述（截断）
	var desc_label = Label.new()
	var short_desc = relic.description.left(28)
	if relic.description.length() > 28:
		short_desc += "..."
	desc_label.text = short_desc
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.65))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(desc_label)

	# 点击覆盖层（透明按钮，填满 icon 区域）
	var click_btn = Button.new()
	click_btn.flat = true
	click_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_btn.z_index = 10
	click_btn.pressed.connect(_on_relic_selected.bind(relic, col))
	icon.add_child(click_btn)

	return col


func _on_relic_selected(relic: RelicData, col: VBoxContainer) -> void:
	AudioManager.ui("ui_click.wav")
	if relic_claimed:
		return
	relic_claimed = true
	PlayerManager.add_relic(relic)

	# 高亮选中项，禁用所有遗物按钮
	for child in relic_display.get_children():
		if child == col:
			child.modulate = Color(0.6, 1.0, 0.6, 1.0)
		else:
			child.modulate = Color(0.4, 0.4, 0.4, 0.6)
		for btn in child.find_children("*", "Button"):
			btn.disabled = true


func _on_proceed_pressed() -> void:
	if leaving:
		return
	leaving = true
	AudioManager.ui("ui_click.wav")
	treasure_completed.emit()
