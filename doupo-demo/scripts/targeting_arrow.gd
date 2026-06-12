## 瞄准箭头
## 从卡牌到鼠标的贝塞尔曲线箭头
class_name TargetingArrow
extends Node2D

## 箭头段数
const SEGMENT_COUNT: int = 15

## 绘制状态
var is_drawing: bool = false
var from_pos: Vector2 = Vector2.ZERO
var to_pos: Vector2 = Vector2.ZERO

## 箭头颜色
var arrow_color: Color = Color(1.0, 0.3, 0.3, 0.8)
var arrow_color_enemy: Color = Color(1.0, 0.3, 0.3, 0.8)
var arrow_color_ally: Color = Color(0.3, 0.8, 1.0, 0.8)

## 当前颜色
var current_color: Color = arrow_color_enemy


func _ready() -> void:
	z_index = 50
	visible = false


func _draw() -> void:
	if not is_drawing:
		return

	# 绘制贝塞尔曲线箭头
	var points = _get_bezier_points(from_pos, to_pos)

	# 绘制线条
	for i in range(points.size() - 1):
		var width = lerp(2.0, 6.0, float(i) / points.size())
		draw_line(points[i], points[i + 1], current_color, width)

	# 绘制箭头头部
	if points.size() >= 2:
		var last = points[points.size() - 1]
		var prev = points[points.size() - 2]
		var dir = (last - prev).normalized()
		var arrow_size = 15.0

		# 箭头两翼
		var wing1 = last - dir.rotated(0.5) * arrow_size
		var wing2 = last - dir.rotated(-0.5) * arrow_size
		draw_line(last, wing1, current_color, 4.0)
		draw_line(last, wing2, current_color, 4.0)


## 获取贝塞尔曲线点
func _get_bezier_points(start: Vector2, end: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = []

	# 控制点 - 形成弧形
	var mid = (start + end) / 2
	var control = Vector2(
		mid.x - (end.y - start.y) * 0.3,
		mid.y - (end.x - start.x) * 0.1
	)

	for i in range(SEGMENT_COUNT + 1):
		var t = float(i) / SEGMENT_COUNT
		var point = _bezier(start, control, end, t)
		points.append(point)

	return points


## 二次贝塞尔插值
func _bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var u = 1.0 - t
	return u * u * p0 + 2 * u * t * p1 + t * t * p2


## 开始绘制
func start_drawing(from: Vector2) -> void:
	is_drawing = true
	from_pos = from
	to_pos = from
	current_color = arrow_color_enemy
	visible = true
	queue_redraw()


## 更新目标位置
func update_target(target: Vector2) -> void:
	to_pos = target
	queue_redraw()


## 设置是否悬停在敌人上
func set_highlighting_on(is_enemy: bool) -> void:
	current_color = arrow_color_enemy if is_enemy else arrow_color_ally
	queue_redraw()


## 停止绘制
func stop_drawing() -> void:
	is_drawing = false
	visible = false
	queue_redraw()
