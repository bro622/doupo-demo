## 事件7：云岚宗弟子伏击
## 触发条件：场景一随机触发
## 类型：战斗事件
class_name EventYunlanAmbush
extends EventModel


func _init() -> void:
	id = 7
	event_name = "云岚宗弟子伏击"
	description = "一伙云岚宗弟子埋伏在路边，似乎早就料到你会经过。"
	category = Category.COMBAT
	scene_id = 1


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：强攻突破
	var choice_a = EventChoice.new("强攻突破")
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "yunlan_ambush", "与云岚宗弟子战斗！")
	choice_a.add_outcome(OutcomeType.GOLD, 150, "", "获得150金币")
	choice_a.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choices.append(choice_a)

	# 选项B：绕道而行
	var choice_b = EventChoice.new("绕道而行")
	choice_b.add_outcome(OutcomeType.DAMAGE, 6, "", "绕行途中受到6点伤害")
	choices.append(choice_b)

	# 选项C：以理服人（需要持有三年之约遗物）
	var choice_c = EventChoice.new("以理服人")
	choice_c.required_relic_id = 51  # 三年之约
	choice_c.add_outcome(OutcomeType.GOLD, 100, "", "出示三年之约，对方让步，获得100金币")
	choices.append(choice_c)

	return choices
