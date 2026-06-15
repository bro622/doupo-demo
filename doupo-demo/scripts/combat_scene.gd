## 战斗场景控制器
## 管理图形化战斗界面、卡牌拖拽出牌、目标选择
extends Control

## 战斗结束信号
signal battle_ended(victory: bool)
## 玩家HP变化信号（顶栏实时同步用）
signal player_hp_changed(hp: int, max_hp: int)
## 牌堆数量变化信号（顶栏牌组计数同步用）
signal deck_count_changed(count: int)

## 战斗管理器
var battle_manager: BattleManager

## 当前玩家
var player: Player

## 当前敌人节点列表
var enemy_nodes: Array[EnemyNode] = []

## 当前手牌节点列表
var card_nodes: Array[CardNode] = []

## 目标选择状态
enum TargetingState { NONE, DRAGGING_CARD, SELECTING_POTION_TARGET }
var targeting_state: TargetingState = TargetingState.NONE

## 当前拖拽的卡牌
var dragged_card: CardNode = null
## 等待选择目标的药水索引
var _pending_potion_index: int = -1
## 当前播放动画的卡牌节点（避免_update_hand_display重复释放）
var _animating_card_node: CardNode = null
## 当前拖拽是否为自目标牌（技能/能力）
var _drag_is_self_target: bool = false

## 当前悬停的敌人
var hovered_enemy: EnemyNode = null

## 上次手牌数量（用于检测抽牌时机，触发动画）
var _prev_hand_count: int = 0


## UI节点引用 — BattleZone
@onready var battle_zone: Control = $BattleVBox/BattleZone
@onready var enemy_area: HBoxContainer = $BattleVBox/BattleZone/EnemyArea
@onready var player_area: Control = $BattleVBox/BattleZone/PlayerArea
@onready var battle_log: RichTextLabel = $BattleVBox/BattleZone/BattleLog
@onready var player_hp_text: Label = $BattleVBox/BattleZone/PlayerArea/PlayerHPBar/HPText
@onready var player_hp_bar: ProgressBar = $BattleVBox/BattleZone/PlayerArea/PlayerHPBar/HPBar
@onready var player_block: Panel = $BattleVBox/BattleZone/PlayerArea/PlayerBlock
@onready var player_block_label: Label = $BattleVBox/BattleZone/PlayerArea/PlayerBlock/BlockLabel
@onready var player_status_bar: StatusBar = $BattleVBox/BattleZone/PlayerArea/PlayerStatusBar
@onready var heavenly_flame_bar: HeavenlyFlameBar = $BattleVBox/BattleZone/PlayerArea/HeavenlyFlameBar
@onready var player_sprite: PlayerSprite = $BattleVBox/BattleZone/PlayerArea/PlayerSprite
@onready var skill_effect_area: TextureRect = $BattleVBox/BattleZone/PlayerArea/SkillEffectArea

## UI节点引用 — BottomZone
@onready var hand_container: Control = $BattleVBox/BottomZone/Margin/Content/HandContainer
@onready var energy_label: Label = $BattleVBox/BottomZone/Margin/Content/LeftPanel/EnergyContainer/EnergyLabel
@onready var end_turn_button: Button = $BattleVBox/BottomZone/Margin/Content/RightPanel/EndTurnButton
@onready var draw_pile_button: Button = $BattleVBox/BottomZone/Margin/Content/LeftPanel/DrawPileButton
@onready var discard_pile_button: Button = $BattleVBox/BottomZone/Margin/Content/RightPanel/DiscardPileButton
@onready var exhaust_pile_button: Button = $BattleVBox/BottomZone/Margin/Content/RightPanel/ExhaustPileButton
@onready var ability_pile_button: Button = $BattleVBox/BottomZone/Margin/Content/RightPanel/AbilityPileButton
@onready var bottom_bg: ColorRect = $BattleVBox/BottomZone/BgColor

## 瞄准箭头
var targeting_arrow: TargetingArrow

## 上一帧玩家HP（用于检测受伤）
var _last_player_hp: int = -1

## 悬停卡牌索引（用于手牌扩散效果）
var _hovered_card_index: int = -1

## 卡牌详情面板
var _detail_panel: CardDetailPanel = null

## 场景预加载
var card_scene = preload("res://scenes/card.tscn")
var enemy_scene = preload("res://scenes/enemy.tscn")
var overlay_scene = preload("res://scenes/card_select_overlay.tscn")

## 牌堆查看覆盖层
var overlay_instance: Control = null

## 拖拽阈值(向上拖拽多少像素进入出牌区域)
const PLAY_ZONE_OFFSET: float = -200.0


func _ready() -> void:
	# 创建瞄准箭头
	targeting_arrow = TargetingArrow.new()
	$TargetingArrow.add_child(targeting_arrow)

	# 连接按钮
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	draw_pile_button.pressed.connect(_on_draw_pile_pressed)
	discard_pile_button.pressed.connect(_on_discard_pile_pressed)
	exhaust_pile_button.pressed.connect(_on_exhaust_pile_pressed)
	ability_pile_button.pressed.connect(_on_ability_pile_pressed)

	# 牌堆按钮样式：深色半透背景 + 边框，文本始终可见
	_style_pile_button(draw_pile_button)
	_style_pile_button(discard_pile_button)
	_style_pile_button(exhaust_pile_button)
	_style_pile_button(ability_pile_button)

	# 检测鼠标释放(全局)
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if targeting_state == TargetingState.DRAGGING_CARD:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				_on_card_drag_released()
			elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				_cancel_card_drag()

		if event is InputEventMouseMotion:
			_update_drag_visuals()
	elif targeting_state == TargetingState.SELECTING_POTION_TARGET:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				_on_potion_target_released()
			elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				_cancel_potion_targeting()

		if event is InputEventMouseMotion:
			_update_potion_targeting_visuals()


## 初始化战斗
func start_battle(p_player: Player, enemies: Array[Enemy], p_battle_type: int = 0) -> void:
	player = p_player

	# 加载战斗背景
	_load_battle_background(enemies)
	# 出牌区域石板纹理
	_apply_stone_plate()

	# 创建战斗管理器
	battle_manager = BattleManager.new()
	battle_manager.setup_battle(player, enemies, p_battle_type)
	battle_manager.fire_type_requested.connect(_on_fire_type_requested)
	battle_manager.choose_discard_requested.connect(_on_choose_discard_requested)
	battle_manager.choose_exhaust_requested.connect(_on_choose_exhaust_requested)
	battle_manager.relic_choice_requested.connect(_on_relic_choice_requested)

	# 洗牌动画信号
	player.deck_shuffled.connect(_on_deck_shuffled)

	# 美杜莎：连接姿态切换信号到player_sprite
	if PlayerManager.character_id == "cailin" and player.has_signal("stance_changed"):
		player.stance_changed.connect(player_sprite._on_stance_changed)
		# 初始化姿态图标（无姿态）
		player_sprite._create_stance_icon()
		player_sprite._update_stance_icon(0)

	# 创建敌人节点
	_create_enemy_nodes(enemies)

	# 设置玩家名字
	var player_name_label = $BattleVBox/BattleZone/PlayerArea/PlayerName as Label
	player_name_label.text = PlayerManager.player_name

	# 异火槽仅萧炎显示
	heavenly_flame_bar.visible = (PlayerManager.character_id == "xiaoyan")

	# 开始战斗
	var msg = battle_manager.start_battle()
	_log_text(msg)
	AudioManager.sfx("player_turn.mp3")

	# 更新UI
	_update_all_displays()


## 根据敌人加载战斗背景
func _load_battle_background(enemies: Array[Enemy]) -> void:
	# 移除旧背景图和雾气层（保留原始 Background ColorRect）
	for child in battle_zone.get_children():
		if child.name == "BackgroundImage" or child.name == "FogLayer":
			child.queue_free()

	var bg_path = EnemyDatabase.get_background_path(enemies)
	if bg_path != "":
		# 尝试加载背景纹理（优先用 load，失败则用 Image 直接读取）
		var texture: Texture2D = null
		if ResourceLoader.exists(bg_path):
			texture = load(bg_path)
		if texture == null:
			# fallback: 用 Image 直接从文件系统加载
			var abs_path = ProjectSettings.globalize_path(bg_path)
			var img = Image.new()
			if img.load(abs_path) == OK:
				texture = ImageTexture.create_from_image(img)
		if texture != null:
			# 背景图：降低饱和度和亮度，使其"后退"
			var bg_tex = TextureRect.new()
			bg_tex.name = "BackgroundImage"
			bg_tex.texture = texture
			bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
			bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bg_tex.modulate = Color(0.6, 0.6, 0.6, 1.0)  # 暗化+去饱和
			battle_zone.add_child(bg_tex)
			battle_zone.move_child(bg_tex, 0)

		# 雾气层：背景与角色之间的半透明渐变
		var fog = ColorRect.new()
		fog.name = "FogLayer"
		fog.set_anchors_preset(Control.PRESET_FULL_RECT)
		fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# 上方浓雾、下方淡雾，营造纵深感
		var fog_mat = ShaderMaterial.new()
		fog_mat.shader = _create_fog_shader()
		fog.material = fog_mat
		battle_zone.add_child(fog)
		battle_zone.move_child(fog, 1)


## 创建雾气渐变 shader
func _create_fog_shader() -> Shader:
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

void fragment() {
	// 从上到下的渐变雾气：顶部浓，底部淡
	float gradient = 1.0 - UV.y;
	float alpha = mix(0.0, 0.25, gradient);
	// 暖灰色雾气
	COLOR = vec4(0.15, 0.14, 0.13, alpha);
}
"""
	return shader


## 出牌区域石板纹理
func _apply_stone_plate() -> void:
	var shader = load("res://shaders/stone_plate.gdshader")
	if shader and bottom_bg:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		bottom_bg.material = mat


## 创建敌人节点
func _create_enemy_nodes(enemies: Array[Enemy]) -> void:
	# 清除旧节点
	for node in enemy_nodes:
		node.queue_free()
	enemy_nodes.clear()

	for enemy in enemies:
		var node = enemy_scene.instantiate() as EnemyNode
		node.enemy_hovered.connect(_on_enemy_hovered)
		node.enemy_unhovered.connect(_on_enemy_unhovered)
		enemy_area.add_child(node)
		node.setup(enemy)
		enemy_nodes.append(node)


## 更新手牌显示（无 await，避免并发竞争）
func _update_hand_display() -> void:
	var was_empty = card_nodes.is_empty()

	# 清除旧手牌节点（跳过正在播放动画的节点，由tween回调负责释放）
	for node in card_nodes:
		if node != _animating_card_node:
			node.queue_free()
	card_nodes.clear()

	# 创建新手牌节点
	for i in range(player.hand.size()):
		var card = player.hand[i]
		var node = card_scene.instantiate() as CardNode
		node.setup(card)
		# 构建预览上下文（卡牌特殊联动需要）
		# 获取当前目标的蛇毒层数（用于蛇毒加成预览）
		var target_venom = 0
		var target_gold_seal = 0
		if hovered_enemy != null and is_instance_valid(hovered_enemy) and hovered_enemy.enemy_data.is_alive():
			target_venom = hovered_enemy.enemy_data.venom
			target_gold_seal = hovered_enemy.enemy_data.gold_seal
		elif enemy_nodes.size() > 0:
			for en in enemy_nodes:
				if is_instance_valid(en) and en.enemy_data.is_alive():
					target_venom = en.enemy_data.venom
					target_gold_seal = en.enemy_data.gold_seal
					break
		var ctx = {
			"cards_played_this_turn": battle_manager.cards_played_this_turn if battle_manager else 0,
			"fire_slot_count": player.fire_slots.size(),
			"target_venom": target_venom,
			"attack_cards_played": battle_manager.attack_cards_played_this_turn if battle_manager else 0,
			"target_gold_seal": target_gold_seal,
		}
		node.update_preview(player, ctx)
		node.card_clicked.connect(_on_card_clicked)
		node.detail_requested.connect(_on_card_detail_requested)
		node.detail_hidden.connect(_on_card_detail_hidden)
		node.mouse_entered.connect(_on_card_hovered.bind(i))
		node.mouse_exited.connect(_on_card_unhovered.bind(i))

		# 设置可打出状态（对齐 battle_manager.gd 费用计算）
		var effective_cost = max(0, card.cost + player.next_card_cost_modifier - player.hand_cost_reduction)
		if player.first_card_free_this_turn:
			effective_cost = 0
		if card.cost_reduction_per_detonate > 0:
			effective_cost = max(0, effective_cost - player.detonation_count_total * card.cost_reduction_per_detonate)
		if card.python_cost_reduction > 0 and player.current_stance == 2:
			effective_cost = max(0, effective_cost - card.python_cost_reduction)
		if card.card_type == CardData.CardType.ABILITY:
			effective_cost = max(0, effective_cost - RelicManager.get_ability_cost_reduction(PlayerManager.relics))
		var playable = effective_cost <= player.energy and card.card_type != CardData.CardType.CURSE and card.card_type != CardData.CardType.STATUS
		# 条件牌：异火连击需要本回合激发过异火
		if playable and card.id == "fire_combo" and not player.evoked_this_turn:
			playable = false
		node.set_playable(playable)

		hand_container.add_child(node)
		card_nodes.append(node)

	# 布局（同步执行，无 await）
	if was_empty and not card_nodes.is_empty():
		# 手牌从空变为有 → 延迟一帧后播放抽牌动画（需要容器尺寸生效）
		call_deferred("_animate_draw_cards")
	else:
		_layout_hand()


## 布局手牌(类似杀戮尖塔的扇形排列)
func _layout_hand() -> void:
	var count = card_nodes.size()
	if count == 0:
		return

	var container_width = hand_container.size.x
	var card_width = 140.0
	var spacing = min(150.0, (container_width - card_width) / max(1, count - 1))
	var start_x = (container_width - spacing * (count - 1) - card_width) / 2.0

	for i in range(count):
		var node = card_nodes[i]
		var x = start_x + spacing * i
		var y_offset = 0.0

		# 扇形曲线
		var normalized_pos = 0.0
		if count > 1:
			normalized_pos = float(i) / (count - 1) * 2.0 - 1.0  # -1 to 1
		y_offset = normalized_pos * normalized_pos * 20.0  # 抛物线弧度

		node.position = Vector2(x, y_offset)
		node.rotation_degrees = normalized_pos * 3.0  # 轻微旋转


## 悬停卡牌 → 重新布局
func _on_card_hovered(_index: int) -> void:
	_hovered_card_index = _index

## 离开卡牌 → 恢复布局
func _on_card_unhovered(_index: int) -> void:
	_hovered_card_index = -1


## === 抽牌动画 ===
## 卡牌从抽牌堆位置逐张飞到手牌扇形位置
func _animate_draw_cards() -> void:
	# 先算出每张牌的目标位置
	var count = card_nodes.size()
	if count == 0:
		return

	var container_width = hand_container.size.x
	var card_width = 140.0
	var spacing = min(150.0, (container_width - card_width) / max(1, count - 1))
	var start_x = (container_width - spacing * (count - 1) - card_width) / 2.0

	var target_positions: Array[Vector2] = []
	var target_rotations: Array[float] = []
	for i in range(count):
		var x = start_x + spacing * i
		var normalized_pos = 0.0
		if count > 1:
			normalized_pos = float(i) / (count - 1) * 2.0 - 1.0
		var y_offset = normalized_pos * normalized_pos * 20.0
		target_positions.append(Vector2(x, y_offset))
		target_rotations.append(normalized_pos * 3.0)

	# 抽牌堆按钮在 HandContainer 坐标系中的位置
	var draw_pile_global = draw_pile_button.global_position + draw_pile_button.size / 2.0
	var draw_pile_local = draw_pile_global - hand_container.global_position

	# 逐张飞出
	for i in range(count):
		var node = card_nodes[i]
		# 起始状态：在抽牌堆位置，缩放为0，发光
		node.position = draw_pile_local
		node.scale = Vector2(0.3, 0.3)
		node.modulate = Color(1.5, 1.5, 1.2, 0.0)  # 亮白偏暖，带透明
		node.rotation_degrees = 0.0
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 动画中禁止交互
		AudioManager.sfx("card_deal.mp3", -6.0)

		# 延迟后开始飞行动画
		var delay = i * 0.12
		var tween = create_tween().set_parallel(true)
		tween.tween_property(node, "position", target_positions[i], 0.35).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(node, "scale", Vector2.ONE, 0.3).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(node, "modulate", Color.WHITE, 0.25).set_delay(delay).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "rotation_degrees", target_rotations[i], 0.35).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

		# 动画结束后恢复交互 + 诅咒牌/状态牌重新变暗
		tween.chain().tween_callback(func():
			if is_instance_valid(node):
				node.mouse_filter = Control.MOUSE_FILTER_STOP
				if not node.can_play:
					node.modulate = Color(0.5, 0.5, 0.5, 0.8)
		).set_delay(0.0)

	_prev_hand_count = count


## === 弃牌动画 ===
## 手牌化成光飞到弃牌堆位置
func _animate_discard_remaining() -> void:
	if card_nodes.is_empty():
		return

	var discard_global = discard_pile_button.global_position + discard_pile_button.size / 2.0
	var discard_local = discard_global - hand_container.global_position

	for i in range(card_nodes.size()):
		var node = card_nodes[i]
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var delay = i * 0.06
		var tween = create_tween().set_parallel(true)
		tween.tween_property(node, "position", discard_local, 0.3).set_delay(delay).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(node, "scale", Vector2(0.2, 0.2), 0.3).set_delay(delay).set_ease(Tween.EASE_IN)
		tween.tween_property(node, "modulate", Color(1.5, 1.5, 1.2, 0.0), 0.3).set_delay(delay).set_ease(Tween.EASE_IN)
		tween.tween_property(node, "rotation_degrees", 0.0, 0.2).set_delay(delay)

	# 等所有动画完成
	await get_tree().create_timer(0.06 * card_nodes.size() + 0.35).timeout

	# 清理节点（await 后检查场景有效性）
	if not is_instance_valid(self):
		return
	for node in card_nodes:
		if is_instance_valid(node):
			node.queue_free()
	card_nodes.clear()


## === 洗牌动画 ===
## 弃牌堆的牌化成光粒子飞回抽牌堆
func _on_deck_shuffled() -> void:
	var draw_pile_global = draw_pile_button.global_position + draw_pile_button.size / 2.0
	var discard_global = discard_pile_button.global_position + discard_pile_button.size / 2.0

	# STS2 风格洗牌粒子：从弃牌堆飞向抽牌堆
	var particle_texture = load("res://assets/effects/shuffle/tiny_glow_dot.png") as Texture2D

	# 主粒子流（光点拖尾）
	var particles = GPUParticles2D.new()
	particles.texture = particle_texture
	particles.amount = 20
	particles.lifetime = 0.8
	particles.emitting = false  # 手动控制 burst
	particles.global_position = discard_global
	add_child(particles)

	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3((draw_pile_global.x - discard_global.x), (draw_pile_global.y - discard_global.y), 0).normalized()
	mat.spread = 25.0
	mat.initial_velocity_min = 200.0
	mat.initial_velocity_max = 350.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.3
	mat.scale_max = 0.8
	mat.color = Color(1.0, 0.85, 0.4, 1.0)
	# 颜色随生命衰减
	mat.color_ramp = _create_fade_ramp(Color(1.0, 0.9, 0.5, 1.0), Color(1.0, 0.6, 0.2, 0.0))
	particles.process_material = mat
	particles.emitting = true

	# 星形点缀粒子（洗牌闪光）
	var star_particles = GPUParticles2D.new()
	star_particles.texture = load("res://assets/effects/shuffle/star1.png") as Texture2D
	star_particles.amount = 6
	star_particles.lifetime = 0.6
	star_particles.emitting = false
	# 居中于弃牌堆和抽牌堆之间
	star_particles.global_position = (discard_global + draw_pile_global) / 2.0
	add_child(star_particles)

	var star_mat = ParticleProcessMaterial.new()
	star_mat.direction = Vector3(0, -1, 0)
	star_mat.spread = 180.0
	star_mat.initial_velocity_min = 50.0
	star_mat.initial_velocity_max = 120.0
	star_mat.gravity = Vector3(0, 80, 0)
	star_mat.scale_min = 0.2
	star_mat.scale_max = 0.5
	star_mat.color_ramp = _create_fade_ramp(Color(1.0, 1.0, 0.8, 1.0), Color(1.0, 0.8, 0.3, 0.0))
	star_particles.process_material = star_mat
	star_particles.emitting = true

	# 自动清理
	var cleanup_tween = create_tween()
	cleanup_tween.tween_interval(1.2)
	cleanup_tween.tween_callback(particles.queue_free)
	cleanup_tween.tween_callback(star_particles.queue_free)


## 创建颜色渐变（从亮到透明）
func _create_fade_ramp(from_color: Color, to_color: Color) -> GradientTexture1D:
	var gradient = Gradient.new()
	gradient.set_color(0, from_color)
	gradient.set_color(1, to_color)
	var tex = GradientTexture1D.new()
	tex.width = 64
	tex.gradient = gradient
	return tex


## 更新所有显示
func _update_all_displays() -> void:
	_update_hand_display()
	_update_enemy_displays()
	_update_player_display()
	_update_energy_display()
	_update_pile_display()


## 更新敌人显示
func _update_enemy_displays() -> void:
	for i in range(enemy_nodes.size()):
		var node = enemy_nodes[i]
		if is_instance_valid(node):
			node._update_hp_display()
			node.update_intent_display()


## 更新玩家显示
func _update_player_display() -> void:
	# 检测受伤抖动
	if _last_player_hp >= 0 and player.hp < _last_player_hp:
		player_sprite.show_damage_shake()
	_last_player_hp = player.hp

	player_hp_text.text = "%d / %d" % [player.hp, player.max_hp]
	player_hp_bar.max_value = player.max_hp
	player_hp_bar.value = player.hp
	player_hp_changed.emit(player.hp, player.max_hp)

	if player.block > 0:
		player_block.visible = true
		player_block_label.text = str(player.block)
	else:
		player_block.visible = false

	# 更新状态效果图标栏
	player_status_bar.update_display(player)

	# 更新异火槽显示（仅萧炎）
	if PlayerManager.character_id == "xiaoyan":
		heavenly_flame_bar.update_display(player.fire_slots, player.max_fire_slots)
		player_sprite.set_permanent_green_fire(player.permanent_green_fire_count > 0)


## 更新斗气显示
func _update_energy_display() -> void:
	energy_label.text = "%d/%d" % [player.energy, player.max_energy]


## 牌堆按钮统一样式
func _style_pile_button(btn: Button) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.6)
	style.border_color = Color(0.5, 0.5, 0.5, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 0.8))


## 更新牌堆显示
func _update_pile_display() -> void:
	draw_pile_button.text = "抽牌堆:%d" % player.draw_pile.size()
	discard_pile_button.text = "弃牌:%d" % player.discard_pile.size()
	exhaust_pile_button.text = "消耗:%d" % player.exhaust_pile.size()
	ability_pile_button.text = "能力:%d" % player.in_play.size()
	deck_count_changed.emit(PlayerManager.deck.size())


## === 牌堆查看器(参考StS2牌堆点击查看) ===

func _on_draw_pile_pressed() -> void:
	if overlay_instance != null:
		return
	if player.draw_pile.is_empty():
		_log_text("[color=gray]抽牌堆为空[/color]\n")
		return
	AudioManager.ui("map_open.mp3")
	_show_pile_overlay("抽牌堆", "当前抽牌堆中的卡牌", player.draw_pile)


func _on_discard_pile_pressed() -> void:
	if overlay_instance != null:
		return
	if player.discard_pile.is_empty():
		_log_text("[color=gray]弃牌堆为空[/color]\n")
		return
	AudioManager.ui("map_open.mp3")
	_show_pile_overlay("弃牌堆", "弃牌堆中的卡牌", player.discard_pile)


func _on_exhaust_pile_pressed() -> void:
	if overlay_instance != null:
		return
	if player.exhaust_pile.is_empty():
		_log_text("[color=gray]消耗堆为空[/color]\n")
		return
	AudioManager.ui("map_open.mp3")
	_show_pile_overlay("消耗堆", "消耗堆中的卡牌（战斗结束后回到卡组）", player.exhaust_pile)


func _on_ability_pile_pressed() -> void:
	if overlay_instance != null:
		return
	if player.in_play.is_empty():
		_log_text("[color=gray]能力牌堆为空[/color]\n")
		return
	AudioManager.ui("map_open.mp3")
	_show_pile_overlay("能力牌堆", "已打出的能力牌（战斗中持续生效）", player.in_play)


func _show_pile_overlay(title: String, hint: String, pile: Array) -> void:
	overlay_instance = overlay_scene.instantiate()
	overlay_instance.z_index = 100
	add_child(overlay_instance)

	var overlay = overlay_instance
	overlay.overlay_closed.connect(_on_pile_overlay_closed)
	overlay.show_overlay(title, hint, pile)


func _on_pile_overlay_closed() -> void:
	if overlay_instance != null:
		overlay_instance.queue_free()
		overlay_instance = null


## === 卡牌拖拽系统 ===

## 卡牌被点击 - 开始拖拽
func _on_card_clicked(card_node) -> void:
	if targeting_state != TargetingState.NONE:
		return

	var card_index = card_nodes.find(card_node)
	if card_index < 0:
		return

	var card = player.hand[card_index]

	# 检查是否可打出（对齐 battle_manager.gd 费用计算）
	var effective_cost = max(0, card.cost + player.next_card_cost_modifier - player.hand_cost_reduction)
	if player.first_card_free_this_turn:
		effective_cost = 0
	if card.cost_reduction_per_detonate > 0:
		effective_cost = max(0, effective_cost - player.detonation_count_total * card.cost_reduction_per_detonate)
	if card.python_cost_reduction > 0 and player.current_stance == 2:
		effective_cost = max(0, effective_cost - card.python_cost_reduction)
	if card.card_type == CardData.CardType.ABILITY:
		effective_cost = max(0, effective_cost - RelicManager.get_ability_cost_reduction(PlayerManager.relics))
	if effective_cost > player.energy:
		_log_text("[color=red]斗气不足！[/color]\n")
		AudioManager.ui("deny.mp3")
		return

	if card.card_type == CardData.CardType.CURSE or card.card_type == CardData.CardType.STATUS:
		_log_text("[color=red]此牌无法使用！[/color]\n")
		AudioManager.ui("deny.mp3")
		return

	# 条件牌检查
	if card.id == "fire_combo" and not player.evoked_this_turn:
		_log_text("[color=red]本回合未激发异火，无法使用！[/color]\n")
		AudioManager.ui("deny.mp3")
		return

	AudioManager.ui("card_select.mp3")

	# 先取消悬停效果，还原到布局位置后再保存原始位置
	card_node.unhighlight()

	# 记录拖拽状态
	dragged_card = card_node
	targeting_state = TargetingState.DRAGGING_CARD
	_drag_is_self_target = (card.card_type != CardData.CardType.ATTACK)

	# 记录原始位置
	card_node.original_position = card_node.position
	card_node.original_parent = card_node.get_parent()
	card_node.original_index = card_node.get_index()

	# 开始拖拽视觉效果
	card_node.start_drag()
	card_node.z_index = 100

	if _drag_is_self_target:
		# 自目标牌（技能/能力）：高亮玩家区域，不显示瞄准箭头
		player_area.modulate = Color(0.5, 1.0, 0.5, 1.0)
	else:
		# 攻击牌：开始绘制瞄准箭头
		var arrow_start = card_node.global_position + card_node.size / 2
		targeting_arrow.start_drawing(arrow_start)


## 更新拖拽视觉
func _update_drag_visuals() -> void:
	if dragged_card == null:
		return

	var mouse_pos = get_global_mouse_position()

	# 卡牌始终跟随鼠标
	dragged_card.global_position = mouse_pos - dragged_card.size / 2

	# 更新瞄准箭头（仅攻击牌）
	if not _drag_is_self_target:
		targeting_arrow.update_target(mouse_pos)
		# 检查是否悬停在敌人上(用于箭头变色)
		if hovered_enemy != null:
			targeting_arrow.set_highlighting_on(true)
		else:
			targeting_arrow.set_highlighting_on(false)


## 卡牌拖拽释放
func _on_card_drag_released() -> void:
	if dragged_card == null:
		_cancel_card_drag()
		return

	var card_index = card_nodes.find(dragged_card)
	if card_index < 0:
		_cancel_card_drag()
		return

	var card = player.hand[card_index]

	# 检查是否在出牌区域
	# 注意：original_position 是手牌容器本地坐标，转换为全局坐标比较
	# 前提：hand_container 在拖拽过程中不会移动（当前成立）
	var card_y = dragged_card.global_position.y
	var original_y = dragged_card.original_position.y + hand_container.global_position.y

	if card_y >= original_y + PLAY_ZONE_OFFSET:
		# 没进入出牌区域 - 取消
		_cancel_card_drag()
		return

	# 确定目标
	var target_index = -1
	if card.aoe or card.card_type != CardData.CardType.ATTACK:
		# AOE或非攻击牌(技能/能力) - 无需选目标
		target_index = -1
	elif hovered_enemy != null and is_instance_valid(hovered_enemy) and hovered_enemy.enemy_data.is_alive():
		# 单体攻击 - 有悬停目标（必须存活）
		target_index = enemy_nodes.find(hovered_enemy)
	else:
		# 单体攻击 - 无悬停目标，找第一个存活敌人
		for i in range(enemy_nodes.size()):
			if enemy_nodes[i].enemy_data.is_alive():
				target_index = i
				break

	_play_card(card_index, target_index)


## 取消卡牌拖拽
func _cancel_card_drag() -> void:
	if dragged_card != null:
		dragged_card.stop_drag()
		dragged_card.position = dragged_card.original_position
		dragged_card = null

	targeting_state = TargetingState.NONE
	_drag_is_self_target = false
	targeting_arrow.stop_drawing()
	player_area.modulate = Color.WHITE

	if hovered_enemy != null:
		hovered_enemy.unhighlight()
		hovered_enemy = null


## 打出卡牌
func _play_card(hand_index: int, enemy_index: int) -> void:
	# 停止拖拽
	if dragged_card != null:
		dragged_card.stop_drag()
		dragged_card = null

	targeting_arrow.stop_drawing()
	targeting_state = TargetingState.NONE
	_drag_is_self_target = false
	player_area.modulate = Color.WHITE

	if hovered_enemy != null:
		hovered_enemy.unhighlight()
		hovered_enemy = null

	# 播放出牌动画
	_play_card_animation(hand_index)

	# 根据卡牌类型播放角色动画
	var card = player.hand[hand_index]
	match card.card_type:
		CardData.CardType.ATTACK:
			var target_pos := _get_attack_target_global_pos(enemy_index)
			player_sprite.play_attack(target_pos)
			AudioManager.sfx("slash_attack.mp3")
		CardData.CardType.SKILL:
			player_sprite.play_skill_burst(skill_effect_area)
			AudioManager.sfx("blunt_attack.mp3")
		CardData.CardType.ABILITY:
			player_sprite.play_ability_effect()
			AudioManager.sfx("burn_card.mp3")

	# 调用战斗管理器打出卡牌
	var msg = battle_manager.player_play_card(hand_index, enemy_index)
	_log_text(msg)

	# 即时刷新所有显示
	_update_all_displays()

	# 诅咒/debuff 牌音效
	if card.apply_burning > 0 or card.apply_weak > 0 or card.apply_vulnerable > 0 or \
	   card.apply_frail > 0 or card.apply_venom > 0 or card.apply_frozen > 0 or \
	   card.apply_armor_break > 0 or card.card_type == CardData.CardType.CURSE:
		AudioManager.sfx("doom_apply.mp3")

	# 攻击牌命中时敌人抖动 + 伤害数字（延迟到冲刺命中瞬间）
	if card.card_type == CardData.CardType.ATTACK:
		get_tree().create_timer(0.15).timeout.connect(_show_enemy_damage_effects.bind(enemy_index))
		if battle_manager.last_damage_dealt > 0:
			get_tree().create_timer(0.15).timeout.connect(_show_damage_number.bind(battle_manager.last_damage_target_index, battle_manager.last_damage_dealt))

	# 检查战斗是否结束
	if battle_manager.state == BattleManager.BattleState.VICTORY:
		_show_battle_result(true)
	elif battle_manager.state == BattleManager.BattleState.DEFEAT:
		_show_battle_result(false)


## 播放出牌动画
func _play_card_animation(hand_index: int) -> void:
	if hand_index < card_nodes.size():
		var card_node = card_nodes[hand_index]
		_animating_card_node = card_node
		# 卡牌飞向屏幕上部消失
		var screen_center = global_position + Vector2(size.x / 2.0, size.y * 0.3) - card_node.size / 2.0
		var tween = create_tween()
		tween.tween_property(card_node, "global_position", screen_center, 0.2)
		tween.tween_property(card_node, "modulate:a", 0.0, 0.1)
		tween.tween_callback(func():
			if is_instance_valid(card_node):
				card_node.queue_free()
			_animating_card_node = null
		)


## 获取攻击目标的全局位置
func _get_attack_target_global_pos(enemy_index: int) -> Vector2:
	if enemy_index >= 0 and enemy_index < enemy_nodes.size():
		var node := enemy_nodes[enemy_index]
		return node.global_position + node.size / 2.0
	return enemy_area.global_position + enemy_area.size / 2.0


## 震屏效果
func shake_screen(intensity: float = 6.0, duration: float = 0.25) -> void:
	var original_pos := position
	var tween := create_tween()
	var steps := 5
	for i in range(steps):
		var decay := 1.0 - float(i) / steps
		var dx := randf_range(-intensity, intensity) * decay
		var dy := randf_range(-intensity, intensity) * decay
		tween.tween_property(self, "position", original_pos + Vector2(dx, dy), duration / steps)
	tween.tween_property(self, "position", original_pos, 0.03)


## 攻击命中时敌人抖动
func _show_enemy_damage_effects(target_index: int = -1) -> void:
	if target_index >= 0 and target_index < enemy_nodes.size():
		# 单体攻击：只让目标敌人抖动
		var node := enemy_nodes[target_index]
		if is_instance_valid(node) and node.enemy_data.is_alive():
			node.show_shake()
	else:
		# AOE攻击或未指定目标：所有存活敌人抖动
		for i in range(enemy_nodes.size()):
			var node := enemy_nodes[i]
			if is_instance_valid(node) and node.enemy_data.is_alive():
				node.show_shake()


## 显示敌人身上的伤害数字
func _show_damage_number(enemy_index: int, damage: int) -> void:
	if enemy_index >= 0 and enemy_index < enemy_nodes.size():
		if is_instance_valid(enemy_nodes[enemy_index]):
			enemy_nodes[enemy_index].show_damage_effect(damage)


## === 敌人悬停 ===

func _on_enemy_hovered(enemy_node: EnemyNode) -> void:
	if (targeting_state == TargetingState.DRAGGING_CARD and not _drag_is_self_target) \
			or targeting_state == TargetingState.SELECTING_POTION_TARGET:
		# 已死亡敌人不可选为目标
		if not enemy_node.enemy_data.is_alive():
			return
		hovered_enemy = enemy_node
		enemy_node.highlight()
		targeting_arrow.set_highlighting_on(true)


func _on_enemy_unhovered(enemy_node: EnemyNode) -> void:
	if hovered_enemy == enemy_node:
		hovered_enemy = null
		enemy_node.unhighlight()
		if targeting_state == TargetingState.DRAGGING_CARD or targeting_state == TargetingState.SELECTING_POTION_TARGET:
			targeting_arrow.set_highlighting_on(false)


## === 结束回合 ===

func _on_end_turn_pressed() -> void:
	if battle_manager.state != BattleManager.BattleState.PLAYER_TURN:
		return
	if targeting_state != TargetingState.NONE:
		return
	# 异步选择进行中时禁止结束回合
	if battle_manager._pending_discard or battle_manager._pending_exhaust or battle_manager._pending_fire_select or battle_manager._pending_relic_choice:
		return

	AudioManager.ui("ui_click.wav")
	_cancel_card_drag()
	end_turn_button.disabled = true

	# 弃牌动画：手牌化光飞到弃牌堆
	await _animate_discard_remaining()

	if not is_instance_valid(self):
		return

	# 记录哪些敌人将要攻击（用于播放攻击动画）
	var attacking_enemies: Array[EnemyNode] = []
	for i in range(enemy_nodes.size()):
		var node = enemy_nodes[i]
		if is_instance_valid(node) and node.enemy_data.is_alive() and node.enemy_data.current_intent != null:
			if node.enemy_data.current_intent.intent == Enemy.IntentType.ATTACK or \
			   node.enemy_data.current_intent.intent == Enemy.IntentType.SPECIAL:
				attacking_enemies.append(node)

	# 记录敌人阶段（用于检测阶段转换）
	var phases_before: Array[int] = []
	for node in enemy_nodes:
		if is_instance_valid(node):
			phases_before.append(node.enemy_data.current_phase)
		else:
			phases_before.append(-1)

	_log_text("\n[color=yellow]═══ 结束回合 ═══[/color]\n")
	var msg = battle_manager.player_end_turn()
	_log_text(msg)
	AudioManager.sfx("enemy_turn.mp3")

	# 检测阶段转换并播放粒子特效
	for i in range(enemy_nodes.size()):
		if is_instance_valid(enemy_nodes[i]) and enemy_nodes[i].enemy_data.is_alive() and i < phases_before.size():
			if enemy_nodes[i].enemy_data.current_phase != phases_before[i]:
				enemy_nodes[i].play_phase_transition_effect()

	# 播放敌人攻击动画（逐个冲刺），每次命中后立即更新血条
	for enemy_node in attacking_enemies:
		if not is_instance_valid(self):
			return
		if is_instance_valid(enemy_node) and enemy_node.enemy_data.is_alive():
			var player_pos = player_sprite.global_position + player_sprite.size / 2.0
			await enemy_node.play_attack_animation(player_pos)
			AudioManager.sfx("heavy_attack.mp3")
			if not is_instance_valid(self):
				return
			# 命中瞬间更新血条
			_update_player_display()
			_update_energy_display()
			await get_tree().create_timer(0.1).timeout
			if not is_instance_valid(self):
				return

	# 敌人死亡渐隐动画
	for i in range(enemy_nodes.size()):
		if is_instance_valid(enemy_nodes[i]) and not enemy_nodes[i].enemy_data.is_alive():
			enemy_nodes[i].play_death_animation()
			AudioManager.sfx("death_stinger.mp3", -6.0)

	_update_all_displays()
	end_turn_button.disabled = false
	if battle_manager.state == BattleManager.BattleState.PLAYER_TURN:
		AudioManager.sfx("player_turn.mp3")

	if battle_manager.state == BattleManager.BattleState.VICTORY:
		_show_battle_result(true)
	elif battle_manager.state == BattleManager.BattleState.DEFEAT:
		_show_battle_result(false)


## === 辅助函数 ===

## 添加日志
func _log_text(text: String) -> void:
	battle_log.append_text(text)


## 显示战斗结果
func _show_battle_result(victory: bool) -> void:
	end_turn_button.disabled = true

	if victory:
		_log_text("\n[color=green][b]═══ 战斗胜利！ ═══[/b][/color]\n")
		AudioManager.sfx("victory.mp3")
	else:
		_log_text("\n[color=red][b]═══ 战斗失败 ═══[/b][/color]\n")
		AudioManager.sfx("death_stinger.mp3")

	# 延迟后发射信号，由main.gd处理后续
	await get_tree().create_timer(1.5).timeout
	if not is_instance_valid(self):
		return
	battle_ended.emit(victory)


## === 卡牌详情面板 ===

func _on_card_detail_requested(card_data: CardData, card_pos: Vector2, card_sz: Vector2) -> void:
	# 销毁旧面板
	if _detail_panel != null:
		_detail_panel.queue_free()
		_detail_panel = null

	_detail_panel = CardDetailPanel.new()
	add_child(_detail_panel)
	_detail_panel.show_card(card_data)

	# 等一帧让面板计算出实际尺寸
	await get_tree().process_frame

	# await 期间面板可能被销毁（如快速移出鼠标）
	if _detail_panel == null or not is_instance_valid(_detail_panel):
		return

	var panel_w = _detail_panel.size.x
	var panel_h = _detail_panel.size.y

	# 水平居中对齐卡牌
	var px = card_pos.x + card_sz.x / 2.0 - panel_w / 2.0
	# 面板底部对齐卡牌顶部上方 20px
	var py = card_pos.y - panel_h - 20

	# 边界修正
	px = clampf(px, 4.0, size.x - panel_w - 4.0)
	if py < 4.0:
		# 上方空间不足，放到卡牌下方
		py = card_pos.y + card_sz.y + 8

	_detail_panel.position = Vector2(px, py)


func _on_card_detail_hidden() -> void:
	if _detail_panel != null:
		_detail_panel.fade_out()
		_detail_panel = null


## === 药水 ===

func _on_potion_used(potion_index: int) -> void:
	if battle_manager == null:
		return
	if targeting_state != TargetingState.NONE:
		return
	if potion_index < 0 or potion_index >= battle_manager.potions.size():
		return

	var potion = battle_manager.potions[potion_index]
	if potion.effect_type == PotionData.EffectType.ATTACK_ENEMY:
		_begin_potion_targeting(potion_index)
		return

	var msg = battle_manager.use_potion(potion_index)
	_log_text(msg)
	AudioManager.potion_slosh()
	_sync_potions_to_manager()
	_update_all_displays()

	if battle_manager.state == BattleManager.BattleState.VICTORY:
		_show_battle_result(true)
	elif battle_manager.state == BattleManager.BattleState.DEFEAT:
		_show_battle_result(false)


func _begin_potion_targeting(potion_index: int) -> void:
	var has_alive_enemy := false
	for node in enemy_nodes:
		if is_instance_valid(node) and node.enemy_data.is_alive():
			has_alive_enemy = true
			break
	if not has_alive_enemy:
		_log_text("[color=gray]没有可攻击的敌人[/color]\n")
		AudioManager.ui("deny.mp3")
		return

	_pending_potion_index = potion_index
	targeting_state = TargetingState.SELECTING_POTION_TARGET
	var arrow_start = player_sprite.global_position + player_sprite.size / 2
	targeting_arrow.start_drawing(arrow_start)
	targeting_arrow.update_target(get_global_mouse_position())
	_log_text("[color=cyan]选择丹药投掷目标，右键取消[/color]\n")
	AudioManager.ui("card_select.mp3")


func _update_potion_targeting_visuals() -> void:
	targeting_arrow.update_target(get_global_mouse_position())
	targeting_arrow.set_highlighting_on(hovered_enemy != null)


func _on_potion_target_released() -> void:
	if targeting_state != TargetingState.SELECTING_POTION_TARGET:
		return
	if hovered_enemy == null or not is_instance_valid(hovered_enemy) or not hovered_enemy.enemy_data.is_alive():
		_log_text("[color=gray]请选择一个存活敌人作为丹药目标[/color]\n")
		AudioManager.ui("deny.mp3")
		return

	var target_index = enemy_nodes.find(hovered_enemy)
	_use_potion_at_target(_pending_potion_index, target_index)


func _cancel_potion_targeting() -> void:
	targeting_state = TargetingState.NONE
	_pending_potion_index = -1
	targeting_arrow.stop_drawing()
	if hovered_enemy != null:
		hovered_enemy.unhighlight()
		hovered_enemy = null
	_log_text("[color=gray]取消使用丹药[/color]\n")


func _use_potion_at_target(potion_index: int, target_index: int) -> void:
	var target_node: EnemyNode = null
	if target_index >= 0 and target_index < enemy_nodes.size():
		target_node = enemy_nodes[target_index]

	targeting_state = TargetingState.NONE
	_pending_potion_index = -1
	targeting_arrow.stop_drawing()
	if hovered_enemy != null:
		hovered_enemy.unhighlight()
		hovered_enemy = null

	var msg = battle_manager.use_potion(potion_index, target_index)
	_log_text(msg)
	AudioManager.potion_slosh()
	if target_node != null and is_instance_valid(target_node):
		target_node.show_shake()
	_sync_potions_to_manager()
	_update_all_displays()

	if battle_manager.state == BattleManager.BattleState.VICTORY:
		_show_battle_result(true)
	elif battle_manager.state == BattleManager.BattleState.DEFEAT:
		_show_battle_result(false)


func _on_potion_discarded(potion_index: int) -> void:
	if battle_manager == null:
		return
	if targeting_state == TargetingState.SELECTING_POTION_TARGET:
		_cancel_potion_targeting()
	var msg = battle_manager.discard_potion(potion_index)
	_log_text(msg)
	_sync_potions_to_manager()
	_update_all_displays()


## 同步战斗管理器的药水到 PlayerManager（让顶栏实时刷新）
func _sync_potions_to_manager() -> void:
	if battle_manager == null:
		return
	PlayerManager.potions.clear()
	for p in battle_manager.potions:
		if p.id not in BattleManager._consumed_potion_ids:
			PlayerManager.potions.append(p)
	PlayerManager.stats_changed.emit()


## === 异火选择UI ===

## 异火选择面板引用
var _fire_select_panel: PanelContainer = null

## 异火置换：弹出异火选择
func _on_fire_type_requested() -> void:
	# 创建选择面板
	_fire_select_panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_fire_select_panel.add_child(vbox)

	var title = Label.new()
	title.text = "选择凝聚异火"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var fires = [
		{"name": "青莲地心火", "type": Player.FireType.GREEN, "color": Color(0.2, 0.8, 0.3)},
		{"name": "陨落心炎", "type": Player.FireType.WHITE, "color": Color(0.95, 0.95, 1.0)},
		{"name": "骨灵冷火", "type": Player.FireType.BLUE, "color": Color(0.7, 0.85, 0.95)},
		{"name": "三千焱炎火", "type": Player.FireType.PURPLE, "color": Color(0.5, 0.1, 0.7)},
	]

	for fire_info in fires:
		var btn = Button.new()
		btn.text = fire_info.name
		btn.add_theme_color_override("font_color", fire_info.color)
		btn.pressed.connect(_on_fire_selected.bind(fire_info.type))
		vbox.add_child(btn)

	# 居中显示
	_fire_select_panel.set_anchors_preset(Control.PRESET_CENTER)
	_fire_select_panel.custom_minimum_size = Vector2(200, 180)
	add_child(_fire_select_panel)


## 异火选择回调
func _on_fire_selected(fire_type: Player.FireType) -> void:
	AudioManager.ui("ui_click.wav")
	if _fire_select_panel != null:
		_fire_select_panel.queue_free()
		_fire_select_panel = null

	var msg = battle_manager.resolve_fire_channel(fire_type)
	_log_text(msg)
	_update_all_displays()

	if battle_manager.state == BattleManager.BattleState.VICTORY:
		_show_battle_result(true)
	elif battle_manager.state == BattleManager.BattleState.DEFEAT:
		_show_battle_result(false)


## === 弃置选择UI（灵魂感知） ===

## 弃置选择信号
signal _discard_selected(cards: Array)

## 灵魂感知/心炎流转：弹出弃置选择
func _on_choose_discard_requested(count: int) -> void:
	# 手牌为空时跳过选择，直接完成弃置+抽牌
	if player.hand.is_empty():
		var result_msg = battle_manager.resolve_choose_discard([])
		_log_text(result_msg)
		_update_all_displays()
		if battle_manager.state == BattleManager.BattleState.VICTORY:
			_show_battle_result(true)
		elif battle_manager.state == BattleManager.BattleState.DEFEAT:
			_show_battle_result(false)
		return
	count = min(count, player.hand.size())

	# 全屏半透明遮罩
	var overlay_bg = ColorRect.new()
	overlay_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_bg.color = Color(0, 0, 0, 0.6)
	overlay_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay_bg)

	# 居中内容面板
	var discard_overlay = PanelContainer.new()
	discard_overlay.anchor_left = 0.5
	discard_overlay.anchor_top = 0.5
	discard_overlay.anchor_right = 0.5
	discard_overlay.anchor_bottom = 0.5
	discard_overlay.offset_left = -200
	discard_overlay.offset_top = -140
	discard_overlay.offset_right = 200
	discard_overlay.offset_bottom = 140
	discard_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(16)
	discard_overlay.add_theme_stylebox_override("panel", panel_style)
	overlay_bg.add_child(discard_overlay)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	discard_overlay.add_child(vbox)

	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "选择丢弃 %d 张牌" % count
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var hint = Label.new()
	hint.text = "点击卡牌选择，选满后自动确认"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hint.add_theme_font_size_override("font_size", 13)
	vbox.add_child(hint)

	var card_grid = HBoxContainer.new()
	card_grid.alignment = BoxContainer.ALIGNMENT_CENTER
	card_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(card_grid)

	# 创建手牌节点
	var discard_card_nodes: Array[CardNode] = []
	for card_data in player.hand:
		var node = card_scene.instantiate() as CardNode
		node.setup(card_data)
		node.set_playable(true)
		node.card_clicked.connect(_on_discard_card_clicked.bind(card_data, count, discard_card_nodes, overlay_bg))
		card_grid.add_child(node)
		discard_card_nodes.append(node)

	# 等待玩家选择完成
	var selected_cards = await _discard_selected

	# 场景可能在await期间被释放
	if not is_instance_valid(self):
		return

	# 清理覆盖层（遮罩+面板一起销毁）
	if is_instance_valid(overlay_bg):
		overlay_bg.queue_free()

	# 回调战斗管理器完成弃置+抽牌
	var msg = battle_manager.resolve_choose_discard(selected_cards)
	_log_text(msg)
	_update_all_displays()

	if battle_manager.state == BattleManager.BattleState.VICTORY:
		_show_battle_result(true)
	elif battle_manager.state == BattleManager.BattleState.DEFEAT:
		_show_battle_result(false)


## 弃置选择：卡牌被点击
func _on_discard_card_clicked(card_node: CardNode, _card_data: CardData, required_count: int,
		discard_card_nodes: Array[CardNode], overlay_bg: ColorRect) -> void:
	AudioManager.ui("ui_click.wav")
	# 切换选中状态
	if card_node.is_selected():
		card_node.set_selected(false)
	else:
		card_node.set_selected(true)

	# 收集所有选中的卡牌
	var selected: Array[CardData] = []
	for n in discard_card_nodes:
		if n.is_selected():
			selected.append(n.card_data)

	# 更新标题（通过节点名查找，避免脆弱的 child 链）
	var title_label = overlay_bg.find_child("TitleLabel", true, false)
	if title_label:
		title_label.text = "选择丢弃 %d 张牌 (%d/%d)" % [required_count, selected.size(), required_count]

	# 选满自动确认
	if selected.size() >= required_count:
		_discard_selected.emit(selected)


## === 消耗选择UI（药鼎淬炼） ===

## 消耗选择信号
signal _exhaust_selected(cards: Array)

## 药鼎淬炼：弹出消耗选择
func _on_choose_exhaust_requested(count: int) -> void:
	# 手牌为空时跳过选择，直接完成消耗+能量+抽牌
	if player.hand.is_empty():
		var result_msg = battle_manager.resolve_choose_exhaust([])
		_log_text(result_msg)
		_update_all_displays()
		if battle_manager.state == BattleManager.BattleState.VICTORY:
			_show_battle_result(true)
		elif battle_manager.state == BattleManager.BattleState.DEFEAT:
			_show_battle_result(false)
		return
	count = min(count, player.hand.size())

	# 全屏半透明遮罩
	var overlay_bg = ColorRect.new()
	overlay_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_bg.color = Color(0, 0, 0, 0.6)
	overlay_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay_bg)

	# 居中内容面板
	var exhaust_overlay = PanelContainer.new()
	exhaust_overlay.anchor_left = 0.5
	exhaust_overlay.anchor_top = 0.5
	exhaust_overlay.anchor_right = 0.5
	exhaust_overlay.anchor_bottom = 0.5
	exhaust_overlay.offset_left = -200
	exhaust_overlay.offset_top = -140
	exhaust_overlay.offset_right = 200
	exhaust_overlay.offset_bottom = 140
	exhaust_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(16)
	exhaust_overlay.add_theme_stylebox_override("panel", panel_style)
	overlay_bg.add_child(exhaust_overlay)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	exhaust_overlay.add_child(vbox)

	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "选择消耗 %d 张牌" % count
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var hint = Label.new()
	hint.text = "点击卡牌选择，选满后自动确认"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hint.add_theme_font_size_override("font_size", 13)
	vbox.add_child(hint)

	var card_grid = HBoxContainer.new()
	card_grid.alignment = BoxContainer.ALIGNMENT_CENTER
	card_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(card_grid)

	# 创建手牌节点
	var exhaust_card_nodes: Array[CardNode] = []
	for card_data in player.hand:
		var node = card_scene.instantiate() as CardNode
		node.setup(card_data)
		node.set_playable(true)
		node.card_clicked.connect(_on_exhaust_card_clicked.bind(card_data, count, exhaust_card_nodes, overlay_bg))
		card_grid.add_child(node)
		exhaust_card_nodes.append(node)

	# 等待玩家选择完成
	var selected_cards = await _exhaust_selected

	if not is_instance_valid(self):
		return

	# 清理覆盖层（遮罩+面板一起销毁）
	if is_instance_valid(overlay_bg):
		overlay_bg.queue_free()

	# 回调战斗管理器完成消耗+能量+抽牌
	var msg = battle_manager.resolve_choose_exhaust(selected_cards)
	_log_text(msg)
	_update_all_displays()

	if battle_manager.state == BattleManager.BattleState.VICTORY:
		_show_battle_result(true)
	elif battle_manager.state == BattleManager.BattleState.DEFEAT:
		_show_battle_result(false)


## 消耗选择：卡牌被点击
func _on_exhaust_card_clicked(card_node: CardNode, _card_data: CardData, required_count: int,
		exhaust_card_nodes: Array[CardNode], overlay_bg: ColorRect) -> void:
	AudioManager.ui("ui_click.wav")
	# 切换选中状态
	if card_node.is_selected():
		card_node.set_selected(false)
	else:
		card_node.set_selected(true)

	# 收集所有选中的卡牌
	var selected: Array[CardData] = []
	for n in exhaust_card_nodes:
		if n.is_selected():
			selected.append(n.card_data)

	# 更新标题（通过节点名查找，避免脆弱的 child 链）
	var title_label = overlay_bg.find_child("TitleLabel", true, false)
	if title_label:
		title_label.text = "选择消耗 %d 张牌 (%d/%d)" % [required_count, selected.size(), required_count]

	# 选满自动确认
	if selected.size() >= required_count:
		_exhaust_selected.emit(selected)


## 遗物选择信号
signal _relic_choice_made(index: int)

## 遗物选择：弹出两按钮选择
func _on_relic_choice_requested(option1: String, option2: String) -> void:
	AudioManager.ui("ui_click.wav")
	var overlay = PanelContainer.new()
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	overlay.add_child(vbox)

	var title = Label.new()
	title.text = "选择一项"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var btn1 = Button.new()
	btn1.text = option1
	btn1.custom_minimum_size = Vector2(200, 40)
	btn1.pressed.connect(func(): _relic_choice_made.emit(0))
	vbox.add_child(btn1)

	var btn2 = Button.new()
	btn2.text = option2
	btn2.custom_minimum_size = Vector2(200, 40)
	btn2.pressed.connect(func(): _relic_choice_made.emit(1))
	vbox.add_child(btn2)

	overlay.set_anchors_preset(Control.PRESET_CENTER)
	overlay.custom_minimum_size = Vector2(300, 160)
	add_child(overlay)

	var choice = await _relic_choice_made

	if not is_instance_valid(self):
		return

	if is_instance_valid(overlay):
		overlay.queue_free()

	var msg = battle_manager.resolve_relic_choice(choice)
	_log_text(msg)
	_update_all_displays()

	if battle_manager.state == BattleManager.BattleState.VICTORY:
		_show_battle_result(true)
	elif battle_manager.state == BattleManager.BattleState.DEFEAT:
		_show_battle_result(false)
