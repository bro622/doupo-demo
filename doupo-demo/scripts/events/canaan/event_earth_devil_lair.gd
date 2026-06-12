## 事件25：地魔老鬼巢穴
## 触发条件：场景三随机触发
## 类型：战斗事件
class_name EventEarthDevilLair
extends EventModel


func _init() -> void:
	id = 25
	event_name = "地魔老鬼巢穴"
	description = "塔底深处，你发现了一处隐秘的洞穴，里面传出阴冷的灵魂波动。"
	category = Category.COMBAT
	scene_id = 3


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：突袭
	var choice_a = EventChoice.new("突袭")
	choice_a.description_rich = "强制精英战（地魔老鬼）。胜利后获得300金币 + 遗物【远古魔核】。"
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "earth_devil_fight", "突袭地魔老鬼")
	choice_a.add_outcome(OutcomeType.GOLD, 300, "", "获得300金币")
	choice_a.add_outcome(OutcomeType.RELIC, 0, "31", "获得远古魔核")
	choices.append(choice_a)

	# 选项B：偷取秘籍
	var choice_b = EventChoice.new("偷取秘籍")
	choice_b.description_rich = "获得1张随机稀有卡牌。代价：将诅咒牌【地魔诅咒】洗入牌库。"
	choice_b.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choice_b.add_outcome(OutcomeType.CURSE_CARD, 1, "earth_devil_curse", "获得诅咒牌地魔诅咒")
	choices.append(choice_b)

	# 选项C：封印洞穴
	var choice_c = EventChoice.new("封印洞穴")
	choice_c.description_rich = "失去15点生命值。获得100金币 + 本局永久+1力量。"
	choice_c.add_outcome(OutcomeType.DAMAGE, 15, "", "受到15点伤害")
	choice_c.add_outcome(OutcomeType.GOLD, 100, "", "获得100金币")
	choice_c.add_outcome(OutcomeType.PERMA_STRENGTH, 1, "", "永久+1力量")
	choices.append(choice_c)

	return choices
