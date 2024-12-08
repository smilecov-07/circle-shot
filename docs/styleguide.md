# Руководство по стилю

Этот документ предназначен для стандартизирования стиля кода в пределах проекта. Основу составило официальное [руководство по стилю GDScript](https://docs.godotengine.org/ru/4.x/tutorials/scripting/gdscript/gdscript_styleguide.html). Здесь представлены расширения этого руководства.

## Структурирование кода

### Пустые строки

Между строкой наследования класса `extends` и методами должно быть ровно **две** пустых строки, если переменных в классе нет. Если же переменные есть, они должны быть отделены от методов и наследования **одной** пустой строкой, если их *не больше трёх*, иначе же их следует отделить **двумя** строками.  
Если переменных достаточно много, то их группы стоит разделять **одной** пустой строкой (группами считаются публичные, приватные, экспортные и `@onready` переменные).

Любая аннотация или документационная строка принадлежит переменной/методу и **не считается** за пустую строку.

#### Примеры

Нет переменных - две строки:

```gdscript
extends Node


func foo() -> String:
    return "bar"
```

Одна переменная - одна строка:

```gdscript
extends Node

var variable: int = 0

func foo() -> String:
    return str(variable)
```

Много переменных - две строки и по одной строке между их группами:

```gdscript
extends Node


@export var var0: int = 0
@export var var1: int = 0
@export var var2: int = 0

var var3: int = 0
var var4: int = 0

var _var6: int = 0
var _var7: int = 0
var _var8: int = 0

@onready var var9: int = 0
@onready var _var10: int = 0


func foo() -> String:
    return str(var0 + var3 - _var7)
```

### Порядок кода

Сохраняются все правила из оригинального руководства, однако добавляются следующие:

- Свойства идут перед обычными переменными своей группы.
- В группе переменных `@onready` могут быть как и публичные, так и приватные переменные. Первые идут перед последними.
- Переопределённые пользовательские методы идут сразу после встроенных переопределённых методов (таких как _process).
- Методы для переопределения в дочерних классах идут после методов своей группы (чаще всего приватных).
- `@rpc` методы идут перед другими из своей группы.
- Обратные вызовы от сигналов идут после других методов своей группы (чаще всего приватных).
    - Обратные вызовы от сигналов, подключенные в редакторе, идут после подключаемых в коде.
- Setter-ы и getter-ы идут после других методов своей группы (чаще всего публичных).

#### Пример

```gdscript
extends Node


var property: int:
    set(value):
        property = value
    get = get_property
var variable := 1.0
@onready var public: int = 0
@onready var _private: int = 0


func _ready() -> void:
    bar()


func _user_method_overridden() -> void:
    super()
    bar()


@rpc
func foo() -> void:
    pass


func bar() -> void:
    foo.rpc()


func get_property() -> int:
    return property


func _foo() -> void:
    pass


func _on_tree_exited() -> void:
    print("exited")


func _on_button_pressed() -> void:
    print("I'm connected from editor")
```

## Именование идентификаторов

- Избегайте добавления `is_` или `can_` в начало имени переменных. На `is_` и `can_` должны начинаться только названия методов.
- Если функция возвращает тип `bool`, рекомендуется начать её имя на `is_` или `can_`.
- Именуйте обратные вызовы сигналов в формате `_on_<node>_<signal>`. `<node>` может быть опущен, если в таком формате будет повторения слов, или если `<node>` единственный и очевидный.
- Оканчивайте переменные типа `PackedScene` на `_scene`.
- Именование переменной итератора:
    - Если итерируете по списку, именуйте переменную итератора осмысленно (например, `child` для `get_children()`).
    - Если итерируете с помощью `range(...)` или числа, используйте классичсекие `i`, `j`, `k`, ..., если нет более осмысленных вариантов.

### Пример

```gdscript
var active := true
var _vfx_scene: PackedScene = preload("uid://abcdefghij")


func _ready() -> void:
    for i: int in range(5):
        print("Hello world!")
    for child: Node in get_children():
        child.queue_free()


func can_attack() -> bool:
    return active
```

## Статическая типизация

### Использование статической типизации

В данном проекте типизация должна использоваться везде. Типизируйте даже массивы, если есть такая возможность.

### Правила типизации

Вы можете использовать `:=` вместо явного указания, но только, когда тип максимально очевиден (например, `float` для `0.5`). Также есть следующие нюансы:

- Стоит указать тип переменной, даже если в неё сохраняется значение из функции, по имени которой понятно, что она возвращает.
- Тип `int` указывайте всегда, так как можно спутать его с `float`.
- Записывайте `float`-переменные всегда с точкой, чтобы отличать от `int` и явно не указывать тип. Даже если это приведёт к записи `*.0`.
- Если Вам нужно привести тип с помощью `as`, делайте это только до такого типа, в котором есть нужный(-ая) Вам метод/переменная/сигнал.

#### Пример

```gdscript
var float_num := 1.0
var int_num: int = 1


func foo() -> void:
    var tween: Tween = create_tween()
    ($Button as BaseButton).disabled = true
```

## Разное

- Если метод/переменная требует `NodePath` или `StringName`, то префиксуйте строковые литералы с `^` и `&` соответственно (включите настройки редактора `text_editor/completion/add_string_name_literals` и `text_editor/completion/add_node_path_literals`).
- Если нужно преобразовать непостоянную строку в `NodePath` или `StringName` для использования в методе/свойстве, конвертировать с помощью конструктора необязательно, так как преобразование будет выполнено автоматически.
    - Однако, если результат сохраняется в переменную для многократного использования, выполните конвертацию вручную.
- Если вам необходимо перенести строку (например, она больше 100 символов), то используйте круглые скобки, если требуется перенести аргументы метода, большую `if`-конструкцию или очень длинное выражение. Иначе используйте `\`.
    - При использовании круглых скобок делайте 2 дополнительных уровня отступа (за исключением вложенных выражений), иначе 1 уровень отступа (для `[]` и `{}`).
    - Перенесённый скобками код `if`-конструкции или длинного выражения не может быть на одной строке с открывающей или закрывающей скобкой.

### Пример

```gdscript
get_node(^"AnimationPlayer").play(&"Walk")

node.name = "Game%d" % randi()
НО:
var id_nodepath := NodePath("Game%d" % randi())
if has_node(id_nodepath) and (get_node(id_nodepath) as CanvasItem).visible:
    ...

if (
        a == b and b == c and c == d and d == a
        and alpha * beta == gamma
):
    create_tween.tween_property(self, ^":position",
            Vector2(10.0, 20.0), 0.5)
    print("Started tween with data: %s %s %s" % [
        "Help",
        "3",
        "5",
    ])
```

## Документация и комментарии

Документация через docstring требуется, комментарии приветствуются.

Документация ведётся на русском языке, как и комментарии. Допускается неофициальный стиль.