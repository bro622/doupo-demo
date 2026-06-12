## 事件32：丹塔历练
## 触发条件：场景四随机触发
## 类型：剧情事件
class_name EventPillTowerTrial
extends EventModel


func _init() -> void:
	id = 32
	event_name = "丹塔历练"
	description = "丹塔七层，每层都有不同等级的考验。塔顶的老者注视着你。"
	category = Category.PLOT
	scene_id = 4


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：挑战第五层
	var choice_a = EventChoice.new("挑战第五层")
	choice_a.description_rich = "强制战斗（丹塔守卫）。胜利后获得300金币 + 遗物【丹塔秘卷】。"
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "pill_tower_guard_fight", "击败丹塔守卫")
	choice_a.add_outcome(OutcomeType.GOLD, 300, "", "获得300金币")
	choice_a.add_outcome(OutcomeType.RELIC, 0, "57", "获得丹塔秘卷")
	choices.append(choice_a)

	# 选项B：挑战第三层
	var choice_b = EventChoice.new("挑战第三层")
	choice_b.description_rich = "获得150金币 + 2瓶高级丹药。"
	choice_b.add_outcome(OutcomeType.GOLD, 150, "", "获得150金币")
	choice_b.add_outcome(OutcomeType.POTION, 2, "", "获得2瓶丹药")
	choices.append(choice_b)

	# 选项C：在第一层研习
	var choice_c = EventChoice.new("在第一层研习")
	choice_c.description_rich = "获得100金币。随机升级1张卡牌。"
	choice_c.add_outcome(OutcomeType.GOLD, 100, "", "获得100金币")
	choice_c.add_outcome(OutcomeType.UPGRADE_CARD, 1, "", "升级1张卡牌")
	choices.append(choice_c)

	return choices
