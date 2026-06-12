## 事件19：炼药师的遗迹
## 触发条件：场景二随机触发
## 类型：奖励事件
class_name EventAlchemistRuins
extends EventModel


func _init() -> void:
	id = 19
	event_name = "炼药师的遗迹"
	description = "一座古老的炼药师遗迹出现在你面前，里面似乎还残留着丹药的气息。"
	category = Category.REWARD
	scene_id = 2


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：回复30%最大HP
	var choice_a = EventChoice.new("炼丹调息")
	choice_a.description_rich = "利用遗迹中的丹药气息调息，回复30%最大HP。"
	choice_a.add_outcome(OutcomeType.HEAL, 30, "", "回复30%最大HP")
	choices.append(choice_a)

	# 选项B：获得1个随机普通遗物
	var choice_b = EventChoice.new("搜刮遗物")
	choice_b.description_rich = "在遗迹中搜刮，获得1个随机普通遗物。"
	choice_b.add_outcome(OutcomeType.RELIC, 0, "random_common", "获得普通遗物")
	choices.append(choice_b)

	# 选项C：失去30点生命值，获得高级药水
	var choice_c = EventChoice.new("炼制秘药")
	choice_c.description_rich = "消耗精血炼制秘药。失去30点生命值，获得高级药水。"
	choice_c.add_outcome(OutcomeType.DAMAGE, 30, "", "消耗精血，失去30点生命值")
	choice_c.add_outcome(OutcomeType.POTION, 1, "", "获得高级药水")
	choices.append(choice_c)

	return choices
