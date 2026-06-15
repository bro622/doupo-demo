## 事件37：远古傀儡守卫
## 触发条件：场景四随机触发
## 类型：战斗事件
class_name EventAncientPuppet
extends EventModel


func _init() -> void:
	id = 37
	event_name = "远古傀儡守卫"
	description = "古帝洞府入口，一尊远古傀儡矗立在通道中央。万年过去，它仍在执行守护指令。"
	category = Category.COMBAT
	scene_id = 4


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：强攻
	var choice_a = EventChoice.new("强攻")
	choice_a.description_rich = "强制战斗（远古傀儡）。胜利后获得250金币 + 遗物【天妖傀】。"
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "ancient_puppet_fight", "击败远古傀儡")
	choice_a.add_outcome(OutcomeType.GOLD, 250, "", "获得250金币")
	choice_a.add_outcome(OutcomeType.RELIC, 0, "35", "获得天妖傀")
	choices.append(choice_a)

	# 选项B：寻找弱点
	var choice_b = EventChoice.new("寻找弱点")
	choice_b.description_rich = "搜寻弱点时受创（-10HP）。强制战斗。胜利后获得200金币。"
	choice_b.add_outcome(OutcomeType.DAMAGE, 10, "", "受到10点伤害")
	choice_b.add_outcome(OutcomeType.COMBAT, 0, "ancient_puppet_fight", "击败削弱的傀儡")
	choice_b.add_outcome(OutcomeType.GOLD, 200, "", "获得200金币")
	choices.append(choice_b)

	# 选项C：绕道
	var choice_c = EventChoice.new("绕道")
	choice_c.description_rich = "失去8点生命值（崎岖山路）。"
	choice_c.add_outcome(OutcomeType.DAMAGE, 8, "", "受到8点伤害")
	choices.append(choice_c)

	return choices
