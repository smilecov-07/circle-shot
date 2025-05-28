class_name SkinData
extends Resource

## Ресурс с данными о скине.
## 
## Содержит данные о скине для игрока, такие как имя, описание, редкость и различные пути.

## Имя скина.
@export var name: String
## Редкость скина. Смотрите [enum ItemsDB.Rarity].
@export var rarity := ItemsDB.Rarity.COMMON
## ID скина. Должно быть уникальным.
@export var id: String

@export_group("About")
## Краткое описание скина.
@export var brief_description: String
## Есть ли у скина особый эффект получения урона.
@export var custom_hurt_vfx := false
## Есть ли у скина особый эффект смерти.
@export var custom_death_vfx := false
## Есть ли у скина особый эффект лечения.
@export var custom_heal_vfx := false
## Есть ли у скина особый эффект истекания кровью.
@export var custom_blood_vfx := false
## Есть ли у скина особые анимации (например, ходьба или особая анимация получения урона).
@export var custom_animations := false

@export_group("Paths")
## Путь до сцены со скином.
@export_file("PackedScene") var scene_path: String
## Путь до картинки скина, желательно с разрешением 256 на 256.
@export_file("Texture2D") var image_path: String
## Индекс скина в массиве [ItemsDB]. Задаётся при инициализации [ItemsDB].
var idx_in_db: int = -1
