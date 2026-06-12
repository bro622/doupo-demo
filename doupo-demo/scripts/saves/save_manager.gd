## 存档管理器（AutoLoad单例）
## 协调PlayerManager/RunManager/RNGManager的checkpoint捕获与恢复
## 参考StS2 SaveManager：只在节点边界存档，checkpoint包含完整游戏状态
extends Node

## 存档格式版本号（未来迁移用）
const SCHEMA_VERSION: int = 3

## 文件名常量
const FILE_RUN: String = "current_run.save"
const FILE_PROGRESS: String = "progress.save"
const FILE_SETTINGS: String = "settings.save"

## 信号
signal run_saved
signal run_loaded
signal progress_saved

## 内存中的checkpoint快照（用于重启/恢复）
var _checkpoint: Dictionary = {}


## ============================================================
##  Checkpoint 系统
## ============================================================

## 捕获当前所有Manager的状态为checkpoint
func capture_checkpoint() -> void:
	_checkpoint = {
		"schema_version": SCHEMA_VERSION,
		# duplicate(true) 切断引用，防止战斗中状态变化污染checkpoint
		"player": PlayerManager.get_save_data().duplicate(true),
		"run": RunManager.get_save_data().duplicate(true),
		"rng": RNGManager.get_rng_states().duplicate(true),
	}
	print("[SaveManager] Checkpoint已捕获 | Seed:%d | 节点:%d | HP:%d/%d | 金币:%d" % [
		RunManager.run_seed, RunManager.current_node_id,
		PlayerManager.hp, PlayerManager.max_hp, PlayerManager.gold
	])


## 保存checkpoint到硬盘
func save_game() -> void:
	if _checkpoint.is_empty():
		push_warning("SaveManager: checkpoint为空，无法保存")
		return
	var data = _checkpoint.duplicate(true)
	var json_string = JSON.stringify(data, "\t")
	var err = SaveFileIO.safe_write(FILE_RUN, json_string)
	if err == OK:
		run_saved.emit()
		print("[SaveManager] 游戏已保存 (节点%d, HP%d/%d, 金币%d)" % [
			RunManager.current_node_id, PlayerManager.hp, PlayerManager.max_hp, PlayerManager.gold
		])
	else:
		push_error("SaveManager: 保存失败 (错误%d)" % err)


## 从硬盘加载并恢复所有Manager状态
func load_game() -> bool:
	var json_string = SaveFileIO.safe_read(FILE_RUN)
	var data = _parse_and_validate(json_string)

	# FIX: [Bug 1] 主文件损坏时，强制尝试恢复备份文件
	if data == null and not json_string.is_empty():
		push_warning("SaveManager: 主文件损坏，尝试读取备份文件...")
		var backup_path = SaveFileIO.SAVE_DIR + FILE_RUN + SaveFileIO.BACKUP_SUFFIX
		var backup_string = SaveFileIO._try_read_file(backup_path)
		if backup_string != null:
			data = _parse_and_validate(backup_string)
			if data != null:
				SaveFileIO.safe_write(FILE_RUN, backup_string)
				print("[SaveManager] 成功从备份文件恢复存档！")

	if data == null:
		if not json_string.is_empty():
			_rename_corrupt_file(FILE_RUN, "JSN")
		else:
			print("[SaveManager] 无存档文件")
		return false

	# 检查版本号
	var version: int = data.get("schema_version", 0)
	if version > SCHEMA_VERSION:
		push_error("SaveManager: 存档版本(%d)高于当前(%d)" % [version, SCHEMA_VERSION])
		_rename_corrupt_file(FILE_RUN, "FUT")
		return false

	# 恢复顺序：RNG -> Player -> Run（RNG必须先恢复，因为其他Manager可能依赖种子）
	RNGManager.restore_rng_states(data.get("rng", {}))
	PlayerManager.restore_data(data.get("player", {}))
	RunManager.restore_data(data.get("run", {}))
	_checkpoint = data.duplicate(true)

	run_loaded.emit()
	print("[SaveManager] 存档已加载 (Seed:%d, 节点%d, HP%d/%d, 金币%d)" % [
		RunManager.run_seed, RunManager.current_node_id,
		PlayerManager.hp, PlayerManager.max_hp, PlayerManager.gold
	])
	return true


# FIX: [Bug 1] 辅助解析校验函数：安全解析JSON并验证格式
func _parse_and_validate(json_string: String) -> Variant:
	if json_string.is_empty():
		return null
	var json = JSON.new()
	if json.parse(json_string) != OK:
		return null
	if not json.data is Dictionary:
		return null
	return json.data


## 从内存中的checkpoint恢复所有Manager（不读硬盘）
func restore_checkpoint() -> void:
	if _checkpoint.is_empty():
		push_warning("SaveManager: checkpoint为空，无法恢复")
		return
	RNGManager.restore_rng_states(_checkpoint.get("rng", {}))
	PlayerManager.restore_data(_checkpoint.get("player", {}))
	RunManager.restore_data(_checkpoint.get("run", {}))
	print("[SaveManager] Checkpoint已恢复 | Seed:%d | 节点:%d | HP:%d/%d" % [
		RunManager.run_seed, RunManager.current_node_id,
		PlayerManager.hp, PlayerManager.max_hp
	])


## 是否有checkpoint
func has_checkpoint() -> bool:
	return not _checkpoint.is_empty()


## ============================================================
##  存档文件操作
## ============================================================

## 是否有行程存档
func has_run_save() -> bool:
	return SaveFileIO.file_exists(FILE_RUN)


## 删除行程存档
func delete_run_save() -> void:
	SaveFileIO.delete_file(FILE_RUN)
	_checkpoint.clear()
	print("[SaveManager] 行程存档已删除")


## ============================================================
##  跨局进度（ProgressData字典）
## ============================================================

func save_progress(data: Dictionary) -> void:
	data["schema_version"] = SCHEMA_VERSION
	var json_string = JSON.stringify(data, "\t")
	var err = SaveFileIO.safe_write(FILE_PROGRESS, json_string)
	if err == OK:
		progress_saved.emit()


func load_progress() -> Dictionary:
	var json_string = SaveFileIO.safe_read(FILE_PROGRESS)
	if json_string.is_empty():
		return {}
	var json = JSON.new()
	var err = json.parse(json_string)
	if err != OK:
		push_error("SaveManager: 进度JSON解析失败")
		return {}
	if not json.data is Dictionary:
		return {}
	# 版本检查：拒绝未来版本（防止降级损坏）
	var version: int = json.data.get("schema_version", 0)
	if version > SCHEMA_VERSION:
		push_error("SaveManager: 进度版本(%d)高于当前(%d)，忽略" % [version, SCHEMA_VERSION])
		return {}
	return json.data


## ============================================================
##  设置
## ============================================================

func save_settings(data: Dictionary) -> void:
	data["schema_version"] = SCHEMA_VERSION
	SaveFileIO.safe_write(FILE_SETTINGS, JSON.stringify(data, "\t"))


func load_settings() -> Dictionary:
	var json_string = SaveFileIO.safe_read(FILE_SETTINGS)
	if json_string.is_empty():
		return {}
	var json = JSON.new()
	if json.parse(json_string) != OK:
		return {}
	return json.data if json.data is Dictionary else {}


## ============================================================
##  损坏文件处理
## ============================================================

func _rename_corrupt_file(filename: String, reason_code: String) -> void:
	var path = SaveFileIO.SAVE_DIR + filename
	if not FileAccess.file_exists(path):
		return
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var corrupt_name = "%s.%s.%s.corrupt" % [filename, timestamp, reason_code]
	var corrupt_path = SaveFileIO.SAVE_DIR + corrupt_name
	DirAccess.rename_absolute(path, corrupt_path)
	push_warning("SaveManager: 损坏存档已重命名为 %s" % corrupt_name)
