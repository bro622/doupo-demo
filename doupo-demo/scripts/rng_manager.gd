## RNG管理器（AutoLoad单例）
## 5个独立种子通道，确保所有随机行为可复现
## 参考StS2：单一run_seed派生所有通道，checkpoint保存/恢复各通道state
extends Node

## 5个独立RNG通道
var shuffle_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var monster_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var event_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var map_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var drop_rng: RandomNumberGenerator = RandomNumberGenerator.new()

## 当前运行种子（用于restore时重新派生通道种子）
var current_seed: int = 0

## 通道名常量
const CHANNEL_NAMES: Array[String] = ["shuffle", "monster", "event", "map", "drop"]


## 初始化新运行 —— 从此刻起，所有随机由种子锁死
func init_new_run(run_seed: int) -> void:
	current_seed = run_seed
	print("[RNGManager] === 新运行初始化 === 种子: ", run_seed)
	# 每个通道用 hash(种子+通道名) 作为独立种子，确保通道间互不干扰
	shuffle_rng.seed = hash(str(run_seed) + "shuffle")
	monster_rng.seed = hash(str(run_seed) + "monster")
	event_rng.seed = hash(str(run_seed) + "event")
	map_rng.seed = hash(str(run_seed) + "map")
	drop_rng.seed = hash(str(run_seed) + "drop")
	# 打印初始状态，用于调试验证
	print("[RNGManager] 通道初始状态 -> shuffle:%s  monster:%s  event:%s  map:%s  drop:%s" % [
		shuffle_rng.state, monster_rng.state, event_rng.state, map_rng.state, drop_rng.state
	])


## 获取所有通道状态（用于checkpoint快照）
func get_rng_states() -> Dictionary:
	return {
		# str() 保护大整数在JSON中不变浮点数
		"current_seed": str(current_seed),
		"shuffle_state": str(shuffle_rng.state),
		"monster_state": str(monster_rng.state),
		"event_state": str(event_rng.state),
		"map_state": str(map_rng.state),
		"drop_state": str(drop_rng.state),
	}


## 恢复所有通道状态（从checkpoint恢复）
## 【关键】必须先设seed再设state！设seed会重置state，顺序不能反！
func restore_rng_states(data: Dictionary) -> void:
	var saved_seed = int(data.get("current_seed", current_seed))
	current_seed = saved_seed

	# 第一步：重新派生种子（重置内部状态）
	shuffle_rng.seed = hash(str(saved_seed) + "shuffle")
	monster_rng.seed = hash(str(saved_seed) + "monster")
	event_rng.seed = hash(str(saved_seed) + "event")
	map_rng.seed = hash(str(saved_seed) + "map")
	drop_rng.seed = hash(str(saved_seed) + "drop")

	# 第二步：恢复state（int()还原JSON中可能被降级的浮点数）
	shuffle_rng.state = int(data.get("shuffle_state", shuffle_rng.state))
	monster_rng.state = int(data.get("monster_state", monster_rng.state))
	event_rng.state = int(data.get("event_state", event_rng.state))
	map_rng.state = int(data.get("map_state", map_rng.state))
	drop_rng.state = int(data.get("drop_state", drop_rng.state))

	print("[RNG读档] 恢复Seed: ", saved_seed, " | 洗牌状态: ", shuffle_rng.state,
		  "  怪物状态: ", monster_rng.state, "  事件状态: ", event_rng.state,
		  "  地图状态: ", map_rng.state, "  掉落状态: ", drop_rng.state)


## Fisher-Yates洗牌 —— 原位洗牌，返回自身引用方便链式调用
## 必须使用shuffle_rng通道，确保洗牌序列可复现
func shuffle_deck_in_place(deck: Array) -> void:
	print("[洗牌开始] 当前洗牌通道状态: ", shuffle_rng.state, " | 牌组大小: ", deck.size())
	for i in range(deck.size() - 1, 0, -1):
		var j = shuffle_rng.randi_range(0, i)
		var temp = deck[i]
		deck[i] = deck[j]
		deck[j] = temp
	print("[洗牌结束] 洗牌后通道状态: ", shuffle_rng.state)


## Fisher-Yates洗牌 —— 返回新数组副本，不修改原数组
func shuffle_deck(deck: Array) -> Array:
	var result = deck.duplicate()
	shuffle_deck_in_place(result)
	return result
