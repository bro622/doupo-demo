## 事件24：走火入魔的学员
## 触发条件：场景三随机触发
## 类型：战斗事件
class_name EventCultivationDeviation
extends EventModel


func _init() -> void:
	id = 24
	event_name = "走火入魔的学员"
	description = "天焚炼气塔底层，一个学员双眼通红，正在疯狂攻击周围的修炼者。"
	category = Category.COMBAT
	scene_id = 3


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：强行制服
	var choice_a = EventChoice.new("强行制服")
	choice_a.description_rich = "强制战斗（走火入魔者）。胜利后获得150金币 + 1张随机卡牌。"
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "cultivation_deviation_fight", "制服走火入魔者")
	choice_a.add_outcome(OutcomeType.GOLD, 150, "", "获得150金币")
	choice_a.add_outcome(OutcomeType.CARD, 0, "", "获得随机卡牌")
	choices.append(choice_a)

	# 选项B：用丹药救治
	var choice_b = EventChoice.new("用丹药救治")
	choice_b.description_rich = "失去1瓶丹药。获得100金币 + 遗物【山岳之心】。"
	choice_b.potion_cost = 1
	choice_b.add_outcome(OutcomeType.GOLD, 100, "", "获得100金币")
	choice_b.add_outcome(OutcomeType.RELIC, 0, "56", "获得山岳之心")
	choices.append(choice_b)

	# 选项C：无视
	var choice_c = EventChoice.new("无视")
	choice_c.description_rich = "无事发生。"
	choices.append(choice_c)

	return choices
