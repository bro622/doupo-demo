## 事件17：天蛇府暗哨
## 触发条件：场景二随机触发
## 类型：战斗事件
class_name EventSerpentOutpost
extends EventModel


func _init() -> void:
	id = 17
	event_name = "天蛇府暗哨"
	description = "天蛇府的暗哨隐藏在毒雾弥漫的枫城深处。"
	category = Category.COMBAT
	scene_id = 2


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：战斗2个天蛇府刺客+1个精锐刺客，胜利获得200金币+高级药水
	var choice_a = EventChoice.new("突袭暗哨")
	choice_a.description_rich = "与天蛇府刺客和精锐刺客战斗。胜利获得200金币+高级药水。"
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "serpent_ambush", "击退天蛇府")
	choice_a.add_outcome(OutcomeType.GOLD, 200, "", "获得200金币")
	choice_a.add_outcome(OutcomeType.POTION, 1, "", "获得高级药水")
	choices.append(choice_a)

	# 选项B：失去10HP，获得150金币+随机卡牌
	var choice_b = EventChoice.new("潜入侦察")
	choice_b.description_rich = "受到10点伤害，获得150金币+1张随机卡牌。"
	choice_b.add_outcome(OutcomeType.DAMAGE, 10, "", "被毒蛇咬伤，受到10点伤害")
	choice_b.add_outcome(OutcomeType.GOLD, 150, "", "获得150金币")
	choice_b.add_outcome(OutcomeType.CARD, 0, "", "获得随机卡牌")
	choices.append(choice_b)

	# 选项C：离开
	var choice_c = EventChoice.new("离开")
	choice_c.description_rich = "安全离开天蛇府暗哨。"
	choices.append(choice_c)

	return choices
