extends Control

var pending_puzzles = [] 
var prev_puzzles = []
var letters = []
var input_enabled := true
var drag_curve: Curve2D = Curve2D.new()
var last_drag_pos: Vector2 = Vector2.ZERO
var selecting := false
var selected_buttons: Array = []
var current_index = 0
var Scissors_borad_buff = 0
var Rock_borad_buff = 0
var Paper_borad_buff = 0
@onready var drag_line: Line2D = $Puzzle/DragLine

@onready var letter_buttons = [
	$Puzzle/LettersContainer/Letter1,
	$Puzzle/LettersContainer/Letter2,
	$Puzzle/LettersContainer/Letter3,
	$Puzzle/LettersContainer/Letter4,
	$Puzzle/LettersContainer/Letter5
]
const WHEEL_PAPER = preload("uid://calqm48l833xu")
const WHEEL_ROCK = preload("uid://pr5flvi2k8pf")
const WHEEL_SCISSOR = preload("uid://di46837uo85hy")
@onready var wheel: Sprite2D = $Puzzle/LettersContainer/Wheel

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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SocketManager.puzzle_received.connect(start_puzzle)

	if SocketManager.use_offline_puzzle:

			await get_tree().process_frame
			pending_puzzles.clear()
			for i in range(3):
				var p = SocketManager.get_offline_test_puzzle()
				pending_puzzles.append(p)
			if !pending_puzzles.is_empty():
				for i in range(3):
					prev_puzzles.append(pending_puzzles[i-1].id)
	for button in letter_buttons:
		var c = Callable(self, "_on_button_gui_input").bind(button)
		button.gui_input.connect(c)
	start_puzzle(pending_puzzles[current_index])
	change_texture(current_index)
	
	
func start_puzzle(data: Dictionary):
	letters = data["letters"]
	_generate_letter_buttons()
	for i in range(3):
		var puzzles = pending_puzzles[i-1]
		for w in puzzles["words"]:
			var word_str = w["word"]
			if word_str not in get_parent().valid_words:
				get_parent().valid_words.append(word_str)
	
func load_next_puzzle():
	current_index += 1
	if current_index > 2:
		current_index = 0
	start_puzzle(pending_puzzles[current_index])
	change_texture(current_index)
	
func load_prev_puzzle():
	current_index -= 1
	if current_index < 0:
		current_index = 2
	start_puzzle(pending_puzzles[current_index])
	change_texture(current_index)
	
func change_texture(index):
	if index == 0:
		wheel.texture = WHEEL_ROCK
		get_parent().current_board = "Rock"
		Show_board_buff(Rock_borad_buff)
	elif index == 1:
		wheel.texture = WHEEL_PAPER
		get_parent().current_board = "Paper"
		Show_board_buff(Paper_borad_buff)
	elif index == 2:
		wheel.texture = WHEEL_SCISSOR
		get_parent().current_board = "Scissors"
		Show_board_buff(Scissors_borad_buff)
		
# =========================
# GENERATE BUTTONS
# =========================
func board_buff(board):
	if board == "Rock":
		Scissors_borad_buff += 1
		Paper_borad_buff += 1
		Rock_borad_buff = 0
		Show_board_buff(Rock_borad_buff)
	elif board == "Paper":
		Scissors_borad_buff += 1
		Rock_borad_buff += 1
		Paper_borad_buff = 0
		Show_board_buff(Paper_borad_buff)
	elif board == "Scissors":
		Paper_borad_buff += 1
		Rock_borad_buff += 1
		Scissors_borad_buff = 0
		Show_board_buff(Scissors_borad_buff)
func Show_board_buff(buff):
	$Puzzle/BoradBuff.text = str(buff)


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

	if get_parent().game_finished or not input_enabled:
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

	if get_parent().game_finished:
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


func _clear_all_selections():

	for btn in selected_buttons:

		if is_instance_valid(btn):

			btn.modulate = Color.WHITE

	selected_buttons.clear()

	get_parent().current_word = ""

	get_parent().current_word_label.text = ""

func _finish_swipe():
	drag_curve.clear_points()
	drag_line.clear_points()
	last_drag_pos = Vector2.ZERO
	_update_current_word_from_selection()

func _update_current_word_from_selection():

	get_parent().current_word = ""

	for btn in selected_buttons:

		get_parent().current_word += btn.get_meta("letter")

	get_parent().current_word_label.text = get_parent().current_word


func shuffle_letters():
	letters.shuffle()

	for btn in letter_buttons:
		btn.modulate.a = 0.3

	await get_tree().create_timer(0.1).timeout

	_generate_letter_buttons()

	for btn in letter_buttons:
		btn.modulate.a = 1.0
