## 药水效果管理器
## 处理药水使用效果、生成逻辑
class_name PotionManager


## 使用药水(执行效果，返回日志文本)
## enemies参数仅在ATTACK_ENEMY类型时需要
static func use_potion(potion: PotionData, player: Player, enemies: Array = []) -> String:
	var msg = "[color=cyan]使用 [%s]！[/color]\n" % potion.potion_name

	# 丹塔令牌：丹药效果翻倍
	var effect_mult := 1
	for relic in PlayerManager.relics:
		if relic.effect_type == RelicData.EffectType.POTION_EFFECT_DOUBLE:
			effect_mult = relic.effect_value
			break

	match potion.effect_type:
		PotionData.EffectType.HEAL:
			var old_hp = player.hp
			player.hp = min(player.max_hp, player.hp + potion.effect_value * effect_mult)
			var healed = player.hp - old_hp
			msg += "恢复 %d 点HP\n" % healed
		PotionData.EffectType.GAIN_STRENGTH:
			player.temp_strength += potion.effect_value * effect_mult
			msg += "临时力量 +%d（本回合）\n" % (potion.effect_value * effect_mult)
		PotionData.EffectType.DRAW_CARDS:
			player.draw_cards(potion.effect_value * effect_mult)
			msg += "抽 %d 张牌\n" % (potion.effect_value * effect_mult)
		PotionData.EffectType.GAIN_ENERGY:
			player.gain_energy(potion.effect_value * effect_mult)
			msg += "能量 +%d\n" % (potion.effect_value * effect_mult)
		PotionData.EffectType.GAIN_BLOCK:
			player.gain_block(potion.effect_value * effect_mult)
			msg += "护盾 +%d\n" % (potion.effect_value * effect_mult)
		PotionData.EffectType.HEAL_PERCENT:
			var heal_amount = int(player.max_hp * potion.effect_value * effect_mult / 100.0)
			var old_hp2 = player.hp
			player.hp = min(player.max_hp, player.hp + heal_amount)
			var healed2 = player.hp - old_hp2
			msg += "恢复 %d 点HP（%d%%最大HP）\n" % [healed2, potion.effect_value * effect_mult]
		PotionData.EffectType.UPGRADE_HAND:
			var upgraded_count = 0
			for card in player.hand:
				if not card.upgraded:
					card.apply_upgrade()
					upgraded_count += 1
			msg += "升级 %d 张手牌\n" % upgraded_count
		PotionData.EffectType.GAIN_AGILITY:
			player.temp_dexterity += potion.effect_value * effect_mult
			msg += "临时敏捷 +%d（本回合）\n" % (potion.effect_value * effect_mult)
		PotionData.EffectType.GAIN_ICE_ARMOR:
			player.ice_armor = true
			msg += "获得冰甲（本回合单次伤害上限1）\n"
		PotionData.EffectType.ATTACK_ENEMY:
			if enemies.size() > 0:
				var target = enemies[0]
				target.take_damage(potion.effect_value * effect_mult)
				target.burn += potion.effect_value2 * effect_mult
				msg += "对 %s 造成 %d 点伤害 + %d 层燃烧\n" % [target.char_name, potion.effect_value * effect_mult, potion.effect_value2 * effect_mult]
			else:
				msg += "[color=gray]没有可攻击的敌人[/color]\n"
		PotionData.EffectType.DEATH_PREVENT:
			msg += "[color=gray]此丹药为被动效果，受到致命伤害时自动触发[/color]\n"

	return msg


## 战斗胜利后生成药水奖励(返回null表示无掉落)
static func generate_reward_potion(battle_type: int) -> PotionData:
	var roll = RNGManager.drop_rng.randi() % 100
	var drop_chance: int

	match battle_type:
		RewardManager.BattleType.NORMAL: drop_chance = 15
		RewardManager.BattleType.ELITE: drop_chance = 25
		RewardManager.BattleType.BOSS: drop_chance = 30
		_: drop_chance = 15

	if roll >= drop_chance:
		return null

	return get_random_potion()


## 从所有药水中随机取一个
static func get_random_potion() -> PotionData:
	var all = PotionDatabase.get_all_potions()
	if all.is_empty():
		return null
	return all[RNGManager.drop_rng.randi() % all.size()]


## 生成商店药水库存(3个)
static func generate_shop_potions() -> Array:
	var items: Array = []
	var count = 3
	var all = PotionDatabase.get_all_potions()

	if all.is_empty():
		return items

	for i in range(count):
		var potion = all[RNGManager.drop_rng.randi() % all.size()]
		var price = _calc_potion_price(potion)
		var item = ShopPotionItem.new(potion, price)
		items.append(item)
	return items


## 计算药水价格
static func _calc_potion_price(potion: PotionData) -> int:
	match potion.rarity:
		PotionData.Rarity.COMMON:
			return 35
		PotionData.Rarity.RARE:
			return 60
	return 35


## 商店药水物品内部类
class ShopPotionItem:
	var potion: PotionData
	var price: int
	var sold: bool = false

	func _init(p_potion: PotionData, p_price: int) -> void:
		potion = p_potion
		price = p_price
