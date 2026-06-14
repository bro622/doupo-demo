## 遗物数据类
## 定义遗物的类型、稀有度和被动效果
class_name RelicData

## 稀有度
enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

## 效果类型
enum EffectType {
	BATTLE_START_SHIELD,     # 战斗开始获得N点护盾
	TURN_START_STRENGTH,     # 回合开始获得N点力量
	TURN_START_DRAW,         # 回合开始额外抽N张牌
	TURN_START_ENERGY,       # 回合开始额外获得N点能量
	TURN_START_HEAL,         # 回合开始恢复N点HP
	VICTORY_HEAL,            # 战斗胜利恢复N点HP
	VICTORY_GOLD,            # 战斗胜利获得N金币
	VICTORY_ENERGY,          # 战斗胜利恢复N点斗气(预留)
	DAMAGE_BONUS_FLAT,       # 所有攻击+N点伤害
	DAMAGE_BONUS_PERCENT,    # 所有攻击伤害+N%
	BLOCK_BONUS_FLAT,        # 所有格挡+N点
	MAX_HP_FLAT,             # 获得时最大HP+N(一次性)
	CARD_PLAY_HEAL,          # 每打出一张牌恢复N点HP
	TURN_START_BLOCK_PERCENT,# 回合开始获得等同于已损失HP*N%的护盾
	VICTORY_GOLD_EVERY_N,    # 每N场胜利获得金币(effect_value=N*1000+金币数)
	VICTORY_GOLD_ELITE,      # 击败精英额外获得N金币
	SHOP_PRICE_DISCOUNT,     # 商店价格降低N%
	TURN_START_SHIELD,       # 回合开始获得N点护盾
	BATTLE_START_DRAW,         # 战斗开始时额外抽N张牌
	TURN_3_CARDS_PLAYED_SHIELD, # 一回合内打出3+张牌时，获得N点护盾
	FIRST_TURN_ENERGY,       # 第一回合获得N点临时能量
	VICTORY_GOLD_PERCENT,    # 战斗胜利金币增加N%
	BURN_STACK_BONUS,        # 给予燃烧时层数+N
	EVENT_HP_LOSS_GOLD,      # 事件中失去HP时获得N金币
	POTION_USE_DRAW,         # 使用丹药时抽N张牌
	NEXT_CARD_DOUBLE,        # 下一张牌打出两次
	REST_UPGRADE_POTION,     # 休息点升级卡牌时额外获得N瓶丹药
	BATTLE_START_BURN_ALL,   # 战斗开始时给予所有敌人N层燃烧
	VICTORY_UPGRADE_ELITE,   # 击败精英时随机升级牌库N张牌
	ABILITY_COST_REDUCE,     # 能力牌费用减少N点（最低0）
	TURN_START_CLEANSE_AOE,  # 回合开始清除debuff并对全体敌人造成N伤害
	WEAK_ALSO_VULNERABLE,    # 给予虚弱时同时给予N层易伤
	CONSECUTIVE_ATTACK_STRENGTH, # 连续打出2张攻击牌获得N力量（回合结束消失）
	LOW_HP_SHIELD_ONCE,      # 首次HP<50%时下次伤害归零
	BATTLE_START_VENOM_ALL,  # 战斗开始给予所有敌人N层蛇毒
	NO_VENOM_ENEMY_SHIELD,   # 回合结束时若无敌人有蛇毒，获得N护盾
	REST_HEAL_BONUS_PERCENT, # 休息回复效果提升N%
	FIRST_TURN_FIRST_ATTACK_BONUS, # 第一回合第一张伤害卡伤害+N
	FIRE_EVOKE_BONUS_DAMAGE, # 激发异火时伤害+N
	EXHAUST_CARD_AOE_DAMAGE, # 消耗卡牌时对全体敌人造成N伤害
	_DEPRECATED_EVENT_HEAL,   # 已废弃，保留占位避免枚举偏移
	BATTLE_START_REMOVE_CURSE, # 战斗开始移除手牌中N张诅咒牌
	REST_EXTRA_HEAL_FLAT,    # 休息点额外回复N HP
	FIRST_TURN_CARDS_COST_ZERO, # 第一回合前N张牌费用为0
	HAND_RETAIN_BLOCK,       # 护盾保留/缺血量加盾（历史命名，实际含义见各遗物注释）
	FIRE_SLOT_CAPACITY_BONUS,# 异火槽上限+N
	FIRE_CLEAR_RETURN_ENERGY,# 清空异火槽时返还N能量
	BURN_DAMAGE_APPLY_DEBUFF,# 燃烧造成伤害时施加N层随机debuff
	DEATH_PREVENT_HEAL,      # 致死伤害时防止死亡并回复N HP（消耗）
	ATTACK_HEAL_IN_STANCE,   # 某姿态下打出攻击牌回复N HP
	GOLD_MARK_THRESHOLD_REDUCE, # 金印引爆所需层数减少N
	COMBO_KEYWORD_SHIELD,    # 打出连击关键字卡牌获得N护盾
	GOLD_MARK_ON_FIRST_ATTACK, # 每场第一张攻击牌施加N层金印
	STANCE_SWITCH_CARD_DRAW, # 首次切换姿态时抽N张牌
	STANCE_SWITCH_ENERGY,    # 首次切换姿态时获得N能量
	FIRST_TURN_AUTO_CHANNEL, # 第一回合开始时若异火槽空则凝聚一朵
	CHANNEL_FULL_HEAL,       # 异火槽满载时回复N HP
	FIRST_ATTACK_ENERGY_COST,# 每回合第一张攻击牌额外消耗N能量
	BATTLE_START_CHANNEL_BLUE, # 战斗开始凝聚1朵骨灵冷火
	LOW_HP_ENERGY_DRAW_CLEANSE, # HP<50%时获得能量+抽牌+清debuff（每场限1次）
	POTION_OVERFLOW_REFINE_HP, # 丹药槽满时获得丹药改为永久+N最大HP
	BATTLE_START_POTION,       # 战斗开始时获得随机丹药
	# === 新增遗物效果类型 ===
	EVERY_NTH_ATTACK_BONUS,    # 每第N次攻击伤害翻倍（黑铁长枪）
	NTH_CARD_SHIELD_PER_TURN,  # 每回合第N张牌打出时获护盾（回气散配方）
	FIRST_HP_DAMAGE_BLOCK,     # 每场战斗抵消第一次HP伤害（飞行斗技残卷）
	NTH_CARD_ENERGY_AND_DRAW,  # 每打出N张牌获能量+抽牌（九彩原石）
	TURN_START_HAND_COST_REDUCE, # 回合开始手牌费用-N（天雁九行翼）
	VICTORY_EXTRA_RELIC_POTION, # 战斗胜利额外获遗物+丹药（黑魔鼎原片）
	NO_DISCARD_AT_TURN_END,    # 回合结束不弃牌（炎帝印记）
	FIRST_ATTACK_DOUBLE,       # 每场第一张攻击牌打出两次（魂殿黑袍）
	POTION_EFFECT_DOUBLE,      # 丹药效果翻倍（丹塔令牌）
	EXHAUST_CARD_SHIELD,       # 消耗卡牌时获护盾（远古魔核-新）
	RETAINED_CARD_HEAL,        # 保留牌到下回合时回复HP（星陨阁信物）
	BATTLE_VICTORY_GOLD_BONUS, # 战斗金币+N%（黑印城令牌）
	UNUPGRADED_AUTO_UPGRADE,   # 打出未升级卡牌自动升级（魂殿拘灵锁）
	ENERGY_ZERO_EXTRA_DRAW,    # 回合结束能量为0时下回合多抽牌（守护者之证-新）
	SHIELD_NEVER_DECAY,        # 护盾永不衰减（星陨护心令-新）
	BATTLE_START_VULNERABLE_ALL, # 战斗开始给予所有敌人N层易伤（火灵石）
	BATTLE_START_WEAK_ALL,       # 战斗开始给予所有敌人N层虚弱（冰寒晶）
	# === Batch 1-4 修复新增 ===
	ATTACK_TRUE_DAMAGE,          # 攻击牌无视护盾（玄重尺）
	ON_KILL_ENERGY,              # 击杀返还能量（玄重尺）
	TURN_END_BURN_ALL,           # 回合结束施加燃烧（净莲妖火残焰）
	BURN_OR_VENOM_DAMAGE_BONUS,  # 对有燃烧/蛇毒的敌人+伤（焚炎谷令）
	VENOM_STACK_BONUS,           # 施加蛇毒时层数+1（化骨珠）
	SKILL_3_PLAYED_DEXTERITY,    # 打3张技能牌获敏捷（紫晶翼）
	SHIELD_ZERO_BONUS,           # 护盾为0时获护盾（血莲丹）
	SINGLE_DAMAGE_CAP,           # 单次伤害上限（冰皇面具）
	FIRST_HP_LOST_DRAW,          # 首次受伤抽牌（迦南院徽）
	SHUFFLE_ENERGY,              # 洗牌时获能量（紫云雕翎）
	ENERGY_RETAIN_MAX,           # 回合结束保留能量（青莲座）
	NTH_CARD_ENERGY,             # 每打出N张牌获1能量（远古魔核-重设计）
	VICTORY_POTION_ELITE,        # 击败精英额外掉丹药（万兽鼎）
	FIRST_CARD_DOUBLE_PER_TURN,  # 每回合第一张牌打出两次（菩提古树之心）
	# === 第二轮审查新增 ===
	TURN_END_LOST_HP_AOE,        # 回合结束对全体造成已损失HP真伤（厄难毒体原液）
	FIRST_TURN_DRAW,             # 仅首回合抽牌（三年之约）
}

var id: int
var relic_name: String
var rarity: Rarity
var description: String
var icon_color: Color
var effect_type: EffectType
var effect_value: int
var bonus_max_hp: int = 0  # 获得时额外增加的最大HP(一次性)
var effect_type_2: EffectType = EffectType.BATTLE_START_SHIELD  # 第二效果类型（无效默认值）
var effect_value_2: int = 0  # 第二效果数值（0表示无第二效果）
var effect_type_3: EffectType = EffectType.BATTLE_START_SHIELD  # 第三效果类型（无效默认值）
var effect_value_3: int = 0  # 第三效果数值（0表示无第三效果）
var exclusive_to: String = ""  # 角色专属：空=通用, "xiaoyan"/"xuner"/"cailin"
var is_turn_start_choice: bool = false  # 回合开始时需要选择效果（如炎帝遗物）
var image_path: String = ""  # 遗物图片路径（如 "res://assets/ui/relics/骨炎戒.png"）


func _init(p_id: int, p_name: String, p_rarity: Rarity, p_desc: String,
		p_icon_color: Color, p_effect_type: EffectType, p_effect_value: int,
		p_bonus_max_hp: int = 0) -> void:
	id = p_id
	relic_name = p_name
	rarity = p_rarity
	description = p_desc
	icon_color = p_icon_color
	effect_type = p_effect_type
	effect_value = p_effect_value
	bonus_max_hp = p_bonus_max_hp


## 设置第二效果
func set_secondary_effect(p_type: EffectType, p_value: int) -> void:
	effect_type_2 = p_type
	effect_value_2 = p_value


## 设置第三效果
func set_third_effect(p_type: EffectType, p_value: int) -> void:
	effect_type_3 = p_type
	effect_value_3 = p_value


## 设置角色专属
func set_exclusive_to(char_id: String) -> void:
	exclusive_to = char_id


func get_rarity_name() -> String:
	match rarity:
		Rarity.COMMON: return "普通"
		Rarity.RARE: return "稀有"
		Rarity.EPIC: return "史诗"
		Rarity.LEGENDARY: return "传说"
	return "未知"


func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMMON: return Color(0.8, 0.8, 0.8)
		Rarity.RARE: return Color(0.3, 0.5, 1.0)
		Rarity.EPIC: return Color(0.6, 0.2, 0.8)
		Rarity.LEGENDARY: return Color(1.0, 0.85, 0.2)
	return Color.WHITE
