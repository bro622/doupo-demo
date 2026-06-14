## 战斗管理器
## 控制回合制战斗流程、卡牌效果结算
class_name BattleManager

## 异火选择信号（异火置换等卡牌使用）
signal fire_type_requested

## 异火选择信号（灵魂感知等选择弃置）
signal choose_discard_requested(count: int)

## 消耗选择信号（药鼎淬炼等选择消耗）
signal choose_exhaust_requested(count: int)

## 遗物选择信号（炎帝遗物等回合开始选择）
signal relic_choice_requested(option1: String, option2: String)

## 战斗状态
enum BattleState { NOT_STARTED, PLAYER_TURN, ENEMY_TURN, VICTORY, DEFEAT }

## 战斗参与者
var player: Player
var enemies: Array[Enemy] = []
var state: BattleState = BattleState.NOT_STARTED

## 战斗类型(0=NORMAL, 1=ELITE, 2=BOSS)
var battle_type: int = 0

## 异火选择等待状态
var _pending_fire_select: bool = false
var _pending_fire_msg: String = ""
var _pending_fire_card: CardData = null

## 弃置选择等待状态
var _pending_discard: bool = false
var _pending_discard_msg: String = ""
var _pending_discard_card: CardData = null

## 消耗选择等待状态
var _pending_exhaust: bool = false
var _pending_exhaust_msg: String = ""
var _pending_exhaust_card: CardData = null

## 遗物选择等待状态
var _pending_relic_choice: bool = false
var _pending_relic_msg: String = ""
var _pending_relic_choice_relic: RelicData = null
var _pending_relic_queue: Array = []  # 剩余待选择的遗物

## 药水背包（从PlayerManager复制，战斗结束写回）
var potions: Array[PotionData] = []
## 战斗中被消耗的丹药ID（死亡保护等绕过use_potion的路径）
## 静态变量：player.gd 可直接写入，sync时读取并清空
static var _consumed_potion_ids: Array[int] = []

## 回合计数
var turn_count: int = 0

## 本回合玩家已打出的牌数（用于叠浪掌等联动）
var cards_played_this_turn: int = 0
## 本回合玩家已打出的攻击牌数（用于八极崩条件判断）
var attack_cards_played_this_turn: int = 0

## 已报告死亡的敌人名称（避免重复输出死亡消息）
var _defeated_enemies: Array[int] = []

## 最近一次出牌造成的伤害（用于UI显示浮动数字）
var last_damage_dealt: int = 0
var last_damage_target_index: int = -1

## 战斗日志回调
var log_callback: Callable


func _init() -> void:
	pass


## 施加蛇毒（统一接口，包含女王被动和能力牌加成）
func _apply_venom(target: Enemy, base_stacks: int) -> String:
	if base_stacks <= 0 or target == null or not target.is_alive():
		return ""
	var total = base_stacks
	# 女王姿态被动：施加蛇毒时+1层
	if player.current_stance == 1:
		total += 1
	# 蟒毒蔓延：施加蛇毒时额外+N层
	total += player.ability_extra_venom
	# 化骨珠：施加蛇毒时层数+1
	for relic in PlayerManager.relics:
		if relic.effect_type == RelicData.EffectType.VENOM_STACK_BONUS:
			total += relic.effect_value
			break
	target.apply_venom(total)
	return "  %s 获得 蛇毒 ×%d\n" % [target.char_name, total]


## 施加金印并检查引爆
## 返回 { "detonated": bool, "msg": String }
func _apply_gold_seal_and_check(target: Enemy, stacks: int) -> Dictionary:
	var result = { "detonated": false, "msg": "" }
	if stacks <= 0 or target == null or not target.is_alive():
		return result

	# 印记共鸣：每回合首次施加金印时额外+N
	var first_apply_bonus = 0
	if player.ability_extra_gold_seal_first > 0 and not player.seal_resonance_used_this_turn:
		first_apply_bonus = player.ability_extra_gold_seal_first
		player.seal_resonance_used_this_turn = true

	var total_stacks = stacks + first_apply_bonus
	target.apply_gold_seal(total_stacks)
	result.msg += "  %s 获得 金印 ×%d\n" % [target.char_name, total_stacks]

	# 检查引爆
	var threshold = player.ability_detonation_threshold
	# 古族玉佩：金印引爆阈值减少
	for relic in PlayerManager.relics:
		if relic.effect_type == RelicData.EffectType.GOLD_MARK_THRESHOLD_REDUCE:
			threshold = max(1, threshold - relic.effect_value)
			break
	while target.gold_seal >= threshold and target.is_alive():
		# 触发引爆
		target.gold_seal -= threshold
		player.detonation_count_this_turn += 1
		player.detonation_count_total += 1
		# 10点真实伤害
		var actual = target.take_damage(10, true)
		result.msg += "  ★ 金印引爆!对 %s 造成 10 点真实伤害\n" % target.char_name
		# 返还1点能量
		player.gain_energy(1)
		result.msg += "    返还 1 点能量\n"
		result.detonated = true
		# 金焰共鸣：每次引爆获得护盾
		if player.ability_block_on_detonate > 0:
			player.gain_block(player.ability_block_on_detonate)
			result.msg += "    金焰共鸣：获得 %d 护盾\n" % player.ability_block_on_detonate
		# 金莲守护：每次引爆对所有敌人造成伤害
		if player.ability_damage_on_detonate > 0:
			for enemy in enemies:
				if enemy.is_alive():
					enemy.take_damage(player.ability_damage_on_detonate)
			result.msg += "    金莲守护：全体敌人受 %d 伤害\n" % player.ability_damage_on_detonate
		# 遗物：古族金令 — 每回合前2次引爆各抽1牌
		if player.detonation_count_this_turn <= 2:
			for relic in PlayerManager.relics:
				if relic.id == 2:  # 古族金令
					var drawn = player.draw_cards(1)
					if drawn.size() > 0:
						result.msg += "    古族金令：抽 %s\n" % drawn[0].card_name
					break

	return result


## 初始化战斗
func setup_battle(p_player: Player, p_enemies: Array[Enemy], p_battle_type: int = 0) -> void:
	player = p_player
	enemies = p_enemies
	battle_type = p_battle_type
	state = BattleState.NOT_STARTED
	turn_count = 0
	# 每场战斗重置（古族金令：每场第一张攻击牌触发一次）
	player.first_turn_attack_bonus_used = false
	# 美杜莎：每场战斗重置姿态
	player.current_stance = 0
	# 从PlayerManager复制药水
	potions.clear()
	_consumed_potion_ids.clear()
	for p in PlayerManager.potions:
		potions.append(p)


## 开始战斗
func start_battle() -> String:
	state = BattleState.PLAYER_TURN
	turn_count = 1
	cards_played_this_turn = 0
	attack_cards_played_this_turn = 0

	# 清除上一场战斗的在场能力牌
	player.in_play.clear()
	player.battle_start_hp = player.hp

	# 重置美杜莎姿态切换状态
	player.stance_switch_triggered_this_battle = false

	# 初始化玩家牌组
	if player.draw_pile.size() == 0:
		player.init_deck(CardDatabase.create_starter_deck_for_character(PlayerManager.character_id))

	var msg = "=== 战斗开始 ===\n"
	msg += "遭遇敌人：\n"
	for enemy in enemies:
		msg += "  - %s (HP:%d)\n" % [enemy.char_name, enemy.max_hp]
	msg += "\n"

	# 遗物： 战斗开始效果
	RelicManager.on_battle_start(player, PlayerManager.relics, enemies)

	# 事件永久力量加成
	var event_strength_bonus = 0
	if RunManager.has_event_flag("ancient_power_boost"):
		event_strength_bonus += 1
	for flag in RunManager.event_flags.keys():
		if str(flag).begins_with(EventManager.PERMANENT_STRENGTH_FLAG_PREFIX):
			event_strength_bonus += 1
	player.strength += event_strength_bonus

	# 事件22选项C:观战学习 — 首回合多抽1牌（一次性）
	if RunManager.has_event_flag("learned_from_observation"):
		RunManager.remove_event_flag("learned_from_observation")
		player.cards_per_turn += 1
		player._bonus_first_turn_draw = 1

	# 开始玩家回合
	msg += _start_player_turn()
	return msg


## 开始玩家回合
func _start_player_turn() -> String:
	var turn_result = player.on_turn_start()
	var msg = ""
	if turn_result["msg"] != "":
		msg += turn_result["msg"]
	# 星空体质挤出的异火需要激发
	if turn_result["ejected_fire"] >= 0:
		msg += _apply_fire_evoke(turn_result["ejected_fire"], 1)
	cards_played_this_turn = 0
	attack_cards_played_this_turn = 0
	_defeated_enemies.clear()

	# 萧薰儿：帝炎刻印 — 回合开始给所有敌人施加金印
	if player.ability_gold_seal_on_turn_start > 0:
		for enemy in enemies:
			if enemy.is_alive():
				var seal_result = _apply_gold_seal_and_check(enemy, player.ability_gold_seal_on_turn_start)
				msg += seal_result.msg

	# 萧薰儿：古族千年传承 — 每回合第一张牌打出两次
	if player.ability_first_card_double:
		player.next_card_double = true

	# 美杜莎：蟒毒体质 — 回合开始给所有敌人施加蛇毒
	if player.ability_venom_on_turn_start > 0:
		for enemy in enemies:
			if enemy.is_alive():
				msg += _apply_venom(enemy, player.ability_venom_on_turn_start)

	# 遗物： 回合开始效果
	var relic_choices = RelicManager.on_turn_start(player, PlayerManager.relics, turn_count, enemies)

	msg += "--- 第 %d 回合 ---\n" % turn_count
	msg += "%s\n" % player.get_status_text()

	# 遗物选择：需要玩家选择时暂停，等待UI回调
	if not relic_choices.is_empty():
		_pending_relic_queue = relic_choices.slice(1)  # 存储剩余
		var choice = relic_choices[0]
		_pending_relic_choice = true
		_pending_relic_msg = msg
		_pending_relic_choice_relic = choice.relic
		relic_choice_requested.emit(choice.option1, choice.option2)
		return msg

	# 诅咒牌抽到时的提示
	if player.last_curse_log != "":
		msg += player.last_curse_log

	# 检查玩家是否存活（可能被燃烧/蛇毒伤害致死）
	if not player.is_alive():
		state = BattleState.DEFEAT
		msg += "\n你被击败了!\n"
		return msg

	# 显示敌人意图
	msg += "\n敌人状态：\n"
	for enemy in enemies:
		if enemy.is_alive():
			msg += "  %s | %s\n" % [enemy.get_status_text(), enemy.get_intent_text()]

	msg += "\n你的手牌：\n"
	msg += player.get_hand_text()
	msg += "\n%s\n" % player.get_pile_text()
	return msg


## 玩家打出卡牌
func player_play_card(hand_index: int, target_index: int = 0) -> String:
	if state != BattleState.PLAYER_TURN:
		return "当前不是你的回合！"

	if hand_index < 0 or hand_index >= player.hand.size():
		return "无效的手牌编号！"

	var card = player.hand[hand_index]

	# 检查诅咒牌
	if card.card_type == CardData.CardType.CURSE:
		# 诅咒牌触发被动效果（如斗气封印：下一张牌+1费）
		return _trigger_curse_passive(card)

	# 检查状态牌（风缠等，不可打出）
	if card.card_type == CardData.CardType.STATUS:
		return "状态牌无法使用!\n"

	# 检查斗气（含临时费用修改 + 能力牌遗物减免）
	var actual_cost = max(0, card.cost + player.next_card_cost_modifier - player.hand_cost_reduction)
	# 菩提古树之心：首张牌免费
	if player.first_card_free_this_turn:
		actual_cost = 0
		player.first_card_free_this_turn = false
	# 古帝碎涅指：每次引爆减少X费用
	if card.cost_reduction_per_detonate > 0:
		actual_cost = max(0, actual_cost - player.detonation_count_total * card.cost_reduction_per_detonate)
	# 致命绞杀：吞天蟒姿态下耗能-N
	if card.python_cost_reduction > 0 and player.current_stance == 2:
		actual_cost = max(0, actual_cost - card.python_cost_reduction)
	if card.card_type == CardData.CardType.ABILITY:
		var ability_reduction = RelicManager.get_ability_cost_reduction(PlayerManager.relics)
		actual_cost = max(0, actual_cost - ability_reduction)
	# 遗物：古帝残魂碎片 — 第一回合前N张牌费用为0
	if turn_count == 1:
		var free_count = RelicManager.get_first_turn_free_cards(PlayerManager.relics)
		if free_count > 0 and player.first_turn_free_cards_used < free_count:
			actual_cost = 0
			player.next_card_cost_modifier = -card.cost  # 让player.play_card也扣0能量
			player.first_turn_free_cards_used += 1
	# 遗物：玄重尺 — 每回合第一张攻击牌额外消耗1能量
	if card.card_type == CardData.CardType.ATTACK and not player.xuanzhongchi_first_attack_pending:
		for relic in PlayerManager.relics:
			if relic.effect_type == RelicData.EffectType.FIRST_ATTACK_ENERGY_COST:
				actual_cost += relic.effect_value
				player.xuanzhongchi_first_attack_pending = true
				break

	# 检查条件牌（异火连击：必须本回合激发过异火）— 在扣除能量前检查
	if card.id == "fire_combo":
		if not player.evoked_this_turn:
			return "[%s] 需要本回合激发过异火才能打出！" % card.card_name

	if actual_cost > player.energy:
		return "斗气不足!需要%d,当前%d" % [actual_cost, player.energy]

	# 扣除能量（含玄重尺等battle_manager层加价）
	player.energy -= actual_cost
	player._skip_energy_deduction = true

	# 获取目标敌人
	var target_enemy: Enemy = null
	if enemies.size() > 0:
		if target_index >= 0 and target_index < enemies.size() and enemies[target_index].is_alive():
			target_enemy = enemies[target_index]
		else:
			for enemy in enemies:
				if enemy.is_alive():
					target_enemy = enemy
					break

	# 打出卡牌（消耗斗气、移出手牌，处理消耗关键字）
	player.play_card(hand_index)

	# 能力牌打出后立即重算被动效果（确保本回合生效）
	if card.card_type == CardData.CardType.ABILITY:
		player._recalculate_ability_effects()

	# 先计数再结算（combo检查需要包含当前牌）
	cards_played_this_turn += 1
	if card.card_type == CardData.CardType.ATTACK:
		attack_cards_played_this_turn += 1
	last_damage_dealt = 0
	last_damage_target_index = target_index
	var msg = _resolve_card_effect(card, target_enemy)

	# 古族战意：每打出4张牌，对随机敌人造成N伤害
	if player.ability_damage_per_4_cards > 0 and cards_played_this_turn % 4 == 0:
		var alive: Array[Enemy] = []
		for e in enemies:
			if e.is_alive():
				alive.append(e)
		if alive.size() > 0:
			var rand_target = alive[RNGManager.drop_rng.randi() % alive.size()]
			var dealt = rand_target.take_damage(player.ability_damage_per_4_cards)
			msg += "  ★ 古族战意：对 %s 造成 %d 伤害\n" % [rand_target.char_name, dealt]

	# 能力牌on-play触发（焚诀运转等）
	msg += _check_on_play_triggers(card)

	# 药皇戒指/千年传承：下一张牌打出两次（使用副本避免副作用重复）
	if player.next_card_double or player.next_card_double_remaining > 0:
		if player.next_card_double:
			player.next_card_double = false
		if player.next_card_double_remaining > 0:
			player.next_card_double_remaining -= 1
		msg += "  ★ 再次打出 [%s]!\n" % card.card_name
		msg += _resolve_card_effect(card.duplicate_card(), target_enemy)

	# 魂殿黑袍：首张攻击牌打出两次
	if player.first_attack_double_available and card.card_type == CardData.CardType.ATTACK:
		player.first_attack_double_available = false
		msg += "  ★ 再次打出 [%s]!（首攻双倍）\n" % card.card_name
		msg += _resolve_card_effect(card.duplicate_card(), target_enemy)

	# 检查战斗是否结束
	_check_battle_end()

	return msg


## 结算卡牌效果（关键字驱动）
func _resolve_card_effect(card: CardData, target: Enemy) -> String:
	var msg = "→ 使用 [%s] (%d费）\n" % [card.card_name, card.cost]
	var is_ability = card.card_type == CardData.CardType.ABILITY

	# 蟒毒腐蚀：先将目标护盾减半（在伤害结算之前）
	if card.halve_block and target and target.is_alive():
		target.block = target.block / 2
		msg += "  ★ 蟒毒腐蚀：%s 护盾减半\n" % target.char_name

	# 1. 造成伤害(ABILITY牌跳过——damage字段是被动参数）
	var base_dmg: int = 0
	if card.damage > 0 and not is_ability:
		base_dmg = player.calc_attack_damage(card.damage)

		# 退婚之辱：手牌中存在时，攻击牌伤害-2
		if player.has_card_in_hand("broken_engagement"):
			base_dmg = max(0, base_dmg - 2)

	# 数据驱动伤害加成（八极崩/叠浪掌/五轮离火法/佛怒火莲/光之箭/连击）
	# 在 card.damage>0 块外计算，确保0基础伤害+金印加成的牌（如穿刺之光）也能生效
	var target_gold_seal = target.gold_seal if target else 0
	var target_venom = target.venom if target else 0
	base_dmg += card.calc_bonus_damage(cards_played_this_turn - 1, player.fire_slots.size(), target_gold_seal, target_venom, attack_cards_played_this_turn - 1)

	if card.damage > 0 and not is_ability:
		# 数据驱动：狂狮罡气 — 拥有指定异火时返还能量
		if card.energy_refund_if_fire_type != "" and card.energy_refund_amount > 0:
			for ft in player.fire_slots:
				if ft == _parse_fire_type(card.energy_refund_if_fire_type):
					player.gain_energy(card.energy_refund_amount)
					msg += "  %s共鸣：返还 %d 点能量\n" % [player._get_fire_name(ft), card.energy_refund_amount]
					break

		# 特殊联动：焱暴 — 激发最前端异火（触发两次）
		# 已通过 evoke_count=2 处理

		# 应用遗物伤害加成
		base_dmg = RelicManager.on_damage_dealt(base_dmg, PlayerManager.relics, player)

		# 遗物：萧家功法残页 — 第一回合第一张伤害卡+3
		if turn_count == 1 and not player.first_turn_attack_bonus_used:
			for relic in PlayerManager.relics:
				if relic.effect_type == RelicData.EffectType.FIRST_TURN_FIRST_ATTACK_BONUS:
					base_dmg += relic.effect_value
					player.first_turn_attack_bonus_used = true
					break

		# 数据驱动：易伤目标伤害倍率（玄重尺斩）
		# 注意：仅对主目标生效,AOE+易伤倍率组合时其他敌人不受加成
		if card.damage_mult_if_vulnerable > 0 and target and target.is_alive() and target.vulnerable > 0:
			base_dmg *= card.damage_mult_if_vulnerable

	# 连击触发时额外伤害（需访问 player.ability_combo_no_condition)
	if card.combo_threshold > 0 and card.combo_bonus_damage > 0:
		if cards_played_this_turn >= card.combo_threshold or player.ability_combo_no_condition:
			base_dmg += card.combo_bonus_damage

	# 累计实际伤害（用于异火亘古尺等效果）— 声明在外层确保后续引用有效
	var total_actual_damage: int = 0
	# 美杜莎之怒：打出时随机进入一种姿态（只触发一次）
	if card.random_stance_on_hit:
		var new_stance = RNGManager.monster_rng.randi_range(1, 2)
		var switch_result = player.switch_stance(new_stance)
		if switch_result.changed:
			msg += switch_result.msg
	# 玄重尺：攻击牌无视护盾（真伤）
	var force_true_damage := card.true_damage
	for relic in PlayerManager.relics:
		if relic.effect_type == RelicData.EffectType.ATTACK_TRUE_DAMAGE:
			force_true_damage = true
			break
	# 焚炎谷令：有燃烧/蛇毒的敌人受伤+30%
	var burn_venom_bonus_pct := 0
	for relic in PlayerManager.relics:
		if relic.effect_type == RelicData.EffectType.BURN_OR_VENOM_DAMAGE_BONUS:
			burn_venom_bonus_pct = relic.effect_value
			break
	if base_dmg > 0:

		if card.aoe:
			for enemy in enemies:
				if enemy.is_alive():
					# 焚炎谷令：对有燃烧/蛇毒的敌人+伤
					var enemy_dmg = base_dmg
					if burn_venom_bonus_pct > 0 and (enemy.burn > 0 or enemy.venom > 0):
						enemy_dmg = int(enemy_dmg * (100 + burn_venom_bonus_pct) / 100.0)
					for i in card.hit_count:
						var actual = enemy.take_damage(enemy_dmg, force_true_damage)
						total_actual_damage += actual
						last_damage_dealt += actual
						if card.hit_count > 1:
							msg += "  第%d击 对 %s 造成 %d 点伤害\n" % [i + 1, enemy.char_name, actual]
							if card.apply_gold_seal > 0 and card.hit_count > 1 and enemy.is_alive():
								var hit_seal = _apply_gold_seal_and_check(enemy, card.apply_gold_seal)
								if hit_seal.msg != "":
									msg += hit_seal.msg
						else:
							msg += "  对 %s 造成 %d 点伤害\n" % [enemy.char_name, actual]
						# 玄重尺：击杀返还1能量
						if not enemy.is_alive():
							for relic in PlayerManager.relics:
								if relic.effect_type == RelicData.EffectType.ON_KILL_ENERGY or relic.effect_type_3 == RelicData.EffectType.ON_KILL_ENERGY:
									player.gain_energy(relic.effect_value)
									msg += "  ★ 击杀返能 +%d\n" % relic.effect_value
									break
		else:
			if target and target.is_alive():
				# 焚炎谷令：对有燃烧/蛇毒的敌人+伤
				var target_dmg = base_dmg
				if burn_venom_bonus_pct > 0 and (target.burn > 0 or target.venom > 0):
					target_dmg = int(target_dmg * (100 + burn_venom_bonus_pct) / 100.0)
				for i in card.hit_count:
					var actual = target.take_damage(target_dmg, force_true_damage)
					total_actual_damage += actual
					last_damage_dealt += actual
					if card.hit_count > 1:
						msg += "  第%d击 对 %s 造成 %d 点伤害\n" % [i + 1, target.char_name, actual]
						if card.apply_gold_seal > 0 and card.hit_count > 1 and target.is_alive():
							var hit_seal = _apply_gold_seal_and_check(target, card.apply_gold_seal)
							if hit_seal.msg != "":
								msg += hit_seal.msg
					else:
						msg += "  对 %s 造成 %d 点伤害\n" % [target.char_name, actual]
					# 玄重尺：击杀返还1能量
					if not target.is_alive():
						for relic in PlayerManager.relics:
							if relic.effect_type == RelicData.EffectType.ON_KILL_ENERGY or relic.effect_type_3 == RelicData.EffectType.ON_KILL_ENERGY:
								player.gain_energy(relic.effect_value)
								msg += "  ★ 击杀返能 +%d\n" % relic.effect_value
								break

	# 2. 获得护盾(ABILITY牌跳过——block字段是被动参数）
	if card.block > 0 and not is_ability:
		var block_amount = card.block
		# 萧家耻辱：手牌中存在时，护盾减半
		if player.has_card_in_hand("xiao_family_shame"):
			block_amount = roundi(block_amount * 0.5)
		block_amount = RelicManager.on_block_gained(block_amount, PlayerManager.relics)
		player.gain_block(block_amount)
		player.last_card_block = block_amount
		msg += "  获得 %d 点护盾\n" % block_amount
	# 连击触发时额外护盾
	if card.combo_threshold > 0 and card.combo_bonus_block > 0:
		if cards_played_this_turn >= card.combo_threshold or player.ability_combo_no_condition:
			player.gain_block(card.combo_bonus_block)
			msg += "  连击：额外获得 %d 护盾\n" % card.combo_bonus_block
	# 遗物：远古魔核 — 消耗卡牌时AOE伤害（独立于护盾判断）
	if card.exhaust:
		for relic in PlayerManager.relics:
			if relic.effect_type == RelicData.EffectType.EXHAUST_CARD_AOE_DAMAGE:
				for enemy in enemies:
					if enemy.is_alive():
						enemy.take_damage(relic.effect_value)
				msg += "  远古魔核：全体敌人受 %d 伤害\n" % relic.effect_value
				break

	# 3. 治疗
	if card.heal > 0:
		var old_hp = player.hp
		player.hp = min(player.max_hp, player.hp + card.heal)
		msg += "  回复 %d 点HP\n" % (player.hp - old_hp)

	# 4. 获得能量
	if card.hp_cost > 0:
		player.hp = max(1, player.hp - card.hp_cost)
		msg += "  失去 %d 点生命值\n" % card.hp_cost
	if card.gain_energy > 0 and not card.choose_exhaust:
		player.gain_energy(card.gain_energy)
		msg += "  恢复 %d 点斗气\n" % card.gain_energy

	# 5. 获得力量(ABILITY牌跳过——gain_strength字段是被动参数）
	if card.gain_strength > 0 and not is_ability:
		player.strength += card.gain_strength
		msg += "  力量+%d\n" % card.gain_strength
	# 连击触发时额外力量
	if card.combo_threshold > 0 and card.combo_bonus_strength > 0:
		if cards_played_this_turn >= card.combo_threshold or player.ability_combo_no_condition:
			player.strength += card.combo_bonus_strength
			msg += "  连击：力量+%d\n" % card.combo_bonus_strength
	# 连击触发时额外敏捷
	if card.combo_threshold > 0 and card.combo_bonus_dexterity > 0:
		if cards_played_this_turn >= card.combo_threshold or player.ability_combo_no_condition:
			player.dexterity += card.combo_bonus_dexterity
			msg += "  连击：敏捷+%d\n" % card.combo_bonus_dexterity

	# 6. 获得敏捷
	if card.gain_dexterity > 0:
		player.dexterity += card.gain_dexterity
		msg += "  敏捷+%d\n" % card.gain_dexterity

	# 7. 施加状态效果
	# 数据驱动：燃烧等于实际伤害（异火亘古尺）
	var burn_bonus = RelicManager.on_burn_applied(PlayerManager.relics)
	var burning_handled_by_equals = false
	if card.apply_burning_equals_damage and total_actual_damage > 0 and target and target.is_alive():
		target.apply_burn(total_actual_damage + burn_bonus)
		msg += "  %s 获得 燃烧 ×%d\n" % [target.char_name, total_actual_damage + burn_bonus]
		burning_handled_by_equals = true

	if target:
		if card.apply_burning > 0 and not burning_handled_by_equals:
			var total_burn = card.apply_burning + burn_bonus
			target.apply_burn(total_burn)
			msg += "  %s 获得 燃烧 ×%d\n" % [target.char_name, total_burn]
		if card.apply_venom > 0:
			msg += _apply_venom(target, card.apply_venom)
		# 美杜莎：venom_apply 字段（单体蛇毒）
		if card.venom_apply > 0:
			msg += _apply_venom(target, card.venom_apply)
		if card.apply_weak > 0:
			target.apply_weak(card.apply_weak)
			RelicManager.on_status_applied(PlayerManager.relics, "weak", target)
			msg += "  %s 获得 虚弱 %d 回合\n" % [target.char_name, card.apply_weak]
		if card.apply_vulnerable > 0:
			target.apply_vulnerable(card.apply_vulnerable)
			msg += "  %s 获得 易伤 %d 回合\n" % [target.char_name, card.apply_vulnerable]
		if card.apply_frail > 0:
			target.apply_frail(card.apply_frail)
			msg += "  %s 获得 脆弱 %d 回合\n" % [target.char_name, card.apply_frail]
		if card.apply_frozen > 0:
			target.apply_frozen(card.apply_frozen)
			msg += "  %s 获得 冰封 ×%d\n" % [target.char_name, card.apply_frozen]
		if card.apply_armor_break > 0:
			target.apply_armor_break(card.apply_armor_break)
			msg += "  %s 获得 破甲 ×%d\n" % [target.char_name, card.apply_armor_break]

	# AOE 状态效果（对所有敌人）
	if card.aoe:
		for enemy in enemies:
			if enemy.is_alive() and enemy != target:
				if card.apply_burning > 0:
					enemy.apply_burn(card.apply_burning + burn_bonus)
				if card.apply_venom > 0:
					msg += _apply_venom(enemy, card.apply_venom)
				# 美杜莎：venom_apply 字段(AOE蛇毒）
				if card.venom_apply > 0:
					msg += _apply_venom(enemy, card.venom_apply)
				if card.apply_weak > 0:
					enemy.apply_weak(card.apply_weak)
					RelicManager.on_status_applied(PlayerManager.relics, "weak", enemy)
				if card.apply_vulnerable > 0:
					enemy.apply_vulnerable(card.apply_vulnerable)
				if card.apply_frail > 0:
					enemy.apply_frail(card.apply_frail)
				if card.apply_frozen > 0:
					enemy.apply_frozen(card.apply_frozen)
				if card.apply_armor_break > 0:
					enemy.apply_armor_break(card.apply_armor_break)

	# === 萧薰儿：金印系统 ===
	# 遗物：古族金令 — 每场第一张攻击牌额外施加2层金印
	var gold_seal_bonus = 0
	if card.card_type == CardData.CardType.ATTACK:
		for relic in PlayerManager.relics:
			if relic.id == 2 and not player.first_turn_attack_bonus_used:
				gold_seal_bonus += 2
				player.first_turn_attack_bonus_used = true
				break

	# 古族血统：打出攻击牌时+N金印
	if card.card_type == CardData.CardType.ATTACK and player.ability_gold_seal_on_attack > 0:
		gold_seal_bonus += player.ability_gold_seal_on_attack

	# 古族血统（升级）:额外给随机敌人施加金印
	if card.card_type == CardData.CardType.ATTACK and player.ability_random_gold_seal_on_attack > 0:
		var alive_for_seal: Array[Enemy] = []
		for e in enemies:
			if e.is_alive() and e != target:
				alive_for_seal.append(e)
		if alive_for_seal.size() > 0:
			var rand_enemy = alive_for_seal[RNGManager.drop_rng.randi() % alive_for_seal.size()]
			var rand_seal = _apply_gold_seal_and_check(rand_enemy, player.ability_random_gold_seal_on_attack)
			if rand_seal.msg != "":
				msg += "  ★ 古族血统：" + rand_seal.msg

	# 施加金印（多段攻击已在伤害循环内逐段施加，此处仅处理加成部分）
	var card_seal_amount = card.apply_gold_seal if card.hit_count <= 1 else 0
	if card.aoe and (card_seal_amount + gold_seal_bonus) > 0:
		# AOE卡牌：金印施加给所有敌人
		for enemy in enemies:
			if enemy.is_alive():
				var seal_result = _apply_gold_seal_and_check(enemy, card_seal_amount + gold_seal_bonus)
				if seal_result.msg != "":
					msg += seal_result.msg
	elif (card_seal_amount + gold_seal_bonus) > 0 and target and target.is_alive():
		# 单体卡牌：金印施加给主目标
		var seal_result = _apply_gold_seal_and_check(target, card_seal_amount + gold_seal_bonus)
		msg += seal_result.msg
		# 帝印决：引爆时移回手牌（耗能 3)
		if seal_result.detonated and card.return_to_hand_on_detonate:
			var return_card = card.duplicate_card()
			return_card.cost = mini(return_card.cost + card.return_cost_increase, 3)
			player.hand.append(return_card)
			msg += "  ★ 帝印决：移回手牌（耗能 %d)\n" % return_card.cost
		# 千年一击：引爆时+1力量
		if seal_result.detonated and card.id == "thousand_year_strike":
			player.strength += 1
			msg += "  ★ 千年一击：力量 +1\n"
		# 金光破：引爆时抽1牌
		if seal_result.detonated and card.id == "golden_light_break":
			var drawn = player.draw_cards(1)
			if drawn.size() > 0:
				msg += "  ★ 金光破：抽 %s\n" % drawn[0].card_name

	# 连击触发时额外金印
	if card.combo_threshold > 0 and card.combo_bonus_gold_seal > 0:
		if cards_played_this_turn >= card.combo_threshold or player.ability_combo_no_condition:
			if target and target.is_alive():
				var combo_seal = _apply_gold_seal_and_check(target, card.combo_bonus_gold_seal)
				msg += combo_seal.msg

	# 连击触发时额外蛇毒（暗影突袭）
	if card.combo_threshold > 0 and card.combo_bonus_venom > 0:
		if cards_played_this_turn >= card.combo_threshold or player.ability_combo_no_condition:
			if target and target.is_alive():
				msg += _apply_venom(target, card.combo_bonus_venom)

	# 偏折光幕/金焰壁：设置金印荆棘
	if card.id in ["deflect_light_curtain", "golden_flame_wall"] and card.apply_gold_seal > 0:
		player.ability_gold_seal_thorns += card.apply_gold_seal
		msg += "  ★ 金印荆棘：被攻击时给攻击者施加 %d 层金印" % card.apply_gold_seal

	# 金印对所有敌人（光之审判、古族秘术等）
	if card.gold_seal_on_all_enemies > 0:
		for enemy in enemies:
			if enemy.is_alive():
				var seal_result = _apply_gold_seal_and_check(enemy, card.gold_seal_on_all_enemies)
				msg += seal_result.msg

	# 万印归宗：立刻引爆所有金印
	if card.gold_seal_detonate:
		for enemy in enemies:
			if enemy.is_alive() and enemy.gold_seal > 0:
				var stacks = enemy.gold_seal
				# 达到阈值的触发标准引爆
				var threshold = player.ability_detonation_threshold
				# 古族玉佩：金印引爆阈值减少
				for relic in PlayerManager.relics:
					if relic.effect_type == RelicData.EffectType.GOLD_MARK_THRESHOLD_REDUCE:
						threshold = max(1, threshold - relic.effect_value)
						break
				while enemy.gold_seal >= threshold and enemy.is_alive():
					enemy.gold_seal -= threshold
					player.detonation_count_this_turn += 1
					player.detonation_count_total += 1
					enemy.take_damage(10, true)
					player.gain_energy(1)
					msg += "  ★ 金印引爆!对 %s 造成 10 真伤 +1能量\n" % enemy.char_name
				# 剩余层数按每层X伤害处理
				if enemy.gold_seal > 0 and card.gold_seal_detonate_damage_per_stack > 0:
					var extra_dmg = enemy.gold_seal * card.gold_seal_detonate_damage_per_stack
					enemy.gold_seal = 0
					enemy.take_damage(extra_dmg, true)
					msg += "  残余金印：对 %s 造成 %d 真伤\n" % [enemy.char_name, extra_dmg]

	# 古族禁术·封印：石化
	if card.petrify and target and target.is_alive():
		target.apply_petrified(1)
		msg += "  ★ 石化!%s 眩晕1回合\n" % target.char_name

	# === 美杜莎：姿态系统 ===
	# 姿态切换
	if card.enter_stance != "":
		var target_stance = 0
		match card.enter_stance:
			"queen": target_stance = 1
			"python": target_stance = 2
		var stance_result = player.switch_stance(target_stance)
		if stance_result.changed:
			msg += stance_result.msg

	# 离开姿态
	if card.leave_stance:
		var leave_result = player.leave_stance()
		if leave_result.changed:
			msg += leave_result.msg

	# 蛇毒施加（所有敌人）
	if card.venom_apply_all > 0:
		for enemy in enemies:
			if enemy.is_alive():
				msg += _apply_venom(enemy, card.venom_apply_all)

	# 女王姿态：蛇鳞飞射每次额外给予蛇毒
	if card.queen_bonus_venom > 0 and player.current_stance == 1:
		if target and target.is_alive():
			for _i in range(card.hit_count if card.hit_count > 0 else 1):
				msg += _apply_venom(target, card.queen_bonus_venom)

	# 吞天蟒姿态：攻击附加目标蛇毒层数伤害
	if player.current_stance == 2 and card.card_type == CardData.CardType.ATTACK:
		if card.aoe:
			# AOE攻击：对所有敌人触发蛇毒侵蚀
			for enemy in enemies:
				if enemy.is_alive() and enemy.venom > 0:
					var venom_bonus_dmg = enemy.venom
					enemy.take_damage(venom_bonus_dmg)
					msg += "  ★ 蛇毒侵蚀：对 %s 额外 %d 伤害\n" % [enemy.char_name, venom_bonus_dmg]
		else:
			# 单体攻击：对目标触发蛇毒侵蚀
			if target and target.is_alive() and target.venom > 0:
				var venom_bonus_dmg = target.venom
				target.take_damage(venom_bonus_dmg)
				msg += "  ★ 蛇毒侵蚀：额外 %d 伤害\n" % venom_bonus_dmg

	# 暗影爪击：目标有蛇毒时+伤害
	if card.bonus_damage_if_venom > 0 and target and target.is_alive() and target.venom > 0:
		target.take_damage(card.bonus_damage_if_venom)
		msg += "  ★ 暗影爪击：额外 %d 伤害\n" % card.bonus_damage_if_venom

	# 古族剑诀：目标易伤时+伤害
	if card.bonus_damage_if_vulnerable > 0 and target and target.is_alive() and target.vulnerable > 0:
		target.take_damage(card.bonus_damage_if_vulnerable)
		msg += "  ★ 古族剑诀：目标易伤，额外 %d 伤害\n" % card.bonus_damage_if_vulnerable

	# 蟒蛇绞杀：目标蛇毒>=5时+伤害
	if card.bonus_damage_if_venom_5 > 0 and target and target.is_alive() and target.venom >= 5:
		target.take_damage(card.bonus_damage_if_venom_5)
		msg += "  ★ 蟒蛇绞杀：额外 %d 伤害\n" % card.bonus_damage_if_venom_5

	# 毒血爆发：每层蛇毒+伤害
	if card.bonus_damage_per_venom > 0 and target and target.is_alive():
		var bonus = min(target.venom * card.bonus_damage_per_venom, card.max_bonus_damage if card.max_bonus_damage > 0 else 999)
		if bonus > 0:
			target.take_damage(bonus)
			msg += "  ★ 毒血爆发：额外 %d 伤害\n" % bonus

	# 七彩吞天：蛇毒>=N时双倍伤害（使用已加成的 base_dmg)
	if card.venom_threshold_double > 0 and target and target.is_alive() and target.venom >= card.venom_threshold_double:
		var extra = target.take_damage(base_dmg)
		total_actual_damage += extra
		msg += "  ★ 七彩吞天：双倍伤害 %d\n" % extra

	# 暗影吞噬：回复目标蛇毒层数HP
	if card.heal_per_venom > 0 and target and target.is_alive():
		var heal_amount = target.venom * card.heal_per_venom
		if heal_amount > 0:
			player.heal(heal_amount)
			msg += "  ★ 暗影吞噬：回复 %d HP\n" % heal_amount

	# 毒素催化：蛇毒翻倍
	if card.double_venom and target and target.is_alive():
		target.venom = target.venom * 2
		msg += "  ★ 毒素催化：蛇毒翻倍至 %d\n" % target.venom

	# 蟒毒爆裂/蛇皇灭杀：消耗所有蛇毒造成伤害
	if card.consume_venom and target and target.is_alive():
		var consumed = target.venom
		if consumed > 0:
			target.venom = 0
			var extra_dmg = consumed * card.damage_per_consume_venom
			var actual = target.take_damage(extra_dmg)
			msg += "  ★ 消耗蛇毒：%d层 → %d伤害\n" % [consumed, actual]
			# 吞噬击杀增加最大HP
			if card.devour_max_hp_bonus > 0 and not target.is_alive():
				player.max_hp += card.devour_max_hp_bonus
				player.hp += card.devour_max_hp_bonus
				msg += "  ★ 吞噬击杀：最大生命值 +%d\n" % card.devour_max_hp_bonus

	# 蛇魂轮回：消耗所有敌人蛇毒
	if card.consume_all_venom_heal > 0:
		for enemy in enemies:
			if enemy.is_alive() and enemy.venom > 0:
				var consumed = enemy.venom
				enemy.venom = 0
				player.heal(consumed * card.consume_all_venom_heal)
				player.gain_block(consumed * card.consume_all_venom_block, 0, true)
				msg += "  ★ 蛇魂轮回：%s 蛇毒%d层 → HP+%d 护盾+%d\n" % [enemy.char_name, consumed, consumed * card.consume_all_venom_heal, consumed * card.consume_all_venom_block]

	# 美杜莎之凝望：全体虚弱+破甲+石化
	if card.apply_weak_all > 0:
		for enemy in enemies:
			if enemy.is_alive():
				enemy.apply_weak(card.apply_weak_all)
	if card.apply_armor_break_all > 0:
		for enemy in enemies:
			if enemy.is_alive():
				enemy.apply_armor_break(card.apply_armor_break_all)
	if card.queen_petrify and player.current_stance == 1:
		var alive_enemies: Array[Enemy] = []
		for enemy in enemies:
			if enemy.is_alive():
				alive_enemies.append(enemy)
		if alive_enemies.size() > 0:
			var petrify_target = alive_enemies[RNGManager.drop_rng.randi() % alive_enemies.size()]
			petrify_target.apply_petrified(1)
			msg += "  ★ 石化!%s 眩晕1回合\n" % petrify_target.char_name

	# 九彩庇护：下一次伤害归零
	if card.next_damage_zero:
		player.next_damage_zero = true
		msg += "  ★ 九彩庇护：下一次伤害归零\n"

	# 蜕皮/蛇蜕重生：移除负面状态（覆盖全部8种类型）
	if card.cleanse_count > 0:
		var debuff_types: Array[String] = []
		if player.burn > 0: debuff_types.append("burn")
		if player.venom > 0: debuff_types.append("venom")
		if player.weak > 0: debuff_types.append("weak")
		if player.vulnerable > 0: debuff_types.append("vulnerable")
		if player.frail > 0: debuff_types.append("frail")
		if player.frozen > 0: debuff_types.append("frozen")
		if player.armor_break > 0: debuff_types.append("armor_break")
		if player.petrified > 0: debuff_types.append("petrified")
		var to_remove = mini(card.cleanse_count, debuff_types.size())
		for i in range(to_remove):
			match debuff_types[i]:
				"burn": player.burn = 0
				"venom": player.venom = 0
				"weak": player.weak = 0
				"vulnerable": player.vulnerable = 0
				"frail": player.frail = 0
				"frozen": player.frozen = 0
				"armor_break": player.armor_break = 0
				"petrified": player.petrified = 0
		if to_remove > 0:
			msg += "  移除 %d 个负面状态\n" % to_remove

	# 8. 凝聚异火
	if card.channel_type != "":
		if not player.can_channel_next_turn:
			msg += "  [斗气化铠] 无法凝聚异火!\n"
		else:
			var fire_type = _parse_fire_type(card.channel_type)
			if fire_type >= 0:
				var result = player.channel_fire(fire_type)
				msg += "  凝聚 %s\n" % player._get_fire_name(fire_type)
				if result["ejected"] != null:
					var eject_name = player._get_fire_name(result["ejected"])
					var eject_log = _apply_fire_evoke(result["ejected"], 1)
					msg += "  ★ 槽位已满,%s 被激发!\n" % eject_name
					msg += eject_log
					# 药鼎守护：每次激发获得护盾
					if player.evoke_block_this_turn > 0:
						player.gain_block(player.evoke_block_this_turn, 0, true)
						msg += "    药鼎守护：+%d 护盾\n" % player.evoke_block_this_turn
					msg += _check_fire_slot_full_relic()

	# 9. 激发异火
	if card.evoke_all_fires:
		# 数据驱动：激发所有异火（焰分噬浪尺·烈/三色火莲）
		# 三色火莲升级后保留异火：通过 channel_type 兼空 + 不清除来实现
		msg += _evoke_all_fires(card.upgraded and card.id == "three_color_lotus")
	elif card.evoke:
		# 消耗1个异火，效果触发evoke_count次
		var result = player.evoke_front()
		if result["success"]:
			var evoke_log = _apply_fire_evoke(result["type"], card.evoke_count)
			msg += "  ★ 激发 %s(×%d)\n" % [player._get_fire_name(result["type"]), card.evoke_count]
			msg += evoke_log
			# 药鼎守护：每次激发获得护盾
			if player.evoke_block_this_turn > 0:
				player.gain_block(player.evoke_block_this_turn * card.evoke_count, 0, true)
				msg += "    药鼎守护：+%d 护盾\n" % (player.evoke_block_this_turn * card.evoke_count)

	# 9.4 选择消耗N张牌（药鼎淬炼：先选消耗，再获得能量+抽牌）
	if card.choose_exhaust and card.exhaust_count > 0:
		_pending_exhaust = true
		_pending_exhaust_msg = msg
		_pending_exhaust_card = card
		choose_exhaust_requested.emit(card.exhaust_count)
		return msg

	# 9.5 丢弃N张牌（在抽牌前执行，匹配"先丢后抽"描述）
	if card.choose_discard and card.discard_count > 0:
		# 灵魂感知：玩家选择弃置（异步，等待UI回调）
		_pending_discard = true
		_pending_discard_msg = msg
		_pending_discard_card = card
		choose_discard_requested.emit(card.discard_count)
		return msg
	elif card.discard_count > 0:
		var actual_discard = min(card.discard_count, player.hand.size())
		var discarded_names: Array[String] = []
		for _i in range(actual_discard):
			var rand_idx = RNGManager.event_rng.randi() % player.hand.size()
			var c = player.hand[rand_idx]
			player.discard_pile.append(c)
			player.hand.remove_at(rand_idx)
			discarded_names.append(c.card_name)
		if discarded_names.size() > 0:
			msg += "  丢弃 %d 张牌：%s\n" % [discarded_names.size(), ", ".join(discarded_names)]

	# 10. 抽牌(ABILITY牌跳过——draw_cards字段是被动参数）
	if card.draw_cards > 0 and not is_ability:
		var drawn = player.draw_cards(card.draw_cards)
		if drawn.size() > 0:
			var names = []
			for c in drawn:
				names.append(c.card_name)
			msg += "  抽取 %d 张牌： %s\n" % [drawn.size(), ", ".join(names)]
		if player.last_curse_log != "":
			msg += player.last_curse_log
	# 连击触发时额外抽牌
	if card.combo_threshold > 0 and card.combo_bonus_draw > 0:
		if cards_played_this_turn >= card.combo_threshold or player.ability_combo_no_condition:
			var combo_drawn = player.draw_cards(card.combo_bonus_draw)
			if combo_drawn.size() > 0:
				var names = []
				for c in combo_drawn:
					names.append(c.card_name)
				msg += "  连击：抽 %d 张牌 (%s)\n" % [combo_drawn.size(), ", ".join(names)]

	# 11. 数据驱动：清空异火槽（佛怒火莲）
	if card.clear_fire_slots_on_play:
		var cleared = player.clear_fire_slots()
		if cleared.size() > 0:
			msg += "  异火槽已清空!\n"

	# 12. 数据驱动：永久增加最大HP（炼制筑基丹）
	if card.permanent_max_hp_gain > 0:
		player.max_hp += card.permanent_max_hp_gain
		player.hp += card.permanent_max_hp_gain
		msg += "  永久 +%d 最大生命值!\n" % card.permanent_max_hp_gain

	# 13. 数据驱动：移除负面状态+获盾（净莲妖火·净化）
	if card.clear_debuffs_on_play:
		var debuff_count = _count_player_debuffs()
		player.clear_all_debuffs()
		var total_shield = debuff_count * card.shield_per_debuff_cleared
		if total_shield > 0:
			player.gain_block(total_shield)
		msg += "  移除 %d 个负面状态，获得 %d 点护盾\n" % [debuff_count, total_shield]

	# 14. 数据驱动：移除所有异火换取能量+抽牌（提炼本源）
	if card.energy_per_fire_removed > 0 or card.draw_per_fire_removed > 0:
		var fire_count = player.fire_slots.size()
		player.clear_fire_slots()
		var energy_gain = fire_count * card.energy_per_fire_removed
		var draw_count = fire_count * card.draw_per_fire_removed
		if energy_gain > 0:
			player.gain_energy(energy_gain)
		if draw_count > 0:
			player.draw_cards(draw_count)
		msg += "  移除 %d 朵异火，获得 %d 能量，抽 %d 张牌\n" % [fire_count, energy_gain, draw_count]
		if player.last_curse_log != "":
			msg += player.last_curse_log

	# 15. 下一张牌耗能减少（紫云翼）
	if card.next_card_cost_reduction > 0:
		player.next_card_cost_modifier = -card.next_card_cost_reduction
		msg += "  下一张牌耗能 -%d\n" % card.next_card_cost_reduction

	# 萧薰儿：千年传承 — 下一张/两张牌打出两次
	if card.next_card_double:
		player.next_card_double = true
		msg += "  下一张牌打出两次\n"
	if card.next_n_cards_double > 0:
		player.next_card_double_remaining += card.next_n_cards_double
		msg += "  下 %d 张牌打出两次\n" % card.next_n_cards_double

	# 16. 移除最右端异火（六合游身移至最左，异火置换移除+凝聚）
	if card.remove_front_fire and player.fire_slots.size() > 0:
		var last = player.fire_slots.size() - 1
		var oldest = player.fire_slots[last]
		if card.reroll_front_fire:
			# 六合游身：最右移至最左
			player.fire_slots.remove_at(last)
			player.fire_slots.insert(0, oldest)
			msg += "  异火重排：%s 移至最左\n" % player._get_fire_name(oldest)
		else:
			# 异火置换等：真正移除
			player.fire_slots.remove_at(last)
			msg += "  移除最右端异火：%s\n" % player._get_fire_name(oldest)
			# 异步选择：等待玩家选择异火类型
			if card.select_channel and player.can_channel_next_turn:
				_pending_fire_select = true
				_pending_fire_msg = msg
				_pending_fire_card = card
				fire_type_requested.emit()
				return msg
			# 数据驱动：移除后凝聚指定异火
			elif card.channel_type_on_fire_remove != "" and player.can_channel_next_turn:
				var fire_type = _parse_fire_type(card.channel_type_on_fire_remove)
				if fire_type >= 0:
					var result = player.channel_fire(fire_type)
					msg += "  凝聚 %s\n" % player._get_fire_name(fire_type)
					if result["ejected"] != null:
						var eject_log = _apply_fire_evoke(result["ejected"], 1)
						msg += "  ★ 槽位已满,%s 被激发!\n" % player._get_fire_name(result["ejected"])
						msg += eject_log
						msg += _check_fire_slot_full_relic()

	# 18. 药鼎守护：本回合每次激发获得护盾
	if card.trigger_block_on_evoke > 0:
		player.evoke_block_this_turn += card.trigger_block_on_evoke
		msg += "  本回合每次激发异火获得 %d 点护盾\n" % card.trigger_block_on_evoke

	# 19. 焰分噬浪尺·守：本回合受击时给予敌人燃烧（动态等于实际护盾值）
	if card.trigger_burn_on_hit > 0:
		var burn_amount = player.last_card_block if player.last_card_block > 0 else card.trigger_burn_on_hit
		player.on_hit_burn_this_turn += burn_amount
		msg += "  本回合受击时给予敌人 %d 层燃烧\n" % burn_amount

	# 美杜莎：蟒毒护甲 — 本回合受击时给予敌人蛇毒
	if card.venom_thorns > 0:
		player.venom_thorns_this_turn += card.venom_thorns
		msg += "  本回合受击时给予敌人 %d 层蛇毒\n" % card.venom_thorns
	# 美杜莎：美杜莎之盾 — 女王姿态受击时给予蛇毒
	if card.queen_venom_thorns > 0 and player.current_stance == 1:
		player.queen_venom_thorns_this_turn += card.queen_venom_thorns
		msg += "  女王姿态：受击时给予敌人 %d 层蛇毒\n" % card.queen_venom_thorns

	# 20. 斗气化铠：下回合无法凝聚
	if not card.can_channel_next_turn:
		player.can_channel_next_turn = false
		msg += "  下回合无法凝聚异火\n"

	# 21. 焚诀运转：丢弃没有异火/燃烧标签的牌
	if card.discard_non_fire:
		var discarded_names: Array[String] = []
		var to_remove: Array[int] = []
		for i in range(player.hand.size()):
			var c = player.hand[i]
			if not c.has_tag("异火") and not c.has_tag("燃烧"):
				to_remove.append(i)
		# 从后往前移除避免索引偏移
		to_remove.reverse()
		for idx in to_remove:
			var c = player.hand[idx]
			player.discard_pile.append(c)
			player.hand.remove_at(idx)
			discarded_names.append(c.card_name)
		if discarded_names.size() > 0:
			msg += "  丢弃：%s\n" % ", ".join(discarded_names)

	# 22. 灵魂感知：效果已整合到 discard_count + draw_cards（见 §9.5 和 §10)

	# 23. 凝火诀：下回合少抽牌
	if card.next_turn_draw_penalty > 0:
		player.next_turn_draw_penalty += card.next_turn_draw_penalty
		msg += "  下回合少抽 %d 张牌\n" % card.next_turn_draw_penalty

	# 检查敌人死亡（仅报告本次新击败的）
	for i in range(enemies.size()):
		if not enemies[i].is_alive() and i not in _defeated_enemies:
			msg += "\n  * %s 被击败!\n" % enemies[i].char_name
			_defeated_enemies.append(i)

	# 能力牌被动效果设置
	_setup_ability_passive(card)

	# 遗物： 出牌后效果
	RelicManager.on_card_played(player, card, PlayerManager.relics, cards_played_this_turn)

	return msg


## 激发所有异火（三色火莲、焰分噬浪尺·烈）
## keep_fires: 升级三色火莲激发后保留异火
func _evoke_all_fires(keep_fires: bool) -> String:
	var msg = ""
	var fires_to_evoke = player.fire_slots.duplicate()

	if not keep_fires:
		player.clear_fire_slots()
		# 遗物：陀舍古帝玉 — 清空异火槽时返还1能量
		for relic in PlayerManager.relics:
			if relic.effect_type == RelicData.EffectType.FIRE_CLEAR_RETURN_ENERGY:
				player.gain_energy(relic.effect_value)
				msg += "  ★ %s:返还 %d 能量\n" % [relic.relic_name, relic.effect_value]
				break

	for fire_type in fires_to_evoke:
		var evoke_log = _apply_fire_evoke(fire_type, 1)
		msg += "  ★ 激发 %s\n" % player._get_fire_name(fire_type)
		msg += evoke_log
		# 药鼎守护：每次激发获得护盾
		if player.evoke_block_this_turn > 0:
			player.gain_block(player.evoke_block_this_turn, 0, true)
			msg += "    药鼎守护：+%d 护盾\n" % player.evoke_block_this_turn

	if keep_fires:
		msg += "  （升级效果：异火保留不被清空）\n"

	return msg


## 异火槽满载时回复HP（紫晶源+紫晶翼狮王紫火）
func _check_fire_slot_full_relic() -> String:
	if player.fire_slots.size() >= player.max_fire_slots:
		for relic in PlayerManager.relics:
			if relic.effect_type == RelicData.EffectType.CHANNEL_FULL_HEAL:
				player.hp = min(player.max_hp, player.hp + relic.effect_value)
				return "  %s:回复 %d HP\n" % [relic.relic_name, relic.effect_value]
	return ""


## 应用异火激发效果
## 返回日志文本
func _apply_fire_evoke(fire_type: Player.FireType, times: int) -> String:
	var msg = ""
	# 炎帝之姿：激发效果触发N次（默认1,每张+1)
	var evoke_repeats = 1 + player.ability_evoke_count
	# 青莲地心火·本源：每张+4激发伤害
	var lotus_bonus = 4 * player.ability_lotus_count
	# 遗物：紫晶翼狮王紫火 — 激发伤害+3
	var fire_evoke_bonus = RelicManager.on_fire_evoke(PlayerManager.relics)
	for i in times:
		for _r in range(evoke_repeats):
			match fire_type:
				Player.FireType.GREEN:
					# 对随机敌人造成 8 点伤害 + 1 层易伤（青莲本源+4)
					var alive_enemies = _get_alive_enemies()
					if alive_enemies.size() > 0:
						var target = alive_enemies[RNGManager.monster_rng.randi() % alive_enemies.size()]
						var dmg = 8 + lotus_bonus + fire_evoke_bonus
						var actual = target.take_damage(dmg)
						target.apply_vulnerable(1)
						msg += "    青莲地心火：对 %s 造成 %d 伤害，施加易伤\n" % [target.char_name, actual]

				Player.FireType.WHITE:
					# 获得 1 点能量，抽 1 张牌
					player.gain_energy(1)
					var drawn = player.draw_cards(1)
					var draw_name = drawn[0].card_name if drawn.size() > 0 else "无"
					msg += "    陨落心炎：+1 能量，抽 %s\n" % draw_name
					if player.last_curse_log != "":
						msg += player.last_curse_log

				Player.FireType.BLUE:
					# 获得 8 点护盾，给予所有敌人 1 层虚弱
					player.gain_block(8, 0, true)
					for enemy in enemies:
						if enemy.is_alive():
							enemy.apply_weak(1)
							RelicManager.on_status_applied(PlayerManager.relics, "weak", enemy)
					msg += "    骨灵冷火：+8 护盾，所有敌人虚弱\n"

				Player.FireType.PURPLE:
					# 提升 2 点力量
					player.strength += 2
					msg += "    三千燎炎火：力量+2\n"
		# 天火三玄变：每次激发获得力量
		if player.ability_strength_on_evoke > 0:
			player.strength += player.ability_strength_on_evoke
			msg += "    天火三玄变：力量+%d\n" % player.ability_strength_on_evoke
	return msg


func _trigger_fire_passives() -> String:
	var msg = ""
	# 青莲地心火·本源：永久异火被动（不占槽，每张1朵，可叠加）
	var passive_repeats = 1 + player.ability_passive_count  # 异火共鸣倍率
	for _i in range(player.permanent_green_fire_count):
		for _r in range(passive_repeats):
			var alive_enemies = _get_alive_enemies()
			if alive_enemies.size() > 0:
				var target = alive_enemies[RNGManager.monster_rng.randi() % alive_enemies.size()]
				var actual = target.take_damage(3)
				msg += "  青莲地心火·本源 被动：对 %s 造成 %d 伤害\n" % [target.char_name, actual]
	# 异火共鸣：被动效果触发N次（默认1,每张+1)
	var slot_repeats = passive_repeats
	for _r in range(slot_repeats):
		for fire_type in player.fire_slots:
			match fire_type:
				Player.FireType.GREEN:
					var alive_enemies = _get_alive_enemies()
					if alive_enemies.size() > 0:
						var target = alive_enemies[RNGManager.monster_rng.randi() % alive_enemies.size()]
						var actual = target.take_damage(3)
						msg += "  %s 被动：对 %s 造成 %d 伤害" % [player._get_fire_name(fire_type), target.char_name, actual]
				Player.FireType.WHITE:
					player.gain_block(2, 0, true)
					msg += "  %s 被动：获得 2 护盾" % player._get_fire_name(fire_type)
				Player.FireType.BLUE:
					var alive_enemies = _get_alive_enemies()
					if alive_enemies.size() > 0:
						var target = alive_enemies[RNGManager.monster_rng.randi() % alive_enemies.size()]
						target.apply_weak(1)
						RelicManager.on_status_applied(PlayerManager.relics, "weak", target)
						msg += "  %s 被动：%s 获得虚弱" % [player._get_fire_name(fire_type), target.char_name]
				Player.FireType.PURPLE:
					player.hp = min(player.max_hp, player.hp + 1)
					msg += "  %s 被动：恢复 1 HP" % player._get_fire_name(fire_type)
	return msg
func _parse_fire_type(type_str: String) -> int:
	match type_str:
		"green": return Player.FireType.GREEN
		"white": return Player.FireType.WHITE
		"blue": return Player.FireType.BLUE
		"purple": return Player.FireType.PURPLE
	return -1


## 获取存活敌人列表
func _get_alive_enemies() -> Array[Enemy]:
	var alive: Array[Enemy] = []
	for enemy in enemies:
		if enemy.is_alive():
			alive.append(enemy)
	return alive


## 统计玩家负面状态数量
func _count_player_debuffs() -> int:
	var count = 0
	if player.burn > 0: count += 1
	if player.venom > 0: count += 1
	if player.weak > 0: count += 1
	if player.vulnerable > 0: count += 1
	if player.frail > 0: count += 1
	if player.frozen > 0: count += 1
	if player.armor_break > 0: count += 1
	return count


## 异火选择回调：完成异火置换的凝聚步骤
func resolve_fire_channel(fire_type: Player.FireType) -> String:
	if not _pending_fire_select:
		return ""
	_pending_fire_select = false
	var msg = _pending_fire_msg
	_pending_fire_msg = ""

	if player.can_channel_next_turn:
		var result = player.channel_fire(fire_type)
		msg += "  凝聚 %s\n" % player._get_fire_name(fire_type)
		if result["ejected"] != null:
			var eject_log = _apply_fire_evoke(result["ejected"], 1)
			msg += "  ★ 槽位已满,%s 被激发!\n" % player._get_fire_name(result["ejected"])
			msg += eject_log
			# 药鼎守护：每次激发获得护盾
			if player.evoke_block_this_turn > 0:
				player.gain_block(player.evoke_block_this_turn, 0, true)
				msg += "    药鼎守护：+%d 护盾\n" % player.evoke_block_this_turn
			msg += _check_fire_slot_full_relic()

	# 遗物： 出牌后效果（补发，因为之前提前return了）
	RelicManager.on_card_played(player, _pending_fire_card, PlayerManager.relics, cards_played_this_turn)
	_pending_fire_card = null

	# 检查战斗是否结束
	_check_battle_end()
	return msg


## 弃置选择回调：完成灵魂感知等卡牌的弃置+抽牌步骤
func resolve_choose_discard(selected_cards: Array) -> String:
	if not _pending_discard:
		return ""
	_pending_discard = false
	var msg = _pending_discard_msg
	_pending_discard_msg = ""
	var card = _pending_discard_card
	_pending_discard_card = null

	# 丢弃玩家选中的卡牌
	var discarded_names: Array[String] = []
	for selected in selected_cards:
		var idx = player.hand.find(selected)
		if idx >= 0:
			player.discard_pile.append(selected)
			player.hand.remove_at(idx)
			discarded_names.append(selected.card_name)
	if discarded_names.size() > 0:
		msg += "  选择丢弃 %d 张牌：%s\n" % [discarded_names.size(), ", ".join(discarded_names)]

	# 抽牌
	if card.draw_cards > 0:
		var drawn = player.draw_cards(card.draw_cards)
		if drawn.size() > 0:
			var names = []
			for c in drawn:
				names.append(c.card_name)
			msg += "  抽 %d 张牌：%s\n" % [drawn.size(), ", ".join(names)]
		if player.last_curse_log != "":
			msg += player.last_curse_log

	# 检查敌人死亡
	for i in range(enemies.size()):
		if not enemies[i].is_alive() and i not in _defeated_enemies:
			msg += "\n  * %s 被击败!\n" % enemies[i].char_name
			_defeated_enemies.append(i)

	# 能力牌被动效果设置
	_setup_ability_passive(card)

	# 遗物： 出牌后效果（补发，因为之前提前return了）
	RelicManager.on_card_played(player, card, PlayerManager.relics, cards_played_this_turn)

	# 检查战斗是否结束
	_check_battle_end()
	return msg


## 遗物选择回调：完成炎帝遗物等回合开始选择
func resolve_relic_choice(choice_index: int) -> String:
	if not _pending_relic_choice:
		return ""
	_pending_relic_choice = false
	var msg = _pending_relic_msg
	_pending_relic_msg = ""
	var relic = _pending_relic_choice_relic
	_pending_relic_choice_relic = null

	# 应用选择的效果（根据effect_type路由，不硬编码）
	var chosen_type = relic.effect_type if choice_index == 0 else relic.effect_type_2
	var chosen_value = relic.effect_value if choice_index == 0 else relic.effect_value_2
	match chosen_type:
		RelicData.EffectType.TURN_START_ENERGY:
			player.gain_energy(chosen_value)
			msg += "  %s:获得 %d 点能量\n" % [relic.relic_name, chosen_value]
		RelicData.EffectType.TURN_START_DRAW:
			var drawn = player.draw_cards(chosen_value)
			if drawn.size() > 0:
				var names: Array[String] = []
				for c in drawn:
					names.append(c.card_name)
				msg += "  %s:抽取 %d 张牌(%s)\n" % [relic.relic_name, drawn.size(), ", ".join(names)]
			else:
				msg += "  %s:抽取 %d 张牌\n" % [relic.relic_name, chosen_value]
			if player.last_curse_log != "":
				msg += player.last_curse_log
		RelicData.EffectType.TURN_START_HEAL:
			player.hp = min(player.max_hp, player.hp + chosen_value)
			msg += "  %s:恢复 %d HP\n" % [relic.relic_name, chosen_value]
		RelicData.EffectType.TURN_START_SHIELD:
			player.gain_block(chosen_value)
			msg += "  %s:获得 %d 护盾\n" % [relic.relic_name, chosen_value]
		RelicData.EffectType.TURN_START_STRENGTH:
			player.strength += chosen_value
			msg += "  %s:力量 +%d\n" % [relic.relic_name, chosen_value]
		_:
			player.gain_energy(chosen_value)
			msg += "  %s:获得 %d 点能量\n" % [relic.relic_name, chosen_value]

	# 继续 _start_player_turn 剩余逻辑
	if not player.is_alive():
		state = BattleState.DEFEAT
		msg += "\n你被击败了!\n"
		return msg

	msg += "\n敌人状态：\n"
	for enemy in enemies:
		if enemy.is_alive():
			msg += "  %s | %s\n" % [enemy.get_status_text(), enemy.get_intent_text()]

	msg += "\n你的手牌：\n"
	msg += player.get_hand_text()
	msg += "\n%s\n" % player.get_pile_text()
	_check_battle_end()

	# 检查是否有排队的遗物选择
	if not _pending_relic_queue.is_empty() and state == BattleState.PLAYER_TURN:
		var next = _pending_relic_queue.pop_front()
		_pending_relic_choice = true
		_pending_relic_msg = msg
		_pending_relic_choice_relic = next.relic
		relic_choice_requested.emit(next.option1, next.option2)
		return msg

	return msg


## 消耗选择回调：完成药鼎淬炼等卡牌的消耗+能量+抽牌步骤
func resolve_choose_exhaust(selected_cards: Array) -> String:
	if not _pending_exhaust:
		return ""
	_pending_exhaust = false
	var msg = _pending_exhaust_msg
	_pending_exhaust_msg = ""
	var card = _pending_exhaust_card
	_pending_exhaust_card = null

	# 消耗玩家选中的卡牌
	var exhausted_names: Array[String] = []
	for selected in selected_cards:
		var idx = player.hand.find(selected)
		if idx >= 0:
			player.exhaust_pile.append(selected)
			player.hand.remove_at(idx)
			exhausted_names.append(selected.card_name)
	if exhausted_names.size() > 0:
		msg += "  消耗 %d 张牌：%s\n" % [exhausted_names.size(), ", ".join(exhausted_names)]

	# 获得能量（必须成功消耗至少1张牌）
	if card.gain_energy > 0 and exhausted_names.size() > 0:
		player.gain_energy(card.gain_energy)
		msg += "  获得 %d 点能量\n" % card.gain_energy

	# 抽牌（必须成功消耗至少1张牌）
	if card.draw_cards > 0 and exhausted_names.size() > 0:
		var drawn = player.draw_cards(card.draw_cards)
		if drawn.size() > 0:
			var names = []
			for c in drawn:
				names.append(c.card_name)
			msg += "  抽 %d 张牌：%s\n" % [drawn.size(), ", ".join(names)]
		if player.last_curse_log != "":
			msg += player.last_curse_log

	# 检查敌人死亡
	for i in range(enemies.size()):
		if not enemies[i].is_alive() and i not in _defeated_enemies:
			msg += "\n  * %s 被击败!\n" % enemies[i].char_name
			_defeated_enemies.append(i)

	# 能力牌被动效果设置
	_setup_ability_passive(card)

	# 遗物： 出牌后效果（补发，因为之前提前return了）
	RelicManager.on_card_played(player, card, PlayerManager.relics, cards_played_this_turn)

	# 检查战斗是否结束
	_check_battle_end()
	return msg


## 触发诅咒牌被动效果
func _trigger_curse_passive(card: CardData) -> String:
	match card.id:
		"qi_seal":
			return "斗气封印：抽到时已触发，本回合下一张牌耗能 +1\n"
		"broken_engagement":
			return "退婚之辱：手牌中存在时，攻击牌伤害 -2\n"
		"inner_demon":
			return "心魔来袭：抽到时已触发，能量 -1\n"
		"beast_backlash":
			return "兽性反噬：抽到时触发，失去2HP并随机丢弃1张牌\n"
		"xiao_family_shame":
			return "萧家耻辱：手牌中存在时，护盾减半\n"
		_:
			return "诅咒牌无法使用!\n"


## 玩家结束回合

## 能力牌一次性效果（打出时触发一次，之后由 in_play 持续生效）
func _setup_ability_passive(card: CardData) -> void:
	match card.id:
		"fire_script":
			# 焚诀残卷：由 _recalculate_ability_effects 统一从 in_play 重算
			pass
		"green_lotus_origin":
			# 青莲地心火·本源：由 _recalculate_ability_effects 统一从 in_play 计数
			pass


## 能力牌on-play触发（焚诀运转等：打出带指定标签的牌时触发）
func _check_on_play_triggers(played_card: CardData) -> String:
	var msg = ""
	for ability in player.in_play:
		if ability == played_card or ability.on_play_tag.is_empty():
			continue
		var matched = false
		for tag in ability.on_play_tag:
			if tag in played_card.tags:
				matched = true
				break
		if matched:
			if ability.id == "cauldron_soul":
				# 药鼎之魂：随机炼制丹药
				var roll = RNGManager.event_rng.randi() % 3
				match roll:
					0: # 疗伤药
						var heal = 5 if not ability.upgraded else 8
						player.hp = min(player.max_hp, player.hp + heal)
						msg += "  ★ 药鼎之魂：炼制疗伤药，回复 %d HP\n" % heal
					1: # 回气丹
						var cost = 3
						var energy = 2 if not ability.upgraded else 3
						player.hp = max(1, player.hp - cost)
						player.gain_energy(energy)
						msg += "  ★ 药鼎之魂：炼制回气丹,-%dHP +%d能量\n" % [cost, energy]
					2: # 筑基丹
						var gain = 2 if not ability.upgraded else 3
						player.max_hp += gain
						player.hp += gain
						msg += "  ★ 药鼎之魂：炼制筑基丹，永久 +%d 最大HP\n" % gain
			else:
				if ability.on_play_draw > 0:
					player.draw_cards(ability.on_play_draw)
				var block = ability.on_play_block if not ability.upgraded or ability.upgraded_on_play_block < 0 else ability.upgraded_on_play_block
				if block > 0:
					player.gain_block(block)
				msg += "  ★ [%s] 触发：抽%d牌，获得%d护盾\n" % [ability.card_name, ability.on_play_draw, block]
	return msg


func player_end_turn() -> String:
	if state != BattleState.PLAYER_TURN:
		return "当前不是你的回合！"

	player.on_turn_end()
	# 美杜莎：女王姿态被动 — 回合结束获得等同于场上最高蛇毒层数的护盾
	if player.current_stance == 1:
		var max_venom = 0
		for enemy in enemies:
			if enemy.is_alive() and enemy.venom > max_venom:
				max_venom = enemy.venom
		if max_venom > 0:
			var shield_amount = int(max_venom * player.ability_queen_block_mult)
			player.gain_block(shield_amount)
	# 遗物：回合结束效果（蛇人族护符、守护者之证）
	RelicManager.on_turn_end(player, PlayerManager.relics, enemies)

	# 触发异火被动效果（在虚无牌消耗之后，确保异火被动计数正确）
	var fire_passive_log = _trigger_fire_passives()

	# 异火被动可能杀敌，提前检查胜利（死亡动画由combat_scene播放）
	if _check_battle_end():
		var msg = "\n=== 敌方回合 ===\n"
		if fire_passive_log != "":
			msg += "--- 异火被动 ---\n" + fire_passive_log
		return msg

	state = BattleState.ENEMY_TURN

	var msg = "\n=== 敌方回合 ===\n"
	if fire_passive_log != "":
		msg += "--- 异火被动 ---\n" + fire_passive_log

	# 敌人行动
	# 收集召唤请求，循环结束后统一处理
	var _pending_summons: Array[Dictionary] = []
	for enemy in enemies:
		if enemy.is_alive():
			# 玩家已死亡则中断敌人循环（对标STS2)
			if not player.is_alive():
				break
			# 敌人状态结算顺序：清盾→DoT→被动（如葛叶+4盾）→行动→状态递减
			var _saved_burn = enemy.burn
			var _saved_venom = enemy.venom
			var hp_before = enemy.hp
			enemy.on_turn_start()
			# 石化延迟意图：如果上回合被石化，这回合使用延迟的意图
			if enemy.delayed_intent != null:
				enemy.current_intent = enemy.delayed_intent
				enemy.delayed_intent = null
			# 显示DoT伤害日志
			if _saved_burn > 0 and enemy.is_alive():
				msg += "  %s 受到 %d 点燃烧伤害\n" % [enemy.char_name, _saved_burn]
			if _saved_venom > 0 and enemy.is_alive():
				msg += "  %s 受到 %d 点蛇毒伤害\n" % [enemy.char_name, _saved_venom]
			# 敌人回合开始：被动效果（如护盾，需在on_turn_start清block后）
			var passive_log = enemy.execute_passives("turn_start", player)
			if passive_log != "":
				msg += passive_log
			# 怒火中烧：燃烧不减少
			if player.ability_burn_no_decay:
				enemy.burn = _saved_burn
			# 怒火中烧：燃烧伤害倍率
			if player.ability_burn_damage_mult > 1.0 and _saved_burn > 0:
				var normal_dmg = _saved_burn
				var multiplied_dmg = roundi(_saved_burn * player.ability_burn_damage_mult)
				if multiplied_dmg > normal_dmg:
					var extra = multiplied_dmg - normal_dmg
					var actual = enemy.take_damage(extra, true)
					if actual > 0:
						msg += "  怒火中烧：额外 %d 燃烧伤害\n" % actual
			# 检查DoT致死
			var enemy_idx = enemies.find(enemy)
			if not enemy.is_alive() and enemy_idx not in _defeated_enemies:
				msg += "  ★ %s 被击败!\n" % enemy.char_name
				_defeated_enemies.append(enemy_idx)
			if enemy.is_alive():
				var phase_before = enemy.current_phase
				player.last_relic_log = ""
				msg += enemy.execute_intent(player) + "\n"
				# 收集召唤请求，循环结束后处理
				if enemy.pending_summons.size() > 0:
					for summon in enemy.pending_summons:
						_pending_summons.append({"id": summon["id"], "count": summon["count"], "summoner": enemy.char_name})
					enemy.pending_summons.clear()
				if player.last_relic_log != "":
					msg += player.last_relic_log
				# 检查玩家是否存活（敌人攻击可能击杀玩家）
				if not player.is_alive():
					break
				# on-hit burn
				if player.on_hit_burn_this_turn > 0:
					var is_attack_intent = enemy.current_intent.intent == Enemy.IntentType.ATTACK
					var is_special_attack = enemy.current_intent.intent == Enemy.IntentType.SPECIAL and enemy.current_intent.damage > 0
					if is_attack_intent or is_special_attack:
						enemy.apply_burn(player.on_hit_burn_this_turn)
						msg += "  ★ 焰分噬浪尺·守：%s 获得 %d 层燃烧" % [enemy.char_name, player.on_hit_burn_this_turn]

				# on-hit effects: independent of burn
				var _is_atk = enemy.current_intent.intent == Enemy.IntentType.ATTACK
				var _is_sp_atk = enemy.current_intent.intent == Enemy.IntentType.SPECIAL and enemy.current_intent.damage > 0
				if _is_atk or _is_sp_atk:
					# gold seal thorns
					if player.ability_gold_seal_thorns > 0:
						var thorns_seal = _apply_gold_seal_and_check(enemy, player.ability_gold_seal_thorns)
						if thorns_seal.msg != "":
							msg += "  ★ 金印荆棘：" + thorns_seal.msg
					# venom on hit
					if player.ability_venom_on_hit > 0:
						msg += _apply_venom(enemy, player.ability_venom_on_hit)
					# venom thorns
					if player.venom_thorns_this_turn > 0:
						msg += _apply_venom(enemy, player.venom_thorns_this_turn)
					# queen venom thorns
					if player.queen_venom_thorns_this_turn > 0 and player.current_stance == 1:
						msg += _apply_venom(enemy, player.queen_venom_thorns_this_turn)
				# phase check
				if enemy.current_phase != phase_before:
					msg += "  ★ %s 进入了第 %d 阶段!\n" % [enemy.char_name, enemy.current_phase + 1]
				enemy.decrement_statuses()

	# 处理召唤请求（循环结束后，最多2个召唤物）
	for summon in _pending_summons:
		var current_summons = 0
		for e in enemies:
			if e.is_summoned:
				current_summons += 1
		var to_summon = mini(summon["count"], 2 - current_summons)
		for _i in range(to_summon):
			var summoned = EnemyDatabase.get_enemy(summon["id"])
			if summoned:
				summoned.is_summoned = true
				enemies.append(summoned)
				msg += "  %s 召唤了 %s！\n" % [summon["summoner"], summoned.char_name]

	# 检查玩家是否存活
	if not player.is_alive():
		state = BattleState.DEFEAT
		msg += "\n你被击败了!\n"
		return msg

	# 检查是否胜利
	if _check_battle_end():
		return msg

	# 进入下一回合
	turn_count += 1
	state = BattleState.PLAYER_TURN
	msg += "\n" + _start_player_turn()
	return msg


## 检查战斗是否结束
func _check_battle_end() -> bool:
	var all_dead = true
	for enemy in enemies:
		if enemy.is_alive():
			all_dead = false
			break

	if all_dead:
		state = BattleState.VICTORY
		_sync_potions_to_manager()
		_sync_deck_to_manager()
		# 遗物： 胜利效果（传入预估奖励金币用于百分比加成）
		var est_reward_gold = RewardManager.generate_gold_reward(battle_type as RewardManager.BattleType)
		RelicManager.on_victory(player, PlayerManager.relics, battle_type, est_reward_gold)
		return true

	if not player.is_alive():
		state = BattleState.DEFEAT
		_sync_potions_to_manager()
		return true

	return false


## 将剩余药水写回PlayerManager（排除战斗中被消耗的丹药，如阴阳玄龙丹）
func _sync_potions_to_manager() -> void:
	PlayerManager.potions.clear()
	for p in potions:
		if p.id not in _consumed_potion_ids:
			PlayerManager.potions.append(p)


## 将所有卡牌区合并写回PlayerManager（保持获取顺序）
func _sync_deck_to_manager() -> void:
	# 收集战斗中所有卡牌（含消耗/在场）
	var all_cards: Array[CardData] = []
	all_cards.append_array(player.draw_pile)
	all_cards.append_array(player.hand)
	all_cards.append_array(player.discard_pile)
	all_cards.append_array(player.exhaust_pile)
	all_cards.append_array(player.in_play)
	# 按战斗前顺序重建，新增卡牌追加到末尾
	var old_order = PlayerManager.deck
	var new_deck: Array[CardData] = []
	var remaining = all_cards.duplicate()
	for old_card in old_order:
		for i in range(remaining.size()):
			if remaining[i] == old_card:
				new_deck.append(remaining[i])
				remaining.remove_at(i)
				break
	# 未匹配到的（升级后id变化等）按id回退匹配
	# 注意：同id卡牌（如两张撕咬）靠object identity在第一轮匹配，此轮仅处理升级等特殊情况
	for old_card in old_order:
		if old_card not in new_deck:
			for i in range(remaining.size()):
				if remaining[i].id == old_card.id and remaining[i].upgraded == old_card.upgraded:
					new_deck.append(remaining[i])
					remaining.remove_at(i)
					break
	# 战斗中获得的新卡（如消耗产生的token牌等）追加末尾
	for card in remaining:
		new_deck.append(card)
	PlayerManager.deck.clear()
	for card in new_deck:
		PlayerManager.deck.append(card)


## 使用药水
func use_potion(potion_index: int) -> String:
	if potion_index < 0 or potion_index >= potions.size():
		return ""
	if state != BattleState.PLAYER_TURN:
		return "当前无法使用药水!\n"

	var potion = potions[potion_index]
	# 被动丹药（阴阳玄龙丹）:不可手动使用
	if potion.effect_type == PotionData.EffectType.DEATH_PREVENT:
		return "[color=gray]此丹药为被动效果，受到致命伤害时自动触发[/color]\n"
	var msg = PotionManager.use_potion(potion, player, enemies)
	potions.remove_at(potion_index)

	# 遗物： 使用丹药后效果
	RelicManager.on_potion_used(player, PlayerManager.relics)

	_check_battle_end()
	return msg


## 丢弃药水
func discard_potion(potion_index: int) -> String:
	if potion_index < 0 or potion_index >= potions.size():
		return ""
	var potion = potions[potion_index]
	potions.remove_at(potion_index)
	return "丢弃了 [%s]\n" % potion.potion_name


## 获取战斗结果
func get_battle_result() -> String:
	if state == BattleState.VICTORY:
		return "=== 战斗胜利! ===\n恭喜你击败了所有敌人！"
	elif state == BattleState.DEFEAT:
		return "=== 战斗失败 ===\n你被击败了..."
	return ""


## 获取当前战斗状态显示
func get_battle_display() -> String:
	var text = ""

	# 敌人区域
	text += "===========================================\n"
	text += "  敌人区域\n"
	text += "===========================================\n"
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if enemy.is_alive():
			text += "  [%d] %s\n" % [i + 1, enemy.get_brief_status()]
			text += "      意图： %s\n" % enemy.get_intent_text()
		else:
			text += "  [%d] %s （已击败）\n" % [i + 1, enemy.char_name]

	# 玩家状态
	text += "\n===========================================\n"
	text += "  玩家状态\n"
	text += "===========================================\n"
	text += "  %s\n" % player.get_status_text()
	text += "  %s\n" % player.get_pile_text()

	# 手牌区域
	text += "\n===========================================\n"
	text += "  手牌 （输入编号出牌,0结束回合）\n"
	text += "===========================================\n"
	text += player.get_hand_text()

	return text
