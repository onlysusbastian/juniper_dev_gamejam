extends AnimatedSprite3D

@onready var sprite = $"."

func _ready():
	sprite.play()

func _process(_delta):

	if not sprite.is_playing():
		queue_free()
