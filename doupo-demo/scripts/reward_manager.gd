## 战斗奖励管理器
## 生成战斗后的金币和卡牌奖励
class_name RewardManager

## 战斗类型
enum BattleType { NORMAL, ELITE, BOSS }

## 生成金币奖励
static func generate_gold_reward(battle_type: BattleType) -> int:
	match battle_type:
		BattleType.NORMAL:
			return RNGManager.drop_rng.randi_range(15, 25)
		BattleType.ELITE:
			return RNGManager.drop_rng.randi_range(30, 50)
		BattleType.BOSS:
			return RNGManager.drop_rng.randi_range(80, 120)
	return 15


## 生成卡牌奖励(3张供选择)
static func generate_card_rewards(battle_type: BattleType) -> Array[CardData]:
	var cards: Array[CardData] = []
	var pool = _get_reward_pool()

	for i in range(3):
		var rarity = _roll_rarity(battle_type)
		var card = _pick_card_of_rarity(pool, rarity)
		if card != null:
			cards.append(card)
	return cards


## 按战斗类型获取稀有度
static func _roll_rarity(battle_type: BattleType) -> CardData.CardRarity:
	var roll = RNGManager.drop_rng.randi() % 100
	match battle_type:
		BattleType.NORMAL:
			# Common 55%, Rare 37%, Epic 8%
			if roll < 55:
				return CardData.CardRarity.COMMON
			elif roll < 92:
				return CardData.CardRarity.RARE
			else:
				return CardData.CardRarity.EPIC
		BattleType.ELITE:
			# Common 30%, Rare 45%, Epic 25%
			if roll < 30:
				return CardData.CardRarity.COMMON
			elif roll < 75:
				return CardData.CardRarity.RARE
			else:
				return CardData.CardRarity.EPIC
		BattleType.BOSS:
			# 全部稀有/史诗
			if roll < 60:
				return CardData.CardRarity.RARE
			else:
				return CardData.CardRarity.EPIC
	return CardData.CardRarity.COMMON


## 从奖励池中选取指定稀有度的卡牌
static func _pick_card_of_rarity(pool: Array[CardData], rarity: CardData.CardRarity) -> CardData:
	var candidates: Array[CardData] = []
	for card in pool:
		if card.rarity == rarity:
			candidates.append(card)

	if candidates.size() == 0:
		# 降级查找
		for card in pool:
			if card.rarity == CardData.CardRarity.COMMON:
				candidates.append(card)

	if candidates.size() == 0:
		return null

	return candidates[RNGManager.drop_rng.randi() % candidates.size()].duplicate_card()


## 获取奖励卡池（根据当前角色过滤）
static func _get_reward_pool() -> Array[CardData]:
	return CardDatabase.create_reward_pool_for_character(PlayerManager.character_id)


## 生成遗物奖励(返回null表示无掉落)
static func generate_relic_reward(battle_type: BattleType) -> RelicData:
	var roll = RNGManager.drop_rng.randi() % 100
	var rarity: RelicData.Rarity

	match battle_type:
		BattleType.NORMAL:
			# 8%普通 + 2%稀有 = 10%总概率
			if roll < 8:
				rarity = RelicData.Rarity.COMMON
			elif roll < 10:
				rarity = RelicData.Rarity.RARE
			else:
				return null
		BattleType.ELITE:
			# 25%普通 + 35%稀有 + 15%史诗 + 5%传说 = 80%
			if roll < 25:
				rarity = RelicData.Rarity.COMMON
			elif roll < 60:
				rarity = RelicData.Rarity.RARE
			elif roll < 75:
				rarity = RelicData.Rarity.EPIC
			elif roll < 80:
				rarity = RelicData.Rarity.LEGENDARY
			else:
				return null
		BattleType.BOSS:
			# 15%普通 + 30%稀有 + 35%史诗 + 20%传说 = 100%
			if roll < 15:
				rarity = RelicData.Rarity.COMMON
			elif roll < 45:
				rarity = RelicData.Rarity.RARE
			elif roll < 80:
				rarity = RelicData.Rarity.EPIC
			else:
				rarity = RelicData.Rarity.LEGENDARY

	return _pick_relic_of_rarity(rarity)


## 从指定稀有度中随机选取遗物（过滤已拥有 + 角色专属）
static func _pick_relic_of_rarity(rarity: RelicData.Rarity) -> RelicData:
	var pool = RelicDatabase.get_relics_by_rarity(rarity)
	if pool.is_empty():
		return null
	# 过滤已拥有遗物 + 角色专属
	var available: Array[RelicData] = []
	for relic in pool:
		if not PlayerManager.has_relic(relic.id) and RelicDatabase.is_available_for_character(relic, PlayerManager.character_id):
			available.append(relic)
	if available.is_empty():
		return null
	return available[RNGManager.drop_rng.randi() % available.size()]
