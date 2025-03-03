extends Grenade


func _customize_projectile(projectile: GrenadeProjectile) -> void:
	for attack: Attack in projectile.get_node(^"Explosion/Attacks").get_children():
		attack.who = player.id
		attack.team = player.team
		attack.damage_multiplier = player.damage_multiplier
