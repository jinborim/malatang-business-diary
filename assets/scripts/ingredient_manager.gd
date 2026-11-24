extends Node

var host

func setup(game_host) -> void:
	host = game_host

func ingredient_color(ingredient_name: String) -> Color:
	if not is_instance_valid(host): return Color.WHITE
	for ingredient in host.INGREDIENTS:
		if str(ingredient[0]) == ingredient_name: return ingredient[1]
	return Color.WHITE

func ingredient_model_path(ingredient_name: String) -> String:
	var paths := {"\uC0C8\uC6B0\uC644\uC790":"res://assets/models/shrimp_ball/shrimp_ball.fbx","\uC18C\uC2DC\uC9C0":"res://assets/models/sausage/sausage.fbx","\uCCAD\uACBD\uCC44":"res://assets/models/bok_choy/bok_choy.fbx","\uBAA9\uC774\uBC84\uC12F":"res://assets/models/wood_ear_mushrooms/wood_ear_mushrooms.fbx","\uC911\uAD6D\uB2F9\uBA74":"res://assets/models/glass_noodle/glass_noodle.fbx","\uBD84\uBAA8\uC790":"res://assets/models/bunja/bunja.fbx","\uAC74\uB450\uBD80":"res://assets/models/gun_dubu/gun_dubu.fbx","\uC54C\uBC30\uAE30\uBC30\uCD94":"res://assets/models/albaegi_cabbage/albaegi_cabbage.fbx","\uD301\uC774\uBC84\uC12F":"res://assets/models/enoki_mushroom/enoki_mushroom.fbx","\uD478\uC8FC":"res://assets/models/tofu_skin.fbx","\uC219\uC8FC":"res://assets/models/bean_sprouts.fbx"}
	return str(paths.get(ingredient_name, ""))

func ingredient_texture_path(ingredient_name: String) -> String:
	var paths := {"\uC0C8\uC6B0\uC644\uC790":"res://assets/models/shrimp_ball/shrimp_ball.png","\uC18C\uC2DC\uC9C0":"res://assets/models/sausage/sausage.png","\uCCAD\uACBD\uCC44":"res://assets/models/bok_choy/bok_choy.png","\uBAA9\uC774\uBC84\uC12F":"res://assets/models/wood_ear_mushrooms/wood_ear_mushrooms.png","\uC911\uAD6D\uB2F9\uBA74":"res://assets/models/glass_noodle/glass_noodle.png","\uBD84\uBAA8\uC790":"res://assets/models/bunja/bunja.png","\uAC74\uB450\uBD80":"res://assets/models/gun_dubu/gun_dubu.png","\uC54C\uBC30\uAE30\uBC30\uCD94":"res://assets/models/albaegi_cabbage/albaegi_cabbage.png","\uD301\uC774\uBC84\uC12F":"res://assets/models/enoki_mushroom/enoki_mushroom.png","\uD478\uC8FC":"res://assets/models/tofu_skin.png","\uC219\uC8FC":"res://assets/models/bean_sprouts.png"}
	return str(paths.get(ingredient_name, ""))

func _add_model(parent: Node3D, model_position: Vector3, model_path: String, texture_path: String, model_name: String, model_scale: float = 0.3) -> Node3D:
	var resource := load(model_path) as PackedScene
	if resource == null: return null
	var model := resource.instantiate() as Node3D
	if model == null: return null
	model.name = model_name
	model.position = model_position
	model.scale = Vector3.ONE * model_scale
	parent.add_child(model)
	_apply_preview_material(model, texture_path)
	return model

func add_bean_sprouts_model(parent: Node3D, model_position: Vector3) -> Node3D:
	return _add_model(parent, model_position, "res://assets/models/bean_sprouts.fbx", "res://assets/models/bean_sprouts.png", "BeanSproutsModel", 0.32)

func add_tofu_skin_model(parent: Node3D, model_position: Vector3) -> Node3D:
	return _add_model(parent, model_position, "res://assets/models/tofu_skin.fbx", "res://assets/models/tofu_skin.png", "TofuSkinModel", 0.30)

func add_shrimp_ball_model(parent: Node3D, model_position: Vector3) -> Node3D:
	return _add_model(parent, model_position, "res://assets/models/shrimp_ball/shrimp_ball.fbx", "res://assets/models/shrimp_ball/shrimp_ball.png", "ShrimpBallModel", 0.30)

func add_sausage_model(parent: Node3D, model_position: Vector3) -> Node3D:
	return _add_model(parent, model_position, "res://assets/models/sausage/sausage.fbx", "res://assets/models/sausage/sausage.png", "SausageModel", 0.30)

func add_bok_choy_model(parent: Node3D, model_position: Vector3) -> Node3D:
	return _add_model(parent, model_position, "res://assets/models/bok_choy/bok_choy.fbx", "res://assets/models/bok_choy/bok_choy.png", "BokChoyModel", 0.30)

func add_wood_ear_model(parent: Node3D, model_position: Vector3) -> Node3D:
	return _add_model(parent, model_position, "res://assets/models/wood_ear_mushrooms/wood_ear_mushrooms.fbx", "res://assets/models/wood_ear_mushrooms/wood_ear_mushrooms.png", "WoodEarModel", 0.30)

func add_glass_noodle_model(parent: Node3D, model_position: Vector3) -> Node3D:
	return _add_model(parent, model_position, "res://assets/models/glass_noodle/glass_noodle.fbx", "res://assets/models/glass_noodle/glass_noodle.png", "GlassNoodleModel", 0.30)

func add_bunja_model(parent: Node3D, model_position: Vector3) -> Node3D:
	return _add_model(parent, model_position, "res://assets/models/bunja/bunja.fbx", "res://assets/models/bunja/bunja.png", "BunjaModel", 0.30)

func add_gun_dubu_model(parent: Node3D, model_position: Vector3) -> Node3D:
	return _add_model(parent, model_position, "res://assets/models/gun_dubu/gun_dubu.fbx", "res://assets/models/gun_dubu/gun_dubu.png", "GunDubuModel", 0.30)

func add_albaegi_cabbage_model(parent: Node3D, model_position: Vector3) -> Node3D:
	return _add_model(parent, model_position, "res://assets/models/albaegi_cabbage/albaegi_cabbage.fbx", "res://assets/models/albaegi_cabbage/albaegi_cabbage.png", "AlbaegiCabbageModel", 0.30)

func add_enoki_model(parent: Node3D, model_position: Vector3) -> Node3D:
	return _add_model(parent, model_position, "res://assets/models/enoki_mushroom/enoki_mushroom.fbx", "res://assets/models/enoki_mushroom/enoki_mushroom.png", "EnokiModel", 0.30)

func animate_tongs_and_add_visual(ingredient_name: String) -> void:
	# The existing cooking interaction owns the tongs animation. This hook keeps
	# the manager API compatible while the visual model is added by the caller.
	return

func make_model_preview(ingredient_name: String, preview_size: int) -> Control:
	var resource := load(ingredient_model_path(ingredient_name)) as PackedScene
	if resource == null: return null
	var container := SubViewportContainer.new(); container.name = "IngredientModelPreview"; container.custom_minimum_size = Vector2(preview_size, preview_size); container.size = Vector2(preview_size, preview_size); container.stretch = true; container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport := SubViewport.new(); viewport.size = Vector2i(128, 128); viewport.transparent_bg = true; viewport.world_3d = World3D.new(); viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; container.add_child(viewport)
	var root := Node3D.new(); viewport.add_child(root)
	var camera := Camera3D.new(); camera.position = Vector3(0, 0.18, 1.45); camera.look_at(Vector3(0, 0.05, 0), Vector3.UP); root.add_child(camera)
	var light := DirectionalLight3D.new(); light.rotation_degrees = Vector3(-35, -25, 0); light.light_energy = 1.7; root.add_child(light)
	var fill := OmniLight3D.new(); fill.position = Vector3(-0.45, 0.55, 0.7); fill.light_energy = 1.1; fill.omni_range = 3.0; root.add_child(fill)
	var model := resource.instantiate() as Node3D; model.position = Vector3(0, -0.18, 0); model.rotation_degrees = Vector3(0, 180, 0); model.scale = Vector3.ONE * 0.52; root.add_child(model)
	_apply_preview_material(model, ingredient_texture_path(ingredient_name))
	return container

func _apply_preview_material(root: Node, texture_path: String) -> void:
	var material := StandardMaterial3D.new(); material.albedo_color = Color.WHITE; material.roughness = 0.76
	if not texture_path.is_empty(): material.albedo_texture = load(texture_path) as Texture2D
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		if is_instance_valid(mesh): mesh.material_override = material

func apply_bean_sprouts_preview_material(root: Node) -> void: _apply_preview_material(root, "res://assets/models/bean_sprouts.png")
func apply_tofu_skin_preview_material(root: Node) -> void: _apply_preview_material(root, "res://assets/models/tofu_skin.png")
func apply_sausage_preview_material(root: Node) -> void: _apply_preview_material(root, "res://assets/models/sausage/sausage.png")
func apply_shrimp_preview_material(root: Node) -> void: _apply_preview_material(root, "res://assets/models/shrimp_ball/shrimp_ball.png")
func apply_bok_choy_preview_material(root: Node) -> void: _apply_preview_material(root, "res://assets/models/bok_choy/bok_choy.png")
func apply_wood_ear_preview_material(root: Node) -> void: _apply_preview_material(root, "res://assets/models/wood_ear_mushrooms/wood_ear_mushrooms.png")
func apply_glass_noodle_preview_material(root: Node) -> void: _apply_preview_material(root, "res://assets/models/glass_noodle/glass_noodle.png")
func apply_bunja_preview_material(root: Node) -> void: _apply_preview_material(root, "res://assets/models/bunja/bunja.png")
func apply_gun_dubu_preview_material(root: Node) -> void: _apply_preview_material(root, "res://assets/models/gun_dubu/gun_dubu.png")
func apply_albaegi_cabbage_preview_material(root: Node) -> void: _apply_preview_material(root, "res://assets/models/albaegi_cabbage/albaegi_cabbage.png")
func apply_enoki_preview_material(root: Node) -> void: _apply_preview_material(root, "res://assets/models/enoki_mushroom/enoki_mushroom.png")
