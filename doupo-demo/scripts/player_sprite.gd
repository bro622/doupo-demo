## 玩家精灵动画控制器
## 管理待机呼吸、攻击冲刺、斗气残影爆发、能力粒子特效
## _base_position 是固定锚点，所有动画通过 _anim_offset 偏移
## _process() 每帧计算 position = _base_position + _anim_offset
class_name PlayerSprite
extends TextureRect

## 纹理资源
var idle_texture: Texture2D
var attack_texture: Texture2D

## 美杜莎：三姿态纹理
var cailin_idle_none: Texture2D
var cailin_attack_none: Texture2D
var cailin_idle_queen: Texture2D
var cailin_attack_queen: Texture2D
var cailin_idle_python: Texture2D
var cailin_attack_python: Texture2D

## 美杜莎：姿态图标
var _stance_icon: TextureRect = null
var _stance_icon_tween: Tween = null

## 永久异火环绕（青莲地心火·本源）
var _permanent_fire_active: bool = false
var _fire_orb_nodes: Array[Control] = []
var _fire_orb_angle: float = 0.0
const FIRE_ORB_RADIUS: float = 55.0
const FIRE_ORB_SPEED: float = 1.5  # 弧度/秒
const FIRE_ORB_SIZE: float = 20.0
const FIRE_GREEN: Color = Color(0.2, 0.8, 0.3, 0.95)
const FIRE_GREEN_BORDER: Color = Color(0.4, 1.0, 0.5, 1.0)

## 呼吸动画状态
var _breathing: bool = false
var _breath_tween: Tween = null

## 攻击动画状态
var _attacking: bool = false

## 固定锚点（场景初始位置，永不修改）
var _base_position: Vector2

## 动画偏移量（tween修改此值，_process应用到position）
var _anim_offset: Vector2 = Vector2.ZERO
## 动画缩放量（tween修改此值，_process应用到scale）
var _anim_scale: Vector2 = Vector2.ONE
## 角色基础缩放（不同角色可调整大小）
var _char_scale: float = 1.0

## 信号
signal attack_animation_finished


## 安全加载纹理（文件不存在返回null）
static func _try_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _ready() -> void:
	# 根据选择的角色加载对应贴图
	match PlayerManager.character_id:
		"xuner":
			idle_texture = _try_load("res://assets/characters/xuner/萧薰儿待机.png")
			attack_texture = _try_load("res://assets/characters/xuner/萧薰儿攻击.png")
		"cailin":
			# 美杜莎：加载三姿态纹理
			cailin_idle_none = _try_load("res://assets/characters/cailin/美杜莎无姿态待机.png")
			cailin_attack_none = _try_load("res://assets/characters/cailin/美杜莎无姿态攻击.png")
			cailin_idle_queen = _try_load("res://assets/characters/cailin/美杜莎女王姿态待机.png")
			cailin_attack_queen = _try_load("res://assets/characters/cailin/美杜莎女王姿态攻击.png")
			cailin_idle_python = _try_load("res://assets/characters/cailin/美杜莎吞天蟒姿态待机.png")
			cailin_attack_python = _try_load("res://assets/characters/cailin/美杜莎吞天蟒姿态攻击.png")
			idle_texture = cailin_idle_none
			attack_texture = cailin_attack_none
		_:
			idle_texture = load("res://assets/characters/xiao-yan/萧炎待机.png")
			attack_texture = load("res://assets/characters/xiao-yan/萧炎攻击.png")
	# 贴图缺失时回退到萧炎
	if idle_texture == null:
		idle_texture = load("res://assets/characters/xiao-yan/萧炎待机.png")
	if attack_texture == null:
		attack_texture = load("res://assets/characters/xiao-yan/萧炎攻击.png")

	texture = idle_texture
	_base_position = position

	# 不同角色缩放比例（新素材统一1024x1536）
	match PlayerManager.character_id:
		"xuner":
			_char_scale = 0.85
		_:
			_char_scale = 0.85

	# pivot 设在中心底部（脚部），缩放时脚不离地
	pivot_offset = Vector2(size.x / 2.0, size.y)

	# 将两张贴图嵌入相同尺寸画布，确保角色位置对齐
	_normalize_textures()

	# 应用角色轮廓shader（描边+边缘光+内发光）
	_apply_outline_shader()

	# 美杜莎：连接姿态切换信号
	if PlayerManager.character_id == "cailin":
		# 延迟连接，等待战斗场景中的player节点
		call_deferred("_connect_stance_signal")

	start_breathing()


## 应用轮廓shader
func _apply_outline_shader() -> void:
	var shader = load("res://shaders/character_outline.gdshader")
	if shader:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("tex_size", Vector2(size.x, size.y))
		# 玩家：蓝色边缘光
		mat.set_shader_parameter("rim_color", Color(0.4, 0.6, 1.0, 0.8))
		material = mat


## === 美杜莎：姿态切换转场特效 ===

## 连接姿态切换信号（备用，主要连接在combat_scene.gd中）
func _connect_stance_signal() -> void:
	# 如果姿态图标还未创建，则创建
	if _stance_icon == null:
		_create_stance_icon()


## 创建姿态虚影
func _create_stance_icon() -> void:
	if _stance_icon != null:
		return
	_stance_icon = TextureRect.new()
	_stance_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_stance_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_stance_icon.custom_minimum_size = Vector2(40, 40)
	_stance_icon.size = Vector2(40, 40)
	_stance_icon.position = Vector2(-20, -20)
	_stance_icon.z_index = 0
	_stance_icon.modulate = Color(1, 1, 1, 0)
	_stance_icon.pivot_offset = Vector2(20, 20)
	_stance_icon.mouse_filter = Control.MOUSE_FILTER_STOP
	_stance_icon.tooltip_text = ""
	add_child(_stance_icon)


## 更新姿态虚影显示
func _update_stance_icon(stance: int) -> void:
	if _stance_icon == null:
		return

	if _stance_icon_tween and _stance_icon_tween.is_valid():
		_stance_icon_tween.kill()

	_stance_icon_tween = create_tween()

	match stance:
		0:
			_stance_icon.tooltip_text = ""
			_stance_icon_tween.tween_property(_stance_icon, "modulate:a", 0.0, 0.3)
		1:
			_stance_icon.texture = preload("res://assets/ui/stances/queen.png")
			_stance_icon.tooltip_text = "美杜莎女王姿态\n被动：每次打出技能牌获得2层荆棘（反弹伤害）"
			_stance_icon.modulate = Color(1, 1, 1, 0)
			_stance_icon_tween.tween_property(_stance_icon, "modulate:a", 0.35, 0.3)
			_stance_icon_tween.set_loops()
			_stance_icon_tween.tween_property(_stance_icon, "scale", Vector2(1.05, 1.05), 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			_stance_icon_tween.tween_property(_stance_icon, "scale", Vector2(1.0, 1.0), 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		2:
			_stance_icon.texture = preload("res://assets/ui/stances/python.png")
			_stance_icon.tooltip_text = "吞天蟒姿态\n被动：每次打出攻击牌额外造成3点伤害"
			_stance_icon.modulate = Color(1, 1, 1, 0)
			_stance_icon_tween.tween_property(_stance_icon, "modulate:a", 0.35, 0.3)
			_stance_icon_tween.set_loops()
			_stance_icon_tween.tween_property(_stance_icon, "scale", Vector2(1.08, 1.08), 0.9).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			_stance_icon_tween.tween_property(_stance_icon, "scale", Vector2(1.0, 1.0), 0.9).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


## 姿态切换回调
func _on_stance_changed(new_stance: int, old_stance: int) -> void:
	if PlayerManager.character_id != "cailin":
		return

	_update_stance_icon(new_stance)

	match new_stance:
		0:  # STANCE_NONE
			_play_transition_to_none()
		1:  # STANCE_QUEEN
			_play_transition_to_queen()
		2:  # STANCE_PYTHON
			_play_transition_to_python()


## 进入女王姿态：淡出旧姿态 → 淡入新姿态
func _play_transition_to_queen() -> void:
	stop_breathing()
	_crossfade_stance(cailin_idle_queen, cailin_attack_queen, Color(0.6, 0.2, 0.8, 0.8))


## 进入吞天蟒姿态：淡出旧姿态 → 淡入新姿态
func _play_transition_to_python() -> void:
	stop_breathing()
	_crossfade_stance(cailin_idle_python, cailin_attack_python, Color(0.8, 0.1, 0.1, 0.8))


## 通用姿态交叉淡入淡出
func _crossfade_stance(new_idle: Texture2D, new_attack: Texture2D, rim_color: Color) -> void:
	var tween := create_tween()
	# 淡出当前姿态
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# 换图 + 渐变边缘光
	tween.tween_callback(func():
		texture = new_idle
		idle_texture = new_idle
		attack_texture = new_attack
		_tween_rim_color(rim_color)
	)
	# 淡入新姿态
	tween.tween_property(self, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		start_breathing()
	)


## 退回无姿态：曝光重置
func _play_transition_to_none() -> void:
	stop_breathing()
	# 曝光重置效果
	var tween = create_tween()
	# 闪白
	tween.tween_property(self, "modulate", Color(2, 2, 2, 1), 0.1)
	# 换图
	tween.tween_callback(func():
		idle_texture = cailin_idle_none
		attack_texture = cailin_attack_none
		texture = idle_texture
	)
	# 褪色
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	# 清理姿态效果
	tween.tween_callback(func():
		_reset_anim()
		_update_rim_color(Color(0.4, 0.6, 1.0, 0.8))
		start_breathing()
	)


## 斜切转场特效（通用）
func _play_cut_transition(target_texture: Texture2D, cut_color: Color, is_python: bool) -> void:
	# 动态生成切割方块
	var cut_rect = ColorRect.new()
	cut_rect.color = cut_color
	cut_rect.size = Vector2(800, 200)
	cut_rect.rotation_degrees = -45
	cut_rect.position = Vector2(-500, -500)
	cut_rect.z_index = 100

	add_child(cut_rect)

	var tween = create_tween()

	# 切割块扫过屏幕
	var target_pos = Vector2(1000, 1000)
	tween.tween_property(cut_rect, "position", target_pos, 0.3) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)

	# 在动画中途换图
	tween.tween_callback(func():
		texture = target_texture
	).set_delay(0.15)

	# 动画结束后销毁切割块
	tween.tween_callback(func():
		if is_instance_valid(cut_rect):
			cut_rect.queue_free()
	)

	# 附加形态重量感
	if is_python:
		# 吞天蟒：沉重砸下
		_anim_scale = Vector2(1.2, 1.2)
		var scale_tween = create_tween()
		scale_tween.tween_property(self, "_anim_scale", Vector2(1, 1), 0.4) \
			.set_delay(0.15).set_trans(Tween.TRANS_BOUNCE)
		scale_tween.tween_callback(func():
			_reset_anim()
			start_breathing()
		)
	else:
		# 女王：轻盈上浮
		_anim_offset.y = 20
		var pos_tween = create_tween()
		pos_tween.tween_property(self, "_anim_offset:y", -20.0, 0.4) \
			.set_delay(0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		pos_tween.tween_property(self, "_anim_offset:y", 0.0, 0.3) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		pos_tween.tween_callback(func():
			_reset_anim()
			start_breathing()
		)


## 更新边缘光颜色
func _update_rim_color(color: Color) -> void:
	if material is ShaderMaterial:
		material.set_shader_parameter("rim_color", color)


## 边缘光颜色渐变过渡（不突兀切换）
func _tween_rim_color(target_color: Color) -> void:
	if not (material is ShaderMaterial):
		return
	var current_color: Color = material.get_shader_parameter("rim_color")
	var tween := create_tween()
	tween.tween_method(_apply_rim_color.bind(material), current_color, target_color, 0.4)

func _apply_rim_color(color: Color, mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("rim_color", color)
func _process(delta: float) -> void:
	position = _base_position + _anim_offset
	scale = _anim_scale * _char_scale
	# 永久异火环绕
	if _permanent_fire_active and _fire_orb_nodes.size() > 0:
		_fire_orb_angle += FIRE_ORB_SPEED * delta
		var center = size / 2.0
		for i in range(_fire_orb_nodes.size()):
			var orb_angle = _fire_orb_angle + i * TAU / _fire_orb_nodes.size()
			var orb_pos = center + Vector2(cos(orb_angle), sin(orb_angle)) * FIRE_ORB_RADIUS
			_fire_orb_nodes[i].position = orb_pos - Vector2(FIRE_ORB_SIZE / 2, FIRE_ORB_SIZE / 2)


## 重置所有动画偏移并强制归位
func _reset_anim() -> void:
	_anim_offset = Vector2.ZERO
	_anim_scale = Vector2.ONE
	position = _base_position
	scale = Vector2.ONE * _char_scale


## === 待机呼吸 ===

func start_breathing() -> void:
	if _breathing:
		return
	_breathing = true
	_run_breath_loop()


func _run_breath_loop() -> void:
	if not _breathing:
		return

	# 从零偏移开始
	_anim_offset = Vector2.ZERO
	_anim_scale = Vector2.ONE

	_breath_tween = create_tween()
	_breath_tween.set_loops()

	# 吸气：变高变窄 + 上浮（offset相对_base_position）
	_breath_tween.tween_property(self, "_anim_scale", Vector2(0.97, 1.03), 1.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_breath_tween.parallel().tween_property(self, "_anim_offset:y", -5.0, 1.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# 呼气：恢复
	_breath_tween.tween_property(self, "_anim_scale", Vector2(1.0, 1.0), 1.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_breath_tween.parallel().tween_property(self, "_anim_offset:y", 0.0, 1.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func stop_breathing() -> void:
	_breathing = false
	if _breath_tween and _breath_tween.is_valid():
		_breath_tween.kill()
		_breath_tween = null
	_reset_anim()


## === 攻击动画（ATTACK 牌） ===

func play_attack(target_global_pos: Vector2) -> void:
	if _attacking:
		return
	_attacking = true

	# 停止呼吸，重置偏移
	stop_breathing()

	# 计算冲刺方向
	var my_center := global_position + size / 2.0
	var direction := (target_global_pos - my_center).normalized()
	var dash_offset := direction * 50.0

	# 切换攻击贴图
	texture = attack_texture

	# 生成残影
	_spawn_afterimage()

	var tween := create_tween()

	# 前冲
	tween.tween_property(self, "_anim_offset", dash_offset, 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# 命中停顿 — scale squash
	tween.tween_property(self, "_anim_scale", Vector2(1.05, 0.95), 0.05) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_anim_scale", Vector2(1.0, 1.0), 0.05) \
		.set_ease(Tween.EASE_IN)

	# 后撤
	tween.tween_property(self, "_anim_offset", Vector2.ZERO, 0.25) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# 切回待机
	tween.tween_callback(func():
		texture = idle_texture
		_reset_anim()
		_attacking = false
		start_breathing()
		attack_animation_finished.emit()
	)


## === 水墨晕染（SKILL 牌） ===

var _ink_texture: Texture2D = preload("res://assets/effects/ink_burst.png")

func play_skill_burst(_effect_area: TextureRect) -> void:
	if _attacking:
		return
	stop_breathing()

	# 水墨晕染层（ColorRect + ShaderMaterial，避免 TextureRect 渲染问题）
	var ink_rect := ColorRect.new()
	ink_rect.size = size
	ink_rect.position = position
	ink_rect.z_index = 10
	ink_rect.pivot_offset = size / 2.0
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/ink_display.gdshader")
	mat.set_shader_parameter("ink_texture", _ink_texture)
	ink_rect.material = mat
	get_parent().add_child(ink_rect)
	get_parent().move_child(ink_rect, get_index())

	# 放大 + 旋转 + 渐隐（通过 shader alpha uniform 控制透明度）
	var ink_tween := ink_rect.create_tween()
	ink_tween.set_parallel(true)
	ink_tween.tween_property(ink_rect, "scale", Vector2(1.15, 1.15), 0.7) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	ink_tween.tween_method(func(val): mat.set_shader_parameter("alpha", val), 0.35, 0.0, 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	ink_tween.tween_property(ink_rect, "rotation", deg_to_rad(25), 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	ink_tween.chain().tween_callback(func():
		if is_instance_valid(ink_rect):
			ink_rect.queue_free()
	)

	# 本体上浮 + 闪光
	modulate = Color(1.5, 1.5, 1.8, 1.0)
	var body_tween := create_tween()
	body_tween.tween_property(self, "modulate", Color.WHITE, 0.3)

	var move_tween := create_tween()
	move_tween.tween_property(self, "_anim_offset:y", -10.0, 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "_anim_offset:y", 0.0, 0.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	move_tween.tween_callback(func():
		_reset_anim()
		start_breathing()
	)


## === 能力粒子特效（ABILITY 牌） ===

func play_ability_effect() -> void:
	if _attacking:
		return
	var center := _base_position + _anim_offset + size / 2.0
	var particle_count := randi_range(12, 16)

	for i in range(particle_count):
		var particle := ColorRect.new()
		particle.size = Vector2(randf_range(8.0, 16.0), randf_range(8.0, 16.0))
		particle.position = center - particle.size / 2.0

		# 金色/橙色随机
		var hue := randf_range(0.05, 0.15)
		var saturation := randf_range(0.8, 1.0)
		var value := randf_range(0.9, 1.0)
		particle.color = Color.from_hsv(hue, saturation, value, 0.9)

		# 随机方向和距离
		var angle := randf() * TAU
		var distance := randf_range(30.0, 70.0)
		var target_offset := Vector2(cos(angle), sin(angle)) * distance

		get_parent().add_child(particle)

		var tween := particle.create_tween()
		tween.set_parallel(true)

		tween.tween_property(particle, "position", particle.position + target_offset, randf_range(0.8, 1.2)) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		tween.tween_property(particle, "modulate:a", 0.0, randf_range(1.0, 1.5)) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		tween.tween_property(particle, "size", particle.size * 0.3, randf_range(1.0, 1.5)) \
			.set_ease(Tween.EASE_IN)

		tween.chain().tween_callback(particle.queue_free)


## === 受伤抖动 ===

func show_damage_shake() -> void:
	if _attacking:
		return
	stop_breathing()
	var tween := create_tween()
	tween.tween_property(self, "_anim_offset:x", 12.0, 0.04)
	tween.tween_property(self, "_anim_offset:x", -12.0, 0.04)
	tween.tween_property(self, "_anim_offset:x", 6.0, 0.04)
	tween.tween_property(self, "_anim_offset:x", -6.0, 0.04)
	tween.tween_property(self, "_anim_offset:x", 0.0, 0.04)
	tween.tween_callback(func():
		_reset_anim()
		start_breathing()
	)


## === 攻击残影 ===

func _spawn_afterimage() -> void:
	var ghost := TextureRect.new()
	ghost.texture = texture
	ghost.position = position
	ghost.size = size
	ghost.stretch_mode = stretch_mode
	ghost.expand_mode = expand_mode
	ghost.scale = scale
	ghost.pivot_offset = pivot_offset
	ghost.modulate = Color(1.0, 1.0, 1.0, 0.4)
	ghost.z_index = -1

	get_parent().add_child(ghost)

	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		if is_instance_valid(ghost):
			ghost.queue_free()
	)


## === 工具方法 ===

## 以待机图为基准，将攻击图缩放到相同尺寸
func _normalize_textures() -> void:
	if idle_texture == null or attack_texture == null:
		return
	var idle_img := idle_texture.get_image()
	var attack_img := attack_texture.get_image()
	var target_w := idle_img.get_width()
	var target_h := idle_img.get_height()
	# 攻击图缩放到与待机图相同尺寸
	if attack_img.get_width() != target_w or attack_img.get_height() != target_h:
		attack_img.resize(target_w, target_h, Image.INTERPOLATE_BILINEAR)
		attack_texture = ImageTexture.create_from_image(attack_img)


func update_base_position() -> void:
	_base_position = position


## === 永久异火环绕（青莲地心火·本源） ===

func set_permanent_green_fire(active: bool) -> void:
	if active == _permanent_fire_active:
		return
	_permanent_fire_active = active
	if active:
		_spawn_fire_orbs()
	else:
		_clear_fire_orbs()


func _spawn_fire_orbs() -> void:
	_clear_fire_orbs()
	# 创建1颗绿火环绕角色
	var orb = _create_fire_orb()
	add_child(orb)
	_fire_orb_nodes.append(orb)
	_fire_orb_angle = 0.0


func _clear_fire_orbs() -> void:
	for orb in _fire_orb_nodes:
		if is_instance_valid(orb):
			orb.free()  # free立即释放，终止无限循环tween，避免step已删除节点
	_fire_orb_nodes.clear()


func _create_fire_orb() -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(FIRE_ORB_SIZE, FIRE_ORB_SIZE)
	container.size = Vector2(FIRE_ORB_SIZE, FIRE_ORB_SIZE)

	# 绿色火球主体
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(FIRE_ORB_SIZE, FIRE_ORB_SIZE)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = FIRE_GREEN
	style.corner_radius_top_left = int(FIRE_ORB_SIZE / 2)
	style.corner_radius_top_right = int(FIRE_ORB_SIZE / 2)
	style.corner_radius_bottom_left = int(FIRE_ORB_SIZE / 2)
	style.corner_radius_bottom_right = int(FIRE_ORB_SIZE / 2)
	style.shadow_color = Color(0.2, 0.8, 0.3, 0.6)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 0)
	panel.add_theme_stylebox_override("panel", style)
	panel.tooltip_text = "青莲地心火·本源（永久）\n被动：回合结束对随机敌人3伤\n所有绿火激发伤+4"
	container.add_child(panel)

	# 呼吸脉冲动画
	var tween = container.create_tween()
	tween.set_loops()
	tween.tween_property(container, "scale", Vector2(1.3, 1.3), 0.8) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(container, "scale", Vector2(1.0, 1.0), 0.8) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	return container
