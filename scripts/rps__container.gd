extends Node2D
@onready var placeholders =[
	$place1,
	$place2,
	$place3,
	$place4
]
const ROCK = preload("uid://dx1kcjudo0gxe")
const PAPER = preload("uid://cocrlxvcogpqs")
const SCISSORS = preload("uid://c43c7km5wekoc")

@export var spacing := 150.0

var current_deck = []
var rps = ['Rock','Paper','Scissors']
func _ready() -> void:
	generate_RPS()
	

func add_to_placeholder(choices):
	for placeholder in placeholders:
		if placeholder.get_children().size() > 0:
			for child in placeholder.get_children():
				child.queue_free()
	var selected_scene
	var index = -1
	for choice in choices:
		index += 1
		if choice == 'Rock':
			selected_scene =  ROCK.instantiate()
		elif choice == 'Paper':
			selected_scene = PAPER.instantiate()
		elif choice == 'Scissors':
			selected_scene = SCISSORS.instantiate()
		selected_scene.add_to_group(choice)
		placeholders[index].add_child(selected_scene)
func generate_RPS():
	var choice
	for i in range(0,4):
		choice = rps.pick_random()
		while current_deck.count(choice) > 1 :
			choice = rps.pick_random()
		current_deck.append(choice)
		add_to_placeholder(current_deck)


func remove_type(type_name: String):
	var targets
	var buff
	if type_name == "Rock":
		targets = get_tree().get_nodes_in_group("Scissors")
		current_deck = current_deck.filter(func(item): return item != "Scissors")
		buff = targets.size()
	elif type_name == "Paper":
		targets = get_tree().get_nodes_in_group("Rock")
		current_deck = current_deck.filter(func(item): return item != "Rock")
		buff = targets.size()
	elif type_name == "Scissors":
		targets = get_tree().get_nodes_in_group("Paper")
		current_deck = current_deck.filter(func(item): return item != "Paper")
		buff = targets.size()
	else:
		print('cant catch')
	get_parent().multiplier = buff
	print("buff: ",buff)
	await wait_to_finish_animation(targets)
		
	await get_tree().create_timer(2).timeout
	fill_free_space()

func wait_to_finish_animation(targets):
	for node in targets:
		node.play_break_animation()

func get_debuff(type_name):
	var targets
	var debuff
	if type_name == "Rock":
		targets = get_tree().get_nodes_in_group("Paper")
		debuff = targets.size()
	elif type_name == "Paper":
		targets = get_tree().get_nodes_in_group("Scissors")
		debuff = targets.size()
	elif type_name == "Scissors":
		targets = get_tree().get_nodes_in_group("Rock")
		debuff = targets.size()
	print("targets:",targets)
	for node in targets:
		node.get_debuff("-1")
	get_parent().debuff = debuff

func fill_free_space():
	print("filled")
	var choice
	
	if current_deck.size() < 4:
		var free_space = 4 - current_deck.size()
		for i in range(0,free_space):
			choice = rps.pick_random()
			while current_deck.count(choice) > 1 :
				choice = rps.pick_random()
			current_deck.append(choice)
			var selected_scene 
			add_to_placeholder(current_deck)
