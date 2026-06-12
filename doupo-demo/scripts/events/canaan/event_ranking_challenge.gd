## 事件22：强榜挑战赛
## 触发条件：场景三随机触发
## 类型：剧情事件
class_name EventRankingChallenge
extends EventModel


func _init() -> void:
	id = 22
	event_name = "强榜挑战赛"
	description = "内院强榜擂台上，强者云集。选择你想挑战的对手。"
	category = Category.PLOT
	scene_id = 3


func get_choices() -> Array[EventChoice]:
	var choices: Array[EventChoice] = []

	# 选项A：挑战韩月（强榜第九）
	var choice_a = EventChoice.new("挑战韩月")
	choice_a.description_rich = "韩月，天北城韩家大小姐，萧炎的学姐，六星斗灵实力。\n" \
		+ "在内院拥有不弱的声望，擅长风属性斗气。\n\n" \
		+ "强制精英战。胜利后获得250金币 + 遗物【强榜玉牌】。"
	choice_a.add_outcome(OutcomeType.COMBAT, 0, "han_yue_challenge", "挑战韩月")
	choice_a.add_outcome(OutcomeType.GOLD, 250, "", "获得250金币")
	choice_a.add_outcome(OutcomeType.RELIC, 0, "21", "获得强榜玉牌")
	choices.append(choice_a)

	# 选项B：挑战紫妍（强榜第一）
	var choice_b = EventChoice.new("挑战紫妍")
	choice_b.description_rich = "紫妍，太虚古龙族龙皇烛坤之女，强榜常年霸榜第一。\n" \
		+ "斗王巅峰实力，肉身力量极其强悍，内院无人敢轻撄其锋。\n\n" \
		+ "强制精英战。胜利后获得350金币 + 1张随机稀有卡牌。"
	choice_b.add_outcome(OutcomeType.COMBAT, 0, "ziyan_challenge", "挑战紫妍")
	choice_b.add_outcome(OutcomeType.GOLD, 350, "", "获得350金币")
	choice_b.add_outcome(OutcomeType.CARD, 0, "rare", "获得稀有卡牌")
	choices.append(choice_b)

	# 选项C：观战学习
	var choice_c = EventChoice.new("观战学习")
	choice_c.description_rich = "获得30金币。下场战斗开始时额外抽1张牌。"
	choice_c.add_outcome(OutcomeType.GOLD, 30, "", "获得30金币")
	choice_c.add_outcome(OutcomeType.FLAG, 0, "learned_from_observation", "下场战斗额外抽1牌")
	choices.append(choice_c)

	return choices
