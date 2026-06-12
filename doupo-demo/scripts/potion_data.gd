## 药水数据类
## 定义药水的类型、稀有度和消耗效果
class_name PotionData

## 稀有度
enum Rarity { COMMON, RARE }

## 使用限制
enum Usage { COMBAT_ONLY }

## 效果类型
enum EffectType {
	HEAL,            # 恢复N点HP
	GAIN_STRENGTH,   # 获得N点力量(本回合)
	DRAW_CARDS,      # 抽N张牌
	GAIN_ENERGY,     # 获得N点能量
	GAIN_BLOCK,      # 获得N点护盾
	HEAL_PERCENT,    # 恢复N%最大生命值
	UPGRADE_HAND,    # 升级手牌中所有卡牌
	GAIN_AGILITY,    # 获得N点敏捷(本回合)
	GAIN_ICE_ARMOR,  # 获得冰甲(本回合单次伤害上限1)
	ATTACK_ENEMY,    # 对目标敌人造成N伤害+施加M层燃烧
	DEATH_PREVENT,   # 受到致命伤害时防止死亡，恢复至N%HP
}

var id: int
var potion_name: String
var rarity: Rarity
var description: String
var icon_color: Color
var effect_type: EffectType
var effect_value: int
var effect_value2: int = 0
var image_path: String = ""


func _init(p_id: int, p_name: String, p_rarity: Rarity, p_desc: String,
		p_icon_color: Color, p_effect_type: EffectType, p_effect_value: int,
		p_effect_value2: int = 0) -> void:
	id = p_id
	potion_name = p_name
	rarity = p_rarity
	description = p_desc
	icon_color = p_icon_color
	effect_type = p_effect_type
	effect_value = p_effect_value
	effect_value2 = p_effect_value2
	# 自动设置图片路径
	var auto_path = "res://assets/ui/potions/%s.png" % p_name
	if ResourceLoader.exists(auto_path):
		image_path = auto_path


func get_rarity_name() -> String:
	match rarity:
		Rarity.COMMON: return "基础"
		Rarity.RARE: return "高级"
	return "未知"


func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMMON: return Color(0.6, 0.8, 0.6)
		Rarity.RARE: return Color(0.3, 0.5, 1.0)
	return Color.WHITE
