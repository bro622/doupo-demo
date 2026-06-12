## 事件41：丹塔密室
## 触发条件：场景四随机触发
## 类型：奖励事件
class_name EventPillTowerSecret
extends EventModel


func _init() -> void:
	id = 41
	event_name = "丹塔密室"
	description = "丹塔最深处的密室中，一尊远古药鼎散发着微弱的光芒。鼎内的药液仍在沸腾。"
	category = Category.REWARD
	scene_id = 4


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：取丹
	var choice_a = EventChoice.new("取丹")
	choice_a.description_rich = "获得2瓶高级丹药。"
	choice_a.add_outcome(OutcomeType.POTION, 2, "", "获得2瓶高级丹药")
	choices.append(choice_a)

	# 选项B：探索密室
	var choice_b = EventChoice.new("探索密室")
	choice_b.description_rich = "获得1个随机传说遗物。代价：失去30点生命值。"
	choice_b.add_outcome(OutcomeType.RELIC, 0, "legendary", "获得传说遗物")
	choice_b.add_outcome(OutcomeType.DAMAGE, 30, "", "受到30点伤害")
	choices.append(choice_b)

	# 选项C：离开
	var choice_c = EventChoice.new("离开")
	choice_c.description_rich = "获得100金币。"
	choice_c.add_outcome(OutcomeType.GOLD, 100, "", "获得100金币")
	choices.append(choice_c)

	return choices
