## 玩家数据管理器（AutoLoad单例）
## 管理所有玩家相关持久数据：HP、金币、卡组、遗物、药水
## 从RunState中剥离，提供标准化的 get_save_data/restore_data 接口
extends Node

## 信号：任何显示属性变化时发射（顶栏UI监听）
signal stats_changed

## 玩家身份
var selected_character: String = "xiaoyan"  # 角色选择界面设置
var character_id: String = "xiaoyan"
var player_name: String = "萧炎"
var max_hp: int = 75
var hp: int = 75
var gold: int = 99

## 当前卡组（跨节点持久化）
var deck: Array[CardData] = []

## 战斗初始牌序（用于重启战斗时恢复相同顺序）
var initial_deck_order: Array[CardData] = []

## 战斗开始时洗牌后的牌库（用于重启时恢复完全相同的牌序）
var battle_start_draw_pile: Array[CardData] = []

## 战斗开始前的HP（用于重启时恢复）
var battle_start_hp: int = 0

## 遗物
var relics: Array[RelicData] = []

## 药水背包
var potions: Array[PotionData] = []
var max_potion_slots: int = 3

## 移卡次数（影响商店移除价格）
var card_removals: int = 0

## 战斗胜利次数（用于每N场触发的遗物）
var battle_wins: int = 0


## ============================================================
##  运行生命周期
## ============================================================

## 初始化新运行
func start_new_run() -> void:
	character_id = selected_character
	# 根据角色设置属性
	match character_id:
		"xiaoyan":
			player_name = "萧炎"
			max_hp = 75
		"xuner":
			player_name = "萧薰儿"
			max_hp = 65
		"cailin":
			player_name = "美杜莎"
			max_hp = 70
		_:
			player_name = "萧炎"
			max_hp = 75
	hp = max_hp
	gold = 99
	card_removals = 0
	battle_wins = 0
	relics.clear()
	potions.clear()
	max_potion_slots = 3
	deck.clear()
	initial_deck_order.clear()
	battle_start_draw_pile.clear()
	var starter = CardDatabase.create_starter_deck_for_character(character_id)
	for card in starter:
		deck.append(card.duplicate_card())
	# 初始遗物（根据角色）
	var start_relic_id = _get_starter_relic_id(character_id)
	var start_relic = RelicDatabase.get_relic(start_relic_id)
	if start_relic != null:
		add_relic(start_relic)
	print("[PlayerManager] 新运行初始化完成 - %s HP:%d/%d 金币:%d 卡组:%d张 遗物:%d个" % [player_name, hp, max_hp, gold, deck.size(), relics.size()])


## 获取角色初始遗物ID
static func _get_starter_relic_id(char_id: String) -> int:
	match char_id:
		"xiaoyan": return 1   # 骨炎戒
		"xuner": return 2     # 古族金令
		"cailin": return 3    # 七彩蛇鳞
		_: return 1


## ============================================================
##  资源管理
## ============================================================

## 恢复HP
func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)
	stats_changed.emit()


## 扣除金币
func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	stats_changed.emit()
	return true


## 增加金币
func add_gold(amount: int) -> void:
	gold += amount
	stats_changed.emit()


## 设置HP（战斗同步、事件伤害等直接赋值场景）
func set_hp(value: int) -> void:
	hp = value
	stats_changed.emit()


## 修改最大HP（事件、遗物等场景）
func modify_max_hp(amount: int) -> void:
	max_hp += amount
	hp += amount
	stats_changed.emit()


## ============================================================
##  卡组管理
## ============================================================

## 添加卡牌到卡组
func add_card_to_deck(card: CardData) -> void:
	deck.append(card.duplicate_card())
	stats_changed.emit()


## 移除卡牌（从卡组）
func remove_card_from_deck(index: int) -> bool:
	if index < 0 or index >= deck.size():
		return false
	deck.remove_at(index)
	card_removals += 1
	stats_changed.emit()
	return true


## 获取移除卡牌的费用
func get_card_removal_cost() -> int:
	return 75 + 25 * card_removals


## ============================================================
##  遗物管理
## ============================================================

## 添加遗物（防重复）
func add_relic(relic: RelicData) -> void:
	if has_relic(relic.id):
		return
	relics.append(relic)
	# 一次性效果：最大HP增加
	if relic.effect_type == RelicData.EffectType.MAX_HP_FLAT:
		modify_max_hp(relic.effect_value)
	# 一次性效果：额外最大HP（如山岳之心）
	if relic.bonus_max_hp > 0:
		modify_max_hp(relic.bonus_max_hp)
	# 陀舍古帝玉碎片 (#36)：获得时额外+100金币、升级3张随机牌
	if relic.id == 36:
		add_gold(100)
		var upgradeable: Array[CardData] = []
		for card in deck:
			if not card.upgraded:
				upgradeable.append(card)
		for _i in range(mini(3, upgradeable.size())):
			var idx = randi() % upgradeable.size()
			upgradeable[idx].apply_upgrade()
			upgradeable.remove_at(idx)
	stats_changed.emit()


## 是否拥有指定遗物
func has_relic(id: int) -> bool:
	for r in relics:
		if r.id == id:
			return true
	return false


## 移除指定遗物
func remove_relic(id: int) -> void:
	for i in range(relics.size()):
		if relics[i].id == id:
			var relic = relics[i]
			# FIX: [Bug 8] 对称剥离一次性特殊属性，防止幽灵属性永久累加
			if relic.effect_type == RelicData.EffectType.MAX_HP_FLAT:
				modify_max_hp(-relic.effect_value)
			if relic.bonus_max_hp > 0:
				modify_max_hp(-relic.bonus_max_hp)
			relics.remove_at(i)
			stats_changed.emit()
			return


## 获取所有遗物
func get_relics() -> Array[RelicData]:
	return relics


## ============================================================
##  药水管理
## ============================================================

## 添加药水（满了返回false；万兽鼎：满时炼化为最大HP）
func add_potion(potion: PotionData) -> bool:
	if potions.size() >= max_potion_slots:
		# 万兽鼎：丹药溢出时炼化为最大HP
		for relic in relics:
			if relic.effect_type == RelicData.EffectType.POTION_OVERFLOW_REFINE_HP:
				max_hp += relic.effect_value
				hp += relic.effect_value
				stats_changed.emit()
				return false  # 药水未添加，但触发了炼化
		return false
	potions.append(potion)
	stats_changed.emit()
	return true


## 移除药水
func remove_potion(index: int) -> void:
	if index >= 0 and index < potions.size():
		potions.remove_at(index)
		stats_changed.emit()


## ============================================================
##  序列化（get_save_data / restore_data）
## ============================================================

## 导出所有玩家数据为JSON安全字典
func get_save_data() -> Dictionary:
	return {
		"selected_character": selected_character,
		"character_id": character_id,
		"player_name": player_name,
		"hp": hp,
		"max_hp": max_hp,
		"gold": gold,
		"deck": _serialize_cards(deck),
		"initial_deck_order": _serialize_cards(initial_deck_order),
		"battle_start_draw_pile": _serialize_cards(battle_start_draw_pile),
		"relics": _serialize_relic_ids(relics),
		"potions": _serialize_potion_ids(potions),
		"max_potion_slots": max_potion_slots,
		"card_removals": card_removals,
		"battle_wins": battle_wins,
	}


## 从字典恢复所有玩家数据
func restore_data(data: Dictionary) -> void:
	selected_character = data.get("selected_character", "xiaoyan")
	character_id = data.get("character_id", "xiaoyan")
	player_name = data.get("player_name", "萧炎")
	hp = data.get("hp", 75)
	max_hp = data.get("max_hp", 75)
	gold = data.get("gold", 99)
	deck = _deserialize_cards(data.get("deck", []))
	initial_deck_order = _deserialize_cards(data.get("initial_deck_order", []))
	battle_start_draw_pile = _deserialize_cards(data.get("battle_start_draw_pile", []))
	relics = _deserialize_relic_ids(data.get("relics", []))
	potions = _deserialize_potion_ids(data.get("potions", []))
	max_potion_slots = data.get("max_potion_slots", 3)
	card_removals = data.get("card_removals", 0)
	battle_wins = data.get("battle_wins", 0)


## ============================================================
##  序列化辅助方法
## ============================================================

func _serialize_cards(cards: Array[CardData]) -> Array:
	var result = []
	for card in cards:
		result.append(card.to_dict())
	return result


func _deserialize_cards(arr: Array) -> Array[CardData]:
	var result: Array[CardData] = []
	for d in arr:
		if not d is Dictionary:
			continue
		result.append(CardData.from_dict(d))
	return result


func _serialize_relic_ids(rels: Array[RelicData]) -> Array:
	var result = []
	for relic in rels:
		result.append(relic.id)
	return result


func _deserialize_relic_ids(arr: Array) -> Array[RelicData]:
	var result: Array[RelicData] = []
	for id_val in arr:
		var id = int(id_val)
		var relic = RelicDatabase.get_relic(id)
		if relic != null:
			result.append(relic)
		else:
			push_warning("PlayerManager: 未知遗物ID=%d，已跳过" % id)
	return result


func _serialize_potion_ids(pots: Array[PotionData]) -> Array:
	var result = []
	for potion in pots:
		result.append(potion.id)
	return result


func _deserialize_potion_ids(arr: Array) -> Array[PotionData]:
	var result: Array[PotionData] = []
	for id_val in arr:
		var id = int(id_val)
		var potion = PotionDatabase.get_potion(id)
		if potion != null:
			result.append(potion)
		else:
			push_warning("PlayerManager: 未知药水ID=%d，已跳过" % id)
	return result
