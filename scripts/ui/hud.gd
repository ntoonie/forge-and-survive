extends CanvasLayer

@onready var iron_label = $Control/ResourcePanel/IronLabel
@onready var wood_label = $Control/ResourcePanel/WoodLabel
@onready var stone_label = $Control/ResourcePanel/StoneLabel

func _process(_delta):
	iron_label.text = "Iron: " + str(GameData.resources["iron"])
	wood_label.text = "Wood: " + str(GameData.resources["wood"])
	stone_label.text = "Stone: " + str(GameData.resources["stone"])
