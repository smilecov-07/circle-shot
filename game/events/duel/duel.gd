class_name Duel
extends Event

## Событие "Дуэль".

## Издаётся когда раунд начался.
signal round_started
## Издаётся когда раунд закончился. [param team_won] - ID победившей команды.
signal round_ended(team_won: int)

var _red_rounds_won: int = 0
var _blue_rounds_won: int = 0
var _current_round: int = 0
var _poison_smokes_scene: PackedScene = preload("uid://cp5ag64gc1s3k")

@onready var _duel_ui: DuelUI = $UI


func _make_teams() -> void:
	var prev_team: int = -1
	var players_ids: Array[int] = players_names.keys()
	players_ids.shuffle()
	for player: int in players_ids:
		if prev_team < 0:
			players_teams[player] = randi() % 2
			prev_team = players_teams[player]
		else:
			players_teams[player] = 1 - prev_team


func _finish_start() -> void:
	if multiplayer.is_server():
		_start_round.rpc()


func _get_spawn_point(id: int) -> Vector2:
	if players_teams[id] == 0:
		return ($Map/SpawnPoint0 as Node2D).global_position
	else:
		return ($Map/SpawnPoint1 as Node2D).global_position


func _customize_player(player: Player) -> void:
	match _current_round:
		0:
			player.equip_data[3] = -1
		1:
			player.equip_data[2] = -1
		2:
			player.equip_data[2] = -1
			player.equip_data[3] = -1


func _player_killed(who: int, _by: int) -> void:
	var team_won: int = 1 - players_teams[who]
	if team_won == 1:
		_blue_rounds_won += 1
	else:
		_red_rounds_won += 1
	if _current_round == 2 or _blue_rounds_won >= 2 or _red_rounds_won >= 2:
		if _blue_rounds_won > _red_rounds_won:
			_end_round.rpc(team_won, players_teams.find_key(1), true)
		else:
			_end_round.rpc(team_won, players_teams.find_key(0), true)
	else:
		_end_round.rpc(team_won, players_teams.find_key(team_won))


func _player_disconnected(_id: int) -> void:
	if _current_round > 2: # Игра завершена
		return
	if not was_started:
		return
	_end_round.rpc(players_teams.values()[0], players_teams.keys()[0], true)


@rpc("reliable", "call_local", "authority", 3)
func _start_round() -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	
	_duel_ui.start_round(_current_round)
	var smokes: Node2D = _poison_smokes_scene.instantiate()
	add_child(smokes)
	var tween: Tween = smokes.create_tween()
	tween.tween_property(smokes, ^":modulate", smokes.modulate, 0.3).from(Color.TRANSPARENT)
	round_started.emit()
	
	if multiplayer.is_server():
		if players_names.size() == 1:
			_end_round.rpc(players_teams.values()[0], players_teams.keys()[0], true)


@rpc("reliable", "call_local", "authority", 3)
func _end_round(win_team: int, winner: int, ends := false) -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	
	_duel_ui.end_round(_current_round, win_team, winner, ends)
	if ends:
		_current_round = 3
	else:
		_current_round += 1
	
	if has_node(^"PoisonSmokes"):
		var tween: Tween = $PoisonSmokes.create_tween()
		tween.tween_property($PoisonSmokes, ^":modulate", Color.TRANSPARENT, 0.3)
		tween.tween_callback($PoisonSmokes.queue_free)
	
	get_tree().call_group(&"Player", &"block_weapon_usage")
	get_tree().call_group(&"Player", &"make_immobile")
	get_tree().call_group(&"Player", &"make_immune")
	get_tree().call_group(&"Player", &"block_turning")
	
	round_ended.emit(win_team)
	if not multiplayer.is_server():
		return
	
	await get_tree().create_timer(3.5).timeout
	if ends:
		await get_tree().create_timer(3.0).timeout
	cleanup()
	await get_tree().create_timer(0.5).timeout
	if ends:
		end.rpc()
	elif _current_round < 3:
		for player: int in players_names:
			spawn_player(player)
		_start_round.rpc()
