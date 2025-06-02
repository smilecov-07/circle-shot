extends Control


var _hide_locked := false
var _type_to_list := ItemsDB.Item.EVENT
var _weapon_type_filter := Weapon.Type.INVALID # все
var _skins_line_filter: int = -1 # все
var _event_map_filter: int = -1 # пока никакое

var _selected_item_type := ItemsDB.Item.EVENT
var _selected_item_idx: int = -1

@onready var _items_grid: ItemsGrid = %ItemsGrid


func _ready() -> void:
	(%Description as CanvasItem).hide()
	(%OnlyUnlocked as CanvasItem).hide()
	
	for skins_line: SkinsLineData in Globals.items_db.skins_lines:
		(%Filters/SkinsFilter as OptionButton).add_item(skins_line.name)
	
	_update_items_grid()


func _update_items_grid() -> void:
	if _type_to_list == ItemsDB.Item.WEAPON and _weapon_type_filter != Weapon.Type.INVALID:
		_items_grid.list_weapons_by_type(_weapon_type_filter, -1, _hide_locked)
	elif _type_to_list == ItemsDB.Item.SKIN and _skins_line_filter >= 0:
		_items_grid.list_skins_line(_skins_line_filter, -1, _hide_locked)
	elif _type_to_list == ItemsDB.Item.MAP and _event_map_filter >= 0:
		_items_grid.list_maps_of_event(_event_map_filter)
	else:
		_items_grid.list_items(_type_to_list, -1, _hide_locked)


func _show_item(type: ItemsDB.Item, idx: int) -> void:
	(%Description as CanvasItem).show()
	(%NothingSelected as CanvasItem).hide()
	(%Description/SmallItem as CanvasItem).hide()
	(%Description/BigItem as CanvasItem).hide()
	(%Description/ShowItems as CanvasItem).hide()
	
	_selected_item_type = type
	_selected_item_idx = idx
	
	var item_name: String
	var description: String
	match type:
		ItemsDB.Item.EVENT:
			var event: EventData = Globals.items_db.events[idx]
			item_name = event.name
			description = "[center]%s[/center]" % event.brief_description
			description += '\n'
			description += "\nМинимум игроков: [color=red]%d[/color]" % event.min_players
			description += "\nМаксимум игроков: [color=red]%d[/color]" % event.max_players
			description += "\nДелитель игроков: [color=red]%d[/color]" % event.players_divider
			description += '\n'
			description += "\nКоличество карт: [color=lime_green]%d[/color]" % event.maps.size()
			
			(%Description/BigItem as CanvasItem).show()
			(%Description/BigItem as TextureRect).texture = load(event.image_path)
			
			(%Description/ShowItems as CanvasItem).show()
			(%Description/ShowItems as Button).text = "Просмотреть карты"
		ItemsDB.Item.MAP:
			var map: MapData = Globals.items_db.events[_event_map_filter].maps[idx]
			item_name = map.name
			description = "[center]%s[/center]" % map.brief_description
			description += "\n\nСобытие: [color=red]%s[/color]" \
					% Globals.items_db.events[_event_map_filter].name
			
			(%Description/BigItem as CanvasItem).show()
			(%Description/BigItem as TextureRect).texture = load(map.image_path)
			
			(%Description/ShowItems as CanvasItem).show()
			(%Description/ShowItems as Button).text = "Просмотреть событие"
		ItemsDB.Item.SKIN:
			var skin: SkinData = Globals.items_db.skins[idx]
			item_name = skin.name
			if not Globals.items_db.has_equip_item(skin.id, type):
				description = "Ещё не открыто"
			else:
				description = "[center]%s[/center]" % skin.brief_description
				description += '\n'
				description += "\nОсобый эффект получения урона: %s" % (
						"[color=lime_green]есть[/color]"
						if skin.custom_hurt_vfx else
						"[color=red]нет[/color]"
				)
				description += "\nОсобый эффект смерти: %s" % (
						"[color=lime_green]есть[/color]"
						if skin.custom_death_vfx else
						"[color=red]нет[/color]"
				)
				description += "\nОсобый эффект лечения: %s" % (
						"[color=lime_green]есть[/color]"
						if skin.custom_heal_vfx else
						"[color=red]нет[/color]"
				)
				description += "\nОсобый эффект истекания кровью: %s" % (
						"[color=lime_green]есть[/color]"
						if skin.custom_blood_vfx else
						"[color=red]нет[/color]"
				)
				description += "\nОсобые анимации: %s" % (
						"[color=lime_green]есть[/color]"
						if skin.custom_animations else
						"[color=red]нет[/color]"
				)
			description += "\n\nЛинейка: [color=red]%s[/color]" \
					% Globals.items_db.skins_lines[_find_skins_line_idx(idx)].name
			
			(%Description/SmallItem as CanvasItem).show()
			(%Description/SmallItem as ColorRect).color = ItemsDB.RARITY_COLORS[skin.rarity]
			(%Description/SmallItem/Texture as TextureRect).texture = load(skin.image_path)
			
			(%Description/ShowItems as CanvasItem).show()
			(%Description/ShowItems as Button).text = "Просмотреть линейку"
		ItemsDB.Item.SKILL:
			var skill: SkillData = Globals.items_db.skills[idx]
			item_name = skill.name
			if not Globals.items_db.has_equip_item(skill.id, type):
				description = "Ещё не открыто"
			else:
				description = skill.description.format(skill.stats)
			
			(%Description/SmallItem as CanvasItem).show()
			(%Description/SmallItem as ColorRect).color = ItemsDB.RARITY_COLORS[skill.rarity]
			(%Description/SmallItem/Texture as TextureRect).texture = load(skill.image_path)
		ItemsDB.Item.WEAPON:
			var weapon: WeaponData = Globals.items_db.weapons[idx]
			item_name = weapon.name
			if not Globals.items_db.has_equip_item(weapon.id, type):
				description = "Ещё не открыто"
			else:
				description = weapon.description.format(weapon.stats)
			
			(%Description/SmallItem as CanvasItem).show()
			(%Description/SmallItem as ColorRect).color = ItemsDB.RARITY_COLORS[weapon.rarity]
			(%Description/SmallItem/Texture as TextureRect).texture = load(weapon.image_path)
		ItemsDB.Item.SKINS_LINE:
			var skins_line: SkinsLineData = Globals.items_db.skins_lines[idx]
			item_name = skins_line.name
			description = "[center]%s[/center]" % skins_line.brief_description
			
			description += "\n\nВсего скинов: [color=red]%d[/color]" % skins_line.skins.size()
			var unlocked: int = 0
			for skin: SkinData in skins_line.skins:
				if Globals.items_db.has_equip_item(skin.id, ItemsDB.Item.SKIN):
					unlocked += 1
			description += "\nОткрыто скинов: [color=lime_green]%d[/color]" % unlocked
			
			(%Description/BigItem as CanvasItem).show()
			(%Description/BigItem as TextureRect).texture = load(skins_line.image_path)
			
			if not _hide_locked or unlocked > 0:
				(%Description/ShowItems as CanvasItem).show()
				(%Description/ShowItems as Button).text = "Просмотреть скины"
	
	(%Description/Name as Label).text = item_name
	(%Description/Text as RichTextLabel).text = description


func _find_skins_line_idx(skin_idx: int) -> int:
	var skins_line_idx: int = 0
	for skins_line: SkinsLineData in Globals.items_db.skins_lines:
		for skin: SkinData in skins_line.skins:
			if skin.idx_in_db == skin_idx:
				return skins_line_idx
		skins_line_idx += 1
	return -1


func _on_quit_pressed() -> void:
	queue_free()


func _on_only_unlocked_toggled(toggled_on: bool) -> void:
	_hide_locked = toggled_on
	_update_items_grid()


func _on_main_filter_item_selected(index: int) -> void:
	(%Description as CanvasItem).hide()
	(%NothingSelected as CanvasItem).show()
	(%Filters/WeaponsFilter as CanvasItem).hide()
	(%Filters/SkinsFilter as CanvasItem).hide()
	(%OnlyUnlocked as CanvasItem).hide()
	
	match index:
		0:
			_type_to_list = ItemsDB.Item.EVENT
		1:
			_type_to_list = ItemsDB.Item.SKIN
			(%Filters/SkinsFilter as CanvasItem).show()
			(%OnlyUnlocked as CanvasItem).show()
		2:
			_type_to_list = ItemsDB.Item.SKILL
			(%OnlyUnlocked as CanvasItem).show()
		3:
			_type_to_list = ItemsDB.Item.WEAPON
			(%Filters/WeaponsFilter as CanvasItem).show()
			(%OnlyUnlocked as CanvasItem).show()
		4:
			_type_to_list = ItemsDB.Item.SKINS_LINE
			(%OnlyUnlocked as CanvasItem).show()
	
	_update_items_grid()


func _on_weapons_filter_item_selected(index: int) -> void:
	if index == 0:
		_weapon_type_filter = Weapon.Type.INVALID
	else:
		_weapon_type_filter = index - 1 as Weapon.Type
	_update_items_grid()


func _on_skins_filter_item_selected(index: int) -> void:
	_skins_line_filter = index - 1
	_update_items_grid()


func _on_items_grid_item_selected(type: ItemsDB.Item, idx: int) -> void:
	_show_item(type, idx)


func _on_show_items_pressed() -> void:
	match _selected_item_type:
		ItemsDB.Item.SKINS_LINE:
			_skins_line_filter = _selected_item_idx
			(%Filters/SkinsFilter as OptionButton).select(_selected_item_idx + 1)
			(%Filters/MainFilter as OptionButton).select(1)
			_on_main_filter_item_selected(1)
		ItemsDB.Item.EVENT:
			(%Description as CanvasItem).hide()
			(%NothingSelected as CanvasItem).show()
			_event_map_filter = _selected_item_idx
			_type_to_list = ItemsDB.Item.MAP
			_update_items_grid()
		ItemsDB.Item.MAP:
			_type_to_list = ItemsDB.Item.EVENT
			_update_items_grid()
			_show_item(ItemsDB.Item.EVENT, _event_map_filter)
		ItemsDB.Item.SKIN:
			(%Filters/MainFilter as OptionButton).select(4)
			_on_main_filter_item_selected(4)
			_show_item(ItemsDB.Item.SKINS_LINE, _find_skins_line_idx(_selected_item_idx))
