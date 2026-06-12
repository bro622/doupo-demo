## 事件42：古帝残魂
## 触发条件：场景四，事件链「古帝之谜」强制触发
## 前置：场景三萧炎专属事件「岩浆世界入口」选项A
## 类型：风险事件（隐藏Boss）
class_name EventAncientEmperorSoul
extends EventModel


func _init() -> void:
	id = 42
	event_name = "古帝残魂"
	description = "一道远古的残魂出现在你面前，它是斗帝留下的最后一丝意志。"
	category = Category.RISK
	scene_id = 4
	required_flag = "ancient_emperor"
	is_forced = true


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：接受考验 → 隐藏Boss战
	var choice_a = EventChoice.new("接受考验")
	choice_a.description_rich = "隐藏Boss战（古帝残魂，3阶段）。胜利后获得传说遗物【古帝残魂碎片】。"
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "ancient_emperor_soul", "与古帝残魂交战")
	choice_a.add_outcome(OutcomeType.RELIC, 0, "58", "获得古帝残魂碎片")
	choices.append(choice_a)

	# 选项B：汲取残魂
	var choice_b = EventChoice.new("汲取残魂")
	choice_b.description_rich = "失去30点最大生命值（永久）。获得1张传说卡牌 + 永久+3力量。"
	choice_b.add_outcome(OutcomeType.MAX_HP, -30, "", "最大HP-30")
	choice_b.add_outcome(OutcomeType.CARD, 0, "legendary", "获得传说卡牌")
	choice_b.add_outcome(OutcomeType.PERMA_STRENGTH, 3, "", "永久+3力量")
	choices.append(choice_b)

	# 选项C：敬而远之
	var choice_c = EventChoice.new("敬而远之")
	choice_c.description_rich = "获得100金币。安全离开。"
	choice_c.add_outcome(OutcomeType.GOLD, 100, "", "获得100金币")
	choices.append(choice_c)

	return choices
