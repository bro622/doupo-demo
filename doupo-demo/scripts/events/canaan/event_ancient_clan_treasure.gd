## 事件23：古族秘宝（萧薰儿专属）
## 触发条件：场景三随机触发
## 类型：剧情事件
class_name EventAncientClanTreasure
extends EventModel


func _init() -> void:
	id = 23
	event_name = "古族秘宝"
	description = "深入古界，你感受到了神品血脉的共鸣。一道金色的光芒从地底涌出。"
	category = Category.PLOT
	scene_id = 3
	character_id = "xuner"


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：激活血脉
	var choice_a = EventChoice.new("激活血脉")
	choice_a.description_rich = "获得传说卡牌【神品血脉】（金印引爆阈值从5层永久降为4层）。代价：最大生命值永久-5。"
	choice_a.add_outcome(OutcomeType.CARD, 0, "divine_blood", "获得传说卡牌神品血脉")
	choice_a.add_outcome(OutcomeType.MAX_HP, -5, "", "最大生命值-5")
	choices.append(choice_a)

	# 选项B：接受传承
	var choice_b = EventChoice.new("接受传承")
	choice_b.description_rich = "随机升级牌库中的3张卡牌。"
	choice_b.add_outcome(OutcomeType.UPGRADE_CARD, 3, "", "升级3张卡牌")
	choices.append(choice_b)

	# 选项C：触碰禁忌
	var choice_c = EventChoice.new("触碰禁忌")
	choice_c.description_rich = "获得遗物【古族玉佩】（金印引爆阈值5→4）。代价：将诅咒牌【古族禁令】洗入牌库。"
	choice_c.add_outcome(OutcomeType.RELIC, 0, "28", "获得古族玉佩")
	choice_c.add_outcome(OutcomeType.CURSE_CARD, 1, "ancient_clan_forbidden", "获得诅咒牌古族禁令")
	choices.append(choice_c)

	return choices
