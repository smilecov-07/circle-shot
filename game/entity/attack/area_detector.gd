class_name AreaDetector
extends Area2D
## Детектор в виде [Area2D] для [Attack].

var _entities: Array[Entity]
@onready var _attack: Attack = get_parent()


func _ready() -> void:
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)


func _physics_process(_delta: float) -> void:
	for entity: Entity in _entities:
		_attack.deal_damage(entity)


func _on_body_entered(body: Node2D) -> void:
	var entity := body as Entity
	if not entity:
		return
	_entities.append(entity)


func _on_body_exited(body: Node2D) -> void:
	var entity := body as Entity
	if not entity:
		return
	_entities.erase(entity)
