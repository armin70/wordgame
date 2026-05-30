# main.gd
extends CanvasLayer

var time_left = 20.0
var game_finished = false
var turn_active = false # کنترل حرکت تایمر

func _ready():
	$UIRoot/TimerBar.max_value = time_left
	$UIRoot/TimerBar.value = time_left
	$UIRoot/SubmitButton.pressed.connect(_on_submit_pressed)
	$EndGamePopup/RestartButton.pressed.connect(_on_restart_pressed)
	
func _process(delta):
	if game_finished or not turn_active:
		return

	time_left -= delta

	$UIRoot/TimerLabel.text = str(int(ceil(time_left)))
	$UIRoot/TimerBar.value = time_left

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

func _on_restart_pressed():
	$EndGamePopup.hide()
	restart_game()

func restart_game():
	game_finished = false
	time_left = 20.0
	turn_active = false
	$UIRoot/TimerLabel.text = "20"
	# بقیه دستورات ریست بازی...
