# meta-name: Оружие
# meta-description: Содержит методы, переопределив которые можно создать новое оружие.
# meta-default: true
extends _BASE_


func _initialize() -> void:
_TS_pass


func _shoot() -> void:
_TS_pass


func _make_current() -> void:
_TS_pass


func _unmake_current() -> void:
_TS_pass


#func _can_reload() -> bool:
_TS_#return # Пишите дополнительные условия тут (или false если не должно перезаряжаться)


#func _can_use_additional_button() -> bool:
_TS_#return # Пишите условия тут


#func _player_disarmed() -> void:
_TS_#pass


#func _player_armed() -> void:
_TS_#pass


#func _ammo_changed(in_stock: bool) -> void:
_TS_#pass


# Удалите, если оружие не должно перезаряжаться
func reload() -> void:
_TS_pass


#func get_reload_args() -> Array:
_TS_#return []


#func additional_button() -> void:
_TS_#pass


#func get_additional_button_args() -> Array:
_TS_#return []


#func has_additional_button() -> bool:
_TS_#return true


#func get_ammo_text() -> String:
_TS_#return # Составляйте новый текст тут