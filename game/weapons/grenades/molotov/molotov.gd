extends Grenade


func _customize_projectile(projectile: GrenadeProjectile) -> void:
	(projectile.get_node(^"Attack") as Attack).team = player.team
	(projectile.get_node(^"Attack") as Attack).who = player.id
	(projectile.get_node(^"Attack") as Attack).damage_multiplier = player.damage_multiplier
