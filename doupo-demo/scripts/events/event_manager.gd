## 事件逻辑管理器
## 处理事件选择、结果执行
class_name EventManager

const PERMANENT_STRENGTH_FLAG_PREFIX := "event_permanent_strength_"


## 选择事件（按场景隔离）
static func generate_event() -> EventModel:
	var scene_id = RunManager.current_scene

	# 1. 检查强制事件（如药老苏醒）
	var forced = EventDatabase.get_forced_event(scene_id, RunManager.completed_events, RunManager.event_flags)
	if forced != null:
		return forced

	# 2. 检查前置标记事件（如三年之约）
	var flag_event = EventDatabase.get_flag_event(scene_id, RunManager.completed_events, RunManager.event_flags)
	if flag_event != null:
		return flag_event

	# 3. 按概率随机选类型
	var roll = RNGManager.event_rng.randi() % 100
	var category: EventModel.Category
	if roll < 40:
		category = EventModel.Category.PLOT
	elif roll < 65:
		category = EventModel.Category.COMBAT
	elif roll < 85:
		category = EventModel.Category.REWARD
	else:
		category = EventModel.Category.RISK

	# 4. 从该场景该类型中排除已完成事件后随机选
	var event = EventDatabase.get_random_event(scene_id, category, RunManager.completed_events, RunManager.event_flags)
	if event != null:
		return event

	# [FIX: Bug 7] 该类型无可用事件，降级策略改为"真随机合并池"
	# 获取该场景下所有剩余未完成、且满足前置条件的事件进行随机，避免事件池偏科
	var all_events = EventDatabase.get_events_for_scene(scene_id)
	var candidates: Array[EventModel] = []

	for e in all_events:
		# 排除专属角色不符的
		if e.character_id != "" and e.character_id != PlayerManager.character_id:
			continue
		# 排除已完成的、强制触发的(强制触发已在上面拦截)、守灵事件
		if e.id not in RunManager.completed_events and not e.is_forced and not e.is_ancient:
			# 检查前置标记是否满足
			if e.can_trigger(RunManager.event_flags):
				candidates.append(e)

	if candidates.size() > 0:
		return candidates[RNGManager.event_rng.randi() % candidates.size()]

	return null


## 执行选项结果
## 返回 { "log": Array[String], "needs_combat": bool, "combat_id": String }
static func apply_choice(event: EventModel, choice_idx: int) -> Dictionary:
	var result = {
		"log": [],
		"needs_combat": false,
		"combat_id": "",
		"deferred_outcomes": [],
		"deferred_gold_cost": 0,
		"deferred_potion_cost": 0,
	}

	# 防止重复执行：事件已完成时跳过
	if event.id in RunManager.completed_events:
		result.log.append("[color=gray]该事件已完成[/color]")
		return result

	var choices = event.get_choices()
	if choice_idx < 0 or choice_idx >= choices.size():
		return result

	var choice = choices[choice_idx]

	# 验证资源是否足够（仅验证，不扣费——COMBAT选项延迟扣费）
	if choice.gold_cost > 0 and PlayerManager.gold < choice.gold_cost:
		result.log.append("[color=red]金币不足！需要 %d 金币[/color]" % choice.gold_cost)
		return result

	if choice.required_relic_id > 0 and not PlayerManager.has_relic(choice.required_relic_id):
		result.log.append("[color=red]缺少所需遗物！[/color]")
		return result

	if choice.potion_cost > 0 and PlayerManager.potions.size() < choice.potion_cost:
		result.log.append("[color=red]丹药不足！需要 %d 瓶丹药[/color]" % choice.potion_cost)
		return result

	# 按概率决定成功/失败
	var outcomes_to_apply: Array
	if choice.probability < 1.0:
		var roll = RNGManager.event_rng.randf()
		if roll < choice.probability:
			outcomes_to_apply = choice.outcomes
			result.log.append("[color=green]成功！[/color]")
		else:
			outcomes_to_apply = choice.fail_outcomes
			result.log.append("[color=red]失败...[/color]")
	else:
		outcomes_to_apply = choice.outcomes

	# 检查是否有COMBAT结果
	var has_combat = false
	for outcome in outcomes_to_apply:
		if outcome.type == EventModel.OutcomeType.COMBAT:
			has_combat = true
			break

	if has_combat:
		# 有战斗：全部延迟到胜利后执行（SL回到选择页时状态不变）
		# 金币/丹药消耗也延迟——SL不会丢失资源
		if choice.gold_cost > 0:
			result.deferred_gold_cost = choice.gold_cost
		if choice.potion_cost > 0:
			result.deferred_potion_cost = choice.potion_cost
		for outcome in outcomes_to_apply:
			if outcome.type == EventModel.OutcomeType.COMBAT:
				result.needs_combat = true
				result.combat_id = outcome.ref_id
				if outcome.description != "":
					result.log.append("[color=red]%s[/color]" % outcome.description)
			else:
				result.deferred_outcomes.append(outcome)
	else:
		# 非战斗路径：先扣费再发奖励（原子性）
		if choice.gold_cost > 0:
			PlayerManager.spend_gold(choice.gold_cost)
			result.log.append("[color=yellow]交出 %d 金币[/color]" % choice.gold_cost)
		if choice.potion_cost > 0:
			for _i in range(choice.potion_cost):
				if PlayerManager.potions.size() > 0:
					PlayerManager.remove_potion(0)
			result.log.append("[color=yellow]交出 %d 瓶丹药[/color]" % choice.potion_cost)
		for outcome in outcomes_to_apply:
			_execute_outcome(outcome, result)

	# 无结果时显示默认文本
	if result.log.is_empty():
		if choice.description_rich != "":
			result.log.append("[color=gray]%s[/color]" % choice.description_rich)
		else:
			result.log.append("[color=gray]你选择了 %s[/color]" % choice.text)

	# 标记事件完成（有战斗时不标记，胜利后由_on_battle_ended标记）
	if not result.needs_combat:
		if event.id not in RunManager.completed_events:
			RunManager.completed_events.append(event.id)

	return result


## 执行单个结果
static func _execute_outcome(outcome: EventModel.EventOutcome, result: Dictionary) -> void:
	match outcome.type:
		EventModel.OutcomeType.GOLD:
			PlayerManager.add_gold(outcome.value)
			result.log.append("[color=yellow]金币 +%d[/color]" % outcome.value)

		EventModel.OutcomeType.HEAL:
			var old_hp = PlayerManager.hp
			PlayerManager.heal(outcome.value)
			var healed = PlayerManager.hp - old_hp
			result.log.append("[color=green]恢复 %d 点HP[/color]" % healed)

		EventModel.OutcomeType.MAX_HP:
			PlayerManager.modify_max_hp(outcome.value)
			result.log.append("[color=green]最大HP +%d[/color]" % outcome.value)

		EventModel.OutcomeType.DAMAGE:
			PlayerManager.set_hp(max(1, PlayerManager.hp - outcome.value))
			result.log.append("[color=red]受到 %d 点伤害[/color]" % outcome.value)
			# 遗物: 事件中失去HP时获得金币（魔兽山脉矿石）
			RelicManager.on_event_hp_loss(null, PlayerManager.relics)

		EventModel.OutcomeType.CARD:
			_give_card(outcome.ref_id, result)

		EventModel.OutcomeType.RELIC:
			_give_relic(outcome.ref_id, result)

		EventModel.OutcomeType.POTION:
			var potion_count = max(1, outcome.value)
			for _i in range(potion_count):
				var potion: PotionData = null
				if outcome.ref_id != "" and outcome.ref_id.is_valid_int():
					potion = PotionDatabase.get_potion(outcome.ref_id.to_int())
				if potion == null:
					potion = PotionManager.get_random_potion()
				if potion != null:
					if PlayerManager.add_potion(potion):
						result.log.append("[color=cyan]获得丹药「%s」[/color]" % potion.potion_name)
					else:
						result.log.append("[color=gray]丹药背包已满，无法获得更多丹药[/color]")
						break
				else:
					result.log.append("[color=gray]没有可用的丹药[/color]")
					break

		EventModel.OutcomeType.COMBAT:
			result.needs_combat = true
			result.combat_id = outcome.ref_id
			if outcome.description != "":
				result.log.append("[color=red]%s[/color]" % outcome.description)

		EventModel.OutcomeType.FLAG:
			RunManager.add_event_flag(outcome.ref_id)
			if outcome.description != "":
				result.log.append("[color=cyan]%s[/color]" % outcome.description)

		EventModel.OutcomeType.REMOVE_CARD:
			var remove_count = max(1, outcome.value)
			for _ri in range(remove_count):
				if PlayerManager.deck.size() > 0:
					var idx = RNGManager.event_rng.randi() % PlayerManager.deck.size()
					var removed = PlayerManager.deck[idx]
					PlayerManager.deck.remove_at(idx)
					result.log.append("[color=gray]失去卡牌「%s」[/color]" % removed.card_name)
				else:
					result.log.append("[color=gray]卡组为空，无法移除[/color]")
					break

		EventModel.OutcomeType.CURSE_CARD:
			_give_curse_card(outcome.ref_id, result)

		EventModel.OutcomeType.UPGRADE_CARD:
			_upgrade_random_cards(outcome.value, result)

		EventModel.OutcomeType.PERMA_STRENGTH:
			_add_permanent_strength(outcome.value)
			result.log.append("[color=orange]永久力量 +%d[/color]" % outcome.value)


static func _add_permanent_strength(amount: int) -> void:
	for _i in range(max(0, amount)):
		var idx = 1
		while RunManager.has_event_flag("%s%d" % [PERMANENT_STRENGTH_FLAG_PREFIX, idx]):
			idx += 1
		RunManager.add_event_flag("%s%d" % [PERMANENT_STRENGTH_FLAG_PREFIX, idx])


## 给予卡牌
static func _give_card(ref_id: String, result: Dictionary) -> void:
	# 根据ref_id给予对应卡牌
	# "rare" -> 随机稀有卡, "epic" -> 随机史诗卡, "legendary" -> 随机传说卡
	# 具体卡牌ID -> 给予指定卡牌
	var card: CardData = null

	match ref_id:
		"rare":
			var cards = CardDatabase.create_reward_pool_for_character(PlayerManager.character_id)
			var rare_cards: Array[CardData] = []
			for c in cards:
				if c.rarity == CardData.CardRarity.RARE:
					rare_cards.append(c)
			if rare_cards.size() > 0:
				card = rare_cards[RNGManager.event_rng.randi() % rare_cards.size()]
		"epic":
			var cards = CardDatabase.create_reward_pool_for_character(PlayerManager.character_id)
			var epic_cards: Array[CardData] = []
			for c in cards:
				if c.rarity == CardData.CardRarity.EPIC:
					epic_cards.append(c)
			if epic_cards.size() > 0:
				card = epic_cards[RNGManager.event_rng.randi() % epic_cards.size()]
		"legendary":
			var cards = CardDatabase.create_reward_pool_for_character(PlayerManager.character_id)
			var leg_cards: Array[CardData] = []
			for c in cards:
				if c.rarity == CardData.CardRarity.LEGENDARY:
					leg_cards.append(c)
			if leg_cards.size() > 0:
				card = leg_cards[RNGManager.event_rng.randi() % leg_cards.size()]
		_:
			# 先从奖励卡池查找
			var cards = CardDatabase.create_reward_pool_for_character(PlayerManager.character_id)
			for c in cards:
				if c.id == ref_id:
					card = c
					break
			# 奖励池找不到时，从全卡池查找（支持诅咒牌等）
			if card == null:
				card = CardDatabase.get_card_by_id(ref_id)

	if card != null:
		PlayerManager.add_card_to_deck(card)
		result.log.append("[color=cyan]获得卡牌「%s」[/color]" % card.card_name)
	else:
		result.log.append("[color=gray]未找到卡牌（ID:%s）[/color]" % ref_id)


## 给予遗物
static func _give_relic(ref_id: String, result: Dictionary) -> void:
	# "random_common" -> 随机普通遗物
	# "rare" -> 随机稀有遗物
	# "epic" -> 随机史诗遗物
	# "legendary" -> 随机传说遗物
	# 数字ID -> 给予指定遗物
	if ref_id == "random_common" or ref_id == "rare" or ref_id == "epic" or ref_id == "legendary":
		var target_rarity: RelicData.Rarity
		match ref_id:
			"random_common": target_rarity = RelicData.Rarity.COMMON
			"rare": target_rarity = RelicData.Rarity.RARE
			"epic": target_rarity = RelicData.Rarity.EPIC
			"legendary": target_rarity = RelicData.Rarity.LEGENDARY
			_: target_rarity = RelicData.Rarity.COMMON
		var all = RelicDatabase.get_relics_by_rarity(target_rarity)
		var available: Array[RelicData] = []
		for r in all:
			if not PlayerManager.has_relic(r.id) and RelicDatabase.is_available_for_character(r, PlayerManager.character_id):
				available.append(r)
		if available.size() > 0:
			var relic = available[RNGManager.event_rng.randi() % available.size()]
			PlayerManager.add_relic(relic)
			result.log.append("[color=cyan]获得遗物「%s」[/color]" % relic.relic_name)
		else:
			# 没有可用遗物，给金币补偿
			PlayerManager.add_gold(50)
			result.log.append("[color=gray]没有可用遗物，获得 50 金币补偿[/color]")
	else:
		var relic_id = ref_id.to_int()
		var relic = RelicDatabase.get_relic(relic_id)
		if relic != null and RelicDatabase.is_available_for_character(relic, PlayerManager.character_id):
			if PlayerManager.has_relic(relic.id):
				# 已有遗物，给金币补偿
				PlayerManager.add_gold(50)
				result.log.append("[color=gray]已拥有遗物「%s」，获得 50 金币补偿[/color]" % relic.relic_name)
			else:
				PlayerManager.add_relic(relic)
				result.log.append("[color=cyan]获得遗物「%s」[/color]" % relic.relic_name)
		elif relic != null:
			# [FIX: Bug 9] 遗物不兼容时给予50金币补偿，避免玩家白忙一场
			PlayerManager.add_gold(50)
			result.log.append("[color=gray]遗物「%s」与当前角色不兼容，获得 50 金币补偿[/color]" % relic.relic_name)
		else:
			result.log.append("[color=gray]未找到遗物（ID:%s）[/color]" % ref_id)


## 给予诅咒牌（直接从全卡池查找，洗入牌库）
static func _give_curse_card(card_id: String, result: Dictionary) -> void:
	var card = CardDatabase.get_card_by_id(card_id)
	if card != null:
		PlayerManager.add_card_to_deck(card)
		result.log.append("[color=purple]诅咒牌「%s」洗入牌库...[/color]" % card.card_name)
	else:
		result.log.append("[color=gray]诅咒牌（ID:%s，未找到）[/color]" % card_id)


## 随机升级牌库中N张卡牌
static func _upgrade_random_cards(count: int, result: Dictionary) -> void:
	var upgradable: Array[CardData] = []
	for card in PlayerManager.deck:
		if not card.upgraded:
			upgradable.append(card)
	if upgradable.is_empty():
		result.log.append("[color=gray]没有可升级的卡牌[/color]")
		return
	var actual = min(count, upgradable.size())
	for i in range(actual):
		var idx = RNGManager.event_rng.randi() % upgradable.size()
		var card = upgradable[idx]
		card.apply_upgrade()
		upgradable.remove_at(idx)
		result.log.append("[color=cyan]卡牌「%s」已升级[/color]" % card.card_name)
