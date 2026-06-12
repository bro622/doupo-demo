## 战斗单位基类
## 玩家和敌人的共同基类
class_name Combatant

## 基础属性
var char_name: String
var hp: int
var max_hp: int
var block: int = 0
var strength: int = 0
var dexterity: int = 0

## 临时增益(回合结束清除)
var temp_strength: int = 0
var temp_dexterity: int = 0
var ice_armor: bool = false                # 冰甲：本回合单次伤害上限1
var death_prevent_hp_percent: int = 0      # 不死保护：致命伤害时恢复至N%HP
var shield_never_decay: bool = false       # 护盾永不衰减（星陨护心令）
var single_damage_cap: int = 0             # 单次HP伤害上限（冰皇面具，0=无上限）
var has_first_hp_block: bool = false       # 拥有飞行斗技残卷
var first_hp_damage_blocked: bool = false  # 本场首次HP伤害已抵消
var frozen_decrement_at_turn_end: bool = false  # 冰封在回合结束递减（玩家用，确保状态栏可见）

## 状态效果 (层数/剩余回合数)
var burn: int = 0          # 燃烧：回合开始受X点真实伤害，然后-1
var venom: int = 0         # 蛇毒：与燃烧完全相同机制，仅名称不同
var weak: int = 0          # 虚弱：造成伤害-25%
var vulnerable: int = 0    # 易伤：受到伤害+50%
var frail: int = 0         # 脆弱：从卡牌获得的护盾值-25%
var frozen: int = 0        # 冰封：每层下回合少抽1牌，最多2层，持续1回合后消失
var armor_break: int = 0   # 破甲：护盾获取量减少X%
var gold_seal: int = 0     # 金印（萧薰儿专属）：叠至5层时引爆，10真伤+返1能量
var petrified: int = 0     # 石化：眩晕1回合，受伤+20%


func _init(p_name: String, p_hp: int) -> void:
	char_name = p_name
	hp = p_hp
	max_hp = p_hp


## 是否存活
func is_alive() -> bool:
	return hp > 0


## 恢复生命值
func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)


## 受到伤害
## is_true_damage: 真实伤害无视护盾
func take_damage(amount: int, is_true_damage: bool = false) -> int:
	# 易伤加成 +50%
	if vulnerable > 0:
		amount = roundi(amount * 1.5)

	# 石化加成 +20%
	if petrified > 0:
		amount = roundi(amount * 1.2)

	# 冰甲：单次伤害上限1
	if ice_armor:
		amount = min(amount, 1)

	# 冰皇面具：单次HP伤害上限
	if single_damage_cap > 0:
		amount = min(amount, single_damage_cap)

	var actual_damage = amount

	# 真实伤害跳过护盾
	if not is_true_damage and block > 0:
		if block >= actual_damage:
			block -= actual_damage
			return 0
		else:
			actual_damage -= block
			block = 0

	# 飞行斗技残卷：本场首次HP伤害归零
	if has_first_hp_block and not first_hp_damage_blocked and actual_damage > 0 and not is_true_damage:
		first_hp_damage_blocked = true
		return 0

	# 不死保护：致命伤害时恢复至N%HP
	if death_prevent_hp_percent > 0 and hp - actual_damage <= 0:
		hp = maxi(1, roundi(max_hp * death_prevent_hp_percent / 100.0))
		death_prevent_hp_percent = 0
		return 0  # 伤害被阻止，无实际HP损失

	# 扣血
	hp = max(0, hp - actual_damage)
	return actual_damage


## 获得护盾
## armor_break_value: 来自攻击者的破甲层数（减少护盾获取%）
## raw: true时跳过脆弱/敏捷修正（异火激发等固定效果）
func gain_block(amount: int, armor_break_value: int = 0, raw: bool = false) -> void:
	if not raw:
		# 敏捷加成（先加后乘，对标STS：(base + dex) * multipliers）
		amount += dexterity + temp_dexterity
		# 脆弱 -25%
		if frail > 0:
			amount = roundi(amount * 0.75)
		# 破甲减少护盾获取
		if armor_break_value > 0:
			amount = roundi(amount * (100 - armor_break_value) / 100.0)
	block += max(0, amount)


## 计算攻击伤害(含力量加成和虚弱)
func calc_attack_damage(base_damage: int) -> int:
	var dmg = base_damage + strength + temp_strength
	# 虚弱 -25%
	if weak > 0:
		dmg = roundi(dmg * 0.75)
	return max(0, dmg)


## 回合开始处理状态效果
func on_turn_start():
	# 护盾每回合清零（星陨护心令：护盾永不衰减）
	if not shield_never_decay:
		block = 0

	# 冰封递减（敌人在回合开始递减；玩家延迟到回合结束，确保状态栏全程可见）
	if frozen > 0 and not frozen_decrement_at_turn_end:
		frozen -= 1

	# 燃烧伤害（真实伤害，无视护盾）
	if burn > 0:
		hp = max(0, hp - burn)
		burn -= 1
		if burn <= 0:
			burn = 0

	# 已死亡则跳过后续DoT
	if hp <= 0:
		return

	# 蛇毒伤害（与燃烧同机制）
	if venom > 0:
		hp = max(0, hp - venom)
		venom -= 1
		if venom <= 0:
			venom = 0


## 状态持续时间递减（敌人行动后调用，确保虚弱/易伤在行动时仍生效）
func decrement_statuses() -> void:
	if weak > 0:
		weak -= 1
	if vulnerable > 0:
		vulnerable -= 1
	if frail > 0:
		frail -= 1
	if armor_break > 0:
		armor_break -= 1
	# 注意：石化在 execute_intent 中已递减，不在这里递减


## 回合结束处理
func on_turn_end() -> void:
	# 冰封递减（玩家在回合结束递减，确保整个回合状态栏可见；敌人已在 on_turn_start 递减）
	if frozen > 0 and frozen_decrement_at_turn_end:
		frozen -= 1


## 获取冰封对抽牌的惩罚
func get_frozen_draw_penalty() -> int:
	return frozen


## 获得状态效果
func apply_burn(stacks: int) -> void:
	burn += stacks


func apply_venom(stacks: int) -> void:
	venom += stacks


func apply_weak(rounds: int) -> void:
	weak += rounds


func apply_vulnerable(rounds: int) -> void:
	vulnerable += rounds


func apply_frail(rounds: int) -> void:
	frail += rounds


func apply_frozen(stacks: int) -> void:
	frozen = min(2, frozen + stacks)


func apply_armor_break(stacks: int) -> void:
	armor_break += stacks


func apply_gold_seal(stacks: int) -> void:
	gold_seal += stacks


func apply_petrified(rounds: int) -> void:
	petrified += rounds


## 清除所有负面状态
func clear_all_debuffs() -> void:
	burn = 0
	venom = 0
	weak = 0
	vulnerable = 0
	frail = 0
	frozen = 0
	armor_break = 0
	petrified = 0


## 显示状态信息
func get_status_text() -> String:
	var text = "%s: HP %d/%d" % [char_name, hp, max_hp]
	if block > 0:
		text += " | 护盾:%d" % block
	if strength > 0:
		text += " | 力量:%d" % strength
	if temp_strength > 0:
		text += " | 临时力量:%d" % temp_strength
	if dexterity > 0:
		text += " | 敏捷:%d" % dexterity
	if temp_dexterity > 0:
		text += " | 临时敏捷:%d" % temp_dexterity

	var effects = []
	if burn > 0:
		effects.append("燃烧:%d" % burn)
	if venom > 0:
		effects.append("蛇毒:%d" % venom)
	if weak > 0:
		effects.append("虚弱:%d" % weak)
	if vulnerable > 0:
		effects.append("易伤:%d" % vulnerable)
	if frail > 0:
		effects.append("脆弱:%d" % frail)
	if frozen > 0:
		effects.append("冰封:%d" % frozen)
	if armor_break > 0:
		effects.append("破甲:%d" % armor_break)
	if gold_seal > 0:
		effects.append("金印:%d" % gold_seal)

	if petrified > 0:
		effects.append("石化:%d" % petrified)

	if effects.size() > 0:
		text += " | 状态:" + ", ".join(effects)

	return text
