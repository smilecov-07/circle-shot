extends Node

## Глобальный класс игры.
##
## Этот класс содержит в себе то, что используется по всей игре. Также отвечает за сохранения.

## Перечисление с возможными методами ввода.
enum InputMethod {
	## Клавиатура и мышь.
	KEYBOARD_AND_MOUSE = 0,
	## Касаниями.
	TOUCH = 1,
}
## Перечисление с допустимыми типами событий для действия при использовании
## [enum Globals.InputMethod.KEYBOARD_AND_MOUSE].
enum EncodedInputEventType {
	## События типа [InputEventKey].
	KEY = 0,
	## События типа [InputEventMouseButton].
	MOUSE_BUTTON = 1,
}
## Путь к файлу сохранения.
const SAVE_FILE_PATH := "user://save.cfg"
## Пароль файла сохранения.
const SAVE_FILE_PASSWORD := "circleshot"
## Стандартная секция файла сохранения.
const DEFAULT_SAVE_FILE_SECTION := "save"
## Секция файла сохранения для настроек.
const SETTINGS_SAVE_FILE_SECTION := "settings"
## Секция файла сохранения для настроек управления (в частности переназначения клавиш).
const CONTROLS_SAVE_FILE_SECTION := "controls"

## Версия игры. Извлекается из [ProjectSettings].
var version: String = ProjectSettings.get_setting("application/config/version")
## Находится ли игра в "безголовом режиме". Если да, то сервер создаётся без игрока.
## Если этот режим будет включён на запуске, то игра автоматически создаст сервер.
var headless := false

## База данных всех предметов. Смотри [ItemsDB].
var items_db: ItemsDB
## Ссылка на [Main]. Сокращение от [code]get_tree().current_scene as Main[/code].
var main: Main
## Ссылка на [Console]. Отсутствует, если консоль отключена.
var console: Console
## Ссылка на [UPNPManager]. Отсутствует, если UPnP отключён.
var upnp: UPNPManager

## Файл сохранения. Предпочитайте методы [code]get_*/set_*[/code] для его модификации.
var save_file: ConfigFile
## Файл с данными, которые загружаются с сервера. Проверяйте на [code]null[/code]
## перед использованием!
var data_file: ConfigFile


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_PREDELETE, \
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_GO_BACK_REQUEST, \
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			if save_file:
				save_file.save_encrypted_pass(SAVE_FILE_PATH, SAVE_FILE_PASSWORD)
		NOTIFICATION_WM_CLOSE_REQUEST:
			quit()


## Инициализирует файл сохранения и настройки.
func initialize() -> void:
	main = get_tree().current_scene
	
	save_file = ConfigFile.new()
	save_file.load_encrypted_pass(SAVE_FILE_PATH, SAVE_FILE_PASSWORD)
	
	if OS.is_debug_build():
		version += "-debug"
	
	setup_settings()
	apply_settings()
	setup_controls_settings()
	apply_controls_settings()


## Инициализирует различные системы.
func initialize_systems() -> void:
	items_db = ResourceLoader.load("uid://pwq1e7l2ckos", "", ResourceLoader.CACHE_MODE_REPLACE_DEEP)
	items_db.initialize()
	
	if "--console" in OS.get_cmdline_user_args():
		if not OS.has_feature("pc"):
			push_error("Console is only supported on PC platforms.")
		else:
			print_verbose("Starting console.")
			console = Console.new()
			console.name = &"Console"
			add_child(console)


## Выходит из игры. Если [param restart] равен [code]true[/code], перезапускает игру с аргументами,
## указанными в [param args].
func quit(restart := false, args := PackedStringArray()) -> void:
	if save_file:
		set_int("window_size_x", get_window().size.x)
		set_int("window_size_y", get_window().size.y)
		set_int("window_pos_x", get_window().position.x)
		set_int("window_pos_y", get_window().position.y)
		save_file.save_encrypted_pass(SAVE_FILE_PATH, SAVE_FILE_PASSWORD)
	if upnp:
		upnp.finalize()
	
	if args.is_empty() and restart:
		var all_args: PackedStringArray = OS.get_cmdline_args()
		var user_args: PackedStringArray = OS.get_cmdline_user_args()
		for arg: String in all_args:
			if not arg in user_args:
				args.append(arg)
		args.append("++")
		args.append_array(user_args)
	if console:
		if restart:
			OS.create_instance(args)
		OS.kill(OS.get_process_id())
	else:
		OS.set_restart_on_exit(restart, args)
		get_tree().quit()


#region Настройки
## Устанавливает настройки по умолчанию, если их ещё нет.
func setup_settings() -> void:
	var override_file := ConfigFile.new()
	override_file.load("user://engine_settings.cfg")
	var shader_cache: bool = ProjectSettings.get_setting_with_override(
			&"rendering/shader_compiler/shader_cache/enabled")
	override_file.set_value("rendering",
			"shader_compiler/shader_cache/enabled", shader_cache)
	override_file.set_value("rendering",
			"shader_compiler/shader_cache/enabled.mobile", shader_cache)
	override_file.save("user://engine_settings.cfg")
	
	# Основное
	set_setting_bool("check_updates", get_setting_bool("check_updates", true))
	set_setting_bool("check_betas", get_setting_bool("check_betas", version.count('.') == 3))
	set_setting_bool("check_patches", get_setting_bool("check_patches", true))
	# Сеть
	set_setting_bool("upnp", get_setting_bool("upnp", false))
	set_setting_bool("broadcast", get_setting_bool("broadcast", true))
	# Игра
	set_setting_bool("minimap", get_setting_bool("minimap", true))
	set_setting_bool("debug_info", get_setting_bool("debug_info", false))
	set_setting_bool("chat_in_game", get_setting_bool("chat_in_game", true))
	set_setting_bool("vibration", get_setting_bool("vibration", false))
	set_setting_bool("aim_dodge", get_setting_bool("aim_dodge", false))
	set_setting_bool("advices", get_setting_bool("advices", true))
	# Графика
	set_setting_bool("fullscreen", get_setting_bool("fullscreen", not OS.has_feature("pc")))
	set_setting_int("max_fps", get_setting_int("max_fps", 130))
	set_setting_bool("low_graphics", get_setting_bool("low_graphics", false))
	# Звук
	set_setting_float("master_volume", get_setting_float("master_volume", 1.0))
	set_setting_float("music_volume", get_setting_float("music_volume", 0.7))
	set_setting_float("sfx_volume", get_setting_float("sfx_volume", 1.0))
	set_setting_bool("custom_tracks", get_setting_bool("custom_tracks", OS.has_feature("pc")))
	set_setting_bool("official_tracks", get_setting_bool("official_tracks", true))


## Устанавливает настройки управления по умолчанию, если их ещё нет.
func setup_controls_settings() -> void:
	var default_input_method: InputMethod = InputMethod.KEYBOARD_AND_MOUSE
	if DisplayServer.is_touchscreen_available():
		default_input_method = InputMethod.TOUCH
	set_controls_int("input_method", get_controls_int("input_method", default_input_method))
	set_controls_bool("follow_mouse", get_controls_bool("follow_mouse", true))
	set_controls_bool("always_show_aim", get_controls_bool("always_show_aim", false))
	set_controls_bool("joystick_fire", get_controls_bool("joystick_fire", false))
	set_controls_float("sneak_multiplier", get_controls_float("sneak_multiplier", 0.5))
	set_controls_float("aim_deadzone", get_controls_float("aim_deadzone", 0.15))
	set_controls_float("aim_zone", get_controls_float("aim_zone", 0.5))
	set_controls_float("joysticks_alpha", get_controls_float("joysticks_alpha", 1.0))
	
	InputMap.load_from_project_settings()
	for action: StringName in InputMap.get_actions():
		if action.begins_with("ui_"):
			continue
		
		var encoded_input_event_types: Array[EncodedInputEventType]
		var encoded_input_event_values: Array[int]
		for event: InputEvent in InputMap.action_get_events(action):
			var encoded_input_event_type: EncodedInputEventType
			var encoded_input_event_value: int
			
			var mb := event as InputEventMouseButton
			if mb:
				encoded_input_event_type = EncodedInputEventType.MOUSE_BUTTON
				encoded_input_event_value = mb.button_index
			var key := event as InputEventKey
			if key:
				encoded_input_event_type = EncodedInputEventType.KEY
				encoded_input_event_value = key.keycode
			
			encoded_input_event_types.append(encoded_input_event_type)
			encoded_input_event_values.append(encoded_input_event_value)
		
		set_controls_variant("action_%s_event_types" % action,
				get_controls_variant("action_%s_event_types" % action, encoded_input_event_types))
		set_controls_variant("action_%s_event_values" % action,
				get_controls_variant("action_%s_event_values" % action, encoded_input_event_values))
	
	set_controls_int("anchors_preset_health_bar",
			get_controls_int("anchors_preset_health_bar", Control.PRESET_CENTER_BOTTOM))
	set_controls_vector2("offsets_lt_health_bar",
			get_controls_vector2("offsets_lt_health_bar", Vector2(-240.0, -64.0)))
	set_controls_vector2("offsets_rb_health_bar",
			get_controls_vector2("offsets_rb_health_bar", Vector2(240.0, -16.0)))
	
	set_controls_int("anchors_preset_additional",
			get_controls_int("anchors_preset_additional", Control.PRESET_BOTTOM_RIGHT))
	set_controls_vector2("offsets_lt_additional",
			get_controls_vector2("offsets_lt_additional", Vector2(-128.0, -128.0)))
	set_controls_vector2("offsets_rb_additional",
			get_controls_vector2("offsets_rb_additional", Vector2(-8.0, -8.0)))
	
	set_controls_int("anchors_preset_move_js",
			get_controls_int("anchors_preset_move_js", Control.PRESET_BOTTOM_LEFT))
	set_controls_vector2("offsets_lt_move_js",
			get_controls_vector2("offsets_lt_move_js", Vector2(128.0, -328.0)))
	set_controls_vector2("offsets_rb_move_js",
			get_controls_vector2("offsets_rb_move_js", Vector2(328.0, -128.0)))
	
	set_controls_int("anchors_preset_aim_js",
			get_controls_int("anchors_preset_aim_js", Control.PRESET_BOTTOM_RIGHT))
	set_controls_vector2("offsets_lt_aim_js",
			get_controls_vector2("offsets_lt_aim_js", Vector2(-328.0, -328.0)))
	set_controls_vector2("offsets_rb_aim_js",
			get_controls_vector2("offsets_rb_aim_js", Vector2(-128.0, -128.0)))
	
	set_controls_int("anchors_preset_weapon",
			get_controls_int("anchors_preset_weapon", Control.PRESET_CENTER_RIGHT))
	set_controls_vector2("offsets_lt_weapon",
			get_controls_vector2("offsets_lt_weapon", Vector2(-288.0, -232.0)))
	set_controls_vector2("offsets_rb_weapon",
			get_controls_vector2("offsets_rb_weapon", Vector2(0.0, -88.0)))
	
	set_controls_int("anchors_preset_spare_weapon",
			get_controls_int("anchors_preset_spare_weapon", Control.PRESET_CENTER_BOTTOM))
	set_controls_vector2("offsets_lt_spare_weapon",
			get_controls_vector2("offsets_lt_spare_weapon", Vector2(-96.0, -176.0)))
	set_controls_vector2("offsets_rb_spare_weapon",
			get_controls_vector2("offsets_rb_spare_weapon", Vector2(96.0, -80.0)))
	
	set_controls_int("anchors_preset_skill",
			get_controls_int("anchors_preset_skill", Control.PRESET_CENTER_RIGHT))
	set_controls_vector2("offsets_lt_skill",
			get_controls_vector2("offsets_lt_skill", Vector2(-128.0, -80.0)))
	set_controls_vector2("offsets_rb_skill",
			get_controls_vector2("offsets_rb_skill", Vector2(-8.0, 40.0)))
	
	set_controls_float("move_joystick_scale",
			get_controls_float("move_joystick_scale", 1.0))
	set_controls_float("move_joystick_deadzone",
			get_controls_float("move_joystick_deadzone", 20.0))
	set_controls_int("move_joystick_mode",
			get_controls_int("move_joystick_mode", VirtualJoystick.JoystickMode.DYNAMIC))
	
	set_controls_float("aim_joystick_scale",
			get_controls_float("aim_joystick_scale", 1.0))
	set_controls_float("aim_joystick_deadzone",
			get_controls_float("aim_joystick_deadzone", 20.0))
	set_controls_int("aim_joystick_mode",
			get_controls_int("aim_joystick_type", VirtualJoystick.JoystickMode.DYNAMIC))
	
	set_controls_vector2("shoot_area",
			get_controls_vector2("shoot_area", Vector2(640.0, 256.0)))


## Применяет общие настройки.
func apply_settings() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Master"),
			linear_to_db(get_setting_float("master_volume")))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music"),
			linear_to_db(get_setting_float("music_volume")))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"SFX"),
			linear_to_db(get_setting_float("sfx_volume")))
	if get_setting_bool("fullscreen"):
		if not get_window().mode in [Window.MODE_EXCLUSIVE_FULLSCREEN, Window.MODE_FULLSCREEN]:
			get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	else:
		if not get_window().mode in [
			Window.MODE_WINDOWED,
			Window.MODE_MINIMIZED,
			Window.MODE_MAXIMIZED,
		]:
			get_window().mode = Window.MODE_WINDOWED
	if get_setting_bool("custom_tracks"):
		DirAccess.make_dir_recursive_absolute(main.music_path)
	var max_fps: int = get_setting_int("max_fps")
	Engine.max_fps = max_fps if max_fps < 125 else 0
	get_viewport().set_canvas_cull_mask_bit(2, not get_setting_bool("low_graphics"))
	get_viewport().set_canvas_cull_mask_bit(3, get_setting_bool("low_graphics"))


## Применяет настройки управления.
func apply_controls_settings() -> void:
	Input.emulate_touch_from_mouse = get_controls_int("input_method") == InputMethod.TOUCH
	
	if get_controls_int("input_method") != InputMethod.KEYBOARD_AND_MOUSE:
		return
	for action: StringName in InputMap.get_actions():
		if action.begins_with("ui_"):
			continue
		InputMap.action_erase_events(action)
		
		var encoded_input_event_types: Array[EncodedInputEventType] = \
				get_controls_variant("action_%s_event_types" % action, [] as Array[int])
		var encoded_input_event_values: Array[int] = \
				get_controls_variant("action_%s_event_values" % action, [] as Array[int])
		
		for i: int in encoded_input_event_types.size():
			var event: InputEvent
			match encoded_input_event_types[i]:
				EncodedInputEventType.KEY:
					var key := InputEventKey.new()
					key.keycode = encoded_input_event_values[i] as Key
					event = key
				EncodedInputEventType.MOUSE_BUTTON:
					var mb := InputEventMouseButton.new()
					mb.button_index = encoded_input_event_values[i] as MouseButton
					event = mb
			
			InputMap.action_add_event(action, event)
#endregion


#region Функции задавания и получения значений
## Получает значение типа [Variant] по [param id]. Если его нет, вернёт [param default_value].
func get_variant(id: String, default_value: Variant) -> Variant:
	return save_file.get_value(DEFAULT_SAVE_FILE_SECTION, id, default_value)


## Задаёт значение типа [Variant] под [param id].
func set_variant(id: String, value: Variant) -> void:
	save_file.set_value(DEFAULT_SAVE_FILE_SECTION, id, value)


## Получает значение типа [int] по [param id]. Если его нет, вернёт [param default_value].
func get_int(id: String, default_value: int = 0) -> int:
	return save_file.get_value(DEFAULT_SAVE_FILE_SECTION, id, default_value)


## Задаёт значение типа [int] под [param id].
func set_int(id: String, value: int) -> void:
	save_file.set_value(DEFAULT_SAVE_FILE_SECTION, id, value)


## Получает значение типа [float] по [param id]. Если его нет, вернёт [param default_value].
func get_float(id: String, default_value := 0.0) -> float:
	return save_file.get_value(DEFAULT_SAVE_FILE_SECTION, id, default_value)


## Задаёт значение типа [float] под [param id].
func set_float(id: String, value: float) -> void:
	save_file.set_value(DEFAULT_SAVE_FILE_SECTION, id, value)


## Получает значение типа [bool] по [param id]. Если его нет, вернёт [param default_value].
func get_bool(id: String, default_value := false) -> bool:
	return save_file.get_value(DEFAULT_SAVE_FILE_SECTION, id, default_value)


## Задаёт значение типа [bool] под [param id].
func set_bool(id: String, value: bool) -> void:
	save_file.set_value(DEFAULT_SAVE_FILE_SECTION, id, value)


## Получает значение типа [String] по [param id]. Если его нет, вернёт [param default_value].
func get_string(id: String, default_value := "") -> String:
	return save_file.get_value(DEFAULT_SAVE_FILE_SECTION, id, default_value)


## Задаёт значение типа [String] под [param id].
func set_string(id: String, value: String) -> void:
	save_file.set_value(DEFAULT_SAVE_FILE_SECTION, id, value)
#endregion


#region Функции задавания и получения настроек
## Получает значение настройки типа [Variant] по [param id].
## Если его нет, вернёт [param default_value].
func get_setting_variant(id: String, default_value: Variant) -> Variant:
	return save_file.get_value(SETTINGS_SAVE_FILE_SECTION, id, default_value)


## Задаёт значение настройки типа [Variant] под [param id].
func set_setting_variant(id: String, value: Variant) -> void:
	save_file.set_value(SETTINGS_SAVE_FILE_SECTION, id, value)


## Получает значение настройки типа [int] по [param id].
## Если его нет, вернёт [param default_value].
func get_setting_int(id: String, default_value: int = 0) -> int:
	return save_file.get_value(SETTINGS_SAVE_FILE_SECTION, id, default_value)


## Задаёт значение настройки типа [int] под [param id].
func set_setting_int(id: String, value: int) -> void:
	save_file.set_value(SETTINGS_SAVE_FILE_SECTION, id, value)


## Получает значение настройки типа [float] по [param id].
## Если его нет, вернёт [param default_value].
func get_setting_float(id: String, default_value := 0.0) -> float:
	return save_file.get_value(SETTINGS_SAVE_FILE_SECTION, id, default_value)


## Задаёт значение настройки типа [float] под [param id].
func set_setting_float(id: String, value: float) -> void:
	save_file.set_value(SETTINGS_SAVE_FILE_SECTION, id, value)


## Получает значение настройки типа [bool] по [param id].
## Если его нет, вернёт [param default_value].
func get_setting_bool(id: String, default_value := false) -> bool:
	return save_file.get_value(SETTINGS_SAVE_FILE_SECTION, id, default_value)


## Задаёт значение настройки типа [bool] под [param id].
func set_setting_bool(id: String, value: bool) -> void:
	save_file.set_value(SETTINGS_SAVE_FILE_SECTION, id, value)
#endregion


#region Функции задавания и получения настроек управления
## Получает значение настройки управления типа [Variant] по [param id].
## Если его нет, вернёт [param default_value].
func get_controls_variant(id: String, default_value: Variant) -> Variant:
	return save_file.get_value(CONTROLS_SAVE_FILE_SECTION, id, default_value)


## Задаёт значение настройки управления типа [Variant] под [param id].
func set_controls_variant(id: String, value: Variant) -> void:
	save_file.set_value(CONTROLS_SAVE_FILE_SECTION, id, value)


## Получает значение настройки управления типа [float] по [param id].
## Если его нет, вернёт [param default_value].
func get_controls_float(id: String, default_value := 0.0) -> float:
	return save_file.get_value(CONTROLS_SAVE_FILE_SECTION, id, default_value)


## Задаёт значение настройки управления типа [float] под [param id].
func set_controls_float(id: String, value: float) -> void:
	save_file.set_value(CONTROLS_SAVE_FILE_SECTION, id, value)


## Получает значение настройки управления типа [int] по [param id].
## Если его нет, вернёт [param default_value].
func get_controls_int(id: String, default_value: int = 0) -> int:
	return save_file.get_value(CONTROLS_SAVE_FILE_SECTION, id, default_value)


## Задаёт значение настройки управления типа [int] под [param id].
func set_controls_int(id: String, value: int) -> void:
	save_file.set_value(CONTROLS_SAVE_FILE_SECTION, id, value)


## Получает значение настройки управления типа [bool] по [param id].
## Если его нет, вернёт [param default_value].
func get_controls_bool(id: String, default_value := false) -> bool:
	return save_file.get_value(CONTROLS_SAVE_FILE_SECTION, id, default_value)


## Задаёт значение настройки управления типа [bool] под [param id].
func set_controls_bool(id: String, value: bool) -> void:
	save_file.set_value(CONTROLS_SAVE_FILE_SECTION, id, value)


## Получает значение настройки управления типа [Vector2] по [param id].
## Если его нет, вернёт [param default_value].
func get_controls_vector2(id: String, default_value := Vector2.ZERO) -> Vector2:
	return save_file.get_value(CONTROLS_SAVE_FILE_SECTION, id, default_value)


## Задаёт значение настройки управления типа [Vector2] под [param id].
func set_controls_vector2(id: String, value: Vector2) -> void:
	save_file.set_value(CONTROLS_SAVE_FILE_SECTION, id, value)
#endregion
