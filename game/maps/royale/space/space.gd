extends Node2D

@export var custom_tracks: Array[AudioStream]

func _ready() -> void:
	(get_parent() as Event).tracks = custom_tracks
