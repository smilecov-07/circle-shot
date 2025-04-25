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
## Базовый интервал появления подбираемых оружий.
@export var weapon_box_spawn_interval_base := 50.0
## Увеличение интервала появления подбираемых оружий за каждого живого игрока.
@export var weapon_box_spawn_interval_per_player := 10.0
## Сцена подбираемого оружия (для предзагрузки).
@export var weapon_scene: PackedScene
## Данные подбираемого оружия.
@export var weapon_data: WeaponData

var _spawn_counter: int = 0
var _heal_box_counter: int = 0
var _ammo_box_counter: int = 0
var _weapon_box_counter: int = 0
var _alive_players: Array[int]

var _heal_box_scene: PackedScene = preload("uid://bysyaaj2r7stt")
var _ammo_box_scene: PackedScene = preload("uid://bdtqr6mv231py")
var _weapon_box_scene: PackedScene = preload("uid://bbfq36qds2oip")
var _poison_smokes_scene: PackedScene = preload("uid://cr1m37xm3w88w")

@onready var _spawn_points: Array[Node] = $Map/SpawnPoints.get_children()
@onready var _heal_box_points: Array[Node] = $Map/HealPoints.get_children()
@onready var _ammo_box_points: Array[Node] = $Map/AmmoPoints.get_children()
@onready var _weapon_box_points: Array[Node] = $Map/WeaponBoxPoints.get_children()
@onready var _royale_ui: RoyaleUI = $UI


func _initialize() -> void:
	_spawn_points.shuffle()
	_heal_box_points.shuffle()
	_ammo_box_points.shuffle()
	_weapon_box_points.shuffle()


func _finish_start() -> void:
	var smokes: Node2D = _poison_smokes_scene.instantiate()
	add_child(smokes)
	var tween: Tween = smokes.create_tween()
	tween.tween_property(smokes, ^":modulate", smokes.modulate, 0.3).from(Color.TRANSPARENT)
	if multiplayer.is_server():
		_alive_players = _players_names.keys()
		($HealBoxSpawnTimer as Timer).start(heal_box_spawn_interval_base
				+ heal_box_spawn_interval_per_player * _alive_players.size())
		($AmmoBoxSpawnTimer as Timer).start(ammo_box_spawn_interval_base
				+ ammo_box_spawn_interval_per_player * _alive_players.size())
		($WeaponBoxSpawnTimer as Timer).start(weapon_box_spawn_interval_base
				+ weapon_box_spawn_interval_per_player * _alive_players.size())
		_royale_ui.set_alive_players.rpc(_alive_players.size())
		_check_winner()


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


## Устанавливает у игрока с ID [param to] оружие [member weapon_data].
@rpc("authority", "call_local", "reliable", 5)
func equip_weapon(to: int) -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	for player: Player in get_tree().get_nodes_in_group(&"Player"):
		if player.id == to:
			player.set_weapon(Weapon.Type.ADDITIONAL, weapon_data)
			break


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
	ammo_box.position = spawn_position
	ammo_box.name += str(randi())
	$Other.add_child(ammo_box)
	_ammo_box_counter += 1
	if _ammo_box_counter == _ammo_box_points.size():
		_ammo_box_counter = 0
		_ammo_box_points.shuffle()


func _spawn_weapon() -> void:
	var spawn_position: Vector2 = \
			(_weapon_box_points[_weapon_box_counter] as Node2D).global_position
	var weapon_box: Area2D = _weapon_box_scene.instantiate()
	weapon_box.position = spawn_position
	weapon_box.name += str(randi())
	$Other.add_child(weapon_box)
	_weapon_box_counter += 1
	if _weapon_box_counter == _weapon_box_points.size():
		_weapon_box_counter = 0
		_weapon_box_points.shuffle()


func _check_winner() -> void:
	if _alive_players.size() != 1:
		return
	var winner_id: int = _alive_players[0]
	var winner_name: String = _players_names[winner_id]
	_royale_ui.show_winner.rpc(winner_id, winner_name)
	freeze_players.rpc()
	($HealBoxSpawnTimer as Timer).stop()
	($AmmoBoxSpawnTimer as Timer).stop()
	($WeaponBoxSpawnTimer as Timer).stop()
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
	($HealBoxSpawnTimer as Timer).start(heal_box_spawn_interval_base
			+ heal_box_spawn_interval_per_player * _alive_players.size())


func _on_ammo_box_spawn_timer_timeout() -> void:
	_spawn_ammo_box()
	($AmmoBoxSpawnTimer as Timer).start(ammo_box_spawn_interval_base
			+ ammo_box_spawn_interval_per_player * _alive_players.size())


func _on_weapon_spawn_timer_timeout() -> void:
	_spawn_weapon()
	($WeaponBoxSpawnTimer as Timer).start(weapon_box_spawn_interval_base
			+ weapon_box_spawn_interval_per_player * _alive_players.size())
