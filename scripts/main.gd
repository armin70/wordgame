# main.gd
extends Control
@onready var game_container: AspectRatioContainer = $gameContainer
var max_time = 20
var time_left = 20
var game_finished = false
var turn_active = false # کنترل حرکت تایمر
@export var max_aspect : float = 1.0
func _ready():

	if PuzzleManager.is_multiplayer:
		$gameContainer/game_scene.visible = false
		$gameContainer/multiplayer.visible = true
		max_time = 35
	else:
		$gameContainer/game_scene.visible = true
		$gameContainer/multiplayer.visible = false
		max_time = 20
	_set_aspect()
	#$gameContainer/game_scene/TimerBar.max_value = max_time
	#$gameContainer/multiplayer/TimerBar.max_value = max_time
	#$gameContainer/game_scene/TimerBar.value = max_time
	#$gameContainer/multiplayer/TimerBar.value = max_time
	#$gameContainer/game_scene/SubmitButton.pressed.connect(_on_submit_pressed)
func _set_aspect():
	var vp_rect = get_viewport_rect()
	var aspect = vp_rect.size.x / vp_rect.size.y
	
	aspect = min(max_aspect, aspect)
	
	game_container.ratio = aspect

#func _process(delta):
	#if game_finished or not turn_active:
		#return

	#time_left -= delta

	#$gameContainer/game_scene/TimerLabel.text = str(int(ceil(time_left)))
	#$gameContainer/game_scene/TimerBar.value = time_left
	#$gameContainer/multiplayer/TimerLabel.text = str(int(ceil(time_left)))
	#$gameContainer/multiplayer/TimerBar.value = time_left
	#if time_left <= 0:
		#turn_active = false
		#time_left = 0
		#print('time is over')
		#$gameContainer/game_scene.turn_over()
		#$gameContainer/multiplayer.turn_over()
		
func reset_timer():
	print("Timer Reset")
	time_left = max_time
	turn_active = true # فعال شدن تایمر برای نوبت بازیکن

func stop_timer():
	turn_active = false

func _on_submit_pressed():
	SocketManager._handle_test()

func _on_clear_pressed():
	if not game_finished:
		$gameContainer/game_scene.clear_current_word()


func restart_game():
	game_finished = false
	time_left = max_time
	turn_active = false
	$gameContainer/game_scene/TimerLabel.text = str(max_time)
	$gameContainer/multiplayer/TimerLabel.text = str(max_time)


func _on_resized() -> void:
	if is_node_ready():
		_set_aspect()
