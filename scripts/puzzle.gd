extends CanvasLayer

var letters = []
var valid_words = []
var found_words = []
var word_owners = {}

var current_word = ""
var score = 0
var bot_score = 0

var selected_buttons: Array = []
var selecting := false
var game_finished := false
var current_turn := ""

var prev_puzzles = []

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

@onready var letters_container = $LettersContainer

@onready var letter_buttons = [
	$LettersContainer/Letter1,
	$LettersContainer/Letter2,
	$LettersContainer/Letter3,
	$LettersContainer/Letter4,
	$LettersContainer/Letter5
]
@onready var score_label: Label = $"../UIRoot/ScoreLabel"

@onready var feedback_label = $"../UIRoot/FeedbackLabel"
@onready var found_count_label = $"../UIRoot/FoundCountLabel"
@onready var current_word_label = $"../UIRoot/CurrentWordLabel"

func _ready():

	SocketManager.puzzle_received.connect(start_puzzle)

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

	valid_words.clear()

	for w in data["words"]:
		valid_words.append(w["word"])

	found_words.clear()

	score = 0
	current_word = ""

	score_label.text = "امتیاز: 0"
	feedback_label.text = ""
	found_count_label.text = "0 / " + str(valid_words.size())
	current_word_label.text = ""

	_generate_letter_buttons()

# =========================
# GENERATE BUTTONS
# =========================

func _generate_letter_buttons():

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

	if game_finished:
		return

	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:

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

		if not event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT:

			selecting = false

			_finish_swipe()

	elif event is InputEventScreenTouch:

		if not event.pressed:

			selecting = false

			_finish_swipe()

func _process_swipe_position(pos: Vector2) -> void:

	for button in letter_buttons:

		if button.visible and not button.disabled:

			var rect = button.get_global_rect()

			if rect.has_point(pos):

				if button not in selected_buttons:

					_add_to_selected(button)

				return

# =========================
# SELECT
# =========================

func _add_to_selected(button):

	selected_buttons.append(button)

	button.modulate = Color(0.7, 1, 0.7)

	_update_current_word_from_selection()

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

		found_count_label.text = str(found_words.size()) \
		+ " / " + str(valid_words.size())

		feedback_label.text = "✅ درست"

	else:

		feedback_label.text = "❌ غلط"

	_clear_all_selections()

# =========================
# BUTTONS
# =========================

func _on_submit_button_pressed() -> void:

	if current_word != "":
		submit_current_word()

func _on_clear_button_pressed() -> void:

	_clear_all_selections()

func _on_reset_puzzle_pressed() -> void:

	var new_puzzle = SocketManager.get_offline_test_puzzle()

	start_puzzle(new_puzzle)
