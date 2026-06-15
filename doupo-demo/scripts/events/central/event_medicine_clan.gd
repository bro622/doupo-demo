## 事件40：药族秘境
## 触发条件：场景四随机触发
## 类型：奖励事件
class_name EventMedicineClan
extends EventModel


func _init() -> void:
	id = 40
	event_name = "药族秘境"
	description = "药族秘境的大门向你敞开，里面保存着远古炼药师的传承。"
	category = Category.REWARD
	scene_id = 4


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：接受传承
	var choice_a = EventChoice.new("接受传承")
	choice_a.description_rich = "获得遗物【药族秘传】（战斗开始若药袋有空位，生成1瓶丹药）。"
	choice_a.add_outcome(OutcomeType.RELIC, 0, "41", "获得药族秘传")
	choices.append(choice_a)

	# 选项B：搜刮药库
	var choice_b = EventChoice.new("搜刮药库")
	choice_b.description_rich = "获得2瓶随机高级丹药 + 100金币。"
	choice_b.add_outcome(OutcomeType.POTION, 2, "", "获得2瓶丹药")
	choice_b.add_outcome(OutcomeType.GOLD, 100, "", "获得100金币")
	choices.append(choice_b)

	# 选项C：研习药方
	var choice_c = EventChoice.new("研习药方")
	choice_c.description_rich = "随机升级2张卡牌。获得100金币。"
	choice_c.add_outcome(OutcomeType.UPGRADE_CARD, 2, "", "升级2张卡牌")
	choice_c.add_outcome(OutcomeType.GOLD, 100, "", "获得100金币")
	choices.append(choice_c)

	return choices
