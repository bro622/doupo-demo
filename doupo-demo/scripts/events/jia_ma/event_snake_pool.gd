## 事件4：蛇人族圣池
## 触发条件：场景一随机触发（美杜莎专属）
## 类型：剧情事件
class_name EventSnakePool
extends EventModel


func _init() -> void:
	id = 4
	event_name = "蛇人族圣池"
	description = "这是历代美杜莎女王蜕变的圣地，池水中蕴含着极度狂暴的能量。"
	category = Category.PLOT
	scene_id = 1
	character_id = "cailin"


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：沐浴毒液
	var choice_a = EventChoice.new("沐浴毒液")
	choice_a.description_rich = "随机升级2张卡牌并受到12点伤害。"
	choice_a.add_outcome(OutcomeType.UPGRADE_CARD, 2, "", "毒液淬炼，2张卡牌获得升级")
	choice_a.add_outcome(OutcomeType.DAMAGE, 12, "", "毒液侵蚀，受到12点伤害")
	choices.append(choice_a)

	# 选项B：剥离软弱
	var choice_b = EventChoice.new("剥离软弱")
	choice_b.description_rich = "移除牌库中2张牌。受到5点伤害。"
	choice_b.add_outcome(OutcomeType.REMOVE_CARD, 2, "", "剥离了2张卡牌")
	choice_b.add_outcome(OutcomeType.DAMAGE, 5, "", "剥离过程造成5点伤害")
	choices.append(choice_b)

	# 选项C：吞天蟒之魂
	var choice_c = EventChoice.new("吞天蟒之魂")
	choice_c.description_rich = "获得卡牌【暗影潜行】。"
	choice_c.add_outcome(OutcomeType.CARD, 0, "shadow_lurk", "获得卡牌【暗影潜行】")
	choices.append(choice_c)

	return choices
