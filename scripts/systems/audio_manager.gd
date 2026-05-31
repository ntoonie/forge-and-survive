extends Node

var music_player: AudioStreamPlayer

func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)

func play_main_menu():
	music_player.stream = load("res://assets/audio/mainmenu.mp3")
	music_player.play()

func play_day():
	music_player.stream = load("res://assets/audio/day.ogg")
	music_player.play()

func play_night():
	music_player.stream = load("res://assets/audio/night.ogg")
	music_player.play()

func stop():
	music_player.stop()

func resume():
	music_player.play()
