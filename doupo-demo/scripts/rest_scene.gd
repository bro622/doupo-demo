## 休息点场景
## 提供回血和升级卡牌选项
## 升级选择使用CardSelectOverlay覆盖层(参考StS2 NDeckUpgradeSelectScreen)
extends Control

## 信号
signal rest_completed

## 数据

## 覆盖层
var overlay_scene = preload("res://scenes/card_select_overlay.tscn")
var overlay_instance: Control = null

## UI引用
@onready var title_label: Label = $CenterContainer/TitleLabel
@onready var heal_button: Button = $CenterContainer/HealButton
@onready var upgrade_button: Button = $CenterContainer/UpgradeButton
@onready var leave_button: Button = $CenterContainer/LeaveButton
@onready var result_label: Label = $CenterContainer/ResultLabel


func _ready() -> void:
	heal_button.pressed.connect(_on_heal_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	leave_button.pressed.connect(_on_leave_pressed)


## 初始化
func setup() -> void:
	title_label.text = "修炼驿站"

	# 大长老手令/灵药圃：自动回复，不占选项
	var auto_heal = 0
	for relic in PlayerManager.relics:
		if relic.id == 42 or relic.id == 54:
			auto_heal += 15
	if auto_heal > 0:
		var old_hp = PlayerManager.hp
		PlayerManager.heal(auto_heal)
		var healed = PlayerManager.hp - old_hp
		if healed > 0:
			result_label.text = "遗物自动恢复了 %d 点HP！" % healed
	else:
		result_label.text = ""

	var base_heal = RestManager.get_heal_amount(PlayerManager.max_hp)
	var total_heal = RelicManager.calculate_rest_heal(base_heal, PlayerManager.hp, PlayerManager.max_hp, PlayerManager.relics)
	heal_button.text = "运功疗伤 (恢复%d HP)" % total_heal
	upgrade_button.text = "研习斗技 (升级1张卡牌)"

	# 如果满血禁用回血
	heal_button.disabled = PlayerManager.hp >= PlayerManager.max_hp

	# 检查是否有可升级的卡牌
	var has_upgradeable = false
	for card in PlayerManager.deck:
		if not card.upgraded:
			has_upgradeable = true
			break
	upgrade_button.disabled = not has_upgradeable


## 回血(选择后禁用升级，二选一)
func _on_heal_pressed() -> void:
	if overlay_instance != null:
		return
	var base_amount = RestManager.get_heal_amount(PlayerManager.max_hp)
	var amount = RelicManager.calculate_rest_heal(base_amount, PlayerManager.hp, PlayerManager.max_hp, PlayerManager.relics)
	PlayerManager.heal(amount)
	AudioManager.sfx("sleep_blanket.mp3", 1.0, AudioManager.PitchVar.SMALL)
	result_label.text = "恢复了 %d 点HP！" % amount
	heal_button.disabled = true
	upgrade_button.disabled = true


## 升级卡牌 - 弹出覆盖层选择
func _on_upgrade_pressed() -> void:
	if overlay_instance != null:
		return
	AudioManager.ui("ui_click.wav")

	# 收集可升级卡牌
	var upgradeable_cards: Array = []
	for card in PlayerManager.deck:
		if not card.upgraded:
			upgradeable_cards.append(card)

	if upgradeable_cards.is_empty():
		result_label.text = "没有可升级的卡牌"
		return

	# 禁用按钮
	heal_button.disabled = true
	upgrade_button.disabled = true

	# 创建覆盖层
	overlay_instance = overlay_scene.instantiate()
	add_child(overlay_instance)

	var overlay = overlay_instance
	overlay.overlay_closed.connect(_on_overlay_closed)
	overlay.show_overlay("研习斗技", "选择一张卡牌进行升级", upgradeable_cards)

	# 连接卡牌选择信号
	overlay.card_selected.connect(_on_upgrade_card_selected)


## 覆盖层中选择了要升级的卡牌(选择后禁用回血，二选一)
func _on_upgrade_card_selected(card) -> void:
	RestManager.upgrade_card(card)
	result_label.text = "升级了 [%s]！" % card.card_name
	AudioManager.sfx("card_smith.mp3", 0.0, AudioManager.PitchVar.SMALL)

	# 炼药笔记：升级时额外获得丹药
	for relic in PlayerManager.relics:
		if relic.effect_type == RelicData.EffectType.REST_UPGRADE_POTION:
			for _i in range(relic.effect_value):
				var potion = PotionManager.get_random_potion()
				if potion != null:
					if PlayerManager.add_potion(potion):
						result_label.text += "\n炼药笔记：获得 [%s]！" % potion.potion_name

	# 清理覆盖层
	if overlay_instance != null:
		overlay_instance.queue_free()
		overlay_instance = null

	# 二选一，升级后禁用两个按钮
	upgrade_button.disabled = true
	heal_button.disabled = true


## 覆盖层关闭(未选择，恢复按钮状态)
func _on_overlay_closed() -> void:
	if overlay_instance != null:
		overlay_instance.queue_free()
		overlay_instance = null

	# 未做选择，恢复两个按钮
	heal_button.disabled = PlayerManager.hp >= PlayerManager.max_hp
	var has_upgradeable = false
	for c in PlayerManager.deck:
		if not c.upgraded:
			has_upgradeable = true
			break
	upgrade_button.disabled = not has_upgradeable


## 离开
func _on_leave_pressed() -> void:
	if overlay_instance != null:
		return
	AudioManager.ui("ui_click.wav")
	rest_completed.emit()
