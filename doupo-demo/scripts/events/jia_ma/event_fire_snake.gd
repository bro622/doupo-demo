## 事件10：沙漠地底的双头火灵蛇
## 触发条件：场景一随机触发
## 类型：风险事件
class_name EventFireSnake
extends EventModel


func _init() -> void:
	id = 10
	event_name = "沙漠地底的双头火灵蛇"
	description = "在沙漠地底深处，你遇到了一条双头火灵蛇。它守护着珍贵的宝藏，但也极具攻击性。"
	category = Category.RISK
	scene_id = 1


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：与蛇搏斗
	var choice_a = EventChoice.new("与蛇搏斗")
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "fire_snake", "与双头火灵蛇战斗！")
	choice_a.add_outcome(OutcomeType.RELIC, 0, "55", "击败后获得遗物「赤火蛇鳞」")
	choice_a.add_outcome(OutcomeType.GOLD, 100, "", "获得100金币")
	choices.append(choice_a)

	# 选项B：用丹药引开（需要丹药）
	var choice_b = EventChoice.new("用丹药引开")
	choice_b.potion_cost = 1
	choice_b.add_outcome(OutcomeType.CARD, 0, "rare", "趁机取得稀有卡牌")
	choice_b.add_outcome(OutcomeType.GOLD, 50, "", "获得50金币")
	choices.append(choice_b)

	# 选项C：悄然退走
	var choice_c = EventChoice.new("悄然退走")
	choice_c.description_rich = "放弃探索，安全离开。"
	choices.append(choice_c)

	return choices
