extends CharacterBody3D

@export var speed := 5.0
@export var mouse_sensitivity := 0.0022
var camera: Camera3D
var input_locked := false

func _ready() -> void:
	camera = get_node_or_null("Camera3D") as Camera3D
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if input_locked: return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and is_instance_valid(camera):
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x - event.relative.y * mouse_sensitivity, -1.35, 1.35)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if input_locked:
		velocity = Vector3.ZERO
		return

	# 이동축을 명시적으로 읽습니다.
	# move_forward(W)는 -1, move_back(S)는 +1이므로
	# 기본 카메라 방향(-Z)에서 W가 앞으로 움직입니다.
	var input_x := Input.get_axis("move_left", "move_right")
	var input_z := Input.get_axis("move_forward", "move_back")
	var input := Vector2(input_x, input_z)
	if input.length_squared() > 1.0:
		input = input.normalized()

	# 스케일/기울기가 섞인 transform.basis를 그대로 사용하지 않습니다.
	# 수평 회전만 남겨 대각선 이동과 충돌 시 속도 튐을 방지합니다.
	var yaw_basis := global_transform.basis.orthonormalized()
	var direction := yaw_basis * Vector3(input.x, 0.0, input.y)
	direction.y = 0.0
	if direction.length_squared() > 0.0001:
		direction = direction.normalized()
	else:
		direction = Vector3.ZERO

	var move_speed := maxf(0.0, speed)
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	if not is_on_floor(): velocity.y -= 20.0 * delta
	else: velocity.y = 0.0
	move_and_slide()
