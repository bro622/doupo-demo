## 事件39：灵魂风暴
## 触发条件：场景四随机触发
## 类型：战斗事件
class_name EventSoulStorm
extends EventModel


func _init() -> void:
	id = 39
	event_name = "灵魂风暴"
	description = "一场灵魂风暴席卷了整个区域，无数灵魂虚影在风暴中嘶吼。"
	category = Category.COMBAT
	scene_id = 4


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：穿越风暴
	var choice_a = EventChoice.new("穿越风暴")
	choice_a.description_rich = "强制战斗（3个灵魂虚影）。胜利后获得350金币 + 遗物【星陨护心令】。"
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "soul_storm_fight", "穿越灵魂风暴")
	choice_a.add_outcome(OutcomeType.GOLD, 350, "", "获得350金币")
	choice_a.add_outcome(OutcomeType.RELIC, 0, "34", "获得星陨护心令")
	choices.append(choice_a)

	# 选项B：等待风暴过去
	var choice_b = EventChoice.new("等待风暴过去")
	choice_b.description_rich = "失去10点生命值（风暴余波）。获得50金币。"
	choice_b.add_outcome(OutcomeType.DAMAGE, 10, "", "受到10点伤害")
	choice_b.add_outcome(OutcomeType.GOLD, 50, "", "获得50金币")
	choices.append(choice_b)

	# 选项C：汲取灵魂能量
	var choice_c = EventChoice.new("汲取灵魂能量")
	choice_c.description_rich = "失去30点最大生命值（永久）。获得1张随机传说卡牌。"
	choice_c.add_outcome(OutcomeType.MAX_HP, -30, "", "最大HP-30")
	choice_c.add_outcome(OutcomeType.CARD, 0, "legendary", "获得传说卡牌")
	choices.append(choice_c)

	return choices
