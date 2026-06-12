## 运行进度管理器（AutoLoad单例）
## 管理所有运行级持久数据：种子、地图、节点、事件、商店库存
## 从RunState中剥离，提供标准化的 get_save_data/restore_data 接口
extends Node

## 房间状态枚举
enum RoomState {
	IN_PROGRESS,    # 正在进行中（战斗中、事件中）
	REWARD_PENDING, # 等待领取奖励
	FINISHED        # 节点已彻底结束，等待选择下一个路线
}

## 运行种子（所有随机性的根源）
var run_seed: int = 0

## 地图数据
var map_nodes: Array = []  # Array[MapNode]

## 地图进度
var current_node_id: int = -1
var visited_nodes: Array[int] = []

## 当前场景编号
var current_scene: int = 1

## 事件系统
var completed_events: Array[int] = []
var event_flags: Dictionary = {}

## 事件战斗延迟奖励（战斗胜利后才发放的事件结果）
var pending_event_outcomes: Array = []  # Array[Dictionary] {type, value, ref_id, description}
var pending_event_id: int = -1
var pending_event_gold_cost: int = 0  # 战斗选项的金币消耗（延迟扣费）
var pending_event_potion_cost: int = 0  # 战斗选项的丹药消耗（延迟扣费）

## 商店库存（用于重启时保持相同商品）
var shop_inventory: Dictionary = {}

## 当前游戏阶段（用于保存并退出后恢复到正确的场景）
## -1=无活跃奇遇, 2=COMBAT, 4=SHOP, 5=REST, 6=EVENT
var saved_phase: int = -1
var saved_event_id: int = -1

## 当前房间状态
var current_room_state: RoomState = RoomState.IN_PROGRESS

## 第0层（菩提古树）状态
var floor_zero_chosen: bool = false
var floor_zero_choice: int = -1    # 0=稳健 1=爆发 2=博弈 3=提纯
var floor_zero_battles_remaining: int = 0  # 选项2：剩余1HP战斗场数
var floor_zero_result_log: Array[String] = []  # 临时数据通道：选项结果日志

## 守灵事件状态（场景2-4）
var scene2_ancient_chosen: bool = false
var scene2_ancient_choice: int = -1    # 0=A 1=B 2=C -1=未选
var scene3_ancient_chosen: bool = false
var scene3_ancient_choice: int = -1
var scene4_ancient_chosen: bool = false
var scene4_ancient_choice: int = -1
var ancient_result_log: Array[String] = []  # 临时数据通道：守灵选项结果日志

## 奖励界面的战斗类型（用于REWARD_PENDING时重新生成奖励）
var reward_battle_type: int = 0

## 地图滚动位置（从节点退出时保持）
var saved_map_scroll_y: float = -1.0

## 宝箱节点缓存（重启时使用相同奖励）
var pending_treasure_relic_ids: Array[int] = []   # 2-3个候选遗物ID
var pending_treasure_gold: int = 0
var treasure_chest_opened: bool = false            # 宝箱是否已开（存档恢复）

## 地图绘画标注数据（DrawingLayer 笔画持久化）
var drawing_strokes: Array = []


## ============================================================
##  运行生命周期
## ============================================================

## 初始化新运行
func init_new_run(seed_val: int) -> void:
	run_seed = seed_val
	map_nodes.clear()
	current_node_id = -1
	visited_nodes.clear()
	current_scene = 1
	completed_events.clear()
	event_flags.clear()
	pending_event_outcomes.clear()
	pending_event_id = -1
	shop_inventory.clear()
	saved_phase = -1
	saved_event_id = -1
	current_room_state = RoomState.IN_PROGRESS
	saved_map_scroll_y = -1.0
	reward_battle_type = 0
	floor_zero_chosen = false
	floor_zero_choice = -1
	floor_zero_battles_remaining = 0
	scene2_ancient_chosen = false
	scene2_ancient_choice = -1
	scene3_ancient_chosen = false
	scene3_ancient_choice = -1
	scene4_ancient_chosen = false
	scene4_ancient_choice = -1
	ancient_result_log.clear()
	floor_zero_result_log.clear()
	pending_event_gold_cost = 0
	pending_event_potion_cost = 0
	drawing_strokes.clear()
	pending_treasure_relic_ids.clear()
	pending_treasure_gold = 0
	treasure_chest_opened = false
	print("[RunManager] 新运行初始化完成 - 种子:%d" % seed_val)


## ============================================================
##  地图导航
## ============================================================

## 按ID查找节点
func get_node_by_id(node_id: int):
	for node in map_nodes:
		if node.id == node_id:
			return node
	return null


## 获取可前往的节点ID列表
func get_travelable_nodes() -> Array[int]:
	var result: Array[int] = []
	if current_node_id < 0:
		# 初始状态 - 返回第一行节点
		for node in map_nodes:
			if node.layer == 0:
				result.append(node.id)
		return result

	# 当前节点可点击（未访问或进行中，用于重启恢复）
	if current_node_id not in visited_nodes or current_room_state == RoomState.IN_PROGRESS:
		if current_node_id not in result:
			result.append(current_node_id)

	# 返回当前节点的子节点
	var current_node = get_node_by_id(current_node_id)
	if current_node != null:
		for child_id in current_node.children:
			if child_id not in result:
				result.append(child_id)
	return result


## 访问节点
func visit_node(node_id: int) -> void:
	current_node_id = node_id
	if node_id not in visited_nodes:
		visited_nodes.append(node_id)


## 推进到下一个节点（奖励界面"离开"按钮调用）
func advance_to_next_node() -> void:
	if current_node_id >= 0 and current_node_id not in visited_nodes:
		visited_nodes.append(current_node_id)
	current_room_state = RoomState.FINISHED


## ============================================================
##  事件系统
## ============================================================

## 添加事件标记
func add_event_flag(flag: String) -> void:
	event_flags[flag] = true


## 是否有事件标记
func has_event_flag(flag: String) -> bool:
	return event_flags.has(flag)


## 移除事件标记（一次性效果消耗后调用）
func remove_event_flag(flag: String) -> void:
	event_flags.erase(flag)


## ============================================================
##  序列化（get_save_data / restore_data）
## ============================================================

## 导出所有运行数据为JSON安全字典
func get_save_data() -> Dictionary:
	return {
		"run_seed": str(run_seed),
		"map_nodes": _serialize_map_nodes(map_nodes),
		"current_node_id": current_node_id,
		"visited_nodes": visited_nodes.duplicate(),
		"current_scene": current_scene,
		"completed_events": completed_events.duplicate(),
		"event_flags": event_flags.duplicate(),
		"shop_inventory": shop_inventory.duplicate(true),
		"saved_phase": saved_phase,
		"saved_event_id": saved_event_id,
		"current_room_state": current_room_state,
		"reward_battle_type": reward_battle_type,
		"floor_zero_chosen": floor_zero_chosen,
		"floor_zero_choice": floor_zero_choice,
		"floor_zero_battles_remaining": floor_zero_battles_remaining,
		"scene2_ancient_chosen": scene2_ancient_chosen,
		"scene2_ancient_choice": scene2_ancient_choice,
		"scene3_ancient_chosen": scene3_ancient_chosen,
		"scene3_ancient_choice": scene3_ancient_choice,
		"scene4_ancient_chosen": scene4_ancient_chosen,
		"scene4_ancient_choice": scene4_ancient_choice,
		"saved_map_scroll_y": saved_map_scroll_y,
		"drawing_strokes": drawing_strokes,
			"pending_treasure_relic_ids": pending_treasure_relic_ids,
			"pending_treasure_gold": pending_treasure_gold,
			"treasure_chest_opened": treasure_chest_opened,
		# pending_event_outcomes/pending_event_id/pending_combat_id 不持久化
		# SL回到事件选择页面，延迟奖励仅在当前会话有效
	}


## 从字典恢复所有运行数据
func restore_data(data: Dictionary) -> void:
	run_seed = int(data.get("run_seed", 0))
	map_nodes = _deserialize_map_nodes(data.get("map_nodes", []))
	current_node_id = data.get("current_node_id", -1)
	visited_nodes.clear()
	for v in data.get("visited_nodes", []):
		visited_nodes.append(int(v))
	current_scene = data.get("current_scene", 1)
	completed_events.clear()
	for e in data.get("completed_events", []):
		completed_events.append(int(e))
	event_flags = _parse_string_bool_dict(data.get("event_flags", {}))
	shop_inventory = data.get("shop_inventory", {}).duplicate(true)
	saved_phase = data.get("saved_phase", -1)
	saved_event_id = data.get("saved_event_id", -1)
	current_room_state = data.get("current_room_state", RoomState.IN_PROGRESS) as RoomState
	reward_battle_type = data.get("reward_battle_type", 0)

	floor_zero_chosen = data.get("floor_zero_chosen", false)
	floor_zero_choice = data.get("floor_zero_choice", -1)
	floor_zero_battles_remaining = data.get("floor_zero_battles_remaining", 0)
	scene2_ancient_chosen = data.get("scene2_ancient_chosen", false)
	scene2_ancient_choice = data.get("scene2_ancient_choice", -1)
	scene3_ancient_chosen = data.get("scene3_ancient_chosen", false)
	scene3_ancient_choice = data.get("scene3_ancient_choice", -1)
	scene4_ancient_chosen = data.get("scene4_ancient_chosen", false)
	scene4_ancient_choice = data.get("scene4_ancient_choice", -1)
	pending_treasure_relic_ids = _parse_int_array(data.get("pending_treasure_relic_ids", []))
	pending_treasure_gold = data.get("pending_treasure_gold", 0)
	treasure_chest_opened = data.get("treasure_chest_opened", false)
	saved_map_scroll_y = data.get("saved_map_scroll_y", -1.0)
	drawing_strokes = data.get("drawing_strokes", [])
	pending_event_outcomes.clear()
	pending_event_id = -1
	pending_event_gold_cost = 0
	pending_event_potion_cost = 0

## ============================================================
##  序列化辅助方法
## ============================================================

func _serialize_map_nodes(nodes: Array) -> Array:
	var result = []
	for node in nodes:
		result.append({
			"id": node.id,
			"node_type": int(node.node_type),
			"layer": node.layer,
			"col": node.col,
			"children": node.children.duplicate(),
			"parents": node.parents.duplicate(),
			"position": {"x": node.position.x, "y": node.position.y},
			"enemy_ids": node.enemy_ids.duplicate(),
			"can_be_modified": node.can_be_modified,
		})
	return result


func _deserialize_map_nodes(arr: Array) -> Array:
	var result: Array = []
	for d in arr:
		if not d is Dictionary:
			continue
		var node = MapData.MapNode.new(
			d.get("id", 0),
			d.get("node_type", 0) as MapData.NodeType,
			d.get("layer", 0),
			d.get("col", 0)
		)
		node.children.clear()
		for c in d.get("children", []):
			node.children.append(int(c))
		node.parents.clear()
		for p in d.get("parents", []):
			node.parents.append(int(p))
		var pos = d.get("position", {})
		if pos is Dictionary:
			node.position = Vector2(pos.get("x", 0.0), pos.get("y", 0.0))
		node.enemy_ids.clear()
		for eid in d.get("enemy_ids", []):
			node.enemy_ids.append(str(eid))
		node.can_be_modified = d.get("can_be_modified", true)
		result.append(node)
	return result


func _parse_string_bool_dict(d) -> Dictionary:
	var result: Dictionary = {}
	if d is Dictionary:
		for key in d:
			result[str(key)] = bool(d[key])
	return result


func _parse_int_array(arr) -> Array[int]:
	var result: Array[int] = []
	if arr is Array:
		for v in arr:
			result.append(int(v))
	return result
