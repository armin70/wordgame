extends Node2D


func play_break_animation():
	$animation.play("break")
	await $animation.animation_finished
	queue_free()
