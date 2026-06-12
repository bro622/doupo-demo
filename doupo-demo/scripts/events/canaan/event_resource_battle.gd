## 事件26：修炼资源争夺
## 触发条件：场景三随机触发
## 类型：战斗事件
class_name EventResourceBattle
extends EventModel


func _init() -> void:
	id = 26
	event_name = "修炼资源争夺"
	description = "内院深处发现了一处远古修炼密室，里面蕴含着浓郁的天地能量。"
	category = Category.COMBAT
	scene_id = 3


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：强夺
	var choice_a = EventChoice.new("强夺")
	choice_a.description_rich = "强制战斗（2个内院精英弟子）。胜利后获得200金币 + 1瓶高级丹药。"
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "resource_battle", "击败内院弟子")
	choice_a.add_outcome(OutcomeType.GOLD, 200, "", "获得200金币")
	choice_a.add_outcome(OutcomeType.POTION, 1, "", "获得高级丹药")
	choices.append(choice_a)

	# 选项B：协商分配
	var choice_b = EventChoice.new("协商分配")
	choice_b.description_rich = "获得150金币。"
	choice_b.add_outcome(OutcomeType.GOLD, 150, "", "获得150金币")
	choices.append(choice_b)

	# 选项C：放弃
	var choice_c = EventChoice.new("放弃")
	choice_c.description_rich = "获得30金币（心境提升）。"
	choice_c.add_outcome(OutcomeType.GOLD, 30, "", "获得30金币")
	choices.append(choice_c)

	return choices
