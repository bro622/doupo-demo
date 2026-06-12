## 事件13：暗巷中的神秘商人
## 触发条件：场景二随机触发
## 类型：剧情事件
class_name EventMysteryMerchant
extends EventModel


func _init() -> void:
	id = 13
	event_name = "暗巷中的神秘商人"
	description = "一个神秘的商人在暗巷中向你招手，他的斗篷下藏着各种奇异物品。"
	category = Category.PLOT
	scene_id = 2


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：花费100金币购买诅咒护符
	var choice_a = EventChoice.new("购买诅咒护符")
	choice_a.description_rich = "花费100金币获得遗物【诅咒护符】（每场战斗开始时移除手牌中1张诅咒牌）。"
	choice_a.gold_cost = 100
	choice_a.add_outcome(OutcomeType.RELIC, 0, "53", "获得诅咒护符")
	choices.append(choice_a)

	# 选项B：失去10点最大HP，获得随机稀有卡牌
	var choice_b = EventChoice.new("以命换牌")
	choice_b.description_rich = "永久失去10点最大HP，获得1张随机稀有卡牌。"
	choice_b.add_outcome(OutcomeType.MAX_HP, -10, "", "永久失去10点最大HP")
	choice_b.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choices.append(choice_b)

	# 选项C：离开
	var choice_c = EventChoice.new("离开")
	choice_c.description_rich = "安全离开暗巷。"
	choices.append(choice_c)

	return choices
