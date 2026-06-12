## 事件15：暗杀者伏击
## 触发条件：场景二随机触发
## 类型：战斗事件
class_name EventAssassinAmbush
extends EventModel


func _init() -> void:
	id = 15
	event_name = "暗杀者伏击"
	description = "黑暗中传来窸窣声，你被暗杀者包围了！"
	category = Category.COMBAT
	scene_id = 2


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：战斗2个暗杀者，胜利获得200金币+稀有卡牌
	var choice_a = EventChoice.new("迎战")
	choice_a.description_rich = "与2名暗杀者战斗。胜利获得200金币+1张稀有卡牌。"
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "assassin_ambush_normal", "击退暗杀者")
	choice_a.add_outcome(OutcomeType.GOLD, 200, "", "获得200金币")
	choice_a.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choices.append(choice_a)

	# 选项B：花费100金币逃跑
	var choice_b = EventChoice.new("花钱消灾")
	choice_b.description_rich = "花费100金币贿赂暗杀者，安全离开。"
	choice_b.gold_cost = 100
	choices.append(choice_b)

	# 选项C：挑战模式——敌人+5攻击力，胜利获得300金币+稀有遗物
	var choice_c = EventChoice.new("挑战模式")
	choice_c.description_rich = "敌人攻击力+5。胜利获得300金币+1个稀有遗物。"
	choice_c.add_outcome(OutcomeType.COMBAT, 0, "assassin_ambush_hard", "击败强化暗杀者")
	choice_c.add_outcome(OutcomeType.GOLD, 300, "", "获得300金币")
	choice_c.add_outcome(OutcomeType.RELIC, 0, "rare", "获得稀有遗物")
	choices.append(choice_c)

	return choices
