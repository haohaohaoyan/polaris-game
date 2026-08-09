extends CharacterBody2D

const SPEED = 200
var is_resupply_available = false

func _physics_process(_delta: float) -> void:
	# basic get direction
	var direction = Input.get_vector("LEFT", "RIGHT", "UP", "DOWN")
	velocity = direction.normalized() * SPEED
	# real ones poll every frame (why is my performance shit)
	if len($Area2D.get_overlapping_bodies()) > 0:
		is_resupply_available = true
	else:
		is_resupply_available = false
	
	move_and_slide()
	
	if velocity.length() > 0:
		$AnimatedSprite2D.play("walk")
	else:
		$AnimatedSprite2D.play("default")
