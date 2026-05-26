extends Node

var puzzles = []
var current_index = 0

func set_puzzle(puzzle_data):
	puzzles = [puzzle_data]
	current_index = 0

func get_current_puzzle():
	if puzzles.is_empty():
		return null
	return puzzles[current_index]

#func request_puzzle():
	#SocketManager.request_puzzle(current_index)

func next_puzzle():
	current_index += 1
	SocketManager.request_puzzle(current_index)


func load_puzzle(puzzle_data: Dictionary):
	print('puzzle loaded:',typeof(puzzle_data))
	#$Puzzle.start_puzzle(puzzle_data)
