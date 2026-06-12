## 卡牌数据库
## 从 JSON 加载所有卡牌数据，提供查询和卡组创建接口
class_name CardDatabase

## 缓存所有已加载的卡牌
static var _all_cards: Array[CardData] = []


## 确保数据已加载（每次调用重新读取 JSON，避免 static 缓存陈旧）
static func _ensure_loaded() -> void:
	_all_cards.clear()
	_all_cards = CardLoader.load_from_json("res://data/cards_xiaoyan.json")
	var xuner_cards = CardLoader.load_from_json("res://data/cards_xuner.json")
	for card in xuner_cards:
		_all_cards.append(card)
	var cailin_cards = CardLoader.load_from_json("res://data/cards_cailin.json")
	for card in cailin_cards:
		_all_cards.append(card)
	print("[CardDatabase] 加载了 %d 张卡牌（萧炎 + 萧薰儿 + 美杜莎）" % _all_cards.size())


## 通过 ID 查找卡牌（返回副本）
static func get_card_by_id(card_id: String) -> CardData:
	_ensure_loaded()
	for card in _all_cards:
		if card.id == card_id:
			return card.duplicate_card()
	push_warning("CardDatabase: 未找到卡牌 ID=%s" % card_id)
	return null


## 通过 ID 查找卡牌（返回原始引用，仅供内部使用）
static func _find_card(card_id: String) -> CardData:
	_ensure_loaded()
	for card in _all_cards:
		if card.id == card_id:
			return card
	return null


## 获取所有已加载卡牌（返回副本列表）
static func get_all_cards() -> Array[CardData]:
	_ensure_loaded()
	var result: Array[CardData] = []
	for card in _all_cards:
		result.append(card.duplicate_card())
	return result


## 根据角色创建初始卡组
static func create_starter_deck_for_character(char_id: String) -> Array[CardData]:
	_ensure_loaded()
	var strike_id = _get_basic_strike_id(char_id)
	var defense_id = _get_basic_defense_id(char_id)
	var deck: Array[CardData] = []

	# 美杜莎特殊处理：基础打击×4 + 基础防御×4 + 毒牙×1 + 女王威压×1
	if char_id == "cailin":
		for i in range(4):
			var card = get_card_by_id("cailin_strike")
			if card:
				deck.append(card)
		for i in range(4):
			var card = get_card_by_id("cailin_defense")
			if card:
				deck.append(card)
		var venom_fang = get_card_by_id("cailin_venom_fang")
		if venom_fang:
			deck.append(venom_fang)
		var queen_pressure = get_card_by_id("queen_pressure")
		if queen_pressure:
			deck.append(queen_pressure)
		return deck

	# 其他角色：基础打击×5 + 基础防御×4 + 额外1张
	for i in range(5):
		var card = get_card_by_id(strike_id)
		if card:
			deck.append(card)
	for i in range(4):
		var card = get_card_by_id(defense_id)
		if card:
			deck.append(card)
	# 萧炎额外：吹火掌
	if char_id == "xiaoyan":
		var fire_palm = get_card_by_id("fire_palm")
		if fire_palm:
			deck.append(fire_palm)
	# 萧薰儿额外：金光掌
	elif char_id == "xuner":
		var golden_palm = get_card_by_id("golden_light_palm")
		if golden_palm:
			deck.append(golden_palm)
	return deck


static func _get_basic_strike_id(char_id: String) -> String:
	match char_id:
		"xiaoyan": return "basic_strike"
		"xuner": return "xuner_strike"
		"cailin": return "cailin_strike"
		_: return "basic_strike"


static func _get_basic_defense_id(char_id: String) -> String:
	match char_id:
		"xiaoyan": return "basic_defense"
		"xuner": return "xuner_defense"
		"cailin": return "cailin_defense"
		_: return "basic_defense"


## 根据角色获取奖励卡池（该角色专属卡 + 通用卡，排除其他角色专属卡）
static func create_reward_pool_for_character(char_id: String) -> Array[CardData]:
	_ensure_loaded()
	var pool: Array[CardData] = []
	var starter_ids = [
		"basic_strike", "basic_defense", "fire_palm",
		"xuner_strike", "xuner_defense", "golden_light_palm",
		"cailin_strike", "cailin_defense", "cailin_venom_fang", "queen_pressure",
	]
	for card in _all_cards:
		if card.id in starter_ids:
			continue
		if card.card_type == CardData.CardType.CURSE:
			continue
		if card.card_type == CardData.CardType.STATUS:
			continue
		# 排除其他角色专属卡
		if card.character_id != "" and card.character_id != char_id:
			continue
		pool.append(card.duplicate_card())
	return pool
