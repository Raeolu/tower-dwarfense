extends Control

var paused = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause_menu()

func toggle_pause_menu():
	if paused:
		hide()
		get_tree().paused = false
	else:
		show()
		get_tree().paused = true
	paused = !paused


func _on_resume_pressed() -> void:
	toggle_pause_menu()


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
