class_name Skill
extends Node2D

## Узел навыка.

## Определяет, сколько раз можно использовать навык.
@export var use_times: int = 2
## Задаёт время отката навыка.
@export var use_cooldown: int = 30
## Информация о навыке.
var data: SkillData
## Ссылка на игрока.
var player: Player
var _cooldown_timer := 0.0
@warning_ignore("unused_private_class_variable") # Для дочерних классов
@onready var _other_parent: Node2D = get_tree().get_first_node_in_group(&"OtherParent")


func _physics_process(delta: float) -> void:
	_cooldown_timer -= delta
	player.skill_vars[1] = ceili(_cooldown_timer)


## Инициализирует навык игроком [param to_player] и данными [param skill_data].
func initialize(to_player: Player, skill_data: SkillData) -> void:
	data = skill_data
	player = to_player
	if player.skill_vars.is_empty():
		player.skill_vars = [use_times, 0]
	_cooldown_timer = player.skill_vars[1]
	_initialize()


## Использует навык.
func use() -> void:
	player.skill_vars[0] -= 1
	player.skill_vars[1] = use_cooldown
	_cooldown_timer = use_cooldown
	_use()


## Возвращает [code]true[/code], если навык можно использовать.
func can_use() -> bool:
	return not player.is_disarmed() and player.skill_vars[0] > 0 \
			and player.skill_vars[1] <= 0 and _can_use()


## Метод для переопределения. Вызывается при инициализации навыка.
func _initialize() -> void:
	pass


## Метод для переопределения. Поместите логику использования навыка сюда.
## Создавайте дополнительные объекты (например, ударную волну) только на сервере.
func _use() -> void:
	pass


## Метод для переопределения. Должен возвращать [code]true[/code], если навык можно
## использовать. Сюда можно добавлять условия для этого.
func _can_use() -> bool:
	return true
