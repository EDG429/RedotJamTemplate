extends CharacterBody2D

# Player state enumeration & defaulting to idle.
enum State {
	IDLE,
	RUN,
	SHOOT,
	SLASH,
	TAKE_DAMAGE,
	DIE
}
var state: int = State.IDLE

# Constants
# Maximum allowed movement (in pixels) during an action state.
const MAX_ACTION_MOVE: float = 25.0

# @export variables
@export var speed: int = 200
@export var max_health: int = 500
@export var max_stamina: int = 200

# @onready variables
@onready var anim_sprite: AnimatedSprite2D = $P1AnimatedSprite
@onready var hurtbox: Area2D = $P1Hurtbox
@onready var sfx_player: AudioStreamPlayer2D = $SFX_Player


# Player1 variables
# This will store the player's position when an action state begins.
var action_start_position: Vector2 = Vector2.ZERO

# Preload variables
var slash_sfx = [
	preload("res://Player1/FlashSFX/slash1.wav"),
	preload("res://Player1/FlashSFX/slash2.wav")
]

func _ready() -> void:
	# Connect the animation_finished signal (no arguments in Godot 4).
	anim_sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	# Connect the hurtbox signal.
	hurtbox.connect("body_entered", Callable(self, "_on_hurtbox_body_entered"))
	_set_state(State.IDLE)

func _physics_process(delta: float) -> void:
	# Only process input if the player is in a neutral state (IDLE or RUN).
	if state == State.IDLE or state == State.RUN:
		var input_vector = Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		).normalized()
		
		velocity = input_vector * speed
		
		# Update state based on input.
		if input_vector != Vector2.ZERO:
			_set_state(State.RUN)
			anim_sprite.flip_h = (input_vector.x < 0)
		else:
			_set_state(State.IDLE)
		
		# Allow initiating an action when neutral.
		if Input.is_action_just_pressed("shoot"):
			_set_state(State.SHOOT)
		elif Input.is_action_just_pressed("slash"):
			_set_state(State.SLASH)
	else:
		# In action states (Shoot, Slash, TakeDamage, Die), restrict movement.
		var displacement = global_position.distance_to(action_start_position)
		if displacement >= MAX_ACTION_MOVE:
			velocity = Vector2.ZERO
	
	# Apply movement.
	move_and_slide()

# Helper function to change state and start the corresponding animation.
func _set_state(new_state: int) -> void:
	# If already in the desired state, do nothing.
	if state == new_state:
		return
	state = new_state
	
	# When entering an action state, record the starting position.
	if state == State.SHOOT or state == State.SLASH or state == State.TAKE_DAMAGE or state == State.DIE:
		action_start_position = global_position
	
	match state:
		State.IDLE:
			anim_sprite.play("Idle", 1.0, 0)  # Force Idle to start at frame 0.
		State.RUN:
			anim_sprite.play("Run")
		State.SHOOT:
			anim_sprite.play("Shoot")
		State.SLASH:
			anim_sprite.play("Slash")
			play_random_slash_sfx()
		State.TAKE_DAMAGE:
			anim_sprite.play("TakeDamage")
		State.DIE:
			anim_sprite.play("Die")

# Called when the current animation finishes.
func _on_animation_finished() -> void:
	# When an action animation completes, immediately revert to Idle.
	if state == State.SHOOT or state == State.SLASH or state == State.TAKE_DAMAGE or state == State.DIE:
		_set_state(State.IDLE)

# Function to apply damage to the player.
func take_damage(amount: int) -> void:
	# (Implement health reduction here as needed.)
	_set_state(State.TAKE_DAMAGE)

# Hurtbox signal callback.
func _on_hurtbox_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		take_damage(1)

# Play a random slash sound effect with pitch variation
func play_random_slash_sfx():
	var random_index = randi() % slash_sfx.size()
	sfx_player.stream = slash_sfx[random_index]
	sfx_player.pitch_scale = randf_range(0.85, 1.2)
	sfx_player.play()
