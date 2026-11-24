@tool
extends Node3D

@export_range(1, 3) var stage: int = 1

const STAGE1_WALL_TILES_PATH := "res://assets/textures/stage1_wall_tiles.png"
const STAGE1_FLOOR_TILES_PATH := "res://assets/textures/stage1_floor_tiles.png"
const STAGE1_WALL_PLASTER_PATH := "res://assets/textures/stage1_wall_plaster.png"
const STAGE1_STAINLESS_PATH := "res://assets/textures/stage1_stainless.png"
const DINING_WALLPAPER_PATH := "res://assets/textures/dining_wallpaper_red_gold.png"

func _ready() -> void:
	var existing_preview := get_node_or_null("EditorPreview") as Node3D
	if existing_preview:
		existing_preview.visible = Engine.is_editor_hint()
	if Engine.is_editor_hint():
		_show_editor_objects()
	if not Engine.is_editor_hint():
		_hide_runtime_previews()
	if Engine.is_editor_hint():
		if get_node_or_null("__LayoutGenerated") == null:
			_build_editor_layout()
		# Older layout scenes already contain __LayoutGenerated but were saved
		# before the tool pads were added. Ensure these editable anchors exist too.
		_add_box("ToolStation", Vector3(4.8, 0.45, -7.1), Vector3(2.4, 0.9, 0.78), Color("9b9185"))
		_add_box("TongsPickup", Vector3(4.35, 0.98, -6.87), Vector3(0.8, 0.12, 0.48), Color("d7d0c6"))
		_add_box("BowlPickup", Vector3(5.25, 0.98, -6.87), Vector3(0.8, 0.12, 0.48), Color("d7d0c6"))
		_ensure_editor_preview()
		_apply_shell_materials()
		_ensure_dining_wallpaper()
		_ensure_open_kitchen_pass_counter()
		_show_editor_objects()
	_remove_obsolete_kitchen_sight_barriers()

func _remove_obsolete_kitchen_sight_barriers() -> void:
	# These legacy sight-block meshes split the main passage and can make the
	# kitchen look like a sealed room. Keep the nodes for scene compatibility,
	# but hide them and remove any accidental collision from older scene saves.
	for node_name in ["KitchenSightBlockLeft", "KitchenSightBlockRight", "KitchenSightHeader", "DeliveryOnlyPrivacyScreen", "PickupPartition"]:
		var node := get_node_or_null(node_name) as Node3D
		if not is_instance_valid(node): continue
		node.visible = false
		for child in node.find_children("*", "StaticBody3D", true, false):
			var body := child as StaticBody3D
			if is_instance_valid(body):
				body.collision_layer = 0
				body.collision_mask = 0

func _hide_runtime_previews() -> void:
	var preview_root := get_node_or_null("EditorPreview") as Node3D
	if is_instance_valid(preview_root):
		preview_root.visible = false
	for node in find_children("*", "Node3D", true, false):
		var node_name:=str(node.name)
		# The sink model is an actual editable kitchen object, despite its
		# historical name. Keep it visible at runtime so the game uses the same
		# model and transform that are edited in the scene.
		var runtime_editable := node_name in ["KitchenSinkModel_EditorPreview", "BrothPotModel_EditorPreview", "BrothPotFilled_EditorPreview", "BrothLiquid_EditorPreview", "BrothWaterTap_EditorPreview", "BrothStockPack_EditorPreview", "Spice_1_EditorPreview", "Spice_2_EditorPreview", "SpiceLevel3Editable"]
		if (node_name.contains("EditorPreview") and not runtime_editable) or node_name.begins_with("IngredientPreview_"):
			node.visible = false

func _show_editor_objects() -> void:
	for node in find_children("*", "Node3D", true, false):
		if str(node.name) in ["BrothPot_EditorPreview", "IngredientPreview_2", "IngredientPreview_6", "Spice_3_EditorPreview"]:
			node.visible = false
		else:
			node.visible = true

func _is_shell_surface(node_name: String) -> bool:
	return node_name == "Floor" or node_name == "BackWall" or node_name == "LeftWall" or node_name == "RightWall" or node_name == "FrontWallLeft" or node_name == "FrontWallRight" or node_name == "Ceiling" or node_name == "KitchenCounter" or node_name == "BrothStation"

func _dining_wallpaper_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var texture := load(DINING_WALLPAPER_PATH) as Texture2D
	if is_instance_valid(texture):
		material.albedo_texture = texture
		material.albedo_color = Color.WHITE
	else:
		material.albedo_color = Color("8f1f1c")
	material.roughness = 0.82
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.uv1_scale = Vector3(3.0, 1.5, 1.0)
	return material

func _ensure_dining_wallpaper() -> void:
	if stage < 2: return
	var structure := get_node_or_null("StageStructure") as Node3D
	if not is_instance_valid(structure):
		structure = Node3D.new()
		structure.name = "StageStructure"
		add_child(structure)
		structure.owner = self
	var dining_start_z := -1.0
	var front_z := 10.35
	var dining_center_z := (dining_start_z + front_z) * 0.5
	var dining_length := front_z - dining_start_z
	for panel_data in [["DiningWallpaperLeft", Vector3(-8.86, 2.5, dining_center_z), Vector3(0.08, 4.7, dining_length)], ["DiningWallpaperRight", Vector3(8.86, 2.5, dining_center_z), Vector3(0.08, 4.7, dining_length)]]:
		var panel := structure.get_node_or_null(str(panel_data[0])) as MeshInstance3D
		if not is_instance_valid(panel):
			panel = MeshInstance3D.new()
			panel.name = str(panel_data[0])
			var shape := BoxMesh.new()
			shape.size = panel_data[2]
			panel.mesh = shape
			panel.position = panel_data[1]
			structure.add_child(panel)
			panel.owner = self
		panel.material_override = _dining_wallpaper_material()

func _ensure_open_kitchen_pass_counter() -> void:
	if stage < 2: return
	var structure := get_node_or_null("StageStructure") as Node3D
	if not is_instance_valid(structure): return
	var counter := structure.get_node_or_null("OpenKitchenPassCounter") as MeshInstance3D
	if not is_instance_valid(counter):
		counter = MeshInstance3D.new()
		counter.name = "OpenKitchenPassCounter"
		var shape := BoxMesh.new()
		shape.size = Vector3(5.2, 1.35, 0.8)
		counter.mesh = shape
		counter.position = Vector3(1.3, 0.68, -3.6)
		structure.add_child(counter)
		counter.owner = self
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("3b2924")
	material.roughness = 0.72
	counter.material_override = material

func _shell_texture(node_name: String) -> Texture2D:
	var path := STAGE1_WALL_PLASTER_PATH
	if node_name == "Floor": path = STAGE1_FLOOR_TILES_PATH
	elif node_name == "BackWall": path = STAGE1_WALL_TILES_PATH
	elif node_name == "KitchenCounter" or node_name == "BrothStation": path = STAGE1_STAINLESS_PATH
	return load(path) as Texture2D

func _shell_fallback_color(node_name: String) -> Color:
	if node_name == "Floor": return Color("#4b5054")
	if node_name == "KitchenCounter" or node_name == "BrothStation": return Color("#c7c4bd")
	if node_name == "Ceiling": return Color("#f4f0e8")
	return Color("#eee8dc")

func _make_shell_material(node_name: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var texture := _shell_texture(node_name)
	if is_instance_valid(texture):
		material.albedo_texture = texture
		material.albedo_color = Color.WHITE
	else:
		material.albedo_color = _shell_fallback_color(node_name)
	material.roughness = 0.78
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material

func _apply_shell_materials() -> void:
	for node_name in ["Floor", "BackWall", "LeftWall", "RightWall", "FrontWallLeft", "FrontWallRight", "Ceiling", "KitchenCounter", "BrothStation"]:
		var node := get_node_or_null(node_name) as MeshInstance3D
		if is_instance_valid(node):
			node.material_override = _make_shell_material(node_name)

func _add_box(node_name: String, position: Vector3, size: Vector3, color: Color) -> void:
	if get_node_or_null(node_name) != null:
		return
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.position = position
	var material := StandardMaterial3D.new()
	if _is_shell_surface(node_name):
		material = _make_shell_material(node_name)
	else:
		material.albedo_color = color
	mesh.material_override = material
	add_child(mesh)
	mesh.owner = self

func _add_model(path: String, node_name: String, position: Vector3, rotation: Vector3, scale_value: float) -> void:
	if get_node_or_null(node_name) != null:
		return
	var resource := load(path) as PackedScene
	if resource == null:
		return
	var model := resource.instantiate() as Node3D
	if model == null:
		return
	model.name = node_name
	model.position = position
	model.rotation_degrees = rotation
	model.scale = Vector3.ONE * scale_value
	add_child(model)
	model.owner = self

func _build_editor_layout() -> void:
	var marker := Node3D.new()
	marker.name = "__LayoutGenerated"
	add_child(marker)
	marker.owner = self

	# 배달 전용 1단계는 주방 뒤쪽은 유지하고, 비어 있는 고객 공간만 짧게 잡습니다.
	var room_depth := 18.0 if stage == 1 else 20.0
	var room_center_z := -0.5 if stage == 1 else 0.5
	var front_z := 8.05 if stage == 1 else 10.35
	_add_box("Floor", Vector3(0, -0.15, room_center_z), Vector3(18, 0.3, room_depth), Color("4b5054"))
	_add_box("BackWall", Vector3(0, 2.5, -9), Vector3(18, 5, 0.25), Color("eee8dc"))
	_add_box("LeftWall", Vector3(-9, 2.5, room_center_z), Vector3(0.25, 5, room_depth), Color("eee8dc"))
	_add_box("RightWall", Vector3(9, 2.5, room_center_z), Vector3(0.25, 5, room_depth), Color("eee8dc"))
	_add_box("FrontWallLeft", Vector3(-2.0, 2.5, front_z), Vector3(14.0, 5.0, 0.25), Color("eee8dc"))
	_add_box("FrontWallRight", Vector3(8.35, 2.5, front_z), Vector3(1.3, 5.0, 0.25), Color("eee8dc"))
	_add_box("Ceiling", Vector3(0, 5.4, room_center_z), Vector3(18, 0.25, room_depth), Color("f4f0e8"))
	var showcase := Node3D.new()
	showcase.name = "IngredientShowcase_Editable"
	showcase.position = Vector3(-5.6, 0, -7.5)
	showcase.rotation_degrees.y = 180.0
	add_child(showcase)
	showcase.owner = self
	_add_box_to("ShowcaseBack", Vector3(0, 2.1, 0.45), Vector3(5.8, 4.2, 0.25), Color("3d4548"), showcase)
	for row in 4:
		_add_box_to("Shelf_%d" % row, Vector3(0, 0.55 + row * 0.95, 0), Vector3(5.8, 0.12, 1.25), Color("aeb8b8"), showcase)
	_add_box("KitchenCounter", Vector3(0.10, 0.55, -7.5), Vector3(4.1, 1.1, 2.0), Color("c7c4bd"))
	_add_box("BrothStation", Vector3(-1.25, 0.55, -7.5), Vector3(1.5, 1.1, 2.0), Color("aaa9a5"))
	_add_box("MonitorDesk", Vector3(6.55, 0.55, -3.55), Vector3(3.0, 1.1, 1.25), Color("796a60"))
	_add_box("TrashCanLayoutGuide", Vector3(3.9, 0.55, -1.7), Vector3(0.8, 1.1, 0.8), Color("4d5960"))
	_add_box("KitchenSightBlockLeft", Vector3(-3.45, 1.45, -3.0), Vector3(3.1, 2.9, 0.32), Color("d8d1c5"))
	_add_box("KitchenSightBlockRight", Vector3(4.15, 1.45, -3.0), Vector3(3.1, 2.9, 0.32), Color("d8d1c5"))
	_add_box("KitchenSightHeader", Vector3(0.35, 3.15, -3.0), Vector3(4.7, 0.35, 0.32), Color("d8d1c5"))
	_add_box("DeliveryCounter", Vector3(5.8, 0.65, 4.6), Vector3(3.5, 1.3, 1.5), Color("b5473d"))
	_add_box("PickupPartition", Vector3(4.2, 2.0, 5.8), Vector3(0.2, 4.0, 2.4), Color("eee8dc"))
	_add_box("ToolStation", Vector3(4.8, 0.45, -7.1), Vector3(2.4, 0.9, 0.78), Color("9b9185"))
	_add_box("TongsPickup", Vector3(4.35, 0.98, -6.87), Vector3(0.8, 0.12, 0.48), Color("d7d0c6"))
	_add_box("BowlPickup", Vector3(5.25, 0.98, -6.87), Vector3(0.8, 0.12, 0.48), Color("d7d0c6"))
	var structure := Node3D.new()
	structure.name = "StageStructure"
	add_child(structure)
	structure.owner = self
	if stage == 1:
		_add_box_to("DeliveryOnlyDivider", Vector3(4.1, 2.0, 1.7), Vector3(0.25, 4.0, 5.5), Color("eee8dc"), structure)
		_add_box_to("CompactKitchenHeader", Vector3(0, 4.2, -1.0), Vector3(17.5, 0.35, 11.5), Color("d8d1c5"), structure)
	elif stage >= 3:
		_add_box_to("ExpandedFloor", Vector3(0, -0.15, 8.5), Vector3(18, 0.3, 3.0), Color("4b5054"), structure)
		_add_box_to("ExpandedLeftWall", Vector3(-9, 2.5, 8.5), Vector3(0.25, 5, 3.0), Color("eee8dc"), structure)
		_add_box_to("ExpandedRightWall", Vector3(9, 2.5, 8.5), Vector3(0.25, 5, 3.0), Color("eee8dc"), structure)
		_add_box_to("ExtraPrepCounter", Vector3(-1.5, 0.55, 4.8), Vector3(3.8, 1.1, 1.4), Color("b9bdba"), structure)
	_add_model("res://assets/models/gas_stove.fbx", "CommercialGasStoveModel", Vector3(0, 1.1, -7.5), Vector3(0, 180, 0), 1.55)
	_add_model("res://assets/models/malatang_pot.fbx", "MalatangCookingPotModel", Vector3(1.2, 1.55, -7.5), Vector3(0, 180, 0), 0.62)
	_add_model("res://assets/models/stainless_table.fbx", "StainlessPrepTableModel", Vector3(3.2, 0.55, -7.5), Vector3(0, 180, 0), 1.0)

	# Reuse serialized dining furniture when the scene already contains it.
	# Creating a second DiningArea here made editor-authored table placement
	# appear duplicated or appear to reset when the game loaded the layout.
	var dining := get_node_or_null("DiningArea") as Node3D
	if dining == null:
		dining = Node3D.new()
		dining.name = "DiningArea"
		add_child(dining)
		dining.owner = self
	var table_count := 4 if stage >= 3 else (2 if stage >= 2 else 0)
	for i in table_count:
		var row := floori(float(i) / 2.0)
		var column := i % 2
		var table_position := Vector3(1.8 + column * 3.2, 0.65, 0.9 + row * 3.0)
		_add_model_to("res://assets/models/dining_table.fbx", "DiningTableModel_%d" % (i + 1), table_position, Vector3(0, 180, 0), 0.72, dining)
		for side in [-1, 1]:
			var chair_position := table_position + Vector3(0, -0.2, side * 1.55)
			_add_model_to("res://assets/models/dining_chair.fbx", "ChairModel_%d_%d" % [i, side], chair_position, Vector3(0, 0 if side == -1 else 180, 0), 0.72, dining)
	_ensure_editor_preview()

func _ensure_editor_preview() -> void:
	if not Engine.is_editor_hint():
		return
	# Runtime creates these small interaction props dynamically. Keep matching
	# editor-only meshes in every layout so scene editing shows the real kitchen.
	_add_model_to("res://assets/models/broth_pot/broth_pot.fbx", "BrothPotModel_EditorPreview", Vector3(-1.25, 1.55, -7.5), Vector3(0, 180, 0), 0.62, self)
	var old_broth_preview := get_node_or_null("BrothPot_EditorPreview") as Node3D
	if is_instance_valid(old_broth_preview): old_broth_preview.visible = false
	_add_preview_cylinder("BrothLiquid_EditorPreview", Vector3(-1.15, 1.83, -7.22), 0.42, 0.035, Color("6495aa"))
	_add_preview_cylinder("BrothWaterTap_EditorPreview", Vector3(-1.78, 1.55, -7.45), 0.16, 0.75, Color("7f9eac"))
	var old_mala_base_preview := get_node_or_null("BrothBase_EditorPreview") as Node3D
	if is_instance_valid(old_mala_base_preview): old_mala_base_preview.visible = false
	for i in 3:
		_add_preview_cylinder("Spice_%d_EditorPreview" % (i + 1), Vector3(2.30 + i * 0.90, 1.78, -7.5), 0.15, 0.42, [Color("e3c35e"), Color("c86435"), Color("a92e27")][i])
	for i in 12:
		var col := i % 3
		var row := floori(float(i) / 3.0)
		_add_preview_cylinder("IngredientPreview_%d" % i, Vector3(-7.5 + col * 1.9, 1.12 + row * 0.95, -7.6), 0.30, 0.28, Color("66b875"))
	_add_model_to("res://assets/models/tofu_skin.fbx", "IngredientTofuModel_EditorPreview", Vector3(-7.5 + 2 * 1.9, 1.15 + 0 * 0.95, -7.6), Vector3.ZERO, 0.30, self)
	_add_model_to("res://assets/models/bean_sprouts.fbx", "IngredientSproutsModel_EditorPreview", Vector3(-7.5 + 0 * 1.9, 1.15 + 2 * 0.95, -7.6), Vector3.ZERO, 0.32, self)
	var tofu_placeholder := get_node_or_null("IngredientPreview_2") as Node3D
	if is_instance_valid(tofu_placeholder): tofu_placeholder.visible = false
	var sprouts_placeholder := get_node_or_null("IngredientPreview_6") as Node3D
	if is_instance_valid(sprouts_placeholder): sprouts_placeholder.visible = false
	_add_preview_cylinder("TrashCan_EditorPreview", Vector3(8.2, 0.55, -3.8), 0.48, 1.1, Color("4d5960"))
	var kitchen_counter := get_node_or_null("KitchenCounter") as MeshInstance3D
	if is_instance_valid(kitchen_counter):
		kitchen_counter.visible = false
	var delivery_counter := get_node_or_null("DeliveryCounter") as MeshInstance3D
	if is_instance_valid(delivery_counter):
		delivery_counter.visible = false
	# These are real scene children, not temporary preview-only nodes. Runtime
	# reuses the same nodes so editor placement remains authoritative.
	_add_model_to("res://assets/models/kitchen_tongs.fbx", "KitchenTongsPickupModel", Vector3(4.35, 1.10, -6.87), Vector3(0, 180, 0), 0.22, self)
	_add_model_to("res://assets/models/ingredient_bowl.fbx", "IngredientBowlPickupModel", Vector3(5.25, 1.09, -6.87), Vector3(0, 180, 0), 0.22, self)
	_add_model_to("res://assets/models/sink/sink.fbx", "KitchenSinkModel_EditorPreview", Vector3(5.55, 0.55, -7.15), Vector3(0, 180, 0), 0.95, self)
	_add_model_to("res://assets/models/broth_stock/stock_pack.fbx", "BrothStockPack_EditorPreview", Vector3(4.6, 1.85, -8.0), Vector3(0, 180, 0), 0.38, self)
	_add_model_to("res://assets/models/spice_level_3.fbx", "SpiceLevel3Editable", Vector3(4.10, 1.78, -7.5), Vector3(0, 180, 0), 0.30, self)
	_apply_spice_level_3_material(get_node_or_null("SpiceLevel3Editable"))
	var preview := get_node_or_null("EditorPreview") as Node3D
	if preview == null:
		preview = Node3D.new()
		preview.name = "EditorPreview"
		preview.visible = true
		preview.set_meta("editor_only_preview", true)
		add_child(preview)
		preview.owner = self
	# Bowl/container placement previews remain separate because runtime creates
	# copies for the player's hand and for each customer/courier.
	_add_model_to("res://assets/models/serving_bowl.fbx", "ServingBowlModel_Preview", Vector3(5.8, 1.42, 4.6), Vector3(8, 180, 0), 0.22, preview)
	_add_model_to("res://assets/models/delivery_container.fbx", "DeliveryContainerModel_Preview", Vector3(5.8, 1.42, 4.6), Vector3(0, 180, 0), 0.15, preview)

func _apply_spice_level_3_material(root: Node) -> void:
	if not is_instance_valid(root):
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.albedo_texture = load("res://assets/models/spice_level_3.png") as Texture2D
	material.metallic = 1.0
	material.roughness = 1.0
	var normal_texture := load("res://assets/models/spice_level_3_normal.png") as Texture2D
	if normal_texture:
		material.normal_enabled = true
		material.normal_texture = normal_texture
	var metallic_texture := load("res://assets/models/spice_level_3_metallic.png") as Texture2D
	if metallic_texture:
		material.metallic_texture = metallic_texture
	var roughness_texture := load("res://assets/models/spice_level_3_roughness.png") as Texture2D
	if roughness_texture:
		material.roughness_texture = roughness_texture
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance:
			mesh_instance.material_overlay = material

func _add_preview_cylinder(node_name: String, position: Vector3, radius: float, height: float, color: Color) -> void:
	var existing := get_node_or_null(node_name) as MeshInstance3D
	if is_instance_valid(existing):
		existing.visible = Engine.is_editor_hint()
		existing.position = position
		if existing.mesh is CylinderMesh:
			var existing_shape := (existing.mesh as CylinderMesh).duplicate() as CylinderMesh
			existing_shape.top_radius = radius
			existing_shape.bottom_radius = radius
			existing_shape.height = height
			existing.mesh = existing_shape
		var existing_material := existing.material_override as StandardMaterial3D
		if is_instance_valid(existing_material):
			existing_material.albedo_color = color
		return
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	mesh.mesh = shape
	mesh.position = position
	mesh.visible = Engine.is_editor_hint()
	mesh.set_meta("editor_only_preview", true)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	add_child(mesh)
	mesh.owner = self

func _add_model_to(path: String, node_name: String, position: Vector3, rotation: Vector3, scale_value: float, parent: Node3D) -> void:
	if parent.get_node_or_null(node_name) != null:
		return
	var resource := load(path) as PackedScene
	if resource == null:
		return
	var model := resource.instantiate() as Node3D
	if model == null:
		return
	model.name = node_name
	model.position = position
	model.rotation_degrees = rotation
	model.scale = Vector3.ONE * scale_value
	parent.add_child(model)
	model.owner = self

func _add_box_to(node_name: String, position: Vector3, size: Vector3, color: Color, parent: Node3D) -> void:
	if parent.get_node_or_null(node_name) != null:
		return
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.position = position
	var material := StandardMaterial3D.new()
	if _is_shell_surface(node_name):
		material = _make_shell_material(node_name)
	else:
		material.albedo_color = color
	mesh.material_override = material
	parent.add_child(mesh)
	mesh.owner = self
