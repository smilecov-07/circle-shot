class_name Projectile
extends Attack

## Снаряд.
##
## Базовый класс для атаки, летящей в определённом направлении.[br]
## [b]Заметка[/b]: не забывайте вызывать [code]super()[/code] в [method Node._ready]
## и в [method Node._physics_process], если Вы переопределяете их
## (если, конечно, не хотите переопределить их логику).

## Издаётся, когда снаряд куда-то попадает.
signal hit(where: Vector2)
## Скорость снаряда.
@export var speed := 1280.0
## Эффект попадания снаряда.
@export var hit_vfx_scene: PackedScene
## Направление движения снаряда. Устанавливается в [method Node._ready] из [member Node2D.rotation].
var direction: Vector2
var _was_hit := false


func _ready() -> void:
	direction = Vector2.from_angle(rotation)


func _physics_process(delta: float) -> void:
	position += speed * direction * delta


@rpc("unreliable", "call_local", "authority", 5)
func _hit(where: Vector2) -> void:
	if _was_hit:
		return
	
	_was_hit = true
	hit.emit(where)
	for rd: RayDetector in ray_detectors:
		rd.enabled = false
	for sd: ShapeDetector in shape_detectors:
		sd.enabled = false
	
	if hit_vfx_scene:
		var vfx_parent: Node = get_tree().get_first_node_in_group(&"VfxParent")
		if is_instance_valid(vfx_parent):
			var vfx: Node2D = hit_vfx_scene.instantiate()
			vfx.global_position = where
			vfx.rotation = rotation
			vfx_parent.add_child(vfx)
	
	await get_tree().physics_frame
	hide()


func _on_detector_hit(where: Vector2) -> void:
	if multiplayer.is_server():
		_hit.rpc(where)
	else:
		_hit(where)


func _on_timer_timeout() -> void:
	if multiplayer.is_server():
		queue_free()
