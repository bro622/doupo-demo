## 守灵事件：场景二（黑角域）
## 自动满血回复 + 3选1恩赐，角色专属对话
## 选项效果由 main.gd _apply_ancient_choice 处理（与 FloorZeroEvent 相同模式）
class_name EventAncientScene2
extends EventModel


func _init() -> void:
	id = 100
	event_name = "守灵"
	description = ""  # 由 get_dialog() 动态生成
	category = Category.REWARD
	scene_id = 2
	is_forced = false
	is_ancient = true


## 动态获取对话文本（根据角色）
func get_dialog() -> String:
	match PlayerManager.character_id:
		"xiaoyan":
			return "药尘的声音从纳戒中传来，语气罕见地凝重——\n\n" \
				+ "\"云山已死，三年之约已了。你做得很好。\"\n" \
				+ "\"但接下来……老夫要告诉你一件事。\"\n" \
				+ "\"黑角域里，有一个人——韩枫。\"\n" \
				+ "\"他是老夫的叛徒弟子，当年偷走了海心焰。\"\n" \
				+ "\"你迟早会与他对上。在那之前……你需要更强。\"\n\n" \
				+ "\"老夫尚有三件事可以指点你。你选一件。\""
		"xuner":
			return "你体内的古族血脉突然剧烈跳动。\n" \
				+ "一道金色的虚影在你面前凝聚——那是一位古族长老的残念。\n\n" \
				+ "\"后辈……你的血脉比我们预想的更强。\"\n" \
				+ "\"前方的路很危险。黑角域的黑暗会侵蚀你的灵魂。\"\n" \
				+ "\"让老夫帮你稳固根基。\""
		"cailin":
			return "你感受到蛇族血脉中传来一股远古的共鸣。\n" \
				+ "一道蛇瞳虚影在你面前浮现——那是一位远古蛇帝的残念。\n\n" \
				+ "\"美杜莎的后裔……你体内的血脉，比你想象的更古老。\"\n" \
				+ "\"黑角域里有毒瘴弥漫之地，那里与我蛇族有渊源。\"\n" \
				+ "\"去吧。但在此之前，让先祖赐你一份力量。\""
		_:
			return "一道远古的虚影出现在你面前……"


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：卡组精简（移除2张基础牌 → 换2张进阶牌）
	var choice_a = EventChoice.new(_get_option_name("A"))
	choice_a.description_rich = "从牌库移除 2 张基础打击/防御，替换为 2 张随机本职业进阶卡牌（不足则每缺 1 张补 50 金）。"
	choices.append(choice_a)

	# 选项B：卡牌获取（稀有卡 + 100金，-10%最大HP）
	var choice_b = EventChoice.new(_get_option_name("B"))
	choice_b.description_rich = "获得 1 张随机稀有卡牌 + 100 金币。\n[color=red]代价：失去 10% 最大生命值。[/color]"
	choices.append(choice_b)

	# 选项C：丹药储备（2瓶高级丹药）
	var choice_c = EventChoice.new(_get_option_name("C"))
	choice_c.description_rich = "获得 2 瓶随机高级丹药。"
	choices.append(choice_c)

	return choices


func _get_option_name(option: String) -> String:
	match PlayerManager.character_id:
		"xiaoyan":
			match option:
				"A": return "药老指点·净心"
				"B": return "药老指点·炼体"
				"C": return "药老指点·备药"
		"xuner":
			match option:
				"A": return "古族洗礼·净脉"
				"B": return "古族秘法·觉醒"
				"C": return "古族遗宝·灵药"
		"cailin":
			match option:
				"A": return "蛇族淬体·蜕鳞"
				"B": return "蛇族秘术·噬血"
				"C": return "蛇族遗蜕·蛇胆"
	return "选项" + option
