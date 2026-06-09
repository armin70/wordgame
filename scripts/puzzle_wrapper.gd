extends Control

func set_letter_buttons_disabled(is_disabled: bool):
	var letters_container = $LettersContainer 
	
	var disabled_texture = load("res://assets/buttons/letter_disabled.png") 
	var normal_texture = load("res://assets/buttons/letter_normal.png") # تصویر حالت عادی
	
	for child in letters_container.get_children():
		if child is TextureButton and is_instance_valid(child):
			child.disabled = is_disabled
			
			if is_disabled:
				if disabled_texture: # چک می‌کنیم که آیا تصویر با موفقیت بارگذاری شده است
					child.texture_normal = disabled_texture 
			else:
				# اگر فعال شد، تصویر عادی را برگردان
				if normal_texture:
					child.texture_normal = normal_texture
