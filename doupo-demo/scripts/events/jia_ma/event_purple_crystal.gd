## 事件3：魔兽山脉的紫晶洞府
## 触发条件：场景一随机触发（萧炎专属）
## 类型：剧情事件
class_name EventPurpleCrystal
extends EventModel


func _init() -> void:
	id = 3
	event_name = "魔兽山脉的紫晶洞府"
	description = "你在魔兽山脉深处发现了一个紫晶洞府，洞内紫晶能量浓郁，似乎蕴含着强大的火属性力量。"
	category = Category.PLOT
	scene_id = 1
	character_id = "xiaoyan"


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：运转焚诀吞噬
	var choice_a = EventChoice.new("运转焚诀吞噬")
	choice_a.add_outcome(OutcomeType.CARD, 0, "fire_combo", "领悟「异火连击」")
	choice_a.add_outcome(OutcomeType.CURSE_CARD, 0, "beast_backlash", "吞噬过程中受到兽性反噬...")
	choices.append(choice_a)

	# 选项B：小心刮取紫晶源
	var choice_b = EventChoice.new("小心刮取紫晶源")
	choice_b.add_outcome(OutcomeType.RELIC, 0, "52", "获得遗物「紫晶源」：异火槽满载时回复2HP")
	choice_b.add_outcome(OutcomeType.DAMAGE, 12, "", "紫晶能量灼伤，受到12点伤害")
	choices.append(choice_b)

	# 选项C：悄然退走
	var choice_c = EventChoice.new("悄然退走")
	choice_c.description_rich = "放弃探索，安全离开。"
	choices.append(choice_c)

	return choices
