# main.gd
extends Control

var time_left = 15.0
var game_finished = false
var turn_active = false # کنترل حرکت تایمر

func _ready():
	$UIRoot/SubmitButton.pressed.connect(_on_submit_pressed)
	$UIRoot/ClearButton.pressed.connect(_on_clear_pressed)
	$EndGamePopup/RestartButton.pressed.connect(_on_restart_pressed)
	
func _process(delta):
	if game_finished or not turn_active:
		return

	# تایمر فقط زمانی کم می‌شود که نوبت فعالِ بازیکن باشد
	if $Puzzle.current_turn == "player":
		time_left -= delta
		$UIRoot/TimerLabel.text = "زمان: " + str(int(ceil(time_left)))

		if time_left <= 0:
			turn_active = false # توقف تایمر
			time_left = 0
			$UIRoot/TimerLabel.text = "زمان تمام!"
			$Puzzle.turn_over() # انتقال نوبت به ربات

func reset_timer():
	print("Timer Reset")
	time_left = 15.0
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
	time_left = 15.0
	turn_active = false
	$UIRoot/TimerLabel.text = "زمان: 15"
	# بقیه دستورات ریست بازی...
