## 药水注册表
## 静态字典存储所有药水定义，惰性初始化
class_name PotionDatabase

static var _registry: Dictionary = {}
static var _initialized: bool = false


static func _ensure_init() -> void:
	if _initialized:
		return
	_initialized = true
	_register_all()


static func _register(potion: PotionData) -> void:
	_registry[potion.id] = potion


static func get_potion(id: int) -> PotionData:
	_ensure_init()
	return _registry.get(id)


static func get_all_potions() -> Array[PotionData]:
	_ensure_init()
	var result: Array[PotionData] = []
	for key in _registry:
		result.append(_registry[key])
	return result


static func get_potions_by_rarity(rarity: PotionData.Rarity) -> Array[PotionData]:
	_ensure_init()
	var result: Array[PotionData] = []
	for key in _registry:
		if _registry[key].rarity == rarity:
			result.append(_registry[key])
	return result


static func _register_all() -> void:
	# === 基础丹药（加玛帝国起） ===
	# 回气散：立刻获得2点能量
	_register(PotionData.new(1, "回气散", PotionData.Rarity.COMMON,
		"立刻获得2点能量", Color(0.4, 0.7, 0.9),
		PotionData.EffectType.GAIN_ENERGY, 2))

	# 聚气散：立刻抽3张牌
	_register(PotionData.new(2, "聚气散", PotionData.Rarity.COMMON,
		"立刻抽3张牌", Color(0.6, 0.5, 0.9),
		PotionData.EffectType.DRAW_CARDS, 3))

	# 护体散：立刻获得12点护盾
	_register(PotionData.new(3, "护体散", PotionData.Rarity.COMMON,
		"立刻获得12点护盾", Color(0.5, 0.5, 0.8),
		PotionData.EffectType.GAIN_BLOCK, 12))

	# 凝血散：回复自身20%的最大生命值
	_register(PotionData.new(4, "凝血散", PotionData.Rarity.COMMON,
		"回复自身20%的最大生命值", Color(0.7, 0.3, 0.3),
		PotionData.EffectType.HEAL_PERCENT, 20))

	# === 高级丹药（黑角域起） ===
	# 焚血丹：获得2点力量
	_register(PotionData.new(5, "焚血丹", PotionData.Rarity.RARE,
		"获得2点力量（本回合）", Color(0.9, 0.3, 0.2),
		PotionData.EffectType.GAIN_STRENGTH, 2))

	# 疾风丹：获得2点敏捷
	_register(PotionData.new(6, "疾风丹", PotionData.Rarity.RARE,
		"获得2点敏捷（本回合）", Color(0.4, 0.9, 0.4),
		PotionData.EffectType.GAIN_AGILITY, 2))

	# 三纹青灵丹：将手牌中的所有卡牌升级
	_register(PotionData.new(7, "三纹青灵丹", PotionData.Rarity.RARE,
		"将手牌中的所有卡牌升级", Color(0.3, 0.8, 0.7),
		PotionData.EffectType.UPGRADE_HAND, 0))

	# 冰灵丹：获得冰甲（本回合单次伤害上限1）
	_register(PotionData.new(8, "冰灵丹", PotionData.Rarity.RARE,
		"获得冰甲（本回合受到的单次伤害上限为1）", Color(0.3, 0.6, 0.9),
		PotionData.EffectType.GAIN_ICE_ARMOR, 0))

	# === 极品丹药（中州/隐藏事件） ===
	# 黄泉血丹：对目标敌人造成20点伤害+5层燃烧
	_register(PotionData.new(9, "黄泉血丹", PotionData.Rarity.RARE,
		"对敌人造成20点伤害并施加5层燃烧", Color(0.8, 0.2, 0.3),
		PotionData.EffectType.ATTACK_ENEMY, 20, 5))

	# 阴阳玄龙丹：受到致命伤害时自动消耗，防止死亡并恢复至30%HP
	_register(PotionData.new(10, "阴阳玄龙丹", PotionData.Rarity.RARE,
		"受到致命伤害时自动防止死亡，恢复至30%最大HP", Color(0.8, 0.5, 0.9),
		PotionData.EffectType.DEATH_PREVENT, 30))
