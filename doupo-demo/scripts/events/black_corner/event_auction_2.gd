## 事件11：黑印城拍卖会
## 触发条件：场景二随机触发
## 类型：剧情事件
class_name EventAuction2
extends EventModel


func _init() -> void:
	id = 11
	event_name = "黑印城拍卖会"
	description = "黑印城的地下拍卖会正在进行，各种珍稀物品琳琅满目。"
	category = Category.PLOT
	scene_id = 2


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：花费200金币购买地灵丹
	var choice_a = EventChoice.new("购买地灵丹")
	choice_a.description_rich = "花费200金币购买地灵丹（战斗中回复30%最大HP）。"
	choice_a.gold_cost = 200
	choice_a.add_outcome(OutcomeType.POTION, 1, "", "获得地灵丹")
	choices.append(choice_a)

	# 选项B：花费150金币购买随机稀有遗物
	var choice_b = EventChoice.new("竞拍遗物")
	choice_b.description_rich = "花费150金币，随机获得1个稀有遗物。"
	choice_b.gold_cost = 150
	choice_b.add_outcome(OutcomeType.RELIC, 0, "rare", "获得随机稀有遗物")
	choices.append(choice_b)

	# 选项C：偷窃——强制战斗
	var choice_c = EventChoice.new("偷窃")
	choice_c.description_rich = "强制遭遇战斗（2个暗杀者+1个赏金猎人），胜利后获得随机遗物。"
	choice_c.add_outcome(OutcomeType.COMBAT, 0, "auction_thieves", "击退盗贼")
	choice_c.add_outcome(OutcomeType.RELIC, 0, "rare", "获得随机稀有遗物")
	choices.append(choice_c)

	return choices
