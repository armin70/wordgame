extends Control
var player_turn: bool = false
var user_click_time: float
var bot_decision_time: float
# فریم‌های انیمیشن
enum Choice {ROCK, PAPER, SCISSORS}
const PAPER = preload("uid://bpxpekxkntnxc")
const ROCK = preload("uid://ww2v4le4n3cp")
const SCISSOR = preload("uid://bji4rmdljiynn")
@onready var bot_choice_texture: TextureRect = $CanvasLayer/BotChoice
@onready var result: Label = $CanvasLayer/result

@onready var rps_anim = $CanvasLayer/Area2D/RPSAnimationPlayer# انیمیشن شما
var current_choice: Choice

func _ready():
	bot_decision_time = randf_range(0.5, 3.0)
	rps_anim.play("loop_rps") # انیمیشن را در حالت لوپ اجرا کنید

func check_selection():
	var frame = rps_anim.frame
	user_click_time = Time.get_ticks_msec() / 1000.0
	if frame == 0:
		current_choice = Choice.ROCK
		print("سنگ")
	elif frame == 1:
		current_choice = Choice.PAPER
		print("کاغذ")
	elif frame == 2:
		current_choice = Choice.SCISSORS
		print("قیچی")
		
	# بعد از انتخاب، انیمیشن را متوقف کنید یا به مرحله بعد بروید
	rps_anim.stop()
	play_result_animation()
	

func play_result_animation():
	rps_anim.stop()
	
	# ۱. زمان واکنش ربات (یک عدد تصادفی بین ۰.۵ تا ۱.۵ ثانیه)
	var bot_reaction_time = randf_range(0.5, 1.5)
	print("ربات در حال فکر کردن است...")
	await get_tree().create_timer(bot_reaction_time).timeout

	
	var bot_choice = randi() % 3
	print("انتخاب بات: ", bot_choice, " | انتخاب شما: ", current_choice)
	if bot_choice == 0:
		bot_choice_texture.texture = ROCK
	elif bot_choice == 1:
		bot_choice_texture.texture = PAPER
	elif bot_choice == 2:
		bot_choice_texture.texture = SCISSOR
	# ۲. بررسی نتیجه
	var draw =(current_choice == 0 and bot_choice == 0) or \
					 (current_choice == 1 and bot_choice == 1) or \
					 (current_choice == 2 and bot_choice == 2)
	if draw:
		if user_click_time < bot_decision_time:
			print("شما زودتر سابمیت کردید! شما برنده شدید.")
			result.text = "شما برنده شدید"
			PuzzleManager.is_player_turn = true
		else:
			print("ربات سریع‌تر بود! او شروع‌کننده است.")
			result.text = "ربات برنده شد"
			PuzzleManager.is_player_turn = true
	

	# ۳. تعیین برنده
	var player_won = (current_choice == 0 and bot_choice == 2) or \
					 (current_choice == 1 and bot_choice == 0) or \
					 (current_choice == 2 and bot_choice == 1)

	if player_won:
		print("شما بردید! شما شروع‌کننده هستید.")
		result.text = "شما برنده شدید"
		PuzzleManager.is_player_turn = true
		player_turn = true
	else:
		PuzzleManager.is_player_turn = false
		print("ربات برد! او شروع‌کننده است.")
		result.text = "ربات برنده شد"
		player_turn = false
	await get_tree().create_timer(1.5).timeout 
	start_main_game()


func start_main_game():
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("check")
		check_selection()
