extends CharacterBody2D

const SPEED = 200

func _physics_process(_delta: float) -> void:
	# basic get direction
	var direction = Input.get_vector("LEFT", "RIGHT", "UP", "DOWN")
	velocity = direction.normalized() * SPEED
	move_and_slide()
