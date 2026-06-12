## 事件20：暗黑拍卖会
## 触发条件：场景二随机触发
## 类型：风险事件
class_name EventDarkAuction
extends EventModel


func _init() -> void:
	id = 20
	event_name = "暗黑拍卖会"
	description = "一场神秘的地下拍卖会，拍卖的物品都是禁忌之物。"
	category = Category.RISK
	scene_id = 2


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：永久失去15点最大HP，获得随机传说卡牌
	var choice_a = EventChoice.new("竞拍禁忌之书")
	choice_a.description_rich = "永久失去15点最大HP，获得1张随机传说卡牌。"
	choice_a.add_outcome(OutcomeType.MAX_HP, -15, "", "永久失去15点最大HP")
	choice_a.add_outcome(OutcomeType.CARD, 0, "legendary", "获得传说卡牌")
	choices.append(choice_a)

	# 选项B：失去15HP，获得1个随机史诗遗物
	var choice_b = EventChoice.new("竞拍遗物")
	choice_b.description_rich = "失去15点HP，获得1个随机史诗遗物。"
	choice_b.add_outcome(OutcomeType.DAMAGE, 15, "", "失去15点HP")
	choice_b.add_outcome(OutcomeType.RELIC, 0, "epic", "获得史诗遗物")
	choices.append(choice_b)

	# 选项C：离开
	var choice_c = EventChoice.new("离开")
	choice_c.description_rich = "安全离开拍卖会。"
	choices.append(choice_c)

	return choices
