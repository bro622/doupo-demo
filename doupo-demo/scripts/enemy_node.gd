## 敌人节点
## 可视化敌人，支持悬停高亮作为目标
class_name EnemyNode
extends Control

## 敌人数据
var enemy_data: Enemy

## 状态栏引用
@onready var status_bar: StatusBar = $StatusContainer

## 精灵动画引用
@onready var enemy_sprite: EnemySprite = $Body

## 是否被选中(鼠标悬停)
var is_hovered: bool = false
## 是否正在播放死亡动画（防重入）
var _dying: bool = false
## 缓存高亮样式（避免每次创建）
var _highlight_style: StyleBoxFlat = null

## 信号
signal enemy_hovered(enemy_node: EnemyNode)
signal enemy_unhovered(enemy_node: EnemyNode)


## 意图浮动动画计时器
var _intent_time: float = 0.0


func _ready() -> void:
	# 连接鼠标进入/离开信号
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	# 子节点必须IGNORE，否则会拦截鼠标事件，父节点收不到信号
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	# 意图图标上下浮动（参考 STS2 NIntent._Process）
	if enemy_data and enemy_data.current_intent:
		_intent_time += delta * 2.0
		var intent_container = $IntentContainer
		if intent_container:
			intent_container.position.y = -22.0 + sin(_intent_time * PI) * 3.0


## 设置敌人数据并更新显示
func setup(data: Enemy) -> void:
	enemy_data = data
	# 加载敌人纹理并启动呼吸动画
	enemy_sprite.setup(data)
	# 死亡动画结束后由父节点清理（避免精灵自释放后父节点持有无效引用）
	enemy_sprite.death_animation_finished.connect(_on_death_animation_finished)
	# 应用角色轮廓shader
	_apply_outline_shader()
	_update_visuals()


## 死亡动画完成回调
func _on_death_animation_finished() -> void:
	if is_instance_valid(enemy_sprite):
		enemy_sprite.queue_free()
	# 延迟一帧再隐藏自身（让视觉过渡自然）
	await get_tree().process_frame
	if is_instance_valid(self):
		visible = false


## 应用轮廓shader
func _apply_outline_shader() -> void:
	var shader = load("res://shaders/character_outline.gdshader")
	if shader:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("tex_size", Vector2(enemy_sprite.size.x, enemy_sprite.size.y))
		# 敌人：红色边缘光
		mat.set_shader_parameter("rim_color", Color(1.0, 0.4, 0.3, 0.8))
		enemy_sprite.material = mat


## 更新视觉显示
func _update_visuals() -> void:
	if enemy_data == null:
		return

	# 名称
	var name_label = $NameLabel as Label
	name_label.text = enemy_data.char_name

	# HP
	_update_hp_display()

	# 意图
	update_intent_display()


## 更新HP显示
func _update_hp_display() -> void:
	if enemy_data == null:
		return

	var hp_text = $HPBarContainer/HPText as Label
	var hp_bar = $HPBarContainer/HPBar as ProgressBar

	hp_text.text = "%d / %d" % [enemy_data.hp, enemy_data.max_hp]
	hp_bar.max_value = enemy_data.max_hp
	hp_bar.value = enemy_data.hp

	# 护盾
	var block_badge = $BlockBadge as Panel
	if enemy_data.block > 0:
		block_badge.visible = true
		var block_label = block_badge.get_node_or_null("BlockLabel") as Label
		if block_label:
			block_label.text = str(enemy_data.block)
	else:
		block_badge.visible = false

	# 状态效果
	status_bar.update_display(enemy_data)


## 更新意图显示
func update_intent_display() -> void:
	if enemy_data == null or enemy_data.current_intent == null:
		return

	var intent_icon = $IntentContainer/IntentIcon as TextureRect
	var intent_label = $IntentContainer/IntentLabel as Label

	intent_label.text = enemy_data.get_intent_text()
	# 加载 PNG 意图图标（参考 STS2 AttackIntent 按伤害量分级）
	var icon_path = enemy_data.get_intent_icon_path()
	if icon_path != "" and ResourceLoader.exists(icon_path):
		intent_icon.texture = load(icon_path)


## 高亮(鼠标悬停)
func highlight() -> void:
	is_hovered = true
	var reticle = $SelectReticle as Panel
	reticle.visible = true

	# 高亮边框（缓存样式，避免重复创建）
	if _highlight_style == null:
		_highlight_style = StyleBoxFlat.new()
		_highlight_style.border_color = Color(1, 0.3, 0.3, 0.8)
		_highlight_style.border_width_left = 3
		_highlight_style.border_width_right = 3
		_highlight_style.border_width_top = 3
		_highlight_style.border_width_bottom = 3
		_highlight_style.bg_color = Color(1, 0, 0, 0.1)
		_highlight_style.corner_radius_top_left = 8
		_highlight_style.corner_radius_top_right = 8
		_highlight_style.corner_radius_bottom_left = 8
		_highlight_style.corner_radius_bottom_right = 8
	reticle.add_theme_stylebox_override("panel", _highlight_style)


## 取消高亮
func unhighlight() -> void:
	is_hovered = false
	var reticle = $SelectReticle as Panel
	reticle.visible = false


func _on_mouse_entered() -> void:
	enemy_hovered.emit(self)


func _on_mouse_exited() -> void:
	enemy_unhovered.emit(self)


## 显示受伤效果
func show_damage_effect(damage: int) -> void:
	# 创建伤害数字显示
	var dmg_label = Label.new()
	dmg_label.text = str(damage)
	dmg_label.add_theme_font_size_override("font_size", 28)
	dmg_label.add_theme_color_override("font_color", Color.RED)
	dmg_label.position = Vector2(60, 50)
	add_child(dmg_label)

	# 动画：向上飘动并消失
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dmg_label, "position:y", dmg_label.position.y - 60, 0.8)
	tween.tween_property(dmg_label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(func():
		if is_instance_valid(dmg_label):
			dmg_label.queue_free()
	)

	# 身体抖动
	enemy_sprite.show_damage_shake()


## 显示获得护盾效果
func show_block_effect() -> void:
	_update_hp_display()


## 仅身体抖动（不创建浮动伤害数字）
func show_shake() -> void:
	if is_instance_valid(enemy_sprite):
		enemy_sprite.show_damage_shake()


## 播放攻击动画（向玩家冲刺）
func play_attack_animation(player_global_pos: Vector2) -> void:
	if not is_instance_valid(enemy_sprite):
		return
	enemy_sprite.play_attack(player_global_pos)
	await enemy_sprite.attack_animation_finished


## 播放死亡渐隐动画
func play_death_animation() -> void:
	if _dying:
		return
	_dying = true
	# 禁用鼠标交互（不可被选为目标）
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 隐藏所有UI信息
	$NameLabel.visible = false
	$HPBarContainer.visible = false
	$IntentContainer.visible = false
	$StatusContainer.visible = false
	if $BlockBadge.visible:
		$BlockBadge.visible = false
	if is_instance_valid(enemy_sprite):
		enemy_sprite.play_death()


## 播放阶段转换粒子特效
func play_phase_transition_effect() -> void:
	# 阶段换图
	_try_swap_phase_texture()

	# 创建粒子发射器
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 30
	particles.lifetime = 0.8
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.direction = Vector2(0, -1)
	particles.spread = 60.0
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 150.0
	particles.gravity = Vector2(0, 200)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(0.8, 0.2, 0.1, 1.0)  # 红色粒子

	# 居中定位
	particles.position = Vector2(70, 80)
	add_child(particles)

	# 闪光效果
	var tween = create_tween()
	enemy_sprite.modulate = Color(1.5, 0.5, 0.3, 1.0)
	tween.tween_property(enemy_sprite, "modulate", Color.WHITE, 0.6)

	# 自动清理粒子
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(particles):
		particles.queue_free()


## 尝试根据当前阶段切换 Boss 纹理
func _try_swap_phase_texture() -> void:
	if not enemy_data or enemy_data.current_phase <= 0:
		return
	var phase = enemy_data.current_phase + 1  # current_phase 是 0-indexed
	var base_name = enemy_data.char_name
	var key = "%s%d阶段" % [base_name, phase]
	var path = EnemyDatabase.get_texture_path(key)
	if path != "" and ResourceLoader.exists(path):
		var tex = load(path)
		if tex != null:
			enemy_sprite.texture = tex
