extends Node

@onready var _anim: AnimationPlayer = $TileMapLayers/AnimationPlayer

func _ready() -> void:
	var duel: Duel = get_parent()
	duel.round_started.connect(_on_round_started)
	duel.round_ended.connect(_on_round_ended)


func _on_round_started() -> void:
	_anim.play(&"Dance")


func _on_round_ended(team_won: int) -> void:
	if team_won == 0:
		_anim.play(&"RedWon")
	else:
		_anim.play(&"BlueWon")
