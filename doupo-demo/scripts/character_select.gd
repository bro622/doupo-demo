## 角色选择界面 — 杀戮尖塔风格
## 全屏立绘 + 左侧信息面板 + 底部角色切换 + 角落操作按钮
extends Control

signal character_selected(character_id: String)
signal cancelled

const PORTRAIT_XIAOYAN = preload("res://assets/characters/xiao-yan/portrait.png")
const PORTRAIT_XUNER = preload("res://assets/characters/xuner/portrait.png")
const PORTRAIT_CAILIN = preload("res://assets/characters/cailin/portrait.png")

const CHARACTERS: Array[Dictionary] = [
	{
		"id": "xiaoyan",
		"name": "萧炎",
		"subtitle": "异火流转 / 爆发输出",
		"hp": 75,
		"gold": 99,
		"description": "斗气大陆天才少年，曾跌落谷底，如今重新崛起。",
		"relic_name": "骨炎戒",
		"relic_desc": "每场战斗开始凝聚骨灵冷火。HP低于50%时触发药老附体。",
		"locked": false,
		"portrait": PORTRAIT_XIAOYAN,
	},
	{
		"id": "xuner",
		"name": "萧薰儿",
		"subtitle": "金印连击 / 印记引爆",
		"hp": 65,
		"gold": 99,
		"description": "古族千金，天之骄女，是古族近千年斗帝血脉觉醒得最完美者",
		"relic_name": "古族金令",
		"relic_desc": "每回合前2次引爆各抽1牌，首张攻击牌+2金印。",
		"locked": false,
		"portrait": PORTRAIT_XUNER,
	},
	{
		"id": "cailin",
		"name": "美杜莎",
		"subtitle": "双生姿态 / 毒素控制",
		"hp": 70,
		"gold": 99,
		"description": "美加玛帝国塔戈尔大沙漠蛇人部落的美杜莎女王，艳名与凶名名闻斗气大陆。",
		"relic_name": "七彩蛇鳞",
		"relic_desc": "首次切姿态+1能量抽2牌。",
		"locked": false,
		"portrait": PORTRAIT_CAILIN,
	},
]

var current_index: int = 0
var _popup_open: bool = false
var _starting: bool = false

## 按钮角色主题色
const BTN_COLORS: Array[Color] = [
	Color(0.9, 0.3, 0.2),  # 萧炎 — 红
	Color(0.9, 0.8, 0.2),  # 薰儿 — 黄
	Color(0.3, 0.8, 0.4),  # 美杜莎 — 绿
]


func _ready() -> void:
	var btns = [%CharBtn_xiaoyan, %CharBtn_xuner, %CharBtn_cailin]
	var icon_paths = [
		"res://assets/characters/xiao-yan/icon.png",
		"res://assets/characters/xuner/icon.png",
		"res://assets/characters/cailin/icon.png",
	]
	var fallback_chars = ["萧", "薰", "彩"]
	for i in range(btns.size()):
		_setup_placeholder_btn(btns[i], BTN_COLORS[i], icon_paths[i], fallback_chars[i])
		btns[i].pressed.connect(_on_char_icon_pressed.bind(i))
		btns[i].mouse_entered.connect(_on_char_hover.bind(i))
		btns[i].mouse_exited.connect(_on_char_unhover)

	# 连接角落按钮
	%StartButton.pressed.connect(_on_start_pressed)
	$BackButton.pressed.connect(func():
		AudioManager.ui("ui_click.wav")
		cancelled.emit()
	)

	_update_display()


func _setup_placeholder_btn(btn: Button, color: Color, icon_path: String, fallback_char: String = "？") -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.82, 0.72, 0.55, 0.95)  # 羊皮纸色
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10
	normal.set_border_width_all(2)
	normal.border_color = color.lightened(0.3)
	btn.add_theme_stylebox_override("normal", normal)

	var hover = normal.duplicate()
	hover.bg_color = Color(0.88, 0.78, 0.60, 1.0)  # 悬停稍亮
	hover.border_color = color
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = normal.duplicate()
	pressed.bg_color = Color(0.75, 0.65, 0.48, 1.0)  # 按下稍暗
	pressed.border_color = color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.pivot_offset = btn.custom_minimum_size / 2

	# 角色图标
	var tex: Texture2D = null
	if icon_path != "":
		tex = load(icon_path)
	if tex != null:
		var icon = TextureRect.new()
		icon.texture = tex
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon)
	else:
		# fallback：无图标时显示首字
		var lbl = Label.new()
		lbl.text = fallback_char
		lbl.add_theme_font_size_override("font_size", 28)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lbl)


## hover：仅放大按钮，不切换立绘
func _on_char_hover(index: int) -> void:
	AudioManager.ui("map_hover.mp3", 0.0, AudioManager.PitchVar.SMALL)
	var btns = [%CharBtn_xiaoyan, %CharBtn_xuner, %CharBtn_cailin]
	for i in range(btns.size()):
		if i == index:
			btns[i].scale = Vector2(1.2, 1.2)
		elif i == current_index:
			btns[i].scale = Vector2(1.15, 1.15)
		else:
			btns[i].scale = Vector2.ONE


## hover 离开：恢复按钮大小
func _on_char_unhover() -> void:
	var btns = [%CharBtn_xiaoyan, %CharBtn_xuner, %CharBtn_cailin]
	for i in range(btns.size()):
		if CHARACTERS[i]["locked"]:
			btns[i].scale = Vector2.ONE
		elif i == current_index:
			btns[i].scale = Vector2(1.15, 1.15)
		else:
			btns[i].scale = Vector2.ONE


## 点击切换立绘 + STS2 风格屏幕 punch
func _on_char_icon_pressed(index: int) -> void:
	AudioManager.ui("ui_click.wav")
	current_index = index
	_update_display()
	_screen_punch(5.0, 0.3, 90.0)


## STS2 ScreenPunchInstance: cosine oscillation + CubicOut decay
var _punch_original_pos: Vector2
var _punch_strength: float = 0.0
var _punch_duration: float = 0.0
var _punch_timer: float = 0.0
var _punch_angle_rad: float = 0.0
var _punch_active: bool = false

func _screen_punch(strength: float, duration: float, deg_angle: float) -> void:
	if not _punch_active:
		_punch_original_pos = position
	_punch_strength = strength
	_punch_duration = duration
	_punch_timer = duration
	_punch_angle_rad = deg_to_rad(deg_angle)
	_punch_active = true
	set_process(true)

func _process(delta: float) -> void:
	if not _punch_active:
		return
	if _punch_timer <= 0.0:
		position = _punch_original_pos
		_punch_active = false
		set_process(false)
		return
	_punch_timer -= delta
	var x = cos(_punch_timer * 60.0)
	var ease_val = pow(clampf(_punch_timer / _punch_duration, 0.0, 1.0), 3.0)  # CubicOut
	var offset = Vector2(x, 0.0).rotated(_punch_angle_rad) * _punch_strength * ease_val
	position = _punch_original_pos + offset


func _show_locked_popup() -> void:
	if _popup_open:
		return
	_popup_open = true

	var popup = PopupPanel.new()

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.1, 1.0)
	style.set_corner_radius_all(12)
	style.set_border_width_all(1)
	style.border_color = Color(1, 1, 1, 0.15)
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", style)
	popup.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "未开发"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "尽请期待"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(desc)

	var ok_btn = Button.new()
	ok_btn.text = "确定"
	ok_btn.custom_minimum_size = Vector2(100, 36)
	ok_btn.add_theme_font_size_override("font_size", 16)
	ok_btn.pressed.connect(func():
		popup.hide()
		popup.queue_free()
		_popup_open = false
	)
	vbox.add_child(ok_btn)

	add_child(popup)
	popup.popup_centered(Vector2(280, 180))


func _update_display() -> void:
	_show_character_info(current_index)
	_update_roster_highlight()


## 更新信息面板（不修改高亮状态，供 hover 复用）
func _show_character_info(index: int) -> void:
	var data = CHARACTERS[index]
	%Background.texture = data["portrait"]
	%RoleName.text = data["name"]
	%RoleSubtitle.text = data["subtitle"]
	%HPLabel.text = "HP: %d" % data["hp"]
	%GoldLabel.text = "金币: %d" % data["gold"]
	%DescLabel.text = data["description"]
	%RelicName.text = data["relic_name"]
	%RelicDesc.text = data["relic_desc"]


## 更新按钮高亮：选中角色边框变金色，hover 角色边框变亮
func _update_roster_highlight() -> void:
	var btns = [%CharBtn_xiaoyan, %CharBtn_xuner, %CharBtn_cailin]
	for i in range(btns.size()):
		var btn = btns[i]
		var char_data = CHARACTERS[i]
		if char_data["locked"]:
			btn.modulate = Color(0.4, 0.4, 0.4, 0.6)
			btn.scale = Vector2.ONE
		elif i == current_index:
			btn.modulate = Color(1, 1, 1, 1)
			btn.scale = Vector2(1.15, 1.15)
			# 选中：金色边框
			_set_btn_border(btn, Color(1.0, 0.85, 0.3), 3)
		else:
			btn.modulate = Color(1, 1, 1, 1)
			btn.scale = Vector2.ONE
			# 未选中：角色色边框
			_set_btn_border(btn, BTN_COLORS[i].lightened(0.3), 2)


func _set_btn_border(btn: Button, border_color: Color, border_width: int) -> void:
	for style_name in ["normal", "hover"]:
		var style = btn.get_theme_stylebox(style_name)
		if style is StyleBoxFlat:
			style.border_color = border_color
			style.set_border_width_all(border_width)


func _on_start_pressed() -> void:
	if _starting:
		return
	var data = CHARACTERS[current_index]
	if data["locked"]:
		_show_locked_popup()
		return
	_starting = true
	AudioManager.sfx("character_unlock.mp3")
	character_selected.emit(data["id"])
