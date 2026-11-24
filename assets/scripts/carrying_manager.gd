extends Node

# 플레이어가 들고 있는 물건의 공통 상태와 표시를 담당합니다.
var host

func setup(game_host) -> void:
	host=game_host

func build_first_person_ladle(camera_node: Camera3D, tools: Node3D) -> void:
	host.held_ladle=make_ladle_model("empty")
	if is_instance_valid(host.held_ladle):
		host.held_ladle.name="HeldLadle"
		host.held_ladle.position=Vector3(0.34,-0.23,-0.78)
		host.held_ladle.rotation_degrees=Vector3(8,-18,12)
		host.held_ladle.scale=Vector3.ONE*0.38
		tools.add_child(host.held_ladle)
	if is_instance_valid(host.held_ladle): host.held_ladle.visible=false

func build_first_person_hand(parent: Node3D, hand_name: String, hand_position: Vector3, hand_rotation: Vector3) -> Node3D:
	var hand_root: Node3D=Node3D.new()
	hand_root.name=hand_name
	hand_root.position=hand_position
	hand_root.rotation_degrees=hand_rotation
	parent.add_child(hand_root)
	var glove_material: StandardMaterial3D=StandardMaterial3D.new()
	glove_material.albedo_color=Color("#25282b")
	glove_material.roughness=0.72
	var skin_material: StandardMaterial3D=StandardMaterial3D.new()
	skin_material.albedo_color=Color("#d9ad91")
	skin_material.roughness=0.78
	var forearm: MeshInstance3D=host.cylinder("Forearm",Vector3(0,0.0,0.24),0.075,0.48,Color("#25282b"),hand_root,false)
	forearm.rotation_degrees.x=90
	forearm.material_override=glove_material
	var palm: MeshInstance3D=host.cylinder("Palm",Vector3(0,0,-0.03),0.095,0.18,Color("#25282b"),hand_root,false)
	palm.rotation_degrees.x=90
	palm.material_override=skin_material
	hand_root.set_meta("rest_position",hand_position)
	return hand_root

func play_tool_pickup_animation(tool: Node3D, hand: Node3D) -> void:
	if not is_instance_valid(tool) or not is_instance_valid(hand): return
	var tool_rest: Vector3=tool.position
	var hand_rest: Vector3=hand.get_meta("rest_position",hand.position)
	tool.position=tool_rest+Vector3(0,-0.55,0.32)
	if not hand is BoneAttachment3D: hand.position=hand_rest+Vector3(0,-0.55,0.32)
	var tween: Tween=host.create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(tool,"position",tool_rest,0.38)
	if not hand is BoneAttachment3D: tween.tween_property(hand,"position",hand_rest,0.38)

func build_bowl_stack(anchor: Vector3, count: int=5) -> void:
	if is_instance_valid(host.bowl_stack_root): host.bowl_stack_root.queue_free()
	host.bowl_stack_models.clear()
	host.bowl_stack_root=Node3D.new()
	host.bowl_stack_root.name="EmptyBowlStack"
	host.bowl_stack_root.global_position=anchor
	host.add_child(host.bowl_stack_root)
	for index in count:
		var bowl: Node3D=instantiate_empty_bowl()
		if not is_instance_valid(bowl): continue
		bowl.name="EmptyBowl_%d"%(index+1)
		bowl.position=Vector3(0.0,float(index)*0.105,0.0)
		bowl.rotation_degrees=Vector3.ZERO
		bowl.scale=Vector3.ONE*0.22
		host.bowl_stack_root.add_child(bowl)
		host.bowl_stack_models.append(bowl)
	host.world_bowl=host.bowl_stack_root

func instantiate_empty_bowl() -> Node3D:
	var resource: Resource=load("res://assets/models/malatang_empty_bowl.fbx")
	if not resource is PackedScene: return null
	var model: Node3D=(resource as PackedScene).instantiate() as Node3D
	if is_instance_valid(model): apply_empty_bowl_material(model)
	return model

func apply_empty_bowl_material(root: Node) -> void:
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color.WHITE
	material.albedo_texture=load("res://assets/models/malatang_empty_bowl.png") as Texture2D
	material.normal_texture=load("res://assets/models/malatang_empty_bowl_normal.png") as Texture2D
	material.normal_enabled=material.normal_texture != null
	material.metallic_texture=load("res://assets/models/malatang_empty_bowl_metallic.png") as Texture2D
	material.roughness_texture=load("res://assets/models/malatang_empty_bowl_roughness.png") as Texture2D
	material.metallic=0.15
	material.roughness=0.32
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_override=material

func add_world_tool_model(path: String, world_position: Vector3, rotation: Vector3, model_scale: float, is_tongs: bool) -> Node3D:
	var resource:Resource=load(path)
	if not resource is PackedScene: return null
	var model:Node3D=(resource as PackedScene).instantiate() as Node3D
	model.position=world_position+Vector3(0,-0.18,0) if path.contains("dining_table") else world_position
	model.rotation_degrees=rotation
	model.scale=Vector3.ONE*model_scale
	host.add_child(model)
	if is_tongs: host._apply_tongs_material(model)
	else: host._apply_ingredient_bowl_material(model)
	return model

func set_held_render_front(root: Node) -> void:
	if not is_instance_valid(root) or root.has_meta("held_render_front"): return
	root.set_meta("held_render_front",true)
	var meshes:Array[MeshInstance3D]=[]
	if root is MeshInstance3D: meshes.append(root as MeshInstance3D)
	for child in root.find_children("*","MeshInstance3D",true,false): meshes.append(child as MeshInstance3D)
	for mesh_instance in meshes:
		if not is_instance_valid(mesh_instance) or not is_instance_valid(mesh_instance.mesh): continue
		mesh_instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface_index in mesh_instance.mesh.get_surface_count():
			var source_material:=mesh_instance.get_active_material(surface_index)
			if source_material is BaseMaterial3D:
				var front_material:BaseMaterial3D=(source_material as BaseMaterial3D).duplicate()
				front_material.no_depth_test=true
				front_material.render_priority=50
				mesh_instance.set_surface_override_material(surface_index,front_material)

func take_bowl_from_stack(take_all: bool=false) -> int:
	if host.bowl_stack_models.is_empty():
		return 0
	var taken: int=1 if not take_all else host.bowl_stack_models.size()
	if take_all:
		for bowl in host.bowl_stack_models:
			if is_instance_valid(bowl):
				bowl.queue_free()
		host.bowl_stack_models.clear()
		if is_instance_valid(host.bowl_stack_root):
			host.bowl_stack_root.visible=false
		return taken
	var top: Node3D=host.bowl_stack_models.pop_back()
	if is_instance_valid(top):
		top.queue_free()
	if is_instance_valid(host.bowl_stack_root):
		host.bowl_stack_root.visible=not host.bowl_stack_models.is_empty()
	return taken

func refresh_held_bowl_stack_visual() -> void:
	for bowl in host.held_bowl_stack_visuals:
		if is_instance_valid(bowl):
			bowl.queue_free()
	host.held_bowl_stack_visuals.clear()
	if not host.has_bowl or host.held_bowl_count<=1 or not is_instance_valid(host.held_bowl): return
	for index in range(1,host.held_bowl_count):
		var bowl: Node3D=instantiate_empty_bowl()
		if not is_instance_valid(bowl): continue
		bowl.name="HeldEmptyBowl_%d"%index
		bowl.position=Vector3(0.0,float(index)*0.60,0.0)
		bowl.rotation_degrees=Vector3.ZERO
		bowl.scale=Vector3.ONE
		host.held_bowl.add_child(bowl)
		host.held_bowl_stack_visuals.append(bowl)

func refresh_held_ladle_model() -> void:
	if not is_instance_valid(host.held_ladle): return
	var parent: Node=host.held_ladle.get_parent()
	var old_position: Vector3=host.held_ladle.position
	var old_rotation: Vector3=host.held_ladle.rotation_degrees
	var old_scale: Vector3=host.held_ladle.scale
	host.held_ladle.free()
	host.held_ladle=make_ladle_model(host.ladle_state)
	if not is_instance_valid(host.held_ladle): return
	host.held_ladle.name="HeldLadle"
	host.held_ladle.position=old_position
	host.held_ladle.rotation_degrees=old_rotation
	host.held_ladle.scale=old_scale
	parent.add_child(host.held_ladle)
	host.held_ladle.visible=host.has_ladle

func is_held_blocked_by_placeable() -> bool:
	if not is_instance_valid(host.held_collision_area): return false
	for body in host.held_collision_area.get_overlapping_bodies():
		var node:Node=body
		while is_instance_valid(node) and node!=host:
			if node.is_in_group("placeable_object"): return true
			node=node.get_parent()
	return false

func update_held_preview(blocked: bool) -> void:
	var carrying_object:bool=host.has_broth_pot or host.has_broth_stock_pack or host.has_ladle or host.has_tongs or host.has_bowl or host.has_steel_bowl
	if not carrying_object or not is_instance_valid(host.held_tools): host._clear_held_preview(); return
	var source:Node3D=null
	if host.has_broth_pot: source=host.carried_broth_pot_model
	elif host.has_broth_stock_pack: source=host.held_broth_stock_open_model if host.broth_stock_pack_open else host.held_broth_stock_model
	elif host.has_ladle: source=host.held_ladle
	elif host.has_tongs: source=host.held_tongs
	elif host.has_bowl: source=host.held_bowl
	elif host.has_steel_bowl: source=host.held_steel_bowl
	if not is_instance_valid(source): host._clear_held_preview(); return
	var placement_surface:Node3D=host._get_placement_surface_from_view()
	if not is_instance_valid(placement_surface): host._clear_held_preview(); return
	var placement:Dictionary=host._get_table_placement_point(placement_surface,2.2,host._held_place_radius(),source)
	var point:Vector3=placement["point"]
	var invalid:bool=blocked or not bool(placement["can_place"])
	if is_instance_valid(host.held_placement_preview) and host.held_preview_source!=source:
		host.held_placement_preview.queue_free(); host.held_placement_preview=null
	if not is_instance_valid(host.held_placement_preview):
		host.held_placement_preview=source.duplicate(); host.held_placement_preview.name="HeldPlacementPreview"; host.add_child(host.held_placement_preview); host.held_preview_source=source
		for child in host.held_placement_preview.find_children("*","CollisionShape3D",true,false): (child as CollisionShape3D).disabled=true
		for child in host.held_placement_preview.find_children("*","StaticBody3D",true,false):
			var body:=child as StaticBody3D; body.collision_layer=0; body.collision_mask=0
		var ghost_material:=StandardMaterial3D.new(); ghost_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; ghost_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; ghost_material.albedo_color=Color(0.25,1.0,0.45,0.42); ghost_material.emission_enabled=true; ghost_material.emission=Color(0.25,1.0,0.45); ghost_material.emission_energy_multiplier=0.8
		for child in host.held_placement_preview.find_children("*","MeshInstance3D",true,false): (child as MeshInstance3D).material_overlay=ghost_material
	var ghost_color:=Color(1.0,0.18,0.12,0.42) if invalid else Color(0.25,1.0,0.45,0.42)
	for child in host.held_placement_preview.find_children("*","MeshInstance3D",true,false):
		var ghost_material:StandardMaterial3D=(child as MeshInstance3D).material_overlay as StandardMaterial3D
		if is_instance_valid(ghost_material): ghost_material.albedo_color=ghost_color; ghost_material.emission=ghost_color
	var preview_scale:=source.scale
	if host.has_broth_pot: preview_scale=Vector3.ONE*0.62
	elif host.has_broth_stock_pack: preview_scale=Vector3.ONE*0.38
	elif host.has_steel_bowl: preview_scale=Vector3.ONE*0.34
	host.held_placement_preview.scale=preview_scale; host.held_placement_preview.global_position=point
	host.held_placement_preview.rotation_degrees=Vector3(0,180+host.held_place_rotation_y,0) if host.has_broth_pot else Vector3(90,host.held_place_rotation_y,90) if host.has_ladle else Vector3(0,host.held_place_rotation_y,90) if host.has_tongs else Vector3(0,host.held_place_rotation_y,0)
	host._snap_model_bottom_to_surface(host.held_placement_preview,host._placement_surface_y(placement_surface)+host._placement_offset_y(placement_surface))

func has_any_held_object() -> bool:
	if not is_instance_valid(host): return false
	return host.has_broth_pot or host.has_broth_stock_pack or host.has_ladle or host.has_tongs or host.has_bowl or host.has_steel_bowl

func held_place_radius() -> float:
	if not is_instance_valid(host): return 0.28
	if host.has_broth_pot: return 0.72
	if host.has_broth_stock_pack: return 0.34
	if host.has_steel_bowl: return 0.38
	return 0.28

func update_visibility() -> void:
	if not is_instance_valid(host): return
	host._set_held_render_front(host.held_tongs)
	host._set_held_render_front(host.held_bowl)
	host._set_held_render_front(host.held_steel_bowl)
	host._set_held_render_front(host.held_ladle)
	host._set_held_render_front(host.held_broth_stock_model)
	host._set_held_render_front(host.held_broth_stock_open_model)
	host._set_held_render_front(host.serving_bowl_view)
	host._set_held_render_front(host.delivery_container_view)
	host._set_held_render_front(host.carried_broth_pot_model)
	for bowl in host.held_bowl_stack_visuals: host._set_held_render_front(bowl)
	if is_instance_valid(host.held_tongs): host.held_tongs.visible=host.has_tongs
	if is_instance_valid(host.held_bowl): host.held_bowl.visible=host.has_bowl
	if is_instance_valid(host.held_steel_bowl): host.held_steel_bowl.visible=host.has_steel_bowl
	host._refresh_held_bowl_stack_visual()
	if is_instance_valid(host.held_ladle): host.held_ladle.visible=host.has_ladle
	if is_instance_valid(host.held_broth_stock_model): host.held_broth_stock_model.visible=host.has_broth_stock_pack and not host.broth_stock_pack_open
	if is_instance_valid(host.held_broth_stock_open_model): host.held_broth_stock_open_model.visible=host.has_broth_stock_pack and host.broth_stock_pack_open
	if is_instance_valid(host.world_ladle): host.world_ladle.visible=not host.has_ladle
	if is_instance_valid(host.held_basket_items): host.held_basket_items.visible=host.has_bowl
	if is_instance_valid(host.world_tongs): host.world_tongs.visible=not host.has_tongs
	if is_instance_valid(host.world_bowl): host.world_bowl.visible=not host.has_bowl
	if is_instance_valid(host.world_steel_bowl): host.world_steel_bowl.visible=not host.has_steel_bowl
	host._update_player_arm_visibility()

func make_ladle_model(state:String) -> Node3D:
	if not is_instance_valid(host): return null
	var path:=str(host.LADLE_MODEL_PATHS.get(state,host.LADLE_MODEL_PATHS["empty"]))
	var resource:Resource=load(path)
	if not resource is PackedScene: return null
	var model:Node3D=(resource as PackedScene).instantiate() as Node3D
	apply_ladle_material(model,state)
	if state=="empty" and host.selected_spice>0:
		var spice_colors:Array[Color]=[Color("#e3c35e"),Color("#c86435"),Color("#a92e27")]
		var sauce:MeshInstance3D=host.cylinder("LadleSpiceColor",Vector3(0,0.16,0),0.07,0.012,spice_colors[clampi(host.selected_spice-1,0,2)],model,false)
		sauce.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return model

func apply_ladle_material(root:Node, state:String) -> void:
	if not is_instance_valid(host): return
	var prefix:String="empty"
	if state=="broth": prefix="broth"
	elif state=="malatang": prefix="malatang"
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color(1.18,1.18,1.18,1.0)
	material.metallic=0.32
	material.roughness=0.28
	var color_texture:=load("res://assets/models/ladles/%s/%s.png"%[prefix,prefix]) as Texture2D
	if color_texture: material.albedo_texture=color_texture
	var normal_texture:=load("res://assets/models/ladles/%s/%s_normal.png"%[prefix,prefix]) as Texture2D
	if normal_texture:
		material.normal_enabled=true
		material.normal_texture=normal_texture
	var metallic_texture:=load("res://assets/models/ladles/%s/%s_metallic.png"%[prefix,prefix]) as Texture2D
	if metallic_texture: material.metallic_texture=metallic_texture
	var roughness_texture:=load("res://assets/models/ladles/%s/%s_roughness.png"%[prefix,prefix]) as Texture2D
	if roughness_texture: material.roughness_texture=roughness_texture
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_overlay=material

func make_ladle_sprite(sprite_name:String, world_position:Vector3, pixel_size_value:float) -> Sprite3D:
	if not is_instance_valid(host): return null
	var sprite:=Sprite3D.new()
	sprite.name=sprite_name
	sprite.texture=load("res://ladle_restaurant_style_blue_grip.png") as Texture2D
	sprite.pixel_size=pixel_size_value
	sprite.position=world_position
	sprite.no_depth_test=true
	sprite.render_priority=10
	host.add_child(sprite)
	return sprite

func play_ladle_scoop_animation() -> void:
	if not is_instance_valid(host.held_ladle): return
	var start_position:Vector3=host.held_ladle.position
	var start_rotation:Vector3=host.held_ladle.rotation_degrees
	var tween:Tween=host.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(host.held_ladle,"position",start_position+Vector3(0,0.08,0.08),0.18)
	tween.parallel().tween_property(host.held_ladle,"rotation_degrees",start_rotation+Vector3(-24,0,0),0.18)
	tween.tween_property(host.held_ladle,"position",start_position,0.22)
	tween.parallel().tween_property(host.held_ladle,"rotation_degrees",start_rotation,0.22)
func place_held_object_on_table(surface: Node3D, whole_stack: bool=false) -> void:
	if not is_instance_valid(host.camera) or not is_instance_valid(surface): return
	var forward:Vector3=-host.camera.global_basis.z
	if absf(forward.y)<0.001:
		host.result_label.text="테이블 상판을 바라보고 내려놓으세요."
		return
	var surface_y:float=host._placement_surface_y(surface)
	var distance:float=(surface_y-host.camera.global_position.y)/forward.y
	if distance<=0.0:
		host.result_label.text="테이블 상판을 바라보고 내려놓으세요."
		return
	var point:Vector3=host.camera.global_position+forward*distance
	var half_extents:Vector2=surface.get_meta("place_half_extents",Vector2(3.50,0.75))
	point.x=clampf(point.x,surface.global_position.x-half_extents.x,surface.global_position.x+half_extents.x)
	point.z=clampf(point.z,surface.global_position.z-half_extents.y,surface.global_position.z+half_extents.y)
	point.y=surface_y+host._placement_offset_y(surface)
	var held_source:Node=null
	if host.has_broth_pot: held_source=host.carried_broth_pot_model
	elif host.has_broth_stock_pack:
		held_source=host.held_broth_stock_open_model if host.broth_stock_pack_open else host.held_broth_stock_model
	elif host.has_steel_bowl: held_source=host.held_steel_bowl
	if not host._is_place_position_free(point,host._held_place_radius(),held_source):
		host.result_label.text="다른 오브젝트와 겹쳐서 이곳에는 둘 수 없습니다."
		return
	if host.has_ladle and is_instance_valid(host.world_ladle):
		host.has_ladle=false
		host.world_ladle.global_position=point
		host.world_ladle.rotation_degrees=Vector3(90,host.held_place_rotation_y,90)
		host._snap_model_bottom_to_surface(host.world_ladle,surface_y+host._placement_offset_y(surface))
		host.world_ladle.visible=true
		host.world_ladle.add_to_group("placeable_object")
		host.world_ladle.set_meta("place_radius",0.28)
		host.interactable(host.world_ladle,"국자 집기")
		host.interaction_data(host.world_ladle,"toggle_ladle")
		host._update_held_tool_visibility()
		host.result_label.text="국자를 테이블 위에 내려놓았습니다."
	elif host.has_tongs and is_instance_valid(host.world_tongs):
		host.has_tongs=false
		host.world_tongs.global_position=point
		host.world_tongs.rotation_degrees=Vector3(0,host.held_place_rotation_y,90)
		host._snap_model_bottom_to_surface(host.world_tongs,surface_y+host._placement_offset_y(surface))
		host.world_tongs.visible=true
		host.world_tongs.add_to_group("placeable_object")
		host.world_tongs.set_meta("place_radius",0.30)
		host.interactable(host.world_tongs,"집게 집기")
		host.interaction_data(host.world_tongs,"toggle_tongs")
		host._update_held_tool_visibility()
		host.result_label.text="집게를 테이블 위에 내려놓았습니다."
	elif host.has_steel_bowl and is_instance_valid(host.world_steel_bowl):
		host.has_steel_bowl=false
		host.world_steel_bowl.global_position=point
		host.world_steel_bowl.rotation_degrees=Vector3(0,host.held_place_rotation_y,0)
		host._snap_model_bottom_to_surface(host.world_steel_bowl,surface_y+host._placement_offset_y(surface))
		host.world_steel_bowl.visible=true
		host.world_steel_bowl.add_to_group("placeable_object")
		host.world_steel_bowl.set_meta("place_radius",0.38)
		host.interactable(host.world_steel_bowl,"쇠그릇 집기")
		host.interaction_data(host.world_steel_bowl,"toggle_steel_bowl")
		host._update_held_tool_visibility()
		host.result_label.text="쇠그릇을 테이블 위에 내려놓았습니다."
	elif host.has_bowl:
		var place_count:int=host.held_bowl_count if whole_stack else 1
		place_count=maxi(1,place_count)
		var placed_bowls:Array[Node3D]=[]
		for bowl_index in place_count:
			var placed_bowl:Node3D=host._instantiate_empty_bowl()
			if is_instance_valid(placed_bowl): placed_bowls.append(placed_bowl)
		if placed_bowls.size()!=place_count:
			host.result_label.text="빈 그릇 모델을 불러올 수 없습니다."
			for placed_bowl in placed_bowls:
				if is_instance_valid(placed_bowl): placed_bowl.queue_free()
			return
		for bowl_index in place_count:
			var placed_bowl:Node3D=placed_bowls[bowl_index]
			placed_bowl.name="PlacedEmptyBowl_%d_%d"%[Time.get_ticks_msec(),bowl_index]
			placed_bowl.global_position=point+Vector3(0,float(bowl_index)*0.105,0)
			placed_bowl.rotation_degrees=Vector3(0,host.held_place_rotation_y,0)
			placed_bowl.scale=Vector3.ONE*0.22
			add_child(placed_bowl)
			host._snap_model_bottom_to_surface(placed_bowl,surface_y+host._placement_offset_y(surface)+float(bowl_index)*0.105)
			placed_bowl.visible=true
			placed_bowl.add_to_group("placeable_object")
			placed_bowl.set_meta("place_radius",0.34)
			placed_bowl.set_meta("placed_empty_bowl",true)
			host.interactable(placed_bowl,"빈 그릇 집기")
			host.interaction_data(placed_bowl,"toggle_bowl")
			host._add_model_collision(placed_bowl,"PlacedEmptyBowlCollision")
		host.held_bowl_count-=place_count
		if host.held_bowl_count<=0:
			host.has_bowl=false
		host._update_held_tool_visibility()
		host.result_label.text="빈 그릇 %d개를 테이블 위에 내려놓았습니다."%place_count
	elif host.has_broth_stock_pack:
		var stock_path: String="res://assets/models/broth_stock/stock_pack_open.fbx" if host.broth_stock_pack_open else "res://assets/models/broth_stock/stock_pack.fbx"
		var placed:Node3D=host._add_broth_stock_model(stock_path,"PlacedBrothStockPack_%d"%Time.get_ticks_msec(),point,0.38)
		if is_instance_valid(placed):
			# Keep the same facing as the editor-placed source object. The
			# imported FBX orientation is not necessarily the same as the world
			# axes, so using a hard-coded rotation can show its back/blank side.
			if is_instance_valid(host.broth_stock_model):
				placed.global_rotation=host.broth_stock_model.global_rotation
			placed.global_rotation_degrees.y+=host.held_place_rotation_y
			host._snap_model_bottom_to_surface(placed,surface_y+host._placement_offset_y(surface))
			placed.visible=true
			placed.add_to_group("placeable_object")
			placed.set_meta("place_radius",0.34)
			placed.set_meta("placed_broth_stock",true)
			placed.set_meta("broth_stock_open",host.broth_stock_pack_open)
			host.interactable(placed,"사골 육수팩 집기")
			host.interaction_data(placed,"broth_stock")
			placed.set_meta("highlight_target",placed)
			host._add_model_collision(placed,"PlacedBrothStockCollision")
		host.has_broth_stock_pack=false
		host.broth_stock_pack_open=false
		host._update_held_tool_visibility()
		host.result_label.text="사골 육수팩을 테이블 위에 내려놓았습니다."
	elif host.has_broth_pot and is_instance_valid(host.carried_broth_pot_model):
		host.has_broth_pot=false
		host.carried_broth_pot_model.reparent(host,true)
		host.carried_broth_pot_model.global_position=point
		host.carried_broth_pot_model.rotation_degrees=Vector3(0,180+host.held_place_rotation_y,0)
		host.carried_broth_pot_model.scale=Vector3.ONE*0.62
		host._snap_model_bottom_to_surface(host.carried_broth_pot_model,surface_y+host._placement_offset_y(surface))
		host.broth_pot_home_transform=host.carried_broth_pot_model.global_transform
		if is_instance_valid(host.broth_pot_interaction):
			if host.broth_pot_interaction.get_parent()==host.carried_broth_pot_model: host.broth_pot_interaction.position=Vector3.ZERO
			else: host.broth_pot_interaction.global_position=point
		host._set_broth_pot_carried_collision(false)
		host._set_broth_pot_filled_visual(is_instance_valid(host.broth_pot_filled_model) and host.broth_pot_filled_model==host.carried_broth_pot_model)
		host.carried_broth_pot_model=null
		if is_instance_valid(host.broth_pot_drop_zone): host.broth_pot_drop_zone.set_meta("interaction_disabled",true)
		host.result_label.text="육수 냄비를 테이블 위에 내려놓았습니다."
	else:
		host.result_label.text="테이블 위에 내려놓을 물건을 들고 있어야 합니다."
	# Clear the placement ghost and the previous focus after a successful drop.
	host._clear_held_preview()
	host._set_highlight(null)
	host.held_place_rotation_y=0.0
	host._refresh_hud()

func build_first_person_tools(camera_node: Camera3D) -> void:
	var tools:=Node3D.new(); tools.name="HeldTools"; tools.position=Vector3(0.34,-0.34,-0.72); camera_node.add_child(tools)
	host.held_tools=tools
	host.held_collision_area=Area3D.new()
	host.held_collision_area.name="HeldObjectCollisionArea"
	host.held_collision_area.collision_layer=0
	host.held_collision_area.collision_mask=1
	host.held_collision_area.monitoring=true
	var held_collision_shape:=CollisionShape3D.new()
	var held_sphere:=SphereShape3D.new()
	held_sphere.radius=0.30
	held_collision_shape.shape=held_sphere
	host.held_collision_area.add_child(held_collision_shape)
	camera_node.add_child(host.held_collision_area)
	host.held_collision_area.position=tools.position+Vector3(-0.30,-0.34,-0.82)
	host.held_collision_area.monitoring=false
	host.held_broth_stock_model=host._add_broth_stock_model("res://assets/models/broth_stock/stock_pack.fbx","HeldBrothStockPack",Vector3(0.02,-0.16,-0.62),0.12)
	host.held_broth_stock_open_model=host._add_broth_stock_model("res://assets/models/broth_stock/stock_pack_open.fbx","HeldBrothStockPackOpen",Vector3(0.02,-0.16,-0.62),0.12)
	if is_instance_valid(host.held_broth_stock_model): host.held_broth_stock_model.reparent(tools); host.held_broth_stock_model.position=Vector3(0.02,-0.16,-0.62); host.held_broth_stock_model.rotation_degrees=Vector3(8,-18,0); host.held_broth_stock_model.scale=Vector3.ONE*0.22; host.held_broth_stock_model.visible=false
	if is_instance_valid(host.held_broth_stock_open_model): host.held_broth_stock_open_model.reparent(tools); host.held_broth_stock_open_model.position=Vector3(0.02,-0.16,-0.62); host.held_broth_stock_open_model.rotation_degrees=Vector3(8,-18,0); host.held_broth_stock_open_model.scale=Vector3.ONE*0.22; host.held_broth_stock_open_model.visible=false
	var tongs_resource:=load("res://assets/models/kitchen_tongs.fbx")
	if tongs_resource is PackedScene:
		var imported_tongs: Node3D=tongs_resource.instantiate() as Node3D; imported_tongs.name="KitchenTongsModel"; imported_tongs.position=Vector3(0.28,-0.22,-0.70); imported_tongs.rotation_degrees=Vector3(8,-90,-8); imported_tongs.scale=Vector3.ONE*0.36; tools.add_child(imported_tongs); host._apply_tongs_material(imported_tongs)
		host.held_tongs=imported_tongs
		# 플레이어 몸을 숨긴 상태에서는 카메라 앞 도구 위치를 사용합니다.
		# Keep the held tongs in the same lower-right first-person framing as the ladle.
		imported_tongs.position=Vector3(0.28,-0.22,-0.70)
		imported_tongs.rotation_degrees=Vector3(8,-90,-8)
		imported_tongs.scale=Vector3.ONE*0.36
	else:
		var handle:MeshInstance3D=host.box("TongHandle",Vector3(0,0,0),Vector3(0.08,0.08,0.65),Color("#c8cdd0"),tools,false); handle.rotation_degrees.x=-18
		var arm_a:MeshInstance3D=host.box("TongArmA",Vector3(-0.07,0,-0.36),Vector3(0.045,0.04,0.58),Color("#d8dcde"),tools,false); arm_a.rotation_degrees.y=-7
		var arm_b:MeshInstance3D=host.box("TongArmB",Vector3(0.07,0,-0.36),Vector3(0.045,0.04,0.58),Color("#d8dcde"),tools,false); arm_b.rotation_degrees.y=7
		host.held_tongs=handle
	var bowl_resource:=load("res://assets/models/malatang_empty_bowl.fbx")
	if bowl_resource is PackedScene:
		var imported_bowl: Node3D=bowl_resource.instantiate() as Node3D
		imported_bowl.name="IngredientBowlModel"
		imported_bowl.position=Vector3(-0.64,-0.40,-0.72)
		imported_bowl.rotation_degrees=Vector3(8,0,0)
		imported_bowl.scale=Vector3.ONE*0.32
		tools.add_child(imported_bowl)
		host._apply_empty_bowl_material(imported_bowl)
		host.held_bowl=imported_bowl
		imported_bowl.position=Vector3(-0.64,-0.40,-0.72)
		imported_bowl.rotation_degrees=Vector3(8,0,0)
		imported_bowl.scale=Vector3.ONE*0.32
	else:
		var basket_view:MeshInstance3D=host.cylinder("HeldBasket",Vector3(-0.66,-0.40,-0.68),0.25,0.10,Color("#aeb5ba"),tools,false)
		basket_view.material_override.metallic=0.9
		basket_view.material_override.roughness=0.25
		host.held_bowl=basket_view
	var steel_bowl_resource:=load("res://assets/models/steel_bowl_check/Meshy_AI_쇠그릇_20261118_texture_fbx/Meshy_AI_쇠그릇_20261118_texture.fbx")
	if steel_bowl_resource is PackedScene:
		var imported_steel_bowl:Node3D=(steel_bowl_resource as PackedScene).instantiate() as Node3D
		imported_steel_bowl.name="HeldSteelBowl"
		# Centered between the hands: this is the only two-hand carry object.
		imported_steel_bowl.position=Vector3(-0.12,-0.38,-0.78)
		imported_steel_bowl.rotation_degrees=Vector3(8,0,0)
		imported_steel_bowl.scale=Vector3.ONE*0.28
		tools.add_child(imported_steel_bowl)
		host.held_steel_bowl=imported_steel_bowl
	host.serving_bowl_view=host._instantiate_serving_bowl()
	if is_instance_valid(host.serving_bowl_view):
		host.serving_bowl_view.name="HeldServingBowl"
		host.serving_bowl_view.position=Vector3(-0.48,-0.42,-0.92)
		host.serving_bowl_view.rotation_degrees=Vector3(8,0,0)
		host.serving_bowl_view.scale=Vector3.ONE*0.22
		camera_node.add_child(host.serving_bowl_view)
		host.serving_bowl_view.visible=false
	host._build_first_person_ladle(camera_node,tools)
	host.delivery_container_view=host._instantiate_delivery_container()
	if is_instance_valid(host.delivery_container_view):
		host.delivery_container_view.name="HeldDeliveryContainer"
		host.delivery_container_view.position=Vector3(-0.48,-0.42,-0.92)
		host.delivery_container_view.rotation_degrees=Vector3(8,0,0)
		host.delivery_container_view.scale=Vector3.ONE*0.15
		camera_node.add_child(host.delivery_container_view)
		host.delivery_container_view.visible=false
	host.held_basket_items=Node3D.new()
	host.held_basket_items.name="BasketContents"
	# Contents belong to the bowl itself. They must never follow the host.camera or
	# hand independently, otherwise ingredients visually separate while moving.
	if is_instance_valid(host.held_bowl):
		host.held_bowl.add_child(host.held_basket_items)
		host.held_basket_items.position=Vector3(0.0,0.44,0.0)
		host.held_basket_items.rotation_degrees=Vector3.ZERO
		host.held_basket_items.scale=Vector3.ONE*4.24
		host.held_basket_items.top_level=false
	else:
		tools.add_child(host.held_basket_items)
		host.held_basket_items.position=Vector3(-0.64,-0.20,-0.72)
	host.tongs_hand=tools
	host.bowl_hand=tools
	host._update_held_tool_visibility()

func build_tool_pickup_station() -> void:
	host.box("ToolStation",Vector3(-4.0,0.45,-5.95),Vector3(2.4,0.9,0.78),Color("#9b9185"))
	var tongs_pad:MeshInstance3D=host.box("TongsPickup",Vector3(-4.52,0.98,-5.72),Vector3(0.8,0.12,0.48),Color("#d7d0c6")); host.interactable(tongs_pad,"집게 집기 / 내려놓기"); host.interaction_data(tongs_pad,"toggle_tongs")
	var bowl_pad:MeshInstance3D=host.box("BowlPickup",Vector3(-3.48,0.98,-5.72),Vector3(0.8,0.12,0.48),Color("#d7d0c6")); host.interactable(bowl_pad,"그릇 집기 / 내려놓기"); host.interaction_data(bowl_pad,"toggle_bowl")
	var steel_bowl_pad:MeshInstance3D=host.box("SteelBowlPickup",Vector3(-1.45,0.98,-5.72),Vector3(0.8,0.12,0.48),Color("#d7d0c6")); host.interactable(steel_bowl_pad,"쇠그릇 집기 / 내려놓기"); host.interaction_data(steel_bowl_pad,"toggle_steel_bowl")
	var steel_bowl_resource:=load("res://assets/models/steel_bowl_check/Meshy_AI_쇠그릇_20261118_texture_fbx/Meshy_AI_쇠그릇_20261118_texture.fbx")
	if steel_bowl_resource is PackedScene:
		var world_steel_bowl:Node3D=(steel_bowl_resource as PackedScene).instantiate() as Node3D
		world_steel_bowl.name="SteelBowl"
		world_steel_bowl.position=Vector3(-1.45,1.16,-5.72)
		world_steel_bowl.scale=Vector3.ONE*0.28
		host.add_child(world_steel_bowl)
		host.world_steel_bowl=world_steel_bowl
		host.interactable(world_steel_bowl,"쇠그릇 집기")
		host.interaction_data(world_steel_bowl,"toggle_steel_bowl")
		host._add_model_collision(world_steel_bowl,"SteelBowlCollision")
		world_steel_bowl.set_meta("highlight_target",world_steel_bowl)
	var ladle_pad:MeshInstance3D=host.box("LadlePickup",Vector3(-2.45,0.98,-5.72),Vector3(0.8,0.12,0.48),Color("#d7d0c6")); host.interactable(ladle_pad,"국자 집기 / 내려놓기"); host.interaction_data(ladle_pad,"toggle_ladle")
	host.world_ladle=host._make_ladle_model("empty")
	if is_instance_valid(host.world_ladle):
		host.world_ladle.name="WorldLadle"
		host.world_ladle.position=Vector3(-2.45,1.10,-5.72)
		host.world_ladle.rotation_degrees=Vector3(0,0,90)
		host.world_ladle.scale=Vector3.ONE*0.34
		add_child(host.world_ladle)
	var editable_tongs:=get_node_or_null("EditableModels/KitchenTongsPickupModel") as Node3D
	host.world_tongs=editable_tongs
	if not host.world_tongs:
		host.world_tongs=host._add_world_tool_model("res://assets/models/kitchen_tongs.fbx",Vector3(-4.52,1.10,-5.72),Vector3(0,0,90),0.22,true)
	else:
		host._apply_tongs_material(host.world_tongs)
	var editable_bowl:=get_node_or_null("EditableModels/IngredientBowlPickupModel") as Node3D
	host.world_bowl=editable_bowl
	var bowl_stack_anchor:=Vector3(-3.48,1.09,-5.72)
	if is_instance_valid(editable_bowl):
		bowl_stack_anchor=editable_bowl.global_position
		editable_bowl.visible=false
	if not host.world_bowl:
		host.world_bowl=null
	else:
		host.world_bowl.visible=false
	host._build_bowl_stack(bowl_stack_anchor)
	# Keep the runtime models aligned with the editable pickup pads in each stage scene.
	if is_instance_valid(host.world_tongs):
		if editable_tongs:
			tongs_pad.global_position=host.world_tongs.global_position-Vector3(0,0.12,0)
		else:
			host.world_tongs.position=tongs_pad.global_position+Vector3(0,0.12,0)
	if is_instance_valid(host.world_bowl):
		if editable_bowl:
			bowl_pad.global_position=host.world_bowl.global_position-Vector3(0,0.11,0)
		else:
			host.world_bowl.position=bowl_pad.global_position+Vector3(0,0.11,0)
