extends Control
var max_time = 20
var time_left = 20
var letters = []
var valid_words = []
var found_words = []
var word_owners = {}
var player1_hp := 40
var player2_hp := 40
var max_hp := 40
var current_word = ""
var score = 0
var bot_score = 0
@onready var total_timer_label: Label = $TotalTimerLabel

var selected_buttons: Array = []
var selecting := false
var game_finished := false
var current_turn := ""
var prev_puzzles = []
var drag_curve: Curve2D = Curve2D.new()
var last_drag_pos: Vector2 = Vector2.ZERO
var pending_puzzles = [] 
# =========================
# Letter Textures
# =========================
@onready var background_rect : Sprite2D = $NoirTheme
const bg_player1  = preload("uid://dlaotwr7k5qkb")
const bg_player2  = preload("uid://7l3tedfxqwo6")

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
var current_puzzle_index = 0
@onready var letter_buttons = [
	$Puzzle/LettersContainer/Letter1,
	$Puzzle/LettersContainer/Letter2,
	$Puzzle/LettersContainer/Letter3,
	$Puzzle/LettersContainer/Letter4,
	$Puzzle/LettersContainer/Letter5
]
@onready var letters_container = $Puzzle/LettersContainer
@onready var end_popup = $"EndGamePopup"
@onready var result_label = $"EndGamePopup/VBoxContainer/ResultLabel"

@onready var player1_hp_label : Label = $Player1HP
@onready var player2_hp_label : Label = $Player2HP

@onready var score_label = $"ScoreLabel"
@onready var feedback_label = $"FeedbackLabel"
@onready var found_count_label = $"FoundCountLabel"
@onready var found_words_container = $"FoundWords"
@onready var current_word_label = $"CurrentWordLabel"
@onready var bot_score_label = $"BotScoreLabel"
@onready var bot_status_label = $"BotStatusLabel"
@onready var drag_line: Line2D = $Puzzle/DragLine
var total_seconds: float = 0.0

func _ready():
	drag_curve.set_bake_interval(1.0)
	drag_curve.set_bake_interval(0.5)
	SocketManager.puzzle_received.connect(start_puzzle)
	$Player1HPBar.max_value = max_hp
	$Player2HPBar.max_value = max_hp

	$Player1HP.text = str(player1_hp)
	$Player2HP.text = str(player2_hp)
	if SocketManager.use_offline_puzzle:

		await get_tree().process_frame
		pending_puzzles.clear()
		for i in range(3):
			var p = SocketManager.get_offline_test_puzzle()
			pending_puzzles.append(p)
		if !pending_puzzles.is_empty():
			for i in range(3):
				prev_puzzles.append(pending_puzzles[i-1].id)
			_update_puzzle_number(0)
			start_puzzle(pending_puzzles[current_puzzle_index])
			start_game()

	# connect buttons

	for button in letter_buttons:

		var c = Callable(self, "_on_button_gui_input").bind(button)
		button.gui_input.connect(c)
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
func start_puzzle(data: Dictionary):
	letters = data["letters"]
	set_buttons_enabled(true)
	_generate_letter_buttons()


func start_game():
	valid_words = []
	found_words.clear()
	word_owners.clear()
	score = 0
	bot_score = 0
	current_word = ""
	selecting = false
	game_finished = false
	_clear_all_selections()
	update_hp_ui()
	player1_hp = max_hp
	player2_hp = max_hp
	current_word_label.text = ""
	for i in range(3):
		var data = pending_puzzles[i-1]
		for w in data["words"]:
			var word_str = w["word"]
			if word_str not in valid_words:
				valid_words.append(word_str)

	_clear_found_words_ui()
	_start_player_turn()
func _update_puzzle_number(index):
	$puzzleNumber.text = str(index+1)
func load_next_puzzle():
	current_puzzle_index += 1
	if(current_puzzle_index) > 2:
		current_puzzle_index =0
	_update_puzzle_number(current_puzzle_index)
	start_puzzle(pending_puzzles[current_puzzle_index])


func load_prev_puzzle():
	current_puzzle_index -= 1
	if(current_puzzle_index) < 0:
		current_puzzle_index = 2
	_update_puzzle_number(current_puzzle_index)
	start_puzzle(pending_puzzles[current_puzzle_index])

func update_turn_background():
	if current_turn == "player":
		background_rect.texture = bg_player1
	else:
		background_rect.texture = bg_player2

func apply_word_effect(word: String, owner: String):
	var l = word.length()

	# HEAL
	if l == 4:
		if owner == "player":
			player1_hp = min(max_hp, player1_hp + 7)

			var bar = $Player1HPBar
			bar.modulate = Color(0.4, 1, 0.4)
			create_tween().tween_property(bar, "modulate", Color(1,1,1), 0.4)

		else:
			player2_hp = min(max_hp, player2_hp + 7)

			var bar = $Player2HPBar
			bar.modulate = Color(0.4, 1, 0.4)
			create_tween().tween_property(bar, "modulate", Color(1,1,1), 0.4)

	# DAMAGE
	else:
		if owner == "player":
			player2_hp -= 2 * l

			var bar = $Player2HPBar
			bar.modulate = Color(1, 0.3, 0.3)
			create_tween().tween_property(bar, "modulate", Color(1,1,1), 0.4)

		else:
			player1_hp -= 2 * l

			var bar = $Player1HPBar
			bar.modulate = Color(1, 0.3, 0.3)
			create_tween().tween_property(bar, "modulate", Color(1,1,1), 0.4)

	update_hp_ui()
	check_game_over()
func check_game_over():

	if player1_hp <= 0:
		game_finished = true
		get_parent().get_parent().game_finished = true
		get_parent().get_parent().turn_active = false

		set_buttons_enabled(false)

		result_label.text = "💀 شما باختید!"
		end_popup.popup_centered()

	elif player2_hp <= 0:
		game_finished = true
		get_parent().get_parent().game_finished = true
		get_parent().get_parent().turn_active = false

		set_buttons_enabled(false)

		result_label.text = "🏆 شما برنده شدید!"
		end_popup.popup_centered()


func update_hp_ui():
	player1_hp_label.text = str(player1_hp)
	player2_hp_label.text = str(player2_hp)

	create_tween().tween_property($Player1HPBar, "value", player1_hp, 0.3)
	create_tween().tween_property($Player2HPBar, "value", player2_hp, 0.3)


func _start_player_turn():
	if game_finished: return
	update_turn_ui()
	current_turn = "player"
	set_buttons_enabled(true)
	update_turn_background()
	# فعال کردن و ریست تایمر در اسکریپت اصلی
	reset_timer()
func _start_player2_turn():
	if game_finished: return
	update_turn_ui()
	current_turn = "player2"
	set_buttons_enabled(true)
	update_turn_background()
	reset_timer()
# =========================
# GENERATE BUTTONS
# =========================
func reset_timer():
	print("Timer Reset")
	time_left = max_time
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
		
		feedback_label.text = "✅ درست"
		if current_turn == "player":
			apply_word_effect(current_word, "player")
			add_found_word(current_word,'player')
		else:
			apply_word_effect(current_word, "player2")
			add_found_word(current_word,'player2')
		turn_over()
	else:

		feedback_label.text = "❌ غلط"

	_clear_all_selections()

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
		_start_player2_turn()
	elif current_turn == "player2":
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

func update_turn_ui():
	print("Current turn:", current_turn)

	var player1_bar = $Player1HPBar
	var player2_bar = $Player2HPBar

	if current_turn == "player":
		player1_bar.modulate = Color(0.5, 0.5, 0.5)
		player2_bar.modulate = Color.WHITE
	else:
		player1_bar.modulate = Color.WHITE
		player2_bar.modulate = Color(0.5, 0.5, 0.5)
func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()


func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_next_puzzle_pressed() -> void:
	load_next_puzzle()


func _on_prev_puzzle_pressed() -> void:
	load_prev_puzzle()
