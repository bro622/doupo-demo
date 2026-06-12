## 商店管理器
## 生成商店库存、处理购买逻辑
class_name ShopManager

## 商店卡牌物品
class ShopItem:
	var card: CardData
	var price: int
	var sold: bool = false

	func _init(p_card: CardData, p_price: int) -> void:
		card = p_card
		price = p_price


## 商店遗物物品
class ShopRelicItem:
	var relic: RelicData
	var price: int
	var sold: bool = false

	func _init(p_relic: RelicData, p_price: int) -> void:
		relic = p_relic
		price = p_price


## 生成商店库存(7张卡牌：5上+2左)
static func generate_shop_inventory() -> Array[ShopItem]:
	var items: Array[ShopItem] = []
	var pool = _get_shop_pool()

	for i in range(7):
		if pool.size() == 0:
			break
		var card = pool[RNGManager.drop_rng.randi() % pool.size()].duplicate_card()
		var price = _calc_price(card)
		var item = ShopItem.new(card, price)
		items.append(item)

	# 随机一张打折(50%)
	if items.size() > 0:
		var sale_index = RNGManager.drop_rng.randi() % items.size()
		items[sale_index].price = max(1, int(items[sale_index].price * 0.5))

	return items


## 计算卡牌价格（测试用：全部1金）
static func _calc_price(_card: CardData) -> int:
	return 1


## 获取商店卡池（根据当前角色过滤）
static func _get_shop_pool() -> Array[CardData]:
	return CardDatabase.create_reward_pool_for_character(PlayerManager.character_id)


## 生成商店遗物库存(3个遗物)
static func generate_shop_relics() -> Array[ShopRelicItem]:
	var items: Array[ShopRelicItem] = []
	var count = 3
	# 预过滤：排除Boss/事件专属遗物(id>=100)
	var all_relics: Array[RelicData] = []
	for r in RelicDatabase.get_all_relics():
		if r.id < 100:
			all_relics.append(r)

	if all_relics.is_empty():
		return items

	var selected_ids: Array[int] = []
	for i in range(count):
		var attempts = 0
		var relic = all_relics[RNGManager.drop_rng.randi() % all_relics.size()]
		# 去重：避免重复遗物、已拥有遗物、其他角色专属遗物
		while (relic.id in selected_ids or PlayerManager.has_relic(relic.id) or not RelicDatabase.is_available_for_character(relic, PlayerManager.character_id)) and attempts < 20:
			relic = all_relics[RNGManager.drop_rng.randi() % all_relics.size()]
			attempts += 1
		# 验证最终选取是否有效
		if relic.id in selected_ids or PlayerManager.has_relic(relic.id) or not RelicDatabase.is_available_for_character(relic, PlayerManager.character_id):
			continue
		selected_ids.append(relic.id)
		var price = _calc_relic_price(relic)
		items.append(ShopRelicItem.new(relic, price))
	return items


## 计算遗物价格（测试用：全部1金）
static func _calc_relic_price(_relic: RelicData) -> int:
	return 1
