extends PanelContainer

@export var idx: int
@onready var _lobby: Lobby = owner.owner # PresetManager тоже сцена

func _ready() -> void:
	($RenameDialog as AcceptDialog).register_text_enter(%NameEdit as LineEdit)
	if not Globals.get_string("preset_%d_name" % idx).is_empty():
		_show_data()
	else:
		_show_empty()


func _show_data() -> void:
	($Main as CanvasItem).show()
	($Empty as CanvasItem).hide()
	var data: Array[String] = Globals.get_variant("preset_%d_data" % idx, [] as Array[String])
	(%Skill as TextureRect).texture = load(Globals.items_db.skills_by_id[data[0]].image_path)
	(%Light as TextureRect).texture = load(Globals.items_db.weapons_by_id[data[1]].image_path)
	(%Heavy as TextureRect).texture = load(Globals.items_db.weapons_by_id[data[2]].image_path)
	(%Support as TextureRect).texture = load(Globals.items_db.weapons_by_id[data[3]].image_path)
	(%Melee as TextureRect).texture = load(Globals.items_db.weapons_by_id[data[4]].image_path)
	(%PresetName as Label).text = Globals.get_string("preset_%d_name" % idx)


func _show_empty() -> void:
	($Main as CanvasItem).hide()
	($Empty as CanvasItem).show()


func _on_add_pressed() -> void:
	Globals.set_string("preset_%d_name" % idx, "Предустановка %d" % idx)
	Globals.set_variant("preset_%d_data" % idx, [
		_lobby.selected_skill,
		_lobby.selected_light_weapon,
		_lobby.selected_heavy_weapon,
		_lobby.selected_support_weapon,
		_lobby.selected_melee_weapon,
	] as Array[String])
	_show_data()


func _on_save_pressed() -> void:
	Globals.set_variant("preset_%d_data" % idx, [
		_lobby.selected_skill,
		_lobby.selected_light_weapon,
		_lobby.selected_heavy_weapon,
		_lobby.selected_support_weapon,
		_lobby.selected_melee_weapon,
	] as Array[String])
	_show_data()


func _on_load_pressed() -> void:
	var data: Array[String] = Globals.get_variant("preset_%d_data" % idx, [] as Array[String])
	_lobby.selected_skill = data[0]
	_lobby.selected_light_weapon = data[1]
	_lobby.selected_heavy_weapon = data[2]
	_lobby.selected_support_weapon = data[3]
	_lobby.selected_melee_weapon = data[4]
	_lobby.update_selected()


func _on_rename_pressed() -> void:
	(%NameEdit as LineEdit).clear()
	($RenameDialog as Window).title = 'Переименовывание "%s"' \
			% Globals.get_string("preset_%d_name" % idx)
	($RenameDialog as Window).popup_centered()
	(%NameEdit as LineEdit).grab_focus()


func _on_delete_pressed() -> void:
	Globals.set_string("preset_%d_name" % idx, "")
	Globals.set_variant("preset_%d_data" % idx, [] as Array[String])
	_show_empty()


func _on_rename_dialog_confirmed() -> void:
	Globals.set_string("preset_%d_name" % idx, Utils.strip_string((%NameEdit as LineEdit).text))
	(%PresetName as Label).text = Globals.get_string("preset_%d_name" % idx)
