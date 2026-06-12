## 事件21：天焚炼气塔修炼
## 触发条件：场景三随机触发
## 类型：剧情事件
class_name EventBlazingTower
extends EventModel


func _init() -> void:
	id = 21
	event_name = "天焚炼气塔修炼"
	description = "天焚炼气塔散发出灼热的能量波动，修炼者们排队进入。你感受到了塔底那股远古力量的脉动。"
	category = Category.PLOT
	scene_id = 3


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：深层修炼
	var choice_a = EventChoice.new("深层修炼")
	choice_a.description_rich = "失去10点生命值（高温灼伤）。获得1张随机稀有卡牌 + 本局永久+1力量。"
	choice_a.add_outcome(OutcomeType.DAMAGE, 10, "", "高温灼伤，受到10点伤害")
	choice_a.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choice_a.add_outcome(OutcomeType.PERMA_STRENGTH, 1, "", "永久+1力量")
	choices.append(choice_a)

	# 选项B：浅层修炼
	var choice_b = EventChoice.new("浅层修炼")
	choice_b.description_rich = "回复15点生命值。获得50金币。"
	choice_b.add_outcome(OutcomeType.HEAL, 15, "", "回复15点生命值")
	choice_b.add_outcome(OutcomeType.GOLD, 50, "", "获得50金币")
	choices.append(choice_b)

	# 选项C：探查塔底
	var choice_c = EventChoice.new("探查塔底")
	choice_c.description_rich = "获得100金币 + 1张随机卡牌。"
	choice_c.add_outcome(OutcomeType.GOLD, 100, "", "获得100金币")
	choice_c.add_outcome(OutcomeType.CARD, 0, "", "获得随机卡牌")
	choices.append(choice_c)

	return choices
