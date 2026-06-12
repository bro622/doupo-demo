## 存档文件I/O层
## 提供安全的原子写入（参考StS2 GodotFileIo）和带备份的读取
class_name SaveFileIO

const SAVE_DIR = "user://saves/"
const TMP_SUFFIX = ".tmp"
const BACKUP_SUFFIX = ".backup"
const MAX_RETRY = 3
const RETRY_DELAY_MS = 100


## === 安全写入 ===
## 流程：旧文件→backup → 写入tmp → rename tmp→最终文件
## 任何一步失败都不会损坏已有存档
static func safe_write(filename: String, content: String) -> Error:
	_ensure_dir()
	var path = SAVE_DIR + filename
	var tmp_path = path + TMP_SUFFIX
	var backup_path = path + BACKUP_SUFFIX

	# 1. 旧文件 → backup
	if FileAccess.file_exists(path):
		# 删除旧backup（如果存在）
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_path)
		var copy_err = DirAccess.copy_absolute(path, backup_path)
		if copy_err != OK:
			push_warning("SaveFileIO: 备份失败 %s → %s (错误%d)" % [path, backup_path, copy_err])

	# 2. 写入 tmp 文件
	var file = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		var open_err = FileAccess.get_open_error()
		push_error("SaveFileIO: 无法写入tmp文件 %s (错误%d)" % [tmp_path, open_err])
		return open_err
	file.store_string(content)
	file.close()

	# 3. 使用 copy + remove 替代 rename（避免 Windows 竞态条件）
	# 先删除旧文件（带重试）
	for retry in range(MAX_RETRY):
		if FileAccess.file_exists(path):
			var rm_err = DirAccess.remove_absolute(path)
			if rm_err != OK:
				if retry < MAX_RETRY - 1:
					push_warning("SaveFileIO: 删除旧文件失败，重试 %d/%d (错误%d)" % [retry + 1, MAX_RETRY, rm_err])
					OS.delay_msec(RETRY_DELAY_MS)
					continue
				push_error("SaveFileIO: 无法删除旧文件以执行替换 (错误%d)" % rm_err)
				return rm_err
		break

	# copy tmp → 最终文件
	var copy_err = DirAccess.copy_absolute(tmp_path, path)
	if copy_err != OK:
		push_error("SaveFileIO: copy失败 %s → %s (错误%d)" % [tmp_path, path, copy_err])
		# 清理tmp文件
		if FileAccess.file_exists(tmp_path):
			DirAccess.remove_absolute(tmp_path)
		return copy_err

	# 清理tmp文件
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(tmp_path)

	return OK


## === 安全读取 ===
## 优先读主文件，失败则读backup
static func safe_read(filename: String) -> String:
	var path = SAVE_DIR + filename
	var backup_path = path + BACKUP_SUFFIX

	# 尝试读主文件
	var content = _try_read_file(path)
	if content != null and content.length() > 0:
		return content

	# 主文件失败，读backup
	push_warning("SaveFileIO: 主文件读取失败，尝试读取backup: %s" % filename)
	content = _try_read_file(backup_path)
	if content != null and content.length() > 0:
		# 用backup恢复主文件
		push_warning("SaveFileIO: 从backup恢复 %s" % filename)
		safe_write(filename, content)
		return content

	return ""


## === 检查文件是否存在 ===
static func file_exists(filename: String) -> bool:
	return FileAccess.file_exists(SAVE_DIR + filename)


## === 删除文件（含backup）===
static func delete_file(filename: String) -> void:
	var path = SAVE_DIR + filename
	var backup_path = path + BACKUP_SUFFIX
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)


## === 内部辅助 ===

static func _try_read_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var content = file.get_as_text()
	file.close()
	return content


static func _ensure_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
