# Архитектура проекта

В этом документе рассмотрена архитектура проекта *Circle Shot*. Она основана на [лучших практиках](https://docs.godotengine.org/ru/4.x/tutorials/best_practices/index.html) Godot.

## Файловая структура

- Папка `addons`: различные дополнения, использующиеся в игре.
- Папка `game`: содержит всё, что связано с самой игрой. Это:
    - Папка `core`: содержит главные классы `Game`, `Loader`, `ItemsDB`, а также `Achievements` (в будущем).
    - Папка `effects`: содержит всевозможные эффекты, в отдельных подпапках.
    - Папка `entity`: содержит основной класс `Entity`, который наследуют `Player` и `Mob`, класс `Effect`, класс `Attack` вместе с его детекторами  (`RayDetector`, `AreaDetector`, ...) и распространёнными формами (`ColorAttack`, ...).
    - Папка `events`: содержит все режимы игры по мультиплееру (событий) в отдельных подпапках, а также одну папку `common`, в которой лежит всё общее между режимами (чат, ...).
    - Папка `maps` в своих подпапках содержит карты для событий.
    - Папка `menus`: содержит различные меню, такие как:
        - Папка `connect_local`: содержит меню для подключения по локальной сети.
        - Папка `solo`: меню для начала одиночной игры (в будущем).
        - Папка `lobby`: меню, где видно игроков и происходит выбор оружия.
    - Папка `mobs`: содержит папку `common` с классом `Mob`, а также папки с непосредственно мобами (в будущем).
    - Папка `player` содержит классы `Player`, `Weapon` и `Skill`.
    - Папка `skills`: содержит в себе папки с навыками.
    - Папка `skins` содержит в своих подпапках скины для игрока, организованные по линейкам.
    - Папка `solo`: содержит в своих подпапках все ресурсы для одиночной игры. Чего нет в мультиплеере, всё идёт сюда. Точная структура будет продумана позже.
    - Папка `weapons` содержит в своих подпапках оружия, организованные по типу (пушки, гранаты, ...). Подпапка типа может содержать в себе папку `common`, в которой лежит то, что объединяет оружия этого типа.
- Папка `main`: содержит классы `Main` и `Globals`, а также прочие ресурсы, которые используются при запуске игры.
- Папка `menu`: содержит в себе главное меню, магазин и прочие штуки, не связанные с игрой. Организуются по подпапкам в зависимости от самостоятельности этого компонента (например, нет смысла выносить из папки `settings` сцену с настройкой управления).
- Папка `misc`: содержит различные вспомогательные ресурсы, такие как: иконки приложения, ранняя заставка, ...

## Краткий обзор проекта

Первое, с чего начинается работа игры, так это с класса `Main`. Он выполняет инициализацию и загрузку игры, после чего открывает меню.

Проект может быть в двух состояниях: меню и игра. Поверх них можно открывать *экраны* с помощью метода `Main.open_screen(screen: PackedScene)`. За этими экранами следит `Main`, и при переходе в другое состояние они автоматически удаляются.

Сохранения в игре реализованы через класс `Globals`, а точнее через его методы `set_*()` и `get_*()`. Также для удобства хранения есть также методы `set_controls_*()` и `get_controls_*()` (для хранения настроек управления) и методы `set_setting_*()` и `get_controls_*()` (для хранения остальных настроек).

## Игровой цикл

В физическом кадре происходят:
- Поллинг `MultiplayerAPI`, т.е. вызовы RPC и синхронизация узлов `MultiplayerSynchronizer`.
- Основные подсчёты движения, будь то снаряды или сущности.
- Регистрация урона от снарядов и других атак.
- Прочие вещи, связанные с предыдущими.

В обычном кадре происходят:
- Визуальные вещи, такие как поворот оружия в соответствии с направлением прицеливания.
- Обработка ввода игрока.
- Прочие вещи, связанные с предыдущими.

## Разное

### Структура Z-индексов

- Индекс -6 и ниже: используются мини-картой.
- Индекс -5: пол. Для обычных объектов смысла в индексе ниже -5 очень мало.
- Индекс 0: основной индекс. На нём расположены сущности и стены карты.
- Индекс 3: декорации, что должны быть над всем происходящим.
- Индекс 10 и выше: используются вспомогательными объектами (линии прицела, ники игроков, метка контроля). Не рекомендуется занимать эти индексы обычными объектами.

Помните, что объекты одного Z-индекса рисуются в зависимости от положения в дереве сцены (узел ниже в дереве рисуется *над* узлом выше). Используйте вкладку "Удалённый" в панели Сцены, чтобы просмотреть положение нужного узла.

### Описание слоёв

#### Физика

- `World`: слой для объектов окружения (стен например). С ним должны сталкиваться снаряды и сущности (могут быть исключения).
- `Entity`: слой для всех сущностей. С ними сталкиваются снаряды, атаки, предметы.
- `Attack`: слой для атак, чаще всего для `AreaDetector`.
- `Boundary`: слой для границ карты. С ним должны сталкиваться ВСЕ снаряды.
- `Fence`: слой для простреливаемых блоков. С ними сталкиваются сущности, но не снаряды.
- `Items`: слой для различных подбираемых предметов.

#### Отрисовка

- `Default`: слой для всех обычных объектов. Включён у всех по умолчанию.
- `Minimap`: слой для элементов мини-карты. Не отображается в основной игре.
- `High Graphics`: слой для объектов, относящихся к продвинутой графике.
- `Low Graphics`: слой для объектов, выступающих заменителями, когда продвинутая графика отключена.

### Каналы RPC

- Канал 0: используется `MultiplayerSpawner` и `MultiplayerSynchronizer`. Не рекомендуется для RPC.
- Канал 1: используется для передачи состояния игры (регистрация игроков, выбор окружения, ...), в частности `Game` и лобби.
- Канал 2: используется чатом.
- Канал 3: используется для передачи информации о событии (увеличение счёта, ...).
- Канал 4: используется для передачи информации о здоровье сущностей и наложении эффектов.
- Канал 5: используется для передачи информации об оружии (смена, перезарядка, ...) и навыках (использование).
- Канал 6: используется для передачи информации о достижениях и статистике.
- Каналы 7-9: зарезервированы для будущего использования.
- Канал 10: используется для определения пинга.
