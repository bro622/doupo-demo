@tool
extends EditorScript

## 去背脚本 — 四角泛洪填充法
## 在 Godot 编辑器中: Project → Tools → Run Script 执行
## 将指定目录下的 JPG/PNG 图片白色背景去除

const COLOR_THRESHOLD := 40.0  # 颜色距离阈值，越小越严格

## 要处理的目录列表
const ASSET_DIRS: Array[String] = [
	"res://assets/characters/xiao-yan/",
	"res://assets/characters/xuner/",
	"res://assets/enemies/scene1-jia-ma/normal/",
	"res://assets/enemies/scene1-jia-ma/elite/",
	"res://assets/enemies/scene1-jia-ma/boss/",
]

func _run() -> void:
	var total_processed := 0
	for asset_dir in ASSET_DIRS:
		total_processed += _process_directory(asset_dir)
	print("去背完成！总共处理了 %d 张图片。" % total_processed)


func _process_directory(dir_path: String) -> int:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("无法打开目录: " + dir_path)
		return 0

	dir.list_dir_begin()
	var file_name := dir.get_next()
	var processed := 0

	while file_name != "":
		var ext := file_name.get_extension().to_lower()
		if ext == "jpg" or ext == "jpeg" or ext == "png":
			var full_path := dir_path + file_name
			if _process_image(full_path):
				processed += 1
		file_name = dir.get_next()

	dir.list_dir_end()
	print("目录 %s 处理了 %d 张图片。" % [dir_path, processed])
	return processed


func _process_image(path: String) -> bool:
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		push_error("加载失败: " + path)
		return false

	# JPG 没有 alpha 通道，需要转换
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)

	var w := image.get_width()
	var h := image.get_height()

	# 采样四角颜色
	var corners: Array[Color] = [
		image.get_pixel(0, 0),
		image.get_pixel(w - 1, 0),
		image.get_pixel(0, h - 1),
		image.get_pixel(w - 1, h - 1),
	]

	# 用四角平均色作为背景色参考
	var bg_color := Color(0, 0, 0, 0)
	for c in corners:
		bg_color += c
	bg_color /= float(corners.size())

	# 泛洪填充：从四条边缘开始
	var visited := {}
	var queue: Array[Vector2i] = []

	# 将四条边的所有像素加入队列
	for x in range(w):
		queue.append(Vector2i(x, 0))
		queue.append(Vector2i(x, h - 1))
	for y in range(1, h - 1):
		queue.append(Vector2i(0, y))
		queue.append(Vector2i(w - 1, y))

	while queue.size() > 0:
		var pos: Vector2i = queue.pop_back()

		if pos in visited:
			continue
		visited[pos] = true

		var px: int = pos.x
		var py: int = pos.y
		if px < 0 or px >= w or py < 0 or py >= h:
			continue

		var pixel_color := image.get_pixel(px, py)
		if _color_distance(pixel_color, bg_color) < COLOR_THRESHOLD:
			# 这是背景像素，设为透明
			image.set_pixel(px, py, Color(0, 0, 0, 0))
			# 将相邻像素加入队列
			queue.append(Vector2i(px + 1, py))
			queue.append(Vector2i(px - 1, py))
			queue.append(Vector2i(px, py + 1))
			queue.append(Vector2i(px, py - 1))

	# 保存为 PNG（覆盖原文件或生成新文件）
	var save_path := path.get_basename() + ".png"
	var save_err := image.save_png(save_path)
	if save_err != OK:
		push_error("保存失败: " + save_path)
		return false

	print("已处理: %s → %s" % [path.get_file(), save_path.get_file()])
	return true


func _color_distance(c1: Color, c2: Color) -> float:
	var dr := (c1.r - c2.r) * 255.0
	var dg := (c1.g - c2.g) * 255.0
	var db := (c1.b - c2.b) * 255.0
	return sqrt(dr * dr + dg * dg + db * db)
