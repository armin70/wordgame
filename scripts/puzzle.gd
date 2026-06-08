extends Control

var valid_words = []
var found_words = []
var word_owners = {}
var player_hp := 40
var bot_hp := 40
var max_hp := 40
var current_word = ""
var score = 0
var bot_score = 0
var debuff = 0
var multiplier = 1
var game_finished := false
var current_turn := ""
var prev_puzzles = []

var pending_puzzles = [] 
var current_board = ""
# =========================
# Letter Textures
# =========================


# =========================
# UI
# =========================
var input_enabled := true
var current_puzzle_index = 0

@onready var letters_container = $Puzzle/LettersContainer
@onready var end_popup = $"EndGamePopup"
@onready var result_label = $"EndGamePopup/VBoxContainer/ResultLabel"

@onready var player_hp_label : Label = $"PlayerHP"
@onready var bot_hp_label : Label = $"BotHP"
@onready var total_timer_label: Label = $TotalTimerLabel

@onready var score_label = $"ScoreLabel"
@onready var feedback_label = $"FeedbackLabel"
@onready var found_count_label = $"FoundCountLabel"
@onready var found_words_container = $"FoundWords"
@onready var current_word_label = $"CurrentWordLabel"
@onready var bot_score_label = $"BotScoreLabel"
@onready var bot_status_label = $"BotStatusLabel"
var total_seconds: float = 0.0

func _ready():

	$"PlayerHPBar".max_value = max_hp

	$"PlayerHP".text = str(player_hp)
	$"BotHP".text = str(bot_hp)
	start_game()
	
	# connect buttons


func get_formatted_time() -> String:
	var minutes = int(total_seconds) / 60
	var seconds = int(total_seconds) % 60
	return "%02d:%02d" % [minutes, seconds]

func _process(delta):
	total_seconds += delta
	# آپدیت کردن متن لیبل با تایمر جهانی
	total_timer_label.text = get_formatted_time()
# =========================
# START PUZZLE
# =========================



func start_game():
	valid_words = []
	found_words.clear()
	word_owners.clear()
	score = 0
	bot_score = 0
	current_word = ""
	#selecting = false
	game_finished = false
	#_clear_all_selections()
	update_hp_ui()
	player_hp = max_hp
	bot_hp = max_hp
	score_label.text = "امتیاز: 0"
	feedback_label.text = ""
	#found_count_label.text = "0 / " + str(valid_words.size())
	current_word_label.text = ""
	bot_score_label.text = "Bot: 0"
	bot_status_label.text = ""


	_clear_found_words_ui()
	if PuzzleManager.is_player_turn:
		_start_player_turn()
	else:
		_start_bot_turn()

func apply_word_effect(word: String, owner: String):
	var damage = word.length()
	 
	if owner == "player":
		bot_hp -= ((multiplier + 2)  * damage) - debuff

		var bar = $BotHPBar
		bar.modulate = Color(1, 0.3, 0.3)
		create_tween().tween_property(bar, "modulate", Color(1,1,1), 0.4)
		print('playeeeeeeeeeer:',((multiplier + 2)  * damage) - debuff)
	else:
		player_hp -= ((multiplier + 2)  * damage) - debuff

		var bar = $"PlayerHPBar"
		bar.modulate = Color(1, 0.3, 0.3)
		create_tween().tween_property(bar, "modulate", Color(1,1,1), 0.4)
		print('boooooooooot:',((multiplier + 2)  * damage) - debuff)
	update_hp_ui()
	check_game_over()
func check_game_over():

	if player_hp <= 0:
		game_finished = true
		get_parent().get_parent().game_finished = true
		get_parent().get_parent().turn_active = false

		#set_buttons_enabled(false)

		result_label.text = "💀 شما باختید!"
		end_popup.popup_centered()

	elif bot_hp <= 0:
		game_finished = true
		get_parent().get_parent().game_finished = true
		get_parent().get_parent().turn_active = false

		#set_buttons_enabled(false)

		result_label.text = "🏆 شما برنده شدید!"
		end_popup.popup_centered()


func update_hp_ui():
	player_hp_label.text = str(player_hp)
	bot_hp_label.text = str(bot_hp)

	create_tween().tween_property($"PlayerHPBar", "value", player_hp, 0.3)
	create_tween().tween_property($BotHPBar, "value", bot_hp, 0.3)
func _start_player_turn():
	if game_finished: return
	update_turn_ui()
	current_turn = "player"
	#set_buttons_enabled(true)
	bot_status_label.text = "نوبت شماست"
	
	# فعال کردن و ریست تایمر در اسکریپت اصلی
	get_parent().get_parent().reset_timer()
	update_turn_ui()
	



# =========================
# SUBMIT
# =========================

func submit_current_word():

	if current_word in valid_words \
	and current_word not in found_words:

		found_words.append(current_word)

		score += current_word.length()

		score_label.text = "امتیاز: " + str(score)

		#found_count_label.text = str(found_words.size()) \
		#+ " / " + str(valid_words.size())
		
		feedback_label.text = "✅ درست"
		apply_word_effect(current_word, "player")
		add_found_word(current_word,'player')
		$RPSContainer.remove_type(current_board)
		$RPSContainer.get_debuff(current_board)
		$"puzzle container".board_buff(current_board)
		turn_over()
	else:

		feedback_label.text = "❌ غلط"

	$"puzzle container"._clear_all_selections()
func _start_bot_turn():
	if game_finished or current_turn == "bot":
		return
	update_turn_ui()
	current_turn = "bot"
	#set_buttons_enabled(false)

	get_parent().get_parent().reset_timer()

	await perform_bot_move()

	if not game_finished:
		_start_player_turn()
	
func perform_bot_move():
	bot_status_label.text = "ربات در حال فکر کردن..."
	var bot_found = false
	current_board = ["Rock","Paper","Scissors"].pick_random()
	print("current board:",current_board)
	while not bot_found:
		var available_words = []
		for w in valid_words:
			if w not in found_words:
				available_words.append(w)
				
		if available_words.size() == 0:
			bot_status_label.text = "کلمه‌ای نمانده!"
			await get_tree().create_timer(1.5).timeout
			break
		
		var thinking_time = randf_range(1.5, 2.5)
		await get_tree().create_timer(thinking_time).timeout
		
		if randf() > 0.3:
			var chosen = available_words.pick_random()
			get_parent().get_parent().stop_timer()
			$RPSContainer.remove_type(current_board)
			$RPSContainer.get_debuff(current_board)
			
			print("bot multi: ",multiplier)
			found_words.append(chosen)
			word_owners[chosen] = "bot"
			current_word=""
			for ch in chosen:
				current_word += ch
				current_word_label.text = current_word
				await get_tree().create_timer(0.2).timeout
			add_found_word(chosen, "bot")
			update_score()
			update_bot_score()
			apply_word_effect(chosen, "bot")
			#update_found_count()
			feedback_label.text = "ربات کلمه '" + chosen + "' را پیدا کرد."
			
			await get_tree().create_timer(1.5).timeout
			bot_found = true 
		else:
			feedback_label.text = "ربات به بن‌بست رسید، دوباره بررسی می‌کند..."
			await get_tree().create_timer(1.2).timeout

	bot_status_label.text = ""

var my_font = preload("res://assets/fonts/Lalezar-Regular.ttf")
func add_found_word(word, owner):
	var label = Label.new()
	var settings = LabelSettings.new()

	if owner == "player":
		label.text = "🟢 " + word
	else:
		label.text = "🔴 " + word

	settings.font_color = Color("#000000")
	settings.font_size = 30
	settings.font = my_font

	label.label_settings = settings

	found_words_container.add_child(label)

func _clear_found_words_ui():
	for child in found_words_container.get_children():
		child.queue_free()

func update_score():
	score_label.text = "امتیاز: " + str(score)

func update_bot_score():
	bot_score_label.text = "Bot: " + str(bot_score)

#func update_found_count():
	#found_count_label.text = str(found_words.size()) + " / " + str(valid_words.size())

#func set_buttons_enabled(enabled):
	#input_enabled = enabled
#
	#for button in letters_container.get_children():
		#if button is Button:
			#button.modulate = Color(1,1,1,1) if enabled else Color(0.5,0.5,0.5,1)

#func check_game_complete():
	#if game_finished:
		#return
#
	#if found_words.size() >= valid_words.size():
		#game_finished = true
		#set_buttons_enabled(false)
	

func turn_over():

	if current_turn == "player":
		_start_bot_turn()

	elif current_turn == "bot":
		_start_player_turn()
		
#func _reset_puzzle():
	#var new_puzzle = SocketManager.get_offline_test_puzzle()
	#var try_count=0
	#while new_puzzle.id in prev_puzzles:
		#try_count += 1
		#new_puzzle = SocketManager.get_offline_test_puzzle()
		#if try_count > 10:
			#break
	#prev_puzzles.append(new_puzzle.id)
	#letters = new_puzzle["letters"]
	#valid_words = []
#
	## استخراج کلمات و وزن‌ها از ساختار جدید
	#for w in new_puzzle["words"]:
		#var word_str = w["word"]
		#var weight_val = w.get("weight", 1) # اگر وزن نداشت پیش‌فرض ۱
		#
		#valid_words.append(word_str)
	#_generate_letter_buttons()
#
#

# =========================
# BUTTONS
# =========================


func _on_submit_button_pressed() -> void:
	if current_word != "":
		submit_current_word()

	else:
		pass


#func _on_clear_button_pressed() -> void:
	#_clear_all_selections()


#func _on_reset_puzzle_pressed() -> void:
	#_reset_puzzle()
#

func _on_shuffle_pressed() -> void:
	$"puzzle container".shuffle_letters()
	
		
func flash_hp(label: Label, color: Color) -> void:
	var original = label.modulate
	label.modulate = color
	
	await get_tree().create_timer(1).timeout
	
	label.modulate = original

func update_turn_ui():
	print("Current turn:", current_turn)

	var player_bar = $PlayerHPBar
	var bot_bar = $BotHPBar

	if current_turn == "player":
		player_bar.modulate = Color(0.5, 0.5, 0.5)
		bot_bar.modulate = Color.WHITE
	else:
		player_bar.modulate = Color.WHITE
		bot_bar.modulate = Color(0.5, 0.5, 0.5)
func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()


func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_next_puzzle_pressed() -> void:
	$"puzzle container".load_next_puzzle()


func _on_prev_puzzle_pressed() -> void:
	$"puzzle container".load_prev_puzzle()
