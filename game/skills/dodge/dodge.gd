extends Skill


@export var roll_speed := 1280.0
@export var roll_duration := 0.5
@export var additional_invincibility := 0.1

var _roll_direction := Vector2.RIGHT
var _aim_dodge: bool
@onready var _roll_timer: Timer = $Timer


func _physics_process(delta: float) -> void:
	super(delta)
	if multiplayer.is_server():
		if _aim_dodge:
			_roll_direction = player.player_input.aim_direction
		elif not player.entity_input.direction.is_zero_approx():
			_roll_direction = player.entity_input.direction


func get_use_args() -> Array:
	return [_roll_direction.normalized()]


func _initialize() -> void:
	if player.is_local():
		_set_aim_dodge.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER, \
				Globals.get_setting_bool("aim_dodge"))


func _use(direction := Vector2.RIGHT) -> void:
	block_cooldown()
	player.make_disarmed()
	player.make_immobile()
	player.knockback = direction * roll_speed
	var previous_collision_layer: int = player.collision_layer
	player.collision_layer = 0
	
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(player.visual, ^":rotation", TAU * player.visual.scale.x, roll_duration)
	tween.tween_callback(func() -> void: player.visual.rotation = 0.0)
	
	_roll_timer.start(roll_duration)
	await _roll_timer.timeout
	
	player.unmake_disarmed()
	player.unmake_immobile()
	player.knockback = Vector2.ZERO
	
	_roll_timer.start(additional_invincibility)
	await _roll_timer.timeout
	
	player.collision_layer = previous_collision_layer
	unblock_cooldown()


@rpc("reliable", "call_local", "any_peer", 5)
func _set_aim_dodge(aim_dodge: bool) -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client.")
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	if player.id != sender_id:
		push_warning("RPC Sender ID (%d) doesn't match with player ID (%d)." % [
			sender_id,
			player.id,
		])
		return
	
	_aim_dodge = aim_dodge
