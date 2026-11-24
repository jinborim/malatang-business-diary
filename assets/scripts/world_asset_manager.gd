extends Node

## Creates the reusable kitchen and service models used by WorldManager.
## Material policy remains in main's compatibility callbacks for now; this
## object owns model instantiation and placement only.

var host: Node

func setup(game_host: Node) -> void:
	host = game_host

func _editable(path: String) -> Node3D:
	return host.get_node_or_null(path) as Node3D

func _instantiate(path: String) -> Node3D:
	var resource: Resource = load(path)
	if not resource is PackedScene: return null
	return (resource as PackedScene).instantiate() as Node3D

func add_order_monitor_model() -> void:
	var model:=_editable("EditableModels/OrderMonitorModel")
	if not is_instance_valid(model): model=_editable("OrderMonitorModel")
	if is_instance_valid(model):
		apply_order_monitor_material(model)
		host._add_model_collision(model,"OrderMonitorCollision")
		return
	model=_instantiate("res://assets/models/order_monitor.fbx")
	if not is_instance_valid(model): return
	model.name="OrderMonitorModel"
	model.position=Vector3(6.55,1.48,-6.15)
	model.rotation_degrees=Vector3(0,180,0)
	model.scale=Vector3.ONE*0.48
	host.add_child(model)
	apply_order_monitor_material(model)
	host._add_model_collision(model,"OrderMonitorCollision")

func add_gas_stove_model(world_position: Vector3, model_scale: float=0.72) -> void:
	var model:=_editable("EditableModels/CommercialGasStoveModel")
	if is_instance_valid(model):
		apply_gas_stove_material(model)
		host._add_model_collision(model,"GasStoveCollision")
		return
	model=_instantiate("res://assets/models/gas_stove.fbx")
	if not is_instance_valid(model): return
	model.name="CommercialGasStoveModel"
	model.position=world_position
	model.rotation_degrees=Vector3(0,180,0)
	model.scale=Vector3.ONE*model_scale
	host.add_child(model)
	apply_gas_stove_material(model)
	host._add_model_collision(model,"GasStoveCollision")

func add_sink_model(world_position: Vector3, model_scale: float=0.72) -> Node3D:
	var model:=_editable("EditableModels/KitchenSinkModel_EditorPreview")
	if not is_instance_valid(model): model=_editable("EditableModels/KitchenSinkModel")
	if is_instance_valid(model):
		apply_sink_material(model)
		host._add_model_collision(model,"SinkCollision")
		return model
	model=_instantiate("res://assets/models/sink/sink.fbx")
	if not is_instance_valid(model): return null
	model.name="KitchenSinkModel"
	model.position=world_position
	model.rotation_degrees=Vector3(0,180,0)
	model.scale=Vector3.ONE*model_scale
	host.add_child(model)
	apply_sink_material(model)
	host._add_model_collision(model,"SinkCollision")
	return model

func add_broth_pot_model(world_position: Vector3, model_scale: float=0.62) -> Node3D:
	var model:=_editable("EditableModels/BrothPotModel_EditorPreview")
	if is_instance_valid(model):
		_prepare_placeable(model)
		apply_broth_pot_material(model)
		host._add_model_collision(model,"BrothPotCollision")
		return model
	model=_instantiate("res://assets/models/broth_pot/broth_pot.fbx")
	if not is_instance_valid(model): return null
	model.name="BrothPotModel"
	model.position=world_position
	model.rotation_degrees=Vector3(0,180,0)
	model.scale=Vector3.ONE*model_scale
	host.add_child(model)
	_prepare_placeable(model)
	apply_broth_pot_material(model)
	return model

func add_broth_stock_model(path: String, node_name: String, world_position: Vector3, model_scale: float) -> Node3D:
	var model:=_instantiate(path)
	if not is_instance_valid(model): return null
	model.name=node_name
	model.position=world_position
	model.rotation_degrees=Vector3.ZERO
	model.scale=Vector3.ONE*model_scale
	host.add_child(model)
	return model

func add_malatang_pot_model(world_position: Vector3) -> Node3D:
	var model:=_editable("EditableModels/MalatangCookingPotModel")
	if is_instance_valid(model):
		_prepare_placeable(model)
		apply_malatang_pot_material(model)
		host._add_model_collision(model,"MalatangPotCollision")
		return model
	model=_instantiate("res://assets/models/malatang_pot.fbx")
	if not is_instance_valid(model): return Node3D.new()
	model.name="MalatangCookingPotModel"
	model.position=world_position
	model.rotation_degrees=Vector3(0,180,0)
	model.scale=Vector3.ONE*0.62
	host.add_child(model)
	_prepare_placeable(model)
	apply_malatang_pot_material(model)
	host._add_model_collision(model,"MalatangPotCollision")
	return model

func _prepare_placeable(model: Node3D) -> void:
	model.add_to_group("placeable_object")
	model.set_meta("place_radius",0.72)

func apply_order_monitor_material(root: Node) -> void:
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color.WHITE
	var color_texture:=load("res://assets/models/order_monitor.png") as Texture2D
	if color_texture: material.albedo_texture=color_texture
	var normal_texture:=load("res://assets/models/order_monitor_normal.png") as Texture2D
	if normal_texture:
		material.normal_enabled=true
		material.normal_texture=normal_texture
	var metallic_texture:=load("res://assets/models/order_monitor_metallic.png") as Texture2D
	if metallic_texture:
		material.metallic=1.0
		material.metallic_texture=metallic_texture
	var roughness_texture:=load("res://assets/models/order_monitor_roughness.png") as Texture2D
	if roughness_texture:
		material.roughness=1.0
		material.roughness_texture=roughness_texture
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_overlay=material


func apply_malatang_pot_material(root: Node) -> void:
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color.WHITE
	var color_texture:=load("res://assets/models/malatang_pot.png") as Texture2D
	if color_texture: material.albedo_texture=color_texture
	var normal_texture:=load("res://assets/models/malatang_pot_normal.png") as Texture2D
	if normal_texture:
		material.normal_enabled=true
		material.normal_texture=normal_texture
	var metallic_texture:=load("res://assets/models/malatang_pot_metallic.png") as Texture2D
	if metallic_texture:
		material.metallic=1.0
		material.metallic_texture=metallic_texture
	var roughness_texture:=load("res://assets/models/malatang_pot_roughness.png") as Texture2D
	if roughness_texture:
		material.roughness=1.0
		material.roughness_texture=roughness_texture
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_overlay=material


func apply_broth_pot_material(pot: Node) -> void:
	if not is_instance_valid(pot): return
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color.WHITE
	material.albedo_texture=load("res://assets/models/broth_pot/broth_pot.png") as Texture2D
	material.metallic=0.55
	material.roughness=0.3
	var normal_texture:=load("res://assets/models/broth_pot/broth_pot_normal.png") as Texture2D
	if normal_texture:
		material.normal_enabled=true
		material.normal_texture=normal_texture
	var metallic_texture:=load("res://assets/models/broth_pot/broth_pot_metallic.png") as Texture2D
	if metallic_texture: material.metallic_texture=metallic_texture
	var roughness_texture:=load("res://assets/models/broth_pot/broth_pot_roughness.png") as Texture2D
	if roughness_texture: material.roughness_texture=roughness_texture
	for child in pot.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_overlay=material


func apply_sink_material(root: Node) -> void:
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color.WHITE
	material.albedo_texture=load("res://assets/models/sink/sink.png") as Texture2D
	material.metallic=0.5
	material.roughness=0.32
	var normal_texture:=load("res://assets/models/sink/sink_normal.png") as Texture2D
	if normal_texture:
		material.normal_enabled=true
		material.normal_texture=normal_texture
	var metallic_texture:=load("res://assets/models/sink/sink_metallic.png") as Texture2D
	if metallic_texture: material.metallic_texture=metallic_texture
	var roughness_texture:=load("res://assets/models/sink/sink_roughness.png") as Texture2D
	if roughness_texture: material.roughness_texture=roughness_texture
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_overlay=material


func apply_gas_stove_material(root: Node) -> void:
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color.WHITE
	# Keep stainless steel readable in the small kitchen even without a strong
	# reflection environment: slightly less metallic and rough than the raw FBX.
	material.metallic=0.48
	material.roughness=0.32
	var color_texture:=load("res://assets/models/gas_stove.png") as Texture2D
	if color_texture: material.albedo_texture=color_texture
	var normal_texture:=load("res://assets/models/gas_stove_normal.png") as Texture2D
	if normal_texture:
		material.normal_enabled=true
		material.normal_texture=normal_texture
	var metallic_texture:=load("res://assets/models/gas_stove_metallic.png") as Texture2D
	if metallic_texture:
		material.metallic=0.48
		material.metallic_texture=metallic_texture
	var roughness_texture:=load("res://assets/models/gas_stove_roughness.png") as Texture2D
	if roughness_texture:
		material.roughness=0.32
		material.roughness_texture=roughness_texture
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_overlay=material

func instantiate_serving_bowl() -> Node3D:
	var resource: Resource=load("res://assets/models/serving_bowl.fbx")
	if not resource is PackedScene: return null
	var model:Node3D=(resource as PackedScene).instantiate() as Node3D
	apply_serving_bowl_material(model)
	return model

func add_world_serving_bowl(world_position: Vector3) -> Node3D:
	var model:=instantiate_serving_bowl()
	if not is_instance_valid(model): return null
	model.name="PlacedServingBowl"
	model.position=world_position
	model.rotation_degrees=Vector3.ZERO
	model.scale=Vector3.ONE*0.22
	host.add_child(model)
	return model

func create_food_tray_visual(tray_name: String) -> Node3D:
	var tray:=Node3D.new()
	tray.name=tray_name
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color("#6f4b35")
	material.roughness=0.72
	var add_part:=func(part_name: String, part_position: Vector3, part_size: Vector3) -> void:
		var mesh_instance:=MeshInstance3D.new()
		mesh_instance.name=part_name
		var mesh:=BoxMesh.new()
		mesh.size=part_size
		mesh_instance.mesh=mesh
		mesh_instance.material_override=material
		mesh_instance.position=part_position
		tray.add_child(mesh_instance)
	add_part.call("TrayBase",Vector3(0,0,0),Vector3(1.10,0.07,0.78))
	add_part.call("TrayFrontRim",Vector3(0,0.09,0.37),Vector3(1.10,0.16,0.07))
	add_part.call("TrayBackRim",Vector3(0,0.09,-0.37),Vector3(1.10,0.16,0.07))
	add_part.call("TrayLeftRim",Vector3(-0.52,0.09,0),Vector3(0.07,0.16,0.70))
	add_part.call("TrayRightRim",Vector3(0.52,0.09,0),Vector3(0.07,0.16,0.70))
	return tray

func add_world_food_tray(world_position: Vector3) -> Node3D:
	var tray:=create_food_tray_visual("PlacedFoodTray")
	tray.global_position=world_position-Vector3(0,0.10,0)
	host.add_child(tray)
	return tray

func apply_serving_bowl_material(root: Node) -> void:
	_apply_textured_material(root,"res://assets/models/serving_bowl.png","res://assets/models/serving_bowl_normal.png","res://assets/models/serving_bowl_metallic.png","res://assets/models/serving_bowl_roughness.png")

func instantiate_delivery_container() -> Node3D:
	var resource: Resource=load("res://assets/models/delivery_container.fbx")
	if not resource is PackedScene: return null
	var model:Node3D=(resource as PackedScene).instantiate() as Node3D
	apply_delivery_container_material(model)
	return model

func apply_delivery_container_material(root: Node) -> void:
	_apply_textured_material(root,"res://assets/models/delivery_container_albedo.png","res://assets/models/delivery_container_normal.png","res://assets/models/delivery_container_metallic.png","res://assets/models/delivery_container_roughness.png")

func _apply_textured_material(root: Node, color_path: String, normal_path: String, metallic_path: String, roughness_path: String) -> void:
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color.WHITE
	var color_texture:=load(color_path) as Texture2D
	if color_texture: material.albedo_texture=color_texture
	var normal_texture:=load(normal_path) as Texture2D
	if normal_texture:
		material.normal_enabled=true
		material.normal_texture=normal_texture
	var metallic_texture:=load(metallic_path) as Texture2D
	if metallic_texture:
		material.metallic=1.0
		material.metallic_texture=metallic_texture
	var roughness_texture:=load(roughness_path) as Texture2D
	if roughness_texture:
		material.roughness=1.0
		material.roughness_texture=roughness_texture
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_overlay=material

func add_child_customer_model(customer: Node3D) -> bool:
	var resource: Resource=load("res://assets/models/child_customer/child_customer.fbx")
	if not resource is PackedScene: return false
	var model:Node3D=(resource as PackedScene).instantiate() as Node3D
	model.name="ChildCustomerModel"
	model.position=Vector3(0,-0.85,0)
	model.rotation_degrees=Vector3(0,180,0)
	model.scale=Vector3.ONE*1.08
	customer.add_child(model)
	apply_child_customer_material(model)
	import_child_sit_animation(model)
	import_child_eating_animation(model)
	var seated_resource:Resource=load("res://assets/models/child_customer/seated_pose.fbx")
	if seated_resource is PackedScene:
		var seated:Node3D=(seated_resource as PackedScene).instantiate() as Node3D
		seated.name="SeatedChildCustomerModel"
		seated.position=Vector3(0,-1.30,-0.08)
		seated.rotation_degrees=Vector3(0,180,0)
		seated.scale=Vector3.ONE*1.08
		seated.visible=false
		customer.add_child(seated)
		apply_child_customer_material(seated)
	return true

func import_child_sit_animation(model: Node3D) -> void:
	_import_child_animation(model,"res://assets/models/child_customer/seated_animation.fbx","StandToSit",["sit","stand"])

func import_child_eating_animation(model: Node3D) -> void:
	_import_child_animation(model,"res://assets/models/child_customer/customer_eating_animation.fbx","Eat",["eat","food"],true)

func _import_child_animation(model: Node3D, path: String, animation_name: String, keywords: Array, looped:=false) -> void:
	var resource:Resource=load(path)
	if not resource is PackedScene: return
	var scene:Node3D=(resource as PackedScene).instantiate() as Node3D
	var source:AnimationPlayer=host._find_animation_player(scene)
	var target:AnimationPlayer=host._find_animation_player(model)
	if not source or not target:
		scene.free()
		return
	var library:AnimationLibrary=target.get_animation_library("")
	if not library:
		library=AnimationLibrary.new()
		target.add_animation_library("",library)
	var selected:Animation
	for animation in source.get_animation_list():
		var lowered:=String(animation).to_lower()
		if lowered=="reset" or lowered.ends_with("/reset"): continue
		var clip:Animation=source.get_animation(animation)
		for keyword in keywords:
			if clip and (selected==null or lowered.contains(str(keyword))): selected=clip
	if selected:
		if library.has_animation(animation_name): library.remove_animation(animation_name)
		var clip:Animation=selected.duplicate()
		if looped: clip.loop_mode=Animation.LOOP_LINEAR
		library.add_animation(animation_name,clip)
	scene.free()

func apply_child_customer_material(root: Node) -> void:
	_apply_textured_material(root,"res://assets/models/child_customer/child_customer.png","res://assets/models/child_customer/child_customer_normal.png","res://assets/models/child_customer/child_customer_metallic.png","res://assets/models/child_customer/child_customer_roughness.png")

func add_customer_spoon(customer: Node3D) -> void:
	var resource:Resource=load("res://assets/models/spoon.fbx")
	if not resource is PackedScene: return
	var spoon:Node3D=(resource as PackedScene).instantiate() as Node3D
	spoon.name="CustomerSpoon"
	spoon.position=Vector3(0.18,0.62,-0.30)
	spoon.rotation_degrees=Vector3(90,0,0)
	spoon.scale=Vector3.ONE*0.075
	spoon.visible=false
	customer.add_child(spoon)
	apply_spoon_material(spoon)

func apply_spoon_material(root: Node) -> void:
	_apply_textured_material(root,"res://assets/models/spoon.png","res://assets/models/spoon_normal.png","res://assets/models/spoon_metallic.png","res://assets/models/spoon_roughness.png")

func add_stainless_table_model(world_position: Vector3) -> Node3D:
	var model:=_editable("EditableModels/StainlessPrepTableModel")
	if is_instance_valid(model):
		apply_stainless_table_material(model)
		host._add_model_collision(model,"PrepTableCollision")
		return model
	model=_instantiate("res://assets/models/stainless_table.fbx")
	if not is_instance_valid(model): return null
	model.name="StainlessPrepTableModel"
	model.position=world_position
	model.rotation_degrees=Vector3.ZERO
	model.scale=Vector3(1.18,0.92,0.98)
	host.add_child(model)
	apply_stainless_table_material(model)
	host._add_model_collision(model,"PrepTableCollision")
	return model

func apply_stainless_table_material(root: Node) -> void:
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color.WHITE
	material.metallic=0.48
	material.roughness=0.32
	var color_texture:=load("res://assets/models/stainless_table.png") as Texture2D
	if color_texture: material.albedo_texture=color_texture
	var normal_texture:=load("res://assets/models/stainless_table_normal.png") as Texture2D
	if normal_texture:
		material.normal_enabled=true
		material.normal_texture=normal_texture
	var metallic_texture:=load("res://assets/models/stainless_table_metallic.png") as Texture2D
	if metallic_texture: material.metallic_texture=metallic_texture
	var roughness_texture:=load("res://assets/models/stainless_table_roughness.png") as Texture2D
	if roughness_texture: material.roughness_texture=roughness_texture
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_overlay=material

func add_spice_level_3_model(world_position: Vector3) -> Node3D:
	var model:=_editable("EditableModels/SpiceLevel3Editable")
	if is_instance_valid(model):
		apply_spice_level_material(model)
		return model
	model=_instantiate("res://assets/models/spice_level_3.fbx")
	if not is_instance_valid(model): return Node3D.new()
	model.name="SpiceLevel3Model"
	model.position=world_position
	model.rotation_degrees=Vector3(0,180,0)
	model.scale=Vector3.ONE*0.30
	host.add_child(model)
	apply_spice_level_material(model)
	return model

func apply_spice_level_material(root: Node) -> void:
	_apply_textured_material(root,"res://assets/models/spice_level_3.png","res://assets/models/spice_level_3_normal.png","res://assets/models/spice_level_3_metallic.png","res://assets/models/spice_level_3_roughness.png")

