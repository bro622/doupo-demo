## 事件16：血宗禁地探索
## 触发条件：场景二随机触发
## 类型：战斗事件
class_name EventBloodSectExplore
extends EventModel


func _init() -> void:
	id = 16
	event_name = "血宗禁地探索"
	description = "血宗禁地弥漫着浓重的血腥气息，前方隐约可见一座邪殿。"
	category = Category.COMBAT
	scene_id = 2


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：战斗1个血宗弟子+1个邪修炼药师，胜利获得150金币
	var choice_a = EventChoice.new("深入探索")
	choice_a.description_rich = "与血宗弟子和邪修炼药师战斗。胜利获得150金币。"
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "blood_sect_guard", "击退血宗守卫")
	choice_a.add_outcome(OutcomeType.GOLD, 150, "", "获得150金币")
	choices.append(choice_a)

	# 选项B：获得随机稀有卡牌，但获得诅咒牌血毒反噬
	var choice_b = EventChoice.new("偷取秘典")
	choice_b.description_rich = "获得1张随机稀有卡牌，但获得诅咒牌【血毒反噬】。"
	choice_b.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choice_b.add_outcome(OutcomeType.CURSE_CARD, 1, "blood_toxin_backlash", "获得诅咒牌血毒反噬")
	choices.append(choice_b)

	# 选项C：离开
	var choice_c = EventChoice.new("离开")
	choice_c.description_rich = "安全离开血宗禁地。"
	choices.append(choice_c)

	return choices
