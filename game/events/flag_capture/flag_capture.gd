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


func _respawn_player(id: int) -> void:
	await get_tree().create_timer(comeback_time, false).timeout
	if _time_remained > 0 and id in players_names:
		spawn_player(id)


func _determine_winner() -> void:
	if not players_teams.find_key(0): # Нет красных больше
		_flag_capture_ui.show_winner.rpc(1)
	elif not players_teams.find_key(1): # Нет синих больше
		_flag_capture_ui.show_winner.rpc(0)
	elif red_flags_captured > blue_flags_captured:
		_flag_capture_ui.show_winner.rpc(0)
	elif blue_flags_captured > red_flags_captured:
		_flag_capture_ui.show_winner.rpc(1)
	else:
		_flag_capture_ui.show_winner.rpc(-1)
	freeze_players.rpc()
	await get_tree().create_timer(6.5).timeout
	cleanup()
	await get_tree().create_timer(0.5).timeout
	end.rpc()


func _on_local_player_created(player: Player) -> void:
	player.died.connect(_flag_capture_ui.show_comeback.unbind(1).bind(comeback_time))


func _on_match_timer_timeout() -> void:
	_time_remained -= 1
	_update_time.rpc(_time_remained)
	if _time_remained <= 0:
		($MatchTimer as Timer).stop()
		_determine_winner()
