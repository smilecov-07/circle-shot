extends Grenade


func _customize_projectile(projectile: GrenadeProjectile) -> void:
	var attack: Attack = projectile.get_node(^"Explosion/Attack")
	attack.who = player.id
	attack.team = player.team
	attack.damage_multiplier = player.damage_multiplier
