extends Control

var letters = []
var valid_words = []
var found_words = []
var word_owners = {}
var player_hp := 40
var bot_hp := 40
var max_hp := 40
var current_word = ""
var score = 0
var bot_score = 0

var selected_buttons: Array = []
var selecting := false
var game_finished := false
var current_turn := ""
var prev_puzzles = []
var drag_curve: Curve2D = Curve2D.new()
var last_drag_pos: Vector2 = Vector2.ZERO
# =========================
# Letter Textures
# =========================

var letter_textures = {
	"ا": preload("res://assets/alphabet/الف.png"),
	"ب": preload("res://assets/alphabet/ب.png"),
	"پ": preload("res://assets/alphabet/پ.png"),
	"ت": preload("res://assets/alphabet/ت.png"),
	"ث": preload("res://assets/alphabet/ث.png"),
	"ج": preload("res://assets/alphabet/ج.png"),
	"چ": preload("res://assets/alphabet/چ.png"),
	"ح": preload("res://assets/alphabet/ح.png"),
	"خ": preload("res://assets/alphabet/خ.png"),
	"د": preload("res://assets/alphabet/د.png"),
	"ذ": preload("res://assets/alphabet/ذ.png"),
	"ر": preload("res://assets/alphabet/ر.png"),
	"ز": preload("res://assets/alphabet/ز.png"),
	"ژ": preload("res://assets/alphabet/ژ.png"),
	"س": preload("res://assets/alphabet/س.png"),
	"ش": preload("res://assets/alphabet/ش.png"),
	"ص": preload("res://assets/alphabet/ص.png"),
	"ض": preload("res://assets/alphabet/ض.png"),
	"ط": preload("res://assets/alphabet/ط.png"),
	"ظ": preload("res://assets/alphabet/ظ.png"),
	"ع": preload("res://assets/alphabet/ع.png"),
	"غ": preload("res://assets/alphabet/غ.png"),
	"ف": preload("res://assets/alphabet/ف.png"),
	"ق": preload("res://assets/alphabet/ق.png"),
	"ک": preload("res://assets/alphabet/ک.png"),
	"گ": preload("res://assets/alphabet/گ.png"),
	"ل": preload("res://assets/alphabet/ل.png"),
	"م": preload("res://assets/alphabet/م.png"),
	"ن": preload("res://assets/alphabet/ن.png"),
	"و": preload("res://assets/alphabet/و.png"),
	"ه": preload("res://assets/alphabet/ه.png"),
	"ی": preload("res://assets/alphabet/ی.png")
}

# =========================
# UI
# =========================
var input_enabled := true
@onready var letters_container = $LettersContainer

@onready var letter_buttons = [
	$LettersContainer/Letter1,
	$LettersContainer/Letter2,
	$LettersContainer/Letter3,
	$LettersContainer/Letter4,
	$LettersContainer/Letter5
]

@onready var end_popup = $"../EndGamePopup"
@onready var result_label = $"../EndGamePopup/VBoxContainer/ResultLabel"

@onready var player_hp_label : Label = $"../UIRoot/PlayerHP"
@onready var bot_hp_label : Label = $"../UIRoot/BotHP"

@onready var score_label = $"../UIRoot/ScoreLabel"
@onready var feedback_label = $"../UIRoot/FeedbackLabel"
@onready var found_count_label = $"../UIRoot/FoundCountLabel"
@onready var found_words_container = $"../UIRoot/FoundWords"
@onready var current_word_label = $"../UIRoot/CurrentWordLabel"
@onready var bot_score_label = $"../UIRoot/BotScoreLabel"
@onready var bot_status_label = $"../UIRoot/BotStatusLabel"
@onready var drag_line: Line2D = $DragLine
func _ready():
	drag_curve.set_bake_interval(1.0)
	drag_curve.set_bake_interval(0.5)
	SocketManager.puzzle_received.connect(start_puzzle)
	$"../UIRoot/PlayerHPBar".max_value = max_hp
	$"../UIRoot/BotHpBar".max_value = max_hp

	$"../UIRoot/PlayerHP".text = str(player_hp)
	$"../UIRoot/BotHP".text = str(bot_hp)
	if SocketManager.use_offline_puzzle:

		await get_tree().process_frame

		var offline_data = SocketManager.get_offline_test_puzzle()

		if !offline_data.is_empty():
			prev_puzzles.append(offline_data.id)
			start_puzzle(offline_data)

	# connect buttons

	for button in letter_buttons:

		var c = Callable(self, "_on_button_gui_input").bind(button)
		button.gui_input.connect(c)

# =========================
# START PUZZLE
# =========================
func start_puzzle(data: Dictionary):
	letters = data["letters"]
	valid_words = []
	player_hp = max_hp
	bot_hp = max_hp
	update_hp_ui()
	# استخراج کلمات و وزن‌ها از ساختار جدید
	for w in data["words"]:
		var word_str = w["word"]
		var weight_val = w.get("weight", 1) # اگر وزن نداشت پیش‌فرض ۱
		
		valid_words.append(word_str)

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
	#found_count_label.text = "0 / " + str(valid_words.size())
	current_word_label.text = ""
	bot_score_label.text = "Bot: 0"
	bot_status_label.text = ""

	_clear_found_words_ui()
	set_buttons_enabled(true)
	
	#start_bot() 

	_generate_letter_buttons()
	_start_player_turn()
	
func apply_word_effect(word: String, owner: String):
	var l = word.length()

	# HEAL
	if l == 4:
		if owner == "player":
			player_hp = min(max_hp, player_hp + 7)

			var bar = $"../UIRoot/PlayerHPBar"
			bar.modulate = Color(0.4, 1, 0.4)
			create_tween().tween_property(bar, "modulate", Color(1,1,1), 0.4)

		else:
			bot_hp = min(max_hp, bot_hp + 4)

			var bar = $"../UIRoot/BotHpBar"
			bar.modulate = Color(0.4, 1, 0.4)
			create_tween().tween_property(bar, "modulate", Color(1,1,1), 0.4)

	# DAMAGE
	else:
		if owner == "player":
			bot_hp -= 2 * l

			var bar = $"../UIRoot/BotHpBar"
			bar.modulate = Color(1, 0.3, 0.3)
			create_tween().tween_property(bar, "modulate", Color(1,1,1), 0.4)

		else:
			player_hp -= 2 * l

			var bar = $"../UIRoot/PlayerHPBar"
			bar.modulate = Color(1, 0.3, 0.3)
			create_tween().tween_property(bar, "modulate", Color(1,1,1), 0.4)

	update_hp_ui()
	check_game_over()
func check_game_over():

	if player_hp <= 0:
		game_finished = true
		get_parent().game_finished = true
		get_parent().turn_active = false

		set_buttons_enabled(false)

		result_label.text = "💀 شما باختید!"
		end_popup.popup_centered()

	elif bot_hp <= 0:
		game_finished = true
		get_parent().game_finished = true
		get_parent().turn_active = false

		set_buttons_enabled(false)

		result_label.text = "🏆 شما برنده شدید!"
		end_popup.popup_centered()


func update_hp_ui():
	player_hp_label.text = str(player_hp)
	bot_hp_label.text = str(bot_hp)

	create_tween().tween_property($"../UIRoot/PlayerHPBar", "value", player_hp, 0.3)
	create_tween().tween_property($"../UIRoot/BotHpBar", "value", bot_hp, 0.3)
func _start_player_turn():
	if game_finished: return
	
	current_turn = "player"
	set_buttons_enabled(true)
	bot_status_label.text = "نوبت شماست"
	
	# فعال کردن و ریست تایمر در اسکریپت اصلی
	get_parent().reset_timer()
# =========================
# GENERATE BUTTONS
# =========================

func _generate_letter_buttons():

	letters.shuffle()

	for i in range(letter_buttons.size()):

		var btn = letter_buttons[i]

		if i < letters.size():

			btn.visible = true

			btn.texture_normal = letter_textures[letters[i]]

			btn.set_meta("letter", letters[i])

		else:

			btn.visible = false

# =========================
# INPUT
# =========================

func _on_button_gui_input(event: InputEvent, button) -> void:

	if game_finished or not input_enabled:
		return

	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:
		drag_curve.clear_points()
		last_drag_pos = Vector2.ZERO
		selecting = true
		drag_line.clear_points()
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

		if not event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT:

			selecting = false

			_finish_swipe()

	elif event is InputEventScreenTouch:

		if not event.pressed:

			selecting = false

			_finish_swipe()

func _process_swipe_position(pos: Vector2) -> void:
	if not input_enabled:
		return
	if last_drag_pos == Vector2.ZERO:
		last_drag_pos = pos

	var dist = last_drag_pos.distance_to(pos)

	if dist > 4:
		var steps = int(dist / 4)

		for i in range(steps):
			var t = float(i) / float(max(steps, 1))
			_add_drag_point(last_drag_pos.lerp(pos, t))

		last_drag_pos = pos

	_add_drag_point(pos)
	# همیشه خط آپدیت شود
	_update_drag_preview(pos)

	for button in letter_buttons:
		if button.visible and not button.disabled:
			var rect = button.get_global_rect()

			if rect.has_point(pos):
				if button not in selected_buttons:
					_add_to_selected(button)
				return
func _update_drag_preview(pos: Vector2):

	if selected_buttons.size() == 0:
		return

	drag_line.clear_points()

	for btn in selected_buttons:

		var center = btn.global_position + (btn.size / 2)
		center = drag_line.to_local(center)

		drag_line.add_point(center)

	# نقطه آخر = موس / انگشت
	drag_line.add_point(drag_line.to_local(pos))
# =========================
# SELECT
# =========================

func _add_to_selected(button):

	selected_buttons.append(button)

	button.modulate = Color(0.7, 1, 0.7)

	_update_current_word_from_selection()
	#_update_drag_line()

func _add_drag_point(pos: Vector2):
	var local = pos - drag_line.global_position
	drag_curve.add_point(local)

	var i = drag_curve.get_point_count() - 1

	if i > 0:
		var prev = drag_curve.get_point_position(i - 1)
		var dir = (local - prev) * 0.5

		drag_curve.set_point_in(i, -dir)
		drag_curve.set_point_out(i, dir)
	if drag_curve.get_point_count() > 0:
		var last = drag_curve.get_point_position(drag_curve.get_point_count() - 1)
		if last.distance_to(local) < 2:
			return

	drag_curve.add_point(local)
	_redraw_line()

func _redraw_line():
	drag_line.clear_points()

	var baked = drag_curve.get_baked_points()

	for p in baked:
		drag_line.add_point(p)
#func _update_drag_line():
#
	#drag_line.clear_points()
#
	#for btn in selected_buttons:
#
		#var center = btn.global_position + (btn.size / 2)
#
		## تبدیل global به local برای Line2D
		#center = drag_line.to_local(center)
#
		#drag_line.add_point(center)
		#
func _update_current_word_from_selection():

	current_word = ""

	for btn in selected_buttons:

		current_word += btn.get_meta("letter")

	current_word_label.text = current_word

func _clear_all_selections():

	for btn in selected_buttons:

		if is_instance_valid(btn):

			btn.modulate = Color.WHITE

	selected_buttons.clear()

	current_word = ""

	current_word_label.text = ""

func _finish_swipe():
	drag_curve.clear_points()
	drag_line.clear_points()
	last_drag_pos = Vector2.ZERO
	_update_current_word_from_selection()

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
		turn_over()
	else:

		feedback_label.text = "❌ غلط"

	_clear_all_selections()
func _start_bot_turn():
	if game_finished or current_turn == "bot":
		return

	current_turn = "bot"
	set_buttons_enabled(false)

	get_parent().reset_timer()

	await perform_bot_move()

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
			get_parent().stop_timer()
			found_words.append(chosen)
			word_owners[chosen] = "bot"
			
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
	# نکته مهم: اینجا دیگر هیچ تابعی را برای تغییر نوبت صدا نزنید.
	# مدیریت نوبت به صورت زنجیره‌ای در تابعِ فرستنده (_start_bot_turn) انجام می‌شود.

func add_found_word(word, owner):
	var label = Label.new()
	var settings = LabelSettings.new()

	if owner == "player":
		label.text = "🟢 " + word
		settings.font_color = Color("#000000")
	else:
		label.text = "🔴 " + word
		settings.font_color = Color("#000000")

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

func set_buttons_enabled(enabled):
	input_enabled = enabled

	for button in letters_container.get_children():
		if button is Button:
			button.modulate = Color(1,1,1,1) if enabled else Color(0.5,0.5,0.5,1)

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

	# استخراج کلمات و وزن‌ها از ساختار جدید
	for w in new_puzzle["words"]:
		var word_str = w["word"]
		var weight_val = w.get("weight", 1) # اگر وزن نداشت پیش‌فرض ۱
		
		valid_words.append(word_str)
	_generate_letter_buttons()



# =========================
# BUTTONS
# =========================


func _on_submit_button_pressed() -> void:
	if current_word != "":
		submit_current_word()
	else:
		pass


func _on_clear_button_pressed() -> void:
	_clear_all_selections()


func _on_reset_puzzle_pressed() -> void:
	_reset_puzzle()


func _on_shuffle_pressed() -> void:
	letters.shuffle()

	for btn in letter_buttons:
		btn.modulate.a = 0.3

	await get_tree().create_timer(0.1).timeout

	_generate_letter_buttons()

	for btn in letter_buttons:
		btn.modulate.a = 1.0
		
func flash_hp(label: Label, color: Color) -> void:
	var original = label.modulate
	label.modulate = color
	
	await get_tree().create_timer(1).timeout
	
	label.modulate = original


func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()


func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
