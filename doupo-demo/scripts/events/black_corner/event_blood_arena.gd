## 事件14：血腥角斗场
## 触发条件：场景二随机触发
## 类型：战斗事件
class_name EventBloodArena
extends EventModel


func _init() -> void:
	id = 14
	event_name = "血腥角斗场"
	description = "黑印城的地下角斗场，鲜血与荣耀的交汇处。"
	category = Category.COMBAT
	scene_id = 2


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：连续2场普通战斗，胜利获得随机稀有遗物
	var choice_a = EventChoice.new("参加角斗")
	choice_a.description_rich = "强制精英战。胜利后获得200金币 + 1张稀有卡牌。"
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "arena_fight_1", "参加角斗")
	choice_a.add_outcome(OutcomeType.GOLD, 200, "", "获得200金币")
	choice_a.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choices.append(choice_a)

	# 选项B：赌50金币，赢了得150金币，但下场战斗获得2张状态牌
	var choice_b = EventChoice.new("赌博")
	choice_b.description_rich = "花费50金币赌博。赢了获得150金币，但下场战斗获得2张状态牌。"
	choice_b.gold_cost = 50
	choice_b.add_outcome(OutcomeType.GOLD, 150, "", "赢得150金币")
	choice_b.add_outcome(OutcomeType.FLAG, 0, "arena_gamble_curse", "下场战斗获得2张状态牌")
	choices.append(choice_b)

	# 选项C：离开
	var choice_c = EventChoice.new("离开")
	choice_c.description_rich = "安全离开角斗场。"
	choices.append(choice_c)

	return choices
