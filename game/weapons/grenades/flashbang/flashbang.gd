extends Grenade


func _customize_projectile(projectile: GrenadeProjectile) -> void:
	(projectile.get_node(^"Explosion/Attack") as Attack).team = player.team
	(projectile.get_node(^"Explosion/Attack") as Attack).who = player.id
