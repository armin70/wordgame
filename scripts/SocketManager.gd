extends Node

const SocketIOClient = preload("res://scripts/client.gd")
var use_offline_puzzle := true 
var client: SocketIOClient
var backend_url: String
signal puzzle_received(data)
func _ready():
	
	backend_url = "http://127.0.0.1:5010/socket.io"
	client = SocketIOClient.new(backend_url, {})
	client.on_engine_connected.connect(_on_socket_ready)
	client.on_connect.connect(_on_socket_connect)
	client.on_event.connect(_on_socket_event)

	add_child(client)

func _on_socket_ready(_sid: String):
	client.socketio_connect()

func _on_socket_connect(_payload: Variant, _name_space, error: bool):
	if error:
		push_error("خطا در اتصال به سرور Socket.IO")
	else:
		print("اتصال موفق به سرور برقرار شد.")
		client.socketio_send("get_puzzle", {"index": 0})

# --- مدیریت رویدادها ---
func _on_socket_event(event_name: String, payload: Variant, _name_space):
	
	match event_name:
		"room_created":
			_handle_room_created(payload)
		"room_joined":
			_handle_room_joined(payload)
		"word_accepted":
			_handle_word_accepted(payload)
		"word_rejected":
			print("کلمه رد شد:", payload)
		"game_over":
			_handle_game_over(payload)
		"puzzle_data":
			_handle_puzzle(payload)
		_:
			print("رویداد ناشناس:", event_name, payload)

	
	match event_name:
		"room_created":
			_handle_room_created(payload)

		"room_joined":
			_handle_room_joined(payload)

		"word_accepted":
			_handle_word_accepted(payload)

		"word_rejected":
			print("کلمه رد شد:", payload)

		"game_over":
			_handle_game_over(payload)

		"puzzle_data":
			_handle_puzzle(payload)
# --- متدهای ارسال پیام ---
func emit(event_name: String, data: Dictionary):
	client.socketio_send(event_name, data)
	

func _handle_puzzle(data):
	puzzle_received.emit(data)
# --- توابع منطقی ---
func _handle_room_created(data):
	print("اتاق ساخته شد: ", data)
	# سیگنال برای آپدیت UI
	# EventBus.emit_signal("ui_update_room", data)

func _handle_room_joined(data):
	print("عضو شدید: ", data)
func _handle_test():
	client.socketio_send("test")
func _handle_word_accepted(data):
	print("کلمه پذیرفته شد: ", data)

func _handle_game_over(data):
	print("بازی تمام شد: ", data)

	
func _exit_tree():
	client.socketio_disconnect()


func get_offline_test_puzzle() -> Dictionary:
	var path = "res://data/levels.json"
	if not FileAccess.file_exists(path):
		push_error("فایل پازل در آدرس " + path + " پیدا نشد!")
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("خطا در پارس کردن فایل JSON")
		return {}

	var data = json.data
	
	# اگر داده‌ها در یک آرایه هستند، یکی را رندوم انتخاب کن
	if data is Array:
		return data[randi() % data.size()]
	return data # اگر کلاً یک آبجکت است
