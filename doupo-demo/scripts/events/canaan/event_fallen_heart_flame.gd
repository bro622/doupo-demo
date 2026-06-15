## 事件29：陨落心炎封印松动
## 触发条件：场景三随机触发
## 类型：风险事件
class_name EventFallenHeartFlame
extends EventModel


func _init() -> void:
	id = 29
	event_name = "陨落心炎封印松动"
	description = "封印出现裂痕，心炎的能量正在泄漏。你可以选择冒险汲取这股力量。"
	category = Category.RISK
	scene_id = 3


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：汲取心炎
	var choice_a = EventChoice.new("汲取心炎")
	choice_a.description_rich = "获得1张随机稀有卡牌。代价：将诅咒牌【心火灼烧】洗入牌库。"
	choice_a.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choice_a.add_outcome(OutcomeType.CURSE_CARD, 1, "heart_fire_burn", "获得诅咒牌心火灼烧")
	choices.append(choice_a)

	# 选项B：加固封印
	var choice_b = EventChoice.new("加固封印")
	choice_b.description_rich = "失去25点生命值。获得200金币 + 遗物【焚炎谷令】。"
	choice_b.add_outcome(OutcomeType.DAMAGE, 25, "", "受到25点伤害")
	choice_b.add_outcome(OutcomeType.GOLD, 200, "", "获得200金币")
	choice_b.add_outcome(OutcomeType.RELIC, 0, "37", "获得焚炎谷令")
	choices.append(choice_b)

	# 选项C：释放心炎
	var choice_c = EventChoice.new("释放心炎")
	choice_c.description_rich = "提前触发Boss战（陨落心炎）。胜利后获得遗物【守护者之证】。"
	choice_c.add_outcome(OutcomeType.COMBAT, 0, "fallen_heart_flame", "与陨落心炎交战")
	choice_c.add_outcome(OutcomeType.RELIC, 0, "40", "获得守护者之证")
	choices.append(choice_c)

	return choices
