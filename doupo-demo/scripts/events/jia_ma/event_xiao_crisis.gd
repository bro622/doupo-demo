## 事件5：萧家危机
## 触发条件：场景一随机触发
## 类型：战斗事件
class_name EventXiaoCrisis
extends EventModel


func _init() -> void:
	id = 5
	event_name = "萧家危机"
	description = "萧家遭到不明势力袭击，情况危急。你必须做出选择。"
	category = Category.COMBAT
	scene_id = 1


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：挺身而出
	var choice_a = EventChoice.new("挺身而出")
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "xiao_raider", "与袭击者战斗！")
	choice_a.add_outcome(OutcomeType.RELIC, 0, "5", "战斗胜利后获得遗物「萧家族徽」")
	choice_a.add_outcome(OutcomeType.GOLD, 100, "", "获得100金币")
	choices.append(choice_a)

	# 选项B：暗中解决
	var choice_b = EventChoice.new("暗中解决")
	choice_b.add_outcome(OutcomeType.DAMAGE, 8, "", "暗中交手受到8点伤害")
	choice_b.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choices.append(choice_b)

	# 选项C：寻求外援
	var choice_c = EventChoice.new("寻求外援")
	choice_c.add_outcome(OutcomeType.GOLD, 80, "", "获得80金币援助")
	choice_c.add_outcome(OutcomeType.CURSE_CARD, 0, "xiao_family_shame", "萧家耻辱洗入牌库...")
	choices.append(choice_c)

	return choices
