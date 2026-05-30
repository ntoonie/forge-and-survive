extends CanvasLayer

@onready var overlay = $NightOverlay

func _ready():
	var game_loop = get_tree().get_first_node_in_group("game_loop")
	if game_loop:
		game_loop.phase_changed.connect(_on_phase_changed)

func _on_phase_changed(new_phase):
	if new_phase == 1:  # DEFENSE/night
		overlay.visible = true
		print("Night overlay ON")
	else:               # BUILD/day
		overlay.visible = false
		print("Night overlay OFF")
