extends Control


var _udp := UDPServer.new()
var _local_lobby_entry_scene: PackedScene = preload("uid://bs4vk7wdu27eo")
@onready var _game: Game = get_parent()
@onready var _ip_edit: LineEdit = %IPEdit
@onready var _lobbies_container: VBoxContainer = %LobbiesContainer
@onready var _no_lobbies_label: Label = %NoLobbiesLabel


func _ready() -> void:
	_game.created.connect(_on_game_created)
	_game.joined.connect(_on_game_joined)
	_game.closed.connect(_on_game_closed)
	
	if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		var clipboard_text: String = _cleanup_ip(DisplayServer.clipboard_get().get_slice('\n', 0))
		if clipboard_text.is_valid_ip_address():
			_ip_edit.text = clipboard_text
	
	_udp.listen(Game.LISTEN_PORT)
	print_verbose("Started listening.")


func _process(_delta: float) -> void:
	if not _udp.is_listening():
		return
	
	_udp.poll()
	if _udp.is_connection_available():
		var peer: PacketPeerUDP = _udp.take_connection()
		var data: PackedByteArray = peer.get_packet()
		if data.size() < 4:
			print_verbose("Found invalid lobby packet.")
			return
		var id_nodepath := NodePath("Lobby%d" % data[0])
		var player_name: String = Game.validate_player_name(data.slice(4).get_string_from_utf8())
		var players: int = data[1]
		var max_players: int = data[2]
		if data[3] < 0 or data[3] >= Globals.items_db.events.size():
			print_verbose("Found lobby packet with invalid event ID.")
			return
		var event: String = Globals.items_db.events[data[3]].name
		print_verbose("Found lobby: %s (%d/%d) with ID %d with event %s (ID: %d) at IP: %s." % [
			player_name,
			players,
			max_players,
			data[0],
			event,
			data[3],
			peer.get_packet_ip(),
		])
		
		if _lobbies_container.has_node(id_nodepath):
			var local_lobby_entry: Button = _lobbies_container.get_node(id_nodepath)
			(local_lobby_entry.get_node(^"Timer") as Timer).start()
			local_lobby_entry.text = "%s (%d/%d)\n%s" % [player_name, players, max_players, event]
			local_lobby_entry.pressed.disconnect(_game.join)
			local_lobby_entry.pressed.connect(_game.join.bind(peer.get_packet_ip()))
			print_verbose("Lobby %d already in list. Updating IP and timer." % data[0])
		else:
			var local_lobby_entry: Button = _local_lobby_entry_scene.instantiate()
			local_lobby_entry.name = id_nodepath.get_concatenated_names() # Конвертация в StringName
			local_lobby_entry.text = "%s (%d/%d)\n%s" % [player_name, players, max_players, event]
			local_lobby_entry.pressed.connect(_game.join.bind(peer.get_packet_ip()))
			_lobbies_container.add_child(local_lobby_entry)
			print_verbose("Lobby %d added to the list." % data[0])
	
	_no_lobbies_label.visible = _lobbies_container.get_child_count() == 0


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST when _game.state == Game.State.CLOSED:
			_on_quit_pressed.call_deferred() # Избегаем мгновенное закрытие


func _cleanup_ip(ip: String) -> String:
	ip = ip.strip_edges().strip_escapes()
	if ip.contains(' '):
		ip = ip.get_slice(' ', 0)
	ip = ip.strip_edges().strip_escapes()
	
	if ip.begins_with("https://"):
		ip = ip.right(-8) # длина https://
	if ip.begins_with("http://"):
		ip = ip.right(-7) # аналогично
	
	# проверка на указания порта
	if ':' in ip:
		var last_colon_idx: int = ip.rfind(':')
		var last_bracket_idx: int = ip.rfind(']')
		if '.' in ip:
			ip = ip.left(last_colon_idx)
		elif last_bracket_idx > -1 and last_bracket_idx < last_colon_idx:
			ip = ip.left(last_colon_idx)
	
	# на случай если IPv6
	ip = ip.lstrip('[')
	ip = ip.rstrip(']')
	return ip


func _on_game_created() -> void:
	hide()
	_udp.stop()
	print_verbose("Listening stopped.")


func _on_game_joined() -> void:
	hide()
	_udp.stop()
	print_verbose("Listening stopped.")


func _on_game_closed() -> void:
	show()
	_udp.listen(Game.LISTEN_PORT)
	print_verbose("Listening restarted.")


func _on_create_pressed() -> void:
	_game.create()


func _on_join_pressed() -> void:
	_ip_edit.text = _cleanup_ip(_ip_edit.text)
	_game.join(_ip_edit.text)


func _on_quit_pressed() -> void:
	Globals.main.open_menu()
