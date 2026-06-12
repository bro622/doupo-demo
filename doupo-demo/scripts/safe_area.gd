## 安全区域全局自动适配
## Autoload：场景切换时自动调整根节点锚点避开刘海/圆角/手势条
extends Node


func _ready() -> void:
	if OS.get_name() != "Android" and OS.get_name() != "iOS":
		return
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if not node is Control:
		return
	if node.get_parent() != get_tree().root:
		return
	await get_tree().process_frame
	if not is_instance_valid(node):
		return
	_apply(node as Control)


func _apply(ctrl: Control) -> void:
	var safe = DisplayServer.get_display_safe_area()
	var win = DisplayServer.window_get_size()
	if win.x <= 0 or win.y <= 0:
		return

	var sx = safe.position.x / float(win.x)
	var sy = safe.position.y / float(win.y)
	var ex = safe.end.x / float(win.x)
	var ey = safe.end.y / float(win.y)

	# 仅在安全区域不是全屏时调整（即存在刘海/手势条）
	if sx > 0.001 or sy > 0.001 or ex < 0.999 or ey < 0.999:
		ctrl.anchor_left = sx
		ctrl.anchor_top = sy
		ctrl.anchor_right = ex
		ctrl.anchor_bottom = ey
		ctrl.grow_horizontal = Control.GROW_DIRECTION_BOTH
		ctrl.grow_vertical = Control.GROW_DIRECTION_BOTH
