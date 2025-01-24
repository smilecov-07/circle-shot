class_name UPNPManager
extends Node


signal status_changed
## Статус UPnP.
enum Status {
	## Отключено в настройках.
	INACTIVE = 0,
	## Поиск UPnP устройств.
	DISCOVERING = 1,
	## Открытие портов.
	MAPPING_PORTS = 2,
	## Подключено.
	ACTIVE = 3,
}
var status := Status.INACTIVE
var _forwarded_port: int = -1
var _thread := Thread.new()
var _mutex := Mutex.new()
var _semaphore := Semaphore.new()
var _command: int = 0 # 0 - ждать, -1 - discover, -2 - выйти, >0 - открыть порт
var _upnp := UPNP.new()


func _ready() -> void:
	_thread.start(_upnp_thread, Thread.PRIORITY_LOW)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_EXIT_TREE:
			_mutex.lock()
			_command = -2
			_mutex.unlock()
			_semaphore.post()
			_thread.wait_to_finish()
			
			if _forwarded_port > 0:
				_upnp.delete_port_mapping(_forwarded_port)
				print_verbose("UPnP: port %d forwarding deleted." % _forwarded_port)


func discover() -> void:
	if not status in [Status.INACTIVE, Status.ACTIVE]:
		push_error("UPnP: can't discover - busy.")
		return
	
	print_verbose("UPnP: discovering devices...")
	status = Status.DISCOVERING
	status_changed.emit(status)
	_mutex.lock()
	_command = -1
	_mutex.unlock()
	_semaphore.post()


func forward_port(port: int) -> void:
	if status != Status.ACTIVE:
		push_error("UPnP: not active to map ports.")
		return
	
	print_verbose("UPnP: forwarding port %d..." % port)
	status = Status.MAPPING_PORTS
	status_changed.emit(status)
	_mutex.lock()
	_command = port
	_mutex.unlock()
	_semaphore.post()


func get_external_ip() -> String:
	if status != Status.ACTIVE:
		push_error("UPnP: querying external IP failed: not active.")
	return _upnp.query_external_address()


func _upnp_thread() -> void:
	while true:
		_semaphore.wait()
		
		_mutex.lock()
		var command: int = _command
		_command = 0
		_mutex.unlock()
		
		match command:
			0:
				pass
			-1:
				_discover_internal()
			-2:
				break
			var port:
				_forward_port_internal(port)


func _discover_internal() -> void:
	var err: UPNP.UPNPResult = _upnp.discover() as UPNP.UPNPResult
	
	if err != UPNP.UPNP_RESULT_SUCCESS:
		push_error("UPnP: discover failed with error %d. Ensure UPnP is enabled on your router."
				% err)
		set_deferred(&"status", Status.INACTIVE)
		status_changed.emit.call_deferred(status)
		return
	
	if not _upnp.get_gateway():
		push_error("UPnP: couldn't get gateaway.")
		set_deferred(&"status", Status.INACTIVE)
		status_changed.emit.call_deferred(status)
		return
	
	if not _upnp.get_gateway().is_valid_gateway():
		push_error("UPnP: gateaway is invalid.")
		set_deferred(&"status", Status.INACTIVE)
		status_changed.emit.call_deferred(status)
		return
	
	set_deferred(&"status", Status.ACTIVE)
	status_changed.emit.call_deferred(status)


func _forward_port_internal(port: int) -> void:
	if _forwarded_port > 0:
		_upnp.delete_port_mapping(_forwarded_port)
		print_verbose("UPnP: port %d forwarding deleted.")
	
	var err: UPNP.UPNPResult = _upnp.add_port_mapping(port, port, str(port) + " for " +
			str(ProjectSettings.get_setting("application/config/name"))) as UPNP.UPNPResult
	
	if err != UPNP.UPNP_RESULT_SUCCESS:
		push_error("UPnP: %d port forward failed with error %d. " % [port, err])
		set_deferred(&"_forwarded_port", -1)
		set_deferred(&"status", Status.INACTIVE)
		status_changed.emit.call_deferred(status)
		return
	
	set_deferred(&"_forwarded_port", port)
	set_deferred(&"status", Status.ACTIVE)
	status_changed.emit.call_deferred(status)
