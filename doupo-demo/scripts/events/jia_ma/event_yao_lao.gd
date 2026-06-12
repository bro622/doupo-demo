## 事件9：药老的炼药指导
## 触发条件：场景一随机触发（萧炎专属）
## 类型：奖励事件
class_name EventYaoLao
extends EventModel


func _init() -> void:
	id = 9
	event_name = "药老的炼药指导"
	description = "药尘药尊难得有兴致指导你的修炼，你希望向他学习什么？"
	category = Category.REWARD
	scene_id = 1
	character_id = "xiaoyan"


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：学习炼药术
	var choice_a = EventChoice.new("学习炼药术")
	choice_a.add_outcome(OutcomeType.RELIC, 0, "4", "获得遗物「炼药笔记」：休息点升级卡牌时额外获得1瓶丹药")
	choices.append(choice_a)

	# 选项B：请教战斗技巧
	var choice_b = EventChoice.new("请教战斗技巧")
	choice_b.add_outcome(OutcomeType.UPGRADE_CARD, 1, "", "随机升级1张卡牌")
	choices.append(choice_b)

	# 选项C：询问异火知识
	var choice_c = EventChoice.new("询问异火知识")
	choice_c.add_outcome(OutcomeType.CARD, 0, "fire_control", "获得卡牌「控火决」")
	choices.append(choice_c)

	return choices
