extends Projectile


func _ready() -> void:
	super()
	var tween: Tween = create_tween()
	tween.tween_property($Sprite2D as Node2D, ^":scale:x", 1.0, 0.25).from(0.1)
