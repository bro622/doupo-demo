## 守灵事件：场景三（迦南学院）
## 自动满血回复 + 3选1恩赐，角色专属对话
class_name EventAncientScene3
extends EventModel


func _init() -> void:
	id = 101
	event_name = "守灵"
	description = ""
	category = Category.REWARD
	scene_id = 3
	is_forced = false
	is_ancient = true


func get_dialog() -> String:
	match PlayerManager.character_id:
		"xiaoyan":
			return "药尘沉默了很久，灵魂虚影在风中微微颤抖。\n\n" \
				+ "\"韩枫……死了。\"\n" \
				+ "\"老夫等这一天，等了二十年。\"\n" \
				+ "\"萧炎，你做得很好。但你看他身上掉落的这份密卷——他在黑角域集结势力，真正的目标居然是迦南学院！\"\n" \
				+ "\"迦南学院的天焚炼气塔底下，封印着排名第十四的异火——陨落心炎。韩枫想夺它来补全《焚诀》。\"\n" \
				+ "\"异火绝不能落入旁人之手。萧炎，我们立刻前往迦南学院，必须抢在黑角域残党反扑前将它收服！\"\n\n" \
				+ "\"去学院之前，老夫还有三件事可以帮你。\""
		"xuner":
			return "古族长老的虚影再次出现，但这次更加清晰。\n\n" \
				+ "\"你从黑角域的杀戮中走出来了……这片混乱之地的鲜血，反而淬炼了你的血脉。\"\n" \
				+ "\"那个被你击败的炼药师（韩枫）不过是个跳梁小丑，但他手里的地图很有意思。他一直觊觎的迦南学院地底，竟然有一处与我古族千丝万缕关联的远古遗迹。\"\n" \
				+ "\"真正的历练才刚刚开始。去迦南学院吧，那里的力量，本就该属于拥有神品血脉的你。\"\n\n" \
				+ "\"在此之前，接受古族的传承吧。\""
		"cailin":
			return "蛇族先祖的虚影再次出现，蛇瞳中闪烁着幽紫光芒。\n\n" \
				+ "\"你从黑角域的毒沼中活着出来了……吞天蟒的血脉正在觉醒。\"\n" \
				+ "\"迦南学院的天焚炼气塔底，封印着一股远古心炎。\"\n" \
				+ "\"它与我蛇族……曾有一段恩怨。你需要做好准备。\""
		_:
			return "一道远古的虚影出现在你面前……"


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：卡牌获取（稀有卡 + 80金）
	var choice_a = EventChoice.new(_get_option_name("A"))
	choice_a.description_rich = "获得 1 张随机稀有卡牌 + 80 金币。"
	choices.append(choice_a)

	# 选项B：卡组精简（移除2张基础牌 → 换2张进阶牌）
	var choice_b = EventChoice.new(_get_option_name("B"))
	choice_b.description_rich = "从牌库移除 2 张基础打击/防御，替换为 2 张随机本职业进阶卡牌（不足则每缺 1 张补 50 金）。"
	choices.append(choice_b)

	# 选项C：遗物获取（稀有遗物，-8最大HP）
	var choice_c = EventChoice.new(_get_option_name("C"))
	choice_c.description_rich = "随机获得 1 个稀有遗物。\n[color=red]代价：失去 8 点最大生命值。[/color]"
	choices.append(choice_c)

	return choices


func _get_option_name(option: String) -> String:
	match PlayerManager.character_id:
		"xiaoyan":
			match option:
				"A": return "药老传授·秘技"
				"B": return "药老传授·洗髓"
				"C": return "药老传授·古法"
		"xuner":
			match option:
				"A": return "古族传承·武学"
				"B": return "古族传承·洗髓"
				"C": return "古族传承·遗宝"
		"cailin":
			match option:
				"A": return "蛇族传承·蛇瞳"
				"B": return "蛇族传承·蜕皮"
				"C": return "蛇族传承·蛇骨"
	return "选项" + option
