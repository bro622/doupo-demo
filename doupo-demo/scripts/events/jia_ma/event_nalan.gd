## 事件2：纳兰嫣然的退婚
## 触发条件：场景一随机触发
## 类型：剧情事件
## 链接：三年之约·结局
class_name EventNalan
extends EventModel


func _init() -> void:
	id = 2
	event_name = "纳兰嫣然的退婚"
	description = "云岚宗弟子纳兰嫣然前来退婚，萧家颜面尽失。你将如何应对？"
	category = Category.PLOT
	scene_id = 1


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：隐忍接下
	var choice_a = EventChoice.new("隐忍接下")
	choice_a.add_outcome(OutcomeType.GOLD, 150, "", "获得150金币作为补偿")
	choice_a.add_outcome(OutcomeType.CURSE_CARD, 0, "broken_engagement", "退婚之辱洗入牌库...")
	choices.append(choice_a)

	# 选项B：莫欺少年穷
	var choice_b = EventChoice.new("莫欺少年穷")
	choice_b.add_outcome(OutcomeType.RELIC, 0, "51", "获得遗物「三年之约」：每场战斗第1回合额外获得1点斗气并抽1张牌")
	choice_b.add_outcome(OutcomeType.FLAG, 0, "three_year_promise", "设定「三年之约」标记")
	choices.append(choice_b)

	# 选项C：以武证道
	var choice_c = EventChoice.new("以武证道")
	choice_c.add_outcome(OutcomeType.COMBAT, 0, "elite_nalan", "与纳兰嫣然战斗！")
	choice_c.add_outcome(OutcomeType.CARD, 0, "rare", "击败后获得稀有卡牌")
	choice_c.add_outcome(OutcomeType.GOLD, 200, "", "获得200金币")
	choice_c.add_outcome(OutcomeType.FLAG, 0, "three_year_promise", "宣告三年之约")
	choice_c.add_outcome(OutcomeType.FLAG, 0, "yunshan_weakened", "云山被削弱")
	choices.append(choice_c)

	return choices
