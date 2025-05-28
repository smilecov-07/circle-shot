class_name ItemsGrid
extends GridContainer

## Сеточный контейнер с предметами.
##
## Этот контейнер может отобразить все предметы одного типа с помощью [method list_items].

## Этот сигнал издаётся, когда один из отображённых предметов нажат. Сигнал содержит
## тип предмета в [param type] и индекс предмета в [param id].
signal item_selected(type: ItemsDB.Item, idx: int)

var _item_big_scene: PackedScene = preload("uid://ck5uq0aa1ov56")
var _item_small_scene: PackedScene = preload("uid://c07pym82q5utt")


## Очищает существующие предметы и отображает новые того типа, который указан в [param type].
## Опционально можно предоставить индекс в базе данных в [param selected_idx],
## чтобы выделить зелёным выбранный предмет.[br]
## Чтобы показать скины из определённой линейки, оружия определённого типа или
## карты определённого события, используйте [method list_skins_line], [method list_weapons_by_type]
## или [method list_maps_of_event] соответственно.
func list_items(type: ItemsDB.Item, selected_idx: int = -1) -> void:
	for child: Node in get_children():
		child.queue_free()
	
	match type:
		ItemsDB.Item.EVENT:
			columns = 1
			var counter: int = 0
			for event: EventData in Globals.items_db.events:
				var item: TextureRect = _item_big_scene.instantiate()
				item.texture = load(event.image_path)
				(item.get_node(^"Container/Name") as Label).text = event.name
				if selected_idx == counter:
					(item.get_node(^"Container/Name") as Label).add_theme_color_override(
							&"font_color", Color.GREEN)
				(item.get_node(^"Container/Description") as Label).text = event.brief_description
				(item.get_node(^"Click") as BaseButton).pressed.connect(
						_on_item_pressed.bind(type, counter))
				add_child(item)
				counter += 1
		ItemsDB.Item.SKINS_LINE:
			columns = 1
			var counter: int = 0
			for skins_line: SkinsLineData in Globals.items_db.skins_lines:
				var item: TextureRect = _item_big_scene.instantiate()
				item.texture = load(skins_line.image_path)
				(item.get_node(^"Container/Name") as Label).text = skins_line.name
				if selected_idx == counter:
					(item.get_node(^"Container/Name") as Label).add_theme_color_override(
							&"font_color", Color.GREEN)
				(item.get_node(^"Container/Description") as Label).text = \
						skins_line.brief_description
				(item.get_node(^"Click") as BaseButton).pressed.connect(
						_on_item_pressed.bind(type, counter))
				add_child(item)
				counter += 1
		ItemsDB.Item.SKIN:
			columns = 3
			for skin: SkinData in Globals.items_db.skins:
				if skin in Globals.items_db.other_skins:
					continue
				var item: TextureRect = _item_small_scene.instantiate()
				item.texture = load(skin.image_path)
				(item.get_node(^"Name") as Label).text = skin.name
				if selected_idx == skin.idx_in_db:
					(item.get_node(^"Name") as Label).add_theme_color_override(
							&"font_color", Color.GREEN)
				(item.get_node(^"Description") as Label).text = skin.brief_description
				(item.get_node(^"Description") as Label).horizontal_alignment = \
						HORIZONTAL_ALIGNMENT_CENTER
				(item.get_node(^"RarityFill") as ColorRect).color = \
						ItemsDB.RARITY_COLORS[skin.rarity]
				(item.get_node(^"Click") as BaseButton).pressed.connect(
						_on_item_pressed.bind(type, skin.idx_in_db))
				add_child(item)
		ItemsDB.Item.SKILL:
			columns = 3
			for skill: SkillData in Globals.items_db.skills:
				if skill in Globals.items_db.other_skills:
					continue
				var item: TextureRect = _item_small_scene.instantiate()
				item.texture = load(skill.image_path)
				(item.get_node(^"Name") as Label).text = skill.name
				if selected_idx == skill.idx_in_db:
					(item.get_node(^"Name") as Label).add_theme_color_override(
							&"font_color", Color.GREEN)
				(item.get_node(^"Description") as Label).text = "%s\n%s" % [
					skill.brief_description.format(skill.stats),
					skill.usage_text.format(skill.stats),
				]
				(item.get_node(^"RarityFill") as ColorRect).color = \
						ItemsDB.RARITY_COLORS[skill.rarity]
				(item.get_node(^"Click") as BaseButton).pressed.connect(
						_on_item_pressed.bind(type, skill.idx_in_db))
				add_child(item)
		ItemsDB.Item.WEAPON:
			columns = 3
			for weapon: WeaponData in Globals.items_db.weapons:
				if weapon in Globals.items_db.other_weapons:
					continue
				var item: TextureRect = _item_small_scene.instantiate()
				item.texture = load(weapon.image_path)
				(item.get_node(^"Name") as Label).text = weapon.name
				if selected_idx == weapon.idx_in_db:
					(item.get_node(^"Name") as Label).add_theme_color_override(
							&"font_color", Color.GREEN)
				(item.get_node(^"Description") as Label).text = "%s\n%s" % [
					weapon.ammo_text.format(weapon.stats),
					weapon.damage_text.format(weapon.stats),
				]
				(item.get_node(^"RarityFill") as ColorRect).color = \
						ItemsDB.RARITY_COLORS[weapon.rarity]
				(item.get_node(^"Click") as BaseButton).pressed.connect(
						_on_item_pressed.bind(type, weapon.idx_in_db))
				add_child(item)
		ItemsDB.Item.MAP:
			push_error("To list maps use list_maps_of_event().")
		_:
			push_error("Invalid type specified: %d." % type)


## Очищает существующие предметы и отображает карты события, ID которого указан в [param event_idx].
## Опционально можно предоставить индекс в базе данных в [param selected_idx],
## чтобы выделить зелёным выбранную карту.
func list_maps_of_event(event_idx: int, selected_idx: int = -1) -> void:
	for child: Node in get_children():
		child.queue_free()
	
	columns = 1
	var counter: int = 0
	for map: MapData in Globals.items_db.events[event_idx].maps:
		var item: TextureRect = _item_big_scene.instantiate()
		item.texture = load(map.image_path)
		(item.get_node(^"Container/Name") as Label).text = map.name
		if selected_idx == counter:
			(item.get_node(^"Container/Name") as Label).add_theme_color_override(
					&"font_color", Color.GREEN)
		(item.get_node(^"Container/Description") as Label).text = map.brief_description
		(item.get_node(^"Click") as BaseButton).pressed.connect(
				_on_item_pressed.bind(ItemsDB.Item.MAP, counter))
		add_child(item)
		counter += 1


## Очищает существующие предметы и отображает оружия, тип которых указан в [param type].
## Опционально можно предоставить индекс в базе данных в [param selected_idx],
## чтобы выделить зелёным выбранное оружие.
func list_weapons_by_type(type: Weapon.Type, selected_idx: int = -1) -> void:
	for child: Node in get_children():
		child.queue_free()
	
	var weapons_to_list: Array[WeaponData]
	match type:
		Weapon.Type.LIGHT:
			weapons_to_list = Globals.items_db.weapons_light
		Weapon.Type.HEAVY:
			weapons_to_list = Globals.items_db.weapons_heavy
		Weapon.Type.SUPPORT:
			weapons_to_list = Globals.items_db.weapons_support
		Weapon.Type.MELEE:
			weapons_to_list = Globals.items_db.weapons_melee
		_:
			push_error("Specified weapon type %d is invalid." % type)
			return
	
	columns = 3
	for weapon: WeaponData in weapons_to_list:
		var item: TextureRect = _item_small_scene.instantiate()
		item.texture = load(weapon.image_path)
		(item.get_node(^"Name") as Label).text = weapon.name
		if selected_idx == weapon.idx_in_db:
			(item.get_node(^"Name") as Label).add_theme_color_override(
					&"font_color", Color.GREEN)
		(item.get_node(^"Description") as Label).text = "%s\n%s" % [
			weapon.ammo_text.format(weapon.stats),
			weapon.damage_text.format(weapon.stats),
		]
		(item.get_node(^"RarityFill") as ColorRect).color = \
				ItemsDB.RARITY_COLORS[weapon.rarity]
		(item.get_node(^"Click") as BaseButton).pressed.connect(
				_on_item_pressed.bind(ItemsDB.Item.WEAPON, weapon.idx_in_db))
		add_child(item)


## Очищает существующие предметы и отображает скины из линейки, ID которой указан в [param line_id].
## Опционально можно предоставить индекс в базе данных в [param selected_idx],
## чтобы выделить зелёным выбранный скин.
func list_skins_line(line_idx: int, selected_idx: int = -1) -> void:
	for child: Node in get_children():
		child.queue_free()
	
	columns = 3
	for skin: SkinData in Globals.items_db.skins_lines[line_idx].skins:
		var item: TextureRect = _item_small_scene.instantiate()
		item.texture = load(skin.image_path)
		(item.get_node(^"Name") as Label).text = skin.name
		if selected_idx == skin.idx_in_db:
			(item.get_node(^"Name") as Label).add_theme_color_override(
					&"font_color", Color.GREEN)
		(item.get_node(^"Description") as Label).text = skin.brief_description
		(item.get_node(^"Description") as Label).horizontal_alignment = \
				HORIZONTAL_ALIGNMENT_CENTER
		(item.get_node(^"RarityFill") as ColorRect).color = \
				ItemsDB.RARITY_COLORS[skin.rarity]
		(item.get_node(^"Click") as BaseButton).pressed.connect(
				_on_item_pressed.bind(ItemsDB.Item.SKIN, skin.idx_in_db))
		add_child(item)


func _on_item_pressed(type: ItemsDB.Item, idx: int) -> void:
	item_selected.emit(type, idx)
