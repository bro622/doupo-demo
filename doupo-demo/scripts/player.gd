## 玩家类
## 继承战斗单位，增加卡牌系统和斗气系统
class_name Player
extends Combatant

## 洗牌信号（弃牌堆洗入抽牌堆时触发，供战斗动画使用）
signal deck_shuffled

## 异火类型（萧炎专属）
enum FireType { GREEN, WHITE, BLUE, PURPLE }

## 斗气系统
var energy: int = 3
var max_energy: int = 3
var energy_per_turn: int = 3
var bonus_energy: int = 0  # 敌人回合获得的额外能量（如药老附体），回合开始时加入

## 异火槽系统（萧炎专属）
var fire_slots: Array[FireType] = []
var max_fire_slots: int = 3

## 记录本回合是否激发过异火（用于异火连击等卡牌条件判断）
var evoked_this_turn: bool = false

## 下一张牌打出两次（药皇戒指效果）
var next_card_double: bool = false
## 下N张牌打出两次（千年传承升级效果）
var next_card_double_remaining: int = 0
## 魂殿黑袍：首张攻击牌打出两次（每场）
var first_attack_double_available: bool = false
## 菩提古树之心：本回合首张牌免费
var first_card_free_this_turn: bool = false

## 跳过play_card内部能量扣除（battle_manager已提前扣除，含玄重尺等加价）
var _skip_energy_deduction: bool = false

## 下一张牌耗能修改（紫云翼等）
var next_card_cost_modifier: int = 0
## 本回合所有手牌费用减免（天雁九行翼）
var hand_cost_reduction: int = 0

## 下回合少抽牌数（凝火诀惩罚）
var next_turn_draw_penalty: int = 0

## 下回合是否可以凝聚异火（斗气化铠）
var can_channel_next_turn: bool = true

## 本回合每次激发异火获得的额外护盾（药鼎守护）
var evoke_block_this_turn: int = 0

## 本回合受击时给予敌人的燃烧层数（焰分噬浪尺·守）
var on_hit_burn_this_turn: int = 0

## 最近一张牌实际提供的护盾值（焰分噬浪尺·守引用）
var last_card_block: int = 0

## 回气散配方：本回合已打出牌数计数
var cards_played_for_relic_count: int = 0

## 焱之拳套：本回合连续攻击牌计数
var consecutive_attacks_this_turn: int = 0
## 紫晶翼：本回合技能牌计数
var skill_cards_this_turn: int = 0
## 黑铁长枪：本场战斗攻击牌总计数
var total_attacks_this_battle: int = 0

## 玄重尺：本回合是否已触发第一张攻击额外消耗
var xuanzhongchi_first_attack_pending: bool = false

## 萧家功法残页：第一回合第一张攻击牌伤害加成是否已使用
var first_turn_attack_bonus_used: bool = false

## 古帝残魂碎片：第一回合已免费打出的牌数
var first_turn_free_cards_used: int = 0

## 山岳之心：战斗中是否已触发过HP<50%
var mountain_heart_triggered: bool = false
## 山岳之心：下次伤害是否归零
var next_damage_zero: bool = false
## 骨炎戒：战斗中是否已触发过药老附体
var guyan_triggered: bool = false
var first_hp_lost_triggered: bool = false  # 迦南院徽：首次受伤抽牌
## 进入战斗时的HP（用于骨炎戒50%判定）
var battle_start_hp: int = 0

## 卡牌区域
var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []
var exhaust_pile: Array[CardData] = []
var in_play: Array[CardData] = []  # 在场能力牌（打出后永久留在场上，战斗结束清除）

## 每回合抽牌数
var cards_per_turn: int = 5
## 下回合额外抽牌数（遗物效果累积）
var bonus_draw_next_turn: int = 0

## 首回合标记（固有牌判定用）
var _is_first_turn: bool = false

## 首回合临时额外抽牌（事件效果，首回合后扣回）
var _bonus_first_turn_draw: int = 0


## === 能力牌被动效果追踪 ===
var ability_burn_no_decay: bool = false     # 怒火中烧：燃烧不减少
var ability_burn_damage_mult: float = 1.0   # 怒火中烧：燃烧伤害倍率
var ability_strength_on_evoke: int = 0      # 天火三玄变：每次激发获得力量
var ability_passive_count: int = 0          # 异火共鸣：被动效果触发次数（默认1，每张+1）
var ability_block_per_fire: int = 0         # 火灵护体：回合开始每异火+N护盾
var ability_extra_draw: int = 0             # 斗气凝聚：回合开始多抽N张
var ability_auto_channel_fire: int = -1     # 星空体质：回合开始自动凝聚异火
var ability_auto_channel_count: int = 0     # 星空体质：每次凝聚几朵
var ability_evoke_count: int = 0            # 炎帝之姿：激发效果触发次数（默认1，每张+1）
var ability_lotus_count: int = 0            # 青莲地心火·本源：叠加数量
var permanent_green_fire_count: int = 0     # 永久青莲地心火数量（不占异火槽）

## === 萧薰儿专属：金印/连击能力牌被动效果追踪 ===
var ability_gold_seal_on_attack: int = 0        # 古族血统：打出攻击牌时+N金印
var ability_random_gold_seal_on_attack: int = 0 # 古族血统（升级）：打出攻击牌时额外随机敌人+N金印
var ability_gold_seal_thorns: int = 0           # 金印荆棘：被攻击时给攻击者施加N层金印
var ability_gold_seal_on_turn_start: int = 0    # 帝炎刻印：回合开始给所有敌人+N金印
var ability_extra_gold_seal_first: int = 0      # 印记共鸣：首次施加金印时额外+N
var seal_resonance_used_this_turn: bool = false  # 印记共鸣：本回合是否已触发
var ability_block_on_detonate: int = 0          # 金焰共鸣：每次引爆+N护盾
var ability_damage_on_detonate: int = 0         # 金莲守护：每次引爆对所有敌人造成N伤害
var ability_first_card_double: bool = false     # 古族千年传承：每回合第一张牌打出两次
var ability_combo_no_condition: bool = false    # 阵法大师：连击牌无条件触发
var ability_detonation_threshold: int = 5       # 神品血脉：引爆阈值（默认5，降低为4）
var ability_damage_per_4_cards: int = 0         # 古族战意：每打出4张牌造成N伤害
var ability_xuner_extra_draw: int = 0           # 光之亲和：回合开始多抽N张

## 萧薰儿：本回合引爆次数（遗物/能力牌联动）
var detonation_count_this_turn: int = 0
## 萧薰儿：总引爆次数（古帝碎涅指费用减免）
var detonation_count_total: int = 0

## === 美杜莎专属：双生姿态系统 ===
## 姿态值：0=NONE, 1=QUEEN, 2=PYTHON
var current_stance: int = 0
var stance_switch_this_turn: bool = false # 姿态精通：本回合是否已切换
var stance_switch_triggered_this_battle: bool = false  # 七彩蛇鳞：本场战斗是否已触发首次切换效果

## 美杜莎能力牌被动
var ability_venom_on_hit: int = 0         # 毒蛇体质：受击时给攻击者N层蛇毒
var ability_strength_on_python: int = 0   # 冷血杀手：进入吞天蟒时+N力量(回合)
var ability_block_on_switch: int = 0      # 蛇魂共鸣：切换姿态时+N护盾
var ability_extra_venom: int = 0          # 蟒毒蔓延：施加蛇毒时额外+N层
var ability_venom_on_turn_start: int = 0  # 蟒毒体质：回合开始给所有敌人N层蛇毒
var ability_queen_block_mult = 1.0 # 女王之姿：女王姿态护盾倍率
var ability_no_python_penalty: bool = false # 远古血脉：取消吞天蟒受伤惩罚
var ability_kill_heal: int = 0            # 九彩吞天蟒之魂：击杀回复N HP
var ability_kill_strength: int = 0        # 九彩吞天蟒之魂：击杀获得N永久力量
var ability_stance_mastery: bool = false  # 姿态精通：切换后下一张牌-1费
var ability_stance_mastery_energy: int = 0 # 姿态精通：每回合首次切换+1能量

## 美杜莎：本回合受击时蛇毒荆棘
var venom_thorns_this_turn: int = 0
var queen_venom_thorns_this_turn: int = 0  # 美杜莎之盾：女王姿态受击蛇毒

## 姿态切换信号
signal stance_changed(new_stance: int, old_stance: int)


## 从在场能力牌重算所有被动效果（每回合开始时调用）
## 所有效果均可叠加：数值类累加，布尔类转为计数
func _recalculate_ability_effects() -> void:
	# 重置为默认值
	ability_burn_no_decay = false
	ability_burn_damage_mult = 1.0
	ability_strength_on_evoke = 0
	ability_passive_count = 0
	ability_block_per_fire = 0
	ability_extra_draw = 0
	ability_auto_channel_fire = -1
	ability_auto_channel_count = 0
	ability_evoke_count = 0
	ability_lotus_count = 0
	permanent_green_fire_count = 0
	max_fire_slots = 3  # 从基础值重算
	# 萧薰儿能力牌重算
	ability_gold_seal_on_attack = 0
	ability_random_gold_seal_on_attack = 0
	ability_gold_seal_thorns = 0
	ability_gold_seal_on_turn_start = 0
	ability_extra_gold_seal_first = 0
	ability_block_on_detonate = 0
	ability_damage_on_detonate = 0
	ability_first_card_double = false
	ability_combo_no_condition = false
	ability_detonation_threshold = 5
	ability_damage_per_4_cards = 0
	ability_xuner_extra_draw = 0
	# 美杜莎能力牌重算
	ability_venom_on_hit = 0
	ability_strength_on_python = 0
	ability_block_on_switch = 0
	ability_extra_venom = 0
	ability_venom_on_turn_start = 0
	ability_queen_block_mult = 1.0
	ability_no_python_penalty = false
	ability_kill_heal = 0
	ability_kill_strength = 0
	ability_stance_mastery = false
	ability_stance_mastery_energy = 0

	for card in in_play:
		match card.id:
			"rage_burning":
				ability_burn_no_decay = true
				# 加法累加（非乘法），两张1.5倍 = 1.0+0.5+0.5 = 2.0
				ability_burn_damage_mult += card.burn_damage_mult - 1.0
			"fire_script":
				max_fire_slots += 1 if not card.upgraded else 2
			"heavenly_fire":
				ability_strength_on_evoke += card.gain_strength if card.gain_strength > 0 else 1
			"fire_resonance":
				ability_passive_count += 1  # 每张+1次被动触发
			"fire_spirit_guard":
				ability_block_per_fire += card.block if card.block > 0 else 2
			"qi_gather":
				ability_extra_draw += card.draw_cards if card.draw_cards > 0 else 1
			"star_body":
				ability_auto_channel_fire = FireType.PURPLE
				ability_auto_channel_count += 1  # 每张凝聚1朵
			"emperor_form":
				ability_evoke_count += 1  # 每张+1次激发
			"green_lotus_origin":
				ability_lotus_count += 1
				permanent_green_fire_count += 1  # 每张1朵永久绿火
			# === 萧薰儿能力牌 ===
			"ancient_bloodline":
				ability_gold_seal_on_attack += 1
				if card.upgraded:
					ability_random_gold_seal_on_attack += 1
			"emperor_seal_engrave":
				ability_gold_seal_on_turn_start += card.apply_gold_seal if card.apply_gold_seal > 0 else 1
			"seal_resonance":
				ability_extra_gold_seal_first += 2 if not card.upgraded else 3
			"golden_flame_resonance":
				ability_block_on_detonate += 3 if not card.upgraded else 4
			"golden_lotus_guard":
				ability_damage_on_detonate += 3 if not card.upgraded else 5
			"ancient_thousand_inherit":
				ability_first_card_double = true
			"formation_master":
				ability_combo_no_condition = true
			"divine_blood":
				ability_detonation_threshold = 4
			"ancient_war_will":
				ability_damage_per_4_cards += 4 if not card.upgraded else 6
			"light_affinity":
				ability_xuner_extra_draw += card.draw_cards if card.draw_cards > 0 else 1
			# === 美杜莎能力牌 ===
			"venom_body":
				ability_venom_on_hit += 2 if not card.upgraded else 3
			"cold_blood_killer":
				ability_strength_on_python += 1 if not card.upgraded else 2
			"snake_soul_resonance":
				ability_block_on_switch += 3 if not card.upgraded else 4
			"python_venom_spread":
				ability_extra_venom += 1 if not card.upgraded else 2
			"stance_mastery":
				ability_stance_mastery = true
				ability_stance_mastery_energy = 1
			"python_venom_body":
				ability_venom_on_turn_start += 2 if not card.upgraded else 3
			"queen_posture":
				var mult = 1.4 if not card.upgraded else 1.7
				ability_queen_block_mult += mult - 1.0
			"ancient_bloodline_cailin":
				ability_no_python_penalty = true
			"nine_color_python_soul":
				ability_kill_heal += 5 if not card.upgraded else 8
				ability_kill_strength += 1
			"snake_queen":
				ability_no_python_penalty = true


## 检查手牌中是否存在指定ID的牌（诅咒被动判定）
func has_card_in_hand(card_id: String) -> bool:
	for card in hand:
		if card.id == card_id:
			return true
	return false


## === 美杜莎：姿态切换系统 ===

## 切换姿态（返回切换信息，由battle_manager调用）
func switch_stance(new_stance: int) -> Dictionary:
	var result = { "changed": false, "msg": "" }
	if current_stance == new_stance:
		return result

	var old_stance = current_stance
	current_stance = new_stance
	result.changed = true

	# 姿态精通：切换后下一张牌-1费
	if ability_stance_mastery:
		next_card_cost_modifier = -1
		result.msg += "  ★ 姿态精通：下一张牌耗能 -1\n"

	# 姿态精通：每回合首次切换+1能量（只在未切换过时触发）
	if ability_stance_mastery_energy > 0 and not stance_switch_this_turn:
		gain_energy(ability_stance_mastery_energy)
		result.msg += "  ★ 姿态精通：获得 %d 点能量\n" % ability_stance_mastery_energy

	# 标记本回合已切换（放在能量检查之后，确保首次切换能获得能量）
	stance_switch_this_turn = true

	# 七彩蛇鳞：首次切换姿态时获得能量并抽牌（数据驱动）
	if not stance_switch_triggered_this_battle:
		stance_switch_triggered_this_battle = true
		for relic in PlayerManager.relics:
			if relic.effect_type == RelicData.EffectType.STANCE_SWITCH_ENERGY:
				gain_energy(relic.effect_value)
				result.msg += "  ★ %s：获得 %d 点能量\n" % [relic.relic_name, relic.effect_value]
			if relic.effect_type == RelicData.EffectType.STANCE_SWITCH_CARD_DRAW or relic.effect_type_2 == RelicData.EffectType.STANCE_SWITCH_CARD_DRAW:
				var draw_val = relic.effect_value if relic.effect_type == RelicData.EffectType.STANCE_SWITCH_CARD_DRAW else relic.effect_value_2
				var drawn_cards = draw_cards(draw_val)
				result.msg += "  ★ %s：抽 %d 张牌\n" % [relic.relic_name, drawn_cards.size()]

	# 蛇魂共鸣：切换时获得护盾
	if ability_block_on_switch > 0:
		var block_amount = ability_block_on_switch
		if current_stance == 1:
			block_amount = int(block_amount * ability_queen_block_mult)
		gain_block(block_amount)
		result.msg += "  ★ 蛇魂共鸣：获得 %d 护盾\n" % block_amount

	# 冷血杀手：进入吞天蟒时获得力量
	if current_stance == 2 and ability_strength_on_python > 0:
		strength += ability_strength_on_python
		result.msg += "  ★ 冷血杀手：力量 +%d\n" % ability_strength_on_python

	# 发送信号（用于视觉/UI更新）
	stance_changed.emit(new_stance, old_stance)

	var stance_name = "无姿态"
	match current_stance:
		1: stance_name = "女王姿态"
		2: stance_name = "吞天蟒姿态"
	result.msg += "  进入【%s】\n" % stance_name

	return result


## 离开当前姿态（回到无姿态）
func leave_stance() -> Dictionary:
	var result = { "changed": false, "msg": "" }
	if current_stance == 0:
		return result
	var old_stance = current_stance
	current_stance = 0
	result.changed = true
	result.msg += "  离开姿态，回到【无姿态】\n"
	return result


## 获取姿态名称
func get_stance_name() -> String:
	match current_stance:
		1: return "女王姿态"
		2: return "吞天蟒姿态"
		_: return "无姿态"


## 最近一次抽牌触发的诅咒日志
var last_curse_log: String = ""

## 最近一次受伤触发的遗物日志（骨炎戒药老附体等）
var last_relic_log: String = ""

## 抽牌时触发诅咒效果
func _trigger_on_draw(card: CardData) -> String:
	if card.card_type != CardData.CardType.CURSE:
		return ""
	match card.id:
		"qi_seal":
			next_card_cost_modifier += 1
			return "斗气封印：本回合下一张牌耗能 +1\n"
		"inner_demon":
			energy = max(0, energy - 1)
			return "心魔来袭：能量 -1\n"
		"beast_backlash":
			hp = max(0, hp - 2)
			# 随机丢弃1张手牌（排除beast_backlash自身，它在hand末尾）
			if hand.size() > 1:
				var idx = RNGManager.monster_rng.randi() % (hand.size() - 1)
				var discarded = hand[idx]
				hand.remove_at(idx)
				discard_pile.append(discarded)
				return "兽性反噬：失去 2 HP，丢弃「%s」\n" % discarded.card_name
			return "兽性反噬：失去 2 HP\n"
		"blood_toxin_backlash":
			hp = max(0, hp - 4)
			return "血毒反噬：失去 4 HP\n"
		"earth_devil_curse":
			hp = max(0, hp - 5)
			return "地魔诅咒：失去 5 HP\n"
		"soul_trauma":
			hp = max(0, hp - 3)
			return "灵魂创伤：失去 3 HP\n"
	return ""


func _init(p_name: String, p_hp: int) -> void:
	super(p_name, p_hp)
	frozen_decrement_at_turn_end = true


## 重写受伤方法（山岳之心：下次伤害归零 + 美杜莎姿态 + 阴阳玄龙丹）
func take_damage(amount: int, is_true_damage: bool = false) -> int:
	if next_damage_zero:
		next_damage_zero = false
		return 0
	# 美杜莎：吞天蟒姿态受伤+25%（远古血脉取消）
	if current_stance == 2 and not ability_no_python_penalty:
		amount = roundi(amount * 1.25)
	var actual = super(amount, is_true_damage)
	death_prevent_hp_percent = 0  # 确保基类的死亡保护不干扰丹药逻辑
	# 骨炎戒：药老附体（HP<50%时触发，每场限1次）
	if not guyan_triggered and hp > 0 and hp < battle_start_hp * 0.5:
		last_relic_log += RelicManager.check_low_hp_trigger(self, PlayerManager.relics)
	# 遗物：天妖凰精血 — 致死伤害防止
	if hp <= 0:
		if RelicManager.check_death_prevent(self, PlayerManager.relics):
			actual = 0
		elif hp <= 0:
			# 丹药：阴阳玄龙丹 — 被动触发，自动消耗
			for i in range(PlayerManager.potions.size()):
				if PlayerManager.potions[i].effect_type == PotionData.EffectType.DEATH_PREVENT:
					var pct = PlayerManager.potions[i].effect_value
					var potion_id = PlayerManager.potions[i].id
					hp = maxi(1, roundi(max_hp * pct / 100.0))
					PlayerManager.potions.remove_at(i)
					BattleManager._consumed_potion_ids.append(potion_id)
					actual = 0
					PlayerManager.stats_changed.emit()
					break
	# 迦南院徽：首次受伤抽2牌
	if actual > 0 and not first_hp_lost_triggered:
		for relic in PlayerManager.relics:
			if relic.effect_type == RelicData.EffectType.FIRST_HP_LOST_DRAW:
				first_hp_lost_triggered = true
				draw_cards(relic.effect_value)
				break
	return actual


## 初始化卡组
func init_deck(deck: Array[CardData]) -> void:
	draw_pile.clear()
	for card in deck:
		draw_pile.append(card.duplicate_card())
	_shuffle_draw_pile()
	# 固有牌移到牌库顶部，确保首回合抽到
	var innate_cards: Array[CardData] = []
	var remaining: Array[CardData] = []
	for card in draw_pile:
		if card.innate:
			innate_cards.append(card)
		else:
			remaining.append(card)
	if innate_cards.size() > 0:
		draw_pile.clear()
		for card in remaining:
			draw_pile.append(card)
		for card in innate_cards:
			draw_pile.append(card)
	_is_first_turn = true


## 洗牌（使用RNGManager的shuffle通道，确保可复现）
func _shuffle_draw_pile() -> void:
	RNGManager.shuffle_deck_in_place(draw_pile)
	# 紫云雕翎：洗牌时获得1能量
	for relic in PlayerManager.relics:
		if relic.effect_type == RelicData.EffectType.SHUFFLE_ENERGY:
			gain_energy(relic.effect_value)
			break


## 回合开始（返回 { "msg": String, "ejected_fire": int/-1 }）
func on_turn_start() -> Dictionary:
	# 星陨护心令：回合结束护盾保留（上限10）
	var _saved_block = block
	var _has_retain = false
	var _retain_cap = 0
	for relic in PlayerManager.relics:
		if relic.effect_type == RelicData.EffectType.HAND_RETAIN_BLOCK:
			_has_retain = true
			_retain_cap = relic.effect_value
			break
	# 冰封惩罚：frozen 在 on_turn_end 递减，此处值即为当前冰封层数
	super.on_turn_start()
	# 恢复保留的护盾
	if _has_retain and _saved_block > 0:
		block = mini(_saved_block, _retain_cap)
	# 状态递减移到 on_turn_end（对标STS2：行动后才递减，确保1回合debuff在行动时仍生效）
	evoked_this_turn = false
	_recalculate_ability_effects()
	var msg = ""
	var ejected_fire: int = -1
	next_card_double = false
	next_card_double_remaining = 0
	first_card_free_this_turn = false
	next_card_cost_modifier = 0
	evoke_block_this_turn = 0
	on_hit_burn_this_turn = 0
	last_card_block = 0
	cards_played_for_relic_count = 0
	consecutive_attacks_this_turn = 0
	skill_cards_this_turn = 0
	hand_cost_reduction = 0
	xuanzhongchi_first_attack_pending = false
	# first_turn_attack_bonus_used 不在此重置（古族金令：每场战斗仅触发一次）
	first_turn_free_cards_used = 0
	# 萧薰儿：重置回合状态
	detonation_count_this_turn = 0
	seal_resonance_used_this_turn = false
	# 美杜莎：重置回合状态
	stance_switch_this_turn = false
	venom_thorns_this_turn = 0
	queen_venom_thorns_this_turn = 0
	# 青莲座：回合结束未用能量最多保留N点到下回合
	var retained_energy := 0
	for relic in PlayerManager.relics:
		if relic.effect_type == RelicData.EffectType.ENERGY_RETAIN_MAX:
			retained_energy = mini(energy, relic.effect_value)
			break
	# 恢复斗气（基础 + 敌人回合获得的额外能量如药老附体）
	energy = energy_per_turn + bonus_energy + retained_energy
	bonus_energy = 0
	# 抽牌（应用冰封惩罚 + 凝火诀惩罚）— 使用之前保存的冰封惩罚值
	var draw_count = max(0, cards_per_turn - frozen - next_turn_draw_penalty)
	next_turn_draw_penalty = 0
	# 固有牌：首回合确保全部抽到
	if _is_first_turn:
		var innate_count = 0
		for card in draw_pile:
			if card.innate:
				innate_count += 1
		draw_count = max(draw_count, innate_count)
		# 首回合临时额外抽牌（事件效果）
		if _bonus_first_turn_draw > 0:
			draw_count += _bonus_first_turn_draw
		_is_first_turn = false
	else:
		# 非首回合：扣回临时额外抽牌对 cards_per_turn 的影响
		if _bonus_first_turn_draw > 0:
			cards_per_turn -= _bonus_first_turn_draw
			_bonus_first_turn_draw = 0
	# 斗气化铠：恢复凝聚能力
	can_channel_next_turn = true
	# 心火灼烧：回合开始时若在手牌中，受到3点伤害
	for card in hand:
		if card.id == "heart_fire_burn":
			hp = max(0, hp - 3)
			last_curse_log += "心火灼烧：失去 3 HP\n"
			break
	# 火灵护体：回合开始每异火+N护盾
	if ability_block_per_fire > 0:
		var shield = ability_block_per_fire * fire_slots.size()
		gain_block(shield)
		msg += "  火灵护体：获得 %d 护盾\n" % shield
	# 斗气凝聚：回合开始多抽N张
	if ability_extra_draw > 0:
		draw_count += ability_extra_draw
	# 星空体质：回合开始自动凝聚异火（可叠加，每张凝聚1朵）
	if ability_auto_channel_fire >= 0 and ability_auto_channel_count > 0:
		var fire_type = ability_auto_channel_fire as FireType
		for _i in range(ability_auto_channel_count):
			var result = channel_fire(fire_type)
			msg += "  星空体质：凝聚 %s\n" % _get_fire_name(fire_type)
			if result["ejected"] != null:
				ejected_fire = result["ejected"]
				msg += "  ★ 槽位已满，%s 被挤出！\n" % _get_fire_name(result["ejected"])
	# 萧薰儿：光之亲和 — 回合开始多抽N张
	if ability_xuner_extra_draw > 0:
		draw_count += ability_xuner_extra_draw
	# 守护者之证：回合结束能量为0时累积的额外抽牌
	if bonus_draw_next_turn > 0:
		draw_count += bonus_draw_next_turn
		bonus_draw_next_turn = 0
	draw_cards(draw_count)
	return { "msg": msg, "ejected_fire": ejected_fire }


## 抽牌
func draw_cards(count: int) -> Array[CardData]:
	var drawn: Array[CardData] = []
	last_curse_log = ""
	for i in range(count):
		if draw_pile.size() == 0:
			# 弃牌堆洗入牌库
			if discard_pile.size() > 0:
				for card in discard_pile:
					draw_pile.append(card)
				discard_pile.clear()
				_shuffle_draw_pile()
				deck_shuffled.emit()
			else:
				break  # 无牌可抽

		if draw_pile.size() > 0:
			var card = draw_pile.pop_back()
			hand.append(card)
			drawn.append(card)
			# 诅咒牌抽到时触发
			var curse_msg = _trigger_on_draw(card)
			if curse_msg != "":
				last_curse_log += curse_msg
	return drawn


## 打出手牌
func play_card(hand_index: int, _target: Combatant = null) -> bool:
	if hand_index < 0 or hand_index >= hand.size():
		return false

	var card = hand[hand_index]

	# 检查诅咒牌不能打出（灵魂创伤例外：可消耗诅咒）
	if card.card_type == CardData.CardType.CURSE:
		if card.id == "soul_trauma" and card.exhaust:
			pass  # 允许打出，走正常消耗流程
		else:
			return false

	# 计算实际费用（含临时修改 + 能力牌遗物减免）
	var actual_cost = max(0, card.cost + next_card_cost_modifier)
	if card.card_type == CardData.CardType.ABILITY:
		var ability_reduction = RelicManager.get_ability_cost_reduction(PlayerManager.relics)
		actual_cost = max(0, actual_cost - ability_reduction)

	# battle_manager已提前扣除能量时，跳过能量检查和扣除
	if _skip_energy_deduction:
		_skip_energy_deduction = false
	else:
		# 检查斗气
		if actual_cost > energy:
			return false
		energy -= actual_cost
	# 重置临时费用修改（仅影响下一张牌）
	next_card_cost_modifier = 0

	# 移出手牌
	hand.remove_at(hand_index)

	# 根据关键字决定去向（exhaust优先于ABILITY类型）
	if card.exhaust:
		exhaust_pile.append(card)
	elif card.card_type == CardData.CardType.ABILITY:
		in_play.append(card)
	else:
		discard_pile.append(card)

	return true


## 获得斗气（无上限，允许溢出——对标STS2设计）
func gain_energy(amount: int) -> void:
	energy += amount


## 凝聚异火
## 新异火插入最前端（index 0 = 最新，显示在最左侧）。
## 槽位已满时，挤出末尾（最旧）异火并激发。
## 返回 { "ejected": FireType|null, "ejected_index": int }
func channel_fire(fire_type: FireType) -> Dictionary:
	var result = { "ejected": null, "ejected_index": -1 }

	# 槽位已满：挤出末尾（最旧）异火
	if fire_slots.size() >= max_fire_slots:
		var last = fire_slots.size() - 1
		result["ejected"] = fire_slots[last]
		result["ejected_index"] = last
		fire_slots.remove_at(last)
		evoked_this_turn = true

	# 新异火插入最前端（最新）
	fire_slots.insert(0, fire_type)
	return result


## 主动激发最右端异火（最旧）
## 注意：front 指显示顺序的最右端（最旧异火），非数组 index 0
## 返回 { "type": FireType, "success": bool }
func evoke_front() -> Dictionary:
	if fire_slots.size() == 0:
		return { "type": -1, "success": false }

	var last = fire_slots.size() - 1
	var fire_type = fire_slots[last]
	fire_slots.remove_at(last)
	evoked_this_turn = true
	return { "type": fire_type, "success": true }


## 获取异火槽显示文本
func get_fire_slot_display() -> String:
	if fire_slots.size() == 0:
		return "异火槽: [空]"
	var names = []
	for ft in fire_slots:
		names.append(_get_fire_name(ft))
	return "异火槽: [%s]" % ", ".join(names)


## 获取异火名称
func _get_fire_name(fire_type: FireType) -> String:
	match fire_type:
		FireType.GREEN: return "青莲地心火"
		FireType.WHITE: return "陨落心炎"
		FireType.BLUE: return "骨灵冷火"
		FireType.PURPLE: return "三千焱炎火"
	return "未知"


## 获取异火视觉色调
func get_fire_color(fire_type: FireType) -> Color:
	match fire_type:
		FireType.GREEN: return Color(0.2, 0.8, 0.3)    # 翠绿
		FireType.WHITE: return Color(0.95, 0.95, 1.0)   # 纯白无色
		FireType.BLUE: return Color(0.7, 0.85, 0.95)    # 森白带蓝
		FireType.PURPLE: return Color(0.5, 0.1, 0.7)    # 紫黑星光
	return Color.WHITE


## 获取异火被动效果（回合结束时触发）
## 返回描述文本
## 回合结束
func on_turn_end() -> void:
	super.on_turn_end()
	# 状态递减在行动后执行（对标STS2：虚弱/易伤等在行动时仍生效，行动后才消失）
	decrement_statuses()
	# 石化：玩家回合结束递减（敌人侧在execute_intent递减）
	if petrified > 0:
		petrified -= 1

	# 清除临时增益
	temp_strength = 0
	temp_dexterity = 0
	ice_armor = false

	# 处理手牌中的回合结束伤害（风缠等）
	for card in hand:
		if card.on_turn_end_damage > 0:
			var dmg = card.on_turn_end_damage
			take_damage(dmg, true)  # 真实伤害，无视护盾
			if not is_alive():
				return  # 玩家已死亡，停止手牌处理

	# 处理手牌
	var cards_to_discard: Array[CardData] = []
	var cards_to_retain: Array[CardData] = []

	# 炎帝印记：回合结束不弃牌（全局保留）
	var no_discard := false
	for relic in PlayerManager.relics:
		if relic.effect_type == RelicData.EffectType.NO_DISCARD_AT_TURN_END \
		   or relic.effect_type_2 == RelicData.EffectType.NO_DISCARD_AT_TURN_END:
			no_discard = true
			break

	# 蛇皇步：女王姿态保留手牌
	var queen_retain_count := 0
	if current_stance == 1:
		for ability in in_play:
			if ability.queen_retain_cards > 0:
				queen_retain_count += ability.queen_retain_cards
		queen_retain_count = mini(queen_retain_count, hand.size())

	var queen_retained := 0
	for card in hand:
		if card.ethereal:
			# 虚无牌：回合结束时进入消耗堆
			exhaust_pile.append(card)
		elif card.retain or no_discard:
			# 保留牌或全局不弃牌：留在手牌
			cards_to_retain.append(card)
		elif queen_retained < queen_retain_count:
			# 女王姿态保留
			cards_to_retain.append(card)
			queen_retained += 1
		else:
			cards_to_discard.append(card)

	# 清空手牌，放回保留牌
	hand.clear()
	for card in cards_to_retain:
		hand.append(card)

	# 弃掉其余
	for card in cards_to_discard:
		discard_pile.append(card)

	# 冰封已在 on_turn_start 中递减


## 清空异火槽（佛怒火莲等卡牌使用）
func clear_fire_slots() -> Array[FireType]:
	var cleared = fire_slots.duplicate()
	fire_slots.clear()
	return cleared


## 显示玩家完整状态
func get_status_text() -> String:
	var text = super.get_status_text()
	text += " | 斗气:%d/%d" % [energy, max_energy]
	if fire_slots.size() > 0:
		text += " | " + get_fire_slot_display()
	return text


## 显示手牌
func get_hand_text() -> String:
	if hand.size() == 0:
		return "  (手牌为空)"

	var text = ""
	for i in range(hand.size()):
		var card = hand[i]
		var playable = card.cost <= energy and card.card_type != CardData.CardType.CURSE
		var mark = ">" if playable else "x"
		var upgrade_mark = "+" if card.upgraded else ""
		text += "  [%d] %s %s%s (%d费) %s" % [i + 1, mark, card.card_name, upgrade_mark, card.cost, card.description]
		# 关键字标签（黄色）
		var tags: Array[String] = []
		if card.exhaust:
			tags.append("[color=#FFD700]消耗[/color]")
		if card.ethereal:
			tags.append("[color=#FFD700]虚无[/color]")
		if card.innate:
			tags.append("[color=#FFD700]固有[/color]")
		if card.retain:
			tags.append("[color=#FFD700]保留[/color]")
		if tags.size() > 0:
			text += " " + " ".join(tags)
		text += "\n"
	return text


## 显示牌堆信息
func get_pile_text() -> String:
	var text = "牌库:%d | 弃牌堆:%d" % [draw_pile.size(), discard_pile.size()]
	if exhaust_pile.size() > 0:
		text += " | 消耗堆:%d" % exhaust_pile.size()
	return text


## 获取牌堆中所有牌（用于UI显示）
func get_draw_pile_cards() -> Array[CardData]:
	return draw_pile


func get_discard_pile_cards() -> Array[CardData]:
	return discard_pile


func get_exhaust_pile_cards() -> Array[CardData]:
	return exhaust_pile
