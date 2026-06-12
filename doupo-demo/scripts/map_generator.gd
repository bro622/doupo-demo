## 地图生成器
## 忠实移植StS2 StandardActMap 6阶段流水线
## 阶段: GenerateMap → AssignPointTypes → PruneAndRepair → CenterGrid/SpreadAdjacent/StraightenPaths → SetEnemies → CalculatePositions
class_name MapGenerator


## 场景配置
const ACT_CONFIGS: Dictionary = {
	"jia_ma": {
		"map_length": 15,
		"col_count": 7,
		"num_of_elites": 5,
		"num_of_shops": 3,
		"num_of_unknowns": 12,
		"num_of_rests": 3,
		"boss_id": "yunshan",
		# 按层数划分区域，每个区域有独立的敌人池
		"zones": [
			{
				"name": "mountains",
				"floor_start": 0,
				"floor_end": 4,
				"monster_pool": ["bandit", "magic_wolf", "bounty_hunter"],
				"elite_pool": ["high_beast"],  # 注意：ELITE 节点在 row 6 前不允许出现，此池实际不可达
			},
			{
				"name": "desert",
				"floor_start": 5,
				"floor_end": 9,
				"monster_pool": ["desert_scorpion", "snake_warrior"],
				"elite_pool": ["hai_bodong"],
			},
			{
				"name": "cloud_sect",
				"floor_start": 10,
				"floor_end": 14,
				"monster_pool": ["yunlan_disciple", "yunlan_inner"],
				"elite_pool": ["geye", "nalan"],
			},
		],
	},
	"black_corner": {
		"map_length": 15,
		"col_count": 7,
		"num_of_elites": 6,
		"num_of_shops": 3,
		"num_of_unknowns": 10,
		"num_of_rests": 3,
		"boss_id": "han_feng",
		"zones": [
			{
				"name": "black_seal_city",
				"floor_start": 0,
				"floor_end": 4,
				"monster_pool": ["bc_assassin", "bc_assassin_member", "bc_mercenary"],
				"elite_pool": ["mo_tianxing"],
			},
			{
				"name": "blood_sect",
				"floor_start": 5,
				"floor_end": 9,
				"monster_pool": ["blood_disciple", "heretical_alchemist"],
				"elite_pool": ["fan_lao"],
			},
			{
				"name": "fengcheng",
				"floor_start": 10,
				"floor_end": 14,
				"monster_pool": ["serpent_assassin", "serpent_elite_assassin"],
				"elite_pool": ["gold_silver_elders"],
			},
		],
	},
	"canaan": {
		"map_length": 15,
		"col_count": 7,
		"num_of_elites": 6,
		"num_of_shops": 3,
		"num_of_unknowns": 10,
		"num_of_rests": 3,
		"boss_id": "fallen_heart_flame",
		"zones": [
			{
				"name": "outer_academy",
				"floor_start": 0,
				"floor_end": 4,
				"monster_pool": ["canaan_outer_disciple", "canaan_inner_disciple"],
				"elite_pool": ["lin_xiuya"],
			},
			{
				"name": "inner_academy",
				"floor_start": 5,
				"floor_end": 9,
				"monster_pool": ["fire_lizard", "cultivation_deviation"],
				"elite_pool": ["liu_qing"],
			},
			{
				"name": "blazing_tower",
				"floor_start": 10,
				"floor_end": 14,
				"monster_pool": ["heart_flame_phantom", "forest_beast"],
				"elite_pool": ["earth_devil"],
			},
		],
	},
	"central_plains": {
		"map_length": 15,
		"col_count": 7,
		"num_of_elites": 6,
		"num_of_shops": 3,
		"num_of_unknowns": 10,
		"num_of_rests": 3,
		"boss_id": "huntiandi",
		"zones": [
			{
				"name": "pill_tower",
				"floor_start": 0,
				"floor_end": 4,
				"monster_pool": ["soul_hall_guard", "pill_tower_guard"],
				"elite_pool": ["yao_dan"],
			},
			{
				"name": "soul_hall",
				"floor_start": 5,
				"floor_end": 9,
				"monster_pool": ["dark_soul_messenger", "soul_hall_elder"],
				"elite_pool": ["hun_miesheng"],
			},
			{
				"name": "ancient_cave",
				"floor_start": 10,
				"floor_end": 14,
				"monster_pool": ["ancient_puppet", "ancient_clan_warrior", "soul_phantom"],
				"elite_pool": ["soul_hall_elder_elite"],
			},
		],
	},
}


## 生成一个Act的地图(对齐StS2 StandardActMap构造函数)
static func generate_act(act_key: String) -> Array:
	var config: Dictionary
	if ACT_CONFIGS.has(act_key):
		config = ACT_CONFIGS[act_key]
	else:
		push_warning("[MapGenerator] 未知Act配置: %s, 使用jia_ma" % act_key)
		config = ACT_CONFIGS["jia_ma"]

	var map_length: int = config["map_length"]
	var col_count: int = config["col_count"]

	# 初始化网格 grid[col][row]
	var grid: Array = []
	for c in col_count:
		var column: Array = []
		column.resize(map_length)
		grid.append(column)

	var node_id: int = 0
	var start_points: Array = []  # 对齐StS2 startMapPoints

	# === 阶段1: GenerateMap ===
	# 起点(对齐StS2 StartingMapPoint)
	@warning_ignore("integer_division")
	var start_node = MapData.MapNode.new(node_id, MapData.NodeType.MONSTER, 0, col_count / 2)
	start_node.can_be_modified = false
	grid[start_node.col][0] = start_node
	node_id += 1

	# Boss节点(对齐StS2 BossMapPoint)
	@warning_ignore("integer_division")
	var boss = MapData.MapNode.new(node_id, MapData.NodeType.BOSS, map_length - 1, col_count / 2)
	boss.enemy_ids = Array([config.get("boss_id", "boss")], TYPE_STRING, "", null)
	boss.can_be_modified = false
	node_id += 1

	# 7条路径(对齐StS2 _iterations = 7)
	for i in 7:
		var start_col = RNGManager.map_rng.randi() % col_count
		# 第2条路径确保不与第1条重合(对齐StS2 i==1)
		if i == 1:
			while _has_point_at(grid, start_col, 1, col_count, map_length):
				start_col = RNGManager.map_rng.randi() % col_count

		# 获取或创建row 1的起点
		var path_start = _get_or_create(grid, start_col, 1, node_id, col_count, map_length)
		if path_start.id == node_id:
			node_id += 1
		start_points.append(path_start)

		# PathGenerate: 从row 1向下走到最后一行
		var current = path_start
		while current.layer < map_length - 2:
			var next_coord = _generate_next_coord(grid, current, col_count, map_length)
			var next_node = _get_or_create(grid, next_coord[0], next_coord[1], node_id, col_count, map_length)
			if next_node.id == node_id:
				node_id += 1
			_add_edge(current, next_node)
			current = next_node

	# 连接最后一行节点到Boss(对齐StS2 ForEachInRow lastRow → Boss)
	for c in col_count:
		var node = _grid_get(grid, c, map_length - 2, col_count, map_length)
		if node != null:
			_add_edge(node, boss)

	# 连接起点到所有row 1节点(对齐StS2 ForEachInRow row1 → StartingMapPoint)
	for c in col_count:
		var node = _grid_get(grid, c, 1, col_count, map_length)
		if node != null:
			_add_edge(start_node, node)

	# 收集所有节点
	var all_points: Array = []
	for c in col_count:
		for r in map_length:
			if grid[c][r] != null:
				all_points.append(grid[c][r])
	all_points.append(boss)

	# === 阶段2: AssignPointTypes ===
	_assign_point_types(grid, config, all_points, start_node, boss, col_count, map_length)

	# === 阶段3: PruneAndRepair ===
	_prune_and_repair(grid, start_points, start_node, boss, config, all_points, col_count, map_length)

	# === 阶段4: PostProcessing ===
	_center_grid(grid, col_count, map_length)
	_spread_adjacent(grid, boss, col_count, map_length)
	_straighten_paths(grid, boss, col_count, map_length)

	# 重新收集(剪枝可能删除了节点)
	var nodes: Array = []
	for c in col_count:
		for r in map_length:
			if grid[c][r] != null:
				nodes.append(grid[c][r])
	nodes.append(boss)

	# 设置Boss和起点类型
	boss.node_type = MapData.NodeType.BOSS
	start_node.node_type = MapData.NodeType.MONSTER

	# === 阶段5: SetEnemies ===
	_set_enemies(nodes, config)

	# === 阶段6: CalculatePositions ===
	_calculate_positions(nodes, start_node, boss, map_length, col_count)

	print("[MapGenerator] 地图生成完成: %d个节点, %d列×%d行" % [nodes.size(), col_count, map_length])
	return nodes


# ============================================================
#  阶段1: GenerateMap (对齐StS2 GenerateMap + PathGenerate + GenerateNextCoord + HasInvalidCrossover)
# ============================================================

## 对齐StS2 PathGenerate: 从起点向下走到最后一行
## 在StS2中这是实例方法，这里内联到generate_act中

## 对齐StS2 GenerateNextCoord: 随机选择下一步坐标
static func _generate_next_coord(grid: Array, current: MapData.MapNode, col_count: int, map_length: int) -> Array:
	var col = current.col
	var min_col = maxi(0, col - 1)
	var max_col = mini(col + 1, col_count - 1)

	# 方向: -1=左, 0=直, 1=右
	var directions: Array = [-1, 0, 1]
	# 打乱方向(对齐StS2 StableShuffle)
	for j in range(directions.size() - 1, 0, -1):
		var k = RNGManager.map_rng.randi() % (j + 1)
		var temp = directions[j]
		directions[j] = directions[k]
		directions[k] = temp

	for dir in directions:
		var target_col: int
		match dir:
			-1: target_col = min_col
			0: target_col = col
			1: target_col = max_col
		var target_row = current.layer + 1

		if not _has_invalid_crossover(grid, current, target_col, col_count, map_length):
			return [target_col, target_row]

	# 所有方向都有交叉，回退到直行
	return [col, current.layer + 1]


## 对齐StS2 HasInvalidCrossover: 检查路径交叉
static func _has_invalid_crossover(grid: Array, current: MapData.MapNode, target_x: int, col_count: int, map_length: int) -> bool:
	var delta = target_x - current.col
	# 直行必定不会产生交叉
	if delta == 0:
		return false
	# 核心修复：获取【同层】的目标列节点 (sibling)
	# 因为只有当同层的相邻节点走向我们所在的列时，才会形成交叉
	var sibling = _grid_get(grid, target_x, current.layer, col_count, map_length)
	if sibling != null:
		# 检查这个同层相邻节点，是否有一条边连向了 current.col 的下一层
		for child_id in sibling.children:
			var child = _find_point(grid, child_id, col_count, map_length)
			# 如果相邻节点走向了我们现在的列，就会形成 X 型交叉
			if child != null and child.col == current.col:
				return true
	return false


# ============================================================
#  阶段2: AssignPointTypes (对齐StS2 AssignPointTypes + GetNextValidPointType + IsValidPointType)
# ============================================================

static func _assign_point_types(grid: Array, config: Dictionary, all_points: Array, _start_node: MapData.MapNode, boss: MapData.MapNode, col_count: int, map_length: int) -> void:
	# 固定类型
	# 最后一行: RestSite(对齐StS2 ForEachInRow lastRow → RestSite)
	for c in col_count:
		var node = _grid_get(grid, c, map_length - 2, col_count, map_length)
		if node != null:
			node.node_type = MapData.NodeType.REST
			node.can_be_modified = false

	# row 1: Monster(对齐StS2 ForEachInRow row1 → Monster)
	for c in col_count:
		var node = _grid_get(grid, c, 1, col_count, map_length)
		if node != null:
			node.node_type = MapData.NodeType.MONSTER
			node.can_be_modified = false

	# row mapLength-7: Treasure(对齐StS2 ForEachInRow rowCount-7 → Treasure)
	var treasure_row = map_length - 7
	if treasure_row > 0 and treasure_row < map_length - 1:
		for c in col_count:
			var node = _grid_get(grid, c, treasure_row, col_count, map_length)
			if node != null:
				node.node_type = MapData.NodeType.TREASURE
				node.can_be_modified = false

	# 构建待分配类型队列(对齐StS2 Queue<MapPointType>)
	var type_queue: Array = []
	for _i in config.get("num_of_rests", 3):
		type_queue.append(MapData.NodeType.REST)
	for _i in config.get("num_of_shops", 3):
		type_queue.append(MapData.NodeType.SHOP)
	for _i in config.get("num_of_elites", 5):
		type_queue.append(MapData.NodeType.ELITE)
	for _i in config.get("num_of_unknowns", 12):
		type_queue.append(MapData.NodeType.UNKNOWN)

	# 打乱队列
	for i in range(type_queue.size() - 1, 0, -1):
		var j = RNGManager.map_rng.randi() % (i + 1)
		var temp = type_queue[i]
		type_queue[i] = type_queue[j]
		type_queue[j] = temp

	# 3轮分配(对齐StS2 AssignRemainingTypesToRandomPoints 的3次迭代)
	for _iter in 3:
		if type_queue.is_empty():
			break
		var unassigned: Array = []
		for p in all_points:
			if int(p.node_type) == 0 and p.can_be_modified:  # Unassigned == MONSTER且可修改
				unassigned.append(p)
		# 打乱
		for i in range(unassigned.size() - 1, 0, -1):
			var j = RNGManager.map_rng.randi() % (i + 1)
			var temp = unassigned[i]
			unassigned[i] = unassigned[j]
			unassigned[j] = temp
		for p in unassigned:
			if type_queue.is_empty():
				break
			var chosen = _get_next_valid_point_type(grid, type_queue, p, boss, col_count, map_length)
			if chosen != -1:
				p.node_type = chosen

	# 未分配的填Monster(对齐StS2 Unassigned → Monster)
	for p in all_points:
		if int(p.node_type) == 0 and p.can_be_modified:
			p.node_type = MapData.NodeType.MONSTER


## 对齐StS2 GetNextValidPointType: 从队列中找到第一个有效类型
static func _get_next_valid_point_type(grid: Array, type_queue: Array, map_point: MapData.MapNode, boss: MapData.MapNode, col_count: int, map_length: int) -> int:
	var queue_size = type_queue.size()
	for _i in queue_size:
		var candidate = type_queue.pop_front()
		if _is_valid_point_type(grid, candidate, map_point, boss, col_count, map_length):
			return candidate
		type_queue.append(candidate)
	return -1  # Unassigned


## 对齐StS2 IsValidPointType: 5层约束校验
static func _is_valid_point_type(grid: Array, point_type: int, map_point: MapData.MapNode, boss: MapData.MapNode, col_count: int, map_length: int) -> bool:
	if not _is_valid_for_lower(point_type, map_point):
		return false
	if not _is_valid_for_upper(point_type, map_point, map_length):
		return false
	if not _is_valid_with_parents(grid, point_type, map_point, boss, col_count, map_length):
		return false
	if not _is_valid_with_children(grid, point_type, map_point, boss, col_count, map_length):
		return false
	if not _is_valid_with_siblings(grid, point_type, map_point, boss, col_count, map_length):
		return false
	return true


## 下限行限制(对齐StS2 IsValidForLower)
static func _is_valid_for_lower(point_type: int, map_point: MapData.MapNode) -> bool:
	# RestSite和Elite不能在row < 6
	if map_point.layer < 6:
		if point_type == MapData.NodeType.REST or point_type == MapData.NodeType.ELITE:
			return false
	return true


## 上限行限制(对齐StS2 IsValidForUpper)
static func _is_valid_for_upper(point_type: int, map_point: MapData.MapNode, map_length: int) -> bool:
	# RestSite不能在最后3行
	if map_point.layer >= map_length - 3:
		if point_type == MapData.NodeType.REST:
			return false
	return true


## 父子相邻限制(对齐StS2 IsValidWithParents)
static func _is_valid_with_parents(grid: Array, point_type: int, map_point: MapData.MapNode, boss: MapData.MapNode, col_count: int, map_length: int) -> bool:
	# Elite/RestSite/Treasure/Shop不能与同类父子相邻
	if point_type == MapData.NodeType.ELITE or point_type == MapData.NodeType.REST or \
	   point_type == MapData.NodeType.TREASURE or point_type == MapData.NodeType.SHOP:
		for parent_id in map_point.parents:
			var parent = _find_point_or_boss(grid, parent_id, boss, col_count, map_length)
			if parent != null and int(parent.node_type) == point_type:
				return false
		for child_id in map_point.children:
			var child = _find_point_or_boss(grid, child_id, boss, col_count, map_length)
			if child != null and int(child.node_type) == point_type:
				return false
	return true


## 子节点限制(对齐StS2 IsValidWithChildren)
static func _is_valid_with_children(grid: Array, point_type: int, map_point: MapData.MapNode, boss: MapData.MapNode, col_count: int, map_length: int) -> bool:
	if point_type == MapData.NodeType.ELITE or point_type == MapData.NodeType.REST or \
	   point_type == MapData.NodeType.TREASURE or point_type == MapData.NodeType.SHOP:
		for child_id in map_point.children:
			var child = _find_point_or_boss(grid, child_id, boss, col_count, map_length)
			if child != null and int(child.node_type) == point_type:
				return false
	return true


## 兄弟限制(对齐StS2 IsValidWithSiblings + GetSiblings)
## StS2的sibling = 父节点的其他子节点(不是同行！)
static func _is_valid_with_siblings(grid: Array, point_type: int, map_point: MapData.MapNode, boss: MapData.MapNode, col_count: int, map_length: int) -> bool:
	if point_type == MapData.NodeType.REST or point_type == MapData.NodeType.MONSTER or \
	   point_type == MapData.NodeType.UNKNOWN or point_type == MapData.NodeType.ELITE or \
	   point_type == MapData.NodeType.SHOP:
		# 获取sibling(父节点的其他子节点)
		for parent_id in map_point.parents:
			var parent = _find_point_or_boss(grid, parent_id, boss, col_count, map_length)
			if parent != null:
				for sibling_id in parent.children:
					if sibling_id != map_point.id:
						var sibling = _find_point_or_boss(grid, sibling_id, boss, col_count, map_length)
						if sibling != null and int(sibling.node_type) == point_type:
							return false
	return true


# ============================================================
#  阶段3: PruneAndRepair (对齐StS2 MapPathPruning)
# ============================================================

static func _prune_and_repair(grid: Array, start_points: Array, start_node: MapData.MapNode, boss: MapData.MapNode, config: Dictionary, all_points: Array, col_count: int, map_length: int) -> void:
	# 最多3轮(对齐StS2)
	for _i in 3:
		_prune_duplicate_segments(grid, start_points, start_node, boss, col_count, map_length)
		# 重建all_points：裁剪后grid中已移除的节点不应再计入配额
		all_points.clear()
		for c in col_count:
			for r in map_length:
				if grid[c][r] != null:
					all_points.append(grid[c][r])
		all_points.append(boss)
		if not _repair_pruned_point_types(grid, all_points, boss, config, col_count, map_length):
			break


## 对齐StS2 PruneDuplicateSegments
static func _prune_duplicate_segments(grid: Array, start_points: Array, start_node: MapData.MapNode, boss: MapData.MapNode, col_count: int, map_length: int) -> void:
	var iterations = 0
	while iterations < 50:
		var matching_segments = _find_matching_segments(grid, start_node, boss, col_count, map_length)
		if matching_segments.is_empty():
			break
		var pruned = _prune_paths(grid, start_points, matching_segments, boss, col_count, map_length)
		if not pruned:
			break
		iterations += 1


## 对齐StS2 FindAllPaths: BFS找到从起点到Boss的所有路径
static func _find_all_paths(grid: Array, current: MapData.MapNode, boss: MapData.MapNode, col_count: int, map_length: int) -> Array:
	if int(current.node_type) == MapData.NodeType.BOSS:
		return [[current]]
	var paths: Array = []
	for child_id in current.children:
		var child = _find_point_or_boss(grid, child_id, boss, col_count, map_length)
		if child != null:
			var sub_paths = _find_all_paths(grid, child, boss, col_count, map_length)
			for sp in sub_paths:
				var new_path = [current]
				new_path.append_array(sp)
				paths.append(new_path)
	return paths


## 对齐StS2 FindMatchingSegments: 找到重复路径段
static func _find_matching_segments(grid: Array, start_node: MapData.MapNode, boss: MapData.MapNode, col_count: int, map_length: int) -> Array:
	var all_paths = _find_all_paths(grid, start_node, boss, col_count, map_length)
	var segments: Dictionary = {}
	for path in all_paths:
		_add_segments_to_dict(path, segments)
	# 返回有重复的段组
	var duplicates: Array = []
	for key in segments:
		if segments[key].size() > 1:
			duplicates.append(segments[key])
	return duplicates


## 对齐StS2 AddSegmentsToDictionary
static func _add_segments_to_dict(path: Array, segments: Dictionary) -> void:
	for i in path.size() - 1:
		if not _is_valid_segment_start(path[i]):
			continue
		for j in range(2, path.size() - i):
			var end_point = path[i + j]
			if _is_valid_segment_end(end_point):
				var segment = path.slice(i, i + j + 1)
				var key = _generate_segment_key(segment)
				if not segments.has(key):
					segments[key] = [segment]
				else:
					var has_overlap = false
					for existing in segments[key]:
						if _overlapping_segment(existing, segment):
							has_overlap = true
							break
					if not has_overlap:
						segments[key].append(segment)


static func _is_valid_segment_start(point: MapData.MapNode) -> bool:
	if point.children.size() <= 1:
		return point.layer == 0
	return true


static func _is_valid_segment_end(point: MapData.MapNode) -> bool:
	return point.parents.size() >= 2


static func _generate_segment_key(segment: Array) -> String:
	var start = segment[0]
	var end = segment[segment.size() - 1]
	var prefix: String
	if start.layer == 0:
		prefix = "%d-%d,%d-" % [start.layer, end.col, end.layer]
	else:
		prefix = "%d,%d-%d,%d-" % [start.col, start.layer, end.col, end.layer]
	var types: Array = []
	for p in segment:
		types.append(int(p.node_type))
	return prefix + ",".join(types)


static func _overlapping_segment(a: Array, b: Array) -> bool:
	if a.size() < 3 or b.size() < 3:
		return false
	for i in range(1, mini(a.size(), b.size()) - 1):
		if a[i].id == b[i].id:
			return true
	return false


## 对齐StS2 PrunePaths
static func _prune_paths(grid: Array, start_points: Array, matching_segments: Array, boss: MapData.MapNode, col_count: int, map_length: int) -> bool:
	for segment_group in matching_segments:
		# 打乱(对齐StS2 UnstableShuffle)
		for i in range(segment_group.size() - 1, 0, -1):
			var j = RNGManager.map_rng.randi() % (i + 1)
			var temp = segment_group[i]
			segment_group[i] = segment_group[j]
			segment_group[j] = temp
		# 尝试PruneAllButLast
		if _prune_all_but_last(grid, start_points, segment_group, boss, col_count, map_length):
			return true
		# 尝试BreakAParentChildRelationship
		if _break_parent_child_in_any(segment_group):
			return true
	return false


static func _prune_all_but_last(grid: Array, start_points: Array, matches: Array, boss: MapData.MapNode, col_count: int, map_length: int) -> bool:
	var count = 0
	for segment in matches:
		if count == matches.size() - 1:
			return count > 0
		if _prune_segment(grid, start_points, segment, boss, col_count, map_length):
			count += 1
	return count > 0


static func _prune_segment(grid: Array, start_points: Array, segment: Array, boss: MapData.MapNode, col_count: int, map_length: int) -> bool:
	var result = false
	for i in segment.size() - 1:
		var point = segment[i]
		if not _is_in_map(grid, point, col_count, map_length):
			return false  # 已移除的节点不算成功裁剪
		if point.children.size() > 1 or point.parents.size() > 1:
			continue
		# 检查父节点是否只有一个子节点
		var parent_single_child = false
		for pid in point.parents:
			var parent = _find_point_or_boss(grid, pid, boss, col_count, map_length)
			if parent != null and parent.children.size() == 1:
				parent_single_child = true
				break
		if parent_single_child:
			continue
		# 检查剩余段是否有分支
		var remaining = segment.slice(i)
		var has_branch = false
		for n in remaining:
			if n.children.size() > 1 and n.parents.size() == 1:
				has_branch = true
				break
		if has_branch:
			continue
		# 检查终点
		if segment[segment.size() - 1].parents.size() == 1:
			return false
		# 检查子节点
		var safe = true
		for cid in point.children:
			if cid not in segment.map(func(s): return s.id):
				var child = _find_point_or_boss(grid, cid, boss, col_count, map_length)
				if child != null and child.parents.size() == 1:
					safe = false
					break
		if safe:
			_remove_point(grid, start_points, point, boss, col_count, map_length)
			result = true
	return result


static func _break_parent_child_in_any(matches: Array) -> bool:
	for segment in matches:
		if _break_parent_child_in_segment(segment):
			return true
	return false


static func _break_parent_child_in_segment(segment: Array) -> bool:
	for i in segment.size() - 1:
		var point = segment[i]
		if point.children.size() >= 2:
			var next = segment[i + 1]
			if next.parents.size() != 1:
				# 断开边
				point.children.erase(next.id)
				next.parents.erase(point.id)
				return true
	return false


static func _remove_point(grid: Array, start_points: Array, point: MapData.MapNode, boss: MapData.MapNode, col_count: int, map_length: int) -> void:
	if point.col >= 0 and point.col < col_count and point.layer >= 0 and point.layer < map_length:
		if grid[point.col][point.layer] == point:
			grid[point.col][point.layer] = null
	start_points.erase(point)
	for cid in point.children.duplicate():
		var child = _find_point_or_boss(grid, cid, boss, col_count, map_length)
		if child != null:
			child.parents.erase(point.id)
	point.children.clear()
	for pid in point.parents.duplicate():
		var parent = _find_point_or_boss(grid, pid, boss, col_count, map_length)
		if parent != null:
			parent.children.erase(point.id)
	point.parents.clear()


static func _is_in_map(grid: Array, point: MapData.MapNode, col_count: int, map_length: int) -> bool:
	if int(point.node_type) == MapData.NodeType.BOSS:
		return true
	if point.col >= 0 and point.col < col_count and point.layer >= 0 and point.layer < map_length:
		return grid[point.col][point.layer] != null
	return false


## 对齐StS2 RepairPrunedPointTypes
static func _repair_pruned_point_types(grid: Array, all_points: Array, boss: MapData.MapNode, config: Dictionary, col_count: int, map_length: int) -> bool:
	var changed = false
	changed = _repair_point_type(grid, all_points, boss, MapData.NodeType.SHOP, config.get("num_of_shops", 3), col_count, map_length) or changed
	changed = _repair_point_type(grid, all_points, boss, MapData.NodeType.ELITE, config.get("num_of_elites", 5), col_count, map_length) or changed
	changed = _repair_point_type(grid, all_points, boss, MapData.NodeType.REST, config.get("num_of_rests", 3), col_count, map_length) or changed
	changed = _repair_point_type(grid, all_points, boss, MapData.NodeType.UNKNOWN, config.get("num_of_unknowns", 12), col_count, map_length) or changed
	return changed


static func _repair_point_type(grid: Array, all_points: Array, boss: MapData.MapNode, type: int, target_count: int, col_count: int, map_length: int) -> bool:
	var current_count = 0
	for p in all_points:
		if int(p.node_type) == type:
			current_count += 1
	var deficit = target_count - current_count
	if deficit <= 0:
		return false
	# 收集可替换的Monster节点
	var replaceable: Array = []
	for p in all_points:
		if int(p.node_type) == MapData.NodeType.MONSTER and p.can_be_modified:
			replaceable.append(p)
	# 打乱
	for i in range(replaceable.size() - 1, 0, -1):
		var j = RNGManager.map_rng.randi() % (i + 1)
		var temp = replaceable[i]
		replaceable[i] = replaceable[j]
		replaceable[j] = temp
	var repaired = false
	for p in replaceable:
		if deficit <= 0:
			break
		if _is_valid_point_type(grid, type, p, boss, col_count, map_length):
			p.node_type = type
			deficit -= 1
			repaired = true
	return repaired


# ============================================================
#  阶段4: PostProcessing (对齐StS2 MapPostProcessing)
# ============================================================

## 对齐StS2 CenterGrid
static func _center_grid(grid: Array, col_count: int, map_length: int) -> void:
	var left_empty = _is_column_empty(grid, 0, map_length) and _is_column_empty(grid, 1, map_length)
	var right_empty = _is_column_empty(grid, col_count - 1, map_length) and _is_column_empty(grid, col_count - 2, map_length)
	var shift = 0
	if left_empty and not right_empty:
		shift = 1  # 左移(所有col减1)
	elif not left_empty and right_empty:
		shift = -1  # 右移(所有col加1)
	if shift == 0:
		return
	# 执行移位
	for r in map_length:
		if shift > 0:
			# 左移: col从0到col_count-2
			for c in range(0, col_count - shift):
				grid[c][r] = grid[c + shift][r]
				if grid[c][r] != null:
					grid[c][r].col = c
			for c in range(col_count - shift, col_count):
				grid[c][r] = null
		else:
			# 右移: col从col_count-1到1
			for c in range(col_count - 1, -shift - 1, -1):
				grid[c][r] = grid[c + shift][r]
				if grid[c][r] != null:
					grid[c][r].col = c
			for c in range(0, -shift):
				grid[c][r] = null


static func _is_column_empty(grid: Array, col: int, map_length: int) -> bool:
	if col < 0 or col >= grid.size():
		return true
	for r in map_length:
		if grid[col][r] != null:
			return false
	return true


## 对齐StS2 SpreadAdjacentMapPoints
static func _spread_adjacent(grid: Array, boss: MapData.MapNode, col_count: int, map_length: int) -> void:
	for r in map_length:
		# 收集本行节点
		var row_nodes: Array = []
		for c in col_count:
			if grid[c][r] != null:
				row_nodes.append(grid[c][r])
		var changed = true
		var attempts = 0
		while changed and attempts < 20:
			changed = false
			attempts += 1
			for node in row_nodes:
				var old_col = node.col
				var allowed = _get_allowed_positions(grid, node, boss, col_count, map_length)
				var best_col = old_col
				var best_gap = _compute_gap(old_col, row_nodes, node)
				for ac in allowed:
					if ac != old_col and (grid[ac][r] == null or grid[ac][r] == node):
						var gap = _compute_gap(ac, row_nodes, node)
						if gap > best_gap:
							best_col = ac
							best_gap = gap
				if best_col != old_col:
					grid[old_col][r] = null
					grid[best_col][r] = node
					node.col = best_col
					changed = true


## 对齐StS2 GetAllowedPositions
static func _get_allowed_positions(grid: Array, node: MapData.MapNode, boss: MapData.MapNode, col_count: int, map_length: int) -> Array:
	var allowed: Array = []
	for c in col_count:
		allowed.append(c)
	# 与所有父节点的邻居取交集
	for pid in node.parents:
		var parent = _find_point_or_boss(grid, pid, boss, col_count, map_length)
		if parent != null:
			var neighbor_allowed: Array = []
			for offset in range(-1, 2):
				var nc = parent.col + offset
				if nc >= 0 and nc < col_count:
					neighbor_allowed.append(nc)
			var intersection: Array = []
			for a in allowed:
				if a in neighbor_allowed:
					intersection.append(a)
			allowed = intersection
	# 与所有子节点的邻居取交集
	for cid in node.children:
		var child = _find_point_or_boss(grid, cid, boss, col_count, map_length)
		if child != null:
			var neighbor_allowed: Array = []
			for offset in range(-1, 2):
				var nc = child.col + offset
				if nc >= 0 and nc < col_count:
					neighbor_allowed.append(nc)
			var intersection: Array = []
			for a in allowed:
				if a in neighbor_allowed:
					intersection.append(a)
			allowed = intersection
	return allowed


static func _compute_gap(candidate_col: int, row_nodes: Array, current: MapData.MapNode) -> int:
	var min_gap = 999999
	for node in row_nodes:
		if node.id != current.id:
			min_gap = mini(min_gap, absi(candidate_col - node.col))
	return min_gap


## 对齐StS2 StraightenPaths
static func _straighten_paths(grid: Array, boss: MapData.MapNode, col_count: int, map_length: int) -> void:
	for r in map_length:
		for c in col_count:
			var node = grid[c][r]
			if node == null or node.parents.size() != 1 or node.children.size() != 1:
				continue
			var parent = _find_point_or_boss(grid, node.parents[0], boss, col_count, map_length)
			var child = _find_point_or_boss(grid, node.children[0], boss, col_count, map_length)
			if parent == null or child == null:
				continue
			# 检查是否形成zigzag(node的col在parent和child的外侧)
			var is_left_zigzag = node.col < child.col and node.col < parent.col
			var is_right_zigzag = node.col > child.col and node.col > parent.col
			if is_left_zigzag and c < col_count - 1:
				var new_col = c + 1
				if grid[new_col][r] == null:
					grid[c][r] = null
					grid[new_col][r] = node
					node.col = new_col
			elif is_right_zigzag and c > 0:
				var new_col = c - 1
				if grid[new_col][r] == null:
					grid[c][r] = null
					grid[new_col][r] = node
					node.col = new_col


# ============================================================
#  阶段5: SetEnemies
# ============================================================

static func _set_enemies(nodes: Array, config: Dictionary) -> void:
	var zones: Array = config.get("zones", [])
	var fallback_monster_pool: Array = config.get("monster_pool", ["bandit", "magic_wolf"])
	var fallback_elite_pool: Array = config.get("elite_pool", ["high_beast"])
	for node in nodes:
		if node.enemy_ids.size() > 0:
			continue
		# 根据层数查找对应区域的敌人池
		var monster_pool = fallback_monster_pool
		var elite_pool = fallback_elite_pool
		for zone in zones:
			if node.layer >= zone["floor_start"] and node.layer <= zone["floor_end"]:
				monster_pool = zone["monster_pool"]
				elite_pool = zone["elite_pool"]
				break
		match node.node_type:
			MapData.NodeType.MONSTER:
				if monster_pool.is_empty():
					continue
				# 1-2个敌人
				var count = 1 + RNGManager.map_rng.randi() % 2
				var ids: Array[String] = []
				for _i in range(count):
					var idx = RNGManager.map_rng.randi() % monster_pool.size()
					ids.append(monster_pool[idx])
				node.enemy_ids = ids
			MapData.NodeType.ELITE:
				if elite_pool.is_empty():
					continue
				var idx = RNGManager.map_rng.randi() % elite_pool.size()
				node.enemy_ids = Array([elite_pool[idx]], TYPE_STRING, "", null)


# ============================================================
#  阶段6: CalculatePositions (对齐StS2 NMapScreen.SetMap)
# ============================================================

## 对齐StS2的位置计算:
## base_offset = (-500, 740), step = (distX, -distY)
## pos = (col, row) * step + base_offset + jitter(-21..21, -25..25)
## Boss固定位置, Start固定位置
static func _calculate_positions(nodes: Array, start_node: MapData.MapNode, boss: MapData.MapNode, map_length: int, col_count: int) -> void:
	# 视口: 1280×700 (MapContainer尺寸)
	var viewport_w = 1280.0
	var total_height = 2325.0
	var dist_x = (viewport_w - 200.0) / (col_count - 1)  # 左右留100px边距
	var dist_y = total_height / (map_length - 1)

	# 居中: col=0 在左边距, col=col_count-1 在右边距
	var base_x = 100.0
	# base_y: boss在视口顶部附近,起点在视口底部附近
	# boss.y = base_y - total_height = 140 → base_y = 2465
	# 起点在底部(boss.y≈0附近),滚动可到达boss
	var base_y = total_height + 90.0

	for node in nodes:
		if node.id == boss.id or node.id == start_node.id:
			continue
		var x = node.col * dist_x + base_x
		var y = node.layer * (-dist_y) + base_y
		# 抖动(对齐StS2: +/-21, +/-25)
		if node.layer > 0 and node.layer < map_length - 1:
			x += RNGManager.map_rng.randf_range(-21.0, 21.0)
			y += RNGManager.map_rng.randf_range(-25.0, 25.0)
		node.position = Vector2(x, y)

	# Boss位置: layer=map_length-1, 在地图最上方
	boss.position = Vector2(viewport_w / 2.0, base_y - total_height - 60.0)

	# 起点位置: layer=0, 在地图最下方
	start_node.position = Vector2(viewport_w / 2.0, base_y - 20.0)


# ============================================================
#  工具方法
# ============================================================

static func _grid_get(grid: Array, col: int, row: int, col_count: int, map_length: int) -> MapData.MapNode:
	if col < 0 or col >= col_count:
		return null
	if row < 0 or row >= map_length:
		return null
	return grid[col][row]


static func _get_or_create(grid: Array, col: int, row: int, node_id: int, col_count: int, map_length: int) -> MapData.MapNode:
	var existing = _grid_get(grid, col, row, col_count, map_length)
	if existing != null:
		return existing
	var node = MapData.MapNode.new(node_id, MapData.NodeType.MONSTER, row, col)
	grid[col][row] = node
	return node


static func _has_point_at(grid: Array, col: int, row: int, col_count: int, map_length: int) -> bool:
	return _grid_get(grid, col, row, col_count, map_length) != null


static func _add_edge(parent: MapData.MapNode, child: MapData.MapNode) -> void:
	if child.id not in parent.children:
		parent.children.append(child.id)
	if parent.id not in child.parents:
		child.parents.append(parent.id)


## 在grid中查找指定id的节点(需要grid作为参数的版本)
static func _find_point_in_grid_static(grid: Array, point_id: int, col_count: int, map_length: int) -> MapData.MapNode:
	for c in col_count:
		for r in map_length:
			if grid[c][r] != null and grid[c][r].id == point_id:
				return grid[c][r]
	return null


## 查找节点: 先在grid中找，找不到则检查是否是boss
static func _find_point_or_boss(grid: Array, point_id: int, boss: MapData.MapNode, col_count: int, map_length: int) -> MapData.MapNode:
	if boss != null and boss.id == point_id:
		return boss
	return _find_point_in_grid_static(grid, point_id, col_count, map_length)


static func _find_point(grid: Array, point_id: int, col_count: int, map_length: int) -> MapData.MapNode:
	return _find_point_in_grid_static(grid, point_id, col_count, map_length)


## 向后兼容: 旧入口
static func generate_jia_ma_layer1() -> Array:
	return generate_act("jia_ma")
