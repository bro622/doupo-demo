## 事件33：魂殿据点
## 触发条件：场景四随机触发
## 类型：剧情事件
class_name EventSoulHallOutpost
extends EventModel


func _init() -> void:
	id = 33
	event_name = "魂殿据点"
	description = "你误入了一处魂殿的灵魂收割据点，阴冷的锁链声在黑暗中回荡。"
	category = Category.PLOT
	scene_id = 4


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：突袭祭坛
	var choice_a = EventChoice.new("突袭祭坛")
	choice_a.description_rich = "强制精英战（魂殿尊老）。胜利后获得400金币 + 1张稀有卡牌 + 1个遗物。"
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "soul_hall_ambush_fight", "击败魂殿尊老")
	choice_a.add_outcome(OutcomeType.GOLD, 400, "", "获得400金币")
	choice_a.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choice_a.add_outcome(OutcomeType.RELIC, 0, "random_common", "获得随机遗物")
	choices.append(choice_a)

	# 选项B：窃取灵魂碎片
	var choice_b = EventChoice.new("窃取灵魂碎片")
	choice_b.description_rich = "随机升级2张卡牌。代价：将诅咒牌【灵魂创伤】洗入牌库。"
	choice_b.add_outcome(OutcomeType.UPGRADE_CARD, 2, "", "升级2张卡牌")
	choice_b.add_outcome(OutcomeType.CURSE_CARD, 1, "soul_trauma", "获得诅咒牌灵魂创伤")
	choices.append(choice_b)

	# 选项C：屏息潜行
	var choice_c = EventChoice.new("屏息潜行")
	choice_c.description_rich = "失去3点生命值，安全离开。"
	choice_c.add_outcome(OutcomeType.DAMAGE, 3, "", "受到3点伤害")
	choices.append(choice_c)

	return choices
