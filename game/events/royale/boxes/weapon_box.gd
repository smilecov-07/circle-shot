extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return
	var player := body as Player
	if not player:
		return
	if player.equip_data[6] != -1:
		return
	(get_tree().get_first_node_in_group(&"Event") as Royale).equip_weapon.rpc(player.id)
	queue_free()


func _on_despawn_timer_timeout() -> void:
	($AnimationPlayer as AnimationPlayer).play(&"Despawn")
	if multiplayer.is_server():
		await ($AnimationPlayer as AnimationPlayer).animation_finished
		queue_free()
