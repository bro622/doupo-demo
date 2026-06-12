## 事件18：走私商人
## 触发条件：场景二随机触发
## 类型：奖励事件
class_name EventSmuggler
extends EventModel


func _init() -> void:
	id = 18
	event_name = "走私商人"
	description = "一个鬼鬼祟祟的走私商人向你展示他的货物。"
	category = Category.REWARD
	scene_id = 2


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：花费80金币购买3个随机药水
	var choice_a = EventChoice.new("购买药水")
	choice_a.description_rich = "花费80金币，获得3个随机药水。"
	choice_a.gold_cost = 80
	choice_a.add_outcome(OutcomeType.POTION, 3, "", "获得3个药水")
	choices.append(choice_a)

	# 选项B：花费120金币购买随机稀有卡牌
	var choice_b = EventChoice.new("购买秘典")
	choice_b.description_rich = "花费120金币，获得1张随机稀有卡牌。"
	choice_b.gold_cost = 120
	choice_b.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choices.append(choice_b)

	# 选项C：离开
	var choice_c = EventChoice.new("离开")
	choice_c.description_rich = "安全离开。"
	choices.append(choice_c)

	return choices
