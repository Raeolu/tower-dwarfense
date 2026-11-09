
extends Control

@onready var button_container: Control = %ButtonContainer

@export var radius = 150
@export var animationSpeed = 0.25

var active = false
var centerPosition: Vector2
var menuTween: Tween

var selected_button: Button = null

func _ready() -> void:
	centerPosition = global_position + get_rect().size / 2 - button_container.get_rect().size / 2

	button_container.hide()

	for button in button_container.get_children():
		button.global_position = centerPosition
		button.scale = Vector2.ZERO


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("radialmenu"):
		_show_menu()

	if Input.is_action_pressed("radialmenu") and active:
		_update_selection()

	if Input.is_action_just_released("radialmenu"):
		if selected_button:
			_select_option(selected_button.name)
		else:
			_hide_menu()


func _show_menu() -> void:
	active = true
	selected_button = null
	button_container.show()

	if menuTween and menuTween.is_running():
		menuTween.kill()

	menuTween = get_tree().create_tween()
	menuTween.set_parallel(true)

	var spacing = TAU / button_container.get_child_count()

	for button in button_container.get_children():
		var angle = spacing * button.get_index() - PI
		var direction = Vector2(radius, 0).rotated(angle)
		var targetPosition = centerPosition + direction - button.get_rect().size / 2

		menuTween.tween_property(button, "global_position", targetPosition, animationSpeed)
		menuTween.tween_property(button, "scale", Vector2.ONE, animationSpeed)


func _hide_menu() -> void:
	if not active:
		return

	active = false

	if menuTween and menuTween.is_running():
		menuTween.kill()

	menuTween = get_tree().create_tween()
	menuTween.set_parallel(true)

	for button in button_container.get_children():
		menuTween.tween_property(button, "global_position", centerPosition, animationSpeed)
		menuTween.tween_property(button, "scale", Vector2.ZERO, animationSpeed)

	await menuTween.finished

	if not active:
		button_container.hide()
		
	selected_button = null


func _select_option(buttonName: String) -> void:
	_hide_menu()
	print("Button Pressed: " + buttonName)
	
func _update_selection() -> void:
	var mouse_position = get_global_mouse_position()
	var direction = mouse_position - centerPosition

	if direction.length() < 30:
		selected_button = null
		return

	var mouse_angle = direction.angle()
	var spacing = TAU / button_container.get_child_count()

	var closest_difference = INF
	selected_button = null

	for button in button_container.get_children():
		var angle = spacing * button.get_index() - PI
		var difference = abs(wrapf(mouse_angle - angle, -PI, PI))

		if difference < closest_difference:
			closest_difference = difference
			selected_button = button

	for button in button_container.get_children():
		var target_scale = Vector2.ONE

		if button == selected_button:
			target_scale = Vector2(1.2, 1.2)

		button.scale = target_scale
