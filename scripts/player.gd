extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_hide_first_person_head()
	_apply_body_texture()


func _hide_first_person_head() -> void:
	var nodes_to_check = [self]
	while nodes_to_check.size() > 0:
		var current = nodes_to_check.pop_front()
		for child in current.get_children():
			if child is MeshInstance3D and (String(child.name).contains("Head") or String(child.name).contains("Cape")):
				child.visible = false
			nodes_to_check.append(child)


func _apply_body_texture() -> void:
	var tex := load("res://assets/character_models/rogue (2).png") as Texture2D
	if tex == null:
		return

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex

	var nodes_to_check = [self]
	while nodes_to_check.size() > 0:
		var current = nodes_to_check.pop_front()
		for child in current.get_children():
			if child is MeshInstance3D:
				if child.mesh != null:
					for i in child.mesh.get_surface_count():
						child.set_surface_override_material(i, mat)
			nodes_to_check.append(child)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		$Camera.rotate_x(-event.relative.y * mouse_sensitivity)
		$Camera.rotation.x = clamp($Camera.rotation.x, -1.5, 1.5)

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
