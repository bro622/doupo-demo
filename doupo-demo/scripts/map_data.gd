## 地图数据结构
## 对齐StS2 MapPoint + MapCoord + MapPointType
class_name MapData

## 节点类型(对齐StS2 MapPointType)
enum NodeType { MONSTER, ELITE, REST, SHOP, EVENT, TREASURE, BOSS, UNKNOWN, FLOOR_ZERO, ANCIENT }

## 节点类型图标（emoji 回退，用于无 PNG 素材的节点）
const NODE_ICONS: Dictionary = {
	0: "⚔️",
	1: "💀",
	2: "🏕",
	3: "💰",
	4: "❓",
	5: "🎁",
	6: "👑",
	7: "❓",
	8: "🌳",
	9: "👁",
}

## 节点类型 PNG 图标路径（有图标的节点，空字符串表示暂无素材回退 emoji）
const NODE_ICON_PATHS: Dictionary = {
	0: "res://assets/ui/map-nodes/mapnode_monster.png",
	1: "res://assets/ui/map-nodes/mapnode_elite.png",
	2: "res://assets/ui/map-nodes/mapnode_rest.png",
	3: "res://assets/ui/map-nodes/mapnode_shop.png",
	4: "res://assets/ui/map-nodes/mapnode_event.png",
	5: "res://assets/ui/map-nodes/mapnode_treasure.png",
	6: "res://assets/ui/map-nodes/mapnode_boss_scene1.png",  # 默认boss，运行时按场景覆盖
	7: "res://assets/ui/map-nodes/mapnode_event.png",  # 未知节点复用事件图标
	8: "res://assets/ui/map-nodes/mapnode_floor_zero.png",  # 菩提古树
	9: "res://assets/ui/map-nodes/mapnode_ancient_scene2.png",  # 守灵（默认，运行时按场景覆盖）
}

## 节点类型轮廓图标路径（悬停时显示）
const NODE_OUTLINE_PATHS: Dictionary = {
	0: "res://assets/ui/map-nodes/mapnode_monster_outline.png",
	1: "res://assets/ui/map-nodes/mapnode_elite_outline.png",
	2: "res://assets/ui/map-nodes/mapnode_rest_outline.png",
	3: "res://assets/ui/map-nodes/mapnode_shop_outline.png",
	4: "res://assets/ui/map-nodes/mapnode_event_outline.png",
	5: "res://assets/ui/map-nodes/mapnode_treasure_outline.png",
	6: "res://assets/ui/map-nodes/mapnode_boss_outline.png",
	7: "res://assets/ui/map-nodes/mapnode_event_outline.png",  # 未知复用事件轮廓
	8: "",
	9: "",
}

## 节点行为配置（参考 STS2 NNormalMapPoint/NBossMapPoint/NAncientMapPoint）
## category -> { hover, down, pulse_amt, pulse_base, vfx_mult }
const NODE_BEHAVIOR: Dictionary = {
	"normal":  { "hover": 1.45, "down": 0.9,  "pulse_amt": 0.12, "pulse_base": 1.1, "vfx_mult": 1.0 },
	"boss":    { "hover": 1.05, "down": 1.02, "pulse_amt": 0.0,  "pulse_base": 1.0, "vfx_mult": 2.0 },
	"ancient": { "hover": 1.1,  "down": 0.9,  "pulse_amt": 0.05, "pulse_base": 1.0, "vfx_mult": 1.5 },
}

## 节点类型名称
const NODE_NAMES: Dictionary = {
	0: "战斗",
	1: "精英",
	2: "修炼驿站",
	3: "商店",
	4: "奇遇",
	5: "宝箱",
	6: "BOSS",
	7: "未知",
	8: "菩提古树",
	9: "守灵",
}


## 地图节点(对齐StS2 MapPoint)
## layer: 从上到下的行索引(0=起点行, N=Boss行)
## col: 同行内的左右位置(0=最左)
class MapNode:
	var id: int
	var node_type: NodeType
	var layer: int         # 行(0=起点)
	var col: int           # 列(0=最左)
	var children: Array[int] = []
	var parents: Array[int] = []
	var position: Vector2 = Vector2.ZERO
	var enemy_ids: Array[String] = []
	var can_be_modified: bool = true  # 剪枝用

	func _init(p_id: int, p_type: NodeType, p_layer: int, p_col: int) -> void:
		id = p_id
		node_type = p_type
		layer = p_layer
		col = p_col

	func get_icon() -> String:
		return NODE_ICONS.get(int(node_type), "?")

	## 获取 PNG 图标路径（空字符串表示无素材，应回退 emoji）
	func get_icon_path() -> String:
		return NODE_ICON_PATHS.get(int(node_type), "")

	## 获取轮廓图标路径
	func get_outline_path() -> String:
		return NODE_OUTLINE_PATHS.get(int(node_type), "")

	## 获取节点行为类别（normal/boss/ancient）
	func get_category() -> String:
		match node_type:
			NodeType.BOSS:
				return "boss"
			NodeType.ANCIENT:
				return "ancient"
			_:
				return "normal"

	## 是否有 PNG 图标素材（false = 回退 emoji）
	func has_icon() -> bool:
		return get_icon_path() != ""

	func get_name() -> String:
		return NODE_NAMES.get(int(node_type), "未知")
