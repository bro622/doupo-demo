## 主场景控制器
## 管理游戏流程：标题 → 地图 → 战斗/商店/休息 → 奖励 → 地图 → ...
extends Control

## 当前阶段
enum GamePhase { TITLE, FLOOR_ZERO, MAP, COMBAT, REWARD, SHOP, REST, EVENT, VICTORY, TREASURE, ANCIENT }
var current_phase: GamePhase = GamePhase.TITLE

## 当前活跃场景节点
var active_scene: Node = null

## 当前战斗类型(用于奖励生成)
var current_battle_type: RewardManager.BattleType = RewardManager.BattleType.NORMAL

## 场景预加载
var map_scene_packed = preload("res://scenes/map.tscn")
var combat_scene_packed = preload("res://scenes/combat.tscn")
var reward_scene_packed = preload("res://scenes/reward.tscn")
var shop_scene_packed = preload("res://scenes/shop.tscn")
var rest_scene_packed = preload("res://scenes/rest.tscn")
var event_scene_packed = preload("res://scenes/event.tscn")
var treasure_scene_packed = preload("res://scenes/treasure_room.tscn")
var character_select_packed = preload("res://scenes/character_select.tscn")

## UI节点
@onready var title_container: VBoxContainer = $TitleContainer
@onready var scene_container: Control = $SceneContainer

## 持久顶栏
@onready var top_bar: PanelContainer = $TopBar
@onready var top_title_label: Label = $TopBar/MarginContainer/HBox/TitleLabel
@onready var name_icon: TextureRect = $TopBar/MarginContainer/HBox/LeftGroup/NameLabel
@onready var hp_icon: TextureRect = $TopBar/MarginContainer/HBox/LeftGroup/HPIcon
@onready var hp_label: Label = $TopBar/MarginContainer/HBox/LeftGroup/HPLabel
@onready var gold_icon: TextureRect = $TopBar/MarginContainer/HBox/LeftGroup/GoldIcon
@onready var gold_label: Label = $TopBar/MarginContainer/HBox/LeftGroup/GoldLabel
@onready var deck_label: Button = $TopBar/MarginContainer/HBox/RightGroup/DeckLabel
@onready var map_button: Button = $TopBar/MarginContainer/HBox/RightGroup/MapBtn
@onready var potion_bar: PotionBar = $TopBar/MarginContainer/HBox/LeftGroup/PotionBar
@onready var relic_bar_panel: Control = $RelicBar
@onready var relic_bar: RelicBar = $RelicBar/MarginContainer/HBox/RelicIcons
@onready var settings_popup: PopupPanel = $SettingsPopup

## 地图覆盖层
@onready var map_overlay_layer: CanvasLayer = $MapOverlayLayer
@onready var map_overlay_bg: ColorRect = $MapOverlayLayer/MapOverlayBg
var map_overlay_scene: Control = null
var _map_overlay_initialized: bool = false
var _deck_badge: Label = null

## 当前战斗敌人列表（用于战斗中重新开始）
var _current_battle_enemies: Array[Enemy] = []

## 当前事件（用于事件中重新开始）
var _current_event: EventModel = null

## 遗物总览覆盖层
var relic_overlay_scene = preload("res://scenes/relic_select_overlay.tscn")
var relic_overlay_instance: Control = null

## 卡组查看覆盖层
var deck_overlay_scene = preload("res://scenes/card_select_overlay.tscn")
var deck_overlay_instance: Control = null
var _map_was_open_before_deck: bool = false


func _ready() -> void:
	get_tree().auto_accept_quit = false
	# 应用全局UI主题（按钮纹理）
	theme = preload("res://themes/ui_theme.tres")
	# 顶栏：暗色琉璃玉石背景
	_apply_top_bar_shader()
	# 遗物栏：暗青铜纹理
	_apply_relic_bar_shader()
	relic_bar.relic_clicked.connect(_on_relic_bar_clicked)
	deck_label.pressed.connect(_on_deck_label_pressed)
	map_button.pressed.connect(_toggle_map_overlay)
	PlayerManager.stats_changed.connect(_on_stats_changed)
	# potion_discarded 始终连接到 main（非战斗时处理丢弃）
	potion_bar.potion_discarded.connect(_on_potion_discarded)
	# 牌组按钮样式：始终可见
	var deck_style = StyleBoxFlat.new()
	deck_style.bg_color = Color(0.2, 0.18, 0.12, 0.8)
	deck_style.border_color = Color(0.5, 0.45, 0.3, 0.9)
	deck_style.set_border_width_all(1)
	deck_style.set_corner_radius_all(4)
	deck_style.content_margin_left = 6
	deck_style.content_margin_right = 6
	deck_style.content_margin_top = 2
	deck_style.content_margin_bottom = 2
	deck_label.add_theme_stylebox_override("normal", deck_style)
	deck_label.add_theme_stylebox_override("hover", deck_style)
	deck_label.add_theme_stylebox_override("pressed", deck_style)
	deck_label.add_theme_stylebox_override("focus", deck_style)
	deck_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7))
	deck_label.add_theme_color_override("font_hover_color", Color(1, 1, 0.8))
	# 加载顶栏图标（STS2 素材）
	hp_icon.texture = load("res://assets/ui/icons/icon_heart.png")
	gold_icon.texture = load("res://assets/ui/icons/icon_gold.png")
	# Deck 图标用 TextureRect 子节点（更可靠地控制大小）
	var deck_tex_rect = TextureRect.new()
	deck_tex_rect.texture = load("res://assets/ui/icons/icon_deck.png")
	deck_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	deck_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	deck_tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deck_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_label.add_child(deck_tex_rect)
	# Deck 右下角数字徽章（带背景色确保可见）
	var badge_bg = Panel.new()
	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = Color(0.8, 0.1, 0.1, 0.9)
	badge_style.corner_radius_top_left = 6
	badge_style.corner_radius_top_right = 6
	badge_style.corner_radius_bottom_left = 6
	badge_style.corner_radius_bottom_right = 6
	badge_bg.add_theme_stylebox_override("panel", badge_style)
	badge_bg.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	badge_bg.position = Vector2(-16, -14)
	badge_bg.size = Vector2(18, 16)
	badge_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_label.add_child(badge_bg)

	_deck_badge = Label.new()
	_deck_badge.text = str(PlayerManager.deck.size())
	_deck_badge.add_theme_font_size_override("font_size", 10)
	_deck_badge.add_theme_color_override("font_color", Color.WHITE)
	_deck_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_deck_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_deck_badge.set_anchors_preset(Control.PRESET_FULL_RECT)
	_deck_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_bg.add_child(_deck_badge)
	# 地图按钮图标
	var map_icon_tex = load("res://assets/ui/icons/icon_map.png") as Texture2D
	map_button.icon = map_icon_tex
	map_button.expand_icon = true
	map_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	# 设置按钮图标
	var settings_btn = $TopBar/MarginContainer/HBox/RightGroup/SettingsBtn as Button
	var settings_icon_tex = load("res://assets/ui/icons/icon_settings.png") as Texture2D
	settings_btn.icon = settings_icon_tex
	settings_btn.expand_icon = true
	settings_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	_show_title_screen()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_instance_valid(AudioManager) and AudioManager.has_method("shutdown"):
			AudioManager.shutdown()
		# 退出时自动保存（仅在有活跃运行时）
		if current_phase != GamePhase.TITLE and current_phase != GamePhase.VICTORY and current_phase != GamePhase.FLOOR_ZERO:
			SaveManager.save_game()
		get_tree().quit()
	elif what == NOTIFICATION_EXIT_TREE or what == NOTIFICATION_PREDELETE:
		if is_instance_valid(AudioManager) and AudioManager.has_method("shutdown"):
			AudioManager.shutdown()


func _input(event: InputEvent) -> void:
	# M 键切换地图覆盖层
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		_toggle_map_overlay()
		get_viewport().set_input_as_handled()
		return
	if current_phase == GamePhase.VICTORY:
		if event is InputEventMouseButton and event.pressed:
			_show_title_screen()


## 清除当前场景
func _clear_scene() -> void:
	_disconnect_potion_used()
	if active_scene != null:
		# 先从场景树移除（立即切断信号），再延迟销毁
		var scene = active_scene
		active_scene = null
		if scene.get_parent():
			scene.get_parent().remove_child(scene)
		scene.queue_free()


## 断开 potion_used 信号（active_scene部分由queue_free自动清理）
func _disconnect_potion_used() -> void:
	# FIX: [Bug 12] 只需切断Main常驻信号，active_scene的信号引擎queue_free会自动擦除
	if potion_bar.potion_used.is_connected(_on_potion_used):
		potion_bar.potion_used.disconnect(_on_potion_used)


## 连接药水使用/丢弃信号到战斗场景
func _connect_potion_to_scene(scene) -> void:
	_disconnect_potion_used()
	potion_bar.potion_used.connect(scene._on_potion_used)
	if not potion_bar.potion_discarded.is_connected(scene._on_potion_discarded):
		potion_bar.potion_discarded.connect(scene._on_potion_discarded)


## 连接药水使用信号到 main（非战斗状态）
func _connect_potion_to_main() -> void:
	_disconnect_potion_used()
	if not potion_bar.potion_used.is_connected(_on_potion_used):
		potion_bar.potion_used.connect(_on_potion_used)


## === 标题画面 ===

func _show_title_screen() -> void:
	current_phase = GamePhase.TITLE
	# 安全关闭地图覆盖层
	if map_overlay_layer.visible:
		map_overlay_layer.visible = false
		get_tree().paused = false
	title_container.visible = true
	scene_container.visible = false
	top_bar.visible = false
	relic_bar_panel.visible = false
	_clear_scene()
	AudioManager.sfx("logo_echo.mp3")
	# 标题页BGM播放列表（2秒交叉淡入淡出）
	var title_bgm: Array[String] = [
		"zhu_jue.mp3", "ru_shi_zhi_mo.mp3", "su.mp3", "que_yue.mp3",
		"ling_xiao.mp3", "shao_nian_lei.mp3", "zhi_po_qiong_cang.mp3", "chong_sheng.mp3",
		"sui_yuan.mp3", "ming_tian.mp3", "cong_bie_hou_tv.mp3", "cong_bie_hou_female.mp3",
	]
	AudioManager.play_bgm_playlist(title_bgm, -8.0, 2.0)

	# FIX: [Bug 9] 强制销毁悬空的全局UI覆盖层，防止内存泄漏与UI坏死
	if relic_overlay_instance != null:
		relic_overlay_instance.queue_free()
		relic_overlay_instance = null
	if deck_overlay_instance != null:
		deck_overlay_instance.queue_free()
		deck_overlay_instance = null
	# FIX: [Bug 10] 彻底释放旧局地图缓存，清除懒加载标记，防止跨局污染
	if _map_overlay_initialized:
		if map_overlay_scene != null:
			map_overlay_scene.queue_free()
			map_overlay_scene = null
		_map_overlay_initialized = false

	# 重置层数选择按钮
	_selected_start_scene = 1
	var btn_layer = title_container.get_node_or_null("BtnLayerSelect")
	if btn_layer != null:
		btn_layer.text = "起始场景：第1层"

	# 显示/隐藏继续按钮
	var btn_continue = title_container.get_node_or_null("BtnContinue")
	if btn_continue != null:
		btn_continue.visible = SaveManager.has_run_save()

	# 显示所有按钮（从胜利画面返回时恢复）
	for child in title_container.get_children():
		if child is Button:
			if child.name != "BtnContinue":
				child.visible = true


## === 角色选择 ===

func _show_character_select() -> void:
	AudioManager.stop_bgm(1.5)
	title_container.visible = false
	_clear_scene()

	var scene = character_select_packed.instantiate()
	add_child(scene)
	active_scene = scene

	scene.character_selected.connect(_on_character_selected)
	scene.cancelled.connect(_on_character_cancelled)


## 测试用：选择的起始场景
var _selected_start_scene: int = 1

func _on_character_selected(character_id: String) -> void:
	PlayerManager.selected_character = character_id
	_clear_scene()
	_start_adventure(_selected_start_scene)


func _on_character_cancelled() -> void:
	_clear_scene()
	_show_title_screen()


## === 开始冒险 ===

func _start_adventure(start_scene: int = 1) -> void:
	# 如果有旧存档，先删除
	if SaveManager.has_run_save():
		SaveManager.delete_run_save()

	# 1. 生成真随机种子
	var seed_val = Time.get_ticks_usec()
	# 2. 初始化所有Manager
	RNGManager.init_new_run(seed_val)
	PlayerManager.start_new_run()
	RunManager.init_new_run(seed_val)
	RunManager.current_scene = start_scene
	# 3. 生成地图
	var act_key = _get_act_key_for_scene(start_scene)
	RunManager.map_nodes = MapGenerator.generate_act(act_key)
	# 4. 将起点节点设为守灵事件（必须在保存前，否则重载变回战斗）
	for node in RunManager.map_nodes:
		if node.layer == 0:
			if start_scene >= 2:
				node.node_type = MapData.NodeType.ANCIENT
			else:
				node.node_type = MapData.NodeType.FLOOR_ZERO
			node.enemy_ids.clear()
	# 5. 保存种子和地图到硬盘
	SaveManager.capture_checkpoint()
	SaveManager.save_game()
	print("[Main] 新运行已保存 | 场景:%d | Seed:%d | HP:%d/%d | 金币:%d" % [start_scene, seed_val, PlayerManager.hp, PlayerManager.max_hp, PlayerManager.gold])
	# 6. 进入地图（底部为菩提古树）
	_enter_map()


## 根据场景编号获取Act配置key
func _get_act_key_for_scene(scene: int) -> String:
	match scene:
		1: return "jia_ma"
		2: return "black_corner"
		3: return "canaan"
		4: return "central_plains"
		_: return "jia_ma"


## Boss胜利后进入下一层
func _advance_to_scene(next_scene: int) -> void:
	RunManager.current_scene = next_scene
	# 进入新层时血量回满
	PlayerManager.hp = PlayerManager.max_hp
	# 清理旧地图缓存
	if _map_overlay_initialized:
		if map_overlay_scene != null:
			map_overlay_scene.queue_free()
			map_overlay_scene = null
		_map_overlay_initialized = false
	# 生成新地图
	var act_key = _get_act_key_for_scene(next_scene)
	RunManager.map_nodes = MapGenerator.generate_act(act_key)
	RunManager.current_node_id = -1
	RunManager.visited_nodes.clear()
	# 设置起点为守灵事件
	for node in RunManager.map_nodes:
		if node.layer == 0:
			if next_scene >= 2:
				node.node_type = MapData.NodeType.ANCIENT
			else:
				node.node_type = MapData.NodeType.FLOOR_ZERO
			node.enemy_ids.clear()
	# 保存并进入地图
	SaveManager.capture_checkpoint()
	SaveManager.save_game()
	print("[Main] 进入第%d层 | HP回满 %d/%d" % [next_scene, PlayerManager.hp, PlayerManager.max_hp])
	_enter_map()


## === 继续冒险（从存档加载）===

func _continue_adventure() -> void:
	if not SaveManager.load_game():
		push_warning("Main: 存档加载失败，开始新游戏")
		_start_adventure()
		return
	_continue_from_save()


## 从存档进入正确的场景（继续冒险和重新开始共用）
func _continue_from_save() -> void:
	# 检查是否有未完成的奇遇（保存并退出时正在某个场景中）
	if RunManager.saved_phase >= 0 and RunManager.current_node_id >= 0:
		match RunManager.saved_phase:
			GamePhase.FLOOR_ZERO:
				# FIX: [Bug 2] 已选择菩提古树选项后直接进地图，防止SL锁死界面
				if RunManager.floor_zero_chosen:
					_enter_map()
				else:
					_enter_floor_zero()
				return
			GamePhase.COMBAT:
				# 检查是否是事件触发的战斗（saved_event_id >= 0）
				# 如果是，回到事件选择界面而不是直接进入战斗
				if RunManager.saved_event_id >= 0:
					var event = EventDatabase.get_event(RunManager.saved_event_id)
					if event != null:
						_enter_event(event)
						return
				var node_data = RunManager.get_node_by_id(RunManager.current_node_id)
				match node_data.node_type:
					MapData.NodeType.ELITE:
						current_battle_type = RewardManager.BattleType.ELITE
					MapData.NodeType.BOSS:
						current_battle_type = RewardManager.BattleType.BOSS
					_:
						current_battle_type = RewardManager.BattleType.NORMAL
				_enter_battle(_get_enemies_for_node(node_data))
				return
			GamePhase.SHOP:
				_enter_shop()
				return
			GamePhase.REST:
				_enter_rest()
				return
			GamePhase.EVENT:
				# SL回到事件选择页面（战斗中途退出也回到事件页面重新选择）
				if RunManager.saved_event_id >= 0:
					var evt = EventDatabase.get_event(RunManager.saved_event_id)
					if evt != null:
						_enter_event(evt)
						return
				# 事件恢复失败，回退到地图
				_enter_map()
				return
			GamePhase.TREASURE:
				_enter_treasure_room()
				return
			GamePhase.ANCIENT:
				var scene = _get_ancient_chosen()
				if scene >= 0:
					_enter_map()
				else:
					_enter_ancient_event()
				return

	# 检查房间状态（战斗胜利后保存并退出 → 恢复到奖励界面）
	if RunManager.current_room_state == RunManager.RoomState.REWARD_PENDING and RunManager.current_node_id >= 0:
		current_battle_type = RunManager.reward_battle_type as RewardManager.BattleType
		_enter_reward()
		return

	# 进入地图
	_enter_map()


## === 第0层：菩提古树 ===

func _enter_floor_zero() -> void:
	current_phase = GamePhase.FLOOR_ZERO
	RunManager.saved_phase = GamePhase.FLOOR_ZERO
	RunManager.saved_event_id = 0

	# 将 layer 0 节点设为当前节点（后续标记已访问、分叉路线都要用）
	for node in RunManager.map_nodes:
		if node.layer == 0:
			RunManager.current_node_id = node.id
			break

	# 捕获checkpoint（确保保存并退出/重新开始时能恢复到此状态）
	SaveManager.capture_checkpoint()

	title_container.visible = false
	scene_container.visible = true
	_clear_scene()

	var event = FloorZeroEvent.new()
	_current_event = event

	var scene = event_scene_packed.instantiate()
	scene_container.add_child(scene)
	active_scene = scene

	scene.setup(event)
	scene.floor_zero_choice_selected.connect(_apply_floor_zero_choice)
	scene.event_completed.connect(_on_floor_zero_completed)
	_update_top_bar("菩提古树")


func _apply_floor_zero_choice(choice_idx: int) -> void:
	# 防止重复选择
	if RunManager.floor_zero_chosen:
		return
	RunManager.floor_zero_chosen = true
	RunManager.floor_zero_choice = choice_idx
	RunManager.floor_zero_result_log.clear()
	# FIX: 立即标记节点已访问，防止地图上仍可点击变暗的菩提古树
	if RunManager.current_node_id >= 0 and RunManager.current_node_id not in RunManager.visited_nodes:
		RunManager.visited_nodes.append(RunManager.current_node_id)
	RunManager.current_room_state = RunManager.RoomState.FINISHED

	# 所有选项通用：恢复全部生命值
	PlayerManager.hp = PlayerManager.max_hp
	RunManager.floor_zero_result_log.append("[color=green]恢复全部生命值[/color]")

	match choice_idx:
		0:
			# === 菩提恩赐：200金币 ===
			PlayerManager.add_gold(200)
			RunManager.floor_zero_result_log.append("[color=yellow]获得 200 金币[/color]")

		1:
			# === 菩提威压：接下来3场战斗敌人初始HP=1 ===
			RunManager.floor_zero_battles_remaining = 3
			RunManager.floor_zero_result_log.append("[color=orange]菩提威压：接下来 3 场战斗敌人初始 HP=1[/color]")

		2:
			# === 菩提试炼：失去10%最大HP + 随机稀有遗物 ===
			var hp_loss = max(1, int(PlayerManager.max_hp * 0.1))
			PlayerManager.max_hp -= hp_loss
			PlayerManager.hp = min(PlayerManager.hp, PlayerManager.max_hp)
			RunManager.floor_zero_result_log.append("[color=red]最大生命值 -%d（当前 %d/%d）[/color]" % [hp_loss, PlayerManager.hp, PlayerManager.max_hp])

			var all_rare = RelicDatabase.get_relics_by_rarity(RelicData.Rarity.RARE)
			var available: Array[RelicData] = []
			for r in all_rare:
				if not PlayerManager.has_relic(r.id) and RelicDatabase.is_available_for_character(r, PlayerManager.character_id):
					available.append(r)
			if available.size() > 0:
				var relic = available[RNGManager.event_rng.randi() % available.size()]
				PlayerManager.add_relic(relic)
				RunManager.floor_zero_result_log.append("[color=cyan]获得遗物「%s」[/color]" % relic.relic_name)
			else:
				PlayerManager.add_gold(100)
				RunManager.floor_zero_result_log.append("[color=yellow]稀有遗物已全部拥有，改为获得 100 金币[/color]")

		3:
			# === 菩提洗髓：移除2张基础牌，替换为2张随机进阶卡牌 ===
			var removals = 0
			var deck_ref = PlayerManager.deck
			var i = deck_ref.size() - 1
			while i >= 0 and removals < 2:
				var card = deck_ref[i]
				if card.id in ["basic_strike", "basic_defense", "xuner_strike", "xuner_defense", "cailin_strike", "cailin_defense"]:
					RunManager.floor_zero_result_log.append("[color=gray]移除了「%s」[/color]" % card.card_name)
					deck_ref.remove_at(i)
					removals += 1
				i -= 1

			var pool = CardDatabase.create_reward_pool_for_character(PlayerManager.character_id)
			for _j in range(removals):
				if pool.size() > 0:
					var new_card = pool[RNGManager.event_rng.randi() % pool.size()]
					PlayerManager.add_card_to_deck(new_card)
					RunManager.floor_zero_result_log.append("[color=cyan]获得「%s」（%s）[/color]" % [new_card.card_name, new_card.get_rarity_name()])
				else:
					PlayerManager.add_gold(50)
					RunManager.floor_zero_result_log.append("[color=yellow]无可用卡牌，获得 50 金币[/color]")

			if removals == 0:
				RunManager.floor_zero_result_log.append("[color=gray]牌库中没有可提纯的基础卡牌[/color]")
			elif removals < 2:
				PlayerManager.add_gold(50)
				RunManager.floor_zero_result_log.append("[color=yellow]仅找到 %d 张基础卡牌，补偿 50 金币[/color]" % removals)

	# FIX: [Bug 6] 锁死开局选择结果，阻止SL刷极品遗物
	SaveManager.capture_checkpoint()
	SaveManager.save_game()



func _on_floor_zero_completed(_needs_combat: bool = false, _combat_id: String = "") -> void:
	# 标记起点节点已访问
	if RunManager.current_node_id >= 0 and RunManager.current_node_id not in RunManager.visited_nodes:
		RunManager.visited_nodes.append(RunManager.current_node_id)

	# FIX: 彻底标记房间状态为完成，剥夺地图上的可点击与活跃状态
	RunManager.current_room_state = RunManager.RoomState.FINISHED

	RunManager.saved_phase = -1
	RunManager.saved_event_id = -1
	SaveManager.capture_checkpoint()
	SaveManager.save_game()
	_enter_map()


## === 守灵事件（场景2-4）===

## 获取当前场景守灵是否已选择（>=0表示已选）
func _get_ancient_chosen() -> int:
	match RunManager.current_scene:
		2: return 0 if RunManager.scene2_ancient_chosen else -1
		3: return 0 if RunManager.scene3_ancient_chosen else -1
		4: return 0 if RunManager.scene4_ancient_chosen else -1
		_: return -1


## 进入守灵事件
func _enter_ancient_event() -> void:
	current_phase = GamePhase.ANCIENT
	RunManager.saved_phase = GamePhase.ANCIENT
	RunManager.saved_event_id = -1

	# 满血回复
	PlayerManager.hp = PlayerManager.max_hp

	# 捕获checkpoint
	SaveManager.capture_checkpoint()

	title_container.visible = false
	scene_container.visible = true
	_clear_scene()

	# 根据场景选择事件
	var event: EventModel
	match RunManager.current_scene:
		2: event = EventAncientScene2.new()
		3: event = EventAncientScene3.new()
		4: event = EventAncientScene4.new()
		_: event = EventAncientScene2.new()
	# 设置角色专属对话文本
	event.description = event.get_dialog()
	_current_event = event

	var scene = event_scene_packed.instantiate()
	scene_container.add_child(scene)
	active_scene = scene

	scene.setup(event)
	scene.ancient_choice_selected.connect(_apply_ancient_choice)
	scene.event_completed.connect(_on_ancient_completed)

	var npc_name = _get_ancient_npc_name()
	_update_top_bar(npc_name)


## 获取守灵NPC名称（用于顶栏显示）
func _get_ancient_npc_name() -> String:
	match PlayerManager.character_id:
		"xiaoyan": return "药尘"
		"xuner": return "古族长老"
		"cailin": return "蛇族先祖"
		_: return "守灵"


## 应用守灵选项
func _apply_ancient_choice(choice_idx: int) -> void:
	# 防止重复选择
	var scene_key = "scene%d_ancient_chosen" % RunManager.current_scene
	var already_chosen = RunManager.get(scene_key)
	if already_chosen:
		return

	RunManager.set(scene_key, true)
	RunManager.set("scene%d_ancient_choice" % RunManager.current_scene, choice_idx)
	RunManager.ancient_result_log.clear()

	# 满血回复（确保）
	PlayerManager.hp = PlayerManager.max_hp

	# 标记节点已访问
	if RunManager.current_node_id >= 0 and RunManager.current_node_id not in RunManager.visited_nodes:
		RunManager.visited_nodes.append(RunManager.current_node_id)

	# 根据场景和选项应用效果
	match RunManager.current_scene:
		2: _apply_ancient_scene2(choice_idx)
		3: _apply_ancient_scene3(choice_idx)
		4: _apply_ancient_scene4(choice_idx)

	SaveManager.capture_checkpoint()
	SaveManager.save_game()


## 场景二守灵效果：卡组精简 / 卡牌获取 / 丹药储备
func _apply_ancient_scene2(choice_idx: int) -> void:
	match choice_idx:
		0: # A：移除2张基础牌 → 换2张进阶牌
			var removals = 0
			var deck_ref = PlayerManager.deck
			var i = deck_ref.size() - 1
			while i >= 0 and removals < 2:
				var card = deck_ref[i]
				if card.id in ["basic_strike", "basic_defense", "xuner_strike", "xuner_defense", "cailin_strike", "cailin_defense"]:
					deck_ref.remove_at(i)
					removals += 1
				i -= 1
			var pool = CardDatabase.create_reward_pool_for_character(PlayerManager.character_id)
			var added = 0
			while added < removals and pool.size() > 0:
				var idx = RNGManager.event_rng.randi() % pool.size()
				var new_card = pool[idx]
				PlayerManager.add_card_to_deck(new_card)
				RunManager.ancient_result_log.append("[color=cyan]获得「%s」[/color]" % new_card.card_name)
				pool.remove_at(idx)
				added += 1
			if removals < 2:
				var gold_comp = (2 - removals) * 50
				PlayerManager.add_gold(gold_comp)
				RunManager.ancient_result_log.append("[color=yellow]基础牌不足，补偿 %d 金币[/color]" % gold_comp)
			RunManager.ancient_result_log.push_front("[color=green]牌库精简完成，移除了 %d 张基础牌[/color]" % removals)

		1: # B：稀有卡 + 100金，-10%最大HP
			var pool = CardDatabase.create_reward_pool_for_character(PlayerManager.character_id)
			var rare_pool: Array[CardData] = []
			for c in pool:
				if c.rarity == CardData.CardRarity.RARE:
					rare_pool.append(c)
			if rare_pool.size() > 0:
				var card = rare_pool[RNGManager.event_rng.randi() % rare_pool.size()]
				PlayerManager.add_card_to_deck(card)
				RunManager.ancient_result_log.append("[color=cyan]获得「%s」[/color]" % card.card_name)
			PlayerManager.add_gold(100)
			var hp_loss = max(1, int(PlayerManager.max_hp * 0.1))
			PlayerManager.modify_max_hp(-hp_loss)
			RunManager.ancient_result_log.append("[color=yellow]获得 100 金币[/color]")
			RunManager.ancient_result_log.append("[color=red]最大生命值 -%d[/color]" % hp_loss)

		2: # C：2瓶高级丹药
			for _j in range(2):
				var potion = PotionManager.get_random_potion()
				if potion != null:
					PlayerManager.add_potion(potion)
					RunManager.ancient_result_log.append("[color=cyan]获得「%s」[/color]" % potion.potion_name)
				else:
					PlayerManager.add_gold(30)
					RunManager.ancient_result_log.append("[color=yellow]丹药已满，获得 30 金币[/color]")


## 场景三守灵效果：卡牌获取 / 卡组精简 / 遗物获取
func _apply_ancient_scene3(choice_idx: int) -> void:
	match choice_idx:
		0: # A：稀有卡 + 80金
			var pool = CardDatabase.create_reward_pool_for_character(PlayerManager.character_id)
			var rare_pool: Array[CardData] = []
			for c in pool:
				if c.rarity == CardData.CardRarity.RARE:
					rare_pool.append(c)
			if rare_pool.size() > 0:
				var card = rare_pool[RNGManager.event_rng.randi() % rare_pool.size()]
				PlayerManager.add_card_to_deck(card)
				RunManager.ancient_result_log.append("[color=cyan]获得「%s」[/color]" % card.card_name)
			PlayerManager.add_gold(80)
			RunManager.ancient_result_log.append("[color=yellow]获得 80 金币[/color]")

		1: # B：移除2张基础牌 → 换2张进阶牌
			var removals = 0
			var deck_ref = PlayerManager.deck
			var i = deck_ref.size() - 1
			while i >= 0 and removals < 2:
				var card = deck_ref[i]
				if card.id in ["basic_strike", "basic_defense", "xuner_strike", "xuner_defense", "cailin_strike", "cailin_defense"]:
					deck_ref.remove_at(i)
					removals += 1
				i -= 1
			var pool = CardDatabase.create_reward_pool_for_character(PlayerManager.character_id)
			var added = 0
			while added < removals and pool.size() > 0:
				var idx = RNGManager.event_rng.randi() % pool.size()
				var new_card = pool[idx]
				PlayerManager.add_card_to_deck(new_card)
				RunManager.ancient_result_log.append("[color=cyan]获得「%s」[/color]" % new_card.card_name)
				pool.remove_at(idx)
				added += 1
			if removals < 2:
				var gold_comp = (2 - removals) * 50
				PlayerManager.add_gold(gold_comp)
				RunManager.ancient_result_log.append("[color=yellow]基础牌不足，补偿 %d 金币[/color]" % gold_comp)
			RunManager.ancient_result_log.push_front("[color=green]牌库精简完成，移除了 %d 张基础牌[/color]" % removals)

		2: # C：稀有遗物，-8最大HP
			var all_rare = RelicDatabase.get_relics_by_rarity(RelicData.Rarity.RARE)
			var available: Array[RelicData] = []
			for r in all_rare:
				if not PlayerManager.has_relic(r.id) and RelicDatabase.is_available_for_character(r, PlayerManager.character_id):
					available.append(r)
			if available.size() > 0:
				var relic = available[RNGManager.event_rng.randi() % available.size()]
				PlayerManager.add_relic(relic)
				PlayerManager.modify_max_hp(-8)
				RunManager.ancient_result_log.append("[color=cyan]获得遗物「%s」[/color]" % relic.relic_name)
				RunManager.ancient_result_log.append("[color=red]最大生命值 -8[/color]")
			else:
				PlayerManager.add_gold(100)
				RunManager.ancient_result_log.append("[color=yellow]稀有遗物已全部拥有，改为获得 100 金币[/color]")


## 场景四守灵效果：卡牌升级 / 遗物获取 / 永久强化
func _apply_ancient_scene4(choice_idx: int) -> void:
	match choice_idx:
		0: # A：随机升级2张牌
			var upgradeable: Array[CardData] = []
			for card in PlayerManager.deck:
				if not card.upgraded:
					upgradeable.append(card)
			var upgraded = 0
			while upgraded < 2 and upgradeable.size() > 0:
				var idx = RNGManager.event_rng.randi() % upgradeable.size()
				upgradeable[idx].apply_upgrade()
				RunManager.ancient_result_log.append("[color=cyan]「%s」已升级[/color]" % upgradeable[idx].card_name)
				upgradeable.remove_at(idx)
				upgraded += 1
			if upgraded == 0:
				RunManager.ancient_result_log.append("[color=gray]没有可升级的卡牌[/color]")

		1: # B：稀有遗物，-10%最大HP
			var all_rare = RelicDatabase.get_relics_by_rarity(RelicData.Rarity.RARE)
			var available: Array[RelicData] = []
			for r in all_rare:
				if not PlayerManager.has_relic(r.id) and RelicDatabase.is_available_for_character(r, PlayerManager.character_id):
					available.append(r)
			if available.size() > 0:
				var relic = available[RNGManager.event_rng.randi() % available.size()]
				PlayerManager.add_relic(relic)
				var hp_loss = max(1, int(PlayerManager.max_hp * 0.1))
				PlayerManager.modify_max_hp(-hp_loss)
				RunManager.ancient_result_log.append("[color=cyan]获得遗物「%s」[/color]" % relic.relic_name)
				RunManager.ancient_result_log.append("[color=red]最大生命值 -%d[/color]" % hp_loss)
			else:
				PlayerManager.add_gold(100)
				RunManager.ancient_result_log.append("[color=yellow]稀有遗物已全部拥有，改为获得 100 金币[/color]")

		2: # C：永久+1力量
			# 永久力量通过一个持久化的flag实现，在战斗开始时应用
			RunManager.add_event_flag("ancient_power_boost")
			RunManager.ancient_result_log.append("[color=gold]永久力量 +1[/color]")


## 守灵事件完成
func _on_ancient_completed(_needs_combat: bool = false, _combat_id: String = "") -> void:
	# 标记节点已访问
	if RunManager.current_node_id >= 0 and RunManager.current_node_id not in RunManager.visited_nodes:
		RunManager.visited_nodes.append(RunManager.current_node_id)

	RunManager.current_room_state = RunManager.RoomState.FINISHED

	RunManager.saved_phase = -1
	RunManager.saved_event_id = -1
	SaveManager.capture_checkpoint()
	SaveManager.save_game()
	_enter_map()



## === 地图覆盖层 ===

func _init_map_overlay() -> void:
	if _map_overlay_initialized:
		return
	_map_overlay_initialized = true
	var map_scene = map_scene_packed.instantiate()
	map_overlay_bg.add_child(map_scene)
	map_overlay_scene = map_scene
	map_overlay_scene.node_selected.connect(_on_map_node_selected)
	map_overlay_scene.back_requested.connect(_toggle_map_overlay)
	map_overlay_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	map_overlay_bg.process_mode = Node.PROCESS_MODE_ALWAYS


func _toggle_map_overlay() -> void:
	AudioManager.ui("ui_click.wav")
	if current_phase in [GamePhase.TITLE, GamePhase.VICTORY]:
		return
	if not _map_overlay_initialized:
		_init_map_overlay()
	var opening = not map_overlay_layer.visible
	map_overlay_layer.visible = opening
	if opening:
		map_overlay_scene.setup(true)
		get_tree().paused = true
	else:
		get_tree().paused = false


## 显示/隐藏地图中的画笔层和工具栏
func _set_map_drawing_visible(show: bool) -> void:
	# 主场景中的地图（active_scene）
	if active_scene != null and active_scene.has_node("MapContainer/DrawingLayer"):
		active_scene.get_node("MapContainer/DrawingLayer").visible = show
	if active_scene != null and active_scene.has_node("Toolbar"):
		active_scene.get_node("Toolbar").visible = show
	# 覆盖层中的地图（map_overlay_scene）
	if map_overlay_scene != null and map_overlay_scene.has_node("MapContainer/DrawingLayer"):
		map_overlay_scene.get_node("MapContainer/DrawingLayer").visible = show
	if map_overlay_scene != null and map_overlay_scene.has_node("Toolbar"):
		map_overlay_scene.get_node("Toolbar").visible = show


## 启用/禁用地图输入（防止卡组等覆盖层打开时滚轮和拖拽穿透）
func _set_map_input_enabled(enabled: bool) -> void:
	if active_scene != null and "input_enabled" in active_scene:
		active_scene.input_enabled = enabled
	if map_overlay_scene != null and "input_enabled" in map_overlay_scene:
		map_overlay_scene.input_enabled = enabled


## === 地图场景 ===

func _enter_map() -> void:
	# 如果地图覆盖层打开着，先关闭
	if map_overlay_layer.visible:
		map_overlay_layer.visible = false
		get_tree().paused = false
	current_phase = GamePhase.MAP
	AudioManager.ui("map_open.mp3")
	RunManager.saved_phase = -1
	RunManager.saved_event_id = -1
	title_container.visible = false
	scene_container.visible = true
	_clear_scene()

	var scene = map_scene_packed.instantiate()
	scene_container.add_child(scene)
	active_scene = scene

	scene.setup()
	scene.node_selected.connect(_on_map_node_selected)
	_update_top_bar("%s - 第%d层" % [_get_scene_name(RunManager.current_scene), RunManager.current_scene])


## 获取场景中文名
func _get_scene_name(scene: int) -> String:
	match scene:
		1: return "加玛帝国"
		2: return "黑角域"
		3: return "迦南学院"
		4: return "中州"
		_: return "未知区域"


## === 节点选择处理 ===

func _on_map_node_selected(node_data) -> void:
	# 空检查
	if node_data == null:
		push_warning("main._on_map_node_selected: node_data is null")
		return
	# 关闭地图覆盖层
	if map_overlay_layer.visible:
		map_overlay_layer.visible = false
		get_tree().paused = false
	# 标记上一个节点已访问（玩家点击新节点=确认离开）
	if RunManager.current_node_id >= 0 and RunManager.current_room_state == RunManager.RoomState.FINISHED:
		if not RunManager.current_node_id in RunManager.visited_nodes:
			RunManager.visited_nodes.append(RunManager.current_node_id)
	# 保存当前节点ID
	RunManager.current_node_id = node_data.id
	RunManager.current_room_state = RunManager.RoomState.IN_PROGRESS
	# 非战斗节点立即标记已访问（防止重复进入）
	if node_data.node_type in [MapData.NodeType.TREASURE, MapData.NodeType.SHOP, MapData.NodeType.REST, MapData.NodeType.ANCIENT]:
		if not RunManager.current_node_id in RunManager.visited_nodes:
			RunManager.visited_nodes.append(RunManager.current_node_id)
	# 宝箱节点：预生成奖励并缓存（确保重启一致）
	if node_data.node_type == MapData.NodeType.TREASURE and RunManager.pending_treasure_relic_ids.is_empty():
		var all_relics = RelicDatabase.get_all_relics()
		var available: Array[RelicData] = []
		for r in all_relics:
			if r.id >= 100:
				continue
			if not PlayerManager.has_relic(r.id) and RelicDatabase.is_available_for_character(r, PlayerManager.character_id):
				available.append(r)
		if not available.is_empty():
			var idx = RNGManager.drop_rng.randi() % available.size()
			RunManager.pending_treasure_relic_ids.append(available[idx].id)
		RunManager.pending_treasure_gold = RNGManager.drop_rng.randi_range(30, 60)
		RunManager.treasure_chest_opened = false
	SaveManager.capture_checkpoint()
	SaveManager.save_game()

	match node_data.node_type:
		MapData.NodeType.FLOOR_ZERO:
			_enter_floor_zero()
			return
		MapData.NodeType.ANCIENT:
			_enter_ancient_event()
			return
		MapData.NodeType.MONSTER:
			current_battle_type = RewardManager.BattleType.NORMAL
			_enter_battle(_get_enemies_for_node(node_data))
		MapData.NodeType.ELITE:
			current_battle_type = RewardManager.BattleType.ELITE
			_enter_battle(_get_enemies_for_node(node_data))
		MapData.NodeType.BOSS:
			current_battle_type = RewardManager.BattleType.BOSS
			_enter_battle(_get_enemies_for_node(node_data))
		MapData.NodeType.SHOP:
			_enter_shop()
		MapData.NodeType.REST:
			_enter_rest()
		MapData.NodeType.EVENT:
			var event = EventManager.generate_event()
			if event != null:
				_enter_event(event)
			else:
				# 无可用事件时降级为原逻辑
				current_battle_type = RewardManager.BattleType.NORMAL
				PlayerManager.add_gold(15)
				_enter_battle(_get_enemies_for_node(node_data))
		MapData.NodeType.UNKNOWN:
			# 未知节点: 随机事件或战斗
			var event = EventManager.generate_event()
			if event != null:
				_enter_event(event)
			else:
				current_battle_type = RewardManager.BattleType.NORMAL
				_enter_battle(_get_enemies_for_node(node_data))
		MapData.NodeType.TREASURE:
			_enter_treasure_room()


## 获取节点对应的敌人
func _get_enemies_for_node(node_data) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	if node_data.enemy_ids.is_empty():
		enemies.append(EnemyDatabase.create_bandit())
		return enemies
	for enemy_id in node_data.enemy_ids:
		match enemy_id:
			# 场景一：魔兽山脉
			"bandit", "thug":
				enemies.append(EnemyDatabase.create_bandit())
			"magic_wolf", "wolf":
				enemies.append(EnemyDatabase.create_magic_wolf())
			"bounty_hunter":
				enemies.append(EnemyDatabase.create_bounty_hunter())
			"high_beast":
				enemies.append(EnemyDatabase.create_high_beast())
			# 场景二：塔戈尔沙漠
			"desert_scorpion":
				enemies.append(EnemyDatabase.create_desert_scorpion())
			"snake_warrior":
				enemies.append(EnemyDatabase.create_snake_warrior())
			"hai_bodong":
				enemies.append(EnemyDatabase.create_elite_hai_bodong())
			# 副场景：地底岩浆
			"fire_snake":
				enemies.append(EnemyDatabase.create_fire_snake())
			# 场景三：云岚宗
			"yunlan_disciple":
				enemies.append(EnemyDatabase.create_yunlan_disciple())
			"yunlan_inner":
				enemies.append(EnemyDatabase.create_yunlan_inner())
			"geye", "yunlan_elite":
				enemies.append(EnemyDatabase.create_elite_geye())
			"nalan":
				enemies.append(EnemyDatabase.create_elite_nalan())
			# Boss
			"yunshan":
				var boss = EnemyDatabase.create_boss_yunshan()
				if RunManager.has_event_flag("yunshan_weakened"):
					boss.strength -= 2
				enemies.append(boss)
			# === 场景二：黑角域 ===
			"bc_assassin":
				enemies.append(EnemyDatabase.create_black_corner_assassin())
			"bc_assassin_member":
				enemies.append(EnemyDatabase.create_assassin_member())
			"bc_mercenary":
				enemies.append(EnemyDatabase.create_black_corner_mercenary())
			"blood_disciple":
				enemies.append(EnemyDatabase.create_blood_disciple())
			"heretical_alchemist":
				enemies.append(EnemyDatabase.create_heretical_alchemist())
			"serpent_assassin":
				enemies.append(EnemyDatabase.create_serpent_assassin())
			"serpent_elite_assassin":
				enemies.append(EnemyDatabase.create_serpent_elite_assassin())
			"fan_lao":
				enemies.append(EnemyDatabase.create_elite_fan_lao())
			"mo_tianxing":
				enemies.append(EnemyDatabase.create_elite_mo_tianxing())
			"gold_silver_elders":
				enemies.append(EnemyDatabase.create_elite_gold_elder())
				enemies.append(EnemyDatabase.create_elite_silver_elder())
			"han_feng":
				enemies.append(EnemyDatabase.create_boss_han_feng())
			# === 场景三：迦南学院 ===
			"canaan_outer_disciple":
				enemies.append(EnemyDatabase.create_canaan_outer_disciple())
			"canaan_inner_disciple":
				enemies.append(EnemyDatabase.create_canaan_inner_disciple())
			"fire_lizard":
				enemies.append(EnemyDatabase.create_ancient_fire_lizard())
			"cultivation_deviation":
				enemies.append(EnemyDatabase.create_cultivation_deviation())
			"heart_flame_phantom":
				enemies.append(EnemyDatabase.create_heart_flame_phantom())
			"forest_beast":
				enemies.append(EnemyDatabase.create_forest_beast())
			"lin_xiuya":
				enemies.append(EnemyDatabase.create_elite_lin_xiuya())
			"liu_qing":
				enemies.append(EnemyDatabase.create_elite_liu_qing())
			"earth_devil":
				enemies.append(EnemyDatabase.create_elite_earth_devil())
			"han_yue":
				enemies.append(EnemyDatabase.create_elite_han_yue())
			"ziyan":
				enemies.append(EnemyDatabase.create_elite_ziyan())
			"forbidden_guard":
				enemies.append(EnemyDatabase.create_elite_forbidden_guard())
			"fallen_heart_flame":
				enemies.append(EnemyDatabase.create_boss_fallen_heart_flame())
			# === 场景四：中州 ===
			"soul_hall_guard":
				enemies.append(EnemyDatabase.create_soul_hall_guard())
			"dark_soul_messenger":
				enemies.append(EnemyDatabase.create_dark_soul_messenger())
			"soul_hall_elder":
				enemies.append(EnemyDatabase.create_soul_hall_elder())
			"ancient_puppet":
				enemies.append(EnemyDatabase.create_ancient_puppet())
			"ancient_clan_warrior":
				enemies.append(EnemyDatabase.create_ancient_clan_warrior())
			"soul_phantom":
				enemies.append(EnemyDatabase.create_soul_phantom())
			"pill_tower_guard":
				enemies.append(EnemyDatabase.create_pill_tower_guard())
			"yao_dan":
				enemies.append(EnemyDatabase.create_elite_yao_dan())
			"hun_miesheng":
				enemies.append(EnemyDatabase.create_elite_hun_miesheng())
			"soul_hall_elder_elite":
				enemies.append(EnemyDatabase.create_elite_soul_hall_elder())
			"soul_elders_group":
				enemies.append(EnemyDatabase.create_soul_elder_a())
				enemies.append(EnemyDatabase.create_soul_elder_b())
				enemies.append(EnemyDatabase.create_soul_elder_c())
				enemies.append(EnemyDatabase.create_soul_elder_d())
			"huntiandi":
				var boss = EnemyDatabase.create_boss_huntiandi()
				if RunManager.has_event_flag("huntiandi_hp_reduced"):
					boss.hp -= 100
					boss.max_hp = boss.hp
				if RunManager.has_event_flag("huntiandi_strength_reduced"):
					boss.strength -= 2
				enemies.append(boss)
			_:
				var floor = _get_current_floor()
				enemies.append(EnemyDatabase.create_random_normal_enemy(floor))
	return enemies


## 获取当前楼层（从RunManager节点数据推导）
func _get_current_floor() -> int:
	for node in RunManager.map_nodes:
		if node.id == RunManager.current_node_id:
			return node.layer
	return 0


## === 战斗场景 ===

func _enter_battle(enemies: Array[Enemy], from_event: bool = false) -> void:
	current_phase = GamePhase.COMBAT
	_current_battle_enemies = enemies.duplicate()
	PlayerManager.battle_start_hp = PlayerManager.hp
	AudioManager.battle_start()
	# BOSS战斗播放登场音效
	if current_battle_type == RewardManager.BattleType.BOSS:
		AudioManager.sfx("regent_intro.wav")
		# 联盟集结：将基础打击/基础防御替换为稀有卡牌
		if RunManager.has_event_flag("alliance_formed"):
			var rare_pool = CardDatabase.create_reward_pool_for_character(PlayerManager.character_id)
			var rare_cards: Array[CardData] = []
			for c in rare_pool:
				if c.rarity == CardData.CardRarity.RARE:
					rare_cards.append(c)
			if rare_cards.size() > 0:
				var replaced = 0
				for i in range(PlayerManager.deck.size() - 1, -1, -1):
					var card = PlayerManager.deck[i]
					if card.id == "basic_strike" or card.id == "basic_defense":
						var new_card = rare_cards[RNGManager.event_rng.randi() % rare_cards.size()].duplicate_card()
						PlayerManager.deck[i] = new_card
						replaced += 1
				if replaced > 0:
					print("[联盟集结] 替换了 %d 张基础牌为稀有卡牌" % replaced)
	# 从事件进入战斗时：保留saved_phase=EVENT
	# 直接进入战斗时：设置saved_phase=COMBAT
	if not from_event:
		RunManager.saved_phase = GamePhase.COMBAT
	title_container.visible = false
	scene_container.visible = true
	_clear_scene()

	var scene = combat_scene_packed.instantiate()
	scene_container.add_child(scene)
	active_scene = scene

	# 保存初始牌序（用于重启战斗时恢复）
	PlayerManager.initial_deck_order = PlayerManager.deck.duplicate()

	# 从PlayerManager创建Player
	var player = Player.new(PlayerManager.player_name, PlayerManager.max_hp)
	player.hp = PlayerManager.hp
	player.energy_per_turn = 3
	player.max_energy = 3
	player.cards_per_turn = 5

	# 重启时使用保存的洗牌后牌序（不重新洗牌），首次进入时正常洗牌并保存
	if not PlayerManager.battle_start_draw_pile.is_empty():
		player.draw_pile.clear()
		for card in PlayerManager.battle_start_draw_pile:
			player.draw_pile.append(card.duplicate_card())
		player.hand.clear()
		player.discard_pile.clear()
	else:
		player.init_deck(PlayerManager.deck)
		# 保存洗牌后的牌库顺序（用于重启时恢复完全相同的牌序）
		PlayerManager.battle_start_draw_pile.clear()
		for card in player.draw_pile:
			PlayerManager.battle_start_draw_pile.append(card.duplicate_card())

	# 事件14选项B：赌博诅咒 — 下场战斗获得2张风缠（一次性）
	if RunManager.has_event_flag("arena_gamble_curse"):
		RunManager.remove_event_flag("arena_gamble_curse")
		var wind_tangle = CardDatabase.get_card_by_id("wind_tangle")
		if wind_tangle:
			for _i in range(2):
				var curse_card = wind_tangle.duplicate_card()
				player.draw_pile.append(curse_card)
				PlayerManager.battle_start_draw_pile.append(curse_card.duplicate_card())

	# FIX: [Bug 3] checkpoint必须在牌序、HP数据完全就绪后捕获，否则SL会丢失洗牌结果
	if not from_event:
		SaveManager.capture_checkpoint()

	# 菩提威压（第0层选项2）：前3场战斗敌人初始HP=1
	if RunManager.floor_zero_battles_remaining > 0:
		for enemy in enemies:
			enemy.max_hp = 1
			enemy.hp = 1
		RunManager.floor_zero_battles_remaining -= 1
		if RunManager.floor_zero_battles_remaining == 0:
			print("[Main] 菩提威压效果已耗尽")

	scene.battle_ended.connect(_on_battle_ended)
	scene.player_hp_changed.connect(_on_combat_hp_changed)
	scene.deck_count_changed.connect(_on_deck_count_changed)
	scene.start_battle(player, enemies, current_battle_type)
	_update_top_bar("战斗中")

	# 连接药水信号到战斗场景
	_connect_potion_to_scene(scene)


# FIX: [Bug 11] _restart_battle() 已删除 — 零引用死代码，战斗重启走checkpoint恢复流水线


func _on_battle_ended(victory: bool) -> void:
	# 断开战斗信号，恢复药水信号到 main
	if active_scene != null:
		if active_scene.player_hp_changed.is_connected(_on_combat_hp_changed):
			active_scene.player_hp_changed.disconnect(_on_combat_hp_changed)
	_connect_potion_to_main()

	# 清除战斗牌序缓存（下次战斗重新洗牌）
	PlayerManager.battle_start_draw_pile.clear()

	if victory:
		# 同步HP回PlayerManager
		if active_scene != null and active_scene.battle_manager != null:
			PlayerManager.set_hp(active_scene.battle_manager.player.hp)

		# 阶段标记（战斗已完成，接受更改）
		RunManager.saved_phase = -1
		RunManager.saved_event_id = -1

		# 更新顶栏HP
		_update_top_bar()

		# === [FIX: Bug 3 & Bug 5] 战斗胜利，结算事件的"门票欠条" ===
		if RunManager.pending_event_gold_cost > 0:
			PlayerManager.spend_gold(RunManager.pending_event_gold_cost)
			RunManager.pending_event_gold_cost = 0

		if RunManager.pending_event_potion_cost > 0:
			for _i in range(RunManager.pending_event_potion_cost):
				if PlayerManager.potions.size() > 0:
					PlayerManager.remove_potion(PlayerManager.potions.size() - 1)
			RunManager.pending_event_potion_cost = 0

		# === [FIX: Bug 6] 收集幽灵奖励文本 ===
		var special_reward_msg = ""

		# 1. 应用事件战斗延迟奖励（胜利后才发放的遗物/卡牌/金币等）
		if not RunManager.pending_event_outcomes.is_empty():
			var fake_result = { "log": [] }
			for o in RunManager.pending_event_outcomes:
				var outcome = EventModel.EventOutcome.new(
					o["type"] as EventModel.OutcomeType, o["value"], o["ref_id"], o.get("description", ""))
				EventManager._execute_outcome(outcome, fake_result)
			RunManager.pending_event_outcomes.clear()
			# 提取结果并追加到弹窗文本中
			for line in fake_result.log:
				special_reward_msg += line + "\n"

		# 标记事件完成
		if RunManager.pending_event_id >= 0 and RunManager.pending_event_id not in RunManager.completed_events:
			RunManager.completed_events.append(RunManager.pending_event_id)
		RunManager.pending_event_id = -1

		# 战斗胜利标记节点已访问
		if not RunManager.current_node_id in RunManager.visited_nodes:
			RunManager.visited_nodes.append(RunManager.current_node_id)

		# Boss胜利检查
		var current_node = RunManager.get_node_by_id(RunManager.current_node_id)
		if current_node.node_type == MapData.NodeType.BOSS:
			var three_year_active = PlayerManager.has_relic(51) or RunManager.has_event_flag("three_year_promise")
			if three_year_active:
				if PlayerManager.has_relic(51):
					PlayerManager.remove_relic(51)
				var leg_cards = CardDatabase.create_reward_pool_for_character(PlayerManager.character_id)
				var legendary_cards: Array[CardData] = []
				for c in leg_cards:
					if c.rarity == CardData.CardRarity.LEGENDARY:
						legendary_cards.append(c)
				if legendary_cards.size() > 0:
					var card = legendary_cards[RNGManager.event_rng.randi() % legendary_cards.size()]
					PlayerManager.add_card_to_deck(card)
					# [FIX: Bug 6] 收集三年之约的奖励文本
					special_reward_msg += "履行三年之约，获得传说卡牌「%s」\n" % card.card_name

			RunManager.current_room_state = RunManager.RoomState.FINISHED
			SaveManager.capture_checkpoint()
			SaveManager.save_game()
			var progress_data = SaveManager.load_progress()
			progress_data["boss_defeated_count"] = progress_data.get("boss_defeated_count", 0) + 1
			if three_year_active:
				progress_data["unlocked_legendary_pool"] = true
			SaveManager.save_progress(progress_data)

			# 进入下一层或胜利
			if RunManager.current_scene < 4:
				# 还有下一层，继续
				SaveManager.delete_run_save()
				var next_scene = RunManager.current_scene + 1
				if special_reward_msg != "":
					_play_boss_defeat_bgm_and_then(
						_show_special_reward_dialog.bind(special_reward_msg, Callable(self, "_advance_to_scene").bind(next_scene)))
				else:
					_play_boss_defeat_bgm_and_then(Callable(self, "_advance_to_scene").bind(next_scene))
			else:
				# 已通关，显示胜利
				SaveManager.delete_run_save()
				if special_reward_msg != "":
					_play_boss_defeat_bgm_and_then(
						_show_special_reward_dialog.bind(special_reward_msg, Callable(self, "_show_victory")))
				else:
					_play_boss_defeat_bgm_and_then(Callable(self, "_show_victory"))
			return

		# 设置房间状态为等待奖励
		RunManager.current_room_state = RunManager.RoomState.REWARD_PENDING
		RunManager.reward_battle_type = int(current_battle_type)

		# 保存战斗胜利后的状态
		SaveManager.capture_checkpoint()
		SaveManager.save_game()

		# [FIX: Bug 6] 有奖励展示弹窗，无奖励直接进常规奖励界面
		if special_reward_msg != "":
			_show_special_reward_dialog(special_reward_msg, Callable(self, "_enter_reward"))
		else:
			_enter_reward()
	else:
		# 战斗失败 - 清除延迟奖励，删除存档，返回标题
		RunManager.pending_event_outcomes.clear()
		RunManager.pending_event_id = -1
		RunManager.pending_event_gold_cost = 0
		RunManager.pending_event_potion_cost = 0
		SaveManager.delete_run_save()
		_show_title_screen()


## === 奖励场景 ===

func _enter_reward() -> void:
	current_phase = GamePhase.REWARD
	title_container.visible = false
	scene_container.visible = true
	_clear_scene()

	var scene = reward_scene_packed.instantiate()
	scene_container.add_child(scene)
	active_scene = scene

	scene.setup(current_battle_type)
	scene.reward_completed.connect(_on_reward_completed)
	_update_top_bar("战斗胜利！")


func _on_reward_completed() -> void:
	_enter_map()


## === 商店场景 ===

func _enter_shop() -> void:
	current_phase = GamePhase.SHOP
	RunManager.saved_phase = GamePhase.SHOP
	AudioManager.ui("ui_click.wav")
	# 进入奇遇前捕获checkpoint
	SaveManager.capture_checkpoint()
	# FIX: [Bug 5] 确保phase与房间状态第一时间落地，防止Alt+F4跳过
	SaveManager.save_game()
	title_container.visible = false
	scene_container.visible = true
	_clear_scene()

	var scene = shop_scene_packed.instantiate()
	scene_container.add_child(scene)
	active_scene = scene

	scene.setup()
	scene.shop_completed.connect(_on_shop_completed)
	_update_top_bar("商店")


func _on_shop_completed() -> void:
	# 标记节点已访问
	if not RunManager.current_node_id in RunManager.visited_nodes:
		RunManager.visited_nodes.append(RunManager.current_node_id)
	RunManager.current_room_state = RunManager.RoomState.FINISHED
	# 清除商店库存和阶段标记（下次进入会重新生成）
	RunManager.shop_inventory.clear()
	RunManager.saved_phase = -1
	SaveManager.capture_checkpoint()
	SaveManager.save_game()
	_enter_map()


## === 休息场景 ===

func _enter_rest() -> void:
	current_phase = GamePhase.REST
	RunManager.saved_phase = GamePhase.REST
	# 进入奇遇前捕获checkpoint
	SaveManager.capture_checkpoint()
	# FIX: [Bug 5] 确保phase与房间状态第一时间落地，防止Alt+F4跳过
	SaveManager.save_game()
	title_container.visible = false
	scene_container.visible = true
	_clear_scene()

	var scene = rest_scene_packed.instantiate()
	scene_container.add_child(scene)
	active_scene = scene
	AudioManager.rest_jingle()

	scene.setup()
	scene.rest_completed.connect(_on_rest_completed)
	_update_top_bar("修炼驿站")


func _on_rest_completed() -> void:
	# 标记节点已访问
	if not RunManager.current_node_id in RunManager.visited_nodes:
		RunManager.visited_nodes.append(RunManager.current_node_id)
	RunManager.current_room_state = RunManager.RoomState.FINISHED
	RunManager.saved_phase = -1
	SaveManager.capture_checkpoint()
	SaveManager.save_game()
	_enter_map()


## === 宝箱场景 ===

func _enter_treasure_room() -> void:
	current_phase = GamePhase.TREASURE
	RunManager.saved_phase = GamePhase.TREASURE
	AudioManager.play_ambience("doll_room_amb.mp3")

	# 回退旧存档的 mid-room 状态（宝箱已开但未点"继续"）
	if RunManager.treasure_chest_opened:
		PlayerManager.gold = max(0, PlayerManager.gold - RunManager.pending_treasure_gold)
		for relic_id in RunManager.pending_treasure_relic_ids:
			if PlayerManager.has_relic(relic_id):
				PlayerManager.remove_relic(relic_id)
		RunManager.treasure_chest_opened = false

	SaveManager.capture_checkpoint()
	# FIX: [Bug 5] 确保phase与房间状态第一时间落地，防止Alt+F4跳过
	SaveManager.save_game()
	title_container.visible = false
	scene_container.visible = true
	_clear_scene()

	var scene = treasure_scene_packed.instantiate()
	scene_container.add_child(scene)
	active_scene = scene

	scene.setup()
	scene.treasure_completed.connect(_on_treasure_completed, CONNECT_ONE_SHOT)
	_update_top_bar("宝箱")


func _on_treasure_completed() -> void:
	AudioManager.stop_ambience(1.0)
	# 标记节点已访问
	if not RunManager.current_node_id in RunManager.visited_nodes:
		RunManager.visited_nodes.append(RunManager.current_node_id)
	RunManager.current_room_state = RunManager.RoomState.FINISHED
	# 清除宝箱缓存
	RunManager.pending_treasure_relic_ids.clear()
	RunManager.pending_treasure_gold = 0
	RunManager.treasure_chest_opened = false
	RunManager.saved_phase = -1
	SaveManager.capture_checkpoint()
	SaveManager.save_game()
	_enter_map()


## === 事件场景 ===

func _enter_event(event: EventModel) -> void:
	current_phase = GamePhase.EVENT
	RunManager.saved_phase = GamePhase.EVENT
	RunManager.saved_event_id = event.id
	_current_event = event
	# 进入奇遇前捕获checkpoint
	SaveManager.capture_checkpoint()
	title_container.visible = false
	scene_container.visible = true
	_clear_scene()

	var scene = event_scene_packed.instantiate()
	scene_container.add_child(scene)
	active_scene = scene

	scene.setup(event)
	scene.event_completed.connect(_on_event_completed)
	_update_top_bar("奇遇")


func _on_event_completed(needs_combat: bool, combat_id: String) -> void:
	# 无论是否触发战斗，都标记节点已访问
	if needs_combat and combat_id != "":
		# 事件触发战斗：保留saved_phase=EVENT，不标记visited（由_on_battle_ended标记）
		current_battle_type = RewardManager.BattleType.NORMAL
		var enemies: Array[Enemy] = _get_enemies_for_combat_id(combat_id)
		_enter_battle(enemies, true)
	else:
		# 事件完成（无战斗），仅标记FINISHED（visited由点击下一节点时标记）
		RunManager.current_room_state = RunManager.RoomState.FINISHED
		RunManager.saved_phase = -1
		RunManager.saved_event_id = -1
		SaveManager.capture_checkpoint()
		SaveManager.save_game()
		_enter_map()


## 根据事件战斗ID获取敌人
func _get_enemies_for_combat_id(combat_id: String) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	match combat_id:
		"nalan":
			enemies.append(EnemyDatabase.create_elite_nalan())
		"elite_nalan":
			enemies.append(EnemyDatabase.create_elite_nalan())
		"xiao_raider":
			enemies.append(EnemyDatabase.create_yunlan_inner())
			enemies.append(EnemyDatabase.create_yunlan_inner())
			enemies.append(EnemyDatabase.create_yunlan_disciple())
		"yunlan_disciple":
			enemies.append(EnemyDatabase.create_yunlan_disciple())
			enemies.append(EnemyDatabase.create_yunlan_disciple())
		"mountain_beast":
			enemies.append(EnemyDatabase.create_high_beast())
			enemies.append(EnemyDatabase.create_magic_wolf())
			enemies.append(EnemyDatabase.create_magic_wolf())
		"desert_bandit":
			enemies.append(EnemyDatabase.create_bandit())
			enemies.append(EnemyDatabase.create_bandit())
			enemies.append(EnemyDatabase.create_bandit())
			enemies.append(EnemyDatabase.create_bounty_hunter())
		"desert_bandit_hard":
			var b1 = EnemyDatabase.create_bandit(); b1.strength += 3; enemies.append(b1)
			var b2 = EnemyDatabase.create_bandit(); b2.strength += 3; enemies.append(b2)
			var b3 = EnemyDatabase.create_bandit(); b3.strength += 3; enemies.append(b3)
			var bh = EnemyDatabase.create_bounty_hunter(); bh.strength += 3; enemies.append(bh)
		"yunlan_ambush":
			enemies.append(EnemyDatabase.create_yunlan_inner())
			enemies.append(EnemyDatabase.create_yunlan_inner())
		"fire_snake":
			enemies.append(EnemyDatabase.create_fire_snake())
		# === 黑角域事件战斗 ===
		"auction_thieves":
			enemies.append(EnemyDatabase.create_assassin_member())
			enemies.append(EnemyDatabase.create_assassin_member())
			enemies.append(EnemyDatabase.create_bounty_hunter())
		"han_feng_weakened":
			var hf = EnemyDatabase.create_boss_han_feng()
			hf.hp -= 15
			enemies.append(hf)
		"arena_fight_1":
			enemies.append(EnemyDatabase.create_black_corner_mercenary())
			enemies.append(EnemyDatabase.create_black_corner_assassin())
		"assassin_ambush_normal":
			enemies.append(EnemyDatabase.create_assassin_member())
			enemies.append(EnemyDatabase.create_assassin_member())
		"assassin_ambush_hard":
			var a1 = EnemyDatabase.create_assassin_member(); a1.strength += 5; enemies.append(a1)
			var a2 = EnemyDatabase.create_assassin_member(); a2.strength += 5; enemies.append(a2)
		"blood_sect_guard":
			enemies.append(EnemyDatabase.create_blood_disciple())
			enemies.append(EnemyDatabase.create_heretical_alchemist())
		"serpent_ambush":
			enemies.append(EnemyDatabase.create_serpent_assassin())
			enemies.append(EnemyDatabase.create_serpent_assassin())
			enemies.append(EnemyDatabase.create_serpent_elite_assassin())
		# === 迦南学院事件战斗 ===
		"cultivation_deviation_fight":
			enemies.append(EnemyDatabase.create_cultivation_deviation())
		"han_yue_challenge":
			enemies.append(EnemyDatabase.create_elite_han_yue())
		"ziyan_challenge":
			enemies.append(EnemyDatabase.create_elite_ziyan())
		"resource_battle":
			enemies.append(EnemyDatabase.create_canaan_inner_disciple())
			enemies.append(EnemyDatabase.create_canaan_inner_disciple())
		"earth_devil_fight":
			enemies.append(EnemyDatabase.create_elite_earth_devil())
		"forbidden_guard_fight":
			enemies.append(EnemyDatabase.create_elite_forbidden_guard())
		"fallen_heart_flame":
			enemies.append(EnemyDatabase.create_boss_fallen_heart_flame())
		# === 中州事件战斗 ===
		"pill_tower_guard_fight":
			enemies.append(EnemyDatabase.create_pill_tower_guard())
		"soul_hall_ambush_fight":
			enemies.append(EnemyDatabase.create_elite_soul_hall_elder())
		"soul_elders_group_fight":
			enemies.append(EnemyDatabase.create_soul_elder_a())
			enemies.append(EnemyDatabase.create_soul_elder_b())
			enemies.append(EnemyDatabase.create_soul_elder_c())
			enemies.append(EnemyDatabase.create_soul_elder_d())
		"soul_hall_elder":
			enemies.append(EnemyDatabase.create_soul_hall_elder())
		"ancient_puppet_fight":
			enemies.append(EnemyDatabase.create_ancient_puppet())
		"ancient_clan_trial_fight":
			enemies.append(EnemyDatabase.create_ancient_clan_warrior())
			enemies.append(EnemyDatabase.create_ancient_clan_warrior())
		"soul_storm_fight":
			enemies.append(EnemyDatabase.create_soul_phantom())
			enemies.append(EnemyDatabase.create_soul_phantom())
			enemies.append(EnemyDatabase.create_soul_phantom())
		"ancient_emperor_soul":
			enemies.append(EnemyDatabase.create_boss_ancient_emperor_soul())
		_:
			var floor = _get_current_floor()
			enemies.append(EnemyDatabase.create_random_normal_enemy(floor))
	return enemies

## BOSS击败后后台播放专属BGM（淡入淡出，不阻塞流程）
func _play_boss_defeat_bgm_and_then(next_action: Callable) -> void:
	var track := "萧炎击败云山.mp3" if PlayerManager.character_id == "xiaoyan" else "其他角色击败云山.mp3"
	AudioManager.stop_bgm(0.5)
	AudioManager.play_bgm_once(track, -6.0, 1.5, 3.0)
	# 不等待BGM，立即执行下一步
	next_action.call()


func _show_victory() -> void:
	current_phase = GamePhase.VICTORY
	AudioManager.sfx("victory.mp3")
	# 安全关闭地图覆盖层
	if map_overlay_layer.visible:
		map_overlay_layer.visible = false
		get_tree().paused = false
	_clear_scene()
	title_container.visible = true
	scene_container.visible = false

	# 隐藏其他按钮，只保留退出
	for child in title_container.get_children():
		if child is Button and child.name != "BtnQuit":
			child.visible = false


## === 持久顶栏 ===

func _update_top_bar(title_text: String = "") -> void:
	if current_phase == GamePhase.TITLE or current_phase == GamePhase.VICTORY:
		top_bar.visible = false
		relic_bar_panel.visible = false
		return
	top_bar.visible = true
	relic_bar_panel.visible = true
	if title_text != "":
		top_title_label.text = title_text
	# 加载角色头像图标
	var char_dir_map = {"xiaoyan": "xiao-yan", "xuner": "xuner", "cailin": "cailin"}
	var char_dir = char_dir_map.get(PlayerManager.character_id, "xiao-yan")
	var icon_path = "res://assets/characters/%s/icon.png" % char_dir
	if ResourceLoader.exists(icon_path):
		name_icon.texture = load(icon_path)
	else:
		name_icon.texture = null
	hp_label.text = "%d/%d" % [PlayerManager.hp, PlayerManager.max_hp]
	gold_label.text = "%d" % PlayerManager.gold
	deck_label.text = ""
	if _deck_badge:
		_deck_badge.text = str(PlayerManager.deck.size())
	map_button.visible = current_phase not in [GamePhase.TITLE, GamePhase.VICTORY]
	_update_relic_bar()
	_update_potion_bar()


func _update_relic_bar() -> void:
	var battle_player: Player = null
	if current_phase == GamePhase.COMBAT and active_scene != null and active_scene.has_method("get") and "player" in active_scene:
		battle_player = active_scene.player
	relic_bar.update_display(PlayerManager.relics, battle_player)


func _update_potion_bar() -> void:
	potion_bar.update_display(PlayerManager.potions, PlayerManager.max_potion_slots)
	# 非战斗状态：药水 used 信号连 main
	if current_phase != GamePhase.COMBAT:
		_connect_potion_to_main()


## 顶栏：暗色琉璃玉石背景shader
func _apply_top_bar_shader() -> void:
	var shader = load("res://shaders/jade_bar.gdshader")
	if shader:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		top_bar.material = mat


## 遗物栏：暗青铜纹理shader
func _apply_relic_bar_shader() -> void:
	var shader = load("res://shaders/relic_bar.gdshader")
	if shader:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		relic_bar_panel.material = mat


## PlayerManager属性变化时自动刷新顶栏
func _on_stats_changed() -> void:
	if current_phase != GamePhase.COMBAT:
		_update_top_bar()
	else:
		# 战斗中只刷新药水栏（HP由player_hp_changed信号单独更新）
		_update_potion_bar()


## 非战斗状态：使用药水
func _on_potion_used(potion_index: int) -> void:
	if current_phase == GamePhase.COMBAT:
		return
	if potion_index < 0 or potion_index >= PlayerManager.potions.size():
		return
	var potion = PlayerManager.potions[potion_index]
	# 非战斗状态不允许使用丹药（不消耗）
	print("[药水] %s 只能在战斗中使用" % potion.potion_name)


## 丢弃药水（非战斗状态；战斗中由 combat_scene._on_potion_discarded 处理）
func _on_potion_discarded(potion_index: int) -> void:
	if current_phase == GamePhase.COMBAT:
		return
	if potion_index < 0 or potion_index >= PlayerManager.potions.size():
		return
	var potion = PlayerManager.potions[potion_index]
	print("[药水] 丢弃了 %s" % potion.potion_name)
	PlayerManager.potions.remove_at(potion_index)
	PlayerManager.stats_changed.emit()


## 战斗中玩家HP变化时实时刷新顶栏HP
func _on_combat_hp_changed(hp_val: int, max_hp_val: int) -> void:
	hp_label.text = "%d/%d" % [hp_val, max_hp_val]


func _on_deck_count_changed(count: int) -> void:
	if _deck_badge:
		_deck_badge.text = str(count)


func _on_relic_bar_clicked() -> void:
	if relic_overlay_instance != null:
		return
	if PlayerManager.relics.is_empty():
		return
	relic_overlay_instance = relic_overlay_scene.instantiate()
	relic_overlay_instance.z_index = 100
	add_child(relic_overlay_instance)
	relic_overlay_instance.overlay_closed.connect(_on_relic_overlay_closed)
	relic_overlay_instance.show_overlay(PlayerManager.relics)


func _on_relic_overlay_closed() -> void:
	if relic_overlay_instance != null:
		relic_overlay_instance.queue_free()
		relic_overlay_instance = null


func _on_deck_label_pressed() -> void:
	AudioManager.ui("ui_click.wav")
	if deck_overlay_instance != null:
		return
	if PlayerManager.deck.is_empty():
		return
	# 打开卡组时隐藏地图覆盖层（防止画笔图层和滚动穿透）
	_map_was_open_before_deck = map_overlay_layer.visible
	if _map_was_open_before_deck:
		map_overlay_layer.visible = false
		get_tree().paused = false
	# 隐藏地图主场景中的画笔层和工具栏
	_set_map_drawing_visible(false)
	# 禁用地图输入（防止滚轮和拖拽穿透）
	_set_map_input_enabled(false)
	deck_overlay_instance = deck_overlay_scene.instantiate()
	deck_overlay_instance.z_index = 100
	add_child(deck_overlay_instance)
	deck_overlay_instance.overlay_closed.connect(_on_deck_overlay_closed)
	deck_overlay_instance.card_selected.connect(_on_deck_overlay_card_selected)
	deck_overlay_instance.show_overlay("卡组", "当前卡组中的所有卡牌（%d张）" % PlayerManager.deck.size(), PlayerManager.deck)


func _on_deck_overlay_closed() -> void:
	if deck_overlay_instance != null:
		deck_overlay_instance.queue_free()
		deck_overlay_instance = null
	# 关闭卡组后恢复地图覆盖层（如果之前是打开的）
	if _map_was_open_before_deck and map_overlay_scene != null:
		map_overlay_layer.visible = true
		map_overlay_scene.setup(true)
		get_tree().paused = true
	_map_was_open_before_deck = false
	# 恢复地图画笔层
	_set_map_drawing_visible(true)
	# 恢复地图输入
	_set_map_input_enabled(true)


func _on_deck_overlay_card_selected(_card_data) -> void:
	_on_deck_overlay_closed()


## === 设置菜单 ===

func _on_settings_pressed() -> void:
	AudioManager.ui("ui_click.wav")
	settings_popup.popup_centered(Vector2(300, 250))


func _on_settings_continue_pressed() -> void:
	AudioManager.ui("ui_click.wav")
	settings_popup.hide()


func _on_settings_restart_pressed() -> void:
	AudioManager.ui("ui_click.wav")
	settings_popup.hide()
	# 重新开始 = 恢复checkpoint + 继续冒险（参考StS2：恢复检查点后重新加载）
	SaveManager.restore_checkpoint()
	SaveManager.save_game()
	# 使用与继续冒险相同的逻辑进入正确场景
	_continue_from_save()


func _on_settings_abandon_pressed() -> void:
	AudioManager.ui("ui_click.wav")
	settings_popup.hide()
	# 确认弹窗，防止误点清除存档
	var dialog = ConfirmationDialog.new()
	dialog.title = "确认放弃"
	dialog.dialog_text = "确定要放弃本次冒险吗？\n当前存档将被清除，无法恢复。"
	dialog.ok_button_text = "确认放弃"
	dialog.cancel_button_text = "取消"
	dialog.exclusive = true
	dialog.confirmed.connect(func():
		dialog.queue_free()
		SaveManager.delete_run_save()
		_show_title_screen()
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
		settings_popup.show()
	)
	add_child(dialog)
	dialog.popup_centered(Vector2(350, 150))


func _on_settings_save_quit_pressed() -> void:
	AudioManager.ui("ui_click.wav")
	settings_popup.hide()
	# 参考StS2：存档只保存奇遇前检查点，不保存奇遇中间状态
	# checkpoint已在进入奇遇时捕获，直接保存
	SaveManager.save_game()
	_show_title_screen()


## === 按钮回调 ===

func _on_btn_continue_pressed() -> void:
	AudioManager.ui("ui_click.wav")
	AudioManager.stop_bgm(1.5)
	_continue_adventure()


func _on_btn_adventure_pressed() -> void:
	AudioManager.ui("ui_click.wav")
	_show_character_select()


## 层数选择：循环切换 1/2/3/4 层
func _on_btn_layer_select_pressed() -> void:
	AudioManager.ui("ui_click.wav")
	_selected_start_scene = _selected_start_scene + 1
	if _selected_start_scene > 4:
		_selected_start_scene = 1
	var btn = title_container.get_node_or_null("BtnLayerSelect")
	if btn != null:
		btn.text = "起始场景：第%d层" % _selected_start_scene


func _on_btn_quit_pressed() -> void:
	AudioManager.ui("ui_click.wav")
	get_tree().quit()


## [FIX: Bug 6] 显示特殊奖励弹窗
func _show_special_reward_dialog(msg: String, next_action: Callable) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "特殊机缘"

	# 原生 AcceptDialog 的 dialog_text 不支持富文本，简单过滤掉颜色标签
	var clean_msg = msg.replace("[color=cyan]", "").replace("[/color]", "")\
		.replace("[color=yellow]", "").replace("[color=red]", "")\
		.replace("[color=gray]", "").replace("[color=green]", "")\
		.replace("[color=purple]", "").replace("[color=orange]", "")
	dialog.dialog_text = clean_msg

	# 设置为独占模式并添加
	dialog.exclusive = true
	add_child(dialog)

	# 确保无论玩家是点确定还是按 ESC 关掉，都能正常执行回调，防止卡死
	var is_closed = [false]
	var close_func = func():
		if not is_closed[0]:
			is_closed[0] = true
			dialog.queue_free()
			next_action.call()

	dialog.confirmed.connect(close_func)
	dialog.canceled.connect(close_func)

	dialog.popup_centered()
