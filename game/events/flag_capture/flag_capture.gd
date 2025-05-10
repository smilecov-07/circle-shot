class_name FlagCapture
extends Event

## Событие "Захват флага".

## Длительность матча.
@export var match_time: int = 180
## Время, через которое возвращаются павшие игроки.
@export var comeback_time: int = 3

var red_flags_captured: int = 0
var blue_flags_captured: int = 0
var _spawn_counter_red: int = 0
var _spawn_counter_blue: int = 0
var _time_remained: int

var _red_flag_scene: PackedScene = preload("uid://cc2mkoa1fingr")
var _blue_flag_scene: PackedScene = preload("uid://cyudg7uces0wb")

@onready var _spawn_points_red: Array[Node] = $Map/SpawnPoints0.get_children()
@onready var _spawn_points_blue: Array[Node] = $Map/SpawnPoints1.get_children()
@onready var _red_flag_spawn_point: Node2D = $Map/RedFlag
@onready var _blue_flag_spawn_point: Node2D = $Map/BlueFlag
@onready var _flag_capture_ui: FlagCaptureUI = $UI


func _initialize() -> void:
	_spawn_points_blue.shuffle()
	_spawn_points_red.shuffle()
	
	_flag_capture_ui.set_time(match_time)
	_flag_capture_ui.set_flags(red_flags_captured, blue_flags_captured)
	_time_remained = match_time
	
	if multiplayer.is_server():
		_spawn_counter_red = randi() % 5
		_spawn_counter_blue = randi() % 5
	
	($FlagZoneRed as Node2D).position = _red_flag_spawn_point.position
	($FlagZoneBlue as Node2D).position = _blue_flag_spawn_point.position


func _make_teams() -> void:
	var next_team: int = -1
	for player: int in players_names:
		if next_team < 0:
			var team: int = randi() % 2
			players_teams[player] = team
			next_team = 1 - team
		else:
			players_teams[player] = next_team
			next_team = -1


func _finish_start() -> void:
	if multiplayer.is_server():
		if not (players_teams.find_key(0) and players_teams.find_key(1)):
			_time_remained = 1
		($MatchTimer as Timer).start()
		_spawn_flag(false)
		_spawn_flag(true)


func _get_spawn_point(id: int) -> Vector2:
	var pos: Vector2
	if players_teams[id] == 0:
		pos = (_spawn_points_red[_spawn_counter_red % 5] as Node2D).global_position
		_spawn_counter_red += 1
	else:
		pos = (_spawn_points_blue[_spawn_counter_blue % 5] as Node2D).global_position
		_spawn_counter_blue += 1
	return pos


func _player_killed(who: int, _by: int) -> void:
	_respawn_player(who)


func _player_disconnected(_id: int) -> void:
	if _time_remained <= 0:
		return
	# Недостаточно участников команд
	if not (players_teams.find_key(0) and players_teams.find_key(1)):
		_time_remained = 1


@rpc("unreliable_ordered", "call_local", "authority", 3)
func _update_time(remained: int) -> void:
	_flag_capture_ui.set_time(remained)


@rpc("reliable", "call_local", "authority", 3)
func _update_score(red: int, blue: int, blue_captured: bool) -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	red_flags_captured = red
	blue_flags_captured = blue
	_flag_capture_ui.set_flags(red_flags_captured, blue_flags_captured)
	_flag_capture_ui.show_flag_captured(blue_captured)
	print_verbose("Team %d captured flag." % int(blue_captured))
	print_verbose("Current score: %d - %d." % [red_flags_captured, blue_flags_captured])


@rpc("reliable", "call_local", "authority", 3)
func _show_winner(team: int) -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	end_event(team == local_team)
	_flag_capture_ui.show_winner(team)
	print_verbose("Team won: %d." % team)


func _respawn_player(id: int) -> void:
	await get_tree().create_timer(comeback_time, false).timeout
	if _time_remained > 0 and id in players_names:
		spawn_player(id)


func _spawn_flag(blue: bool) -> void:
	var flag: Flag = (_blue_flag_scene if blue else _red_flag_scene).instantiate()
	flag.name += str(randi())
	flag.position = (_blue_flag_spawn_point if blue else _red_flag_spawn_point).position
	$Other.add_child(flag)


func _end_event() -> void:
	if not players_teams.find_key(0): # Нет красных больше
		_show_winner.rpc(1)
	elif not players_teams.find_key(1): # Нет синих больше
		_show_winner.rpc(0)
	elif red_flags_captured > blue_flags_captured:
		_show_winner.rpc(0)
	elif blue_flags_captured > red_flags_captured:
		_show_winner.rpc(1)
	else:
		_show_winner.rpc(-1)
	freeze_players.rpc()
	await get_tree().create_timer(6.5).timeout
	cleanup()
	await get_tree().create_timer(0.5).timeout
	end.rpc()


func _on_local_player_died() -> void:
	_flag_capture_ui.show_comeback(comeback_time)


func _on_local_player_created(player: Player) -> void:
	player.died.connect(_on_local_player_died.unbind(1))


func _on_match_timer_timeout() -> void:
	_time_remained -= 1
	_update_time.rpc(_time_remained)
	if _time_remained <= 0:
		($MatchTimer as Timer).stop()
		_end_event()


func _on_flag_zone_red_flag_captured() -> void:
	red_flags_captured += 1
	_update_score.rpc(red_flags_captured, blue_flags_captured, false)
	_spawn_flag.call_deferred(true)


func _on_flag_zone_blue_flag_captured() -> void:
	blue_flags_captured += 1
	_update_score.rpc(red_flags_captured, blue_flags_captured, true)
	_spawn_flag.call_deferred(false)
