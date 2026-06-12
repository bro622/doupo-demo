## 事件38：古族试炼
## 触发条件：场景四随机触发
## 类型：战斗事件
class_name EventAncientTrial
extends EventModel


func _init() -> void:
	id = 38
	event_name = "古族试炼"
	description = "古帝洞府中，一道远古意志降临——古族战士的虚影出现在你面前。"
	category = Category.COMBAT
	scene_id = 4


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：接受试炼
	var choice_a = EventChoice.new("接受试炼")
	choice_a.description_rich = "强制战斗（2个古族战士）。胜利后获得300金币 + 永久+2力量 + 1张稀有卡牌。"
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "ancient_clan_trial_fight", "通过古族试炼")
	choice_a.add_outcome(OutcomeType.GOLD, 300, "", "获得300金币")
	choice_a.add_outcome(OutcomeType.PERMA_STRENGTH, 2, "", "永久+2力量")
	choice_a.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choices.append(choice_a)

	# 选项B：献祭精血
	var choice_b = EventChoice.new("献祭精血")
	choice_b.description_rich = "失去25点生命值。跳过试炼，获得200金币 + 1个随机遗物。"
	choice_b.add_outcome(OutcomeType.DAMAGE, 25, "", "受到25点伤害")
	choice_b.add_outcome(OutcomeType.GOLD, 200, "", "获得200金币")
	choice_b.add_outcome(OutcomeType.RELIC, 0, "random_common", "获得随机遗物")
	choices.append(choice_b)

	# 选项C：放弃
	var choice_c = EventChoice.new("放弃")
	choice_c.description_rich = "无事发生。"
	choices.append(choice_c)

	return choices
