## 遗物效果管理器
## 在战斗各阶段被BattleManager调用，执行遗物被动效果
class_name RelicManager


## 战斗开始时触发
static func on_battle_start(player: Player, relics: Array[RelicData], enemies: Array = []) -> void:
	# 被动标志类遗物（不消耗，战斗全程生效）
	player.shield_never_decay = false
	player.single_damage_cap = 0
	player.has_first_hp_block = false
	player.first_hp_damage_blocked = false
	player.first_hp_lost_triggered = false
	player.first_attack_double_available = false
	player.total_attacks_this_battle = 0
	for relic in relics:
		if relic.effect_type == RelicData.EffectType.SHIELD_NEVER_DECAY:
			player.shield_never_decay = true
		elif relic.effect_type == RelicData.EffectType.SINGLE_DAMAGE_CAP:
			player.single_damage_cap = relic.effect_value
		elif relic.effect_type == RelicData.EffectType.FIRST_HP_DAMAGE_BLOCK:
			player.has_first_hp_block = true
		elif relic.effect_type == RelicData.EffectType.FIRST_ATTACK_DOUBLE:
			player.first_attack_double_available = true
	for relic in relics:
		match relic.effect_type:
			RelicData.EffectType.BATTLE_START_SHIELD:
				if relic.effect_value > 0:
					player.gain_block(relic.effect_value)
			RelicData.EffectType.BATTLE_START_DRAW:
				if relic.effect_value > 0:
					player.draw_cards(relic.effect_value)
			RelicData.EffectType.BATTLE_START_BURN_ALL:
				for enemy in enemies:
					enemy.apply_burn(relic.effect_value)
			RelicData.EffectType.BATTLE_START_VENOM_ALL:
				for enemy in enemies:
					enemy.apply_venom(relic.effect_value)
			RelicData.EffectType.BATTLE_START_VULNERABLE_ALL:
				for enemy in enemies:
					enemy.apply_vulnerable(relic.effect_value)
			RelicData.EffectType.BATTLE_START_WEAK_ALL:
				for enemy in enemies:
					enemy.apply_weak(relic.effect_value)
			RelicData.EffectType.BATTLE_START_REMOVE_CURSE:
				_remove_curse_from_hand(player, relic.effect_value)
			RelicData.EffectType.FIRE_SLOT_CAPACITY_BONUS:
				player.max_fire_slots += relic.effect_value
			RelicData.EffectType.BATTLE_START_CHANNEL_BLUE:
				player.channel_fire(Player.FireType.BLUE)
			RelicData.EffectType.BATTLE_START_POTION:
				if PlayerManager.potions.size() < PlayerManager.max_potion_slots:
					var potion = PotionManager.get_random_potion()
					if potion != null:
						PlayerManager.add_potion(potion)
		# 检查第二效果
		if relic.effect_value_2 > 0:
			match relic.effect_type_2:
				RelicData.EffectType.BATTLE_START_SHIELD:
					player.gain_block(relic.effect_value_2)
				RelicData.EffectType.BATTLE_START_DRAW:
					player.draw_cards(relic.effect_value_2)
				RelicData.EffectType.BATTLE_START_BURN_ALL:
					for enemy in enemies:
						enemy.apply_burn(relic.effect_value_2)
				RelicData.EffectType.BATTLE_START_VENOM_ALL:
					for enemy in enemies:
						enemy.apply_venom(relic.effect_value_2)
				RelicData.EffectType.BATTLE_START_VULNERABLE_ALL:
					for enemy in enemies:
						enemy.apply_vulnerable(relic.effect_value_2)
				RelicData.EffectType.BATTLE_START_WEAK_ALL:
					for enemy in enemies:
						enemy.apply_weak(relic.effect_value_2)
				RelicData.EffectType.BATTLE_START_REMOVE_CURSE:
					_remove_curse_from_hand(player, relic.effect_value_2)
				RelicData.EffectType.FIRE_SLOT_CAPACITY_BONUS:
					player.max_fire_slots += relic.effect_value_2
				RelicData.EffectType.BATTLE_START_CHANNEL_BLUE:
					player.channel_fire(Player.FireType.BLUE)
				RelicData.EffectType.BATTLE_START_POTION:
					if PlayerManager.potions.size() < PlayerManager.max_potion_slots:
						var potion = PotionManager.get_random_potion()
						if potion != null:
							PlayerManager.add_potion(potion)
		# 检查第三效果
		if relic.effect_value_3 > 0:
			match relic.effect_type_3:
				RelicData.EffectType.BATTLE_START_SHIELD:
					player.gain_block(relic.effect_value_3)
				RelicData.EffectType.BATTLE_START_DRAW:
					player.draw_cards(relic.effect_value_3)
				RelicData.EffectType.BATTLE_START_BURN_ALL:
					for enemy in enemies:
						enemy.apply_burn(relic.effect_value_3)
				RelicData.EffectType.BATTLE_START_VENOM_ALL:
					for enemy in enemies:
						enemy.apply_venom(relic.effect_value_3)
				RelicData.EffectType.BATTLE_START_VULNERABLE_ALL:
					for enemy in enemies:
						enemy.apply_vulnerable(relic.effect_value_3)
				RelicData.EffectType.BATTLE_START_WEAK_ALL:
					for enemy in enemies:
						enemy.apply_weak(relic.effect_value_3)
				RelicData.EffectType.BATTLE_START_REMOVE_CURSE:
					_remove_curse_from_hand(player, relic.effect_value_3)
				RelicData.EffectType.FIRE_SLOT_CAPACITY_BONUS:
					player.max_fire_slots += relic.effect_value_3
				RelicData.EffectType.BATTLE_START_CHANNEL_BLUE:
					player.channel_fire(Player.FireType.BLUE)


## 辅助：从手牌中移除诅咒牌
static func _remove_curse_from_hand(player: Player, count: int) -> void:
	var removed = 0
	var i = player.hand.size() - 1
	while i >= 0 and removed < count:
		if player.hand[i].card_type == CardData.CardType.CURSE:
			player.hand.remove_at(i)
			removed += 1
		i -= 1


## 回合开始时触发(必须在player.on_turn_start()之后调用)
## 返回需要玩家选择的遗物列表 Array[Dictionary]（空=无选择）
static func on_turn_start(player: Player, relics: Array[RelicData], turn_count: int = 1, enemies: Array = []) -> Array:
	# 山岳之心：检查HP是否首次降至50%以下
	for relic in relics:
		if relic.effect_type == RelicData.EffectType.LOW_HP_SHIELD_ONCE and not player.mountain_heart_triggered:
			if player.hp < player.max_hp * 0.5:
				player.mountain_heart_triggered = true
				player.next_damage_zero = true

	var choice_requests: Array = []
	for relic in relics:
		# 选择型遗物：收集信息，不自动生效
		if relic.is_turn_start_choice:
			var opt1 = _get_effect_desc(relic.effect_type, relic.effect_value)
			var opt2 = _get_effect_desc(relic.effect_type_2, relic.effect_value_2)
			choice_requests.append({"relic": relic, "option1": opt1, "option2": opt2})
			continue
		match relic.effect_type:
			RelicData.EffectType.TURN_START_STRENGTH:
				# 佣兵徽章：仅首回合获得力量
				if turn_count == 1:
					player.strength += relic.effect_value
			RelicData.EffectType.TURN_START_DRAW:
				player.draw_cards(relic.effect_value)
			RelicData.EffectType.TURN_START_ENERGY:
				player.gain_energy(relic.effect_value)
			RelicData.EffectType.TURN_START_HEAL:
				player.hp = min(player.max_hp, player.hp + relic.effect_value)
			RelicData.EffectType.TURN_START_BLOCK_PERCENT:
				var missing_hp = player.max_hp - player.hp
				if missing_hp > 0:
					var block_amount = int(missing_hp * relic.effect_value / 100.0)
					if block_amount > 0:
						player.gain_block(block_amount)
			RelicData.EffectType.TURN_START_SHIELD:
				player.gain_block(relic.effect_value)
			RelicData.EffectType.FIRST_TURN_ENERGY:
				if turn_count == 1:
					player.gain_energy(relic.effect_value)
			RelicData.EffectType.TURN_START_CLEANSE_AOE:
				# 清除所有负面状态
				player.clear_all_debuffs()
				# 对全体敌人造成伤害
				for enemy in enemies:
					if enemy.is_alive():
						enemy.take_damage(relic.effect_value)
			RelicData.EffectType.TURN_START_HAND_COST_REDUCE:
				# 天雁九行翼：回合开始手牌费用-N
				player.hand_cost_reduction = max(player.hand_cost_reduction, relic.effect_value)
			RelicData.EffectType.FIRST_CARD_DOUBLE_PER_TURN:
				# 菩提古树之心：每回合第一张牌打出两次+免费
				player.next_card_double = true
				player.first_card_free_this_turn = true
		# 检查第二效果（与主效果共享第一回合限制）
		if relic.effect_value_2 > 0:
			var skip_secondary = (relic.effect_type == RelicData.EffectType.FIRST_TURN_ENERGY and turn_count != 1)
			if not skip_secondary:
				match relic.effect_type_2:
					RelicData.EffectType.TURN_START_STRENGTH:
						player.strength += relic.effect_value_2
					RelicData.EffectType.TURN_START_DRAW:
						player.draw_cards(relic.effect_value_2)
					RelicData.EffectType.TURN_START_ENERGY:
						player.gain_energy(relic.effect_value_2)
					RelicData.EffectType.TURN_START_HEAL:
						player.hp = min(player.max_hp, player.hp + relic.effect_value_2)
					RelicData.EffectType.TURN_START_SHIELD:
						player.gain_block(relic.effect_value_2)
					RelicData.EffectType.FIRST_TURN_ENERGY:
						if turn_count == 1:
							player.gain_energy(relic.effect_value_2)
					RelicData.EffectType.TURN_START_HAND_COST_REDUCE:
						player.hand_cost_reduction = max(player.hand_cost_reduction, relic.effect_value_2)
					RelicData.EffectType.FIRST_CARD_DOUBLE_PER_TURN:
						player.next_card_double = true
						player.first_card_free_this_turn = true
					RelicData.EffectType.FIRST_TURN_DRAW:
						# 三年之约：仅首回合抽牌
						if turn_count == 1:
							player.draw_cards(relic.effect_value_2)
					RelicData.EffectType.TURN_START_BLOCK_PERCENT:
						var missing_hp_2 = player.max_hp - player.hp
						if missing_hp_2 > 0:
							var block_amount_2 = int(missing_hp_2 * relic.effect_value_2 / 100.0)
							if block_amount_2 > 0:
								player.gain_block(block_amount_2)
					RelicData.EffectType.TURN_START_CLEANSE_AOE:
						player.clear_all_debuffs()
						for enemy in enemies:
							if enemy.is_alive():
								enemy.take_damage(relic.effect_value_2)
		# 检查第三效果
		if relic.effect_value_3 > 0:
			var skip_tertiary = (relic.effect_type == RelicData.EffectType.FIRST_TURN_ENERGY and turn_count != 1)
			if not skip_tertiary:
				match relic.effect_type_3:
					RelicData.EffectType.TURN_START_STRENGTH:
						player.strength += relic.effect_value_3
					RelicData.EffectType.TURN_START_DRAW:
						player.draw_cards(relic.effect_value_3)
					RelicData.EffectType.TURN_START_ENERGY:
						player.gain_energy(relic.effect_value_3)
					RelicData.EffectType.TURN_START_HEAL:
						player.hp = min(player.max_hp, player.hp + relic.effect_value_3)
					RelicData.EffectType.TURN_START_SHIELD:
						player.gain_block(relic.effect_value_3)
					RelicData.EffectType.FIRST_TURN_ENERGY:
						if turn_count == 1:
							player.gain_energy(relic.effect_value_3)
					RelicData.EffectType.TURN_START_HAND_COST_REDUCE:
						player.hand_cost_reduction = max(player.hand_cost_reduction, relic.effect_value_3)
					RelicData.EffectType.FIRST_CARD_DOUBLE_PER_TURN:
						player.next_card_double = true
						player.first_card_free_this_turn = true
					RelicData.EffectType.FIRST_TURN_DRAW:
						if turn_count == 1:
							player.draw_cards(relic.effect_value_3)
					RelicData.EffectType.TURN_START_BLOCK_PERCENT:
						var missing_hp_3 = player.max_hp - player.hp
						if missing_hp_3 > 0:
							var block_amount_3 = int(missing_hp_3 * relic.effect_value_3 / 100.0)
							if block_amount_3 > 0:
								player.gain_block(block_amount_3)
					RelicData.EffectType.TURN_START_CLEANSE_AOE:
						player.clear_all_debuffs()
						for enemy in enemies:
							if enemy.is_alive():
								enemy.take_damage(relic.effect_value_3)

	return choice_requests


## 获取效果描述文本（用于选择型遗物的选项显示）
static func _get_effect_desc(effect_type: RelicData.EffectType, value: int) -> String:
	match effect_type:
		RelicData.EffectType.TURN_START_ENERGY:
			return "能量+%d" % value
		RelicData.EffectType.TURN_START_DRAW:
			return "抽牌+%d" % value
		RelicData.EffectType.TURN_START_HEAL:
			return "恢复%dHP" % value
		RelicData.EffectType.TURN_START_SHIELD:
			return "护盾+%d" % value
		RelicData.EffectType.TURN_START_STRENGTH:
			return "力量+%d" % value
		_:
			return "效果+%d" % value


## 回合结束时触发
static func on_turn_end(player: Player, relics: Array[RelicData], enemies: Array = []) -> void:
	for relic in relics:
		match relic.effect_type:
			RelicData.EffectType.NO_VENOM_ENEMY_SHIELD:
				# 蛇人族护符：场上无敌人有蛇毒时获得护盾
				var any_venom = false
				for enemy in enemies:
					if enemy.is_alive() and enemy.venom > 0:
						any_venom = true
						break
				if not any_venom:
					player.gain_block(relic.effect_value)
			RelicData.EffectType.HAND_RETAIN_BLOCK:
				# 守护者之证：获得已损HP×N%的护盾
				var missing_hp = player.max_hp - player.hp
				if missing_hp > 0 and relic.effect_value > 0:
					player.gain_block(int(missing_hp * relic.effect_value / 100.0))
			RelicData.EffectType.TURN_END_BURN_ALL:
				# 净莲妖火残焰：回合结束给予所有敌人燃烧
				for enemy in enemies:
					if enemy.is_alive():
						enemy.apply_burn(relic.effect_value)
			RelicData.EffectType.SHIELD_ZERO_BONUS:
				# 血莲丹：回合结束护盾为0时获得护盾
				if player.block <= 0:
					player.gain_block(relic.effect_value)
			RelicData.EffectType.ENERGY_ZERO_EXTRA_DRAW:
				# 守护者之证：回合结束能量为0时，标记下回合多抽
				if player.energy <= 0:
					player.bonus_draw_next_turn += relic.effect_value
			RelicData.EffectType.TURN_END_LOST_HP_AOE:
				# 厄难毒体原液：回合结束对全体造成已损失HP真伤
				var lost_hp = player.max_hp - player.hp
				if lost_hp > 0:
					for enemy in enemies:
						if enemy.is_alive():
							enemy.take_damage(lost_hp, true)
		# 检查第二效果
		if relic.effect_value_2 > 0 or relic.effect_type_2 == RelicData.EffectType.TURN_END_LOST_HP_AOE:
			match relic.effect_type_2:
				RelicData.EffectType.ENERGY_ZERO_EXTRA_DRAW:
					if player.energy <= 0:
						player.bonus_draw_next_turn += relic.effect_value_2
				RelicData.EffectType.TURN_END_LOST_HP_AOE:
					var lost_hp_2 = player.max_hp - player.hp
					if lost_hp_2 > 0:
						for enemy in enemies:
							if enemy.is_alive():
								enemy.take_damage(lost_hp_2, true)
		# 检查第三效果
		if relic.effect_value_3 > 0 or relic.effect_type_3 == RelicData.EffectType.TURN_END_LOST_HP_AOE:
			match relic.effect_type_3:
				RelicData.EffectType.ENERGY_ZERO_EXTRA_DRAW:
					if player.energy <= 0:
						player.bonus_draw_next_turn += relic.effect_value_3
				RelicData.EffectType.TURN_END_LOST_HP_AOE:
					var lost_hp_3 = player.max_hp - player.hp
					if lost_hp_3 > 0:
						for enemy in enemies:
							if enemy.is_alive():
								enemy.take_damage(lost_hp_3, true)


## 异火激发时触发，返回额外伤害
static func on_fire_evoke(relics: Array[RelicData]) -> int:
	var bonus = 0
	for relic in relics:
		match relic.effect_type:
			RelicData.EffectType.FIRE_EVOKE_BONUS_DAMAGE:
				bonus += relic.effect_value
	return bonus


## 获取第一回合前N张牌费用为0的数量
static func get_first_turn_free_cards(relics: Array[RelicData]) -> int:
	for relic in relics:
		if relic.effect_type == RelicData.EffectType.FIRST_TURN_CARDS_COST_ZERO:
			return relic.effect_value
	return 0


## 休息时触发
static func on_rest(player: Player, relics: Array[RelicData]) -> void:
	for relic in relics:
		match relic.effect_type:
			RelicData.EffectType.REST_EXTRA_HEAL_FLAT:
				if relic.effect_value > 0:
					player.hp = min(player.max_hp, player.hp + relic.effect_value)


## 计算休息回复量（含遗物加成），供 rest_scene 使用
static func calculate_rest_heal(base_amount: int, current_hp: int, max_hp_val: int, relics: Array[RelicData]) -> int:
	var amount = base_amount
	for relic in relics:
		match relic.effect_type:
			RelicData.EffectType.REST_HEAL_BONUS_PERCENT:
				if current_hp < max_hp_val * 0.5:
					amount = int(amount * (100 + relic.effect_value) / 100.0)
			RelicData.EffectType.REST_EXTRA_HEAL_FLAT:
				amount += relic.effect_value
	return amount


## 检查致死伤害防止（天妖凰精血），返回是否阻止了死亡
static func check_death_prevent(player: Player, relics: Array[RelicData]) -> bool:
	# 先找到要移除的遗物，循环结束后再移除（避免迭代中修改数组）
	var idx_to_remove: int = -1
	for i in range(relics.size() - 1, -1, -1):
		var relic = relics[i]
		if relic.effect_type == RelicData.EffectType.DEATH_PREVENT_HEAL:
			if player.hp <= 0:
				player.hp = relic.effect_value
				idx_to_remove = i
				break
	if idx_to_remove >= 0:
		relics.remove_at(idx_to_remove)
		return true
	return false


## 骨炎戒：药老附体（HP<50%时触发，每场限1次）
## effect_value_2 编码：能量*100+抽牌数（如203=2能量+3抽牌）
static func check_low_hp_trigger(player: Player, relics: Array[RelicData]) -> String:
	for relic in relics:
		var is_low_hp_effect = relic.effect_type == RelicData.EffectType.LOW_HP_ENERGY_DRAW_CLEANSE or relic.effect_type_2 == RelicData.EffectType.LOW_HP_ENERGY_DRAW_CLEANSE
		if is_low_hp_effect and not player.guyan_triggered:
			player.guyan_triggered = true
			var val = relic.effect_value_2 if relic.effect_type_2 == RelicData.EffectType.LOW_HP_ENERGY_DRAW_CLEANSE else relic.effect_value
			var energy_gain = int(val / 100.0) if val >= 100 else 2
			var draw_count = val % 100 if val >= 100 else 3
			# 立即获得能量（存入bonus_energy，回合开始时保留）
			player.bonus_energy += energy_gain
			var drawn = player.draw_cards(draw_count)
			player.clear_all_debuffs()
			var draw_names = []
			for c in drawn:
				draw_names.append(c.card_name)
			var log_msg = "  ★ 药老附体！获得 %d 点能量，抽 %d 张牌" % [energy_gain, draw_count]
			if draw_names.size() > 0:
				log_msg += "（%s）" % ", ".join(draw_names)
			log_msg += "，清除所有负面状态\n"
			return log_msg
	return ""


static func on_card_played(player: Player, card: CardData, relics: Array[RelicData], _cards_played_this_turn: int = 1) -> void:
	# 更新回气散配方计数
	player.cards_played_for_relic_count += 1
	# 更新焱之拳套连续攻击计数
	if card.card_type == CardData.CardType.ATTACK:
		player.consecutive_attacks_this_turn += 1
		player.total_attacks_this_battle += 1
	elif card.card_type == CardData.CardType.SKILL:
		player.consecutive_attacks_this_turn = 0
		player.skill_cards_this_turn += 1
	else:
		player.consecutive_attacks_this_turn = 0

	# 七彩反噬：本回合遗物效果失效
	if player.relics_disabled_this_turn:
		return

	for relic in relics:
		match relic.effect_type:
			RelicData.EffectType.CARD_PLAY_HEAL:
				if relic.effect_value > 0 and card.card_type == CardData.CardType.ABILITY:
					player.hp = min(player.max_hp, player.hp + relic.effect_value)
			RelicData.EffectType.TURN_3_CARDS_PLAYED_SHIELD:
				# 回气散配方：每回合第3张牌打出时获护盾
				if player.cards_played_for_relic_count == 3:
					player.gain_block(relic.effect_value)
			RelicData.EffectType.NTH_CARD_SHIELD_PER_TURN:
				# 回气散配方：每回合第N张牌打出时获护盾
				if player.cards_played_for_relic_count == 3:
					player.gain_block(relic.effect_value)
			RelicData.EffectType.CONSECUTIVE_ATTACK_STRENGTH:
				# 凌影的暗镖：同回合连续打出3张攻击牌获得力量
				if player.consecutive_attacks_this_turn >= 3 and player.consecutive_attacks_this_turn % 3 == 0:
					player.temp_strength += relic.effect_value
			RelicData.EffectType.UNUPGRADED_AUTO_UPGRADE:
				# 魂殿拘灵锁：打出未升级卡牌时自动升级
				if not card.upgraded:
					card.apply_upgrade()
			RelicData.EffectType.NTH_CARD_ENERGY_AND_DRAW:
				# 九彩原石：每打出N张牌获能量+抽牌
				if relic.effect_value > 0 and player.cards_played_for_relic_count % relic.effect_value == 0:
					player.gain_energy(1)
					player.draw_cards(1)
			RelicData.EffectType.NTH_CARD_ENERGY:
				# 远古魔核（重设计）：每打出N张牌获1能量
				if relic.effect_value > 0 and player.cards_played_for_relic_count % relic.effect_value == 0:
					player.gain_energy(1)
			RelicData.EffectType.SKILL_3_PLAYED_DEXTERITY:
				# 紫晶翼：同回合打出3张技能牌时+1敏捷
				if card.card_type == CardData.CardType.SKILL:
					if player.skill_cards_this_turn % 3 == 0:
						player.temp_dexterity += relic.effect_value
		# 检查第二效果
		if relic.effect_value_2 > 0:
			match relic.effect_type_2:
				RelicData.EffectType.CARD_PLAY_HEAL:
					if card.card_type == CardData.CardType.ABILITY:
						player.hp = min(player.max_hp, player.hp + relic.effect_value_2)
				RelicData.EffectType.NTH_CARD_ENERGY_AND_DRAW:
					if relic.effect_value_2 > 0 and player.cards_played_for_relic_count % relic.effect_value_2 == 0:
						player.gain_energy(1)
						player.draw_cards(1)
				RelicData.EffectType.NTH_CARD_ENERGY:
					if player.cards_played_for_relic_count % relic.effect_value_2 == 0:
						player.gain_energy(1)
				RelicData.EffectType.UNUPGRADED_AUTO_UPGRADE:
					if not card.upgraded:
						card.apply_upgrade()
				RelicData.EffectType.SKILL_3_PLAYED_DEXTERITY:
					if card.card_type == CardData.CardType.SKILL:
						if player.skill_cards_this_turn % 3 == 0:
							player.temp_dexterity += relic.effect_value_2
				RelicData.EffectType.CONSECUTIVE_ATTACK_STRENGTH:
					if player.consecutive_attacks_this_turn >= 3 and player.consecutive_attacks_this_turn % 3 == 0:
						player.temp_strength += relic.effect_value_2
		# 检查第三效果
		if relic.effect_value_3 > 0:
			match relic.effect_type_3:
				RelicData.EffectType.CARD_PLAY_HEAL:
					if card.card_type == CardData.CardType.ABILITY:
						player.hp = min(player.max_hp, player.hp + relic.effect_value_3)
				RelicData.EffectType.NTH_CARD_ENERGY_AND_DRAW:
					if player.cards_played_for_relic_count % relic.effect_value_3 == 0:
						player.gain_energy(1)
						player.draw_cards(1)
				RelicData.EffectType.NTH_CARD_ENERGY:
					if player.cards_played_for_relic_count % relic.effect_value_3 == 0:
						player.gain_energy(1)
				RelicData.EffectType.UNUPGRADED_AUTO_UPGRADE:
					if not card.upgraded:
						card.apply_upgrade()
				RelicData.EffectType.SKILL_3_PLAYED_DEXTERITY:
					if card.card_type == CardData.CardType.SKILL:
						if player.skill_cards_this_turn % 3 == 0:
							player.temp_dexterity += relic.effect_value_3


## 修改伤害值
static func on_damage_dealt(base_damage: int, relics: Array[RelicData], player: Player = null) -> int:
	var result = base_damage
	for relic in relics:
		match relic.effect_type:
			RelicData.EffectType.DAMAGE_BONUS_FLAT:
				result += relic.effect_value
			RelicData.EffectType.DAMAGE_BONUS_PERCENT:
				result = int(result * (100 + relic.effect_value) / 100.0)
			RelicData.EffectType.EVERY_NTH_ATTACK_BONUS:
				# 黑铁长枪：每第N次攻击伤害翻倍
				if player != null and relic.effect_value > 0 and player.total_attacks_this_battle > 0 and player.total_attacks_this_battle % relic.effect_value == 0:
					result *= 2
	return max(0, result)


## 修改格挡值
static func on_block_gained(base_block: int, relics: Array[RelicData]) -> int:
	var result = base_block
	for relic in relics:
		match relic.effect_type:
			RelicData.EffectType.BLOCK_BONUS_FLAT:
				result += relic.effect_value
	return max(0, result)


## 获取商店折扣百分比(遍历所有遗物的SHOP_PRICE_DISCOUNT)
static func get_shop_discount(relics: Array[RelicData]) -> int:
	var discount = 0
	for relic in relics:
		if relic.effect_type == RelicData.EffectType.SHOP_PRICE_DISCOUNT:
			discount += relic.effect_value
	return discount


## 获取能力牌费用减免(丹塔秘卷)
static func get_ability_cost_reduction(relics: Array[RelicData]) -> int:
	var reduction = 0
	for relic in relics:
		if relic.effect_type == RelicData.EffectType.ABILITY_COST_REDUCE:
			reduction += relic.effect_value
	return reduction


## 施加状态时触发(冰晶护符：虚弱附带易伤)
static func on_status_applied(relics: Array[RelicData], status_type: String, target) -> void:
	for relic in relics:
		if relic.effect_type == RelicData.EffectType.WEAK_ALSO_VULNERABLE:
			if status_type == "weak":
				target.apply_vulnerable(relic.effect_value)


## 使用丹药时触发
static func on_potion_used(player: Player, relics: Array[RelicData]) -> void:
	for relic in relics:
		# 检查主效果
		match relic.effect_type:
			RelicData.EffectType.POTION_USE_DRAW:
				player.draw_cards(relic.effect_value)
			RelicData.EffectType.NEXT_CARD_DOUBLE:
				player.next_card_double = true
		# 检查第二效果
		if relic.effect_value_2 > 0:
			match relic.effect_type_2:
				RelicData.EffectType.POTION_USE_DRAW:
					player.draw_cards(relic.effect_value_2)
				RelicData.EffectType.NEXT_CARD_DOUBLE:
					player.next_card_double = true
		# 检查第三效果
		if relic.effect_value_3 > 0:
			match relic.effect_type_3:
				RelicData.EffectType.POTION_USE_DRAW:
					player.draw_cards(relic.effect_value_3)
				RelicData.EffectType.NEXT_CARD_DOUBLE:
					player.next_card_double = true


## 给予燃烧时触发，返回额外层数
static func on_burn_applied(relics: Array[RelicData]) -> int:
	var bonus = 0
	for relic in relics:
		match relic.effect_type:
			RelicData.EffectType.BURN_STACK_BONUS:
				bonus += relic.effect_value
	return bonus


## 事件中失去HP时触发
# _player 未使用，通过 PlayerManager 单例访问
static func on_event_hp_loss(_player, relics: Array[RelicData]) -> void:
	for relic in relics:
		match relic.effect_type:
			RelicData.EffectType.EVENT_HP_LOSS_GOLD:
				if relic.effect_value > 0:
					PlayerManager.add_gold(relic.effect_value)


## 战斗胜利时触发
## reward_gold: 本次战斗奖励金币（用于百分比加成计算）
static func on_victory(_player: Player, relics: Array[RelicData], battle_type: int = 0, reward_gold: int = 0) -> void:
	PlayerManager.battle_wins += 1
	var gold_percent_bonus: int = 0
	for relic in relics:
		match relic.effect_type:
			RelicData.EffectType.VICTORY_HEAL:
				PlayerManager.heal(relic.effect_value)
			RelicData.EffectType.VICTORY_GOLD:
				if relic.effect_value > 0:
					PlayerManager.add_gold(relic.effect_value)
			RelicData.EffectType.VICTORY_GOLD_EVERY_N:
				var interval = int(relic.effect_value / 1000.0)
				var amount = int(relic.effect_value) % 1000
				if interval > 0 and PlayerManager.battle_wins % interval == 0:
					PlayerManager.add_gold(amount)
			RelicData.EffectType.VICTORY_GOLD_ELITE:
				if battle_type == RewardManager.BattleType.ELITE:
					PlayerManager.add_gold(relic.effect_value)
			RelicData.EffectType.VICTORY_GOLD_PERCENT:
				gold_percent_bonus += relic.effect_value
			RelicData.EffectType.VICTORY_ENERGY:
				pass  # 预留: 斗气系统尚未实现
			RelicData.EffectType.VICTORY_UPGRADE_ELITE:
				# 强榜玉牌：击败精英随机升级牌库1张牌
				if battle_type == RewardManager.BattleType.ELITE:
					_upgrade_random_card()
			RelicData.EffectType.VICTORY_POTION_ELITE:
				# 万兽鼎：击败精英额外掉丹药
				if battle_type == RewardManager.BattleType.ELITE:
					if PlayerManager.potions.size() < PlayerManager.max_potion_slots:
						var potion = PotionManager.get_random_potion()
						if potion != null:
							PlayerManager.add_potion(potion)
			RelicData.EffectType.VICTORY_EXTRA_RELIC_POTION:
				# 黑魔鼎原片：胜利后额外获得遗物+丹药
				var extra_relic = RelicDatabase.get_relic(RNGManager.drop_rng.randi() % 50 + 1)
				if extra_relic != null and not PlayerManager.has_relic(extra_relic.id):
					PlayerManager.add_relic(extra_relic)
				var extra_potion = PotionManager.get_random_potion()
				if extra_potion != null:
					PlayerManager.add_potion(extra_potion)
			RelicData.EffectType.BATTLE_VICTORY_GOLD_BONUS:
				# 黑印城令牌：战斗金币+N%
				if reward_gold > 0:
					var bonus = int(reward_gold * relic.effect_value / 100.0)
					if bonus > 0:
						PlayerManager.add_gold(bonus)
		# 检查第二效果
		if relic.effect_value_2 > 0:
			match relic.effect_type_2:
				RelicData.EffectType.VICTORY_HEAL:
					PlayerManager.heal(relic.effect_value_2)
				RelicData.EffectType.VICTORY_GOLD:
					if relic.effect_value_2 > 0:
						PlayerManager.add_gold(relic.effect_value_2)
				RelicData.EffectType.VICTORY_GOLD_ELITE:
					if battle_type == RewardManager.BattleType.ELITE:
						PlayerManager.add_gold(relic.effect_value_2)
				RelicData.EffectType.VICTORY_UPGRADE_ELITE:
					if battle_type == RewardManager.BattleType.ELITE:
						_upgrade_random_card()
				RelicData.EffectType.VICTORY_POTION_ELITE:
					if battle_type == RewardManager.BattleType.ELITE:
						if PlayerManager.potions.size() < PlayerManager.max_potion_slots:
							var potion = PotionManager.get_random_potion()
							if potion != null:
								PlayerManager.add_potion(potion)
				RelicData.EffectType.VICTORY_EXTRA_RELIC_POTION:
					var extra_relic_2 = RelicDatabase.get_relic(RNGManager.drop_rng.randi() % 50 + 1)
					if extra_relic_2 != null and not PlayerManager.has_relic(extra_relic_2.id):
						PlayerManager.add_relic(extra_relic_2)
					var extra_potion_2 = PotionManager.get_random_potion()
					if extra_potion_2 != null:
						PlayerManager.add_potion(extra_potion_2)
				RelicData.EffectType.BATTLE_VICTORY_GOLD_BONUS:
					if reward_gold > 0:
						var bonus_2 = int(reward_gold * relic.effect_value_2 / 100.0)
						if bonus_2 > 0:
							PlayerManager.add_gold(bonus_2)
				RelicData.EffectType.VICTORY_GOLD_PERCENT:
					gold_percent_bonus += relic.effect_value_2
		# 检查第三效果
		if relic.effect_value_3 > 0:
			match relic.effect_type_3:
				RelicData.EffectType.VICTORY_HEAL:
					PlayerManager.heal(relic.effect_value_3)
				RelicData.EffectType.VICTORY_GOLD:
					if relic.effect_value_3 > 0:
						PlayerManager.add_gold(relic.effect_value_3)
				RelicData.EffectType.VICTORY_GOLD_ELITE:
					if battle_type == RewardManager.BattleType.ELITE:
						PlayerManager.add_gold(relic.effect_value_3)
				RelicData.EffectType.VICTORY_UPGRADE_ELITE:
					if battle_type == RewardManager.BattleType.ELITE:
						_upgrade_random_card()
				RelicData.EffectType.VICTORY_POTION_ELITE:
					if battle_type == RewardManager.BattleType.ELITE:
						if PlayerManager.potions.size() < PlayerManager.max_potion_slots:
							var potion = PotionManager.get_random_potion()
							if potion != null:
								PlayerManager.add_potion(potion)
				RelicData.EffectType.VICTORY_EXTRA_RELIC_POTION:
					var extra_relic_3 = RelicDatabase.get_relic(RNGManager.drop_rng.randi() % 50 + 1)
					if extra_relic_3 != null and not PlayerManager.has_relic(extra_relic_3.id):
						PlayerManager.add_relic(extra_relic_3)
					var extra_potion_3 = PotionManager.get_random_potion()
					if extra_potion_3 != null:
						PlayerManager.add_potion(extra_potion_3)
				RelicData.EffectType.BATTLE_VICTORY_GOLD_BONUS:
					if reward_gold > 0:
						var bonus_3 = int(reward_gold * relic.effect_value_3 / 100.0)
						if bonus_3 > 0:
							PlayerManager.add_gold(bonus_3)
				RelicData.EffectType.VICTORY_GOLD_PERCENT:
					gold_percent_bonus += relic.effect_value_3
	# 应用金币百分比加成（基于本次战斗奖励金币）
	if gold_percent_bonus > 0 and reward_gold > 0:
		var bonus_gold = int(reward_gold * gold_percent_bonus / 100.0)
		if bonus_gold > 0:
			PlayerManager.add_gold(bonus_gold)


## 强榜玉牌辅助：随机升级PlayerManager.deck中1张未升级的牌
static func _upgrade_random_card() -> void:
	var upgradeable: Array[CardData] = []
	for card in PlayerManager.deck:
		if not card.upgraded:
			upgradeable.append(card)
	if upgradeable.size() > 0:
		var idx = RNGManager.drop_rng.randi() % upgradeable.size()
		upgradeable[idx].apply_upgrade()
