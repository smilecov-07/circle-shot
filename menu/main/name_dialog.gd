extends AcceptDialog

signal name_accepted

func _ready() -> void:
	register_text_enter($LineEdit as LineEdit)


func _on_confirmed() -> void:
	var result: Array[bool]
	var player_name: String = Game.validate_player_name(($LineEdit as LineEdit).text, 0, result)
	($LineEdit as LineEdit).clear()
	if not result[0]:
		($LineEdit as LineEdit).placeholder_text = "Недопустимое имя!"
		return
	Globals.set_string("player_name", player_name)
	name_accepted.emit()
	hide()
	print_verbose("Name set: %s." % player_name)
