extends Node

# ????嫄??????????????⑥ル럯????????怨룸돱???????????????汝뷴젆??녷뉩??읂???????щ쇀????????????????關?쒎첎?嫄??怨몃룯??????????꿔꺂??????
var host

func setup(game_host) -> void:
	host=game_host

func remove_obsolete_kitchen_sight_barriers() -> void:
	for node_name in ["KitchenSightBlockLeft", "KitchenSightBlockRight", "KitchenSightHeader", "DeliveryOnlyPrivacyScreen", "PickupPartition"]:
		var node := host.get_node_or_null("EditableModels/%s" % node_name) as Node3D
		if not is_instance_valid(node): node = host.get_node_or_null(node_name) as Node3D
		if not is_instance_valid(node): continue
		node.visible = false
		for child in node.find_children("*", "StaticBody3D", true, false):
			var body := child as StaticBody3D
			if is_instance_valid(body):
				body.collision_layer = 0
				body.collision_mask = 0

func make_material(color: Color, emission:=Color.BLACK) -> StandardMaterial3D:
	var material:=StandardMaterial3D.new()
	material.albedo_color=color
	if emission!=Color.BLACK:
		material.emission_enabled=true
		material.emission=emission
	return material

func register_interactable(node: Node3D, label: String) -> void:
	if not is_instance_valid(node): return
	node.set_meta("interaction",label)
	if not node.is_in_group("interactable"): node.add_to_group("interactable")

func register_interaction_data(node: Node3D, interaction_type: String, value: Variant=null) -> void:
	if not is_instance_valid(node): return
	node.set_meta("interaction_type",interaction_type)
	node.set_meta("interaction_value",value)

func make_box(node_name: String, pos: Vector3, size: Vector3, color: Color, parent: Node, collision:=true) -> MeshInstance3D:
	var obsolete_sight_barrier := node_name in ["KitchenSightBlockLeft", "KitchenSightBlockRight", "KitchenSightHeader", "DeliveryOnlyPrivacyScreen", "PickupPartition"]
	var existing:=parent.get_node_or_null(node_name) as MeshInstance3D
	if not existing and parent==host:
		var layout:Node=host.get_node_or_null("EditableModels")
		if layout: existing=layout.get_node_or_null(node_name) as MeshInstance3D
	if is_instance_valid(existing):
		if obsolete_sight_barrier:
			existing.visible = false
			var old_body := existing.get_node_or_null("StaticBody3D") as StaticBody3D
			if is_instance_valid(old_body):
				old_body.collision_layer = 0
				old_body.collision_mask = 0
			return existing
		if existing.mesh is BoxMesh:
			var resized_mesh:BoxMesh=(existing.mesh as BoxMesh).duplicate()
			resized_mesh.size=size
			existing.mesh=resized_mesh
		if is_shell_surface(node_name): existing.material_override=textured_material(node_name)
		if collision and not existing.get_node_or_null("StaticBody3D"):
			var body:=StaticBody3D.new(); body.name="StaticBody3D"; existing.add_child(body)
			var shape_node:=CollisionShape3D.new(); shape_node.name="CollisionShape3D"
			var box_shape:=BoxShape3D.new(); box_shape.size=size; shape_node.shape=box_shape
			body.add_child(shape_node)
		return existing
	var mesh:=MeshInstance3D.new(); mesh.name=node_name
	var box_mesh:=BoxMesh.new(); box_mesh.size=size; mesh.mesh=box_mesh; mesh.position=pos
	mesh.material_override=textured_material(node_name) if is_shell_surface(node_name) else make_material(color)
	parent.add_child(mesh)
	if obsolete_sight_barrier:
		mesh.visible = false
		return mesh
	if collision:
		var body:=StaticBody3D.new(); mesh.add_child(body)
		var shape_node:=CollisionShape3D.new(); var box_shape:=BoxShape3D.new(); box_shape.size=size; shape_node.shape=box_shape; body.add_child(shape_node)
	return mesh

func make_cylinder(node_name: String, pos: Vector3, radius: float, height: float, color: Color, parent: Node, collision:=true) -> MeshInstance3D:
	var existing:=parent.get_node_or_null(node_name) as MeshInstance3D
	if not existing and parent==host:
		var layout:Node=host.get_node_or_null("EditableModels")
		if layout: existing=layout.get_node_or_null(node_name) as MeshInstance3D
	if is_instance_valid(existing): return existing
	var mesh:=MeshInstance3D.new(); mesh.name=node_name
	var cylinder_mesh:=CylinderMesh.new(); cylinder_mesh.top_radius=radius; cylinder_mesh.bottom_radius=radius; cylinder_mesh.height=height
	mesh.mesh=cylinder_mesh; mesh.position=pos; mesh.material_override=make_material(color); parent.add_child(mesh)
	if collision:
		var body:=StaticBody3D.new(); mesh.add_child(body)
		var shape_node:=CollisionShape3D.new(); var cylinder_shape:=CylinderShape3D.new(); cylinder_shape.radius=radius; cylinder_shape.height=height; shape_node.shape=cylinder_shape; body.add_child(shape_node)
	return mesh

func add_model_collision(root: Node3D, collision_name: String = "WorldCollision") -> void:
	if not is_instance_valid(root) or root.get_node_or_null(collision_name) != null: return
	var bounds:=AABB()
	var has_bounds:=false
	var root_inverse:=root.global_transform.affine_inverse()
	var mesh_nodes:Array[MeshInstance3D]=[]
	if root is MeshInstance3D: mesh_nodes.append(root as MeshInstance3D)
	for child in root.find_children("*","MeshInstance3D",true,false): mesh_nodes.append(child as MeshInstance3D)
	for mesh_instance in mesh_nodes:
		if not is_instance_valid(mesh_instance) or not is_instance_valid(mesh_instance.mesh): continue
		var mesh_to_root:=root_inverse * mesh_instance.global_transform
		var mesh_bounds:=mesh_instance.get_aabb()
		for corner_index in 8:
			var corner:=mesh_bounds.position+Vector3(mesh_bounds.size.x if (corner_index&1)!=0 else 0.0,mesh_bounds.size.y if (corner_index&2)!=0 else 0.0,mesh_bounds.size.z if (corner_index&4)!=0 else 0.0)
			var point:=mesh_to_root*corner
			if not has_bounds: bounds=AABB(point,Vector3.ZERO); has_bounds=true
			else: bounds=bounds.expand(point)
	if not has_bounds or bounds.size.length_squared()<0.0001: return
	if collision_name=="PrepTableCollision":
		var tabletop_height:=minf(bounds.size.y*0.15,0.18)
		bounds.position.y+=bounds.size.y-tabletop_height; bounds.size.y=tabletop_height
	var body:=StaticBody3D.new(); body.name=collision_name; body.collision_layer=1; body.collision_mask=1; root.add_child(body)
	var collision:=CollisionShape3D.new(); var shape:=BoxShape3D.new(); shape.size=bounds.size; collision.shape=shape; collision.position=bounds.position+bounds.size*0.5; body.add_child(collision)

func is_shell_surface(surface_name: String) -> bool:
	return surface_name == "Floor" or surface_name == "BackWall" or surface_name == "LeftWall" or surface_name == "RightWall" or surface_name == "FrontWallLeft" or surface_name == "FrontWallRight" or surface_name == "Ceiling" or surface_name == "KitchenCounter" or surface_name == "BrothStation"

const DINING_WALLPAPER_PATH := "res://assets/textures/dining_wallpaper_red_gold.png"

func dining_wallpaper_material() -> StandardMaterial3D:
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

func add_dining_wallpaper_panels(front_z: float) -> void:
	if host.store_stage < 2: return
	var dining_start_z := -1.0
	var dining_center_z := (dining_start_z + front_z) * 0.5
	var dining_length := front_z - dining_start_z
	for panel_data in [["DiningWallpaperLeft", Vector3(-8.86, 2.5, dining_center_z), Vector3(0.08, 4.7, dining_length)], ["DiningWallpaperRight", Vector3(8.86, 2.5, dining_center_z), Vector3(0.08, 4.7, dining_length)]]:
		var panel := host.get_node_or_null(str(panel_data[0])) as MeshInstance3D
		if not is_instance_valid(panel):
			panel = host.box(str(panel_data[0]), panel_data[1], panel_data[2], Color("8f1f1c"), host, false)
		panel.material_override = dining_wallpaper_material()

func add_open_kitchen_pass_counter() -> void:
	if host.store_stage < 2: return
	var counter: MeshInstance3D = host.box("OpenKitchenPassCounter", Vector3(1.3, 0.68, -3.6), Vector3(5.2, 1.35, 0.8), Color("3b2924"), host, false)
	if is_instance_valid(counter):
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("3b2924")
		material.roughness = 0.72
		counter.material_override = material

func add_stage1_interior_model() -> void:
	var resource: Resource=load("res://assets/models/stage1_interior.glb")
	if not resource is PackedScene: return
	var interior: Node3D=(resource as PackedScene).instantiate() as Node3D
	if not is_instance_valid(interior): return
	interior.name="Stage1BlenderInterior"
	host.add_child(interior)
	for shell_name in ["Floor","BackWall","LeftWall","RightWall","FrontWallLeft","FrontWallRight","Ceiling"]:
		var shell:=host.get_node_or_null("EditableModels/%s"%shell_name) as MeshInstance3D
		if not shell: shell=host.get_node_or_null(shell_name) as MeshInstance3D
		if is_instance_valid(shell): shell.visible=false

func shell_texture(surface_name: String) -> Texture2D:
	if surface_name == "Ceiling": return load("res://assets/textures/ceiling_panel.png") as Texture2D
	var path: String = host.STAGE1_WALL_TILES_PATH
	if surface_name == "Floor": path = host.STAGE1_FLOOR_TILES_PATH
	elif surface_name == "BackWall": path = host.STAGE1_WALL_TILES_PATH
	elif surface_name == "KitchenCounter" or surface_name == "BrothStation": path = host.STAGE1_STAINLESS_PATH
	return load(path) as Texture2D

func shell_fallback_color(surface_name: String) -> Color:
	if surface_name == "Floor": return Color("#4b5054")
	if surface_name == "KitchenCounter" or surface_name == "BrothStation": return Color("#c7c4bd")
	if surface_name == "Ceiling": return Color("#f4f0e8")
	return Color("#eee8dc")

func textured_material(surface_name: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var texture := shell_texture(surface_name)
	if is_instance_valid(texture): material.albedo_texture=texture; material.albedo_color=Color.WHITE
	else: material.albedo_color=shell_fallback_color(surface_name)
	material.roughness=0.78
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if surface_name == "Floor": material.uv1_scale=Vector3(6.0,6.0,1.0)
	elif surface_name == "Ceiling": material.uv1_scale=Vector3(3.0,3.0,1.0)
	elif surface_name != "KitchenCounter" and surface_name != "BrothStation": material.uv1_scale=Vector3(6.0,2.0,1.0)
	return material
func build_world() -> void:
	var env := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color("#c8d5df")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color.WHITE; e.ambient_light_energy = 0.65
	env.environment = e; host.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-55,-30,0); sun.shadow_enabled = true; sun.light_energy = 1.0; host.add_child(sun)
	# Stage 1 is a delivery-only kitchen: keep only the kitchen, order monitor,
	# courier waiting area, and the entrance instead of reserving dining space.
	var delivery_only_map: bool = host.store_stage == 1
	# ?????????嚥싲갭큔?댁옃紐?????諛몃마??store_stage_1.tscn)????????? ??????ㅻ쿋???????ㅻ깹????????꿔꺂??????
	# 1??傭?끆???????轝?癰궽븐숯??????쇰뮛??????????댄뱼嚥??????????????? ???癲?????Z=-12??????????????? ?????嚥싲갭큔?댁옃紐?????猷멸컼?????????놁졄.
	var room_depth := 18.0
	var room_center_z := -0.5
	var front_z := 8.05
	var back_wall_z := -9.0
	var floor_surface: MeshInstance3D = host.box("Floor", Vector3(0,-0.15,room_center_z), Vector3(18,0.3,room_depth), Color("#4b5054"))
	# ????썹땟戮녹???????????ル뒇????????????????????????????썹땟戮녹???????꿔꺂??씙????????????????꿔꺂??????
	floor_surface.set_meta("place_surface_y",0.0)
	floor_surface.set_meta("place_half_extents",Vector2(8.65,8.65))
	floor_surface.set_meta("place_offset_y",0.02)
	host.interactable(floor_surface,"Place items here")
	host.interaction_data(floor_surface,"place_surface")
	# Keep a dedicated, invisible floor collider independent from the editable
	# visual floor. This prevents a saved scene without a StaticBody3D (or a
	# moved visual floor) from making the player fall through the kitchen.
	var floor_safety: MeshInstance3D = host.box("WorldFloorSafetyCollision",Vector3(0,-0.42,room_center_z),Vector3(18,0.5,room_depth),Color("#4b5054"),host,true)
	floor_safety.visible=false
	host.box("BackWall", Vector3(0,2.5,back_wall_z), Vector3(18,5,0.25), Color("#eee8dc"))
	host.box("LeftWall", Vector3(-9,2.5,room_center_z), Vector3(0.25,5,room_depth), Color("#eee8dc"))
	host.box("RightWall", Vector3(9,2.5,room_center_z), Vector3(0.25,5,room_depth), Color("#eee8dc"))
	# Enclose the storefront while keeping one shared entrance for customers and couriers.
	host.box("FrontWallLeft",Vector3(-2.0,2.5,front_z),Vector3(14.0,5.0,0.25),Color("#eee8dc"))
	host.box("FrontWallRight",Vector3(8.35,2.5,front_z),Vector3(1.3,5.0,0.25),Color("#eee8dc"))
	add_dining_wallpaper_panels(front_z)
	add_open_kitchen_pass_counter()
	if delivery_only_map:
		var delivery_privacy_screen:MeshInstance3D=host.box("DeliveryOnlyPrivacyScreen",Vector3(6.35,2.5,7.62),Vector3(2.35,5.0,0.12),Color(0.88,0.86,0.80,0.96),host,false)
		delivery_privacy_screen.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	host.box("Ceiling", Vector3(0,5.4,room_center_z), Vector3(18,0.25,room_depth), Color("#f4f0e8"), host, false)
	# ????????????????썹땟戮녹???????????좊틣??????????꿔꺂?????? ????쇰뮛?????Blender ??轅붽틓??筌뚮챶夷????붺댆???紐꾩젢????鶯ㅼ룇??껊븸?	# ???????? ??????????????댄뱼??????????????? ???????諛몃마????꾤뙳???轅붽틓????볥??????ル늉?? ?????????????
	var ceiling_light:=OmniLight3D.new(); ceiling_light.name="CeilingLight"; ceiling_light.position=Vector3(0,4.8,-4.0 if delivery_only_map else 0.5); ceiling_light.light_color=Color("#fff4dc"); ceiling_light.light_energy=2.0; ceiling_light.omni_range=15.0; host.add_child(ceiling_light)
	var kitchen_light:=OmniLight3D.new(); kitchen_light.name="KitchenCeilingLight"; kitchen_light.position=Vector3(0,4.6,-5.0); kitchen_light.light_color=Color("#fff8e8"); kitchen_light.light_energy=1.6; kitchen_light.omni_range=9.0; host.add_child(kitchen_light)
	var stand:=host.get_node_or_null("IngredientShowcase_Editable") as Node3D
	if not stand: stand=host.get_node_or_null("EditableModels/IngredientShowcase_Editable") as Node3D
	if not stand:
		stand=Node3D.new(); stand.name="IngredientShowcase_Editable"; stand.position=Vector3(-5.6,0,-2.3); stand.rotation_degrees.y=180.0; host.add_child(stand)
	host.box("ShowcaseBack", Vector3(0,2.1,0.45), Vector3(5.8,4.2,0.25), Color("#3d4548"), stand)
	for row in 4:
		host.box("Shelf_%d" % row, Vector3(0,0.55 + row*0.95,0), Vector3(5.8,0.12,1.25), Color("#aeb8b8"), stand)
		var divider_resource:=load("res://assets/models/divider/Meshy_AI_칸막이_20261124_texture.fbx")
		if divider_resource is PackedScene:
			for divider_index in 2:
				var divider_model:Node3D=(divider_resource as PackedScene).instantiate() as Node3D
				divider_model.name="IngredientDivider_%d_%d" % [row,divider_index]
				divider_model.position=Vector3(-0.95 + divider_index*1.9,1.02 + row*0.95,-0.05)
				divider_model.rotation_degrees=Vector3.ZERO
				divider_model.scale=Vector3.ONE*0.22
				stand.add_child(divider_model)
				var divider_visual:MeshInstance3D=host.box("IngredientDividerVisual_%d_%d" % [row,divider_index],Vector3(-0.95 + divider_index*1.9,0.98 + row*0.95,-0.05),Vector3(0.08,0.82,1.08),Color(0.76,0.82,0.84,0.82),stand,false)
				divider_visual.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in host.INGREDIENTS.size():
		var col: int = i % 3; var row := floori(float(i) / 3.0)
		var bin: MeshInstance3D = host.box("Bin_%s" % host.INGREDIENTS[i][0], Vector3(-1.9+col*1.9,0.82+row*0.95,-0.1), Vector3(1.55,0.42,0.95), Color(0.55,0.85,0.9,0.55), stand, false)
		bin.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bin.visible=false
		var tray_resource:=load("res://assets/models/tray/Meshy_AI_트레이_20261124_texture.fbx")
		if tray_resource is PackedScene:
			var tray_model:Node3D=(tray_resource as PackedScene).instantiate() as Node3D
			tray_model.name="IngredientTray_%02d" % i
			tray_model.position=bin.position+Vector3(0,0.02,0)
			tray_model.rotation_degrees=Vector3.ZERO
			tray_model.scale=Vector3.ONE*0.50
			stand.add_child(tray_model)
		var basket_resource:=load("res://assets/models/mint_glow_display_case_import/Meshy_AI_Mint_Glow_Display_Case_20261118_texture_fbx/Meshy_AI_Mint_Glow_Display_Case_20261118_texture.fbx")
		if basket_resource is PackedScene:
			var basket_model:Node3D=(basket_resource as PackedScene).instantiate() as Node3D
			basket_model.name="IngredientBasket_%02d" % i
			basket_model.position=bin.position+Vector3(0,0.16,0)
			basket_model.rotation_degrees=Vector3(0,180,0)
			basket_model.scale=Vector3.ONE*0.38
			stand.add_child(basket_model)
		var food_position:=Vector3(-1.9+col*1.9,1.12+row*0.95,-0.12)
		var food: MeshInstance3D = host.cylinder(host.INGREDIENTS[i][0],food_position,0.3,0.28,host.INGREDIENTS[i][1],stand)
		if str(host.INGREDIENTS[i][0])=="\uC219\uC8FC":
			food.visible=false
			var bean_sprouts_model:Node3D=host._add_bean_sprouts_model(stand,food_position)
			food.set_meta("highlight_target",bean_sprouts_model)
		if str(host.INGREDIENTS[i][0])=="\uD478\uC8FC":
			food.visible=false
			var tofu_skin_model:Node3D=host._add_tofu_skin_model(stand,food_position)
			food.set_meta("highlight_target",tofu_skin_model)
		host.interactable(food,str(host.INGREDIENTS[i][0])+" pick up")
		if str(host.INGREDIENTS[i][0])=="\uC0C8\uC6B0\uC644\uC790":
			food.visible=false
			var shrimp_model:Node3D=host._add_shrimp_ball_model(stand,food_position)
			food.set_meta("highlight_target",shrimp_model)
		if str(host.INGREDIENTS[i][0])=="\uC18C\uC2DC\uC9C0":
			food.visible=false
			var sausage_model:Node3D=host._add_sausage_model(stand,food_position)
			food.set_meta("highlight_target",sausage_model)
		if str(host.INGREDIENTS[i][0])=="\uCCAD\uACBD\uCC44":
			food.visible=false
			var bok_choy_model:Node3D=host._add_bok_choy_model(stand,food_position)
			food.set_meta("highlight_target",bok_choy_model)
		if str(host.INGREDIENTS[i][0])=="\uBAA9\uC774\uBC84\uC12F":
			food.visible=false
			var wood_ear_model:Node3D=host._add_wood_ear_model(stand,food_position)
			food.set_meta("highlight_target",wood_ear_model)
		if str(host.INGREDIENTS[i][0])=="\uC911\uAD6D\uB2F9\uBA74":
			food.visible=false
			var glass_noodle_model:Node3D=host._add_glass_noodle_model(stand,food_position)
			food.set_meta("highlight_target",glass_noodle_model)
		if str(host.INGREDIENTS[i][0])=="\uBD84\uBAA8\uC790":
			food.visible=false
			var bunja_model:Node3D=host._add_bunja_model(stand,food_position)
			food.set_meta("highlight_target",bunja_model)
		if str(host.INGREDIENTS[i][0])=="\uAC74\uB450\uBD80":
			food.visible=false
			var gun_dubu_model:Node3D=host._add_gun_dubu_model(stand,food_position)
			food.set_meta("highlight_target",gun_dubu_model)
		if str(host.INGREDIENTS[i][0])=="\uC54C\uBC30\uAE30\uBC30\uCD94":
			food.visible=false
			var albaegi_cabbage_model:Node3D=host._add_albaegi_cabbage_model(stand,food_position)
			food.set_meta("highlight_target",albaegi_cabbage_model)
		if str(host.INGREDIENTS[i][0])=="\uD301\uC774\uBC84\uC12F":
			food.visible=false
			var enoki_model:Node3D=host._add_enoki_model(stand,food_position)
			food.set_meta("highlight_target",enoki_model)
		host.interaction_data(food, "ingredient", host.INGREDIENTS[i][0])
	var cooking_wall_z := -8.5
	# Keep a compact support counter for the host.cooking pot; the prep area is the stainless table beside it.
	var kitchen_counter: MeshInstance3D = host.box("KitchenCounter", Vector3(0.10,0.55,cooking_wall_z), Vector3(4.1,1.1,2.0), Color("#c7c4bd"))
	# The old placeholder counter is a large white host.box that blocks the view.
	kitchen_counter.visible=false
	var kitchen_counter_body:=kitchen_counter.get_node_or_null("StaticBody3D") as StaticBody3D
	if kitchen_counter_body:
		kitchen_counter_body.collision_layer=0
		kitchen_counter_body.collision_mask=0
	var pot_model: Node3D = host._add_malatang_pot_model(host.COOKING_POT_POSITION)
	host.interactable(pot_model,"Cook malatang"); host.interaction_data(pot_model,"pot")
	# ?????諛몃마???饔낅떽????ш낄?뉔뇡????????????饔낅떽????????????????????癲????????몄뿴??? ??傭?끆?????ル벥?????饔낅떽??????????諛몃마??λ????饔낅떽????ш낄?뉔뇡????????????????????⑤슢堉???夷??
	var pot: MeshInstance3D = host.cylinder("CookingPotInteraction",Vector3.ZERO,0.82,0.8,Color("#777d81"),pot_model); pot.visible=false
	host.interactable(pot,"Cook malatang"); host.interaction_data(pot,"pot")
	# ??轅붽틓????獄쏅챸????????⑹름?癲ル슢罹숂땟?⑤뼀????????嚥싲갭큔?源?????????ы깯 ?????櫻????ル늉?? ???嚥싲갭큔野껁렔爾?????븍콅???? ???嚥싲갭큔?源由??????諛몃마嶺뚮??껆빊?????쇰뮛????????썹땟戮녹??諛명꺐???	# ????嫄?彛?????嚥▲굧?먪춯??????????饔낅떽????ш낄?뉔뇡??????꿔꺂???????꿔꺂??????
	var broth_station: MeshInstance3D = host.box("BrothStation",Vector3(-1.25,0.55,cooking_wall_z),Vector3(1.5,1.1,2.0),Color("#aaa9a5"))
	broth_station.visible=false
	var broth_station_body:=broth_station.get_node_or_null("StaticBody3D") as StaticBody3D
	if is_instance_valid(broth_station_body):
		broth_station_body.collision_layer=0
		broth_station_body.collision_mask=0
	host._add_gas_stove_model(host.GAS_STOVE_POSITION,1.55)
	# ??轅붽틓????獄쏅챸????????⑹름?癲ル슢罹숂땟?⑤뼀????????????????????????????믩틲??????壤굿筌뚮벉?? ?????諛몃마???????嚥싲갭큔?源???????諛몃마???????諛몃마??????????????????	# ????⑥ル럯?????饔낅떽????????????깅짆???????얜????????嚥???????⑥ル럯?????????怨뺤떪???????? ????????????놁졄.
	var cooking_flame_position: Vector3 = host.COOKING_POT_POSITION
	if is_instance_valid(pot_model): cooking_flame_position=pot_model.global_position
	host._build_cooking_flame(cooking_flame_position+Vector3(0,-0.48,0))
	var prep_table_model: Node3D = host._add_stainless_table_model(Vector3(3.20,0.55,cooking_wall_z))
	# Invisible placement surface covering the full stainless prep table.
	# The held object is positioned from the host.camera ray, so it can be dropped
	# anywhere on this surface instead of at one fixed marker.
	var prep_table_surface_position:=Vector3(4.6,1.60,cooking_wall_z-0.5)
	if is_instance_valid(prep_table_model):
		# Use the imported model's real upper bound as the tabletop height.  The
		# old fixed +1.05 value was close for one table scale, but made every
		# placed item float when the editable table used a different scale.
		var table_bounds: AABB = host._get_model_world_aabb(prep_table_model)
		if table_bounds.size.y>0.001:
			prep_table_surface_position=Vector3(prep_table_model.global_position.x,table_bounds.position.y+table_bounds.size.y,prep_table_model.global_position.z)
	host.prep_table_place=host.box("PrepTablePlaceSurface",prep_table_surface_position,Vector3(7.0,0.12,1.5),Color("#ffffff"),host,false)
	host.prep_table_place.visible=false
	host.prep_table_place.set_meta("place_half_extents",Vector2(3.50,0.75))
	# host._snap_model_bottom_to_surface already adds a tiny clearance. Do not add
	# the guide host.box's height here, or the object will be visibly above the top.
	host.prep_table_place.set_meta("place_offset_y",0.0)
	host.interactable(host.prep_table_place,"Place ingredients")
	host.interaction_data(host.prep_table_place,"place_surface")
	# ??關?쒎첎?嫄???우뱺????????怨쀫뮡????? ??????딅텑??遺얘탿??????怨룹쾺??????썹땟戮녹???????濡ろ뜐??? ???汝뷴젆????????????쇰뮛?????????????????饔낅떽????????꿔꺂??琉뷩궘??????⑤슢堉???夷??
	var sink_model: Node3D = host._add_sink_model(Vector3(5.55,0.55,cooking_wall_z + 0.35),0.95)
	var sink_anchor: Vector3 = sink_model.global_position if is_instance_valid(sink_model) else Vector3(5.55,0.55,cooking_wall_z + 0.35)
	var sink_tap: MeshInstance3D = host.cylinder("SinkFaucetInteraction",sink_anchor + Vector3(0,1.23,0.10),0.25,0.78,Color("#7f9eac"),host,false)
	host.interactable(sink_tap,"Get water"); host.interaction_data(sink_tap,"sink_water")
	if is_instance_valid(sink_model): sink_tap.set_meta("highlight_target",sink_model)
	# ?????????????????????熬곻퐢夷?嶺?? ????嫄?彛???????쇰뮛???????爰?? ??????밸븶??ㅲ뵛?????濡ろ뜐??? ???嚥싲갭큔?源?????汝뷴젆?????? ???熬곣뫖利당춯???????傭?끆???????떈?????꿔꺂???影?우Ŀ???꿔꺂??????
	sink_tap.visible=false
	var faucet_nozzle:=sink_anchor+Vector3(-0.32,1.42,0.30)
	host.sink_water_stream=host.cylinder("SinkWaterStream",faucet_nozzle-Vector3(0,0.34,0),0.025,0.68,Color("#78c7e8"),host,false)
	var sink_water_material:=StandardMaterial3D.new()
	sink_water_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	sink_water_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	sink_water_material.albedo_color=Color(0.35,0.78,0.92,0.62)
	sink_water_material.roughness=0.12
	host.sink_water_stream.material_override=sink_water_material
	host.sink_water_stream.visible=false
	# ???汝뷴젆??????????????????뗭삪????源녾텛????????ル뒇??????傭?끆???????떈
	host.sink_water_particles=GPUParticles3D.new()
	host.sink_water_particles.name="SinkWaterParticles"
	host.sink_water_particles.amount=36
	host.sink_water_particles.lifetime=0.7
	host.sink_water_particles.preprocess=0.4
	host.sink_water_particles.local_coords=false
	host.sink_water_particles.position=faucet_nozzle
	var water_particle_process:=ParticleProcessMaterial.new()
	water_particle_process.direction=Vector3(0,-1,0)
	water_particle_process.spread=5.0
	water_particle_process.gravity=Vector3(0,-2.2,0)
	water_particle_process.initial_velocity_min=0.35
	water_particle_process.initial_velocity_max=0.65
	water_particle_process.scale_min=0.035
	water_particle_process.scale_max=0.075
	host.sink_water_particles.process_material=water_particle_process
	var water_drop_mesh:=SphereMesh.new()
	water_drop_mesh.radius=0.018
	water_drop_mesh.height=0.036
	var water_drop_material:=StandardMaterial3D.new()
	water_drop_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	water_drop_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	water_drop_material.albedo_color=Color(0.35,0.78,0.92,0.68)
	water_drop_material.roughness=0.08
	water_drop_mesh.material=water_drop_material
	host.sink_water_particles.draw_pass_1=water_drop_mesh
	host.sink_water_particles.visible=false
	host.add_child(host.sink_water_particles)
	host.broth_pot_model=host._add_broth_pot_model(Vector3(-1.25,1.55,cooking_wall_z),0.62)
	if is_instance_valid(host.broth_pot_model): host.broth_pot_home_transform=host.broth_pot_model.global_transform
	host.broth_pot_filled_model=host.get_node_or_null("EditableModels/BrothPotFilled_EditorPreview") as Node3D
	if not is_instance_valid(host.broth_pot_filled_model):
		host.broth_pot_filled_model=host.find_child("BrothPotFilled_EditorPreview",true,false) as Node3D
	if is_instance_valid(host.broth_pot_filled_model):
		host.broth_pot_filled_model.global_transform=host.broth_pot_home_transform
		host.broth_pot_filled_model.visible=false
		host.broth_pot_filled_model.set_meta("highlight_target",host.broth_pot_filled_model)
		host._apply_broth_pot_material(host.broth_pot_filled_model)
		host._add_model_collision(host.broth_pot_filled_model,"BrothPotFilledCollision")
	if is_instance_valid(host.broth_pot_model):
		host.interactable(host.broth_pot_model,"Use broth pot")
		host.interaction_data(host.broth_pot_model,"broth")
		host.broth_pot_model.set_meta("highlight_target",host.broth_pot_model)
	var broth_pot_parent:Node=host.broth_pot_model if is_instance_valid(host.broth_pot_model) else host
	var broth_pot_interaction_position:=Vector3.ZERO if broth_pot_parent==host.broth_pot_model else Vector3(-1.25,1.55,cooking_wall_z)
	host.broth_pot_interaction=host.cylinder("BrothPotInteraction",broth_pot_interaction_position,0.62,0.85,Color("#8d9295"),broth_pot_parent); host.broth_pot_interaction.visible=false; host.interactable(host.broth_pot_interaction,"Use broth pot"); host.interaction_data(host.broth_pot_interaction,"broth")
	if is_instance_valid(host.broth_pot_model): host.broth_pot_interaction.set_meta("highlight_target",host.broth_pot_model)
	host.broth_pot_drop_zone=host.cylinder("BrothPotDropZone",host.broth_pot_home_transform.origin,0.86,0.18,Color("#8d9295"),host,false)
	host.broth_pot_drop_zone.visible=false
	host.broth_pot_drop_zone.set_meta("interaction_disabled",true)
	# No dedicated original-position interaction: use the generic drop action.
	# The pot is released through the generic placement surface, never by a
	# special trigger at its original position.
	if host.broth_base_added: host.broth_pot_interaction.set_meta("interaction","Cook malatang")
	elif host.broth_water_added or host.broth_stock_added: host.broth_pot_interaction.set_meta("interaction","Add ingredients")
	# ?????諛몃마???關???꾨き??熬곥룊???꿔꺂??濾??????ル늉??? ?????댄뱼嚥??????? ???轝꿸섣????饔낅떽??????μ떜媛?슙??븍툖釉?????????Β???饔낅떽?????????????ル뒇????????諛몃마??????썹땟戮녹???????????????? ??????밸븶??ㅲ뵛????꿔꺂??????
	var editable_broth_liquid:=host.get_node_or_null("EditableModels/BrothLiquid_EditorPreview") as MeshInstance3D
	if is_instance_valid(editable_broth_liquid): host.broth_liquid=editable_broth_liquid
	else: host.broth_liquid=host.cylinder("BrothLiquid",Vector3(-1.25,1.90,cooking_wall_z + 0.02),0.34,0.035,Color("#6495aa"),host,false)
	# The liquid belongs to the broth pot. Keeping it as a world-space node
	# makes it float beside the pot and separates it when the pot is carried.
	if is_instance_valid(host.broth_pot_model) and host.broth_liquid.get_parent()!=host.broth_pot_model:
		host.broth_liquid.reparent(host.broth_pot_model)
		host.broth_liquid.position=Vector3(0,0.45,0)
		host.broth_liquid.rotation=Vector3.ZERO
		host.broth_liquid.scale=Vector3(1.65,1.0,1.65)
	host.broth_liquid_base_scale=host.broth_liquid.scale
	host.broth_liquid.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host._update_broth_liquid_visual()
	host._set_broth_pot_filled_visual(host.broth_stock_added or host.broth_base_added or host.broth_servings>0)
	var water_tap:Node3D=host.get_node_or_null("EditableModels/BrothWaterTap_EditorPreview") as Node3D
	if not is_instance_valid(water_tap): water_tap=host.cylinder("BrothWaterTap",Vector3(-1.78,1.55,cooking_wall_z + 0.05),0.16,0.75,Color("#7f9eac"))
	# Legacy water-tap proxy. Water is now received only from the real sink
	# faucet, so this old helper must never be selectable or highlighted.
	water_tap.visible=false
	water_tap.set_meta("interaction_disabled",true)
	water_tap.remove_from_group("interactable")
	water_tap.remove_meta("interaction")
	water_tap.remove_meta("interaction_type")
	var legacy_water_tap:=host.get_node_or_null("EditableModels/BrothWaterTap_EditorPreview") as Node3D
	if is_instance_valid(legacy_water_tap):
		legacy_water_tap.visible=false
		legacy_water_tap.set_meta("interaction_disabled",true)
		legacy_water_tap.remove_from_group("interactable")
		legacy_water_tap.remove_meta("interaction")
		legacy_water_tap.remove_meta("interaction_type")
	host.broth_water_stream=host.cylinder("BrothWaterStream",Vector3(-1.25,1.78,cooking_wall_z),0.045,0.55,Color("#78c7e8"),host,false)
	host.broth_water_stream.visible=false
	# Invisible hit proxy is intentionally a little larger than the imported
	# package so the crosshair can select it from the visual center, not only
	# from a narrow edge of the mesh.
	var broth_stock: MeshInstance3D = host.cylinder("BrothStock",Vector3(-0.72,1.48,cooking_wall_z + 0.05),0.36,0.85,Color("#d7c18a")); host.interactable(broth_stock,"Pick up broth pack"); host.interaction_data(broth_stock,"broth_stock")
	broth_stock.visible=false
	broth_stock.position=Vector3(4.6,1.85,cooking_wall_z-0.5)
	broth_stock.scale=Vector3.ONE*1.3
	var broth_stock_body:=broth_stock.get_node_or_null("StaticBody3D") as StaticBody3D
	if broth_stock_body:
		broth_stock_body.collision_layer=0
		broth_stock_body.collision_mask=0
	var editable_broth_stock:=host.get_node_or_null("EditableModels/BrothStockPack_EditorPreview") as Node3D
	if is_instance_valid(editable_broth_stock): host.broth_stock_model=editable_broth_stock
	else: host.broth_stock_model=host._add_broth_stock_model("res://assets/models/broth_stock/stock_pack.fbx","BrothStockPack",broth_stock.position,0.38)
	host.broth_stock_open_model=host._add_broth_stock_model("res://assets/models/broth_stock/stock_pack_open.fbx","BrothStockPackOpen",broth_stock.position,0.38)
	if is_instance_valid(host.broth_stock_model): broth_stock.global_position=host.broth_stock_model.global_position
	if is_instance_valid(host.broth_stock_model): broth_stock.set_meta("highlight_target",host.broth_stock_model)
	if is_instance_valid(host.broth_stock_model): host.broth_stock_model.visible=host.broth_stock_packs>0
	host._set_broth_stock_source_enabled(host.broth_stock_packs>0)
	if is_instance_valid(host.broth_stock_model):
		host.broth_stock_model.add_to_group("placeable_object")
		host.broth_stock_model.set_meta("place_radius",0.34)
	if is_instance_valid(host.broth_stock_open_model): host.broth_stock_open_model.visible=false
	if is_instance_valid(host.broth_stock_open_model):
		host.broth_stock_open_model.add_to_group("placeable_object")
		host.broth_stock_open_model.set_meta("place_radius",0.34)
		host.broth_stock_open_model.set_meta("broth_stock_open",false)
		host.interactable(host.broth_stock_open_model,"Open broth pack")
		host.interaction_data(host.broth_stock_open_model,"broth_stock")
		host.broth_stock_open_model.set_meta("highlight_target",host.broth_stock_open_model)
		host._add_model_collision(host.broth_stock_open_model,"BrothStockOpenCollision")
		var open_body:=host.broth_stock_open_model.get_node_or_null("BrothStockOpenCollision") as StaticBody3D
		if is_instance_valid(open_body):
			open_body.collision_layer=0
			open_body.collision_mask=0
	# The old mala-base proxy is no longer part of the kitchen interaction flow.
	# Hide and disable any stale scene instance, but never create a replacement proxy.
	var legacy_broth_base:=host.get_node_or_null("EditableModels/BrothBase_EditorPreview") as Node3D
	if is_instance_valid(legacy_broth_base):
		legacy_broth_base.visible=false
		legacy_broth_base.set_meta("interaction_disabled",true)
		legacy_broth_base.remove_from_group("interactable")
		legacy_broth_base.remove_meta("interaction")
		legacy_broth_base.remove_meta("interaction_type")
	host._build_broth_steam(Vector3(-1.25,2.10,cooking_wall_z))
	var broth_base_preview:=host.get_node_or_null("BrothBase") as Node3D
	if is_instance_valid(broth_base_preview):
		broth_base_preview.visible=false
		broth_base_preview.set_meta("interaction_disabled",true)
		broth_base_preview.remove_from_group("interactable")
		broth_base_preview.remove_meta("interaction")
		broth_base_preview.remove_meta("interaction_type")
	host.broth_world_progress_label=Label3D.new()
	host.broth_world_progress_label.name="BrothWorldProgress"
	host.broth_world_progress_label.position=Vector3(-1.15,2.18,cooking_wall_z+0.28)
	host.broth_world_progress_label.font_size=42
	host.broth_world_progress_label.outline_size=8
	host.broth_world_progress_label.modulate=Color("#ffe09a")
	host.broth_world_progress_label.outline_modulate=Color("#3b2415")
	host.broth_world_progress_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	host.broth_world_progress_label.no_depth_test=true
	host.broth_world_progress_label.text=""
	host.broth_world_progress_label.visible=false
	host.add_child(host.broth_world_progress_label)
	for i in 3:
		var sauce:Node3D=host.get_node_or_null("EditableModels/Spice_%d_EditorPreview"%(i+1)) as Node3D
		if i == 2: sauce=host._add_spice_level_3_model(Vector3(2.30+i*0.90,1.78,cooking_wall_z))
		sauce.add_to_group("placeable_object")
		sauce.set_meta("place_radius",0.30)
		if not is_instance_valid(sauce): sauce=host.cylinder("Spice_%d"%(i+1),Vector3(2.30+i*0.90,1.78,cooking_wall_z),0.15,0.42,[Color("#e3c35e"),Color("#c86435"),Color("#a92e27")][i])
		host.interactable(sauce,"Select sauce %d" % (i+1))
		host._add_model_collision(sauce,"SpiceInteractionCollision_%d"%(i+1))
		host.interaction_data(sauce,"spice",i+1)
		if i == 2:
			sauce.visible=true
	# ?饔낅떽????ш낄?뉔뇡????? ????썹땟戮녹?????????諛몃마????
	host.box("MonitorDesk",Vector3(6.55,0.55,-7.25),Vector3(3.0,1.1,1.25),Color("#796a60"))
	host._add_order_monitor_model()
	var monitor: MeshInstance3D = host.box("OrderMonitorInteraction",Vector3(6.55,1.65,-6.35),Vector3(1.9,1.25,0.5),Color(0,0,0,0)); monitor.visible=false; host.interactable(monitor,"Open order monitor"); host.interaction_data(monitor,"monitor")
	var delivery:MeshInstance3D=host.box("DeliveryCounter",Vector3(5.8,0.65,4.6),Vector3(3.5,1.3,1.5),Color("#b5473d")); host.interactable(delivery,"Deliver food"); host.interaction_data(delivery,"delivery")
	host.box("PickupPartition",Vector3(4.2,2.0,5.8),Vector3(0.2,4.0,2.4),Color("#eee8dc"))
	var trash:MeshInstance3D=host.cylinder("TrashCan",Vector3(3.9,0.55,-1.7),0.48,1.1,Color("#4d5960")); host.interactable(trash,"Throw away"); host.interaction_data(trash,"trash")
	# Move the trash can away from the host.cooking and ingredient interaction paths.
	trash.position=Vector3(8.2,0.55,-3.8)
	host._build_tool_pickup_station()
	# Move the bowl/tongs station away from the ingredient showcase.
	var tool_station:=host.get_node_or_null("ToolStation") as Node3D
	if not tool_station: tool_station=host.get_node_or_null("EditableModels/ToolStation") as Node3D
	if tool_station:
		var tool_station_body:=tool_station.get_node_or_null("StaticBody3D") as StaticBody3D
		if tool_station_body:
			tool_station_body.collision_layer=0
			tool_station_body.collision_mask=0
	var tongs_pickup:=host.get_node_or_null("TongsPickup") as Node3D
	if not tongs_pickup:
		tongs_pickup=host.get_node_or_null("EditableModels/TongsPickup") as Node3D
	var bowl_pickup:=host.get_node_or_null("BowlPickup") as Node3D
	if not bowl_pickup:
		bowl_pickup=host.get_node_or_null("EditableModels/BowlPickup") as Node3D
	var editable_tongs_world:=host.get_node_or_null("EditableModels/KitchenTongsPickupModel") as Node3D
	var editable_bowl_world:=host.get_node_or_null("EditableModels/IngredientBowlPickupModel") as Node3D
	# Editable model nodes are the source of truth. Runtime only follows them
	# with the invisible interaction pads; it never resets their transforms.
	if is_instance_valid(host.world_tongs) and is_instance_valid(tongs_pickup):
		if not is_instance_valid(editable_tongs_world):
			host.world_tongs.global_position=tongs_pickup.global_position+Vector3(0,0.12,0)
			tongs_pickup.global_rotation_degrees=host.world_tongs.global_rotation_degrees
		else:
			tongs_pickup.global_position=host.world_tongs.global_position-Vector3(0,0.12,0)
	if is_instance_valid(host.world_bowl) and is_instance_valid(bowl_pickup):
		if not is_instance_valid(editable_bowl_world):
			host.world_bowl.global_position=bowl_pickup.global_position+Vector3(0,0.11,0)
			bowl_pickup.global_rotation_degrees=host.world_bowl.global_rotation_degrees
		else:
			bowl_pickup.global_position=host.world_bowl.global_position-Vector3(0,0.11,0)
	# ?????????????????썹땟戮녹??????????⑹름?癲ル슢罹숂땟?⑤뼀????????????⑥ル럯????????諛몃마??????????? ??????쇰뮛????棺堉?뤃?????? ????????????놁졄.
	var monitor_interaction:=host.get_node_or_null("OrderMonitorInteraction") as Node3D
	var monitor_anchor:=host.get_node_or_null("EditableModels/OrderMonitorModel") as Node3D
	if not monitor_anchor:
		monitor_anchor=host.get_node_or_null("OrderMonitorModel") as Node3D
	if monitor_interaction:
		if monitor_anchor:
			var monitor_basis:=monitor_anchor.global_transform.basis.orthonormalized()
			monitor_interaction.global_position=monitor_anchor.global_position+monitor_basis*Vector3(0,0.17,0.20)
			monitor_interaction.global_rotation=monitor_anchor.global_rotation
		else:
			monitor_interaction.position=Vector3(6.55,1.65,-4.15)
	var delivery_counter:=host.get_node_or_null("DeliveryCounter") as Node3D
	if delivery_counter:
		delivery_counter.visible=false
		var delivery_body:=delivery_counter.get_node_or_null("StaticBody3D") as StaticBody3D
		if delivery_body:
			delivery_body.collision_layer=0
			delivery_body.collision_mask=0
	var pickup_partition:=host.get_node_or_null("PickupPartition") as Node3D
	if pickup_partition:
		pickup_partition.visible=false
	host.delivery_courier=host._create_courier_actor("DeliveryRider")
	host.courier_package=host._instantiate_delivery_container()
	if is_instance_valid(host.courier_package):
		host.courier_package.name="CourierDeliveryContainer"
		host.courier_package.position=Vector3(0.42,1.05,-0.18)
		host.courier_package.rotation_degrees=Vector3(0,0,0)
		host.courier_package.scale=Vector3.ONE*0.12
		host.delivery_courier.add_child(host.courier_package)
	else:
		host.courier_package=host.box("CourierPackage",Vector3(0.42,1.05,-0.18),Vector3(0.52,0.38,0.46),Color("#f2d29b"),host.delivery_courier,false)
	host.courier_package.visible=false
	var player := CharacterBody3D.new()
	player.name="Player"
	player.position=Vector3(0,1.1,-2.5 if host.store_stage==1 else 3.0)
	player.collision_layer=2
	player.collision_mask=1
	player.set_script(load("res://assets/scripts/player.gd"))
	host.player_body=player
	var capsule := CollisionShape3D.new(); var cap := CapsuleShape3D.new(); cap.radius=0.35; cap.height=2.10; capsule.shape=cap; player.add_child(capsule)
	host._add_player_character_model(player)
	host.camera=Camera3D.new(); host.camera.name="Camera3D"; host.camera.position=Vector3(0,1.38,-0.08); host.camera.current=true; player.add_child(host.camera)
	host._build_first_person_tools(host.camera)
	host.add_child(player)

func create_dining_tables() -> void:
	var old_area:=get_node_or_null("DiningArea")
	if not old_area: old_area=get_node_or_null("EditableModels/DiningArea")
	if host.store_stage==1:
		# 1??傭?끆????????????썹땟戮녹?????????諛몃마???????????????關履???????雅?퍔瑗?땟??믠뫁竊?????????????傭?끆??????????????놁졄.
		if is_instance_valid(old_area): old_area.visible=false
		return
	var area:Node3D
	if old_area:
		area=old_area as Node3D
		area.visible=true
		for child in area.get_children():
			if child.name.begins_with("DiningTable_"): child.free()
	else:
		area=Node3D.new(); area.name="DiningArea"; add_child(area)
	var table_count:int=0 if host.store_stage==1 else (4 if host.store_stage>=3 else 2)
	for i in table_count:
		var row:int=floori(float(i)/2.0); var column:int=i%2
		var table_position:=Vector3(1.8+column*3.2,0.65,0.9+row*3.0)
		var table_model:=area.get_node_or_null("DiningTableModel_%d"%(i+1)) as Node3D
		if is_instance_valid(table_model):
			table_position=table_model.position
			host._add_model_collision(table_model,"FurnitureCollision")
		var table_proxy: MeshInstance3D = host.box("DiningTable_%d"%(i+1),table_position,Vector3(2.0,1.3,1.2),Color("#9a7658"),area)
		table_proxy.visible=false
		host.interactable(table_proxy,"?饔낅떽???????????????????????꿔꺂?€??"); host.interaction_data(table_proxy,"table",i)
		if not is_instance_valid(table_model): host._add_dining_furniture_model("res://assets/models/dining_table.fbx",table_position,Vector3(0,180,0),0.72,"DiningTableModel_%d"%(i+1),area)
		for side in [-1,1]:
			# Keep the entire chair outside the tabletop: the backrest must be on
			# the side opposite the table, with the seat facing inward.
			var chair_position:=table_position+Vector3(0, -0.2, side*1.55)
			# The imported chair's back faces the opposite direction in Godot,
			# so reverse the yaw to keep the backrest behind the seated customer.
			var existing_chair:=area.get_node_or_null("ChairModel_%d_%d"%[i,side]) as Node3D
			if is_instance_valid(existing_chair):
				host._add_model_collision(existing_chair,"FurnitureCollision")
			else:
				host._add_dining_furniture_model("res://assets/models/dining_chair.fbx",chair_position,Vector3(0,0 if side==-1 else 180,0),0.72,"ChairModel_%d_%d"%[i,side],area)

func add_dining_furniture_model(path: String, world_position: Vector3, rotation: Vector3, model_scale: float, model_name: String, parent: Node3D) -> Node3D:
	var resource: Resource=load(path)
	if not resource is PackedScene: return Node3D.new()
	var model: Node3D=(resource as PackedScene).instantiate() as Node3D
	model.name=model_name
	model.position=world_position
	model.rotation_degrees=rotation
	model.scale=Vector3.ONE*model_scale
	parent.add_child(model)
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color.WHITE
	var prefix: String="dining_table" if path.contains("dining_table") else "dining_chair"
	var color_texture:=load("res://assets/models/%s.png"%prefix) as Texture2D
	if color_texture: material.albedo_texture=color_texture
	var normal_texture:=load("res://assets/models/%s_normal.png"%prefix) as Texture2D
	if normal_texture:
		material.normal_enabled=true
		material.normal_texture=normal_texture
	var metallic_texture:=load("res://assets/models/%s_metallic.png"%prefix) as Texture2D
	if metallic_texture:
		material.metallic=1.0
		material.metallic_texture=metallic_texture
	var roughness_texture:=load("res://assets/models/%s_roughness.png"%prefix) as Texture2D
	if roughness_texture:
		material.roughness=1.0
		material.roughness_texture=roughness_texture
	for child in model.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_overlay=material
	host._add_model_collision(model,"FurnitureCollision")
	return model
