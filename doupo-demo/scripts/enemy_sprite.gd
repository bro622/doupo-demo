## 敌人精灵动画控制器
## 管理待机呼吸、攻击冲刺、受伤抖动、死亡渐隐
## _base_position 是固定锚点，所有动画通过 _anim_offset 偏移
## _process() 每帧计算 position = _base_position + _anim_offset
class_name EnemySprite
extends TextureRect

## 纹理资源
var idle_texture: Texture2D

## 呼吸动画状态
var _breathing: bool = false
var _breath_tween: Tween = null

## 攻击动画状态
var _attacking: bool = false
## 死亡动画状态（防止死亡期间播放其他动画）
var _dying: bool = false

## 固定锚点（场景初始位置，永不修改）
var _base_position: Vector2

## 动画偏移量（tween修改此值，_process应用到position）
var _anim_offset: Vector2 = Vector2.ZERO
## 动画缩放量（tween修改此值，_process应用到scale）
var _anim_scale: Vector2 = Vector2.ONE

## 信号
signal attack_animation_finished
signal death_animation_finished


func _ready() -> void:
	_base_position = position
	# pivot 设在中心底部（脚部），缩放时脚不离地
	pivot_offset = Vector2(size.x / 2.0, size.y)


## 每帧：position = base + offset, scale = anim_scale
func _process(_delta: float) -> void:
	position = _base_position + _anim_offset
	scale = _anim_scale


## 重置所有动画偏移并强制归位
func _reset_anim() -> void:
	_anim_offset = Vector2.ZERO
	_anim_scale = Vector2.ONE
	position = _base_position
	scale = Vector2.ONE


## 设置敌人数据并加载纹理
func setup(enemy_data) -> void:
	var tex_path := EnemyDatabase.get_texture_path(enemy_data.char_name)
	if tex_path != "" and ResourceLoader.exists(tex_path):
		idle_texture = load(tex_path)
		_auto_fit_size()
		texture = idle_texture
		stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		modulate = Color.WHITE
	else:
		# 无纹理时显示为红色色块（回退）
		idle_texture = null
		texture = null
		_create_fallback_body()

	_base_position = position
	pivot_offset = Vector2(size.x / 2.0, size.y)
	start_breathing()


## 根据图片宽高比自动调整显示尺寸
## 人形（竖图）以高度为基准，兽形（横图）以宽度为基准
## 所有敌人共享同一个最大区域，按比例缩放
func _auto_fit_size() -> void:
	if idle_texture == null:
		return
	var tex_w := float(idle_texture.get_width())
	var tex_h := float(idle_texture.get_height())
	if tex_w <= 0 or tex_h <= 0:
		return

	# Body 节点的可用区域 (offset_left=10, offset_top=0, right=170, bottom=140)
	var max_w := 160.0
	var max_h := 140.0
	var aspect := tex_w / tex_h

	var fit_w: float
	var fit_h: float

	if aspect >= max_w / max_h:
		# 横图（兽形）：以宽度为基准
		fit_w = max_w
		fit_h = max_w / aspect
	else:
		# 竖图（人形）：以高度为基准
		fit_h = max_h
		fit_w = max_h * aspect

	# 居中放置，+10 是 Body 的 offset_left
	var offset_x := (max_w - fit_w) / 2.0 + 10.0
	var offset_y: float
	if aspect >= max_w / max_h:
		# 横图（兽形）：底部对齐，让兽形敌人"站"在地面上
		offset_y = max_h - fit_h
	else:
		# 竖图（人形）：垂直居中
		offset_y = (max_h - fit_h) / 2.0
	position = Vector2(offset_x, offset_y)
	size = Vector2(fit_w, fit_h)


## 无纹理时创建回退色块
func _create_fallback_body() -> void:
	for child in get_children():
		if child is ColorRect:
			return
	var fallback := ColorRect.new()
	fallback.color = Color(0.6, 0.2, 0.2, 1.0)
	fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fallback)


## === 待机呼吸 ===

func start_breathing() -> void:
	if _breathing:
		return
	_breathing = true
	_run_breath_loop()


func _run_breath_loop() -> void:
	if not _breathing:
		return

	_anim_offset = Vector2.ZERO
	_anim_scale = Vector2.ONE

	_breath_tween = create_tween()
	_breath_tween.set_loops()

	# 吸气：变高变窄 + 上浮
	_breath_tween.tween_property(self, "_anim_scale", Vector2(0.97, 1.03), 1.25) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_breath_tween.parallel().tween_property(self, "_anim_offset:y", -5.0, 1.25) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# 呼气：恢复
	_breath_tween.tween_property(self, "_anim_scale", Vector2(1.0, 1.0), 1.25) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_breath_tween.parallel().tween_property(self, "_anim_offset:y", 0.0, 1.25) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func stop_breathing() -> void:
	_breathing = false
	if _breath_tween and _breath_tween.is_valid():
		_breath_tween.kill()
		_breath_tween = null
	_reset_anim()


## === 攻击动画 ===

func play_attack(target_global_pos: Vector2) -> void:
	if _attacking or _dying:
		return
	_attacking = true

	stop_breathing()

	var my_center := global_position + size / 2.0
	var direction := (target_global_pos - my_center).normalized()
	var dash_offset := direction * 40.0

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
	tween.tween_property(self, "_anim_offset", Vector2.ZERO, 0.2) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# 完成：恢复呼吸
	tween.tween_callback(func():
		_reset_anim()
		_attacking = false
		start_breathing()
		attack_animation_finished.emit()
	)


## === 受伤抖动 ===

func show_damage_shake() -> void:
	if _attacking or _dying:
		return
	stop_breathing()
	var tween := create_tween()
	tween.tween_property(self, "_anim_offset:x", 10.0, 0.04)
	tween.tween_property(self, "_anim_offset:x", -10.0, 0.04)
	tween.tween_property(self, "_anim_offset:x", 6.0, 0.04)
	tween.tween_property(self, "_anim_offset:x", -6.0, 0.04)
	tween.tween_property(self, "_anim_offset:x", 0.0, 0.04)
	tween.tween_callback(func():
		_reset_anim()
		start_breathing()
	)


## === 死亡动画 ===

func play_death() -> void:
	_attacking = false
	_dying = true
	stop_breathing()

	var tween := create_tween()
	# 渐暗
	tween.tween_property(self, "modulate", Color(0.3, 0.3, 0.3, 0.5), 0.5) \
		.set_ease(Tween.EASE_IN)
	# 渐隐 + 缩小
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.3) \
		.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "_anim_scale", Vector2(0.8, 0.8), 0.3) \
		.set_ease(Tween.EASE_IN)
	# 清理（由父节点EnemyNode处理释放）
	tween.chain().tween_callback(func():
		if is_instance_valid(self):
			death_animation_finished.emit()
	)


## === 工具方法 ===

func update_base_position() -> void:
	_base_position = position
