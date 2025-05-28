class_name ItemsDB
extends Resource

## База данных всех предметов в игре.
##
## Хранит в себе всю информацию обо всех предметах в игре.

## Перечисление предметов в игре.
enum Item {
	## Событие.
	EVENT = 0,
	## Карта события.
	MAP = 1,
	## Скин.
	SKIN = 2,
	## Навык.
	SKILL = 3,
	## Оружие.
	WEAPON = 4,
	## Линейка скинов.
	SKINS_LINE = 5,
}
## Редкость некоторых предметов.
enum Rarity {
	## Обычная редкость (не надо разблокировать).
	COMMON = 0,
	## Редкая редкость (хах).
	RARE = 1,
	## Эпическая редкость.
	EPIC = 2,
	## Легендарная редкость.
	LEGENDARY = 3,
	## СЕКРЕТНАЯ редкость (нельзя просмотреть предметы до разблокировки).
	SECRET = 4,
	## Особая редкость (нельзя получить из ящиков).
	SPECIAL = 5,
}

## Цвета редкостей.
const RARITY_COLORS: Dictionary[Rarity, Color] = {
	Rarity.COMMON: Color(0.675, 1, 1),
	Rarity.RARE: Color(0, 0.9, 0.225),
	Rarity.EPIC: Color(0.625, 0, 0.825),
	Rarity.LEGENDARY: Color(1, 0.93, 0.195),
	Rarity.SECRET: Color(0.415, 0.415, 0.415),
	Rarity.SPECIAL: Color(1, 0.492, 0),
}

## Массив событий.
@export var events: Array[EventData]

@export_group("Equip")
## Массив линеек скинов.
@export var skins_lines: Array[SkinsLineData]
## Массив навыков, доступных для выбора.
@export var skills_normal: Array[SkillData]
## Массив лёгких оружий.
@export var weapons_light: Array[WeaponData]
## Массив тяжёлых оружий.
@export var weapons_heavy: Array[WeaponData]
## Массив оружий поддержки.
@export var weapons_support: Array[WeaponData]
## Массив ближних оружий.
@export var weapons_melee: Array[WeaponData]

@export_group("Other", "other_")
## Массив скинов, не доступных для выбора, но используемых где-то в игре.
@export var other_skins: Array[SkinData]
## Массив навыков, не доступных для выбора, но используемых где-то в игре.
@export var other_skills: Array[SkillData]
## Массив оружий, не доступных для выбора, но используемых где-то в игре.
@export var other_weapons: Array[WeaponData]

@export_group("Defaults", "default_")
## ID скина по умолчанию.
@export var default_skin: String
## ID навыка по умолчанию.
@export var default_skill: String
## ID лёгкого оружия по умолчанию.
@export var default_light_weapon: String
## ID тяжёлого оружия по умолчанию.
@export var default_heavy_weapon: String
## ID оружия поддержки по умолчанию.
@export var default_support_weapon: String
## ID ближнего оружия по умолчанию.
@export var default_melee_weapon: String

## Массив всех скинов. Собирается из скинов всех линеек при инициализации [ItemsDB].
var skins: Array[SkinData]
## Массив всех навыков. Собирается из [member skills_normal] и [member other_skills]
## при инициализации [ItemsDB].
var skills: Array[SkillData]
## Массив всех оружий. Собирается из [member weapons_light], [member weapons_heavy],
## [member weapons_support], [member weapons_melee] и [member other_weapons]
## при инициализации [ItemsDB].
var weapons: Array[WeaponData]

## Словарь скинов вида <ID скина> - <скин>.
var skins_by_id: Dictionary[String, SkinData]
## Словарь навыков вида <ID навыка> - <навык>.
var skills_by_id: Dictionary[String, SkillData]
## Словарь оружий вида <ID оружия> - <оружие>.
var weapons_by_id: Dictionary[String, WeaponData]

## Массив из путей к сценам, которые должны синхронизироваться при появлении, связанных с оружием. 
## Автоматически создаётся из [member WeaponData.spawnable_scenes_paths] у всех оружий.
var spawnable_projectiles_paths: Array[String]
## Массив из путей к сценам, которые должны синхронизироваться при появлении, не связанных
## с оружием. Автоматически создаётся из [member SkillData.spawnable_scenes_paths] у всех навыков.
var spawnable_other_paths: Array[String]


## Инициализирует базу данных предметов.
func initialize() -> void:
	skins.clear()
	skills.clear()
	weapons.clear()
	skins_by_id.clear()
	skills_by_id.clear()
	
	spawnable_projectiles_paths.clear()
	spawnable_other_paths.clear()
	
	for skins_line: SkinsLineData in skins_lines:
		skins_line.skins.sort_custom(_sort_rarity_skin)
		skins.append_array(skins_line.skins)
	skins.sort_custom(_sort_rarity_skin)
	skins.append_array(other_skins)
	
	skills_normal.sort_custom(_sort_rarity_skill)
	skills.append_array(skills_normal)
	other_skills.sort_custom(_sort_rarity_skill)
	skills.append_array(other_skills)
	
	weapons_light.sort_custom(_sort_rarity_weapon)
	weapons.append_array(weapons_light)
	weapons_heavy.sort_custom(_sort_rarity_weapon)
	weapons.append_array(weapons_heavy)
	weapons_support.sort_custom(_sort_rarity_weapon)
	weapons.append_array(weapons_support)
	weapons_melee.sort_custom(_sort_rarity_weapon)
	weapons.append_array(weapons_melee)
	other_weapons.sort_custom(_sort_rarity_weapon)
	weapons.append_array(other_weapons)
	
	for skin: SkinData in skins:
		skins_by_id[skin.id] = skin
	for skill: SkillData in skills:
		skills_by_id[skill.id] = skill
	for weapon: WeaponData in weapons:
		weapons_by_id[weapon.id] = weapon
	
	for skill: SkillData in skills:
		spawnable_other_paths.append_array(skill.spawnable_scenes_paths)
	for weapon: WeaponData in weapons:
		spawnable_projectiles_paths.append_array(weapon.spawnable_scenes_paths)
	
	for i: int in skins.size():
		skins[i].idx_in_db = i
	for i: int in skills.size():
		skills[i].idx_in_db = i
	for i: int in weapons.size():
		weapons[i].idx_in_db = i


func has_equip_item(id: String, type: Item) -> bool:
	match type:
		Item.SKIN:
			var skin: SkinData = skins_by_id[id]
			return skin.rarity == Rarity.COMMON or true
			# TODO: добавить проверку на наличие предмета, 3.0 контент
		Item.SKILL:
			var skill: SkillData = skills_by_id[id]
			return skill.rarity == Rarity.COMMON or true
			# TODO: добавить проверку на наличие предмета, 3.0 контент
		Item.WEAPON:
			var weapon: WeaponData = weapons_by_id[id]
			return weapon.rarity == Rarity.COMMON or true
			# TODO: добавить проверку на наличие предмета, 3.0 контент
		_:
			push_error("Callend with invalid item type: %d." % type)
	return false


func _sort_rarity_weapon(first: WeaponData, second: WeaponData) -> bool:
	if first.rarity != second.rarity:
		return first.rarity < second.rarity
	return first.idx_in_db < second.idx_in_db


func _sort_rarity_skin(first: SkinData, second: SkinData) -> bool:
	if first.rarity != second.rarity:
		return first.rarity < second.rarity
	return first.idx_in_db < second.idx_in_db


func _sort_rarity_skill(first: SkillData, second: SkillData) -> bool:
	if first.rarity != second.rarity:
		return first.rarity < second.rarity
	return first.idx_in_db < second.idx_in_db
