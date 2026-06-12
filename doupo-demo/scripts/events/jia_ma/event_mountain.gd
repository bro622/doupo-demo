## 事件1：魔兽山脉的隐秘洞穴
## 触发条件：场景一随机触发
## 类型：剧情事件
class_name EventMountain
extends EventModel


func _init() -> void:
	id = 1
	event_name = "魔兽山脉的隐秘洞穴"
	description = "你在魔兽山脉中发现了一个隐秘的洞穴，洞口散发着微弱的光芒。你决定如何行动？"
	category = Category.PLOT
	scene_id = 1


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：深入探索
	var choice_a = EventChoice.new("深入探索")
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "mountain_beast", "遭遇洞穴守护魔兽！")
	choice_a.add_outcome(OutcomeType.CARD, 0, "rare", "击败后获得稀有卡牌")
	choice_a.add_outcome(OutcomeType.RELIC, 0, "34", "获得遗物「七彩灵鹤羽」")
	choice_a.add_outcome(OutcomeType.CURSE_CARD, 0, "beast_backlash", "受到兽性反噬...")
	choices.append(choice_a)

	# 选项B：采集矿石
	var choice_b = EventChoice.new("采集矿石")
	choice_b.add_outcome(OutcomeType.DAMAGE, 8, "", "洞穴碎石造成8点伤害")
	choice_b.add_outcome(OutcomeType.GOLD, 120, "", "获得120金币的矿石")
	choice_b.add_outcome(OutcomeType.POTION, 2, "", "发现2瓶丹药")
	choices.append(choice_b)

	# 选项C：悄然退走
	var choice_c = EventChoice.new("悄然退走")
	choice_c.description_rich = "放弃探索，安全离开。"
	choices.append(choice_c)

	return choices
