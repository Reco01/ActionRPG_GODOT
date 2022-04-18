extends KinematicBody2D

const playerHurtSound = preload("res://Action RPG Resources/Player/PlayerHurtSound.tscn")

export var acceleration = 500
export var friction = 500
export var max_speed = 100
export var roll_speed = 125

enum {
	Move,
	Roll,
	Attack
}

var state = Move
var stats = PlayerStats
var velocity = Vector2.ZERO
var roll_vector = Vector2.LEFT

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var swordHitbox = $HitboxPivot/SwordHitbox
onready var hurtbox = $Hurtbox
onready var blinkAnimationPlayer = $BlinkAnimationPlayer

func _ready():
	randomize()
	stats.connect("health_zero", self, "queue_free")
	animationTree.active = true
	swordHitbox.knockback_vector = roll_vector

func _process(delta):
	match state:
		Move:
			move_state(delta)
		Roll:
			roll_state(delta)
		Attack:
			attack_state(delta)
	print(state) # Print current state of action 0 = Move; 1 = Roll; 2 = Attack
	
func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	#print(velocity) # Print Velocity on delta
	
	if input_vector != Vector2.ZERO:
		roll_vector = input_vector
		swordHitbox.knockback_vector = input_vector
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		animationTree.set("parameters/Attack/blend_position", input_vector)
		animationTree.set("parameters/Roll/blend_position", input_vector)
		animationState.travel("Run")
		velocity = velocity.move_toward(input_vector * max_speed, acceleration * delta)
	else:
		animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	if Input.is_action_just_pressed("roll"):
		state = Roll
	
	if Input.is_action_just_pressed("attack"):
		state = Attack
		
	move()
	
func roll_state(_delta):
	velocity = roll_vector * roll_speed
	animationState.travel("Roll")
	move()

func attack_state(_delta):
	velocity = Vector2.ZERO
	animationState.travel("Attack")

func move():
	velocity = move_and_slide(velocity)

func roll_animation_finished():
	state = Move
	
func attack_animation_finished():
	state = Move

func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	hurtbox.start_invincibility(0.5)
	hurtbox.create_hit_effect()
	var playerHurtSounds = playerHurtSound.instance()
	get_tree().current_scene.add_child(playerHurtSounds)

func _on_Hurtbox_invincibility_started():
	blinkAnimationPlayer.play("Start")

func _on_Hurtbox_invincibility_ended():
	blinkAnimationPlayer.play("Stop")
