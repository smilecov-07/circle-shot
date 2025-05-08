extends Control


const AIM_VISUAL_MAX_SIZE := 360.0
@export_multiline var help_messages: Array[String]
var _override_file := ConfigFile.new()
@onready var _aim_visual: ColorRect = %AimVisual


func _ready() -> void:
	show_section("General")
	
	_override_file.load("user://engine_settings.cfg")
	
	# Основное
	(%UpdatesCheck as BaseButton).set_pressed_no_signal(Globals.get_setting_bool("check_updates"))
	_on_updates_check_toggled((%UpdatesCheck as BaseButton).button_pressed)
	(%BetasCheck as BaseButton).set_pressed_no_signal(Globals.get_setting_bool("check_betas"))
	(%PatchesCheck as BaseButton).set_pressed_no_signal(Globals.get_setting_bool("check_patches"))
	# Сеть
	(%BroadcastCheck as BaseButton).set_pressed_no_signal(Globals.get_setting_bool("broadcast"))
	(%UPNPCheck as BaseButton).set_pressed_no_signal(Globals.get_setting_bool("upnp"))
	_on_upnp_check_toggled((%UPNPCheck as BaseButton).button_pressed)
	# Игра
	(%ChatInGameCheck as BaseButton).set_pressed_no_signal(Globals.get_setting_bool("chat_in_game"))
	(%ShowMinimapCheck as BaseButton).set_pressed_no_signal(Globals.get_setting_bool("minimap"))
	(%ShowDebugCheck as BaseButton).set_pressed_no_signal(Globals.get_setting_bool("debug_info"))
	(%DodgeOptions as OptionButton).selected = int(Globals.get_setting_bool("aim_dodge"))
	(%VibrationCheck as BaseButton).set_pressed_no_signal(Globals.get_setting_bool("vibration"))
	# Графика
	var shader_cache: bool = \
			_override_file.get_value("rendering", "shader_compiler/shader_cache/enabled")
	(%ShaderCacheCheck as BaseButton).set_pressed_no_signal(shader_cache)
	(%LowGraphicsCheck as BaseButton).set_pressed_no_signal(
			Globals.get_setting_bool("low_graphics"))
	(%FullscreenCheck as BaseButton).set_pressed_no_signal(Globals.get_setting_bool("fullscreen"))
	(%FPSSlider as Range).value = Globals.get_setting_int("max_fps")
	# Звук
	(%MasterVolumeSlider as Range).set_value_no_signal(Globals.get_setting_float("master_volume"))
	(%MusicVolumeSlider as Range).set_value_no_signal(Globals.get_setting_float("music_volume"))
	(%SFXVolumeSlider as Range).set_value_no_signal(Globals.get_setting_float("sfx_volume"))
	(%CustomTracksCheck as BaseButton).set_pressed_no_signal(
			Globals.get_setting_bool("custom_tracks"))
	_on_custom_tracks_check_toggled((%CustomTracksCheck as BaseButton).button_pressed)
	(%OfficialTracksCheck as BaseButton).set_pressed_no_signal(
			Globals.get_setting_bool("official_tracks"))
	# Управление
	(%InputOptions as OptionButton).selected = Globals.get_controls_int("input_method")
	_toggle_input_method_settings_visibility(Globals.get_controls_int("input_method"))
	(%FollowMouseCheck as BaseButton).set_pressed_no_signal(
			Globals.get_controls_bool("follow_mouse"))
	(%FireModeOptions as OptionButton).selected = int(Globals.get_controls_bool("joystick_fire"))
	(%SneakSlider as Range).value = Globals.get_controls_float("sneak_multiplier")
	(%AimDZoneSlider as Range).value = Globals.get_controls_float("aim_deadzone")
	(%AimZoneSlider as Range).set_value_no_signal(Globals.get_controls_float("aim_zone"))
	(%AlwaysAimCheck as BaseButton).set_pressed_no_signal(
			Globals.get_controls_bool("always_show_aim"))
	(%JoysticksAlphaSlider as Range).set_value_no_signal(
			Globals.get_controls_float("joysticks_alpha"))
	
	_update_aim_visual_size()
	get_window().size_changed.connect(_update_aim_visual_size)
	
	# UPnP
	var upnp_status := "Отключён"
	if Globals.main.upnp:
		match Globals.main.upnp.status:
			UPNPManager.Status.INACTIVE:
				upnp_status = "Неактивен"
			_:
				upnp_status = "Активен"
	(%UPNPStatus as Label).text = upnp_status
	
	# Кастомные треки
	(%CustomTracksPath as Label).text = "Путь к папке с треками: %s" % Globals.main.music_path
	if not Globals.main.custom_tracks.is_empty():
		for node: Node in %LoadedTracks.get_children():
			node.queue_free()
		
		for track: String in Globals.main.custom_tracks:
			var label := Label.new()
			label.text = track
			%LoadedTracks.add_child(label)
	
	# Скрытие настроек
	if "--upnp" in OS.get_cmdline_user_args():
		(%UPNPCheck.get_parent().get_parent() as CanvasItem).hide()
	if not OS.has_feature("pc"):
		(%FullscreenCheck.get_parent().get_parent() as CanvasItem).hide()
	if not OS.has_feature("mobile"):
		(%VibrationCheck.get_parent().get_parent() as CanvasItem).hide()
	if OS.has_feature("editor"):
		(%PatchesCheck.get_parent().get_parent() as CanvasItem).hide()
		(%ClearPatches.get_parent() as CanvasItem).hide()
	if "--disable-update-check" in OS.get_cmdline_user_args():
		(%UpdatesCheck.get_parent().get_parent() as CanvasItem).hide()
		(%BetasCheck.get_parent().get_parent() as CanvasItem).hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action(&"fullscreen") and event.is_pressed():
		(%FullscreenCheck as BaseButton).set_pressed_no_signal(
				Globals.get_setting_bool("fullscreen"))


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST when visible:
			_on_quit_pressed()


func show_section(section_name: String) -> void:
	for section: CanvasItem in %Sections.get_children():
		section.hide()
	
	(%Sections.get_node(section_name) as CanvasItem).show()


func show_help(help_idx: int) -> void:
	($HelpDialog as AcceptDialog).dialog_text = help_messages[help_idx]
	($HelpDialog as Window).size.y = 0 # Устанавливает минимальную высоту
	($HelpDialog as Window).popup_centered()


func remove_recursive(path: String) -> void:
	var dir_access := DirAccess.open(path)
	if dir_access:
		for file: String in dir_access.get_files():
			dir_access.remove(file)
		for dir: String in dir_access.get_directories():
			remove_recursive(dir_access.get_current_dir().path_join(dir))
		
		dir_access.remove(dir_access.get_current_dir())


func _toggle_input_method_settings_visibility(method: Main.InputMethod) -> void:
	(%KeyboardSettings as CanvasItem).hide()
	(%TouchSettings as CanvasItem).hide()
	match method:
		Main.InputMethod.KEYBOARD_AND_MOUSE:
			(%KeyboardSettings as CanvasItem).show()
		Main.InputMethod.TOUCH:
			(%TouchSettings as CanvasItem).show()


func _update_aim_visual_size() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x >= viewport_size.y:
		_aim_visual.custom_minimum_size.x = AIM_VISUAL_MAX_SIZE
		_aim_visual.custom_minimum_size.y = 1.0 / viewport_size.aspect() * AIM_VISUAL_MAX_SIZE
	else:
		_aim_visual.custom_minimum_size.y = AIM_VISUAL_MAX_SIZE
		_aim_visual.custom_minimum_size.x = viewport_size.aspect() * AIM_VISUAL_MAX_SIZE


func _on_request_permissions_result(permission: String, granted: bool) -> void:
	print_verbose("Permission %s granted: %s." % [permission, str(granted)])
	var lambda: Callable = func(value: bool) -> void:
		(%CustomTracksCheck as BaseButton).button_pressed = value
	lambda.call_deferred(granted)


func _on_quit_pressed() -> void:
	if is_instance_valid(Globals.main.menu):
		Globals.main.menu.check_updates()
	queue_free()


#region Основное
func _on_updates_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("check_updates", toggled_on)
	(%BetasCheck.get_parent().get_parent() as CanvasItem).visible = toggled_on


func _on_betas_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("check_betas", toggled_on)


func _on_patches_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("check_patches", toggled_on)


func _on_clear_patches_pressed() -> void:
	remove_recursive("user://patches")
	Globals.set_variant("patches", {} as Dictionary[String, int])
	Globals.quit(true)


func _on_change_name_pressed() -> void:
	($NameDialog as Window).title = \
			"Смена имени (текущее: %s)" % Globals.get_string("player_name")
	($NameDialog as Window).popup_centered()


func _on_reset_data_dialog_confirmed() -> void:
	remove_recursive("user://")
	Globals.quit(true)


func _on_reset_controls_dialog_confirmed() -> void:
	Globals.save_file.erase_section(Globals.CONTROLS_SAVE_FILE_SECTION)
	Globals.main.setup_controls_settings()
	Globals.main.apply_controls_settings()
	
	name = &"OldSettings"
	queue_free()
	Globals.main.open_screen(load("uid://c2leb2h0qjtmo") as PackedScene)


func _on_reset_settings_dialog_confirmed() -> void:
	Globals.save_file.erase_section(Globals.SETTINGS_SAVE_FILE_SECTION)
	Globals.save_file.erase_section(Globals.CONTROLS_SAVE_FILE_SECTION)
	DirAccess.remove_absolute("user://engine_settings.cfg")
	Globals.main.setup_settings()
	Globals.main.apply_settings()
	Globals.main.setup_controls_settings()
	Globals.main.apply_controls_settings()
	
	name = &"OldSettings"
	queue_free()
	Globals.main.open_screen(load("uid://c2leb2h0qjtmo") as PackedScene)


func _on_restart_game_pressed() -> void:
	Globals.quit(true)
#endregion


#region Сеть
func _on_broadcast_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("broadcast", toggled_on)


func _on_upnp_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("upnp", toggled_on)
	(%UPNPStatus.get_parent() as CanvasItem).visible = toggled_on
#endregion


#region Игра
func _on_show_minimap_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("minimap", toggled_on)


func _on_chat_in_game_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("chat_in_game", toggled_on)


func _on_show_debug_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("debug_info", toggled_on)


func _on_dodge_options_item_selected(index: int) -> void:
	Globals.set_setting_bool("aim_dodge", bool(index))


func _on_vibration_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("vibration", toggled_on)
#endregion


#region Графика
func _on_fullscreen_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("fullscreen", toggled_on)
	Globals.main.apply_settings()


func _on_fps_slider_value_changed(value: float) -> void:
	Globals.set_setting_int("max_fps", int(value))
	if value > 125.0:
		(%FPSValue as Label).text = "Нет"
	else:
		(%FPSValue as Label).text = "%d" % value
	Globals.main.apply_settings()


func _on_low_graphics_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("low_graphics", toggled_on)
	Globals.main.apply_settings()


func _on_shader_cache_check_toggled(toggled_on: bool) -> void:
	_override_file.set_value("rendering", "shader_compiler/shader_cache/enabled", toggled_on)
	_override_file.set_value("rendering", "shader_compiler/shader_cache/enabled.mobile", toggled_on)
	_override_file.set_value("rendering", "rendering_device/pipeline_cache/enable", toggled_on)
	_override_file.set_value("rendering",
			"rendering_device/pipeline_cache/enable.mobile", toggled_on)
	_override_file.save("user://engine_settings.cfg")


func _on_clear_shader_cache_pressed() -> void:
	remove_recursive("user://shader_cache")
	remove_recursive("user://vulkan")
	Globals.quit(true)
#endregion


#region Звук
func _on_master_volume_slider_value_changed(value: float) -> void:
	Globals.set_setting_float("master_volume", value)
	Globals.main.apply_settings()


func _on_music_volume_slider_value_changed(value: float) -> void:
	Globals.set_setting_float("music_volume", value)
	Globals.main.apply_settings()


func _on_sfx_volume_slider_value_changed(value: float) -> void:
	Globals.set_setting_float("sfx_volume", value)
	Globals.main.apply_settings()


func _on_custom_tracks_check_toggled(toggled_on: bool) -> void:
	if toggled_on and OS.has_feature("android"):
		var perms: PackedStringArray = OS.get_granted_permissions()
		if not (
				"android.permission.READ_MEDIA_AUDIO" in perms
				or "android.permission.READ_EXTERNAL_STORAGE" in perms
				or "android.permission.WRITE_EXTERNAL_STORAGE" in perms
		):
			(%CustomTracksCheck as BaseButton).set_pressed_no_signal(false)
			get_tree().on_request_permissions_result.connect(_on_request_permissions_result,
					CONNECT_ONE_SHOT)
			OS.request_permissions()
			toggled_on = false
	(%CustomTracksSettings as CanvasItem).visible = toggled_on
	Globals.set_setting_bool("custom_tracks", toggled_on)
	Globals.main.apply_settings()


func _on_official_tracks_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("official_tracks", toggled_on)
#endregion


#region Управление
func _on_configure_controls_pressed() -> void:
	Globals.main.open_screen(load("uid://5wx4yqp027gq") as PackedScene)


func _on_configure_actions_pressed() -> void:
	if $ActionsConfiguration is InstancePlaceholder:
		($ActionsConfiguration as InstancePlaceholder).create_instance(true)
	($ActionsConfiguration as Window).popup_centered()


func _on_input_options_item_selected(index: int) -> void:
	Globals.set_controls_int("input_method", index)
	Globals.main.apply_controls_settings()
	_toggle_input_method_settings_visibility(index)


func _on_follow_mouse_check_toggled(toggled_on: bool) -> void:
	Globals.set_controls_bool("follow_mouse", toggled_on)


func _on_fire_mode_options_item_selected(index: int) -> void:
	Globals.set_controls_bool("joystick_fire", bool(index))


func _on_sneak_slider_value_changed(value: float) -> void:
	Globals.set_controls_float("sneak_multiplier", value)
	(%SneakValue as Label).text = "x%.2f" % value


func _on_aim_d_zone_slider_value_changed(value: float) -> void:
	Globals.set_controls_float("aim_deadzone", value)
	(%AimZoneSlider as Range).min_value = maxf(value + 0.1, 0.25)
	_aim_visual.queue_redraw()


func _on_aim_zone_slider_value_changed(value: float) -> void:
	Globals.set_controls_float("aim_zone", value)
	_aim_visual.queue_redraw()


func _on_always_aim_check_toggled(toggled_on: bool) -> void:
	Globals.set_controls_bool("always_show_aim", toggled_on)


func _on_joysticks_alpha_slider_value_changed(value: float) -> void:
	Globals.set_controls_float("joysticks_alpha", value)


func _on_aim_visual_draw() -> void:
	var min_side: float = minf(_aim_visual.size.x, _aim_visual.size.y) / 2
	_aim_visual.draw_circle(_aim_visual.size / 2,
			min_side * Globals.get_controls_float("aim_zone"), Color.GREEN, true, -1.0, true)
	_aim_visual.draw_circle(_aim_visual.size / 2,
			min_side * Globals.get_controls_float("aim_deadzone"), Color.RED, true, -1.0, true)
	
	_aim_visual.draw_line(Vector2(_aim_visual.size.x / 2, 0.0),
			Vector2(_aim_visual.size.x / 2, _aim_visual.size.y), Color.BLACK)
	_aim_visual.draw_line(Vector2(0.0, _aim_visual.size.y / 2),
			Vector2(_aim_visual.size.x, _aim_visual.size.y / 2), Color.BLACK)
#endregion
