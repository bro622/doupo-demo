## 卡牌数据加载器
## 从 JSON 文件加载卡牌数据，返回 CardData 数组
class_name CardLoader


## 从 JSON 文件加载卡牌
static func load_from_json(path: String) -> Array[CardData]:
	var cards: Array[CardData] = []

	if not FileAccess.file_exists(path):
		push_error("CardLoader: 文件不存在: %s" % path)
		return cards

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("CardLoader: 无法打开文件: %s" % path)
		return cards

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("CardLoader: JSON 解析错误: %s 行 %d" % [json.get_error_message(), json.get_error_line()])
		return cards

	var data = json.data
	if not data is Array:
		push_error("CardLoader: JSON 顶层应为数组")
		return cards

	for item in data:
		if not item is Dictionary:
			continue
		var card = _parse_card(item)
		if card != null:
			cards.append(card)

	return cards


## 解析单张卡牌（委托 CardData.from_dict 统一处理）
static func _parse_card(d: Dictionary) -> CardData:
	var id = d.get("id", "")
	if id == "":
		push_warning("CardLoader: 卡牌缺少 id，跳过")
		return null
	return CardData.from_dict(d)
