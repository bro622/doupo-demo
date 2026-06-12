## 守灵事件：场景四（中州）
## 自动满血回复 + 3选1恩赐，角色专属对话
class_name EventAncientScene4
extends EventModel


func _init() -> void:
	id = 102
	event_name = "守灵"
	description = ""
	category = Category.REWARD
	scene_id = 4
	is_forced = false
	is_ancient = true


func get_dialog() -> String:
	match PlayerManager.character_id:
		"xiaoyan":
			return "四周的空间通道轰然碎裂，狂暴的银色乱流席卷而来！\n" \
				+ "药尘的灵魂虚影从骨炎戒中冲出，化作一道淡蓝色的屏障死死护住你。\n\n" \
				+ "\"空间风暴……小心！\"\n" \
				+ "\"萧炎，中州不比加玛帝国，那里是魂殿的大本营，也是真正的修罗场。\"\n" \
				+ "\"老夫现在的灵魂力量，只能帮你顶住这阵空间乱流了……接下来的中州之路，以及对抗魂殿的决战，都要靠你自己去闯！\"\n" \
				+ "\"在风暴将我们冲散前，接好老夫最后的力量！\""
		"xuner":
			return "古族长老的虚影变得异常明亮。\n\n" \
				+ "\"你的血脉已经觉醒到第四层。\"\n" \
				+ "\"古帝洞府……那里有我古族先祖留下的传承。\"\n" \
				+ "\"魂天帝也在觊觎那份力量。你必须比他先到。\"\n" \
				+ "\"最后的准备，让老夫助你一臂之力。\""
		"cailin":
			return "银色的空间风暴撕裂而来，你感受到蛇族血脉中传来一股不屈的狂暴战意。\n" \
				+ "蛇族先祖的幽紫虚影盘踞在风暴中心，巨大的蛇躯将你护在中央。\n\n" \
				+ "\"区区空间乱流，也想吞噬九彩吞天蟒的血脉？\"\n" \
				+ "\"去吧，中州才是你真正该去的地方。在那里，让世人再次回想起远古蛇帝的恐惧。\"\n" \
				+ "\"魂殿曾犯我蛇族，魂族更是留有血债。在穿过这片乱流前，接受先祖最后的馈赠，去中州大闹一场吧！\""
		_:
			return "一道远古的虚影出现在你面前……"


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：卡牌升级（随机升级2张牌）
	var choice_a = EventChoice.new(_get_option_name("A"))
	choice_a.description_rich = "随机升级牌库中的 2 张卡牌。"
	choices.append(choice_a)

	# 选项B：遗物获取（稀有遗物，-10%最大HP）
	var choice_b = EventChoice.new(_get_option_name("B"))
	choice_b.description_rich = "随机获得 1 个稀有遗物。\n[color=red]代价：失去 10% 最大生命值。[/color]"
	choices.append(choice_b)

	# 选项C：永久强化（永久+1力量）
	var choice_c = EventChoice.new(_get_option_name("C"))
	choice_c.description_rich = "本局永久获得 1 点力量。"
	choices.append(choice_c)

	return choices


func _get_option_name(option: String) -> String:
	match PlayerManager.character_id:
		"xiaoyan":
			match option:
				"A": return "药老最后的教诲·顿悟"
				"B": return "药老最后的教诲·传承"
				"C": return "药老最后的教诲·印记"
		"xuner":
			match option:
				"A": return "古族长老·血脉觉醒"
				"B": return "古族长老·古帝遗宝"
				"C": return "古族长老·帝境感悟"
		"cailin":
			match option:
				"A": return "蛇族先祖·终极蜕变"
				"B": return "蛇族先祖·远古蛇蜕"
				"C": return "蛇族先祖·蛇帝之力"
	return "选项" + option
