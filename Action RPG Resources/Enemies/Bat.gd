extends KinematicBody2D

const EnemyDeathEffect = preload("res://Action RPG Resources/Effects/EnemyDeathEffect.tscn")
var knockback = Vector2.ZERO
var velocity = Vector2.ZERO

export var acceleration = 300
export var max_speed = 50
export var friction = 200
export var wander_target_range = 4

onready var sprite = $AnimationSprite
onready var stats = $Stats
onready var playerDetectionZone = $PlayerDetectionZone
onready var hurtbox = $Hurtbox
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController
onready var animationPlayer = $AnimationPlayer

enum {
	Idle,
	Wander,
	Chase,
}

var state = Chase

func _ready():
	state = pick_random_state([Idle, Wander])

func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, friction * delta)
	knockback = move_and_slide(knockback)
	
	match state:
		
		Idle:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			seek_player()
			
			if wanderController.get_time_left() == 0:
				update_wander()
			
		Wander:
			seek_player()
			
			if wanderController.get_time_left() == 0:
				update_wander()
				
			accelerate_toward_point(wanderController.target_position, delta)
			
			if global_position.distance_to(wanderController.target_position) <= wander_target_range:
				update_wander()
				
		Chase:
			var player = playerDetectionZone.player
			if player != null:
				accelerate_toward_point(player.global_position, delta)
			else:
				state = Idle
			
	if softCollision.is_colliding():
		velocity += softCollision.get_pushed() * delta * 400
	velocity = move_and_slide(velocity)
	
func update_wander():
	state = pick_random_state([Idle, Wander])
	wanderController.start_wander_timer(rand_range(1, 3))

func accelerate_toward_point(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * max_speed, acceleration * delta)
	sprite.flip_h = velocity.x < 0
	
func seek_player():
	if playerDetectionZone.can_see_player():
		state = Chase

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	knockback = area.knockback_vector * 120
	hurtbox.create_hit_effect()
	hurtbox.start_invincibility(0.4)
 
func _on_Stats_health_zero():
	queue_free()
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position

func _on_Hurtbox_invincibility_started():
	animationPlayer.play("Start")

func _on_Hurtbox_invincibility_ended():
	animationPlayer.play("Stop")
