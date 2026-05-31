# main.gd
extends Control
@onready var game_container: AspectRatioContainer = $gameContainer

var time_left = 20.0
var game_finished = false
var turn_active = false # کنترل حرکت تایمر
@export var max_aspect : float = 1.0
func _ready():
	_set_aspect()
	$gameContainer/UIRoot/TimerBar.max_value = time_left
	$gameContainer/UIRoot/TimerBar.value = time_left
	$gameContainer/UIRoot/SubmitButton.pressed.connect(_on_submit_pressed)
	
func _set_aspect():
	var vp_rect = get_viewport_rect()
	var aspect = vp_rect.size.x / vp_rect.size.y
	
	aspect = min(max_aspect, aspect)
	
	game_container.ratio = aspect

func _process(delta):
	if game_finished or not turn_active:
		return

	time_left -= delta

	$gameContainer/UIRoot/TimerLabel.text = str(int(ceil(time_left)))
	$gameContainer/UIRoot/TimerBar.value = time_left

	if time_left <= 0:
		turn_active = false
		time_left = 0
		$Puzzle.turn_over()
		
func reset_timer():
	print("Timer Reset")
	time_left = 20.0
	turn_active = true # فعال شدن تایمر برای نوبت بازیکن

func stop_timer():
	turn_active = false

func _on_submit_pressed():
	SocketManager._handle_test()

func _on_clear_pressed():
	if not game_finished:
		$Puzzle.clear_current_word()


func restart_game():
	game_finished = false
	time_left = 20.0
	turn_active = false
	$gameContainer/UIRoot/TimerLabel.text = "20"
	


func _on_resized() -> void:
	if is_node_ready():
		_set_aspect()
