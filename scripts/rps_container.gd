extends Control

const PAPER = preload("uid://cocrlxvcogpqs")
const ROCK = preload("uid://dx1kcjudo0gxe")
const SCISSORS = preload("uid://c43c7km5wekoc")

var current_deck = []
var rps = ['Rock','Paper','Scissors']
func _ready() -> void:
	generate_RPS()


func generate_RPS():
	var choice
	for i in range(0,4):
		choice = rps.pick_random()
		while current_deck.count(choice) > 1 :
			choice = rps.pick_random()
		current_deck.append(choice)
		var selected_scene 
		if choice == 'Rock':
			selected_scene =  ROCK.instantiate()
			selected_scene.add_to_group(choice)
		elif choice == 'Paper':
			selected_scene = PAPER.instantiate()
			selected_scene.add_to_group(choice)
		elif choice == 'Scissors':
			selected_scene = SCISSORS.instantiate()
			selected_scene.add_to_group(choice)
		$RPSBox.add_child(selected_scene)

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
	for node in targets:
		node.queue_free()
	fill_free_space(type_name)
	get_parent().multiplier = buff

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
	get_parent().debuff = debuff

func fill_free_space(target):
	var choice
	if current_deck.size() < 4:
		var free_space = 4 - current_deck.size()
		for i in range(0,free_space):
			choice = rps.pick_random()
			while current_deck.count(choice) > 1 :
				choice = rps.pick_random()
			current_deck.append(choice)
			var selected_scene 
			if choice == 'Rock':
				selected_scene =  ROCK.instantiate()
				selected_scene.add_to_group(choice)
			elif choice == 'Paper':
				selected_scene = PAPER.instantiate()
				selected_scene.add_to_group(choice)
			elif choice == 'Scissors':
				selected_scene = SCISSORS.instantiate()
				selected_scene.add_to_group(choice)
			$RPSBox.add_child(selected_scene)
	
