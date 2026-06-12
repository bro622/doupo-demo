## 事件注册表
## 按场景分组存储所有事件实例，惰性初始化
class_name EventDatabase

static var _by_scene: Dictionary = {}  # scene_id -> Array[EventModel]
static var _by_id: Dictionary = {}     # event_id -> EventModel
static var _initialized: bool = false


static func _ensure_init() -> void:
	if _initialized:
		return
	_initialized = true
	_register_all()


static func _register(event: EventModel) -> void:
	if _by_id.has(event.id):
		push_warning("EventDatabase: 事件 ID %d 碰撞，旧事件 '%s' 被 '%s' 覆盖" % [event.id, _by_id[event.id].event_name, event.event_name])
	_by_id[event.id] = event
	if not _by_scene.has(event.scene_id):
		_by_scene[event.scene_id] = []
	_by_scene[event.scene_id].append(event)


## 注册所有事件（每个新事件只需在此加一行）
static func _register_all() -> void:
	# === 加玛帝国 (scene_id=1) ===
	_register(EventYaoLao.new())
	_register(EventNalan.new())
	_register(EventPurpleCrystal.new()) # [FIX: Bug 10] 原 EventDesert
	_register(EventAuction.new())
	_register(EventXiaoCrisis.new())
	_register(EventYunlanAmbush.new())  # [FIX: Bug 10] 原 EventHaiBodong
	_register(EventDesertBandit.new())  # [FIX: Bug 10] 原 EventSpy
	_register(EventFireSnake.new())     # [FIX: Bug 10] 原 EventAppraisal
	_register(EventMountain.new())
	_register(EventSnakePool.new())

	# === 黑角域 (scene_id=2) ===
	_register(EventAuction2.new())
	_register(EventHanfengTrap.new())
	_register(EventMysteryMerchant.new())
	_register(EventBloodArena.new())
	_register(EventAssassinAmbush.new())
	_register(EventBloodSectExplore.new())
	_register(EventSerpentOutpost.new())
	_register(EventSmuggler.new())
	_register(EventAlchemistRuins.new())
	_register(EventDarkAuction.new())

	# === 迦南学院 (scene_id=3) ===
	_register(EventBlazingTower.new())
	_register(EventRankingChallenge.new())
	_register(EventAncientClanTreasure.new())
	_register(EventCultivationDeviation.new())
	_register(EventEarthDevilLair.new())
	_register(EventResourceBattle.new())
	_register(EventHerbGarden.new())
	_register(EventAncientCave.new())
	_register(EventFallenHeartFlame.new())
	_register(EventInnerAcademyForbidden.new())
	_register(EventLavaWorldEntrance.new())

	# === 中州 (scene_id=4) ===
	_register(EventPillTowerTrial.new())
	_register(EventSoulHallOutpost.new())
	_register(EventAncientGate.new())
	_register(EventAlliance.new())
	_register(EventSoulEldersAmbush.new())
	_register(EventAncientPuppet.new())
	_register(EventAncientTrial.new())
	_register(EventSoulStorm.new())
	_register(EventMedicineClan.new())
	_register(EventPillTowerSecret.new())
	_register(EventAncientEmperorSoul.new())
	_register(EventHuntiandiPlot.new())

	# === 守灵事件 (场景2-4) ===
	_register(EventAncientScene2.new())
	_register(EventAncientScene3.new())
	_register(EventAncientScene4.new())


## 获取指定ID的事件
static func get_event(id: int) -> EventModel:
	_ensure_init()
	return _by_id.get(id)


## 获取指定场景的所有事件
static func get_events_for_scene(scene_id: int) -> Array:
	_ensure_init()
	return _by_scene.get(scene_id, [])


## 获取强制事件（is_forced=true且未完成）
static func get_forced_event(scene_id: int, completed: Array, flags: Dictionary) -> EventModel:
	_ensure_init()
	var events = _by_scene.get(scene_id, [])
	for event in events:
		# 强制事件不过滤角色（剧情关键事件必须触发）
		if event.is_forced and event.id not in completed and event.can_trigger(flags):
			return event
	return null


## 获取需要前置标记的事件（required_flag已设置且未完成）
static func get_flag_event(scene_id: int, completed: Array, flags: Dictionary) -> EventModel:
	_ensure_init()
	var events = _by_scene.get(scene_id, [])
	for event in events:
		if event.character_id != "" and event.character_id != PlayerManager.character_id:
			continue
		if not event.is_forced and event.required_flag != "" and event.id not in completed and event.can_trigger(flags):
			return event
	return null


## 按类型随机获取事件（排除已完成和需要前置标记的）
static func get_random_event(scene_id: int, category: EventModel.Category, completed: Array, flags: Dictionary) -> EventModel:
	_ensure_init()
	var events = _by_scene.get(scene_id, [])
	var candidates: Array[EventModel] = []
	for event in events:
		if event.character_id != "" and event.character_id != PlayerManager.character_id:
			continue
		if event.category == category and event.id not in completed and not event.is_forced and not event.is_ancient and event.required_flag == "" and event.can_trigger(flags):
			candidates.append(event)
	if candidates.is_empty():
		return null
	return candidates[RNGManager.event_rng.randi() % candidates.size()]
