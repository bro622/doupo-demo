## 事件基类
## 所有事件继承此类，实现 get_choices() 返回选项
class_name EventModel


## 事件分类
enum Category { PLOT, COMBAT, REWARD, RISK }

## 结果类型
enum OutcomeType {
	GOLD,            # 获得金币
	HEAL,            # 恢复HP
	MAX_HP,          # 增加最大HP
	DAMAGE,          # 受到伤害
	CARD,            # 获得卡牌
	RELIC,           # 获得遗物
	POTION,          # 获得药水
	COMBAT,          # 触发战斗
	FLAG,            # 设置事件链标记
	REMOVE_CARD,     # 移除随机卡牌
	CURSE_CARD,      # 将诅咒牌洗入牌库（ref_id=诅咒牌ID）
	UPGRADE_CARD,    # 随机升级牌库中N张卡牌（value=数量）
	PERMA_STRENGTH,  # 永久增加力量（value=层数）
}


## 单个结果
class EventOutcome:
	var type: OutcomeType
	var value: int          # 数值（金币数、HP量等）
	var ref_id: String      # 引用ID（遗物ID字符串、敌人组ID、标记名等）
	var description: String # 结果描述文本

	func _init(p_type: OutcomeType, p_value: int = 0, p_ref_id: String = "", p_desc: String = "") -> void:
		type = p_type
		value = p_value
		ref_id = p_ref_id
		description = p_desc


## 单个选项
class EventChoice:
	var text: String                          # 选项文本
	var description_rich: String = ""         # 富文本详细描述（用于特殊显示如第0层）
	var outcomes: Array[EventOutcome]         # 结果列表
	var gold_cost: int = 0                    # 需要花费的金币（0=免费）
	var potion_cost: int = 0                  # 需要消耗的丹药数量（0=不需要）
	var probability: float = 1.0              # 成功概率（1.0=必定成功）
	var fail_outcomes: Array[EventOutcome]    # 概率失败时的结果
	var required_relic_id: int = 0            # 需要持有的遗物ID（0=无要求）

	func _init(p_text: String) -> void:
		text = p_text

	func add_outcome(p_type: OutcomeType, p_value: int = 0, p_ref_id: String = "", p_desc: String = "") -> EventChoice:
		outcomes.append(EventOutcome.new(p_type, p_value, p_ref_id, p_desc))
		return self

	func add_fail_outcome(p_type: OutcomeType, p_value: int = 0, p_ref_id: String = "", p_desc: String = "") -> EventChoice:
		fail_outcomes.append(EventOutcome.new(p_type, p_value, p_ref_id, p_desc))
		return self


## 事件属性
var id: int
var event_name: String
var description: String
var category: Category
var scene_id: int = 1                       # 所属场景（1=加玛帝国）
var required_flag: String = ""              # 前置事件标记
var is_forced: bool = false                 # 是否强制触发
var is_ancient: bool = false                # 守灵事件（通过ANCIENT节点触发，不进入随机池）
var character_id: String = ""               # 角色专属（空=所有角色可用）


## 子类重写此方法返回选项
func get_choices() -> Array[EventChoice]:
	return []


## 是否可以触发
func can_trigger(flags: Dictionary) -> bool:
	if required_flag == "":
		return true
	return flags.has(required_flag)


## 获取分类名称
func get_category_name() -> String:
	match category:
		Category.PLOT: return "剧情"
		Category.COMBAT: return "战斗"
		Category.REWARD: return "奖励"
		Category.RISK: return "风险"
	return "未知"


## 获取分类颜色
func get_category_color() -> Color:
	match category:
		Category.PLOT: return Color(0.3, 0.6, 0.9)
		Category.COMBAT: return Color(0.9, 0.3, 0.3)
		Category.REWARD: return Color(0.9, 0.8, 0.2)
		Category.RISK: return Color(0.8, 0.4, 0.1)
	return Color.WHITE


## 判断是否包含战斗结果
func has_combat_outcome() -> bool:
	for choice in get_choices():
		# 1. 检查必定发生的结果
		for outcome in choice.outcomes:
			if outcome.type == OutcomeType.COMBAT:
				return true
		# [FIX: Bug 8] 2. 增加对概率失败结果的遍历，防止漏判隐藏战斗
		for outcome in choice.fail_outcomes:
			if outcome.type == OutcomeType.COMBAT:
				return true
	return false
