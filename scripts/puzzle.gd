extends Control

var letters = []
var valid_words = []
var found_words = []
var word_owners = {}

var current_word = ""
var score = 0
var bot_score = 0
var bot_timer = null
const LetterButtonScene  = preload("uid://od34dlw3bmb4")

var selected_buttons: Array = []
var selecting := false
var game_finished := false
var turn_timer_running := false
var current_turn := ""
var turn_time_left := 15
var turn_time_limit :=15
var prev_puzzles =[]
@onready var letters_container = $LettersContainer
@onready var score_label = $"../UIRoot/ScoreLabel"
@onready var feedback_label = $"../UIRoot/FeedbackLabel"
@onready var found_count_label = $"../UIRoot/FoundCountLabel"
@onready var found_words_container = $"../UIRoot/FoundWords"
@onready var current_word_label = $"../UIRoot/CurrentWordLabel"
@onready var bot_score_label = $"../UIRoot/BotScoreLabel"
@onready var bot_status_label = $"../UIRoot/BotStatusLabel"
var word_weights = {}
func _ready():
	SocketManager.puzzle_received.connect(start_puzzle)
	if SocketManager.use_offline_puzzle:
		await get_tree().process_frame 
		var offline_data = SocketManager.get_offline_test_puzzle()
		if !offline_data.is_empty():
			prev_puzzles.append(offline_data.id)
			start_puzzle(offline_data)
	for button in letters_container.get_children():
		if button is Button:
			var c = Callable(self, "_on_button_gui_input").bind(button)
			button.gui_input.connect(c)



func start_puzzle(data: Dictionary):
	letters = data["letters"]
	valid_words = []
	word_weights.clear()

	# استخراج کلمات و وزن‌ها از ساختار جدید
	for w in data["words"]:
		var word_str = w["word"]
		var weight_val = w.get("weight", 1) # اگر وزن نداشت پیش‌فرض ۱
		
		valid_words.append(word_str)
		word_weights[word_str] = weight_val

	# ریست کردن وضعیت بازی
	found_words.clear()
	word_owners.clear()
	score = 0
	bot_score = 0
	current_word = ""
	selecting = false
	game_finished = false
	_clear_all_selections()

	# آپدیت UI
	score_label.text = "امتیاز: 0"
	feedback_label.text = ""
	found_count_label.text = "0 / " + str(valid_words.size())
	current_word_label.text = ""
	bot_score_label.text = "Bot: 0"
	bot_status_label.text = ""

	_clear_found_words_ui()
	set_buttons_enabled(true)
	
	#start_bot() 

	_generate_letter_buttons()
	_start_player_turn()

func _start_player_turn():
	if game_finished: return
	
	current_turn = "player"
	set_buttons_enabled(true)
	bot_status_label.text = "نوبت شماست"
	
	# فعال کردن و ریست تایمر در اسکریپت اصلی
	get_parent().reset_timer()


func _generate_letter_buttons():

	for child in letters_container.get_children():
		child.queue_free()

	var radius = 150
	var count = letters.size()
	var center = letters_container.size / 2

	for i in range(count):

		var angle = (TAU / count) * i

		var btn = LetterButtonScene.instantiate()
		btn.text = letters[i]

		letters_container.add_child(btn)

		var pos = Vector2(
			cos(angle) * radius,
			sin(angle) * radius
		)

		btn.position = center + pos - btn.size / 2

		var c = Callable(self, "_on_button_gui_input").bind(btn)
		btn.gui_input.connect(c)

func _on_button_gui_input(event: InputEvent, button: Button) -> void:
	if game_finished:
		return

	# فقط شروع Swipe
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selecting = true
		_clear_all_selections()
		_add_to_selected(button)

	elif event is InputEventScreenTouch and event.pressed:
		selecting = true
		_clear_all_selections()
		_add_to_selected(button)

func _input(event):
	if game_finished:
		return

	if not selecting:
		return

	if event is InputEventMouseMotion:
		_process_swipe_position(event.position)

	elif event is InputEventScreenDrag:
		_process_swipe_position(event.position)

	elif event is InputEventMouseButton:
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			selecting = false
			_finish_swipe()

	elif event is InputEventScreenTouch:
		if not event.pressed:
			selecting = false
			_finish_swipe()

func _process_swipe_position(pos: Vector2) -> void:
	for button in letters_container.get_children():
		if button is Button and button.visible and not button.disabled:
			var rect = button.get_global_rect()
			if rect.has_point(pos):
				if button not in selected_buttons:
					_add_to_selected(button)
				return

func _add_to_selected(button: Button) -> void:
	selected_buttons.append(button)
	button.add_theme_color_override("font_color", Color(0.678, 1.0, 0.0, 1.0))
	_update_current_word_from_selection()

func _update_current_word_from_selection() -> void:
	current_word = ""
	for btn in selected_buttons:
		current_word += btn.text
	current_word_label.text = current_word

func _clear_all_selections() -> void:
	for btn in selected_buttons:
		if is_instance_valid(btn):
			btn.remove_theme_color_override("font_color")
	selected_buttons.clear()
	current_word = ""
	current_word_label.text = ""

func _finish_swipe() -> void:
	_update_current_word_from_selection()


func clear_current_word():
	_clear_all_selections()

func submit_current_word():
	if current_turn != "player": return
	
	# بلافاصله تایمر را متوقف کن تا در حین پردازش زمان هدر نرود
	get_parent().stop_timer()
	
	if current_word in valid_words and current_word not in found_words:
		found_words.append(current_word)
		word_owners[current_word] = "player"
		score += word_weights.get(current_word, current_word.length())
		add_found_word(current_word, "player")
		feedback_label.text = "✅ درست"
		update_score()
		update_found_count()
		
		await get_tree().create_timer(1.0).timeout 
		_start_bot_turn() # نوبت ربات
	else:
		feedback_label.text = "❌ غلط"
		clear_current_word()
		# اگر غلط بود، بازیکن هنوز می‌تواند در وقت باقی‌مانده‌اش تلاش کند
		get_parent().turn_active = true 

func _start_bot_turn():
	if game_finished or current_turn == "bot": return
	
	current_turn = "bot"
	set_buttons_enabled(false)
	get_parent().stop_timer() # مطمئن شویم تایمر بازیکن کاملاً متوقف است
	
	await perform_bot_move()
	
	# پس از پایان کاملِ حرکت ربات، نوبت به بازیکن داده می‌شود
	if not game_finished:
		_start_player_turn()
func perform_bot_move():
	bot_status_label.text = "ربات در حال فکر کردن..."
	var bot_found = false
	
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
			found_words.append(chosen)
			word_owners[chosen] = "bot"
			bot_score += word_weights.get(chosen, 1)
			
			add_found_word(chosen, "bot")
			update_score()
			update_bot_score()
			update_found_count()
			feedback_label.text = "ربات کلمه '" + chosen + "' را پیدا کرد."
			
			await get_tree().create_timer(1.5).timeout
			bot_found = true 
		else:
			feedback_label.text = "ربات به بن‌بست رسید، دوباره بررسی می‌کند..."
			await get_tree().create_timer(1.2).timeout
	
	bot_status_label.text = ""
	# نکته مهم: اینجا دیگر هیچ تابعی را برای تغییر نوبت صدا نزنید.
	# مدیریت نوبت به صورت زنجیره‌ای در تابعِ فرستنده (_start_bot_turn) انجام می‌شود.

func add_found_word(word, owner):
	var label = Label.new()

	if owner == "player":
		label.text = "🟢 " + word
	else:
		label.text = "🔴 " + word

	found_words_container.add_child(label)

func _clear_found_words_ui():
	for child in found_words_container.get_children():
		child.queue_free()

func update_score():
	score_label.text = "امتیاز: " + str(score)

func update_bot_score():
	bot_score_label.text = "Bot: " + str(bot_score)

func update_found_count():
	found_count_label.text = str(found_words.size()) + " / " + str(valid_words.size())

func set_buttons_enabled(enabled):
	for button in letters_container.get_children():
		if button is Button:
			button.disabled = !enabled

#func check_game_complete():
	#if game_finished:
		#return
#
	#if found_words.size() >= valid_words.size():
		#game_finished = true
		#set_buttons_enabled(false)
	

func turn_over():
	if current_turn == "player":
		print("Player time limit reached. Switching to bot...")
		_start_bot_turn()
		
func _reset_puzzle():
	var new_puzzle = SocketManager.get_offline_test_puzzle()
	var try_count=0
	while new_puzzle.id in prev_puzzles:
		try_count += 1
		new_puzzle = SocketManager.get_offline_test_puzzle()
		if try_count > 10:
			break
	prev_puzzles.append(new_puzzle.id)
	letters = new_puzzle["letters"]
	valid_words = []
	word_weights.clear()

	# استخراج کلمات و وزن‌ها از ساختار جدید
	for w in new_puzzle["words"]:
		var word_str = w["word"]
		var weight_val = w.get("weight", 1) # اگر وزن نداشت پیش‌فرض ۱
		
		valid_words.append(word_str)
		word_weights[word_str] = weight_val
	_generate_letter_buttons()
	
	


func _on_submit_button_pressed() -> void:
	if current_word != "":
		submit_current_word()
	else:
		pass
	



func _on_clear_button_pressed() -> void:
	_clear_all_selections()


func _on_reset_puzzle_pressed() -> void:
	_reset_puzzle()
