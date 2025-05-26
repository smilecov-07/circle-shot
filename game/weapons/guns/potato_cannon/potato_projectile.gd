extends Projectile

@export var bounce_margin := 8.0

func _process_hit(where: Vector2, what: Entity) -> void:
	var normal: Vector2 = ray_detectors[0].get_collision_normal()
	if what or normal.is_zero_approx():
		if multiplayer.is_server():
			_destroy.rpc(where)
		else:
			_destroy(where)
		return
	
	var remainder: float = where.distance_to(position)
	direction = direction.bounce(normal)
	rotation = direction.angle()
	position = where + (remainder + bounce_margin) * direction
	
	var vfx_parent: Node = get_tree().get_first_node_in_group(&"VfxParent")
	if is_instance_valid(vfx_parent):
		var vfx: Node2D = hit_vfx_scene.instantiate()
		vfx.position = where
		vfx_parent.add_child(vfx)
