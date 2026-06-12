## 事件8：米特尔拍卖行
## 触发条件：场景一随机触发
## 类型：奖励事件
class_name EventAuction
extends EventModel


func _init() -> void:
	id = 8
	event_name = "米特尔拍卖行"
	description = "米特尔拍卖行正在举行拍卖会，各种珍品琳琅满目。你可以选择竞拍或闲逛。"
	category = Category.REWARD
	scene_id = 1


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：浏览丹药
	var choice_a = EventChoice.new("浏览丹药")
	choice_a.gold_cost = 60
	choice_a.add_outcome(OutcomeType.POTION, 2, "", "购买2瓶丹药")
	choices.append(choice_a)

	# 选项B：浏览卡牌
	var choice_b = EventChoice.new("浏览卡牌")
	choice_b.gold_cost = 100
	choice_b.add_outcome(OutcomeType.CARD, 0, "rare", "购买1张稀有卡牌")
	choices.append(choice_b)

	# 选项C：闲逛离开
	var choice_c = EventChoice.new("闲逛离开")
	choice_c.add_outcome(OutcomeType.GOLD, 30, "", "捡到30金币")
	choices.append(choice_c)

	return choices
