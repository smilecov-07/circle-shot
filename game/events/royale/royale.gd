class_name Royale
extends Event

## Событие "Королевская битва".

## Базовый интервал появления аптечек.
@export var heal_box_spawn_interval_base := 30.0
## Увеличение интервала появления аптечек за каждого живого игрока.
@export var heal_box_spawn_interval_per_player := 2.0
## Базовый интервал появления коробок с боеприпасами.
@export var ammo_box_spawn_interval_base := 40.0
## Увеличение интервала появления коробок с боеприпасами за каждого живого игрока.
@export var ammo_box_spawn_interval_per_player := 2.5
## Время, за которое ядовитый дым покроет всю карту.
@export var poison_smoke_time := 400.0

var _spawn_counter: int = 0
var _heal_box_counter: int = 0
var _ammo_box_counter: int = 0
var _alive_players: Array[int]

var _heal_box_scene: PackedScene = preload("uid://bysyaaj2r7stt")
var _ammo_box_scene: PackedScene = preload("uid://bdtqr6mv231py")

@onready var _spawn_points: Array[Node] = $Map/SpawnPoints.get_children()
@onready var _heal_box_points: Array[Node] = $Map/HealPoints.get_children()
@onready var _ammo_box_points: Array[Node] = $Map/AmmoPoints.get_children()
@onready var _royale_ui: RoyaleUI = $UI


func _initialize() -> void:
	_spawn_points.shuffle()
	_heal_box_points.shuffle()
	_ammo_box_points.shuffle()


func _finish_start() -> void:
	if multiplayer.is_server():
		_alive_players = _players_names.keys()
		($HealBoxSpawnTimer as Timer).start(heal_box_spawn_interval_base
				+ heal_box_spawn_interval_per_player * _alive_players.size())
		($AmmoBoxSpawnTimer as Timer).start(ammo_box_spawn_interval_base
				+ ammo_box_spawn_interval_per_player * _alive_players.size())
		_royale_ui.set_alive_players.rpc(_alive_players.size())
		_check_winner()
	for smoke: Node2D in $PoisonSmoke.get_children():
		var tween: Tween = smoke.create_tween()
		tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tween.tween_property(smoke, ^":position", Vector2.ZERO, poison_smoke_time)


func _make_teams() -> void:
	var counter: int = 0
	var teams: Array = range(0, 10)
	teams.shuffle()
	for player: int in _players_names:
		_players_teams[player] = teams[counter]
		counter += 1


func _get_spawn_point(_id: int) -> Vector2:
	var pos: Vector2 = (_spawn_points[_spawn_counter] as Node2D).global_position
	_spawn_counter += 1
	return pos


func _player_killed(who: int, by: int) -> void:
	_alive_players.erase(who)
	_royale_ui.set_alive_players.rpc(_alive_players.size())
	_royale_ui.kill_player.rpc(who, by)
	_check_winner()


func _player_disconnected(id: int) -> void:
	_alive_players.erase(id)
	_royale_ui.set_alive_players.rpc(_alive_players.size())
	_royale_ui.kill_player.rpc(id)
	_check_winner()


func _spawn_heal_box() -> void:
	var spawn_position: Vector2 = (_heal_box_points[_heal_box_counter] as Node2D).global_position
	var heal_box: Area2D = _heal_box_scene.instantiate()
	heal_box.position = spawn_position
	heal_box.name += str(randi())
	$Other.add_child(heal_box)
	_heal_box_counter += 1
	if _heal_box_counter == _heal_box_points.size():
		_heal_box_counter = 0
		_heal_box_points.shuffle()


func _spawn_ammo_box() -> void:
	var spawn_position: Vector2 = (_ammo_box_points[_ammo_box_counter] as Node2D).global_position
	var ammo_box: Area2D = _ammo_box_scene.instantiate()
	ammo_box.global_position = spawn_position
	ammo_box.name += str(randi())
	$Other.add_child(ammo_box)
	_ammo_box_counter += 1
	if _ammo_box_counter == _ammo_box_points.size():
		_ammo_box_counter = 0
		_ammo_box_points.shuffle()


func _check_winner() -> void:
	if _alive_players.size() != 1:
		return
	var winner_id: int = _alive_players[0]
	var winner_name: String = _players_names[winner_id]
	_royale_ui.show_winner.rpc(winner_id, winner_name)
	($HealBoxSpawnTimer as Timer).stop()
	($AmmoBoxSpawnTimer as Timer).stop()
	await get_tree().create_timer(6.5).timeout
	cleanup()
	await get_tree().create_timer(0.5).timeout
	end.rpc()


func _on_local_player_died(_who: int) -> void:
	_royale_ui.show_defeat()


func _on_local_player_created(player: Player) -> void:
	player.died.connect(_on_local_player_died)


func _on_heal_box_spawn_timer_timeout() -> void:
	_spawn_heal_box()
	if _players.is_empty():
		return
	($HealBoxSpawnTimer as Timer).start(heal_box_spawn_interval_base
			+ heal_box_spawn_interval_per_player * _alive_players.size())


func _on_ammo_box_spawn_timer_timeout() -> void:
	_spawn_ammo_box()
	if _players.is_empty():
		return
	($AmmoBoxSpawnTimer as Timer).start(ammo_box_spawn_interval_base
			+ ammo_box_spawn_interval_per_player * _alive_players.size())
