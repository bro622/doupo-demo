# AudioManager — AutoLoad singleton for all game audio
# Phase 1: Object pool + handles + PitchVariance + Ambience bus
# Phase 2: BGM playlist with crossfade
extends Node

# Audio bus names
const BUS_SFX := "SFX"
const BUS_UI := "UI"
const BUS_AMBIENCE := "Ambience"
const BUS_BGM := "Music"

# Pitch variance levels (STS2-aligned)
enum PitchVar { NONE, SMALL, MEDIUM, LARGE }
const _PITCH_RANGES := {
	PitchVar.NONE: 0.0,
	PitchVar.SMALL: 0.02,
	PitchVar.MEDIUM: 0.05,
	PitchVar.LARGE: 0.10,
}

# Object pool
var _free_players: Array[AudioStreamPlayer] = []
var _active: Dictionary = {}   # {handle_id: AudioStreamPlayer}
var _next_id: int = 0
var _ambience_handle: int = -1

# BGM playlist
var _bgm_playlist: Array[String] = []
var _bgm_index: int = 0
var _bgm_player_a: AudioStreamPlayer
var _bgm_player_b: AudioStreamPlayer
var _bgm_active_a: bool = true  # true = player_a is current
var _bgm_volume: float = 0.0  # dB
var _bgm_crossfade_time: float = 2.0
var _bgm_fade_tween: Tween = null

# Preloaded audio pools
var _sfx_cache: Dictionary = {}
var _ui_cache: Dictionary = {}

# RNG
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_ensure_buses()
	_preload_audio()
	# BGM players (dedicated, not pooled — for crossfade)
	_bgm_player_a = AudioStreamPlayer.new()
	_bgm_player_a.bus = BUS_BGM if AudioServer.get_bus_index(BUS_BGM) >= 0 else "Master"
	add_child(_bgm_player_a)
	_bgm_player_b = AudioStreamPlayer.new()
	_bgm_player_b.bus = BUS_BGM if AudioServer.get_bus_index(BUS_BGM) >= 0 else "Master"
	add_child(_bgm_player_b)
	_bgm_player_a.finished.connect(_on_bgm_finished.bind(true))
	_bgm_player_b.finished.connect(_on_bgm_finished.bind(false))


func _ensure_buses() -> void:
	# Ambience bus may not exist in default layout — create if missing
	if AudioServer.get_bus_index(BUS_AMBIENCE) < 0:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, BUS_AMBIENCE)
		AudioServer.set_bus_send(idx, "Master")
		AudioServer.set_bus_volume_db(idx, 0.0)
		AudioServer.set_bus_mute(idx, false)
	# BGM bus uses existing "Music" bus from default_bus_layout.tres


func _preload_audio() -> void:
	var sfx_dir := "res://assets/audio/sfx/"
	var sfx_files := [
		"battle_start_1.mp3", "battle_start_2.mp3",
		"heavy_attack.mp3", "slash_attack.mp3", "blunt_attack.mp3", "dagger_throw.mp3",
		"doom_apply.mp3", "death_stinger.mp3", "victory.mp3",
		"player_turn.mp3", "enemy_turn.mp3",
		"card_deal.mp3", "card_exhaust.mp3", "card_smith.mp3", "burn_card.mp3",
		"potion_slosh_1.mp3", "potion_slosh_2.mp3", "potion_slosh_3.mp3", "gain_potion.mp3",
		"relic_get.mp3", "character_unlock.mp3", "character_unlock_charge.mp3",
		"rest_jingle.mp3", "rest_jingle_b.mp3", "rest_jingle_c.mp3", "sleep_blanket.mp3",
		"doll_room_amb.mp3", "shovel.mp3",
		"regent_intro.wav", "logo_echo.mp3",
	]
	for fname in sfx_files:
		var path: String = sfx_dir + fname
		if ResourceLoader.exists(path):
			_sfx_cache[fname] = load(path)

	var ui_dir := "res://assets/audio/ui/"
	var ui_files := [
		"ui_click.wav", "card_select.mp3", "deny.mp3",
		"map_hover.mp3", "map_open.mp3", "map_ping.mp3", "map_split_tick.mp3",
	]
	for fname in ui_files:
		var path: String = ui_dir + fname
		if ResourceLoader.exists(path):
			_ui_cache[fname] = load(path)


# ── Public API ──────────────────────────────────────────────

## Play a one-shot SFX. Returns handle for stop/fade control.
func sfx(sfx_name: String, volume_db_offset: float = 0.0, pitch_var: PitchVar = PitchVar.NONE, bus_override: String = "") -> int:
	if not _sfx_cache.has(sfx_name):
		push_warning("AudioManager: SFX not found: %s" % sfx_name)
		return -1
	var bus := bus_override if bus_override != "" else BUS_SFX
	return _play_stream(_sfx_cache[sfx_name], bus, volume_db_offset, pitch_var)


## Play a one-shot UI sound. Returns handle.
func ui(ui_name: String, volume_db_offset: float = 0.0, pitch_var: PitchVar = PitchVar.NONE) -> int:
	if not _ui_cache.has(ui_name):
		push_warning("AudioManager: UI sound not found: %s" % ui_name)
		return -1
	return _play_stream(_ui_cache[ui_name], BUS_UI, volume_db_offset, pitch_var)


## Stop a playing sound by handle, with optional fade-out.
func stop(handle_id: int, fade_time: float = 0.0) -> void:
	if not _active.has(handle_id):
		return
	var player: AudioStreamPlayer = _active[handle_id]
	if fade_time > 0.0 and is_instance_valid(player):
		var tween := create_tween()
		tween.tween_property(player, "volume_db", -80.0, fade_time)
		tween.tween_callback(func():
			_release(handle_id)
		)
	else:
		_release(handle_id)


## Stop the current ambience loop with fade-out.
func stop_ambience(fade_time: float = 1.0) -> void:
	if _ambience_handle >= 0:
		stop(_ambience_handle, fade_time)
		_ambience_handle = -1


## Play ambience sound (looping). Stores handle for stop_ambience().
func play_ambience(sfx_name: String, volume_db_offset: float = 0.0) -> void:
	stop_ambience(0.0)
	if not _sfx_cache.has(sfx_name):
		push_warning("AudioManager: Ambience SFX not found: %s" % sfx_name)
		return
	var handle := _play_stream(_sfx_cache[sfx_name], BUS_AMBIENCE, volume_db_offset, PitchVar.NONE, true)
	_ambience_handle = handle


# ── Convenience methods ─────────────────────────────────────

func battle_start() -> void:
	if _rng.randi() % 2 == 0:
		sfx("battle_start_1.mp3")
	else:
		sfx("battle_start_2.mp3")


func potion_slosh() -> void:
	var idx := _rng.randi() % 3 + 1
	sfx("potion_slosh_%d.mp3" % idx, 0.0, PitchVar.LARGE)


func rest_jingle() -> void:
	var variants := ["rest_jingle.mp3", "rest_jingle_b.mp3", "rest_jingle_c.mp3"]
	sfx(variants[_rng.randi() % variants.size()])


# ── Internals ───────────────────────────────────────────────

func _acquire() -> AudioStreamPlayer:
	if _free_players.size() > 0:
		return _free_players.pop_back()
	var player := AudioStreamPlayer.new()
	add_child(player)
	return player


func _release(handle_id: int) -> void:
	if not _active.has(handle_id):
		return
	var player: AudioStreamPlayer = _active[handle_id]
	_active.erase(handle_id)
	if is_instance_valid(player):
		player.stop()
		player.stream = null
		_free_players.append(player)


func _play_stream(stream: AudioStream, bus_name: String, volume_db_offset: float, pitch_var: PitchVar, looping: bool = false) -> int:
	var player := _acquire()
	var handle := _next_id
	_next_id += 1
	_active[handle] = player

	player.stream = stream
	player.bus = bus_name if AudioServer.get_bus_index(bus_name) >= 0 else "Master"
	# Pitch variance
	var pitch_range: float = _PITCH_RANGES.get(pitch_var, 0.0)
	if pitch_range > 0.0:
		player.pitch_scale = 1.0 + _rng.randf_range(-pitch_range, pitch_range)
	else:
		player.pitch_scale = 1.0
	# Volume with square curve (STS2-aligned)
	var linear_vol := db_to_linear(volume_db_offset)
	player.volume_db = linear_to_db(pow(absf(linear_vol), 2.0) * signf(linear_vol)) if linear_vol != 0.0 else 0.0

	if looping:
		player.stream.loop = true
	player.play()
	if not looping:
		player.finished.connect(_on_finished.bind(handle), CONNECT_ONE_SHOT)
	return handle


func _on_finished(handle_id: int) -> void:
	_release(handle_id)


# ── BGM Playlist with Crossfade ─────────────────────────────

## Start playing a BGM playlist. Tracks crossfade with fade_time seconds.
## If playlist is empty, stops current BGM.
## volume_db: base volume for BGM playback.
func play_bgm_playlist(tracks: Array[String], volume_db: float = -10.0, crossfade_time: float = 2.0) -> void:
	if tracks.is_empty():
		stop_bgm(1.0)
		return
	_bgm_playlist = tracks
	_bgm_index = 0
	_bgm_volume = volume_db
	_bgm_crossfade_time = crossfade_time
	_play_current_track(false)


## Play a one-shot BGM (non-looping, not in playlist) with fade-in/out.
## Returns a handle. Emits `bgm_once_finished` when playback completes naturally.
## fade_in: seconds to ramp from silence to full volume.
## fade_out: seconds to ramp down BEFORE the track ends (0 = no fade-out).
signal bgm_once_finished

func play_bgm_once(track_name: String, volume_db: float = -6.0, fade_in: float = 1.5, fade_out: float = 2.0) -> int:
	var path := "res://assets/audio/bgm/" + track_name
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: BGM once track not found: %s" % path)
		return -1
	var stream: AudioStream = load(path)
	if stream == null:
		return -1

	var player := _acquire()
	var handle := _next_id
	_next_id += 1
	_active[handle] = player

	player.stream = stream
	player.bus = BUS_BGM if AudioServer.get_bus_index(BUS_BGM) >= 0 else "Master"
	player.volume_db = -80.0
	player.pitch_scale = 1.0
	player.play()

	# Fade in
	if fade_in > 0.0:
		var tw := create_tween()
		tw.tween_property(player, "volume_db", volume_db, fade_in)
	else:
		player.volume_db = volume_db

	# Fade out near end
	if fade_out > 0.0:
		var track_len := stream.get_length()
		var fade_start := maxf(0.0, track_len - fade_out)
		get_tree().create_timer(fade_start).timeout.connect(func():
			if not is_instance_valid(player) or not player.playing:
				return
			var tw2 := create_tween()
			tw2.tween_property(player, "volume_db", -80.0, fade_out)
		)

	# Emit signal on finish, then release
	player.finished.connect(func():
		bgm_once_finished.emit()
		_release(handle)
	, CONNECT_ONE_SHOT)
	return handle


## Stop BGM with fade-out.
func stop_bgm(fade_time: float = 1.0) -> void:
	_bgm_playlist.clear()
	var current := _get_active_player()
	if current and current.playing:
		_fade_out_player(current, fade_time)


## Skip to next track with crossfade.
func bgm_next() -> void:
	if _bgm_playlist.is_empty():
		return
	_bgm_index = (_bgm_index + 1) % _bgm_playlist.size()
	_play_current_track(true)


func _play_current_track(crossfade: bool) -> void:
	if _bgm_playlist.is_empty():
		return
	var path := "res://assets/audio/bgm/" + _bgm_playlist[_bgm_index]
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: BGM not found: %s" % path)
		return
	var stream: AudioStream = load(path)
	if stream == null:
		push_warning("AudioManager: BGM load returned null: %s" % path)
		return
	var new_player := _get_inactive_player()
	var old_player := _get_active_player()

	new_player.stream = stream
	new_player.volume_db = -80.0 if crossfade else _bgm_volume
	new_player.bus = BUS_BGM
	new_player.play()

	if crossfade and old_player and old_player.playing:
		# Crossfade: fade in new, fade out old
		if _bgm_fade_tween and _bgm_fade_tween.is_valid():
			_bgm_fade_tween.kill()
		_bgm_fade_tween = create_tween().set_parallel(true)
		_bgm_fade_tween.tween_property(new_player, "volume_db", _bgm_volume, _bgm_crossfade_time)
		_bgm_fade_tween.tween_property(old_player, "volume_db", -80.0, _bgm_crossfade_time)
		_bgm_fade_tween.chain().tween_callback(func():
			old_player.stop()
			old_player.stream = null
		)
	else:
		new_player.volume_db = _bgm_volume
		if old_player and old_player.playing:
			old_player.stop()
			old_player.stream = null

	_bgm_active_a = (new_player == _bgm_player_a)


func _get_active_player() -> AudioStreamPlayer:
	return _bgm_player_a if _bgm_active_a else _bgm_player_b


func _get_inactive_player() -> AudioStreamPlayer:
	return _bgm_player_b if _bgm_active_a else _bgm_player_a


func _fade_out_player(player: AudioStreamPlayer, fade_time: float) -> void:
	if _bgm_fade_tween and _bgm_fade_tween.is_valid():
		_bgm_fade_tween.kill()
	_bgm_fade_tween = create_tween()
	_bgm_fade_tween.tween_property(player, "volume_db", -80.0, fade_time)
	_bgm_fade_tween.tween_callback(func():
		player.stop()
		player.stream = null
		_bgm_playlist.clear()
	)


func _on_bgm_finished(is_player_a: bool) -> void:
	if _bgm_playlist.is_empty():
		return
	# Advance to next track
	_bgm_index = (_bgm_index + 1) % _bgm_playlist.size()
	_play_current_track(false)
