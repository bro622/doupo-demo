## 事件31：岩浆世界入口
## 触发条件：场景三随机触发，萧炎专属
## 类型：风险事件
## 选项A链接：古帝之谜 → 场景四强制触发隐藏Boss
class_name EventLavaWorldEntrance
extends EventModel


func _init() -> void:
	id = 31
	event_name = "岩浆世界入口"
	description = "天焚炼气塔底层的最深处，你发现了一个散发着灼热气息的洞穴入口。"
	category = Category.RISK
	scene_id = 3
	character_id = "xiaoyan"


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：硬抗高温深入 → 设置古帝之谜标记
	var choice_a = EventChoice.new("硬抗高温深入")
	choice_a.description_rich = "失去15点生命值（严重灼伤）。获得100金币 + 1张随机卡牌。🔗链接：古帝之谜"
	choice_a.add_outcome(OutcomeType.DAMAGE, 15, "", "受到15点伤害")
	choice_a.add_outcome(OutcomeType.GOLD, 100, "", "获得100金币")
	choice_a.add_outcome(OutcomeType.CARD, 0, "", "获得随机卡牌")
	choice_a.add_outcome(OutcomeType.FLAG, 0, "ancient_emperor", "触发古帝之谜事件链")
	choices.append(choice_a)

	# 选项B：用丹药护体
	var choice_b = EventChoice.new("用丹药护体")
	choice_b.description_rich = "失去1瓶丹药。获得1张随机稀有卡牌。"
	choice_b.potion_cost = 1
	choice_b.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choices.append(choice_b)

	# 选项C：抽身离去
	var choice_c = EventChoice.new("抽身离去")
	choice_c.description_rich = "无事发生。"
	choices.append(choice_c)

	return choices
