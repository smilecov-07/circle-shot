extends PlayerSkin


@export var idle_scarf_amplitude := 0.1
@export var walk_scarf_amplitude := 0.2
@export var reach_angle_speed := 20.0
var _last_walk_angle := 0.0
var _last_rotation := 0.0
@onready var _scarfes: Node2D = $Scarfes


func _initialize() -> void:
	player.health_changed.connect(_on_player_health_changed)


func _process(delta: float) -> void:
	if not player.velocity.is_zero_approx():
		_last_walk_angle = player.velocity.angle()
	_scarfes.global_rotation = lerp_angle(_last_rotation, _last_walk_angle,
			reach_angle_speed * delta)
	_last_rotation = _scarfes.global_rotation
	for child: CanvasItem in _scarfes.get_children():
		child.set_instance_shader_parameter(&"amplitude", lerpf(idle_scarf_amplitude,
				walk_scarf_amplitude, player.entity_input.direction.length_squared()))


func _on_player_health_changed(old: int, new: int) -> void:
	if old < new:
		($AnimationPlayer as AnimationPlayer).play(&"Heal")
		($AnimationPlayer as AnimationPlayer).seek(0.0)
