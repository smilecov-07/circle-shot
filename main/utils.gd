class_name Utils

## Класс с различными вспомогательными методами.

## Проверяет имя игрока и исправляет при необходимости. Если [param id] равен 0, не печатает
## никаких предупреждений. В [param valid] можно передать массив, который после выполнения
## функции будет содержать [code]true[/code], если имя игрока допустимо.[br]
## Недопустимое имя заменяется на "Игрок[[param id], если указан]".
static func validate_player_name(player_name: String, id: int = 0,
		valid: Array[bool] = []) -> String:
	# Там, где якобы пусто, стоит пустой символ
	player_name = strip_string(player_name)
	valid.append(not player_name.is_empty())
	if player_name.is_empty():
		var new_name: String = "Игрок%d" % id if id != 0 else "Игрок"
		if id != 0:
			push_warning("Client's %d player name length is invalid. Falling back to %s." % [
				id,
				new_name,
			])
		return new_name
	elif player_name.length() > Game.MAX_PLAYER_NAME_LENGTH:
		if id != 0:
			push_warning("Client's %d player name length (%d) is more than allowed (%d)." % [
				id,
				player_name.length(),
				Game.MAX_PLAYER_NAME_LENGTH,
			])
		return player_name.left(Game.MAX_PLAYER_NAME_LENGTH)
	return player_name


## Возвращает текстовое представление закодированного в двух числах (тип и значение) события ввода.
static func encoded_input_event_as_text(type: Globals.EncodedInputEventType, value: int) -> String:
	match type:
		Globals.EncodedInputEventType.KEY:
			return OS.get_keycode_string(value)
		Globals.EncodedInputEventType.MOUSE_BUTTON:
			match value:
				MOUSE_BUTTON_LEFT:
					return "ЛКМ"
				MOUSE_BUTTON_MIDDLE:
					return "СКМ"
				MOUSE_BUTTON_RIGHT:
					return "ПКМ"
				MOUSE_BUTTON_XBUTTON1:
					return "X1"
				MOUSE_BUTTON_XBUTTON2:
					return "X2"
				MOUSE_BUTTON_WHEEL_DOWN:
					return "Колесо вниз"
				MOUSE_BUTTON_WHEEL_LEFT:
					return "Колесо влево"
				MOUSE_BUTTON_WHEEL_RIGHT:
					return "Колесо вправо"
				MOUSE_BUTTON_WHEEL_UP:
					return "Колесо вверх"
	return "НЕИЗВЕСТНО"


## Возвращает [code]true[/code], если указанный адрес в [param address] может использоваться
## для подключения к серверу. Если [param check_domain] равняется [code]true[/code], то
## также выполняется проверка существования домена (если указан не IP-адрес).
static func is_valid_address(address: String, check_domain: bool) -> bool:
	return (
			address.is_valid_ip_address()
			or (address.count('.') > 0 and address.find('.') > 0
			and address.rfind('.') < address.length() - 1)
			and not (check_domain and IP.resolve_hostname(address).is_empty())
	)


## Избавляет строку от различных вспомогательных символов (пробелы, ...).
static func strip_string(string: String) -> String:
	return string.strip_edges().strip_escapes().lstrip('⁣').rstrip('⁣')
