## 事件6：塔戈尔沙漠劫匪
## 触发条件：场景一随机触发
## 类型：战斗事件
class_name EventDesertBandit
extends EventModel


func _init() -> void:
	id = 6
	event_name = "塔戈尔沙漠劫匪"
	description = "在塔戈尔沙漠中遭遇一伙劫匪，他们拦住了你的去路。"
	category = Category.COMBAT
	scene_id = 1


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：正面歼灭
	var choice_a = EventChoice.new("正面歼灭")
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "desert_bandit", "与劫匪战斗！")
	choice_a.add_outcome(OutcomeType.POTION, 1, "1", "获得1瓶回气散")
	choice_a.add_outcome(OutcomeType.GOLD, 100, "", "获得100金币")
	choices.append(choice_a)

	# 选项B：交钱买路
	var choice_b = EventChoice.new("交钱买路")
	choice_b.description_rich = "花费80金币平安通过。"
	choice_b.gold_cost = 80
	choices.append(choice_b)

	# 选项C：反抢
	var choice_c = EventChoice.new("反抢")
	choice_c.add_outcome(OutcomeType.COMBAT, 0, "desert_bandit_hard", "与劫匪精锐战斗！")
	choice_c.add_outcome(OutcomeType.GOLD, 200, "", "获得200金币")
	choice_c.add_outcome(OutcomeType.POTION, 1, "", "获得1瓶丹药")
	choices.append(choice_c)

	return choices
