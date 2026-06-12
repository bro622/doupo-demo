## 休息点管理器
## 提供休息和升级选项
class_name RestManager

## 休息选项
enum RestAction { HEAL, UPGRADE }

## 获取回血量(30%最大HP)
static func get_heal_amount(max_hp: int) -> int:
	return int(max_hp * 0.3)


## 升级卡牌（使用卡牌自身的升级数据）
static func upgrade_card(card: CardData) -> void:
	card.apply_upgrade()
