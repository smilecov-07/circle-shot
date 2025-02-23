class_name UPNPManager
extends Node


## Издаётся, когда UPnP меняет свой статус.
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
## Текущий статус UPnP.
var status := Status.INACTIVE
var _forwarded_port: int = -1
var _task_id: int = -1
var _upnp := UPNP.new()
var _upnp_devices: Array[UPNPDevice]


func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = 300.0
	timer.timeout.connect(_on_update_timer_timeout)
	timer.name = &"UpdateTimer"
	timer.autostart = true
	add_child(timer)


## Завершает UPnP.
func finalize() -> void:
	if not WorkerThreadPool.is_task_completed(_task_id):
		WorkerThreadPool.wait_for_task_completion(_task_id)
	
	if _forwarded_port > 0:
		for device: UPNPDevice in _upnp_devices:
			device.delete_port_mapping(_forwarded_port)
		print_verbose("UPnP: devices port %d forwarding deleted." % _forwarded_port)
		_forwarded_port = 0


## Ищет устройства UPnP в локальной сети.
func discover() -> void:
	if not status in [Status.INACTIVE, Status.ACTIVE] \
			or _task_id > 0 and not WorkerThreadPool.is_task_completed(_task_id):
		push_error("UPnP: can't discover - busy.")
		return
	
	print_verbose("UPnP: discovering devices...")
	status = Status.DISCOVERING
	status_changed.emit(status)
	_upnp_devices.clear()
	_task_id = WorkerThreadPool.add_task(_discover_task)


## Пытается открыть порт [param port].
func forward_port(port: int) -> void:
	if status != Status.ACTIVE:
		push_error("UPnP: not active to forward ports.")
		return
	
	print_verbose("UPnP: forwarding port %d..." % port)
	status = Status.MAPPING_PORTS
	status_changed.emit(status)
	_task_id = WorkerThreadPool.add_task(_forward_port_task.bind(port))


## Возвращает глобальный IP.
func get_external_ip() -> String:
	if status != Status.ACTIVE:
		push_error("UPnP: querying external IP failed: not active.")
	return _upnp_devices[0].query_external_address()


func _discover_task() -> void:
	var err: UPNP.UPNPResult = _upnp.discover(2000, 2, "") as UPNP.UPNPResult
	
	if err != UPNP.UPNP_RESULT_SUCCESS:
		push_error("UPnP: discover failed with error %d. Ensure UPnP is enabled on your router."
				% err)
		set_deferred(&"status", Status.INACTIVE)
		status_changed.emit.call_deferred(status)
		return
	
	for i: int in _upnp.get_device_count():
		var device: UPNPDevice = _upnp.get_device(i)
		print_verbose("UPnP: found device with status %d." % device.igd_status)
		if device.is_valid_gateway():
			_upnp_devices.append(device)
	
	if _upnp_devices.is_empty():
		push_error("UPnP: can't find valid gateways.")
		set_deferred(&"status", Status.INACTIVE)
		status_changed.emit.call_deferred(status)
		return
	print_verbose("UPnP: found %d valid gateways." % _upnp_devices.size())
	
	set_deferred(&"status", Status.ACTIVE)
	status_changed.emit.call_deferred(status)


func _forward_port_task(port: int) -> void:
	if _forwarded_port > 0:
		for device: UPNPDevice in _upnp_devices:
			device.delete_port_mapping(_forwarded_port)
		print_verbose("UPnP: port %d forwarding deleted." % _forwarded_port)
	
	var errors: Array[String]
	for i: int in _upnp_devices.size():
		var err: UPNP.UPNPResult = _upnp_devices[i].add_port_mapping(port, port, str(port) + " for "
				+ str(ProjectSettings.get_setting("application/config/name"))) as UPNP.UPNPResult
		if err != UPNP.UPNP_RESULT_SUCCESS:
			errors.append("UPnP: device %d port %d forward failed with error %d." % [i, port, err])
	
	if errors.size() == _upnp_devices.size():
		for error: String in errors:
			push_error(error)
		set_deferred(&"_forwarded_port", -1)
		set_deferred(&"status", Status.INACTIVE)
		status_changed.emit.call_deferred(status)
		return
	
	for error: String in errors:
		print_verbose(error)
	print_verbose("UPnP: forwarded port %d on %d devices." % [
		port,
		_upnp_devices.size() - errors.size()
	])
	
	set_deferred(&"_forwarded_port", port)
	set_deferred(&"status", Status.ACTIVE)
	status_changed.emit.call_deferred(status)


func _on_update_timer_timeout() -> void:
	if status != Status.ACTIVE:
		return
	
	discover()
	await status_changed
	
	if status == Status.INACTIVE:
		return
	
	forward_port(_forwarded_port)
	await status_changed
	
	if status == Status.ACTIVE and \
			(OS.is_stdout_verbose() or DisplayServer.get_name() == "headless"):
		print("UPnP updated. External IP: %s" % get_external_ip())
