## 事件27：药圃奇遇
## 触发条件：场景三随机触发
## 类型：奖励事件
class_name EventHerbGarden
extends EventModel


func _init() -> void:
	id = 27
	event_name = "药圃奇遇"
	description = "迦南学院的药圃中，一株罕见的灵药正在绽放。药老的声音在你脑海中响起。"
	category = Category.REWARD
	scene_id = 3


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：采摘灵药
	var choice_a = EventChoice.new("采摘灵药")
	choice_a.description_rich = "回复40%最大生命值。"
	choice_a.add_outcome(OutcomeType.HEAL, 40, "", "回复40%最大HP")
	choices.append(choice_a)

	# 选项B：炼制丹药
	var choice_b = EventChoice.new("炼制丹药")
	choice_b.description_rich = "获得2瓶随机高级丹药。"
	choice_b.add_outcome(OutcomeType.POTION, 2, "", "获得2瓶丹药")
	choices.append(choice_b)

	# 选项C：移植
	var choice_c = EventChoice.new("移植")
	choice_c.description_rich = "获得遗物【灵药圃】（每次休息时额外回复5点HP）。"
	choice_c.add_outcome(OutcomeType.RELIC, 0, "54", "获得灵药圃")
	choices.append(choice_c)

	return choices
