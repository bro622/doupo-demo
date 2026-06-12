## 事件30：内院禁地
## 触发条件：场景三随机触发
## 类型：风险事件
class_name EventInnerAcademyForbidden
extends EventModel


func _init() -> void:
	id = 30
	event_name = "内院禁地"
	description = "内院禁地中封印着一柄远古神兵，守卫极其森严。"
	category = Category.RISK
	scene_id = 3


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：强闯
	var choice_a = EventChoice.new("强闯")
	choice_a.description_rich = "强制精英战（禁地守卫）。胜利后获得1张随机传说卡牌。"
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "forbidden_guard_fight", "击败禁地守卫")
	choice_a.add_outcome(OutcomeType.CARD, 0, "legendary", "获得传说卡牌")
	choices.append(choice_a)

	# 选项B：贿赂守卫
	var choice_b = EventChoice.new("贿赂守卫")
	choice_b.description_rich = "花费200金币。获得1张随机稀有卡牌 + 1个随机遗物。"
	choice_b.gold_cost = 200
	choice_b.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choice_b.add_outcome(OutcomeType.RELIC, 0, "random_common", "获得随机遗物")
	choices.append(choice_b)

	# 选项C：放弃
	var choice_c = EventChoice.new("放弃")
	choice_c.description_rich = "无事发生。"
	choices.append(choice_c)

	return choices
