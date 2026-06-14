## 事件34：古界之门（萧薰儿专属）
## 触发条件：场景四随机触发
## 类型：剧情事件
class_name EventAncientGate
extends EventModel


func _init() -> void:
	id = 34
	event_name = "古界之门"
	description = "一道金色的巨门矗立在你面前，门上刻着古族的族徽。你的血脉在沸腾。"
	category = Category.PLOT
	scene_id = 4
	character_id = "xuner"


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：进入古界
	var choice_a = EventChoice.new("进入古界")
	choice_a.description_rich = "获得遗物【古族玉佩】（金印引爆阈值5→4）。解锁古族传承事件链。"
	choice_a.add_outcome(OutcomeType.RELIC, 0, "28", "获得古族玉佩")
	choice_a.add_outcome(OutcomeType.FLAG, 0, "ancient_clan_heritage", "解锁古族传承")
	choices.append(choice_a)

	# 选项B：隔门感应
	var choice_b = EventChoice.new("隔门感应")
	choice_b.description_rich = "获得100金币 + 本局永久+2力量。"
	choice_b.add_outcome(OutcomeType.GOLD, 100, "", "获得100金币")
	choice_b.add_outcome(OutcomeType.PERMA_STRENGTH, 2, "", "永久+2力量")
	choices.append(choice_b)

	# 选项C：封印古门
	var choice_c = EventChoice.new("封印古门")
	choice_c.description_rich = "失去20点生命值。获得200金币 + 1张稀有卡牌。"
	choice_c.add_outcome(OutcomeType.DAMAGE, 20, "", "受到20点伤害")
	choice_c.add_outcome(OutcomeType.GOLD, 200, "", "获得200金币")
	choice_c.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choices.append(choice_c)

	return choices
