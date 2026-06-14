## 事件35：天府联盟成立
## 触发条件：场景四随机触发
## 类型：剧情事件
class_name EventAlliance
extends EventModel


func _init() -> void:
	id = 35
	event_name = "天府联盟成立"
	description = "各方势力齐聚，商讨对抗魂殿的大计。众人推举你为联盟盟主。"
	category = Category.PLOT
	scene_id = 4


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：担任盟主
	var choice_a = EventChoice.new("担任盟主")
	choice_a.description_rich = "获得遗物【大长老手令】（进入休息点自动回复15HP）。设置联盟集结标记。"
	choice_a.add_outcome(OutcomeType.RELIC, 0, "42", "获得大长老手令")
	choice_a.add_outcome(OutcomeType.FLAG, 0, "alliance_formed", "联盟集结")
	choices.append(choice_a)

	# 选项B：推举他人
	var choice_b = EventChoice.new("推举他人")
	choice_b.description_rich = "获得200金币 + 1瓶高级丹药。"
	choice_b.add_outcome(OutcomeType.GOLD, 200, "", "获得200金币")
	choice_b.add_outcome(OutcomeType.POTION, 1, "", "获得高级丹药")
	choices.append(choice_b)

	# 选项C：独行
	var choice_c = EventChoice.new("独行")
	choice_c.description_rich = "获得1张随机传说卡牌。"
	choice_c.add_outcome(OutcomeType.CARD, 0, "legendary", "获得传说卡牌")
	choices.append(choice_c)

	return choices
