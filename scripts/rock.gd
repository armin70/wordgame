extends Node2D


func play_break_animation():
	$Multiplier.text = "2x"
	await get_tree().create_timer(1).timeout
	$animation.play("break")
	await $animation.animation_finished
	$Multiplier.text = ""
	queue_free()


func get_debuff(debuff):
	print("debuff value: ", debuff)
	$debuff.text = debuff
	await get_tree().create_timer(2).timeout
	$debuff.text = ""
