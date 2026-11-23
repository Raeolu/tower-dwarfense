extends CanvasLayer
## Displays current wave progress/state and optional spawner debug info.

@export var wave_spawner: WaveSpawner
@export var debug_enabled: bool = false

@onready var wave_label: Label = $PanelContainer/VBoxContainer/HeaderRow/WaveLabel
@onready var status_label: Label = $PanelContainer/VBoxContainer/StatusLabel
@onready var progress_bar: ProgressBar = $PanelContainer/VBoxContainer/ProgressBar
@onready var summary_label: Label = $PanelContainer/VBoxContainer/SummaryLabel


func _ready() -> void:
	if wave_spawner == null:
		wave_spawner = get_tree().get_first_node_in_group("wave_spawner") as WaveSpawner

	_update_ui()


func _process(_delta: float) -> void:
	if wave_spawner == null or not is_instance_valid(wave_spawner):
		wave_spawner = get_tree().get_first_node_in_group("wave_spawner") as WaveSpawner

	_update_ui()


func _update_ui() -> void:
	if wave_spawner == null or not is_instance_valid(wave_spawner):
		wave_label.text = "Wave: --"
		status_label.text = "No WaveSpawner found"
		progress_bar.max_value = 1
		progress_bar.value = 0
		summary_label.text = ""
		return

	var info := wave_spawner.get_debug_info()
	var state: String = info["state"]
	var wave_index: int = info["wave_index"]
	var wave_count: int = info["wave_count"]
	var spawned: int = info["spawned"]
	var total: int = info["total"]
	var active_enemies: int = info["active_enemies"]
	var next_wave_in: float = info["next_wave_in"]

	if wave_count == 0:
		wave_label.text = "No Waves"
	else:
		var display_wave := maxi(wave_index + 1, 0)
		wave_label.text = "Wave %d / %d" % [display_wave, wave_count]
		if state == "Finished":
			wave_label.text += " (Done)"

	match state:
		"Spawning":
			status_label.text = "Spawning..."
		"Waiting for Clear":
			status_label.text = "Waiting for wave clear..."
		"Next Wave Delay":
			status_label.text = "Next wave in %.1fs" % next_wave_in
		"Finished":
			status_label.text = "All waves completed!"
		_:
			status_label.text = "Idle"

	progress_bar.max_value = maxi(total, 1)
	progress_bar.value = spawned if total > 0 else 0
	summary_label.text = "Spawned: %d / %d | Alive: %d" % [spawned, total, active_enemies]
