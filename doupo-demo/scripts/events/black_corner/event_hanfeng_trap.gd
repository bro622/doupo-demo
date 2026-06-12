## 事件12：韩枫的陷阱
## 触发条件：场景二随机触发
## 类型：剧情事件
class_name EventHanfengTrap
extends EventModel


func _init() -> void:
	id = 12
	event_name = "韩枫的陷阱"
	description = "你发现了韩枫设下的陷阱，但似乎还有其他选择..."
	category = Category.PLOT
	scene_id = 2


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：提前进入陷阱——Boss战（韩枫HP-30）
	var choice_a = EventChoice.new("主动出击")
	choice_a.description_rich = "提前发动攻击，韩枫初始HP-15。触发Boss战。"
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "han_feng_weakened", "与韩枫交战")
	choices.append(choice_a)

	# 选项B：承受毒伤，获得随机稀有卡牌
	var choice_b = EventChoice.new("承受毒伤")
	choice_b.description_rich = "受到20点伤害，获得1张随机稀有卡牌。"
	choice_b.add_outcome(OutcomeType.DAMAGE, 20, "", "毒素侵蚀，受到20点伤害")
	choice_b.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choices.append(choice_b)

	# 选项C：忽略
	var choice_c = EventChoice.new("忽略")
	choice_c.description_rich = "安全离开，不触发任何效果。"
	choices.append(choice_c)

	return choices
