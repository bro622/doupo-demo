## 敌人类
## 继承战斗单位，增加AI行为和阶段系统
class_name Enemy
extends Combatant

## 敌人意图类型
enum IntentType { ATTACK, DEFEND, BUFF, DEBUFF, SPECIAL, UNKNOWN, SUMMON }

## 行动定义
class EnemyAction:
	var intent: IntentType
	var damage: int = 0
	var hit_count: int = 1
	var block: int = 0
	var apply_burn: int = 0
	var apply_venom: int = 0
	var apply_weak: int = 0
	var apply_vulnerable: int = 0
	var apply_frail: int = 0
	var apply_frozen: int = 0
	var apply_armor_break: int = 0
	var heal: int = 0
	var strength_gain: int = 0
	var temp_strength: int = 0     # 临时力量：行动后获得，持续到下次行动后消失
	var aoe: bool = false          # 是否攻击全体敌人（用于反击等场景）
	var clear_debuffs: bool = false # 是否清除自身负面状态
	var add_card_id: String = ""   # 塞入玩家牌库的卡牌ID
	var add_card_count: int = 0    # 塞入数量
	var true_damage: bool = false  # 真实伤害：无视护盾
	var self_damage: int = 0       # 自伤：行动后对自身造成伤害（走火入魔者等）
	var damage_per_burn_stack: int = 0  # 每层燃烧额外伤害（心炎幻影等）
	var clear_player_block_mult: float = 0.0  # 清除玩家护盾并造成等量×mult伤害（禁地守卫等）
	var summon_id: String = ""       # 召唤敌人ID（心炎幻影等）
	var summon_count: int = 0        # 召唤数量
	var description: String = ""

	func _init(p_intent: IntentType, p_desc: String = "") -> void:
		intent = p_intent
		description = p_desc

## 阶段系统
var phases: Array[Array] = []           # 每个 phase 是一个 EnemyAction 数组
var phase_hp_thresholds: Array[float] = []  # 如 [0.5] 表示 HP<=50% 进入下一阶段
var current_phase: int = 0

## 行动模式列表（当前阶段）
var actions: Array[EnemyAction] = []
var current_action_index: int = 0

## 常驻被动效果
var passive_effects: Array[Dictionary] = []
# 格式: { "trigger": "turn_start", "type": "gain_block", "value": 4 }

## 首击减伤（每回合重置，纳兰嫣然等精英用）
var first_hit_reduction: int = 0

## 黑皇诀：对虚弱/易伤目标额外伤害
var bonus_damage_to_debuffed: int = 0

## 山岳之体：受到低于阈值的伤害时获得护盾
var shield_on_low_damage_threshold: int = 0
var shield_on_low_damage_amount: int = 0

## 药丹被动：每N回合生成丹药
var generate_potion_interval: int = 0
var _potion_turn_counter: int = 0

## 召唤请求（由 battle_manager 处理）
var pending_summons: Array[Dictionary] = []

## 是否为召唤物（用于召唤上限计数）
var is_summoned: bool = false

## 石化延迟意图（被石化时保存当前意图，下回合执行）
var delayed_intent: EnemyAction = null

## HP阈值动作（山贼等：HP<阈值时触发一次）
var low_hp_threshold: float = 0.0
var low_hp_action: EnemyAction = null
var _low_hp_triggered: bool = false

## 首动（海波东等：第一回合使用，之后循环后续动作）
var first_action: EnemyAction = null
var _first_action_used: bool = false

## 临时力量待清除（沙漠毒蝎等：行动后获得，下次行动后消失）
var _temp_strength_pending_clear: bool = false
var _temp_strength_amount: int = 0

## 当前显示的意图
var current_intent: EnemyAction


func _init(p_name: String, p_hp: int) -> void:
	super(p_name, p_hp)


## 受到伤害（首击减伤在护盾前生效，减少原始伤害）
func take_damage(amount: int, is_true_damage: bool = false) -> int:
	# 首击减伤：在易伤计算后、护盾吸收前生效
	if first_hit_reduction > 0:
		var reduced = mini(amount, first_hit_reduction)
		amount -= reduced
		first_hit_reduction -= reduced
	var actual = super(amount, is_true_damage)
	# 山岳之体：受到低于阈值的伤害时获得护盾
	if shield_on_low_damage_threshold > 0 and actual > 0 and actual < shield_on_low_damage_threshold:
		gain_block(shield_on_low_damage_amount)
	return actual


## 设置行动模式（单阶段敌人）
func set_actions(p_actions: Array[EnemyAction]) -> void:
	phases = [p_actions]
	phase_hp_thresholds = []
	current_phase = 0
	actions = p_actions
	current_action_index = 0
	_advance_intent()


## 设置多阶段行动模式
func set_phases(p_phases: Array[Array], p_thresholds: Array[float]) -> void:
	phases = p_phases
	phase_hp_thresholds = p_thresholds
	current_phase = 0
	actions = phases[0] if phases.size() > 0 else []
	current_action_index = 0
	_advance_intent()


## 添加常驻被动效果
func add_passive(trigger: String, type: String, value: int = 0) -> void:
	passive_effects.append({ "trigger": trigger, "type": type, "value": value })


## 执行被动效果（按触发时机）
func execute_passives(trigger: String, player = null) -> String:
	var msg = ""
	for passive in passive_effects:
		if passive["trigger"] != trigger:
			continue
		match passive["type"]:
			"gain_block":
				gain_block(passive["value"])
				msg += "%s 被动：获得 %d 点护盾。\n" % [char_name, passive["value"]]
			"gain_strength":
				strength += passive["value"]
				msg += "%s 被动：力量 +%d。\n" % [char_name, passive["value"]]
			"heal":
				var old_hp = hp
				hp = min(max_hp, hp + passive["value"])
				msg += "%s 被动：回复 %d 点HP。\n" % [char_name, hp - old_hp]
			"first_hit_reduction":
				first_hit_reduction = passive["value"]
				msg += "%s 被动：首次受击伤害 -%d。\n" % [char_name, passive["value"]]
			"damage_player":
				if player != null:
					player.take_damage(passive["value"], true)
					msg += "%s 领域：对玩家造成 %d 点灵魂伤害。\n" % [char_name, passive["value"]]
			"apply_weak_player":
				if player != null:
					player.apply_weak(passive["value"])
					msg += "%s 被动：施加 %d 层虚弱。\n" % [char_name, passive["value"]]
	# 药丹被动：每N回合生成丹药
	if generate_potion_interval > 0:
		_potion_turn_counter += 1
		if _potion_turn_counter % generate_potion_interval == 0:
			if PlayerManager.potions.size() < PlayerManager.max_potions:
				var potion = PotionDatabase.get_all_potions().pick_random()
				PlayerManager.potions.append(potion)
				msg += "%s 被动：生成丹药「%s」。\n" % [char_name, potion.potion_name]
	return msg


## 推进到下一个意图
func _advance_intent() -> void:
	# 首动优先（海波东冰封等，只用一次）
	# 注意：触发时不推进 current_action_index，正常循环从原位继续
	if first_action != null and not _first_action_used:
		current_intent = first_action
		_first_action_used = true
		return

	# HP阈值动作（山贼亡命一击等，触发一次）
	# 注意：同上，循环"暂停"而非重置
	if low_hp_action != null and not _low_hp_triggered:
		var hp_ratio = float(hp) / float(max_hp)
		if hp_ratio < low_hp_threshold:
			current_intent = low_hp_action
			_low_hp_triggered = true
			return

	if actions.size() > 0:
		current_intent = actions[current_action_index]
		current_action_index = (current_action_index + 1) % actions.size()


## 检查阶段转换
func _check_phase_transition() -> bool:
	if phase_hp_thresholds.size() == 0:
		return false
	if current_phase >= phase_hp_thresholds.size():
		return false

	var hp_ratio = float(hp) / float(max_hp)
	if hp_ratio <= phase_hp_thresholds[current_phase]:
		current_phase += 1
		if current_phase < phases.size():
			actions = phases[current_phase]
			current_action_index = 0
			_advance_intent()
			return true
	return false


## 获取阶段转换描述（供 battle_manager 显示）
func get_phase_transition_text() -> String:
	if current_phase > 0 and current_phase <= phases.size():
		return "%s 进入了第 %d 阶段！" % [char_name, current_phase + 1]
	return ""


## 执行当前意图
func execute_intent(player: Player) -> String:
	var intent = current_intent
	var log_msg = ""

	# 防御 null
	if intent == null:
		push_warning("enemy.execute_intent: current_intent is null for %s" % char_name)
		return ""

	# 石化检查：被石化时延迟意图到下回合
	if petrified > 0:
		log_msg = "%s 被石化，无法行动！" % char_name
		# 保存当前意图到延迟槽
		delayed_intent = current_intent
		# 推进到下一个意图（但不执行）
		_advance_intent()
		petrified -= 1  # 石化持续1回合
		return log_msg

	# 清除上一次行动的临时力量（在当前行动前清除，让当前行动的temp_strength生效）
	if _temp_strength_pending_clear:
		strength -= _temp_strength_amount
		_temp_strength_amount = 0
		_temp_strength_pending_clear = false

	match intent.intent:
		IntentType.ATTACK:
			var total_damage = 0
			for i in range(intent.hit_count):
				var dmg = calc_attack_damage(intent.damage)
				# 黑皇诀：对虚弱/易伤目标额外伤害
				if bonus_damage_to_debuffed > 0 and (player.weak > 0 or player.vulnerable > 0):
					dmg += bonus_damage_to_debuffed
				var actual = player.take_damage(dmg, intent.true_damage)
				total_damage += actual
			if intent.hit_count > 1:
				log_msg = "%s 发动攻击，造成 %d 点伤害（%d×%d）！" % [char_name, total_damage, intent.hit_count, intent.damage]
			else:
				log_msg = "%s 发动攻击，造成 %d 点伤害！" % [char_name, total_damage]

		IntentType.DEFEND:
			gain_block(intent.block)
			log_msg = "%s 获得 %d 点护盾。" % [char_name, intent.block]

		IntentType.BUFF:
			if intent.clear_debuffs:
				clear_all_debuffs()
				log_msg = "%s 清除了所有负面状态！" % char_name
			if intent.strength_gain > 0:
				strength += intent.strength_gain
				log_msg += "%s 力量 +%d。" % [char_name, intent.strength_gain]
			if intent.heal > 0:
				var old_hp = hp
				hp = min(max_hp, hp + intent.heal)
				log_msg += "%s 回复 %d 点HP。" % [char_name, hp - old_hp]

		IntentType.DEBUFF:
			var debuffs = []
			if intent.apply_burn > 0:
				player.apply_burn(intent.apply_burn)
				debuffs.append("燃烧 %d" % intent.apply_burn)
			if intent.apply_venom > 0:
				player.apply_venom(intent.apply_venom)
				debuffs.append("蛇毒 %d" % intent.apply_venom)
			if intent.apply_weak > 0:
				player.apply_weak(intent.apply_weak)
				debuffs.append("虚弱 %d" % intent.apply_weak)
			if intent.apply_vulnerable > 0:
				player.apply_vulnerable(intent.apply_vulnerable)
				debuffs.append("易伤 %d" % intent.apply_vulnerable)
			if intent.apply_frail > 0:
				player.apply_frail(intent.apply_frail)
				debuffs.append("脆弱 %d" % intent.apply_frail)
			if intent.apply_frozen > 0:
				player.apply_frozen(intent.apply_frozen)
				debuffs.append("冰封 %d" % intent.apply_frozen)
			if intent.apply_armor_break > 0:
				player.apply_armor_break(intent.apply_armor_break)
				debuffs.append("破甲 %d" % intent.apply_armor_break)
			if intent.add_card_id != "" and intent.add_card_count > 0:
				_add_cards_to_player_draw_pile(player, intent.add_card_id, intent.add_card_count)
				debuffs.append("塞入 %d 张状态牌" % intent.add_card_count)
			log_msg = "%s 对你施加 %s！" % [char_name, ", ".join(debuffs)]

		IntentType.SPECIAL:
			# 组合动作：可同时攻击+防御+施加状态
			var parts = []
			if intent.clear_debuffs:
				clear_all_debuffs()
				parts.append("清除负面状态")
			# 清盾伤害：先计算再清除，后续攻击直击HP
			if intent.clear_player_block_mult > 0 and player.block > 0:
				var clear_dmg = roundi(player.block * intent.clear_player_block_mult)
				if clear_dmg > 0:
					if player.vulnerable > 0:
						clear_dmg = roundi(clear_dmg * 1.5)
					if player.petrified > 0:
						clear_dmg = roundi(clear_dmg * 1.2)
					player.block = 0
					var clear_actual = player.take_damage(clear_dmg, true)
					parts.append("清盾造成 %d 伤害" % clear_actual)
			if intent.damage > 0 or intent.damage_per_burn_stack > 0:
				var total_actual = 0
				var burn_bonus = intent.damage_per_burn_stack * player.burn if intent.damage_per_burn_stack > 0 else 0
				for i in range(intent.hit_count):
					var dmg = calc_attack_damage(intent.damage)
					if i == 0:
						dmg += burn_bonus
					total_actual += player.take_damage(dmg, intent.true_damage)
				if intent.hit_count > 1:
					parts.append("造成 %d 伤害（%d×%d）" % [total_actual, intent.hit_count, intent.damage])
				else:
					parts.append("造成 %d 伤害" % total_actual)
			if intent.block > 0:
				gain_block(intent.block)
				parts.append("获得 %d 护盾" % intent.block)
			if intent.strength_gain > 0:
				strength += intent.strength_gain
				parts.append("力量 +%d" % intent.strength_gain)
			if intent.heal > 0:
				var old_hp = hp
				hp = min(max_hp, hp + intent.heal)
				parts.append("回复 %d HP" % (hp - old_hp))
			if intent.apply_burn > 0:
				player.apply_burn(intent.apply_burn)
				parts.append("施加燃烧 %d" % intent.apply_burn)
			if intent.apply_venom > 0:
				player.apply_venom(intent.apply_venom)
				parts.append("施加蛇毒 %d" % intent.apply_venom)
			if intent.apply_weak > 0:
				player.apply_weak(intent.apply_weak)
				parts.append("施加虚弱 %d" % intent.apply_weak)
			if intent.apply_vulnerable > 0:
				player.apply_vulnerable(intent.apply_vulnerable)
				parts.append("施加易伤 %d" % intent.apply_vulnerable)
			if intent.apply_frail > 0:
				player.apply_frail(intent.apply_frail)
				parts.append("施加脆弱 %d" % intent.apply_frail)
			if intent.apply_frozen > 0:
				player.apply_frozen(intent.apply_frozen)
				parts.append("施加冰封 %d" % intent.apply_frozen)
			if intent.add_card_id != "" and intent.add_card_count > 0:
				_add_cards_to_player_draw_pile(player, intent.add_card_id, intent.add_card_count)
				parts.append("塞入 %d 张状态牌" % intent.add_card_count)
			log_msg = "%s：%s" % [char_name, "，".join(parts)]

		IntentType.SUMMON:
			pending_summons.append({"id": intent.summon_id, "count": intent.summon_count})
			log_msg = "%s 召唤了援军！" % char_name

	# 应用临时力量（当前行动后生效，下次行动后消失）
	if intent.temp_strength > 0:
		strength += intent.temp_strength
		_temp_strength_amount = intent.temp_strength
		_temp_strength_pending_clear = true
		log_msg += "\n%s 力量临时 +%d" % [char_name, intent.temp_strength]

	# 自伤（走火入魔者等：行动后对自身造成伤害）
	if intent.self_damage > 0:
		hp = max(0, hp - intent.self_damage)
		log_msg += "\n%s 自伤 %d" % [char_name, intent.self_damage]

	# 检查阶段转换（转换时内部已推进意图），未转换时手动推进
	if not _check_phase_transition():
		_advance_intent()

	return log_msg


## 获取意图图标（单一数据源，emoji 回退用于纯文本场景如 battle_log）
func get_intent_icon() -> String:
	if current_intent == null:
		return "❓"
	match current_intent.intent:
		IntentType.ATTACK:
			var total_dmg = calc_attack_damage(current_intent.damage) * current_intent.hit_count
			return "💀" if total_dmg >= 15 else "⚔️"
		IntentType.DEFEND:
			return "🛡️"
		IntentType.BUFF:
			return "❤️" if current_intent.heal > 0 else "💪"
		IntentType.DEBUFF:
			return "🔮"
		IntentType.SPECIAL:
			if current_intent.damage > 0 or current_intent.clear_player_block_mult > 0 or current_intent.damage_per_burn_stack > 0:
				return "💀" if calc_attack_damage(current_intent.damage) * current_intent.hit_count >= 15 or current_intent.clear_player_block_mult > 0 else "⚔️"
			elif current_intent.block > 0:
				return "🛡️"
			else:
				return "🔮"
		IntentType.SUMMON:
			return "👥"
	return "?"


## 获取意图 PNG 图标路径（参考 STS2 AttackIntent 按伤害量分级）
func get_intent_icon_path() -> String:
	if current_intent == null:
		return "res://assets/ui/intents/intent_unknown.png"
	match current_intent.intent:
		IntentType.ATTACK:
			var total_dmg = calc_attack_damage(current_intent.damage) * current_intent.hit_count
			if total_dmg >= 15:
				return "res://assets/ui/intents/intent_attack_high.png"
			elif total_dmg >= 8:
				return "res://assets/ui/intents/intent_attack_mid.png"
			else:
				return "res://assets/ui/intents/intent_attack_low.png"
		IntentType.DEFEND:
			return "res://assets/ui/intents/intent_defend.png"
		IntentType.BUFF:
			if current_intent.heal > 0:
				return "res://assets/ui/intents/intent_heal.png"
			return "res://assets/ui/intents/intent_buff.png"
		IntentType.DEBUFF:
			return "res://assets/ui/intents/intent_debuff.png"
		IntentType.SPECIAL:
			if current_intent.damage > 0 or current_intent.clear_player_block_mult > 0 or current_intent.damage_per_burn_stack > 0:
				var total_dmg = calc_attack_damage(current_intent.damage) * current_intent.hit_count
				if total_dmg >= 15 or current_intent.clear_player_block_mult > 0:
					return "res://assets/ui/intents/intent_attack_high.png"
				elif total_dmg >= 8:
					return "res://assets/ui/intents/intent_attack_mid.png"
				else:
					return "res://assets/ui/intents/intent_attack_low.png"
			elif current_intent.block > 0:
				return "res://assets/ui/intents/intent_defend.png"
			else:
				return "res://assets/ui/intents/intent_debuff.png"
		IntentType.SUMMON:
			return "res://assets/ui/intents/intent_buff.png"
	return "res://assets/ui/intents/intent_unknown.png"


## 获取意图显示文本（纯文本，不含 emoji，图标由 TextureRect 显示）
func get_intent_text() -> String:
	if current_intent == null:
		return "未知"

	var detail = ""

	match current_intent.intent:
		IntentType.ATTACK:
			var total_dmg = calc_attack_damage(current_intent.damage) * current_intent.hit_count
			if current_intent.hit_count > 1:
				detail = "攻击 %d×%d (预计%d)" % [current_intent.damage, current_intent.hit_count, total_dmg]
			else:
				detail = "攻击 (预计%d)" % total_dmg
		IntentType.DEFEND:
			detail = "护盾 %d" % current_intent.block
		IntentType.BUFF:
			var buff_parts = []
			if current_intent.heal > 0:
				buff_parts.append("回复 %d" % current_intent.heal)
			if current_intent.strength_gain > 0:
				buff_parts.append("力量 +%d" % current_intent.strength_gain)
			if current_intent.clear_debuffs:
				buff_parts.append("清除debuff")
			detail = "，".join(buff_parts) if buff_parts.size() > 0 else "增强"
		IntentType.DEBUFF:
			var debuffs = []
			if current_intent.apply_burn > 0: debuffs.append("燃烧")
			if current_intent.apply_venom > 0: debuffs.append("蛇毒")
			if current_intent.apply_weak > 0: debuffs.append("虚弱")
			if current_intent.apply_vulnerable > 0: debuffs.append("易伤")
			if current_intent.apply_frail > 0: debuffs.append("脆弱")
			if current_intent.apply_frozen > 0: debuffs.append("冰封")
			detail = ", ".join(debuffs) if debuffs.size() > 0 else "施法"
		IntentType.SPECIAL:
			var parts = []
			if current_intent.clear_player_block_mult > 0:
				parts.append("清盾×%.1f" % current_intent.clear_player_block_mult)
			if current_intent.damage > 0:
				var total_dmg = calc_attack_damage(current_intent.damage) * current_intent.hit_count
				if current_intent.hit_count > 1:
					parts.append("攻击 %d×%d(预计%d)" % [current_intent.damage, current_intent.hit_count, total_dmg])
				else:
					parts.append("攻击(预计%d)" % total_dmg)
			if current_intent.damage_per_burn_stack > 0:
				parts.append("燃烧×%d" % current_intent.damage_per_burn_stack)
			if current_intent.block > 0:
				parts.append("护盾 %d" % current_intent.block)
			if current_intent.strength_gain > 0:
				parts.append("力量 +%d" % current_intent.strength_gain)
			if current_intent.heal > 0:
				parts.append("回复 %d" % current_intent.heal)
			if current_intent.apply_burn > 0:
				parts.append("燃烧 %d" % current_intent.apply_burn)
			if current_intent.apply_venom > 0:
				parts.append("蛇毒 %d" % current_intent.apply_venom)
			if current_intent.apply_weak > 0:
				parts.append("虚弱 %d" % current_intent.apply_weak)
			if current_intent.apply_vulnerable > 0:
				parts.append("易伤 %d" % current_intent.apply_vulnerable)
			if current_intent.apply_frail > 0:
				parts.append("脆弱 %d" % current_intent.apply_frail)
			if current_intent.apply_frozen > 0:
				parts.append("冰封 %d" % current_intent.apply_frozen)
			detail = ", ".join(parts) if parts.size() > 0 else "特殊"
		IntentType.SUMMON:
			detail = "召唤 ×%d" % current_intent.summon_count

	return detail


## 获取敌人简要状态（用于UI显示）
func get_brief_status() -> String:
	var text = "%s HP:%d/%d" % [char_name, hp, max_hp]
	if block > 0:
		text += " 护盾:%d" % block
	var effects = []
	if burn > 0: effects.append("燃烧:%d" % burn)
	if venom > 0: effects.append("蛇毒:%d" % venom)
	if weak > 0: effects.append("虚弱:%d" % weak)
	if vulnerable > 0: effects.append("易伤:%d" % vulnerable)
	if frail > 0: effects.append("脆弱:%d" % frail)
	if frozen > 0: effects.append("冰封:%d" % frozen)
	if armor_break > 0: effects.append("破甲:%d" % armor_break)
	if strength > 0: effects.append("力量:%d" % strength)
	if effects.size() > 0:
		text += " [%s]" % ", ".join(effects)
	return text


## 塞入状态牌到玩家抽牌堆
func _add_cards_to_player_draw_pile(player: Player, card_id: String, count: int) -> void:
	# 从卡牌数据库查找卡牌模板
	var all_cards = CardDatabase.get_all_cards()
	var template: CardData = null
	for card in all_cards:
		if card.id == card_id:
			template = card
			break
	if template == null:
		push_warning("Enemy: 找不到卡牌 %s" % card_id)
		return
	for i in range(count):
		var new_card = template.duplicate_card()
		player.draw_pile.append(new_card)
	# 洗牌
	RNGManager.shuffle_deck_in_place(player.draw_pile)
