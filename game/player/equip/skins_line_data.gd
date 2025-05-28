class_name SkinsLineData
extends Resource

## Ресурс с данными о линейке скинов.
## 
## Содержит данные о линейке скинов, такие как имя, описание и непосредственно скины.

## Имя линейки скинов.
@export var name: String
## Краткое описание линейки скинов.
@export var brief_description: String
## Путь до картинки линейки скинов, желательно с разрешением 784 на 160.
@export_file("Texture2D") var image_path: String
## Скины этой линейки.
@export var skins: Array[SkinData]
