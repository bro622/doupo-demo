## 遗物注册表
## 静态字典存储所有遗物定义，惰性初始化
## ID规范: #1-3=初始, #4-18=普通, #19-33=稀有, #34-43=史诗, #44-50=传说, #51-58=事件专属
## 完全对齐 game-design/06-遗物系统.md
class_name RelicDatabase

static var _registry: Dictionary = {}
static var _initialized: bool = false


static func _ensure_init() -> void:
	if _initialized:
		return
	_initialized = true
	_register_all()


static func _register(relic: RelicData) -> void:
	# 自动设置遗物图片路径
	var image_path = "res://assets/ui/relics/%s.png" % relic.relic_name
	if ResourceLoader.exists(image_path):
		relic.image_path = image_path
	_registry[relic.id] = relic


static func get_relic(id: int) -> RelicData:
	_ensure_init()
	return _registry.get(id)


static func get_all_relics() -> Array[RelicData]:
	_ensure_init()
	var result: Array[RelicData] = []
	for key in _registry:
		result.append(_registry[key])
	return result


static func get_relics_by_rarity(rarity: RelicData.Rarity) -> Array[RelicData]:
	_ensure_init()
	var result: Array[RelicData] = []
	for key in _registry:
		if _registry[key].rarity == rarity:
			result.append(_registry[key])
	return result


## 检查遗物是否对指定角色可用
static func is_available_for_character(relic: RelicData, char_id: String) -> bool:
	return relic.exclusive_to == "" or relic.exclusive_to == char_id


static func _register_all() -> void:
	# ================================================================
	#  初始遗物 (⭐ #1-#3)
	# ================================================================

	# 1. 骨炎戒 - 萧炎初始遗物
	var guyan = RelicData.new(1, "骨炎戒", RelicData.Rarity.COMMON,
		"萧炎初始遗物。战斗开始凝聚1朵骨灵冷火。每场限1次，HP<50%时触发药老附体：+2能量、抽3牌、清debuff", Color(0.8, 0.8, 0.8),
		RelicData.EffectType.BATTLE_START_CHANNEL_BLUE, 0)
	guyan.set_secondary_effect(RelicData.EffectType.LOW_HP_ENERGY_DRAW_CLEANSE, 203)
	guyan.set_exclusive_to("xiaoyan")
	_register(guyan)

	# 2. 古族金令 - 薰儿初始遗物
	var gujin = RelicData.new(2, "古族金令", RelicData.Rarity.COMMON,
		"薰儿初始遗物。每回合前两次引爆各抽1牌。每场第一张攻击牌施加2层金印", Color(0.8, 0.8, 0.8),
		RelicData.EffectType.BATTLE_START_DRAW, 0)
	gujin.set_exclusive_to("xuner")
	_register(gujin)

	# 3. 七彩蛇鳞 - 美杜莎初始遗物
	var qicai = RelicData.new(3, "七彩蛇鳞", RelicData.Rarity.COMMON,
		"美杜莎初始遗物。首次切换姿态时+1能量、抽2牌", Color(0.8, 0.8, 0.8),
		RelicData.EffectType.STANCE_SWITCH_ENERGY, 1)
	qicai.set_secondary_effect(RelicData.EffectType.STANCE_SWITCH_CARD_DRAW, 2)
	qicai.set_exclusive_to("cailin")
	_register(qicai)

	# ================================================================
	#  普通遗物 (⬜ #4-#18)
	# ================================================================

	# 4. 纳戒 - 战斗开始额外抽2牌
	_register(RelicData.new(4, "纳戒", RelicData.Rarity.COMMON,
		"战斗开始额外抽 2 牌", Color(0.8, 0.8, 0.8),
		RelicData.EffectType.BATTLE_START_DRAW, 2))

	# 5. 萧家族徽 - 战斗开始获得6护盾
	_register(RelicData.new(5, "萧家族徽", RelicData.Rarity.COMMON,
		"战斗开始获得 6 点护盾", Color(0.8, 0.8, 0.8),
		RelicData.EffectType.BATTLE_START_SHIELD, 6))

	# 6. 佣兵徽章 - 战斗开始获得1力量
	_register(RelicData.new(6, "佣兵徽章", RelicData.Rarity.COMMON,
		"战斗开始获得 1 点力量", Color(0.8, 0.8, 0.8),
		RelicData.EffectType.TURN_START_STRENGTH, 1))

	# 7. 蛇人族护符 - 战斗开始获得1敏捷（BLOCK_BONUS_FLAT = +1格挡，等效敏捷）
	_register(RelicData.new(7, "蛇人族护符", RelicData.Rarity.COMMON,
		"战斗开始获得 1 点敏捷", Color(0.8, 0.8, 0.8),
		RelicData.EffectType.BLOCK_BONUS_FLAT, 1))

	# 8. 火灵石 - 战斗开始给予所有敌人1层易伤
	_register(RelicData.new(8, "火灵石", RelicData.Rarity.COMMON,
		"战斗开始给予所有敌人 1 层易伤", Color(0.8, 0.8, 0.8),
		RelicData.EffectType.BATTLE_START_VULNERABLE_ALL, 1))

	# 9. 冰寒晶 - 战斗开始给予所有敌人1层虚弱
	_register(RelicData.new(9, "冰寒晶", RelicData.Rarity.COMMON,
		"战斗开始给予所有敌人 1 层虚弱", Color(0.8, 0.8, 0.8),
		RelicData.EffectType.BATTLE_START_WEAK_ALL, 1))

	# 10. 魔兽晶核 - 战斗胜利后回复2HP
	_register(RelicData.new(10, "魔兽晶核", RelicData.Rarity.COMMON,
		"战斗胜利后回复 2 HP", Color(0.8, 0.8, 0.8),
		RelicData.EffectType.VICTORY_HEAL, 2))

	# 11. 炼药手札 - 休息时额外回复15HP
	_register(RelicData.new(11, "炼药手札", RelicData.Rarity.COMMON,
		"休息时额外回复 15 HP", Color(0.8, 0.8, 0.8),
		RelicData.EffectType.REST_EXTRA_HEAL_FLAT, 15))

	# 12. 米特尔金卡 - 商店价格×0.8
	_register(RelicData.new(12, "米特尔金卡", RelicData.Rarity.COMMON,
		"商店价格 ×0.8", Color(0.8, 0.8, 0.8),
		RelicData.EffectType.SHOP_PRICE_DISCOUNT, 20))

	# 13. 黑铁长枪 - 每第10次攻击伤害翻倍
	_register(RelicData.new(13, "黑铁长枪", RelicData.Rarity.COMMON,
		"每第 10 次攻击伤害翻倍，计数清零", Color(0.8, 0.8, 0.8),
		RelicData.EffectType.EVERY_NTH_ATTACK_BONUS, 10))

	# 14. 回气散配方 - 每回合第3张牌打出时获4护盾
	_register(RelicData.new(14, "回气散配方", RelicData.Rarity.COMMON,
		"每回合第 3 张牌打出时获 4 护盾。回合结束重置", Color(0.8, 0.8, 0.8),
		RelicData.EffectType.NTH_CARD_SHIELD_PER_TURN, 4))

	# 15. 飞行斗技残卷 - 每场战斗抵消第一次HP伤害
	_register(RelicData.new(15, "飞行斗技残卷", RelicData.Rarity.COMMON,
		"每场战斗抵消第一次 HP 伤害", Color(0.8, 0.8, 0.8),
		RelicData.EffectType.FIRST_HP_DAMAGE_BLOCK, 1))

	# 16. 药鼎碎片 - 每打出一张能力牌回复2HP
	_register(RelicData.new(16, "药鼎碎片", RelicData.Rarity.COMMON,
		"每打出一张能力牌回复 2 HP", Color(0.8, 0.8, 0.8),
		RelicData.EffectType.CARD_PLAY_HEAL, 2))

	# 17. 迦南院徽 - 每场首次失去HP时抽2牌
	_register(RelicData.new(17, "迦南院徽", RelicData.Rarity.COMMON,
		"每场首次失去 HP 时抽 2 牌", Color(0.8, 0.8, 0.8),
		RelicData.EffectType.FIRST_HP_LOST_DRAW, 2))

	# 18. 紫云雕翎 - 弃牌堆洗入抽牌堆时获得1能量
	_register(RelicData.new(18, "紫云雕翎", RelicData.Rarity.COMMON,
		"弃牌堆洗入抽牌堆时获得 1 能量", Color(0.8, 0.8, 0.8),
		RelicData.EffectType.SHUFFLE_ENERGY, 1))

	# ================================================================
	#  稀有遗物 (🟦 #19-#33)
	# ================================================================

	# 19. 青莲座 - 回合结束未用能量最多保留2点
	_register(RelicData.new(19, "青莲座", RelicData.Rarity.RARE,
		"回合结束未用能量最多保留 2 点到下回合", Color(0.3, 0.5, 1.0),
		RelicData.EffectType.ENERGY_RETAIN_MAX, 2))

	# 20. 万兽鼎 - 最大HP+7，精英击败额外掉丹药
	var wanshou = RelicData.new(20, "万兽鼎", RelicData.Rarity.RARE,
		"最大 HP +7。精英击败时额外掉 1 瓶丹药", Color(0.3, 0.5, 1.0),
		RelicData.EffectType.MAX_HP_FLAT, 7)
	wanshou.set_secondary_effect(RelicData.EffectType.VICTORY_POTION_ELITE, 1)
	_register(wanshou)

	# 21. 强榜玉牌 - 精英掉落的卡牌奖励全部已升级
	_register(RelicData.new(21, "强榜玉牌", RelicData.Rarity.RARE,
		"精英掉落的卡牌奖励全部已升级", Color(0.3, 0.5, 1.0),
		RelicData.EffectType.VICTORY_UPGRADE_ELITE, 1))

	# 22. 血莲丹 - 回合结束护盾为0时获得5护盾
	_register(RelicData.new(22, "血莲丹", RelicData.Rarity.RARE,
		"回合结束护盾为 0 时获得 5 护盾", Color(0.3, 0.5, 1.0),
		RelicData.EffectType.SHIELD_ZERO_BONUS, 5))

	# 23. 冰皇面具 - 单次HP伤害上限15
	_register(RelicData.new(23, "冰皇面具", RelicData.Rarity.RARE,
		"单次 HP 伤害上限 15", Color(0.3, 0.5, 1.0),
		RelicData.EffectType.SINGLE_DAMAGE_CAP, 15))

	# 24. 凌影的暗镖 - 同回合打出3张攻击牌时+1力量
	_register(RelicData.new(24, "凌影的暗镖", RelicData.Rarity.RARE,
		"同回合打出 3 张攻击牌时 +1 力量", Color(0.3, 0.5, 1.0),
		RelicData.EffectType.CONSECUTIVE_ATTACK_STRENGTH, 1))

	# 25. 紫晶翼 - 同回合打出3张技能牌时+1敏捷
	_register(RelicData.new(25, "紫晶翼", RelicData.Rarity.RARE,
		"同回合打出 3 张技能牌时 +1 敏捷", Color(0.3, 0.5, 1.0),
		RelicData.EffectType.SKILL_3_PLAYED_DEXTERITY, 1))

	# 26. 异火残图 - 萧炎限定，激发异火时对全体造成3伤害
	var yihuo = RelicData.new(26, "异火残图", RelicData.Rarity.RARE,
		"萧炎限定。激发异火时对全体敌人造成 3 伤害", Color(0.3, 0.5, 1.0),
		RelicData.EffectType.FIRE_EVOKE_BONUS_DAMAGE, 3)
	yihuo.set_exclusive_to("xiaoyan")
	_register(yihuo)

	# 27. 化骨珠 - 美杜莎限定，施加蛇毒时层数+1
	var huagu = RelicData.new(27, "化骨珠", RelicData.Rarity.RARE,
		"美杜莎限定。施加蛇毒时层数 +1", Color(0.3, 0.5, 1.0),
		RelicData.EffectType.VENOM_STACK_BONUS, 1)
	huagu.set_exclusive_to("cailin")
	_register(huagu)

	# 28. 古族玉佩 - 薰儿限定，金印引爆阈值5→4
	var guzu = RelicData.new(28, "古族玉佩", RelicData.Rarity.RARE,
		"薰儿限定。金印引爆阈值 5→4", Color(0.3, 0.5, 1.0),
		RelicData.EffectType.GOLD_MARK_THRESHOLD_REDUCE, 1)
	guzu.set_exclusive_to("xuner")
	_register(guzu)

	# 29. 魂殿黑袍 - 每场第一张攻击牌连续打出两次
	_register(RelicData.new(29, "魂殿黑袍", RelicData.Rarity.RARE,
		"每场第一张攻击牌连续打出两次", Color(0.3, 0.5, 1.0),
		RelicData.EffectType.FIRST_ATTACK_DOUBLE, 1))

	# 30. 丹塔令牌 - 所有丹药效果翻倍
	_register(RelicData.new(30, "丹塔令牌", RelicData.Rarity.RARE,
		"所有丹药效果翻倍", Color(0.3, 0.5, 1.0),
		RelicData.EffectType.POTION_EFFECT_DOUBLE, 2))

	# 31. 远古魔核 - 每打出3张牌获得1能量（重设计）
	_register(RelicData.new(31, "远古魔核", RelicData.Rarity.RARE,
		"每打出 3 张牌，获得 1 点能量", Color(0.3, 0.5, 1.0),
		RelicData.EffectType.NTH_CARD_ENERGY, 3))

	# 32. 星陨阁信物 - 战斗开始下一张牌免费（重设计）
	_register(RelicData.new(32, "星陨阁信物", RelicData.Rarity.RARE,
		"战斗开始时，下一张牌费用为 0", Color(0.3, 0.5, 1.0),
		RelicData.EffectType.FIRST_TURN_CARDS_COST_ZERO, 1))

	# 33. 黑印城令牌 - 战斗金币+50%
	_register(RelicData.new(33, "黑印城令牌", RelicData.Rarity.RARE,
		"战斗金币 +50%", Color(0.3, 0.5, 1.0),
		RelicData.EffectType.BATTLE_VICTORY_GOLD_BONUS, 50))

	# ================================================================
	#  史诗遗物 (🟪 #34-#43)
	# ================================================================

	# 34. 星陨护心令 - 护盾永不衰减，可跨回合保留
	_register(RelicData.new(34, "星陨护心令", RelicData.Rarity.EPIC,
		"护盾永不衰减，可跨回合保留", Color(0.6, 0.2, 0.8),
		RelicData.EffectType.SHIELD_NEVER_DECAY, 1))

	# 35. 天妖傀 - 战斗开始获得15护盾
	_register(RelicData.new(35, "天妖傀", RelicData.Rarity.EPIC,
		"战斗开始获得 15 护盾", Color(0.6, 0.2, 0.8),
		RelicData.EffectType.BATTLE_START_SHIELD, 15))

	# 36. 陀舍古帝玉碎片 - 获得时：最大HP+10、100金币、升级3张随机牌
	var tuyu = RelicData.new(36, "陀舍古帝玉碎片", RelicData.Rarity.EPIC,
		"获得时：最大 HP +10、100 金币、升级 3 张随机牌", Color(0.6, 0.2, 0.8),
		RelicData.EffectType.MAX_HP_FLAT, 10)
	tuyu.bonus_max_hp = 10
	_register(tuyu)

	# 37. 焚炎谷令 - 有燃烧或蛇毒的敌人受伤+30%
	_register(RelicData.new(37, "焚炎谷令", RelicData.Rarity.EPIC,
		"有燃烧或蛇毒的敌人受伤 +30%", Color(0.6, 0.2, 0.8),
		RelicData.EffectType.BURN_OR_VENOM_DAMAGE_BONUS, 30))

	# 38. 风雷阁主令 - 每回合开始额外抽1牌
	_register(RelicData.new(38, "风雷阁主令", RelicData.Rarity.EPIC,
		"每回合开始额外抽 1 牌", Color(0.6, 0.2, 0.8),
		RelicData.EffectType.TURN_START_DRAW, 1))

	# 39. 净莲妖火残焰 - 回合结束给予所有敌人2层燃烧
	_register(RelicData.new(39, "净莲妖火残焰", RelicData.Rarity.EPIC,
		"回合结束给予所有敌人 2 层燃烧", Color(0.6, 0.2, 0.8),
		RelicData.EffectType.TURN_END_BURN_ALL, 2))

	# 40. 守护者之证 - 回合结束能量为0时下回合多抽1牌
	_register(RelicData.new(40, "守护者之证", RelicData.Rarity.EPIC,
		"回合结束能量为 0 时，下回合多抽 1 牌", Color(0.6, 0.2, 0.8),
		RelicData.EffectType.ENERGY_ZERO_EXTRA_DRAW, 1))

	# 41. 药族秘传 - 战斗开始若药袋有空位生成1瓶丹药
	_register(RelicData.new(41, "药族秘传", RelicData.Rarity.EPIC,
		"战斗开始若药袋有空位，生成 1 瓶丹药", Color(0.6, 0.2, 0.8),
		RelicData.EffectType.BATTLE_START_POTION, 1))

	# 42. 大长老手令 - 进入休息点自动回复15HP（不占用选项）
	_register(RelicData.new(42, "大长老手令", RelicData.Rarity.EPIC,
		"进入休息点自动回复 15 HP（不占用选项）", Color(0.6, 0.2, 0.8),
		RelicData.EffectType.REST_EXTRA_HEAL_FLAT, 15))

	# 43. 九彩原石 - 每打出5张牌获得1能量并抽1牌
	_register(RelicData.new(43, "九彩原石", RelicData.Rarity.EPIC,
		"每打出 5 张牌获得 1 能量并抽 1 牌", Color(0.6, 0.2, 0.8),
		RelicData.EffectType.NTH_CARD_ENERGY_AND_DRAW, 5))

	# ================================================================
	#  传说遗物 (🟨 #44-#50)
	# ================================================================

	# 44. 厄难毒体原液 - +2能量，回合结束对全体造成已损失HP真伤
	var enan = RelicData.new(44, "厄难毒体原液", RelicData.Rarity.LEGENDARY,
		"+2 能量。回合结束对全体敌人造成 = 已损失 HP 的真实伤害", Color(1.0, 0.85, 0.2),
		RelicData.EffectType.TURN_START_ENERGY, 2)
	enan.set_secondary_effect(RelicData.EffectType.TURN_END_LOST_HP_AOE, 0)
	_register(enan)

	# 45. 魂殿拘灵锁 - +1能量，打出未升级卡牌时自动永久升级
	var hunsuo = RelicData.new(45, "魂殿拘灵锁", RelicData.Rarity.LEGENDARY,
		"+1 能量。打出未升级卡牌时自动永久升级", Color(1.0, 0.85, 0.2),
		RelicData.EffectType.TURN_START_ENERGY, 1)
	hunsuo.set_secondary_effect(RelicData.EffectType.UNUPGRADED_AUTO_UPGRADE, 1)
	_register(hunsuo)

	# 46. 菩提古树之心 - +1能量，每回合第一张牌免费打出两次
	var puti = RelicData.new(46, "菩提古树之心", RelicData.Rarity.LEGENDARY,
		"+1 能量。每回合第一张牌免费打出两次", Color(1.0, 0.85, 0.2),
		RelicData.EffectType.TURN_START_ENERGY, 1)
	puti.set_secondary_effect(RelicData.EffectType.FIRST_CARD_DOUBLE_PER_TURN, 1)
	_register(puti)

	# 47. 天雁九行翼 - +1能量，回合开始手牌费用全部-1
	var tianyan = RelicData.new(47, "天雁九行翼", RelicData.Rarity.LEGENDARY,
		"+1 能量。回合开始手牌费用全部 -1（最低 0）", Color(1.0, 0.85, 0.2),
		RelicData.EffectType.TURN_START_ENERGY, 1)
	tianyan.set_secondary_effect(RelicData.EffectType.TURN_START_HAND_COST_REDUCE, 1)
	_register(tianyan)

	# 48. 玄重尺 - +1能量，攻击牌无视护盾（真伤），击杀返还1能量
	var xuanzhongchi = RelicData.new(48, "玄重尺", RelicData.Rarity.LEGENDARY,
		"+1 能量。攻击牌无视护盾（真伤），击杀敌人返还 1 能量", Color(1.0, 0.85, 0.2),
		RelicData.EffectType.TURN_START_ENERGY, 1)
	xuanzhongchi.set_secondary_effect(RelicData.EffectType.ATTACK_TRUE_DAMAGE, 1)
	xuanzhongchi.set_third_effect(RelicData.EffectType.ON_KILL_ENERGY, 1)
	_register(xuanzhongchi)

	# 49. 黑魔鼎原片 - +1能量，战斗胜利后额外获得1遗物+1丹药
	var heimo = RelicData.new(49, "黑魔鼎原片", RelicData.Rarity.LEGENDARY,
		"+1 能量。战斗胜利后额外获得 1 遗物 + 1 丹药", Color(1.0, 0.85, 0.2),
		RelicData.EffectType.TURN_START_ENERGY, 1)
	heimo.set_secondary_effect(RelicData.EffectType.VICTORY_EXTRA_RELIC_POTION, 1)
	_register(heimo)

	# 50. 炎帝印记 - +1能量，回合结束不弃牌
	var yandi = RelicData.new(50, "炎帝印记", RelicData.Rarity.LEGENDARY,
		"+1 能量。回合结束不弃牌", Color(1.0, 0.85, 0.2),
		RelicData.EffectType.TURN_START_ENERGY, 1)
	yandi.set_secondary_effect(RelicData.EffectType.NO_DISCARD_AT_TURN_END, 1)
	_register(yandi)

	# ================================================================
	#  事件专属遗物 (🔶 #51-#58)
	# ================================================================

	# 51. 三年之约 - 第1回合+1能量+抽1牌，击败云山后消耗
	var sannian = RelicData.new(51, "三年之约", RelicData.Rarity.EPIC,
		"第 1 回合 +1 能量并抽 1 牌。击败场景一 Boss 后消耗", Color(0.9, 0.7, 0.2),
		RelicData.EffectType.FIRST_TURN_ENERGY, 1)
	sannian.set_secondary_effect(RelicData.EffectType.FIRST_TURN_DRAW, 1)
	_register(sannian)

	# 52. 紫晶源 - 萧炎限定，异火槽满并继续凝聚时回复2HP
	var zijing = RelicData.new(52, "紫晶源", RelicData.Rarity.RARE,
		"萧炎限定。异火槽满并继续凝聚时回复 2 HP", Color(0.6, 0.2, 0.8),
		RelicData.EffectType.CHANNEL_FULL_HEAL, 2)
	zijing.set_exclusive_to("xiaoyan")
	_register(zijing)

	# 53. 诅咒护符 - 每场战斗中抽到的第一张诅咒牌自动消耗并重新抽牌
	_register(RelicData.new(53, "诅咒护符", RelicData.Rarity.RARE,
		"每场战斗中，你抽到的第一张诅咒牌将被自动消耗并重新抽一张牌", Color(0.4, 0.2, 0.6),
		RelicData.EffectType.BATTLE_START_REMOVE_CURSE, 1))

	# 54. 灵药圃 - 进入休息节点自动回复15HP
	_register(RelicData.new(54, "灵药圃", RelicData.Rarity.RARE,
		"进入休息节点自动回复 15 HP", Color(0.3, 0.7, 0.3),
		RelicData.EffectType.REST_EXTRA_HEAL_FLAT, 15))

	# 55. 赤火蛇鳞 - 战斗开始给予所有敌人2层燃烧
	_register(RelicData.new(55, "赤火蛇鳞", RelicData.Rarity.RARE,
		"战斗开始给予所有敌人 2 层燃烧", Color(0.9, 0.3, 0.1),
		RelicData.EffectType.BATTLE_START_BURN_ALL, 2))

	# 56. 山岳之心 - 首次HP<50%时下次伤害归零
	_register(RelicData.new(56, "山岳之心", RelicData.Rarity.EPIC,
		"首次 HP < 50% 时下次伤害归零", Color(0.6, 0.2, 0.8),
		RelicData.EffectType.LOW_HP_SHIELD_ONCE, 1))

	# 57. 丹塔秘卷 - 能力牌费用-1
	_register(RelicData.new(57, "丹塔秘卷", RelicData.Rarity.EPIC,
		"能力牌费用 -1", Color(0.6, 0.2, 0.8),
		RelicData.EffectType.ABILITY_COST_REDUCE, 1))

	# 58. 古帝残魂碎片 - 第1回合前5张牌费用为0
	_register(RelicData.new(58, "古帝残魂碎片", RelicData.Rarity.LEGENDARY,
		"第 1 回合前 5 张牌费用为 0", Color(1.0, 0.85, 0.2),
		RelicData.EffectType.FIRST_TURN_CARDS_COST_ZERO, 5))
