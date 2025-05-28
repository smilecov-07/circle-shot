class_name SkillData
extends Resource

## Ресурс с данными о навыке.
## 
## Содержит данные о навыке для игрока, такие как имя, описание, редкость и различные пути.

## Имя навыка.
@export var name: String
## Редкость навыка. Смотрите [enum ItemsDB.Rarity].
@export var rarity := ItemsDB.Rarity.COMMON
## ID навыка. Должно быть уникальным.
@export var id: String

@export_group("About")
## Словарь с различными статистиками навыка (урон, кол-во использований, ...).
## В [member usage_text], [member brief_description] и [member description] можно подставлять
## значения отсюда, если написать в них [code]{<нужная статистика>}[/code].
@export var stats: Dictionary[String, String] = {
	"count": "",
	"cooldown": "",
}
## Краткое описание навыка (что он делает).
@export var brief_description: String
## Текст с данными о том, сколько раз можно использовать навык и какой у него откат.
## Рекомендуемый формат: "X исп./YY с", где X - кол-во использований, YY - время отката.
## Если использование только одно, откат можно не писать.
@export var usage_text := "{count} исп./{cooldown} с"
## Полное описание навыка, включающее в себя почти всю информацию о нём. Для форматирования можно
## использовать BBCode.
@export_multiline var description := """[color=deep_blue_sky]Что делает навык[/color]
Характеристики

Количество использований: [color=blue]{count}[/color]
Перезарядка: [color=blue]{cooldown} с[/color]

Описание"""

@export_group("Paths")
## Путь до сцены с навыком.
@export_file("PackedScene") var scene_path: String
## Путь до картинки навыка, желательно с разрешением 256 пикселей по большей стороне.
@export_file("Texture2D") var image_path: String
## Массив путей к сценам, относящихся конкретно к этому навыка, которые должны синхронизироваться
## при появлении. Например, сцена удара об землю.
@export_file("PackedScene") var spawnable_scenes_paths: Array[String]

## Индекс навыка в массиве [ItemsDB]. Задаётся при инициализации [ItemsDB].
var idx_in_db: int = -1
