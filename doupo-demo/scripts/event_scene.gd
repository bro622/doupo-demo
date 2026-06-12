## 事件场景
## 上半：事件背景图
## 下半：事件标题、描述、选项、结果
extends Control

signal event_completed(needs_combat: bool, combat_id: String)
signal floor_zero_choice_selected(choice_idx: int)
signal ancient_choice_selected(choice_idx: int)

var current_event: EventModel
var needs_combat: bool = false
var combat_id: String = ""

@onready var image_rect: TextureRect = %ImageRect
@onready var detail_panel: PanelContainer = %DetailPanel
@onready var title_label: Label = %TitleLabel
@onready var desc_text: RichTextLabel = %DescText
@onready var choices_container: VBoxContainer = %ChoicesContainer
@onready var result_text: RichTextLabel = %ResultText
@onready var continue_button: Button = %ContinueButton

## 事件ID → 背景图路径（所有事件均为专属背景，不复用战斗背景）
const EVENT_BG: Dictionary = {
	# 场景一：加玛帝国
	0: "res://assets/scenes/events/event_bg_bodhitree.png",
	1: "res://assets/scenes/events/event_bg_cave.png",
	2: "res://assets/scenes/events/event_bg_xiaohall.png",
	3: "res://assets/scenes/events/event_bg_purplecave.png",
	4: "res://assets/scenes/events/event_bg_snakepool.png",
	5: "res://assets/scenes/events/event_bg_xiaocourtyard.png",
	6: "res://assets/scenes/events/event_bg_desert_road.png",
	7: "res://assets/scenes/events/event_bg_yunlan_ambush.png",
	8: "res://assets/scenes/events/event_bg_auctionhouse.png",
	9: "res://assets/scenes/events/event_bg_yaohut.png",
	10: "res://assets/scenes/events/event_bg_desertcave.png",
	# 场景二：黑角域
	11: "res://assets/scenes/events/event_bg_blood_arena.png",
	12: "res://assets/scenes/events/event_bg_hanfeng_trap.png",
	13: "res://assets/scenes/events/event_bg_mystery_merchant.png",
	14: "res://assets/scenes/events/event_bg_blood_arena.png",
	15: "res://assets/scenes/events/event_bg_assassin_ambush.png",
	16: "res://assets/scenes/events/event_bg_blood_sect_explore.png",
	17: "res://assets/scenes/events/event_bg_serpent_nest.png",
	18: "res://assets/scenes/events/event_bg_smuggler.png",
	19: "res://assets/scenes/events/event_bg_alchemist_ruins.png",
	20: "res://assets/scenes/events/event_bg_dark_auction.png",
	# 场景三：迦南学院
	21: "res://assets/scenes/events/event_bg_blazing_tower_cultivation.png",
	22: "res://assets/scenes/events/event_bg_ranking_challenge.png",
	23: "res://assets/scenes/events/event_bg_ancient_clan_treasure.png",
	24: "res://assets/scenes/events/event_bg_cultivation_deviation.png",
	25: "res://assets/scenes/events/event_bg_earth_devil_lair.png",
	26: "res://assets/scenes/events/event_bg_resource_battle.png",
	27: "res://assets/scenes/events/event_bg_herb_garden.png",
	28: "res://assets/scenes/events/event_bg_ancient_cave.png",
	29: "res://assets/scenes/events/event_bg_fallen_heart_flame.png",
	30: "res://assets/scenes/events/event_bg_inner_academy_forbidden.png",
	31: "res://assets/scenes/events/event_bg_lava_world_entrance.png",
	# 场景四：中州
	32: "res://assets/scenes/events/event_bg_pill_tower_trial.png",
	33: "res://assets/scenes/events/event_bg_soul_hall_outpost.png",
	34: "res://assets/scenes/events/event_bg_ancient_gate.png",
	35: "res://assets/scenes/events/event_bg_alliance_formed.png",
	36: "res://assets/scenes/events/event_bg_soul_hall_ambush.png",
	37: "res://assets/scenes/events/event_bg_ancient_puppet.png",
	38: "res://assets/scenes/events/event_bg_ancient_clan_trial.png",
	39: "res://assets/scenes/events/event_bg_soul_storm.png",
	40: "res://assets/scenes/events/event_bg_medicine_clan.png",
	41: "res://assets/scenes/events/event_bg_pill_tower_secret.png",
	42: "res://assets/scenes/events/event_bg_ancient_emperor_soul.png",
	43: "res://assets/scenes/events/event_bg_huntiandi_plot.png",
}


func setup(p_event: EventModel) -> void:
	current_event = p_event
	needs_combat = false

	# 加载事件背景图
	_load_event_bg(p_event.id)

	# 详情面板毛玻璃效果
	if detail_panel.material == null:
		var shader = load("res://shaders/frosted_glass.gdshader")
		var mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("blur_amount", 4.0)
		mat.set_shader_parameter("opacity", 0.65)
		mat.set_shader_parameter("tint_color", Color(0.06, 0.06, 0.09, 1.0))
		detail_panel.material = mat
	# 去掉面板默认背景
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0)
	panel_style.set_content_margin_all(0)
	detail_panel.add_theme_stylebox_override("panel", panel_style)

	# 标题 + 描述
	title_label.text = p_event.event_name
	desc_text.text = p_event.description

	# 隐藏结果区和继续按钮
	result_text.visible = false
	continue_button.visible = false

	# 连接继续按钮
	if not continue_button.pressed.is_connected(_on_continue_pressed):
		continue_button.pressed.connect(_on_continue_pressed)

	# 创建选项按钮
	_create_choice_buttons()


## 剥离BBCode标签（按钮不支持富文本）
func _strip_bbcode(text: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[/?[^\\[\\]]*\\]")
	return regex.sub(text, "", true)


func _load_event_bg(event_id: int) -> void:
	# 守灵事件：根据角色加载专属背景
	if event_id >= 100 and event_id <= 102:
		var scene_num = event_id - 98  # 100→2, 101→3, 102→4
		var char_suffix = _get_character_suffix()
		var path = "res://assets/scenes/events/event_bg_ancient_scene%d_%s.png" % [scene_num, char_suffix]
		if ResourceLoader.exists(path):
			image_rect.texture = load(path)
			image_rect.visible = true
		else:
			image_rect.visible = false
		return

	var path = EVENT_BG.get(event_id, "")
	if path != "" and ResourceLoader.exists(path):
		image_rect.texture = load(path)
		image_rect.visible = true
	else:
		image_rect.visible = false


func _get_character_suffix() -> String:
	match PlayerManager.character_id:
		"xiaoyan": return "xiaoyan"
		"xuner": return "xuner"
		"cailin": return "cailin"
		_: return "xiaoyan"


func _create_choice_buttons() -> void:
	if not is_instance_valid(choices_container):
		return
	for child in choices_container.get_children():
		if is_instance_valid(child):
			child.queue_free()

	var choices = current_event.get_choices()
	var cat_color = current_event.get_category_color()

	for i in range(choices.size()):
		var choice = choices[i]

		# 外层容器（左侧色条 + 按钮）
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 0)

		# 左侧色条
		var color_bar = ColorRect.new()
		color_bar.custom_minimum_size = Vector2(4, 0)
		color_bar.color = cat_color
		row.add_child(color_bar)

		# 选项面板（支持BBCode富文本）
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 56)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.mouse_filter = Control.MOUSE_FILTER_STOP

		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.12, 0.12, 0.18, 0.9)
		panel_style.border_color = Color(0.4, 0.4, 0.5, 0.6)
		panel_style.set_border_width_all(1)
		panel_style.set_corner_radius_all(4)
		panel_style.set_content_margin_all(8)
		panel.add_theme_stylebox_override("panel", panel_style)

		var rtl = RichTextLabel.new()
		rtl.bbcode_enabled = true
		rtl.fit_content = true
		rtl.scroll_active = false
		rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# 构建富文本
		var bbcode = "[b]%s[/b]" % choice.text
		if not choice.description_rich.is_empty():
			bbcode += "\n" + choice.description_rich
		if choice.gold_cost > 0:
			bbcode += "  [color=yellow][金币 -%d][/color]" % choice.gold_cost

		# 条件检查：禁用不满足的选项
		var is_disabled = false
		if choice.gold_cost > 0 and PlayerManager.gold < choice.gold_cost:
			is_disabled = true
			bbcode += "  [color=gray][金币不足][/color]"
		if choice.potion_cost > 0 and PlayerManager.potions.size() < choice.potion_cost:
			is_disabled = true
			bbcode += "  [color=gray][丹药不足][/color]"
		if choice.required_relic_id > 0 and not PlayerManager.has_relic(choice.required_relic_id):
			is_disabled = true
			var relic = RelicDatabase.get_relic(choice.required_relic_id)
			var relic_name = "遗物%d" % choice.required_relic_id if relic == null else relic.relic_name
			bbcode += "  [color=gray][需要「%s」][/color]" % relic_name

		rtl.text = bbcode
		panel.add_child(rtl)

		if is_disabled:
			panel.modulate = Color(0.5, 0.5, 0.5, 0.6)
			panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			panel.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					AudioManager.ui("ui_click.wav")
					_on_choice_pressed(i)
			)
			panel.mouse_entered.connect(func():
				AudioManager.ui("map_hover.mp3", 0.0, AudioManager.PitchVar.SMALL)
				panel_style.border_color = Color(0.6, 0.6, 0.8, 1.0)
				panel_style.bg_color = Color(0.18, 0.18, 0.25, 0.95)
			)
			panel.mouse_exited.connect(func():
				panel_style.border_color = Color(0.4, 0.4, 0.5, 0.6)
				panel_style.bg_color = Color(0.12, 0.12, 0.18, 0.9)
			)
		row.add_child(panel)

		choices_container.add_child(row)


func _on_choice_pressed(choice_idx: int) -> void:
	# 防止重复点击
	if continue_button.visible:
		return
	if not is_instance_valid(choices_container):
		return
	for child in choices_container.get_children():
		if is_instance_valid(child) and child is HBoxContainer:
			for sub in child.get_children():
				if is_instance_valid(sub) and sub is PanelContainer:
					sub.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if current_event is FloorZeroEvent:
		floor_zero_choice_selected.emit(choice_idx)
		result_text.visible = true
		var result_log = ""
		for line in RunManager.floor_zero_result_log:
			result_log += line + "\n"
		result_text.text = result_log
		continue_button.visible = true
		return

	if current_event is EventAncientScene2 or current_event is EventAncientScene3 or current_event is EventAncientScene4:
		ancient_choice_selected.emit(choice_idx)
		result_text.visible = true
		var result_log = ""
		for line in RunManager.ancient_result_log:
			result_log += line + "\n"
		result_text.text = result_log
		continue_button.visible = true
		return

	# 执行结果
	var result = EventManager.apply_choice(current_event, choice_idx)
	needs_combat = result.needs_combat
	combat_id = result.combat_id

	# 存储延迟奖励
	RunManager.pending_event_outcomes.clear()
	RunManager.pending_event_gold_cost = 0
	RunManager.pending_event_potion_cost = 0
	if needs_combat:
		RunManager.pending_event_id = current_event.id
	if result.has("deferred_outcomes") and not result.deferred_outcomes.is_empty():
		for o in result.deferred_outcomes:
			RunManager.pending_event_outcomes.append({
				"type": int(o.type),
				"value": o.value,
				"ref_id": o.ref_id,
				"description": o.description,
			})

	if result.has("deferred_gold_cost") and result.deferred_gold_cost > 0:
		if needs_combat:
			RunManager.pending_event_gold_cost = result.deferred_gold_cost
		else:
			PlayerManager.spend_gold(result.deferred_gold_cost)

	if result.has("deferred_potion_cost") and result.deferred_potion_cost > 0:
		if needs_combat:
			RunManager.pending_event_potion_cost = result.deferred_potion_cost
		else:
			for _i in range(result.deferred_potion_cost):
				if PlayerManager.potions.size() > 0:
					PlayerManager.remove_potion(PlayerManager.potions.size() - 1)

	# 显示结果
	result_text.visible = true
	var log_text = ""
	if result.has("log") and not result.log.is_empty():
		for line in result.log:
			log_text += line + "\n"
	else:
		log_text = "[color=gray]无事发生[/color]\n"
	result_text.text = log_text
	continue_button.visible = true


func _on_continue_pressed() -> void:
	AudioManager.ui("ui_click.wav")
	event_completed.emit(needs_combat, combat_id)
