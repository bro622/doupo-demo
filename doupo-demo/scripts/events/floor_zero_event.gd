## 第0层事件：菩提古树
## 开局恩赐，4选1
class_name FloorZeroEvent
extends EventModel


func _init() -> void:
	id = 0
	event_name = "菩提古树"
	description = "远古菩提树下，一道苍老的声音在你心中响起...\n" \
		+ "菩提古树赐予你一次机缘，你将如何抉择？"
	category = Category.REWARD
	scene_id = -1  # 特殊场景，不受场景筛选
	is_forced = true


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 注意：菩提古树的所有选项效果由 main.gd _apply_floor_zero_choice 手动处理
	# 此处仅定义选项UI文本，outcomes留空（event_scene.gd对FloorZeroEvent走专用信号路径）

	# 选项一【稳健】：获得200金币
	var choice_a = EventChoice.new("菩提恩赐")
	choice_a.description_rich = "获得 200 金币。"
	choices.append(choice_a)

	# 选项二【爆发】：接下来3场战斗，所有敌人初始HP=1
	var choice_b = EventChoice.new("菩提威压")
	choice_b.description_rich = "接下来的 3 场战斗中，所有敌人的初始生命值为 1。"
	choices.append(choice_b)

	# 选项三【博弈】：失去10%最大生命值，获得1个稀有遗物
	var choice_c = EventChoice.new("菩提试炼")
	choice_c.description_rich = "失去 10% 最大生命值。随机获得 1 个稀有遗物（蓝色品质）。"
	choices.append(choice_c)

	# 选项四【提纯】：将2张基础卡牌替换为随机进阶卡牌
	var choice_d = EventChoice.new("菩提洗髓")
	choice_d.description_rich = "从牌库中移除 2 张基础打击/防御，替换为 2 张随机的本职业进阶卡牌。"
	choices.append(choice_d)

	return choices
