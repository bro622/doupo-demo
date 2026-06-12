## 奖励选择场景
## 战斗胜利后显示金币和3张卡牌选择
extends Control

## 信号
signal reward_completed

## 当前数据
var gold_reward: int = 0
var card_rewards: Array[CardData] = []
var relic_reward: RelicData = null
var relic_claimed: bool = false
var potion_reward: PotionData = null
var potion_claimed: bool = false
var battle_type: RewardManager.BattleType
var card_picked: bool = false  # 是否已选择卡牌
var leaving: bool = false      # 是否正在离开（防止重复点击）

## UI引用
@onready var gold_label: Label = $CenterContainer/GoldLabel
@onready var relic_container: HBoxContainer = $CenterContainer/RelicContainer
@onready var potion_container: HBoxContainer = $CenterContainer/PotionContainer
@onready var card_container: HBoxContainer = $CenterContainer/CardContainer
@onready var leave_button: Button = $CenterContainer/LeaveButton

## 卡牌场景
var card_scene = preload("res://scenes/card.tscn")


func _ready() -> void:
	leave_button.pressed.connect(_on_leave_pressed)


## 设置奖励
func setup(p_battle_type: RewardManager.BattleType) -> void:
	battle_type = p_battle_type
	card_picked = false
	leaving = false
	relic_claimed = false
	potion_claimed = false

	# 生成金币
	gold_reward = RewardManager.generate_gold_reward(battle_type)
	PlayerManager.add_gold(gold_reward)

	# 生成卡牌
	card_rewards = RewardManager.generate_card_rewards(battle_type)

	# 生成遗物
	relic_reward = RewardManager.generate_relic_reward(battle_type)

	# 生成药水
	potion_reward = PotionManager.generate_reward_potion(battle_type)

	# 更新显示
	gold_label.text = "金币 +%d (总计: %d)" % [gold_reward, PlayerManager.gold]

	# 显示遗物
	_display_relic()
	# 显示药水
	_display_potion()
	# 显示卡牌
	_display_cards()


## 显示卡牌选择
func _display_cards() -> void:
	for card_data in card_rewards:
		var node = card_scene.instantiate() as CardNode
		node.setup(card_data)
		node.set_playable(true)
		node.card_clicked.connect(_on_card_selected.bind(card_data))
		card_container.add_child(node)


## 显示药水奖励
func _display_potion() -> void:
	if potion_reward == null:
		potion_container.visible = false
		return

	potion_container.visible = true

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(200, 50)
	btn.text = "%s (%s)\n%s" % [potion_reward.potion_name, potion_reward.get_rarity_name(), potion_reward.description]

	var style = StyleBoxFlat.new()
	style.bg_color = potion_reward.icon_color.darkened(0.5)
	style.border_color = potion_reward.get_rarity_color()
	style.set_border_width_all(2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = potion_reward.icon_color.darkened(0.3)
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.pressed.connect(_on_potion_selected)
	potion_container.add_child(btn)


## 选择药水
func _on_potion_selected() -> void:
	if potion_claimed or potion_reward == null:
		return
	potion_claimed = true
	if not PlayerManager.add_potion(potion_reward):
		potion_claimed = false
		return
	AudioManager.sfx("gain_potion.mp3")

	# 禁用药水按钮
	for child in potion_container.get_children():
		if child is Button:
			child.disabled = true
			child.text = "已领取: %s" % potion_reward.potion_name


## 显示遗物奖励
func _display_relic() -> void:
	if relic_reward == null:
		relic_container.visible = false
		return

	relic_container.visible = true

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(200, 50)
	btn.text = "%s (%s)\n%s" % [relic_reward.relic_name, relic_reward.get_rarity_name(), relic_reward.description]

	# 尝试加载遗物图片
	if relic_reward.image_path != "" and ResourceLoader.exists(relic_reward.image_path):
		var tex = load(relic_reward.image_path)
		if tex:
			btn.icon = tex
			btn.expand_icon = true
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT

	var style = StyleBoxFlat.new()
	style.bg_color = relic_reward.icon_color.darkened(0.5)
	style.border_color = relic_reward.get_rarity_color()
	style.set_border_width_all(2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = relic_reward.icon_color.darkened(0.3)
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.pressed.connect(_on_relic_selected)
	relic_container.add_child(btn)


## 选择卡牌 (card_node是信号传入的CardNode, card_data是.bind绑定的数据)
func _on_card_selected(_card_node, card_data) -> void:
	if card_picked:
		return
	card_picked = true

	PlayerManager.add_card_to_deck(card_data)
	AudioManager.sfx("card_deal.mp3")

	# 高亮选中的卡牌，禁用其他卡牌
	for child in card_container.get_children():
		if child is CardNode:
			if child.card_data == card_data:
				child.modulate = Color(0.5, 1.0, 0.5, 1.0)
			else:
				child.set_playable(false)

	# 更新离开按钮文字为"继续"
	leave_button.text = "继续"


## 离开奖励界面（推进节点进度并保存）
func _on_leave_pressed() -> void:
	if leaving:
		return
	leaving = true
	AudioManager.ui("ui_click.wav")
	RunManager.advance_to_next_node()
	SaveManager.capture_checkpoint()
	SaveManager.save_game()
	reward_completed.emit()


## 选择遗物
func _on_relic_selected() -> void:
	if relic_claimed or relic_reward == null:
		return
	relic_claimed = true
	PlayerManager.add_relic(relic_reward)
	AudioManager.sfx("relic_get.mp3")

	# 禁用遗物按钮
	for child in relic_container.get_children():
		if child is Button:
			child.disabled = true
			child.text = "已领取: %s" % relic_reward.relic_name
