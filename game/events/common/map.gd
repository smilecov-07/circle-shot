class_name Map
extends Node2D
## Базовый класс для карт.

## Список треков для этой карты. Если не пуст, переопределяет заданные в [Event].
@export var custom_tracks: Array[AudioStream]
## Ссылка на [Event] этой карты.
@onready var event: Event = get_parent()

func _ready() -> void:
	if not custom_tracks.is_empty():
		event.tracks = custom_tracks
	_initialize()


## Вирутальный метод для инициализации карты. Для доступа к событию используйте [member event].
func _initialize() -> void:
	pass
