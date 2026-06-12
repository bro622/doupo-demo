## 卡牌数据定义
## 定义卡牌类型、属性和效果
class_name CardData

## 卡牌类型
enum CardType { ATTACK, SKILL, ABILITY, CURSE, STATUS }

## 卡牌品质
enum CardRarity { COMMON, RARE, EPIC, LEGENDARY }

## 基础数据
var id: String
var card_name: String
var card_type: CardType
var rarity: CardRarity
var cost: int
var description: String
var detail: String = ""  # 完整效果描述（详情面板用），为空时回退到 description
var upgraded_detail: String = ""  # 升级后的完整描述
var character_id: String = ""  # 角色专属：空=通用卡, "xiaoyan"/"xuner"/"cailin"

## 效果数据
var damage: int = 0
var block: int = 0
var hit_count: int = 1
var draw_cards: int = 0
var heal: int = 0
var apply_burning: int = 0   # 燃烧层数（叠层DOT，回合开始受X伤后-1，无视护盾）
var apply_weak: int = 0
var apply_vulnerable: int = 0
var apply_frail: int = 0     # 脆弱（-25%护盾获取）
var apply_frozen: int = 0    # 冰封（每层下回合少抽1牌，最多2层）
var apply_venom: int = 0     # 蛇毒（与燃烧同机制，仅名称不同）
var apply_armor_break: int = 0  # 破甲（减少目标护盾获取%）
var gain_strength: int = 0
var gain_dexterity: int = 0
var gain_energy: int = 0
var hp_cost: int = 0           # 打出时失去X点当前HP（不会致死）
var aoe: bool = false

## 关键字
var exhaust: bool = false      # 消耗：打出后从牌库移除
var ethereal: bool = false     # 虚无：回合结束在手牌则消耗
var innate: bool = false       # 固有：首回合必定在手牌
var retain: bool = false       # 保留：回合结束不弃牌
var true_damage: bool = false  # 真实伤害：无视护盾

## 萧炎专属：异火系统
var channel_type: String = ""  # 凝聚异火类型："green"/"white"/"blue"/"purple"
var evoke: bool = false        # 是否触发激发
var evoke_count: int = 0       # 激发次数（0=不激发）

## 卡面图片路径（空=无卡面，使用默认占位）
var image_path: String = ""

## 标签系统（用于卡牌间联动筛选）
var tags: Array[String] = []   # 如 ["异火", "燃烧"]

## 能力牌on-play触发（打出带指定标签的牌时触发）
var on_play_tag: Array[String] = []  # 触发标签（如 ["异火", "燃烧"]，任一匹配即触发）
var on_play_draw: int = 0            # 触发时抽牌数
var on_play_block: int = 0           # 触发时获得护盾
var upgraded_on_play_block: int = -1 # 升级后触发护盾（-1=不升级）

## 进阶效果
var next_card_cost_reduction: int = 0   # 紫云翼：下一张牌耗能-N
var discard_count: int = 0              # 心炎流转：丢弃N张牌
var next_turn_draw_penalty: int = 0     # 凝火诀：下回合少抽N张牌
var can_channel_next_turn: bool = true  # 斗气化铠：false=下回合无法凝聚
var trigger_block_on_evoke: int = 0     # 药鼎守护：本回合每次激发+N护盾
var trigger_burn_on_hit: int = 0        # 焰分噬浪尺·守：受击时给予敌人N层燃烧
var remove_front_fire: bool = false     # 六合游身/异火置换：移除最前端异火
var select_channel: bool = false        # 异火置换：移除后选择一朵凝聚
var discard_non_fire: bool = false      # 焚诀运转：丢弃没有异火/燃烧标签的牌
var scry_count: int = 0                 # （废弃，灵魂感知已改为 discard_count + draw_cards）
var choose_discard: bool = false        # 灵魂感知：玩家选择弃置卡牌（区别于心炎流转的随机弃置）
var choose_exhaust: bool = false       # 药鼎淬炼：玩家选择消耗卡牌
var exhaust_count: int = 0             # 药鼎淬炼：消耗N张牌

## 数据驱动效果（替代 _resolve_card_effect 中的硬编码ID检查）
var bonus_damage_if_cards_played_gt: int = 0  # 八极崩：打出过>N张牌时+X伤
var bonus_damage_at_threshold: int = 0        # 八极崩：满足条件时的加成值
var bonus_damage_per_card_played: int = 0     # 叠浪掌：每打出过1张牌+X伤
var bonus_damage_per_fire_slot: int = 0       # 五轮离火法/佛怒火莲：每朵异火+X伤
var clear_fire_slots_on_play: bool = false    # 佛怒火莲：打出后清空异火槽
var energy_refund_if_fire_type: String = ""   # 狂狮罡气：拥有指定异火时返还能量
var energy_refund_amount: int = 0             # 狂狮罡气：返还能量值
var evoke_all_fires: bool = false             # 焰分噬浪尺·烈/三色火莲：激发所有异火
var permanent_max_hp_gain: int = 0            # 炼制筑基丹：永久增加最大HP
var clear_debuffs_on_play: bool = false       # 净莲妖火·净化：移除所有负面状态
var shield_per_debuff_cleared: int = 0        # 净莲妖火·净化：每移除1个状态+N护盾
var energy_per_fire_removed: int = 0          # 提炼本源：每移除1朵异火+N能量
var draw_per_fire_removed: int = 0            # 提炼本源：每移除1朵异火抽N张牌
var reroll_front_fire: bool = false           # 六合游身：移除最前端异火至末尾
var channel_type_on_fire_remove: String = ""  # 异火置换：移除异火后凝聚指定类型
var damage_mult_if_vulnerable: int = 0        # 玄重尺斩：目标易伤时伤害×N
var apply_burning_equals_damage: bool = false  # 异火亘古尺：燃烧层数等于实际伤害值
var burn_no_decay: bool = false                 # 怒火中烧：燃烧不随回合递减
var burn_damage_mult: float = 1.0               # 怒火中烧：燃烧伤害倍率
var upgraded_burn_damage_mult: float = -1.0     # 怒火中烧：升级后燃烧伤害倍率（-1=不升级）

## 萧薰儿专属：金印系统
var apply_gold_seal: int = 0                    # 施加金印层数
var gold_seal_detonate: bool = false            # 万印归宗：立刻引爆所有金印
var gold_seal_detonate_damage_per_stack: int = 0 # 万印归宗：每层造成X伤害
var combo_threshold: int = 0                    # 连击阈值（打出>=N张牌后触发额外效果）
var combo_bonus_damage: int = 0                 # 连击触发时额外伤害
var combo_bonus_gold_seal: int = 0              # 连击触发时额外金印
var combo_bonus_block: int = 0                  # 连击触发时额外护盾
var combo_bonus_draw: int = 0                   # 连击触发时额外抽牌
var combo_bonus_strength: int = 0               # 连击触发时额外力量
var combo_bonus_dexterity: int = 0              # 连击触发时额外敏捷
var bonus_damage_per_gold_seal: int = 0         # 光之箭/穿刺之光：每层金印+X伤害（上限见max_bonus）
var max_bonus_damage: int = 0                   # 光之箭：额外伤害上限
var return_to_hand_on_detonate: bool = false    # 帝印决：触发引爆时移回手牌
var return_cost_increase: int = 0               # 帝印决：回手后本回合耗能+N
var next_card_double: bool = false              # 千年传承：下一张牌打出两次
var next_n_cards_double: int = 0                # 千年传承（升级）：下N张牌打出两次
var petrify: bool = false                       # 古族禁术·封印：石化（眩晕1回合+受伤+20%）
var gold_seal_on_all_enemies: int = 0           # 光之审判/帝炎刻印：给所有敌人N层金印
var cost_reduction_per_detonate: int = 0        # 古帝碎涅指：每次引爆减少X费用

## 美杜莎专属：姿态系统
var enter_stance: String = ""                   # 进入姿态："queen"/"python"/"none"
var leave_stance: bool = false                  # 离开当前姿态（回到无姿态）
var venom_apply: int = 0                        # 施加蛇毒层数
var venom_apply_all: int = 0                    # 给予所有敌人N层蛇毒
var devour: bool = false                        # 吞噬关键字
var devour_max_hp_bonus: int = 0                # 吞噬击杀永久增加最大HP
var consume_venom: bool = false                 # 消耗目标所有蛇毒
var damage_per_consume_venom: int = 0           # 消耗每层蛇毒造成X伤害
var double_venom: bool = false                  # 毒素催化：蛇毒翻倍
var bonus_damage_per_venom: int = 0             # 毒血爆发：每层蛇毒+X伤害
var bonus_damage_if_venom: int = 0              # 暗影爪击：目标有蛇毒时+X伤害
var bonus_damage_if_venom_5: int = 0            # 蟒蛇绞杀：目标蛇毒>=5时+X伤害
var venom_threshold_double: int = 0             # 七彩吞天：蛇毒>=N时双倍伤害
var python_cost_reduction: int = 0              # 致命绞杀：吞天蟒姿态下耗能-N
var bonus_damage_if_vulnerable: int = 0         # 古族剑诀：目标易伤时+X伤害
var queen_bonus_venom: int = 0                  # 蛇鳞飞射：女王姿态每次额外+N蛇毒
var heal_per_venom: int = 0                     # 暗影吞噬：回复目标蛇毒层数HP
var halve_block: bool = false                   # 蟒毒腐蚀：先将目标护盾减半
var random_stance_on_hit: bool = false          # 美杜莎之怒：打出时随机进入一种姿态
var venom_thorns: int = 0                       # 蟒毒护甲：本回合受击给攻击者N层蛇毒
var queen_retain_cards: int = 0                 # 蛇皇步：女王姿态保留N张手牌
var python_block_max_venom: bool = false        # 蛇魂爆发：吞天蟒姿态获得最高蛇毒护盾
var queen_venom_thorns: int = 0                 # 美杜莎之盾：女王姿态受击给攻击者N层蛇毒
var apply_weak_all: int = 0                     # 美杜莎之凝望：给所有敌人N层虚弱
var apply_armor_break_all: int = 0              # 美杜莎之凝望：给所有敌人N层破甲
var queen_petrify: bool = false                 # 美杜莎之凝望：女王姿态石化
var next_damage_zero: bool = false              # 九彩庇护：下一次伤害归零
var consume_all_venom_heal: int = 0             # 蛇魂轮回：消耗蛇毒每层恢复N HP
var consume_all_venom_block: int = 0            # 蛇魂轮回：消耗蛇毒每层获得N护盾
var cleanse_count: int = 0                      # 蜕皮：移除N个负面状态
var combo_bonus_venom: int = 0                  # 暗影突袭：连击触发时额外蛇毒

## 升级系统（每张卡独立升级数据）
var upgraded: bool = false
var upgraded_cost: int = -1
var upgraded_damage: int = -1
var upgraded_block: int = -1
var upgraded_hit_count: int = -1
var upgraded_draw_cards: int = -1
var upgraded_heal: int = -1
var upgraded_apply_burning: int = -1
var upgraded_apply_weak: int = -1
var upgraded_apply_vulnerable: int = -1
var upgraded_apply_frail: int = -1
var upgraded_apply_frozen: int = -1
var upgraded_apply_venom: int = -1
var upgraded_apply_armor_break: int = -1
var upgraded_gain_strength: int = -1
var upgraded_gain_dexterity: int = -1
var upgraded_gain_energy: int = -1
var upgraded_hp_cost: int = -1
var upgraded_next_card_cost_reduction: int = -1
var upgraded_discard_count: int = -1
var upgraded_trigger_block_on_evoke: int = -1
var upgraded_trigger_burn_on_hit: int = -1
var upgraded_scry_count: int = -1
var upgraded_bonus_damage_at_threshold: int = -1
var upgraded_bonus_damage_per_card_played: int = -1
var upgraded_bonus_damage_per_fire_slot: int = -1
var upgraded_permanent_max_hp_gain: int = -1
var upgraded_shield_per_debuff_cleared: int = -1
var upgraded_energy_per_fire_removed: int = -1
var upgraded_draw_per_fire_removed: int = -1
var upgraded_energy_refund_amount: int = -1
var upgraded_evoke_count: int = -1
var upgraded_innate: bool = false
var upgraded_apply_gold_seal: int = -1
var upgraded_combo_bonus_damage: int = -1
var upgraded_combo_bonus_gold_seal: int = -1
var upgraded_bonus_damage_per_gold_seal: int = -1
var upgraded_max_bonus_damage: int = -1
var upgraded_description: String = ""

## 美杜莎专属升级字段
var upgraded_venom_apply: int = -1
var upgraded_venom_apply_all: int = -1
var upgraded_devour_max_hp_bonus: int = -1
var upgraded_damage_per_consume_venom: int = -1
var upgraded_bonus_damage_per_venom: int = -1
var upgraded_bonus_damage_if_venom: int = -1
var upgraded_bonus_damage_if_venom_5: int = -1
var upgraded_bonus_damage_if_vulnerable: int = -1
var upgraded_venom_threshold_double: int = -1
var upgraded_python_cost_reduction: int = -1
var upgraded_queen_bonus_venom: int = -1
var upgraded_heal_per_venom: int = -1
var upgraded_venom_thorns: int = -1
var upgraded_queen_retain_cards: int = -1
var upgraded_queen_venom_thorns: int = -1
var upgraded_apply_weak_all: int = -1
var upgraded_apply_armor_break_all: int = -1
var upgraded_consume_all_venom_heal: int = -1
var upgraded_consume_all_venom_block: int = -1
var upgraded_cleanse_count: int = -1
var upgraded_combo_bonus_venom: int = -1

## 萧薰儿专属升级字段
var upgraded_next_n_cards_double: int = -1
var upgraded_gold_seal_detonate_damage_per_stack: int = -1
var upgraded_combo_bonus_block: int = -1
var upgraded_combo_bonus_draw: int = -1
var upgraded_combo_bonus_strength: int = -1
var upgraded_combo_bonus_dexterity: int = -1
var upgraded_return_cost_increase: int = -1
var upgraded_gold_seal_on_all_enemies: int = -1
var upgraded_cost_reduction_per_detonate: int = -1

## 状态牌/诅咒牌
var is_status_card: bool = false  # 战斗中生成，战斗后清除
var on_turn_end_damage: int = 0   # 回合结束时若在手牌中，受到X点伤害（风缠等）


func _init(p_id: String, p_name: String, p_type: CardType, p_rarity: CardRarity,
		   p_cost: int, p_desc: String) -> void:
	id = p_id
	card_name = p_name
	card_type = p_type
	rarity = p_rarity
	cost = p_cost
	description = p_desc


## 序列化为字典（统一导出格式，消除 player_manager/card_loader 重复）
func to_dict() -> Dictionary:
	return {
		"id": id,
		"card_name": card_name,
		"card_type": int(card_type),
		"rarity": int(rarity),
		"cost": cost,
		"description": description,
		"detail": detail,
		"upgraded_detail": upgraded_detail,
		"damage": damage,
		"block": block,
		"hit_count": hit_count,
		"draw_cards": draw_cards,
		"heal": heal,
		"apply_burning": apply_burning,
		"apply_weak": apply_weak,
		"apply_vulnerable": apply_vulnerable,
		"apply_frail": apply_frail,
		"apply_frozen": apply_frozen,
		"apply_venom": apply_venom,
		"apply_armor_break": apply_armor_break,
		"gain_strength": gain_strength,
		"gain_dexterity": gain_dexterity,
		"gain_energy": gain_energy,
		"hp_cost": hp_cost,
		"aoe": aoe,
		"exhaust": exhaust,
		"ethereal": ethereal,
		"innate": innate,
		"retain": retain,
		"true_damage": true_damage,
		"channel_type": channel_type,
		"evoke": evoke,
		"evoke_count": evoke_count,
		"tags": tags.duplicate(),
		"next_card_cost_reduction": next_card_cost_reduction,
		"discard_count": discard_count,
		"next_turn_draw_penalty": next_turn_draw_penalty,
		"can_channel_next_turn": can_channel_next_turn,
		"trigger_block_on_evoke": trigger_block_on_evoke,
		"trigger_burn_on_hit": trigger_burn_on_hit,
		"remove_front_fire": remove_front_fire,
		"select_channel": select_channel,
		"discard_non_fire": discard_non_fire,
		"scry_count": scry_count,
		"choose_discard": choose_discard,
		"choose_exhaust": choose_exhaust,
		"exhaust_count": exhaust_count,
		"bonus_damage_if_cards_played_gt": bonus_damage_if_cards_played_gt,
		"bonus_damage_at_threshold": bonus_damage_at_threshold,
		"bonus_damage_per_card_played": bonus_damage_per_card_played,
		"bonus_damage_per_fire_slot": bonus_damage_per_fire_slot,
		"clear_fire_slots_on_play": clear_fire_slots_on_play,
		"energy_refund_if_fire_type": energy_refund_if_fire_type,
		"energy_refund_amount": energy_refund_amount,
		"evoke_all_fires": evoke_all_fires,
		"permanent_max_hp_gain": permanent_max_hp_gain,
		"clear_debuffs_on_play": clear_debuffs_on_play,
		"shield_per_debuff_cleared": shield_per_debuff_cleared,
		"energy_per_fire_removed": energy_per_fire_removed,
		"draw_per_fire_removed": draw_per_fire_removed,
		"reroll_front_fire": reroll_front_fire,
		"channel_type_on_fire_remove": channel_type_on_fire_remove,
		"damage_mult_if_vulnerable": damage_mult_if_vulnerable,
		"apply_burning_equals_damage": apply_burning_equals_damage,
		"burn_no_decay": burn_no_decay,
		"burn_damage_mult": burn_damage_mult,
		"upgraded_burn_damage_mult": upgraded_burn_damage_mult,
		"upgraded": upgraded,
		"upgraded_cost": upgraded_cost,
		"upgraded_damage": upgraded_damage,
		"upgraded_block": upgraded_block,
		"upgraded_hit_count": upgraded_hit_count,
		"upgraded_draw_cards": upgraded_draw_cards,
		"upgraded_heal": upgraded_heal,
		"upgraded_apply_burning": upgraded_apply_burning,
		"upgraded_apply_weak": upgraded_apply_weak,
		"upgraded_apply_vulnerable": upgraded_apply_vulnerable,
		"upgraded_apply_frail": upgraded_apply_frail,
		"upgraded_apply_frozen": upgraded_apply_frozen,
		"upgraded_apply_venom": upgraded_apply_venom,
		"upgraded_apply_armor_break": upgraded_apply_armor_break,
		"upgraded_gain_strength": upgraded_gain_strength,
		"upgraded_gain_dexterity": upgraded_gain_dexterity,
		"upgraded_gain_energy": upgraded_gain_energy,
		"upgraded_hp_cost": upgraded_hp_cost,
		"upgraded_next_card_cost_reduction": upgraded_next_card_cost_reduction,
		"upgraded_discard_count": upgraded_discard_count,
		"upgraded_trigger_block_on_evoke": upgraded_trigger_block_on_evoke,
		"upgraded_trigger_burn_on_hit": upgraded_trigger_burn_on_hit,
		"upgraded_scry_count": upgraded_scry_count,
		"upgraded_bonus_damage_at_threshold": upgraded_bonus_damage_at_threshold,
		"upgraded_bonus_damage_per_card_played": upgraded_bonus_damage_per_card_played,
		"upgraded_bonus_damage_per_fire_slot": upgraded_bonus_damage_per_fire_slot,
		"upgraded_permanent_max_hp_gain": upgraded_permanent_max_hp_gain,
		"upgraded_shield_per_debuff_cleared": upgraded_shield_per_debuff_cleared,
		"upgraded_energy_per_fire_removed": upgraded_energy_per_fire_removed,
		"upgraded_draw_per_fire_removed": upgraded_draw_per_fire_removed,
		"upgraded_energy_refund_amount": upgraded_energy_refund_amount,
		"upgraded_evoke_count": upgraded_evoke_count,
		"upgraded_innate": upgraded_innate,
		"upgraded_apply_gold_seal": upgraded_apply_gold_seal,
		"upgraded_combo_bonus_damage": upgraded_combo_bonus_damage,
		"upgraded_combo_bonus_gold_seal": upgraded_combo_bonus_gold_seal,
		"upgraded_bonus_damage_per_gold_seal": upgraded_bonus_damage_per_gold_seal,
		"upgraded_max_bonus_damage": upgraded_max_bonus_damage,
		"upgraded_description": upgraded_description,
		"is_status_card": is_status_card,
		"on_turn_end_damage": on_turn_end_damage,
		"image_path": image_path,
		"character_id": character_id,
		"on_play_tag": on_play_tag.duplicate(),
		"on_play_draw": on_play_draw,
		"on_play_block": on_play_block,
		"upgraded_on_play_block": upgraded_on_play_block,
		# 萧薰儿：金印系统
		"apply_gold_seal": apply_gold_seal,
		"gold_seal_detonate": gold_seal_detonate,
		"gold_seal_detonate_damage_per_stack": gold_seal_detonate_damage_per_stack,
		"combo_threshold": combo_threshold,
		"combo_bonus_damage": combo_bonus_damage,
		"combo_bonus_gold_seal": combo_bonus_gold_seal,
		"combo_bonus_block": combo_bonus_block,
		"combo_bonus_draw": combo_bonus_draw,
		"combo_bonus_strength": combo_bonus_strength,
		"combo_bonus_dexterity": combo_bonus_dexterity,
		"bonus_damage_per_gold_seal": bonus_damage_per_gold_seal,
		"max_bonus_damage": max_bonus_damage,
		"return_to_hand_on_detonate": return_to_hand_on_detonate,
		"return_cost_increase": return_cost_increase,
		"next_card_double": next_card_double,
		"next_n_cards_double": next_n_cards_double,
		"petrify": petrify,
		"gold_seal_on_all_enemies": gold_seal_on_all_enemies,
		"cost_reduction_per_detonate": cost_reduction_per_detonate,
		# 美杜莎：姿态系统
		"enter_stance": enter_stance,
		"leave_stance": leave_stance,
		"venom_apply": venom_apply,
		"venom_apply_all": venom_apply_all,
		"devour": devour,
		"devour_max_hp_bonus": devour_max_hp_bonus,
		"consume_venom": consume_venom,
		"damage_per_consume_venom": damage_per_consume_venom,
		"double_venom": double_venom,
		"bonus_damage_per_venom": bonus_damage_per_venom,
		"bonus_damage_if_venom": bonus_damage_if_venom,
		"bonus_damage_if_venom_5": bonus_damage_if_venom_5,
		"bonus_damage_if_vulnerable": bonus_damage_if_vulnerable,
		"venom_threshold_double": venom_threshold_double,
		"python_cost_reduction": python_cost_reduction,
		"queen_bonus_venom": queen_bonus_venom,
		"heal_per_venom": heal_per_venom,
		"halve_block": halve_block,
		"random_stance_on_hit": random_stance_on_hit,
		"venom_thorns": venom_thorns,
		"queen_retain_cards": queen_retain_cards,
		"python_block_max_venom": python_block_max_venom,
		"queen_venom_thorns": queen_venom_thorns,
		"apply_weak_all": apply_weak_all,
		"apply_armor_break_all": apply_armor_break_all,
		"queen_petrify": queen_petrify,
		"next_damage_zero": next_damage_zero,
		"consume_all_venom_heal": consume_all_venom_heal,
		"consume_all_venom_block": consume_all_venom_block,
		"cleanse_count": cleanse_count,
		"combo_bonus_venom": combo_bonus_venom,
		# 美杜莎升级字段
		"upgraded_venom_apply": upgraded_venom_apply,
		"upgraded_venom_apply_all": upgraded_venom_apply_all,
		"upgraded_devour_max_hp_bonus": upgraded_devour_max_hp_bonus,
		"upgraded_damage_per_consume_venom": upgraded_damage_per_consume_venom,
		"upgraded_bonus_damage_per_venom": upgraded_bonus_damage_per_venom,
		"upgraded_bonus_damage_if_venom": upgraded_bonus_damage_if_venom,
		"upgraded_bonus_damage_if_venom_5": upgraded_bonus_damage_if_venom_5,
		"upgraded_bonus_damage_if_vulnerable": upgraded_bonus_damage_if_vulnerable,
		"upgraded_venom_threshold_double": upgraded_venom_threshold_double,
		"upgraded_python_cost_reduction": upgraded_python_cost_reduction,
		"upgraded_queen_bonus_venom": upgraded_queen_bonus_venom,
		"upgraded_heal_per_venom": upgraded_heal_per_venom,
		"upgraded_venom_thorns": upgraded_venom_thorns,
		"upgraded_queen_retain_cards": upgraded_queen_retain_cards,
		"upgraded_queen_venom_thorns": upgraded_queen_venom_thorns,
		"upgraded_apply_weak_all": upgraded_apply_weak_all,
		"upgraded_apply_armor_break_all": upgraded_apply_armor_break_all,
		"upgraded_consume_all_venom_heal": upgraded_consume_all_venom_heal,
		"upgraded_consume_all_venom_block": upgraded_consume_all_venom_block,
		"upgraded_cleanse_count": upgraded_cleanse_count,
		"upgraded_combo_bonus_venom": upgraded_combo_bonus_venom,
		# 萧薰儿升级字段
		"upgraded_next_n_cards_double": upgraded_next_n_cards_double,
		"upgraded_gold_seal_detonate_damage_per_stack": upgraded_gold_seal_detonate_damage_per_stack,
		"upgraded_combo_bonus_block": upgraded_combo_bonus_block,
		"upgraded_combo_bonus_draw": upgraded_combo_bonus_draw,
		"upgraded_combo_bonus_strength": upgraded_combo_bonus_strength,
		"upgraded_combo_bonus_dexterity": upgraded_combo_bonus_dexterity,
		"upgraded_return_cost_increase": upgraded_return_cost_increase,
		"upgraded_gold_seal_on_all_enemies": upgraded_gold_seal_on_all_enemies,
		"upgraded_cost_reduction_per_detonate": upgraded_cost_reduction_per_detonate,
	}


## 从字典创建卡牌（兼容 JSON 格式和序列化格式）
static func from_dict(d: Dictionary) -> CardData:
	var card_id = d.get("id", "unknown")
	# JSON 用 "name"/"type"，代码用 "card_name"/"card_type"——from_dict 兼容两种，to_dict 输出后者
	var card = CardData.new(
		card_id,
		d.get("card_name", d.get("name", card_id)),
		_parse_card_type(d.get("card_type", d.get("type", 0))),
		_parse_rarity(d.get("rarity", 0)),
		d.get("cost", 0),
		d.get("description", ""),
	)
	card.detail = d.get("detail", "")
	card.upgraded_detail = d.get("upgraded_detail", "")
	card.damage = d.get("damage", 0)
	card.block = d.get("block", 0)
	card.hit_count = d.get("hit_count", 1)
	card.draw_cards = d.get("draw_cards", 0)
	card.heal = d.get("heal", 0)
	card.apply_burning = d.get("apply_burning", 0)
	card.apply_weak = d.get("apply_weak", 0)
	card.apply_vulnerable = d.get("apply_vulnerable", 0)
	card.apply_frail = d.get("apply_frail", 0)
	card.apply_frozen = d.get("apply_frozen", 0)
	card.apply_venom = d.get("apply_venom", 0)
	card.apply_armor_break = d.get("apply_armor_break", 0)
	card.gain_strength = d.get("gain_strength", 0)
	card.gain_dexterity = d.get("gain_dexterity", 0)
	card.gain_energy = d.get("gain_energy", 0)
	card.hp_cost = d.get("hp_cost", 0)
	card.aoe = d.get("aoe", false)
	card.character_id = d.get("character_id", "")
	var _opt: Array[String] = []
	_opt.assign(d.get("on_play_tag", []))
	card.on_play_tag = _opt
	card.on_play_draw = d.get("on_play_draw", 0)
	card.on_play_block = d.get("on_play_block", 0)
	card.upgraded_on_play_block = d.get("upgraded_on_play_block", -1)
	# 萧薰儿：金印系统
	card.apply_gold_seal = d.get("apply_gold_seal", 0)
	card.gold_seal_detonate = d.get("gold_seal_detonate", false)
	card.gold_seal_detonate_damage_per_stack = d.get("gold_seal_detonate_damage_per_stack", 0)
	card.combo_threshold = d.get("combo_threshold", 0)
	card.combo_bonus_damage = d.get("combo_bonus_damage", 0)
	card.combo_bonus_gold_seal = d.get("combo_bonus_gold_seal", 0)
	card.combo_bonus_block = d.get("combo_bonus_block", 0)
	card.combo_bonus_draw = d.get("combo_bonus_draw", 0)
	card.combo_bonus_strength = d.get("combo_bonus_strength", 0)
	card.combo_bonus_dexterity = d.get("combo_bonus_dexterity", 0)
	card.bonus_damage_per_gold_seal = d.get("bonus_damage_per_gold_seal", 0)
	card.max_bonus_damage = d.get("max_bonus_damage", 0)
	card.return_to_hand_on_detonate = d.get("return_to_hand_on_detonate", false)
	card.return_cost_increase = d.get("return_cost_increase", 0)
	card.next_card_double = d.get("next_card_double", false)
	card.next_n_cards_double = d.get("next_n_cards_double", 0)
	card.petrify = d.get("petrify", false)
	card.gold_seal_on_all_enemies = d.get("gold_seal_on_all_enemies", 0)
	card.cost_reduction_per_detonate = d.get("cost_reduction_per_detonate", 0)
	card.exhaust = d.get("exhaust", false)
	card.ethereal = d.get("ethereal", false)
	card.innate = d.get("innate", false)
	card.retain = d.get("retain", false)
	card.true_damage = d.get("true_damage", false)
	card.channel_type = d.get("channel_type", "")
	card.evoke = d.get("evoke", false)
	card.evoke_count = d.get("evoke_count", 0)
	var _tags: Array[String] = []
	_tags.assign(d.get("tags", []))
	card.tags = _tags
	card.next_card_cost_reduction = d.get("next_card_cost_reduction", 0)
	card.discard_count = d.get("discard_count", 0)
	card.next_turn_draw_penalty = d.get("next_turn_draw_penalty", 0)
	card.can_channel_next_turn = d.get("can_channel_next_turn", true)
	card.trigger_block_on_evoke = d.get("trigger_block_on_evoke", 0)
	card.trigger_burn_on_hit = d.get("trigger_burn_on_hit", 0)
	card.remove_front_fire = d.get("remove_front_fire", false)
	card.select_channel = d.get("select_channel", false)
	card.discard_non_fire = d.get("discard_non_fire", false)
	card.scry_count = d.get("scry_count", 0)
	card.choose_discard = d.get("choose_discard", false)
	card.choose_exhaust = d.get("choose_exhaust", false)
	card.exhaust_count = d.get("exhaust_count", 0)
	card.bonus_damage_if_cards_played_gt = d.get("bonus_damage_if_cards_played_gt", 0)
	card.bonus_damage_at_threshold = d.get("bonus_damage_at_threshold", 0)
	card.bonus_damage_per_card_played = d.get("bonus_damage_per_card_played", 0)
	card.bonus_damage_per_fire_slot = d.get("bonus_damage_per_fire_slot", 0)
	card.clear_fire_slots_on_play = d.get("clear_fire_slots_on_play", false)
	card.energy_refund_if_fire_type = d.get("energy_refund_if_fire_type", "")
	card.energy_refund_amount = d.get("energy_refund_amount", 0)
	card.evoke_all_fires = d.get("evoke_all_fires", false)
	card.permanent_max_hp_gain = d.get("permanent_max_hp_gain", 0)
	card.clear_debuffs_on_play = d.get("clear_debuffs_on_play", false)
	card.shield_per_debuff_cleared = d.get("shield_per_debuff_cleared", 0)
	card.energy_per_fire_removed = d.get("energy_per_fire_removed", 0)
	card.draw_per_fire_removed = d.get("draw_per_fire_removed", 0)
	card.reroll_front_fire = d.get("reroll_front_fire", false)
	card.channel_type_on_fire_remove = d.get("channel_type_on_fire_remove", "")
	card.damage_mult_if_vulnerable = d.get("damage_mult_if_vulnerable", 0)
	card.apply_burning_equals_damage = d.get("apply_burning_equals_damage", false)
	card.burn_no_decay = d.get("burn_no_decay", false)
	card.burn_damage_mult = d.get("burn_damage_mult", 1.0)
	card.upgraded_burn_damage_mult = d.get("upgraded_burn_damage_mult", -1.0)
	card.upgraded = d.get("upgraded", false)
	card.upgraded_cost = d.get("upgraded_cost", -1)
	card.upgraded_damage = d.get("upgraded_damage", -1)
	card.upgraded_block = d.get("upgraded_block", -1)
	card.upgraded_hit_count = d.get("upgraded_hit_count", -1)
	card.upgraded_draw_cards = d.get("upgraded_draw_cards", -1)
	card.upgraded_heal = d.get("upgraded_heal", -1)
	card.upgraded_apply_burning = d.get("upgraded_apply_burning", -1)
	card.upgraded_apply_weak = d.get("upgraded_apply_weak", -1)
	card.upgraded_apply_vulnerable = d.get("upgraded_apply_vulnerable", -1)
	card.upgraded_apply_frail = d.get("upgraded_apply_frail", -1)
	card.upgraded_apply_frozen = d.get("upgraded_apply_frozen", -1)
	card.upgraded_apply_venom = d.get("upgraded_apply_venom", -1)
	card.upgraded_apply_armor_break = d.get("upgraded_apply_armor_break", -1)
	card.upgraded_gain_strength = d.get("upgraded_gain_strength", -1)
	card.upgraded_gain_dexterity = d.get("upgraded_gain_dexterity", -1)
	card.upgraded_gain_energy = d.get("upgraded_gain_energy", -1)
	card.upgraded_hp_cost = d.get("upgraded_hp_cost", -1)
	card.upgraded_next_card_cost_reduction = d.get("upgraded_next_card_cost_reduction", -1)
	card.upgraded_discard_count = d.get("upgraded_discard_count", -1)
	card.upgraded_trigger_block_on_evoke = d.get("upgraded_trigger_block_on_evoke", -1)
	card.upgraded_trigger_burn_on_hit = d.get("upgraded_trigger_burn_on_hit", -1)
	card.upgraded_scry_count = d.get("upgraded_scry_count", -1)
	card.upgraded_bonus_damage_at_threshold = d.get("upgraded_bonus_damage_at_threshold", -1)
	card.upgraded_bonus_damage_per_card_played = d.get("upgraded_bonus_damage_per_card_played", -1)
	card.upgraded_bonus_damage_per_fire_slot = d.get("upgraded_bonus_damage_per_fire_slot", -1)
	card.upgraded_permanent_max_hp_gain = d.get("upgraded_permanent_max_hp_gain", -1)
	card.upgraded_shield_per_debuff_cleared = d.get("upgraded_shield_per_debuff_cleared", -1)
	card.upgraded_energy_per_fire_removed = d.get("upgraded_energy_per_fire_removed", -1)
	card.upgraded_draw_per_fire_removed = d.get("upgraded_draw_per_fire_removed", -1)
	card.upgraded_energy_refund_amount = d.get("upgraded_energy_refund_amount", -1)
	card.upgraded_evoke_count = d.get("upgraded_evoke_count", -1)
	card.upgraded_innate = d.get("upgraded_innate", false)
	card.upgraded_apply_gold_seal = d.get("upgraded_apply_gold_seal", -1)
	card.upgraded_combo_bonus_damage = d.get("upgraded_combo_bonus_damage", -1)
	card.upgraded_combo_bonus_gold_seal = d.get("upgraded_combo_bonus_gold_seal", -1)
	card.upgraded_bonus_damage_per_gold_seal = d.get("upgraded_bonus_damage_per_gold_seal", -1)
	card.upgraded_max_bonus_damage = d.get("upgraded_max_bonus_damage", -1)
	card.upgraded_description = d.get("upgraded_description", "")
	card.is_status_card = d.get("is_status_card", false)
	card.on_turn_end_damage = d.get("on_turn_end_damage", 0)
	card.image_path = d.get("image_path", "")
	# 美杜莎：姿态系统
	card.enter_stance = d.get("enter_stance", "")
	card.leave_stance = d.get("leave_stance", false)
	card.venom_apply = d.get("venom_apply", 0)
	card.venom_apply_all = d.get("venom_apply_all", 0)
	card.devour = d.get("devour", false)
	card.devour_max_hp_bonus = d.get("devour_max_hp_bonus", 0)
	card.consume_venom = d.get("consume_venom", false)
	card.damage_per_consume_venom = d.get("damage_per_consume_venom", 0)
	card.double_venom = d.get("double_venom", false)
	card.bonus_damage_per_venom = d.get("bonus_damage_per_venom", 0)
	card.bonus_damage_if_venom = d.get("bonus_damage_if_venom", 0)
	card.bonus_damage_if_venom_5 = d.get("bonus_damage_if_venom_5", 0)
	card.venom_threshold_double = d.get("venom_threshold_double", 0)
	card.bonus_damage_if_vulnerable = d.get("bonus_damage_if_vulnerable", 0)
	card.python_cost_reduction = d.get("python_cost_reduction", 0)
	card.queen_bonus_venom = d.get("queen_bonus_venom", 0)
	card.heal_per_venom = d.get("heal_per_venom", 0)
	card.halve_block = d.get("halve_block", false)
	card.random_stance_on_hit = d.get("random_stance_on_hit", false)
	card.venom_thorns = d.get("venom_thorns", 0)
	card.queen_retain_cards = d.get("queen_retain_cards", 0)
	card.python_block_max_venom = d.get("python_block_max_venom", false)
	card.queen_venom_thorns = d.get("queen_venom_thorns", 0)
	card.apply_weak_all = d.get("apply_weak_all", 0)
	card.apply_armor_break_all = d.get("apply_armor_break_all", 0)
	card.queen_petrify = d.get("queen_petrify", false)
	card.next_damage_zero = d.get("next_damage_zero", false)
	card.consume_all_venom_heal = d.get("consume_all_venom_heal", 0)
	card.consume_all_venom_block = d.get("consume_all_venom_block", 0)
	card.cleanse_count = d.get("cleanse_count", 0)
	card.combo_bonus_venom = d.get("combo_bonus_venom", 0)
	# 美杜莎升级字段
	card.upgraded_venom_apply = d.get("upgraded_venom_apply", -1)
	card.upgraded_venom_apply_all = d.get("upgraded_venom_apply_all", -1)
	card.upgraded_devour_max_hp_bonus = d.get("upgraded_devour_max_hp_bonus", -1)
	card.upgraded_damage_per_consume_venom = d.get("upgraded_damage_per_consume_venom", -1)
	card.upgraded_bonus_damage_per_venom = d.get("upgraded_bonus_damage_per_venom", -1)
	card.upgraded_bonus_damage_if_venom = d.get("upgraded_bonus_damage_if_venom", -1)
	card.upgraded_bonus_damage_if_venom_5 = d.get("upgraded_bonus_damage_if_venom_5", -1)
	card.upgraded_bonus_damage_if_vulnerable = d.get("upgraded_bonus_damage_if_vulnerable", -1)
	card.upgraded_venom_threshold_double = d.get("upgraded_venom_threshold_double", -1)
	card.upgraded_python_cost_reduction = d.get("upgraded_python_cost_reduction", -1)
	card.upgraded_queen_bonus_venom = d.get("upgraded_queen_bonus_venom", -1)
	card.upgraded_heal_per_venom = d.get("upgraded_heal_per_venom", -1)
	card.upgraded_venom_thorns = d.get("upgraded_venom_thorns", -1)
	card.upgraded_queen_retain_cards = d.get("upgraded_queen_retain_cards", -1)
	card.upgraded_queen_venom_thorns = d.get("upgraded_queen_venom_thorns", -1)
	card.upgraded_apply_weak_all = d.get("upgraded_apply_weak_all", -1)
	card.upgraded_apply_armor_break_all = d.get("upgraded_apply_armor_break_all", -1)
	card.upgraded_consume_all_venom_heal = d.get("upgraded_consume_all_venom_heal", -1)
	card.upgraded_consume_all_venom_block = d.get("upgraded_consume_all_venom_block", -1)
	card.upgraded_cleanse_count = d.get("upgraded_cleanse_count", -1)
	card.upgraded_combo_bonus_venom = d.get("upgraded_combo_bonus_venom", -1)
	# 萧薰儿升级字段
	card.upgraded_next_n_cards_double = d.get("upgraded_next_n_cards_double", -1)
	card.upgraded_gold_seal_detonate_damage_per_stack = d.get("upgraded_gold_seal_detonate_damage_per_stack", -1)
	card.upgraded_combo_bonus_block = d.get("upgraded_combo_bonus_block", -1)
	card.upgraded_combo_bonus_draw = d.get("upgraded_combo_bonus_draw", -1)
	card.upgraded_combo_bonus_strength = d.get("upgraded_combo_bonus_strength", -1)
	card.upgraded_combo_bonus_dexterity = d.get("upgraded_combo_bonus_dexterity", -1)
	card.upgraded_return_cost_increase = d.get("upgraded_return_cost_increase", -1)
	card.upgraded_gold_seal_on_all_enemies = d.get("upgraded_gold_seal_on_all_enemies", -1)
	card.upgraded_cost_reduction_per_detonate = d.get("upgraded_cost_reduction_per_detonate", -1)
	return card


static func _parse_card_type(val) -> CardType:
	if val is int:
		return val as CardType
	if val is float:
		return int(val) as CardType
	match str(val):
		"ATTACK": return CardType.ATTACK
		"SKILL": return CardType.SKILL
		"ABILITY": return CardType.ABILITY
		"CURSE": return CardType.CURSE
		"STATUS": return CardType.STATUS
	return CardType.ATTACK


static func _parse_rarity(val) -> CardRarity:
	if val is int:
		return val as CardRarity
	if val is float:
		return int(val) as CardRarity
	match str(val):
		"COMMON": return CardRarity.COMMON
		"RARE": return CardRarity.RARE
		"EPIC": return CardRarity.EPIC
		"LEGENDARY": return CardRarity.LEGENDARY
	return CardRarity.COMMON


func duplicate_card() -> CardData:
	return from_dict(to_dict())


## 应用升级数据
func apply_upgrade() -> void:
	if upgraded:
		return
	if upgraded_cost >= 0:
		cost = upgraded_cost
	if upgraded_damage >= 0:
		damage = upgraded_damage
	if upgraded_block >= 0:
		block = upgraded_block
	if upgraded_hit_count >= 0:
		hit_count = upgraded_hit_count
	if upgraded_draw_cards >= 0:
		draw_cards = upgraded_draw_cards
	if upgraded_heal >= 0:
		heal = upgraded_heal
	if upgraded_apply_burning >= 0:
		apply_burning = upgraded_apply_burning
	if upgraded_apply_weak >= 0:
		apply_weak = upgraded_apply_weak
	if upgraded_apply_vulnerable >= 0:
		apply_vulnerable = upgraded_apply_vulnerable
	if upgraded_apply_frail >= 0:
		apply_frail = upgraded_apply_frail
	if upgraded_apply_frozen >= 0:
		apply_frozen = upgraded_apply_frozen
	if upgraded_apply_venom >= 0:
		apply_venom = upgraded_apply_venom
	if upgraded_apply_armor_break >= 0:
		apply_armor_break = upgraded_apply_armor_break
	if upgraded_gain_strength >= 0:
		gain_strength = upgraded_gain_strength
	if upgraded_gain_dexterity >= 0:
		gain_dexterity = upgraded_gain_dexterity
	if upgraded_gain_energy >= 0:
		gain_energy = upgraded_gain_energy
	if upgraded_hp_cost >= 0:
		hp_cost = upgraded_hp_cost
	if upgraded_next_card_cost_reduction >= 0:
		next_card_cost_reduction = upgraded_next_card_cost_reduction
	if upgraded_discard_count >= 0:
		discard_count = upgraded_discard_count
	if upgraded_trigger_block_on_evoke >= 0:
		trigger_block_on_evoke = upgraded_trigger_block_on_evoke
	if upgraded_trigger_burn_on_hit >= 0:
		trigger_burn_on_hit = upgraded_trigger_burn_on_hit
	if upgraded_scry_count >= 0:
		scry_count = upgraded_scry_count
	if upgraded_bonus_damage_at_threshold >= 0:
		bonus_damage_at_threshold = upgraded_bonus_damage_at_threshold
	if upgraded_bonus_damage_per_card_played >= 0:
		bonus_damage_per_card_played = upgraded_bonus_damage_per_card_played
	if upgraded_bonus_damage_per_fire_slot >= 0:
		bonus_damage_per_fire_slot = upgraded_bonus_damage_per_fire_slot
	if upgraded_permanent_max_hp_gain >= 0:
		permanent_max_hp_gain = upgraded_permanent_max_hp_gain
	if upgraded_shield_per_debuff_cleared >= 0:
		shield_per_debuff_cleared = upgraded_shield_per_debuff_cleared
	if upgraded_energy_per_fire_removed >= 0:
		energy_per_fire_removed = upgraded_energy_per_fire_removed
	if upgraded_draw_per_fire_removed >= 0:
		draw_per_fire_removed = upgraded_draw_per_fire_removed
	if upgraded_energy_refund_amount >= 0:
		energy_refund_amount = upgraded_energy_refund_amount
	if upgraded_evoke_count >= 0:
		evoke_count = upgraded_evoke_count
	if upgraded_innate:
		innate = true
	if upgraded_apply_gold_seal >= 0:
		apply_gold_seal = upgraded_apply_gold_seal
	if upgraded_combo_bonus_damage >= 0:
		combo_bonus_damage = upgraded_combo_bonus_damage
	if upgraded_combo_bonus_gold_seal >= 0:
		combo_bonus_gold_seal = upgraded_combo_bonus_gold_seal
	if upgraded_bonus_damage_per_gold_seal >= 0:
		bonus_damage_per_gold_seal = upgraded_bonus_damage_per_gold_seal
	if upgraded_max_bonus_damage >= 0:
		max_bonus_damage = upgraded_max_bonus_damage
	if upgraded_on_play_block >= 0:
		on_play_block = upgraded_on_play_block
	if upgraded_burn_damage_mult >= 0.0:
		burn_damage_mult = upgraded_burn_damage_mult
	# 美杜莎升级
	if upgraded_venom_apply >= 0:
		venom_apply = upgraded_venom_apply
	if upgraded_venom_apply_all >= 0:
		venom_apply_all = upgraded_venom_apply_all
	if upgraded_devour_max_hp_bonus >= 0:
		devour_max_hp_bonus = upgraded_devour_max_hp_bonus
	if upgraded_damage_per_consume_venom >= 0:
		damage_per_consume_venom = upgraded_damage_per_consume_venom
	if upgraded_bonus_damage_per_venom >= 0:
		bonus_damage_per_venom = upgraded_bonus_damage_per_venom
	if upgraded_bonus_damage_if_venom >= 0:
		bonus_damage_if_venom = upgraded_bonus_damage_if_venom
	if upgraded_bonus_damage_if_venom_5 >= 0:
		bonus_damage_if_venom_5 = upgraded_bonus_damage_if_venom_5
	if upgraded_bonus_damage_if_vulnerable >= 0:
		bonus_damage_if_vulnerable = upgraded_bonus_damage_if_vulnerable
	if upgraded_venom_threshold_double >= 0:
		venom_threshold_double = upgraded_venom_threshold_double
	if upgraded_python_cost_reduction >= 0:
		python_cost_reduction = upgraded_python_cost_reduction
	if upgraded_queen_bonus_venom >= 0:
		queen_bonus_venom = upgraded_queen_bonus_venom
	if upgraded_heal_per_venom >= 0:
		heal_per_venom = upgraded_heal_per_venom
	if upgraded_venom_thorns >= 0:
		venom_thorns = upgraded_venom_thorns
	if upgraded_queen_retain_cards >= 0:
		queen_retain_cards = upgraded_queen_retain_cards
	if upgraded_queen_venom_thorns >= 0:
		queen_venom_thorns = upgraded_queen_venom_thorns
	if upgraded_apply_weak_all >= 0:
		apply_weak_all = upgraded_apply_weak_all
	if upgraded_apply_armor_break_all >= 0:
		apply_armor_break_all = upgraded_apply_armor_break_all
	if upgraded_consume_all_venom_heal >= 0:
		consume_all_venom_heal = upgraded_consume_all_venom_heal
	if upgraded_consume_all_venom_block >= 0:
		consume_all_venom_block = upgraded_consume_all_venom_block
	if upgraded_cleanse_count >= 0:
		cleanse_count = upgraded_cleanse_count
	if upgraded_combo_bonus_venom >= 0:
		combo_bonus_venom = upgraded_combo_bonus_venom
	# 萧薰儿升级
	if upgraded_next_n_cards_double >= 0:
		next_n_cards_double = upgraded_next_n_cards_double
	if upgraded_gold_seal_detonate_damage_per_stack >= 0:
		gold_seal_detonate_damage_per_stack = upgraded_gold_seal_detonate_damage_per_stack
	if upgraded_combo_bonus_block >= 0:
		combo_bonus_block = upgraded_combo_bonus_block
	if upgraded_combo_bonus_draw >= 0:
		combo_bonus_draw = upgraded_combo_bonus_draw
	if upgraded_combo_bonus_strength >= 0:
		combo_bonus_strength = upgraded_combo_bonus_strength
	if upgraded_combo_bonus_dexterity >= 0:
		combo_bonus_dexterity = upgraded_combo_bonus_dexterity
	if upgraded_return_cost_increase >= 0:
		return_cost_increase = upgraded_return_cost_increase
	if upgraded_gold_seal_on_all_enemies >= 0:
		gold_seal_on_all_enemies = upgraded_gold_seal_on_all_enemies
	if upgraded_cost_reduction_per_detonate >= 0:
		cost_reduction_per_detonate = upgraded_cost_reduction_per_detonate
	if upgraded_description != "":
		description = upgraded_description
	if upgraded_detail != "":
		detail = upgraded_detail
	upgraded = true


func has_tag(tag: String) -> bool:
	return tag in tags


func get_type_name() -> String:
	match card_type:
		CardType.ATTACK: return "攻击"
		CardType.SKILL: return "技能"
		CardType.ABILITY: return "能力"
		CardType.CURSE: return "诅咒"
		CardType.STATUS: return "状态"
	return "未知"


func get_rarity_name() -> String:
	match rarity:
		CardRarity.COMMON: return "普通"
		CardRarity.RARE: return "稀有"
		CardRarity.EPIC: return "史诗"
		CardRarity.LEGENDARY: return "传说"
	return "未知"


## 计算数据驱动的伤害加成
## cards_played: 本回合已打出牌数, fire_count: 异火槽中异火数
## gold_seal_count: 目标金印层数
func calc_bonus_damage(cards_played: int, fire_count: int, gold_seal_count: int = 0, target_venom: int = 0, attack_cards_played: int = -1) -> int:
	var bonus = 0
	# 八极崩：已打出过攻击牌时+X伤（用 attack_cards_played，-1 时回退到 cards_played 兼容旧调用）
	var attack_count = attack_cards_played if attack_cards_played >= 0 else cards_played
	if bonus_damage_at_threshold > 0 and attack_count > bonus_damage_if_cards_played_gt:
		bonus += bonus_damage_at_threshold
	# 叠浪掌：每打出过1张牌+X伤（用总牌数）
	if bonus_damage_per_card_played > 0:
		bonus += cards_played * bonus_damage_per_card_played
	# 五轮离火法/佛怒火莲：每朵异火+X伤
	if bonus_damage_per_fire_slot > 0:
		bonus += fire_count * bonus_damage_per_fire_slot
	# 光之箭/穿刺之光：每层金印+X伤（有上限）
	if bonus_damage_per_gold_seal > 0:
		var seal_bonus = gold_seal_count * bonus_damage_per_gold_seal
		if max_bonus_damage > 0:
			seal_bonus = mini(seal_bonus, max_bonus_damage)
		bonus += seal_bonus
	# 蛇毒相关加成
	if bonus_damage_per_venom > 0 and target_venom > 0:
		var venom_bonus = target_venom * bonus_damage_per_venom
		if max_bonus_damage > 0:
			venom_bonus = mini(venom_bonus, max_bonus_damage)
		bonus += venom_bonus
	if bonus_damage_if_venom > 0 and target_venom > 0:
		bonus += bonus_damage_if_venom
	if bonus_damage_if_venom_5 > 0 and target_venom >= 5:
		bonus += bonus_damage_if_venom_5
	# 连击额外伤害在 battle_manager 中处理（需要访问 player.ability_combo_no_condition）
	return bonus


## 获取预览数值（含 buff/debuff 修正 + 卡牌特殊联动）
## context: { "cards_played_this_turn": int, "fire_slot_count": int }
## 返回 { damage, block, cost, damage_base, block_base, cost_base }
func get_preview_stats(player: Player, context: Dictionary = {}) -> Dictionary:
	var result = {
		"damage": damage,
		"block": block,
		"cost": cost,
		"damage_base": damage,
		"block_base": block,
		"cost_base": cost,
	}

	var played = context.get("cards_played_this_turn", 0)
	var fire_count = context.get("fire_slot_count", 0)

	# 能耗预览（对齐 battle_manager.gd 的费用计算）
	var cost_effective = cost + player.next_card_cost_modifier - player.hand_cost_reduction
	if player.first_card_free_this_turn:
		cost_effective = 0
	if cost_reduction_per_detonate > 0:
		cost_effective = max(0, cost_effective - player.detonation_count_total * cost_reduction_per_detonate)
	if python_cost_reduction > 0 and player.current_stance == 2:
		cost_effective = max(0, cost_effective - python_cost_reduction)
	if card_type == CardType.ABILITY:
		cost_effective = max(0, cost_effective - RelicManager.get_ability_cost_reduction(PlayerManager.relics))
	result.cost = max(0, cost_effective)

	# 伤害预览（仅攻击牌）
	if damage > 0 and card_type == CardType.ATTACK:
		var effective = player.calc_attack_damage(damage)
		effective += calc_bonus_damage(played, fire_count, context.get("target_gold_seal", 0), context.get("target_venom", 0), context.get("attack_cards_played", -1))
		# 连击伤害预览（calc_bonus_damage 不处理连击，需在此单独计算）
		if combo_threshold > 0 and combo_bonus_damage > 0:
			if played >= combo_threshold or player.ability_combo_no_condition:
				effective += combo_bonus_damage
		# 退婚之辱：手牌中存在时攻击-2
		if player.has_card_in_hand("broken_engagement"):
			effective = max(0, effective - 2)
		effective = RelicManager.on_damage_dealt(effective, PlayerManager.relics, player)
		result.damage = effective

	# 护盾预览（仅技能/能力牌）— 对齐 battle_manager.gd + combatant.gd 顺序
	if block > 0:
		var block_effective = block
		# 萧家耻辱：手牌中存在时护盾减半（最先应用）
		if player.has_card_in_hand("xiao_family_shame"):
			block_effective = roundi(block_effective * 0.5)
		block_effective = RelicManager.on_block_gained(block_effective, PlayerManager.relics)
		# 敏捷加成（在脆弱之前，对齐 combatant.gd gain_block）
		block_effective += player.dexterity + player.temp_dexterity
		# 脆弱 -25%
		if player.frail > 0:
			block_effective = roundi(block_effective * 0.75)
		result.block = max(0, block_effective)

	return result
