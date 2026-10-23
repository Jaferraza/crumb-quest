extends CharacterBody2D

const MAX_SPEED := 110.0
const ACCEL := 800.0
const GROUND_FRICTION := 1000.0
const AIR_FRICTION := 400.0
const JUMP_VELOCITY := -300.0
const GRAVITY := 900.0
const MAX_FALL := 400.0
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.1

const SURFACES := {
	"honey": {"speed": 0.5, "accel": 1.0, "friction": 3.0, "jump": 0.7},
	"water": {"speed": 1.0, "accel": 0.15, "friction": 0.1, "jump": 1.0},
}

var speed_mult := 1.0
var accel_mult := 1.0
var friction_mult := 1.0
var jump_mult := 1.0
var surface := ""

var coyote_timer := 0.0
var buffer_timer := 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
func _ready() -> void:
	add_to_group("player")
	anim.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL)
		coyote_timer -= delta
	else:
		coyote_timer = COYOTE_TIME
		surface = _get_surface()
		_apply_surface(surface)

	if Input.is_action_just_pressed("jump"):
		buffer_timer = JUMP_BUFFER
	else:
		buffer_timer -= delta

	if buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY * jump_mult
		buffer_timer = 0.0
		coyote_timer = 0.0

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5

	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * MAX_SPEED * speed_mult, ACCEL * accel_mult * delta)
		anim.flip_h = dir < 0.0
	else:
		var f := (GROUND_FRICTION if is_on_floor() else AIR_FRICTION) * friction_mult
		velocity.x = move_toward(velocity.x, 0.0, f * delta)

	move_and_slide()
	_update_animation(dir)

func _update_animation(dir: float) -> void:
	var next := "idle"
	if not is_on_floor():
		next = "jump"
	elif surface == "water" and absf(velocity.x) > 10.0:
		next = "oil"
	elif dir != 0.0:
		next = "walk"
	if anim.animation != next:
		anim.play(next)

func _get_surface() -> String:
	var layer := get_tree().get_first_node_in_group("ground") as TileMapLayer
	if layer == null:
		return ""
	var coords := layer.local_to_map(layer.to_local(global_position + Vector2(0, 2)))
	var data := layer.get_cell_tile_data(coords)
	if data == null:
		return ""
	return str(data.get_custom_data("surface"))

func _apply_surface(s: String) -> void:
	var m: Dictionary = SURFACES.get(s, {})
	speed_mult = m.get("speed", 1.0)
	accel_mult = m.get("accel", 1.0)
	friction_mult = m.get("friction", 1.0)
	jump_mult = m.get("jump", 1.0)
