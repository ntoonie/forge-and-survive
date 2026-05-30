extends CollisionShape2D


signal died

func die():
	died.emit()
	queue_free()
