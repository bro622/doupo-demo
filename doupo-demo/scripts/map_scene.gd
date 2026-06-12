## 地图场景控制器
## 参考StS2 NMapScreen: 节点定位 + dot-chain路径 + 滚动 + 旅行状态
extends Control

## 信号
signal node_selected(node_data)
signal back_requested

## 节点类型颜色
const NODE_COLORS: Dictionary = {
	MapData.NodeType.MONSTER:    Color(0.15, 0.15, 0.22, 1.0),  # 深蓝灰 - 战斗
	MapData.NodeType.ELITE:      Color(0.25, 0.10, 0.10, 1.0),  # 暗红 - 精英
	MapData.NodeType.REST:       Color(0.10, 0.20, 0.12, 1.0),  # 深绿 - 修炼驿站
	MapData.NodeType.SHOP:       Color(0.22, 0.18, 0.08, 1.0),  # 暗金 - 商店
	MapData.NodeType.EVENT:      Color(0.15, 0.10, 0.25, 1.0),  # 紫色 - 奇遇
	MapData.NodeType.TREASURE:   Color(0.20, 0.15, 0.05, 1.0),  # 深棕 - 宝箱
	MapData.NodeType.BOSS:       Color(0.30, 0.08, 0.08, 1.0),  # 深红 - BOSS
	MapData.NodeType.UNKNOWN:    Color(0.12, 0.12, 0.18, 1.0),  # 原深蓝灰 - 未知
	MapData.NodeType.FLOOR_ZERO: Color(0.08, 0.18, 0.10, 1.0),  # 墨绿 - 菩提古树
}

## 守灵节点颜色（按场景区分）
const ANCIENT_COLORS: Dictionary = {
	1: Color(0.08, 0.18, 0.10, 1.0),  # 墨绿 - 菩提古树（场景一）
	2: Color(0.18, 0.08, 0.08, 1.0),  # 暗红 - 黑角域守灵
	3: Color(0.08, 0.12, 0.18, 1.0),  # 青蓝 - 迦南学院守灵
	4: Color(0.22, 0.16, 0.05, 1.0),  # 金橙 - 中州守灵
}

## 节点容器 / 路径dot / 脉冲动画数据
var node_buttons: Array[Control] = []
var path_dots: Array[Node] = []
## 每个节点的脉冲动画数据: { container, category, is_travelable, elapsed }
var _node_pulse_data: Array[Dictionary] = []
## 每个节点的轮廓原始颜色（用于 unhover 恢复）: container -> Color
var _node_outline_colors: Dictionary = {}
## 每个节点的活跃 tween（用于 kill 旧 tween 防抖动）: container -> Tween
var _node_tweens: Dictionary = {}

## 守灵图标路径映射（按场景）
const ANCIENT_ICON_BY_SCENE: Dictionary = {
	1: "res://assets/ui/map-nodes/mapnode_floor_zero.png",
	2: "res://assets/ui/map-nodes/mapnode_ancient_scene2.png",
	3: "res://assets/ui/map-nodes/mapnode_ancient_scene3.png",
	4: "res://assets/ui/map-nodes/mapnode_ancient_scene4.png",
}

## Boss 图标路径映射（按场景：1云山/2韩枫/3陨落心炎/4魂天帝）
const BOSS_ICON_BY_SCENE: Dictionary = {
	1: "res://assets/ui/map-nodes/mapnode_boss_scene1.png",  # 云山
	2: "res://assets/ui/map-nodes/mapnode_boss_scene2.png",  # 韩枫
	3: "res://assets/ui/map-nodes/mapnode_boss_scene3.png",  # 陨落心炎
	4: "res://assets/ui/map-nodes/mapnode_boss_scene4.png",  # 魂天帝
}

## Boss 轮廓路径映射（按场景）
const BOSS_OUTLINE_BY_SCENE: Dictionary = {
	1: "res://assets/ui/map-nodes/mapnode_boss_scene1_outline.png",
	2: "res://assets/ui/map-nodes/mapnode_boss_scene2_outline.png",
	3: "res://assets/ui/map-nodes/mapnode_boss_scene3_outline.png",
	4: "res://assets/ui/map-nodes/mapnode_boss_scene4_outline.png",
}

## 守灵/菩提古树轮廓路径映射（按场景）
const ANCIENT_OUTLINE_BY_SCENE: Dictionary = {
	1: "res://assets/ui/map-nodes/mapnode_floor_zero_outline.png",
	2: "res://assets/ui/map-nodes/mapnode_ancient_scene2_outline.png",
	3: "res://assets/ui/map-nodes/mapnode_ancient_scene3_outline.png",
	4: "res://assets/ui/map-nodes/mapnode_ancient_scene4_outline.png",
}

## 参考StS2 _tickDist = 22px
const DOT_SPACING: float = 25.0

## 滚动参数(对齐StS2 NMapScreen)
var scroll_y: float = 0.0
var target_scroll_y: float = 0.0
const SCROLL_SPEED: float = 15.0
const SPRING_SPEED: float = 12.0
var scroll_min: float = 0.0
var scroll_max: float = 1725.0

## 拖拽状态
var is_dragging: bool = false
var drag_start_y: float = 0.0
var drag_start_scroll: float = 0.0

## 画笔激活时暂停拖拽
var _drawing_active: bool = false

## 输入开关（卡组等覆盖层打开时禁用，防止穿透）
var input_enabled: bool = true

## UI引用
@onready var map_container: Control = $MapContainer
@onready var back_button: Button = $BackButton
@onready var drawing_layer: Control = $MapContainer/DrawingLayer
@onready var toolbar: HBoxContainer = $Toolbar


func _ready() -> void:
	back_button.visible = false
	back_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toolbar.tool_changed.connect(_on_tool_changed)
	toolbar.clear_requested.connect(drawing_layer.clear_all)
	drawing_layer.is_drawing_changed.connect(_on_drawing_changed)


func _on_drawing_changed(active: bool) -> void:
	_drawing_active = active
	if active:
		is_dragging = false


func _on_back_pressed() -> void:
	AudioManager.ui("ui_click.wav")
	back_requested.emit()


func setup(overlay_mode: bool = false) -> void:
	_draw_map(overlay_mode)
	# 计算并动态调整滚动边界与容器高度
	_calculate_scroll_bounds()
	# 恢复上次滚动位置，否则滚动到当前节点位置
	if RunManager.saved_map_scroll_y >= 0:
		scroll_y = RunManager.saved_map_scroll_y
	elif RunManager.current_node_id >= 0:
		var current_node = RunManager.get_node_by_id(RunManager.current_node_id)
		if current_node:
			var vp_h = get_viewport_rect().size.y
			scroll_y = current_node.position.y - vp_h / 2.0
			scroll_y = clampf(scroll_y, scroll_min, scroll_max)
		else:
			scroll_y = scroll_max
	else:
		# 新地图：滚动到底部（起点/守灵位置）
		scroll_y = scroll_max
	target_scroll_y = scroll_y
	map_container.position.y = -scroll_y
	# 恢复绘画标注
	drawing_layer.restore_data(RunManager.drawing_strokes)
	# 返回按钮：仅覆盖层模式显示
	back_button.visible = overlay_mode
	if overlay_mode:
		back_button.text = "✕ 返回"
		back_button.mouse_filter = Control.MOUSE_FILTER_STOP
		if not back_button.pressed.is_connected(_on_back_pressed):
			back_button.pressed.connect(_on_back_pressed)
	else:
		back_button.mouse_filter = Control.MOUSE_FILTER_IGNORE


## 动态计算容器尺寸和滚动极值
func _calculate_scroll_bounds() -> void:
	var viewport_h = get_viewport_rect().size.y
	var min_y: float = 99999.0
	var max_y: float = -99999.0
	for node in RunManager.map_nodes:
		min_y = minf(min_y, node.position.y)
		max_y = maxf(max_y, node.position.y)
	# 撑开容器高度，确保底部节点不被裁切
	map_container.custom_minimum_size.y = max_y + 200.0
	map_container.size.y = max_y + 200.0
	# 顶部滚动极值: Boss留边距
	scroll_min = min_y - 100.0
	if scroll_min < 0:
		scroll_min = 0.0
	# 底部滚动极值: Start出现在屏幕底部
	var bottom_margin = 120.0
	scroll_max = max_y - viewport_h + bottom_margin+25


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	# 平滑滚动(对齐StS2: lerp at delta*15)
	scroll_y = lerpf(scroll_y, target_scroll_y, delta * SCROLL_SPEED)
	# 弹簧回弹(对齐StS2: spring back at delta*12)
	if target_scroll_y < scroll_min:
		target_scroll_y = lerpf(target_scroll_y, scroll_min, delta * SPRING_SPEED)
	elif target_scroll_y > scroll_max:
		target_scroll_y = lerpf(target_scroll_y, scroll_max, delta * SPRING_SPEED)
	map_container.position.y = -scroll_y
	# 脉冲动画（参考 STS2 NNormalMapPoint._Process，作用于 container 自身）
	for data in _node_pulse_data:
		if not data.is_travelable:
			continue
		var behavior = MapData.NODE_BEHAVIOR.get(data.category, {})
		var pulse_amt = behavior.get("pulse_amt", 0.0)
		if pulse_amt <= 0.0:
			continue
		data.elapsed += delta * 4.0  # pulseSpeed = 4
		var pulse_base = behavior.get("pulse_base", 1.0)
		var s = sin(data.elapsed) * pulse_amt + pulse_base
		if is_instance_valid(data.container):
			data.container.scale = Vector2.ONE * s


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not input_enabled:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_scroll_y -= 80.0
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_scroll_y += 80.0
		elif event.button_index == MOUSE_BUTTON_LEFT:
			# 画笔激活时左键交给 drawing_layer 处理
			if _drawing_active:
				return
			# 左侧 20px 边距：忽略（Android 返回手势区域）
			if event.position.x < 20.0:
				return
			if event.pressed:
				is_dragging = true
				drag_start_y = event.position.y
				drag_start_scroll = target_scroll_y
			else:
				is_dragging = false
	elif event is InputEventMouseMotion and is_dragging and not _drawing_active:
		var delta_y = drag_start_y - event.position.y
		target_scroll_y = drag_start_scroll + delta_y


## 绘制地图（overlay_mode=true时禁用节点点击，仅做信息展示）
func _draw_map(overlay_mode: bool = false) -> void:
	# 清除旧元素
	for btn in node_buttons:
		btn.queue_free()
	node_buttons.clear()
	for dot in path_dots:
		dot.queue_free()
	path_dots.clear()
	_node_pulse_data.clear()
	_node_outline_colors.clear()
	_node_tweens.clear()

	var travelable = RunManager.get_travelable_nodes()

	# 先画路径dot(在按钮下面)
	_create_all_paths(travelable)

	# 再创建节点（不同类不同大小，都以 node.position 为中心对齐）
	for node in RunManager.map_nodes:
		var cat = node.get_category()
		var node_size: Vector2
		match cat:
			"boss":
				node_size = Vector2(160, 130)
			"ancient":
				node_size = Vector2(140, 120)
			_:
				if node.node_type == MapData.NodeType.FLOOR_ZERO:
					node_size = Vector2(140, 120)  # 菩提古树同守灵大小
				else:
					node_size = Vector2(72, 56)  # 普通节点
		var half_size = node_size / 2.0

		var container = Control.new()
		container.size = node_size
		container.position = node.position - half_size
		# Boss 节点在地图最上方，下移避免超出
		if cat == "boss":
			container.position.y += 30
		container.pivot_offset = half_size

		var has_icon = node.has_icon()
		var icon_rect: TextureRect = null
		var outline_rect: TextureRect = null

		if has_icon:
			var icon_path = node.get_icon_path()
			if node.node_type == MapData.NodeType.ANCIENT:
				icon_path = ANCIENT_ICON_BY_SCENE.get(RunManager.current_scene, icon_path)
			elif node.node_type == MapData.NodeType.BOSS:
				icon_path = BOSS_ICON_BY_SCENE.get(RunManager.current_scene, icon_path)

			# outline（所有节点都显示，Boss/Ancient 按场景区分）
			outline_rect = TextureRect.new()
			var outline_path = node.get_outline_path()
			if node.node_type == MapData.NodeType.BOSS:
				outline_path = BOSS_OUTLINE_BY_SCENE.get(RunManager.current_scene, outline_path)
			elif node.node_type == MapData.NodeType.ANCIENT or node.node_type == MapData.NodeType.FLOOR_ZERO:
				outline_path = ANCIENT_OUTLINE_BY_SCENE.get(RunManager.current_scene, outline_path)
			if outline_path != "" and ResourceLoader.exists(outline_path):
				outline_rect.texture = load(outline_path)
			outline_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			outline_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			outline_rect.position = Vector2.ZERO
			outline_rect.size = node_size
			outline_rect.custom_minimum_size = Vector2.ZERO
			outline_rect.pivot_offset = node_size / 2.0
			outline_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var bg_color = NODE_COLORS.get(node.node_type, Color(0.12, 0.12, 0.18, 1.0))
			if node.node_type == MapData.NodeType.ANCIENT:
				bg_color = ANCIENT_COLORS.get(RunManager.current_scene, bg_color)
			outline_rect.modulate = bg_color
			_node_outline_colors[container] = bg_color

			var icon_display_size: Vector2
			match cat:
				"boss":
					icon_display_size = Vector2(140, 115)
				"ancient":
					icon_display_size = Vector2(120, 100)
				_:
					if node.node_type == MapData.NodeType.FLOOR_ZERO:
						icon_display_size = Vector2(120, 100)
					else:
						icon_display_size = Vector2(64, 50)

			var icon_offset = (node_size - icon_display_size) / 2.0

			icon_rect = TextureRect.new()
			if icon_path != "" and ResourceLoader.exists(icon_path):
				icon_rect.texture = load(icon_path)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.position = icon_offset
			icon_rect.size = icon_display_size
			icon_rect.custom_minimum_size = Vector2.ZERO
			icon_rect.pivot_offset = icon_display_size / 2.0
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

			if outline_rect:
				container.add_child(outline_rect)
			container.add_child(icon_rect)

			_node_pulse_data.append({
				"container": container,
				"category": cat,
				"is_travelable": node.id in travelable,
				"elapsed": randf() * TAU,
			})
		else:
			# emoji 回退模式
			var bg = PanelContainer.new()
			var style = StyleBoxFlat.new()
			if node.node_type == MapData.NodeType.ANCIENT:
				style.bg_color = ANCIENT_COLORS.get(RunManager.current_scene, Color(0.18, 0.08, 0.08, 1.0))
			else:
				style.bg_color = NODE_COLORS.get(node.node_type, Color(0.12, 0.12, 0.18, 1.0))
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_left = 6
			style.corner_radius_bottom_right = 6
			style.content_margin_left = 4
			style.content_margin_right = 4
			style.content_margin_top = 2
			style.content_margin_bottom = 2
			bg.add_theme_stylebox_override("panel", style)
			bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bg.offset_left = 0
			bg.offset_top = 0
			bg.offset_right = node_size.x
			bg.offset_bottom = node_size.y

			var label = Label.new()
			label.text = node.get_icon() + "\n" + node.get_name()
			label.add_theme_font_size_override("font_size", 13)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.offset_left = 0
			label.offset_top = 0
			label.offset_right = node_size.x
			label.offset_bottom = node_size.y

			bg.add_child(label)
			container.add_child(bg)

			_node_pulse_data.append({
				"container": container,
				"category": cat,
				"is_travelable": false,
				"elapsed": 0.0,
			})

		# 状态调制（亮度区分，不透明）
		if node.id in RunManager.visited_nodes:
			container.modulate = Color(0.4, 0.4, 0.4, 1.0)
		elif node.id not in travelable:
			container.modulate = Color(0.5, 0.5, 0.5, 1.0)

		# 可点击节点（覆盖层模式下禁用点击，仅做信息展示）
		if not overlay_mode and node.id in travelable:
			container.mouse_filter = Control.MOUSE_FILTER_STOP
			var node_id = node.id
			container.gui_input.connect(_on_node_gui_input.bind(node_id))
			var base_modulate = container.modulate
			container.mouse_entered.connect(_on_node_hover.bind(
				container, icon_rect, outline_rect, has_icon, cat, base_modulate, true))
			container.mouse_exited.connect(_on_node_hover.bind(
				container, icon_rect, outline_rect, has_icon, cat, base_modulate, false))
		else:
			container.mouse_filter = Control.MOUSE_FILTER_IGNORE

		map_container.add_child(container)
		node_buttons.append(container)


## 创建所有路径
func _create_all_paths(travelable: Array[int]) -> void:
	# 计算玩家当前所在层级(已访问节点的最大layer)
	var current_layer = -1
	for node in RunManager.map_nodes:
		if node.id in RunManager.visited_nodes and node.layer > current_layer:
			current_layer = node.layer

	for node in RunManager.map_nodes:
		for child_id in node.children:
			var child = _find_node_by_id(child_id)
			if child != null:
				_create_path(node.position, child.position, node.id, child_id, travelable, current_layer)


## 创建单条路径
func _create_path(from: Vector2, to: Vector2, parent_id: int, child_id: int, travelable: Array[int], current_layer: int) -> void:
	var both_visited = parent_id in RunManager.visited_nodes and child_id in RunManager.visited_nodes
	var parent_node = _find_node_by_id(parent_id)
	if parent_node == null:
		return

	if both_visited:
		# 实际走过的边 → 深棕墨线
		var line = Line2D.new()
		line.points = PackedVector2Array([from, to])
		line.width = 12.0
		line.default_color = Color(0.30, 0.20, 0.08, 1.0)
		line.antialiased = true
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		map_container.add_child(line)
		path_dots.append(line)
	else:
		var direction = (to - from).normalized()
		var angle = direction.angle()
		var distance = from.distance_to(to)
		var dot_count = int(distance / DOT_SPACING) + 1

		# 路径颜色判断
		var color: Color
		if parent_id in RunManager.visited_nodes and child_id in travelable:
			# 可走 - 金色
			color = Color(0.85, 0.75, 0.20, 1.0)
		elif parent_id not in RunManager.visited_nodes and parent_node.layer <= current_layer:
			# 父节点在玩家当前位置之前或同层,且未被访问 → 永久不可达 - 暗灰
			color = Color(0.55, 0.45, 0.30, 0.5)
		elif parent_id in RunManager.visited_nodes:
			# 已走过但子节点不可走 - 暗灰
			color = Color(0.55, 0.45, 0.30, 0.5)
		else:
			# 未探索(在玩家位置之后) - 浅蓝灰
			color = Color(0.50, 0.42, 0.28, 0.6)

		for i in range(1, dot_count):
			var t = float(i) / dot_count
			var pos = from.lerp(to, t)
			pos += Vector2(RNGManager.map_rng.randf_range(-3.0, 3.0), RNGManager.map_rng.randf_range(-3.0, 3.0))
			var dot = _create_dot(pos, angle, color)
			map_container.add_child(dot)
			path_dots.append(dot)


## 创建单个路径dot(参考StS2 map_dot.tscn)
func _create_dot(pos: Vector2, angle: float, color: Color) -> Control:
	var dot = ColorRect.new()
	dot.custom_minimum_size = Vector2(8, 8)
	dot.size = Vector2(8, 8)
	dot.position = pos - Vector2(4, 4)
	dot.color = color
	dot.rotation = angle + RNGManager.map_rng.randf_range(-0.1, 0.1)  # 角度抖动
	dot.pivot_offset = Vector2(4, 4)
	return dot


## 悬停交互（参考 STS2 NNormalMapPoint.AnimHover/AnimUnhover）
func _on_node_hover(btn: Control, icon_rect: TextureRect, outline_rect: TextureRect,
		has_icon: bool, cat: String, base_modulate: Color, entering: bool) -> void:
	# kill 旧 tween 防止快速进出时动画抖动
	if _node_tweens.has(btn) and _node_tweens[btn] != null:
		_node_tweens[btn].kill()
	var tween = btn.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_node_tweens[btn] = tween
	if entering:
		AudioManager.ui("map_hover.mp3")
		if has_icon and is_instance_valid(icon_rect):
			# 图标模式：缩放 container + outline 亮度过渡
			var behavior = MapData.NODE_BEHAVIOR.get(cat, MapData.NODE_BEHAVIOR["normal"])
			var hover_scale = behavior.get("hover", 1.45)
			tween.tween_property(btn, "scale", Vector2.ONE * hover_scale, 0.05)
			if is_instance_valid(outline_rect):
				tween.parallel().tween_property(outline_rect, "modulate", Color(1, 1, 1, 0.75), 0.05)
		else:
			# emoji 回退：仅亮度变化
			tween.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.15)
			var bright = base_modulate * Color(1.4, 1.4, 1.4, 1.0)
			tween.parallel().tween_property(btn, "modulate", bright, 0.15)
	else:
		if has_icon and is_instance_valid(icon_rect):
			tween.tween_property(btn, "scale", Vector2.ONE, 0.5)
			if is_instance_valid(outline_rect):
				var bg_color = _node_outline_colors.get(btn, Color(0.12, 0.12, 0.18, 1.0))
				tween.parallel().tween_property(outline_rect, "modulate", bg_color, 0.5)
		else:
			tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)
			tween.parallel().tween_property(btn, "modulate", base_modulate, 0.15)


## 节点被点击
func _on_node_gui_input(event: InputEvent, node_id: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var travelable = RunManager.get_travelable_nodes()
	if node_id not in travelable:
		return
	RunManager.visit_node(node_id)
	AudioManager.ui("ui_click.wav")
	# 保存滚动位置,退出节点后恢复
	RunManager.saved_map_scroll_y = scroll_y
	# 保存绘画标注
	RunManager.drawing_strokes = drawing_layer.get_save_data()
	var node = _find_node_by_id(node_id)
	if node != null:
		node_selected.emit(node)


## 按ID查找节点
func _find_node_by_id(node_id: int) -> MapData.MapNode:
	for node in RunManager.map_nodes:
		if node.id == node_id:
			return node
	return null


## 绘画工具切换
func _on_tool_changed(tool: int) -> void:
	drawing_layer.current_tool = tool
