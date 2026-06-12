## 事件43：魂天帝的阴谋
## 触发条件：场景四随机触发
## 类型：风险事件
class_name EventHuntiandiPlot
extends EventModel


func _init() -> void:
	id = 43
	event_name = "魂天帝的阴谋"
	description = "魂天帝的声音在虚空中回荡——你以为你能阻止我？"
	category = Category.RISK
	scene_id = 4


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：以命换命
	var choice_a = EventChoice.new("以命换命")
	choice_a.description_rich = "失去15点最大生命值（永久）。最终Boss魂天帝HP-100。"
	choice_a.add_outcome(OutcomeType.MAX_HP, -15, "", "最大HP-15")
	choice_a.add_outcome(OutcomeType.FLAG, 0, "huntiandi_hp_reduced", "魂天帝HP-100")
	choices.append(choice_a)

	# 选项B：献祭遗物
	var choice_b = EventChoice.new("以魂铸甲")
	choice_b.description_rich = "以灵魂之力布下结界。最终Boss魂天帝力量-2。"
	choice_b.add_outcome(OutcomeType.FLAG, 0, "huntiandi_strength_reduced", "魂天帝力量-2")
	choices.append(choice_b)

	# 选项C：正面决战
	var choice_c = EventChoice.new("正面决战")
	choice_c.description_rich = "无增益无减益。面对完整的魂天帝。"
	choices.append(choice_c)

	return choices
