## 事件36：魂殿尊老伏击
## 触发条件：场景四随机触发
## 类型：战斗事件
class_name EventSoulEldersAmbush
extends EventModel


func _init() -> void:
	id = 36
	event_name = "魂殿尊老伏击"
	description = "四位魂殿尊老挡住了你的去路。他们的灵魂力量扭曲了周围的空间。"
	category = Category.COMBAT
	scene_id = 4


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：正面迎战
	var choice_a = EventChoice.new("正面迎战")
	choice_a.description_rich = "强制精英战（魂殿四大尊老，4v1）。胜利后获得400金币 + 1张稀有卡牌 + 1个遗物。"
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "soul_elders_group_fight", "击败四大尊老")
	choice_a.add_outcome(OutcomeType.GOLD, 400, "", "获得400金币")
	choice_a.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choice_a.add_outcome(OutcomeType.RELIC, 0, "random_common", "获得随机遗物")
	choices.append(choice_a)

	# 选项B：各个击破
	var choice_b = EventChoice.new("各个击破")
	choice_b.description_rich = "强制战斗（1个魂殿长老）。胜利后获得200金币 + 1张稀有卡牌。"
	choice_b.add_outcome(OutcomeType.COMBAT, 0, "soul_hall_elder", "击败魂殿长老")
	choice_b.add_outcome(OutcomeType.GOLD, 200, "", "获得200金币")
	choice_b.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choices.append(choice_b)

	# 选项C：灵魂隐匿
	var choice_c = EventChoice.new("灵魂隐匿")
	choice_c.description_rich = "失去15点生命值（灵魂消耗），跳过此战斗。"
	choice_c.add_outcome(OutcomeType.DAMAGE, 15, "", "受到15点伤害")
	choices.append(choice_c)

	return choices
