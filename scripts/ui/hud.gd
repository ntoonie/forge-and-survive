extends CanvasLayer

@onready var iron_label = $Control/ResourcePanel/IronLabel
@onready var wood_label = $Control/ResourcePanel/WoodLabel
@onready var stone_label = $Control/ResourcePanel/StoneLabel
@onready var timer_label = $Control/ResourcePanel/TimerLabel
@onready var wave_label = $Control/ResourcePanel/WaveLabel

func _process(_delta):
	iron_label.text = "Iron: " + str(GameData.resources["iron"])
	wood_label.text = "Wood: " + str(GameData.resources["wood"])
	stone_label.text = "Stone: " + str(GameData.resources["stone"])

	var game_loop = get_tree().get_first_node_in_group("game_loop")
	if game_loop:
		if game_loop.current_phase == 0:  # BUILD
			timer_label.text = "Day: " + str(int(game_loop.get_time_remaining())) + "s"
			wave_label.text = "Wave: " + str(game_loop.wave_number + 1) + "/" + str(game_loop.max_waves)
		else:
			timer_label.text = "NIGHT - DEFEND!"
			wave_label.text = "Wave: " + str(game_loop.wave_number) + "/" + str(game_loop.max_waves)
