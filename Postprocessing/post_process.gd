extends CanvasLayer

func _ready():
	var root = get_tree().root
	root.move_child(self, root.get_child_count() - 1)
