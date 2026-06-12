## 地图绘画层
## 在地图上右键画线进行路线规划，笔画跟随地图滚动
## 触屏：工具激活时单指触摸绘制
extends Control

enum Tool { NONE, PEN, ERASER }

signal is_drawing_changed(value: bool)

var current_tool: Tool = Tool.NONE
var is_drawing: bool = false:
	set(value):
		if is_drawing != value:
			is_drawing = value
			is_drawing_changed.emit(is_drawing)
var current_line: Line2D = null
var last_point: Vector2 = Vector2.ZERO

const MIN_DISTANCE: float = 10.0
const STROKE_WIDTH: float = 4.0
const STROKE_COLOR: Color = Color.WHITE
const ERASE_RADIUS: float = 20.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1


func _input(event: InputEvent) -> void:
	if current_tool == Tool.NONE:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		var local_pos = get_global_transform().affine_inverse() * event.global_position
		if event.pressed:
			if current_tool == Tool.PEN:
				_start_stroke(local_pos)
			elif current_tool == Tool.ERASER:
				_erase_at(local_pos)
		else:
			_end_stroke()

	elif event is InputEventMouseMotion:
		if is_drawing:
			var local_pos = get_global_transform().affine_inverse() * event.global_position
			if current_tool == Tool.PEN:
				_add_point(local_pos)
			elif current_tool == Tool.ERASER:
				_erase_at(local_pos)

	# 触屏画笔（仅 index=0 即第一根手指）
	elif event is InputEventScreenTouch and event.index == 0:
		get_viewport().set_input_as_handled()
		var local_pos = get_global_transform().affine_inverse() * event.position
		if event.pressed:
			if current_tool == Tool.PEN:
				_start_stroke(local_pos)
			elif current_tool == Tool.ERASER:
				_erase_at(local_pos)
		else:
			_end_stroke()

	elif event is InputEventScreenDrag and event.index == 0 and is_drawing:
		get_viewport().set_input_as_handled()
		var local_pos = get_global_transform().affine_inverse() * event.position
		if current_tool == Tool.PEN:
			_add_point(local_pos)
		elif current_tool == Tool.ERASER:
			_erase_at(local_pos)


## 画笔：开始新笔画
func _start_stroke(pos: Vector2) -> void:
	is_drawing = true
	current_line = Line2D.new()
	current_line.width = STROKE_WIDTH
	current_line.default_color = STROKE_COLOR
	current_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	current_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	current_line.joint_mode = Line2D.LINE_JOINT_ROUND
	current_line.add_point(pos)
	add_child(current_line)
	last_point = pos


## 画笔：添加点（距离采样防抖）
func _add_point(pos: Vector2) -> void:
	if current_line == null:
		return
	if pos.distance_to(last_point) < MIN_DISTANCE:
		return
	current_line.add_point(pos)
	last_point = pos


## 画笔：结束笔画
func _end_stroke() -> void:
	is_drawing = false
	if current_line != null and current_line.get_point_count() < 2:
		current_line.queue_free()
	current_line = null


## 橡皮：擦除指定位置附近的线条点
func _erase_at(pos: Vector2) -> void:
	is_drawing = true
	var lines_to_process: Array[Line2D] = []
	for child in get_children():
		if child is Line2D:
			lines_to_process.append(child)

	for line in lines_to_process:
		var kept_segments: Array[PackedVector2Array] = []
		var current_segment = PackedVector2Array()

		for i in range(line.get_point_count()):
			var pt = line.get_point_position(i)
			if pt.distance_to(pos) > ERASE_RADIUS:
				current_segment.append(pt)
			else:
				if current_segment.size() >= 2:
					kept_segments.append(current_segment)
				current_segment = PackedVector2Array()

		if current_segment.size() >= 2:
			kept_segments.append(current_segment)

		if kept_segments.size() == 0:
			line.queue_free()
		elif kept_segments.size() == 1 and kept_segments[0].size() == line.get_point_count():
			pass  # 没有变化
		else:
			line.queue_free()
			for seg in kept_segments:
				var new_line = Line2D.new()
				new_line.width = STROKE_WIDTH
				new_line.default_color = STROKE_COLOR
				new_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
				new_line.end_cap_mode = Line2D.LINE_CAP_ROUND
				new_line.joint_mode = Line2D.LINE_JOINT_ROUND
				for pt in seg:
					new_line.add_point(pt)
				add_child(new_line)


## 清空所有笔画
func clear_all() -> void:
	for child in get_children():
		if child is Line2D:
			child.queue_free()


## 序列化为存档数据
func get_save_data() -> Array:
	var result = []
	for child in get_children():
		if child is Line2D:
			var pts = []
			for i in range(child.get_point_count()):
				var p = child.get_point_position(i)
				pts.append([p.x, p.y])
			result.append({"points": pts})
	return result


## 从存档数据恢复
func restore_data(data: Array) -> void:
	for entry in data:
		if not entry is Dictionary:
			continue
		var pts = entry.get("points", [])
		if not pts is Array or pts.size() < 2:
			continue
		var line = Line2D.new()
		line.width = STROKE_WIDTH
		line.default_color = STROKE_COLOR
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		for p in pts:
			if p is Array and p.size() >= 2:
				line.add_point(Vector2(p[0], p[1]))
		if line.get_point_count() >= 2:
			add_child(line)
