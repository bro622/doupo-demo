## 事件28：古修洞府
## 触发条件：场景三随机触发
## 类型：奖励事件
class_name EventAncientCave
extends EventModel


func _init() -> void:
	id = 28
	event_name = "古修洞府"
	description = "一处被遗忘的远古修炼洞府，里面的阵法仍在运转。"
	category = Category.REWARD
	scene_id = 3


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：修炼
	var choice_a = EventChoice.new("修炼")
	choice_a.description_rich = "获得100金币 + 本局永久+1力量。"
	choice_a.add_outcome(OutcomeType.GOLD, 100, "", "获得100金币")
	choice_a.add_outcome(OutcomeType.PERMA_STRENGTH, 1, "", "永久+1力量")
	choices.append(choice_a)

	# 选项B：探索
	var choice_b = EventChoice.new("探索")
	choice_b.description_rich = "获得1个随机遗物 + 80金币。"
	choice_b.add_outcome(OutcomeType.RELIC, 0, "random_common", "获得随机遗物")
	choice_b.add_outcome(OutcomeType.GOLD, 80, "", "获得80金币")
	choices.append(choice_b)

	# 选项C：破阵取宝
	var choice_c = EventChoice.new("破阵取宝")
	choice_c.description_rich = "失去20点生命值。获得1张随机稀有卡牌。"
	choice_c.add_outcome(OutcomeType.DAMAGE, 20, "", "受到20点伤害")
	choice_c.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choices.append(choice_c)

	return choices
