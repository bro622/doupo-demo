## 异火槽显示栏（圆弧布局）
## 在角色上方形成圆弧排列，类似故障机器人的充能球
class_name HeavenlyFlameBar
extends Control

## 异火颜色定义（fallback，纹理加载失败时使用）
const FIRE_COLORS = {
	0: Color(0.2, 0.8, 0.3),    # GREEN - 青莲地心火（翠绿）
	1: Color(0.95, 0.95, 1.0),   # WHITE - 陨落心炎（纯白）
	2: Color(0.5, 0.7, 0.95),    # BLUE - 骨灵冷火（冰蓝）
	3: Color(0.6, 0.2, 0.8),     # PURPLE - 三千焱炎火（紫黑）
}

## 呼吸动画参数
const BREATH_SCALE_MIN = 1.0
const BREATH_SCALE_MAX = 1.18
const BREATH_ALPHA_MIN = 0.82
const BREATH_ALPHA_MAX = 1.0
const BREATH_DURATION_BASE = 1.6  # 基础周期（秒）
const BREATH_DURATION_VARY = 0.4  # 每朵火随机偏移量

## 异火纹理
var fire_textures: Dictionary = {}

const EMPTY_COLOR = Color(0.3, 0.3, 0.3, 0.6)
const SLOT_SIZE = 26.0

## 圆弧参数
const ARC_RADIUS = 85.0        # 圆弧半径
const ARC_START_ANGLE = 200.0  # 起始角度（度，左侧）
const ARC_END_ANGLE = 340.0    # 结束角度（度，右侧）
const CENTER_OFFSET = Vector2(80, 10)  # 圆弧中心偏移（相对于节点）


func _ready() -> void:
	# 禁用鼠标事件穿透
	mouse_filter = Control.MOUSE_FILTER_STOP
	# 加载异火纹理
	fire_textures = {
		0: load("res://assets/ui/fire-icons/green.png"),   # 青莲地心火
		1: load("res://assets/ui/fire-icons/white.png"),   # 陨落心炎
		2: load("res://assets/ui/fire-icons/blue.png"),    # 骨灵冷火
		3: load("res://assets/ui/fire-icons/purple.png"),  # 三千焱炎火
	}


## 更新异火槽显示
func update_display(fire_slots: Array, max_slots: int = 3) -> void:
	# 清除旧节点（先kill无限循环tween，再释放节点）
	var children = get_children()
	for child in children:
		_kill_breathing_tweens(child)
		child.free()

	# 计算圆弧参数
	var center = CENTER_OFFSET
	var start_rad = deg_to_rad(ARC_START_ANGLE)
	var end_rad = deg_to_rad(ARC_END_ANGLE)

	# 槽位从右向左填充：第一个异火在最右，新火向左扩展
	# fire_slots[0] = 最新（左），fire_slots[last] = 最早/第一个（右）
	for i in range(max_slots):
		var angle: float
		if max_slots == 1:
			angle = (start_rad + end_rad) / 2.0
		else:
			# slot 0 = 最左，slot max_slots-1 = 最右
			angle = start_rad + (end_rad - start_rad) * i / (max_slots - 1)

		var pos = center + Vector2(cos(angle), sin(angle)) * ARC_RADIUS

		# slot i 对应 fire_slots[i - (max_slots - size)]
		# 第一个异火（index size-1）固定在最右槽（slot max_slots-1）
		var fire_index = i - (max_slots - fire_slots.size())
		if fire_index >= 0 and fire_index < fire_slots.size():
			var orb = _create_fire_orb(fire_slots[fire_index])
			orb.position = pos - Vector2(SLOT_SIZE / 2, SLOT_SIZE / 2)
			add_child(orb)
			_apply_breathing(orb, fire_index)
		else:
			var empty = _create_empty_slot()
			empty.position = pos - Vector2(SLOT_SIZE / 2, SLOT_SIZE / 2)
			add_child(empty)

	# 永久异火：由 player_sprite 环绕动画处理，此处不显示


## kill 子节点上存储的呼吸 tween（避免无限循环 step 已释放节点）
func _kill_breathing_tweens(node: Node) -> void:
	if node.has_meta("breath_tween"):
		var tw = node.get_meta("breath_tween")
		if tw and tw.is_valid():
			tw.kill()
	if node.has_meta("breath_tween_alpha"):
		var tw = node.get_meta("breath_tween_alpha")
		if tw and tw.is_valid():
			tw.kill()


## 创建异火球体
func _create_fire_orb(fire_type) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	container.size = Vector2(SLOT_SIZE, SLOT_SIZE)

	var tex = fire_textures.get(fire_type)
	if tex:
		var tex_rect = TextureRect.new()
		tex_rect.texture = tex
		tex_rect.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		tex_rect.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		container.add_child(tex_rect)
	else:
		# fallback: 纯色方块
		var style = StyleBoxFlat.new()
		style.bg_color = FIRE_COLORS.get(fire_type, Color.WHITE)
		style.corner_radius_top_left = 13
		style.corner_radius_top_right = 13
		style.corner_radius_bottom_left = 13
		style.corner_radius_bottom_right = 13
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		panel.add_theme_stylebox_override("panel", style)
		container.add_child(panel)

	# tooltip
	match fire_type:
		0: container.tooltip_text = "青莲地心火\n被动：对随机敌人造成3伤害\n激发：8伤害+易伤"
		1: container.tooltip_text = "陨落心炎\n被动：获得2护盾\n激发：+1能量+抽牌"
		2: container.tooltip_text = "骨灵冷火\n被动：随机敌人虚弱\n激发：8护盾+全体虚弱"
		3: container.tooltip_text = "三千焱炎火\n被动：恢复1HP\n激发：+2力量"

	return container


## 呼吸感缩放 + 透明度脉冲
func _apply_breathing(orb: Control, index: int) -> void:
	# 用 index 做相位偏移，让每朵火呼吸节奏错开
	var duration = BREATH_DURATION_BASE + fmod(index * 0.37, BREATH_DURATION_VARY)
	var delay = fmod(index * 0.5, duration)

	# 找到纹理子节点
	var tex_node: Control = null
	for child in orb.get_children():
		if child is TextureRect or child is PanelContainer:
			tex_node = child
			break
	if tex_node == null:
		return

	# 设置缩放中心
	tex_node.pivot_offset = Vector2(SLOT_SIZE / 2, SLOT_SIZE / 2)

	var tween = create_tween()
	tween.set_loops()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)

	# 缩放呼吸
	tween.tween_property(tex_node, "scale", Vector2(BREATH_SCALE_MAX, BREATH_SCALE_MAX), duration * 0.5).set_delay(delay).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_node, "scale", Vector2(BREATH_SCALE_MIN, BREATH_SCALE_MIN), duration * 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# 透明度呼吸（独立 tween，周期略不同步）
	var tween_alpha = create_tween()
	tween_alpha.set_loops()
	tween_alpha.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	var alpha_duration = duration * 1.3
	tween_alpha.tween_property(tex_node, "modulate:a", BREATH_ALPHA_MIN, alpha_duration * 0.5).set_delay(delay + 0.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween_alpha.tween_property(tex_node, "modulate:a", BREATH_ALPHA_MAX, alpha_duration * 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# 存储 tween 引用，释放前需 kill
	orb.set_meta("breath_tween", tween)
	orb.set_meta("breath_tween_alpha", tween_alpha)


## 创建空槽位
func _create_empty_slot() -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	container.size = Vector2(SLOT_SIZE, SLOT_SIZE)

	var style = StyleBoxFlat.new()
	style.bg_color = EMPTY_COLOR
	style.corner_radius_top_left = 13
	style.corner_radius_top_right = 13
	style.corner_radius_bottom_left = 13
	style.corner_radius_bottom_right = 13
	style.border_color = Color(0.4, 0.4, 0.4, 0.4)
	style.set_border_width_all(2)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	panel.add_theme_stylebox_override("panel", style)
	panel.tooltip_text = "空槽位"

	container.add_child(panel)
	return container
