extends Node3D

# Main scene controller.

const GAME_CONFIG = preload("res://assets/scripts/game_config.gd")

const SAVE_PATH := GAME_CONFIG.SAVE_PATH
const STAGE1_WALL_TILES_PATH := GAME_CONFIG.STAGE1_WALL_TILES_PATH
const STAGE1_FLOOR_TILES_PATH := GAME_CONFIG.STAGE1_FLOOR_TILES_PATH
const STAGE1_WALL_PLASTER_PATH := GAME_CONFIG.STAGE1_WALL_PLASTER_PATH
const STAGE1_STAINLESS_PATH := GAME_CONFIG.STAGE1_STAINLESS_PATH
const LADLE_MODEL_PATHS := {
	"empty": "res://assets/models/ladles/empty/empty.fbx",
	"broth": "res://assets/models/ladles/broth/broth.fbx",
	"malatang": "res://assets/models/ladles/malatang/malatang.fbx"
}
# The shop is one continuous room. Keep the first layout as the single
# runtime shell so a saved upgrade can never swap the player into a second
# disconnected scene. Stage 3 uses the same room with the expanded dining
# layout, including the single-seat row.
const UNIFIED_LAYOUT_PATH := GAME_CONFIG.UNIFIED_LAYOUT_PATH
const STAGE3_LAYOUT_PATH := GAME_CONFIG.STAGE3_LAYOUT_PATH

const INGREDIENTS := [
	["\uC219\uC8FC", Color("#f09a78")],
	["\uCCAD\uACBD\uCC44", Color("#55a95b")],
	["\uC54C\uBC30\uAE30\uBC30\uCD94", Color("#d8e87b")],
	["\uAC74\uB450\uBD80", Color("#e6bd62")],
	["\uBAA9\uC774\uBC84\uC12F", Color("#e8d7a7")],
	["\uD478\uC8FC", Color("#59372d")],
	["\uC911\uAD6D\uB2F9\uBA74", Color("#eee6ca")],
	["\uBD84\uBAA8\uC790", Color("#f2e7b5")],
	["\uC0C8\uC6B0\uC644\uC790", Color("#d9e5e5")],
	["\uD301\uC774\uBC84\uC12F", Color("#f4ece7")],
	["\uD53C\uC26C\uBCFC", Color("#bd503d")],
	["\uC18C\uC2DC\uC9C0", Color("#9d4540")]
]

var info_label: Label
var game_clock_label: Label
var prompt_label: Label
var prompt_mouse_icon: TextureRect
var prompt_background: Panel
var focused_interaction: Node
var camera: Camera3D
var monitor_camera_original_transform: Transform3D
var monitor_camera_original_rotation := Vector3.ZERO
var monitor_camera_original_fov := 75.0
var monitor_player_original_transform: Transform3D
var monitor_camera_tween: Tween
var monitor_player_tween: Tween
var monitor_camera_focused := false
var order_panel: PanelContainer
var monitor_backdrop: ColorRect
var order_list: VBoxContainer
var store_status_label: Label
var monitor_message_label: Label
var monitor_message_tween: Tween
var current_order_label: Label
var order_receipt: PanelContainer
var receipt_toggle_button: Button
var receipt_open := false
var receipt_key_was_down := false
var receipt_tween: Tween
var reset_confirmation: ConfirmationDialog
var next_day_button: Button
var next_day_confirmation: ConfirmationDialog
var basket_label: Label
var result_label: Label
var orders: Array[Dictionary] = []
var next_delivery_order_id := 1
var pending_order_ui_tick := 0.0
var current_order: Dictionary = {}
var basket: Array[String] = []
var selected_spice := 0
var cooked_food: Dictionary = {}
var money := 25000
var rating := 3.5
var completed_orders := 0
var cooking := false
var remaining_time := 0.0
var stock: Dictionary = {}
var purchase_cart: Dictionary = {}
var purchase_cart_packaging := 0
var purchase_cart_broth := 0
var packaging := 50
var broth_stock_packs := 1
var broth_servings := 0
var broth_making := false
var broth_water_added := false
var broth_stock_added := false
var broth_base_added := false
var broth_liquid: MeshInstance3D
var broth_liquid_base_scale := Vector3.ONE
var broth_stock_model: Node3D
var broth_stock_open_model: Node3D
var held_broth_stock_model: Node3D
var held_broth_stock_open_model: Node3D
var has_broth_stock_pack := false
var broth_stock_pack_open := false
var broth_stock_open_in_world := false
var broth_pot_model: Node3D
var broth_pot_filled_model: Node3D
var carried_broth_pot_model: Node3D
var broth_pot_interaction: MeshInstance3D
var broth_pot_drop_zone: MeshInstance3D
var prep_table_place: MeshInstance3D
var broth_pot_home_transform := Transform3D.IDENTITY
var has_broth_pot := false
var broth_water_stream: MeshInstance3D
var broth_water_stream_tween: Tween
var sink_water_stream: MeshInstance3D
var sink_water_stream_tween: Tween
var sink_water_particles: GPUParticles3D
var broth_steam: GPUParticles3D
var broth_boil_tween: Tween
var cooking_flame: Node3D
var cooking_flame_light: OmniLight3D
var cooking_flame_tween: Tween
var broth_progress_bar: ProgressBar
var broth_progress_label: Label
var broth_world_progress_label: Label3D
var monitor_mode := "orders"
var day := 1
var daily_sales := 0
var daily_target := 30000
var daily_material_cost := 0
var daily_completed_orders := 0
var daily_rating_total := 0.0
var pending_upgrades: Array[String] = []
var upgrade_levels := {"stock":0,"cooking":0,"movement":0}
var dining_unlocked := false
var store_stage := 1
var active_customer: CharacterBody3D
var customer_manager
var save_manager
var order_manager
var cooking_manager
var day_manager
var economy_manager
var service_manager
var interaction_manager
var carrying_manager
var broth_manager
var ui_manager
var ingredient_manager
var courier_manager
var world_manager
var tutorial_manager
var placement_manager
var asset_material_manager
var player_visual_manager
var manager_registry
var layout_manager
var game_clock_manager
var game_loop_manager
var lifecycle_manager
var customer_order: Dictionary = {}
var active_customer_table_position := Vector3.ZERO
var pending_customer_payment := 0
var pending_customer_stars := 0.0
var customer_spawn_timer := 4.0
var customer_status_label: Label
var fade_overlay: ColorRect
var next_customer_table := 0
var held_tools: Node3D
var held_collision_area: Area3D
var held_safe_player_position:=Vector3.ZERO
var held_collision_was_blocked:=false
var held_preview_outline: MeshInstance3D
var held_preview_material: StandardMaterial3D
var held_preview_blocked:=false
var held_placement_preview: Node3D
var held_preview_source: Node3D
var held_place_rotation_y:=0.0
var held_tongs: Node3D
var held_bowl: Node3D
var held_ladle: Node3D
var world_ladle: Node3D
var serving_bowl_view: Node3D
var food_tray_view: Node3D
var food_tray_world: Node3D
var has_food_tray:=false
var delivery_container_view: Node3D
var placed_serving_bowl: Node3D
var placed_food_tray: Node3D
var tongs_hand: Node3D
var bowl_hand: Node3D
var right_hand_attachment: BoneAttachment3D
var left_hand_attachment: BoneAttachment3D
var player_skeleton: Skeleton3D
var player_body: CharacterBody3D
var player_arms_visible := true
var player_body_hidden := true
var player_animation_player: AnimationPlayer
var player_walking_animation: StringName
var player_was_moving := false
var world_tongs: Node3D
var world_bowl: Node3D
var bowl_stack_root: Node3D
var bowl_stack_models: Array[Node3D]=[]
var held_bowl_stack_visuals: Array[Node3D]=[]
var world_steel_bowl: Node3D
var held_steel_bowl: Node3D
var has_steel_bowl := false
var held_basket_items: Node3D
var has_tongs := false
var has_bowl := false
var held_bowl_count := 0
var has_ladle := false
var ladle_state := "empty" # empty, broth, malatang
var cooking_pot_broth_added := false
var highlighted_meshes: Array[MeshInstance3D] = []
var highlighted_target: Node
var delivery_courier: Node3D
var courier_package: Node3D
var courier_ready := false
var courier_moving := false
var courier_tween: Tween
var courier_wait_seconds := 0.0
var courier_queue_visuals: Array[Node3D] = []
var courier_queue_tweens: Array[Tween] = []
var last_clock_minute := -1
var auto_close_day := 0
var tutorial_seen := false
var tutorial_active := false
var tutorial_overlay: CanvasLayer
var tutorial_title: Label
var tutorial_body: Label
var tutorial_button: Button
var tutorial_step := 0
var tutorial_quest_panel: PanelContainer
var tutorial_quest_label: Label
var tutorial_quest_last_text := ""
var tutorial_delivery_done := false

const COURIER_ENTRANCE := GAME_CONFIG.COURIER_ENTRANCE
const COURIER_WAITING := GAME_CONFIG.COURIER_WAITING
const COURIER_QUEUE_POSITIONS := GAME_CONFIG.COURIER_QUEUE_POSITIONS
const CUSTOMER_PAYMENT_POSITION := GAME_CONFIG.CUSTOMER_PAYMENT_POSITION
const CUSTOMER_EXIT_POSITION := GAME_CONFIG.CUSTOMER_EXIT_POSITION

# ??????諛몄カ??轅붽틓????洹ｋ마???????遺얘턁?????????遺얜??????????꾩룆梨띰쭕???????Β????????????? Vector3(x, y, z)?????y??????ル뭽?? ?????釉랁닑???筌뤾스????????嶺?罹??
const GAS_STOVE_POSITION := GAME_CONFIG.GAS_STOVE_POSITION
const COOKING_POT_POSITION := GAME_CONFIG.COOKING_POT_POSITION
const BROTH_POT_POSITION := GAME_CONFIG.BROTH_POT_POSITION
const WRONG_TABLE_PENALTY := GAME_CONFIG.WRONG_TABLE_PENALTY
const OPENING_HOUR := GAME_CONFIG.OPENING_HOUR
const CLOSING_HOUR := GAME_CONFIG.CLOSING_HOUR
const GAME_MINUTES_PER_REAL_MINUTE := GAME_CONFIG.GAME_MINUTES_PER_REAL_MINUTE
var game_clock_minutes: float = 10.0*60.0

func _is_shop_open() -> bool:
	if is_instance_valid(lifecycle_manager): return lifecycle_manager.is_shop_open()
	return false

func _game_clock_text() -> String:
	if is_instance_valid(lifecycle_manager): return lifecycle_manager.clock_text()
	return "00:00"

func _ready() -> void:
	manager_registry=load("res://assets/scripts/manager_registry.gd").new()
	manager_registry.name="ManagerRegistry"
	add_child(manager_registry)
	manager_registry.setup(self,INGREDIENTS,OPENING_HOUR,CUSTOMER_EXIT_POSITION)
	for ingredient in INGREDIENTS:
		stock[str(ingredient[0])] = 10
	_load_game()
	if not tutorial_seen and broth_stock_packs<=0:
		broth_stock_packs=1
	_load_stage_layout()
	_build_world()
	_apply_store_structure()
	_apply_upgrade_effects()
	_build_ui()
	_build_tutorial_quest_ui()
	if not tutorial_seen: _start_tutorial_quests()
	ui_manager.show_start_menu()

func _load_stage_layout() -> void:
	if is_instance_valid(layout_manager):
		layout_manager.load_stage_layout()
		if is_instance_valid(world_manager): world_manager.remove_obsolete_kitchen_sight_barriers()
		return
	return
	# ??????????????????????γ볥걙????????諛몃마嶺뚮??????????????????? ??????????꾨굴????????????嶺뚮씮??????볧꼤????? ?????????????怨몄）.
	# ???????怨뺤른??????????熬곣벀嫄?????꾤뙴???????????대첐?????????????諛몄カ??轅붽틓????洹ｋ마?????????????????????レ쑓??? ??????????????????꾩룆梨띰쭕????????ル뭽???????ル뭸????????猷멥늾???????????怨몄）.

func _notification(what: int) -> void:
	if is_instance_valid(lifecycle_manager): lifecycle_manager.handle_notification(what)

func _save_game(show_message := true) -> void:
	if is_instance_valid(lifecycle_manager): lifecycle_manager.save_game(show_message)

func _load_game() -> void:
	if is_instance_valid(lifecycle_manager): lifecycle_manager.load_game()
func mat(color: Color, emission := Color.BLACK) -> StandardMaterial3D:
	if is_instance_valid(world_manager): return world_manager.make_material(color,emission)
	var m:=StandardMaterial3D.new(); m.albedo_color=color; return m

func _add_model_collision(root: Node3D, collision_name: String = "WorldCollision") -> void:
	if is_instance_valid(world_manager):
		world_manager.add_model_collision(root,collision_name)
		return
	# ?????1??????????????耀??怨뚮뼺獒뺣폍???????MeshInstance3D ????????????????쎛 ????猷맣㎫몭???????遺얘턁?????????遺얜???????????饔낅떽???????
func box(node_name: String, pos: Vector3, size: Vector3, color: Color, parent: Node = self, collision := true) -> MeshInstance3D:
	if is_instance_valid(world_manager): return world_manager.make_box(node_name,pos,size,color,parent,collision)
	return null

func cylinder(node_name: String, pos: Vector3, radius: float, height: float, color: Color, parent: Node = self, collision := true) -> MeshInstance3D:
	if is_instance_valid(world_manager): return world_manager.make_cylinder(node_name,pos,radius,height,color,parent,collision)
	return null

func interactable(node: Node3D, label: String) -> void:
	if is_instance_valid(world_manager): world_manager.register_interactable(node,label)

func interaction_data(node: Node3D, type: String, value: Variant = null) -> void:
	if is_instance_valid(world_manager): world_manager.register_interaction_data(node,type,value)

func _set_broth_stock_source_enabled(enabled: bool) -> void:
	if is_instance_valid(broth_manager): broth_manager.set_stock_source_enabled(enabled)

func _tutorial_allows_interaction(type: String) -> bool:
	return interaction_manager.tutorial_allows_interaction(type)

func _find_nearby_interaction(origin: Vector3, forward: Vector3) -> Node:
	return interaction_manager.find_nearby_interaction(origin,forward)

func _build_world() -> void:
	if is_instance_valid(world_manager): world_manager.build_world()
func _add_player_character_model(player: CharacterBody3D) -> void:
	player_visual_manager.add_player_character_model(player)
func _set_player_arms_visible(should_show: bool) -> void:
	if not player_skeleton or player_arms_visible==should_show: return
	player_arms_visible=should_show
	if should_show: _pose_player_arms_for_tools()
	for bone_name in [&"mixamorig_LeftArm",&"mixamorig_RightArm"]:
		var bone_index:=player_skeleton.find_bone(bone_name)
		if bone_index<0: continue
		player_skeleton.set_bone_pose_scale(bone_index,Vector3.ONE if should_show else Vector3.ONE*0.001)
		if not should_show:
			var hidden_pose:=player_skeleton.get_bone_global_pose(bone_index)
			hidden_pose.basis=hidden_pose.basis.scaled(Vector3.ONE*0.001)
			player_skeleton.set_bone_global_pose_override(bone_index,hidden_pose,1.0,true)

func _update_player_animation() -> void:
	if not is_instance_valid(player_body) or not player_skeleton: return
	var moving:=Vector2(player_body.velocity.x,player_body.velocity.z).length_squared()>0.04
	if moving==player_was_moving: return
	player_was_moving=moving
	if moving:
		# Walking must control the complete rig, so remove the stationary cooking pose.
		player_skeleton.clear_bones_global_pose_override()
		player_arms_visible=true
		for bone_name in [&"mixamorig_LeftArm",&"mixamorig_RightArm"]:
			var bone_index:=player_skeleton.find_bone(bone_name)
			if bone_index>=0: player_skeleton.set_bone_pose_scale(bone_index,Vector3.ONE)
		if player_animation_player and not player_walking_animation.is_empty():
			player_animation_player.play(player_walking_animation,0.15,1.0)
	else:
		if player_animation_player: player_animation_player.stop()
		if has_tongs or has_bowl or has_steel_bowl:
			_pose_player_arms_for_tools()
			player_arms_visible=true
		else:
			player_arms_visible=true
			_set_player_arms_visible(false)

func _basis_with_y_axis(direction: Vector3, reference: Vector3=Vector3.FORWARD) -> Basis:
	var y_axis:=direction.normalized()
	var x_axis:=reference.cross(y_axis).normalized()
	if x_axis.length_squared()<0.01: x_axis=Vector3.RIGHT
	var z_axis:=x_axis.cross(y_axis).normalized()
	return Basis(x_axis,y_axis,z_axis).orthonormalized()

func _pose_player_arms_for_tools() -> void:
	if not player_skeleton: return
	var poses:=[
		[&"mixamorig_LeftArm",Vector3(0.176,1.378,-0.043),Vector3(0.31,1.15,0.18)],
		[&"mixamorig_LeftForeArm",Vector3(0.31,1.15,0.18),Vector3(0.25,1.08,0.48)],
		[&"mixamorig_LeftHand",Vector3(0.25,1.08,0.48),Vector3(0.22,1.05,0.64)],
		[&"mixamorig_RightArm",Vector3(-0.169,1.378,-0.043),Vector3(-0.31,1.15,0.18)],
		[&"mixamorig_RightForeArm",Vector3(-0.31,1.15,0.18),Vector3(-0.25,1.08,0.48)],
		[&"mixamorig_RightHand",Vector3(-0.25,1.08,0.48),Vector3(-0.22,1.05,0.64)]
	]
	for pose in poses:
		var bone_name: StringName=pose[0] as StringName
		var start: Vector3=pose[1] as Vector3
		var target: Vector3=pose[2] as Vector3
		var bone_index:=player_skeleton.find_bone(bone_name)
		if bone_index<0: continue
		var transform:=Transform3D(_basis_with_y_axis(target-start),start)
		player_skeleton.set_bone_global_pose_override(bone_index,transform,1.0,true)

func _apply_player_material(root: Node) -> void:
	var material:=StandardMaterial3D.new()
	material.albedo_texture=load("res://assets/models/player_character_rigged.png") as Texture2D
	material.normal_enabled=true
	material.normal_texture=load("res://assets/models/player_character_rigged_normal.png") as Texture2D
	material.metallic_texture=load("res://assets/models/player_character_rigged_metallic.png") as Texture2D
	material.roughness_texture=load("res://assets/models/player_character_rigged_roughness.png") as Texture2D
	material.roughness=0.75
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_overlay=material

func _add_order_monitor_model() -> void:
	var editable_model:=get_node_or_null("EditableModels/OrderMonitorModel") as Node3D
	# The stage scenes may already contain the monitor as a root-level editable
	# instance. Reuse it instead of spawning a second monitor at a hard-coded
	# position at runtime.
	if not is_instance_valid(editable_model):
		editable_model=get_node_or_null("OrderMonitorModel") as Node3D
	if is_instance_valid(editable_model):
		_apply_order_monitor_material(editable_model)
		_add_model_collision(editable_model,"OrderMonitorCollision")
		return
	var monitor_resource: Resource=load("res://assets/models/order_monitor.fbx")
	if not monitor_resource is PackedScene: return
	var monitor_model: Node3D=(monitor_resource as PackedScene).instantiate() as Node3D
	monitor_model.name="OrderMonitorModel"
	monitor_model.position=Vector3(6.55,1.48,-6.15)
	# ??遺얘턁?????????遺얜?????????濾?鶯??????????????????繹먮굞????????ル뭽?? ???????????????????????γ볥걙????????꾩룆梨띰쭕??縕????????諛몃마嶺뚮????????饔낅떽???????
	monitor_model.rotation_degrees=Vector3(0,180,0)
	monitor_model.scale=Vector3.ONE*0.48
	add_child(monitor_model)
	_apply_order_monitor_material(monitor_model)
	_add_model_collision(monitor_model,"OrderMonitorCollision")

func _add_gas_stove_model(world_position: Vector3, model_scale: float = 0.72) -> void:
	var editable_model:=get_node_or_null("EditableModels/CommercialGasStoveModel") as Node3D
	if is_instance_valid(editable_model):
		_apply_gas_stove_material(editable_model)
		_add_model_collision(editable_model,"GasStoveCollision")
		return
	var stove_resource: Resource=load("res://assets/models/gas_stove.fbx")
	if not stove_resource is PackedScene: return
	var stove_model: Node3D=(stove_resource as PackedScene).instantiate() as Node3D
	stove_model.name="CommercialGasStoveModel"
	stove_model.position=world_position
	stove_model.rotation_degrees=Vector3(0,180,0)
	stove_model.scale=Vector3.ONE*model_scale
	add_child(stove_model)
	_apply_gas_stove_material(stove_model)
	_add_model_collision(stove_model,"GasStoveCollision")

func _apply_gas_stove_material(root: Node) -> void:
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

func _add_sink_model(world_position: Vector3, model_scale: float=0.72) -> Node3D:
	var editable_model:=get_node_or_null("EditableModels/KitchenSinkModel_EditorPreview") as Node3D
	if not is_instance_valid(editable_model):
		editable_model=get_node_or_null("EditableModels/KitchenSinkModel") as Node3D
	if is_instance_valid(editable_model):
		_apply_sink_material(editable_model)
		_add_model_collision(editable_model,"SinkCollision")
		return editable_model
	var resource: Resource=load("res://assets/models/sink/sink.fbx")
	if not resource is PackedScene: return null
	var sink:Node3D=(resource as PackedScene).instantiate() as Node3D
	sink.name="KitchenSinkModel"
	sink.position=world_position
	sink.rotation_degrees=Vector3(0,180,0)
	sink.scale=Vector3.ONE*model_scale
	add_child(sink)
	_apply_sink_material(sink)
	_add_model_collision(sink,"SinkCollision")
	return sink

func _apply_sink_material(root: Node) -> void:
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

func _add_broth_pot_model(world_position: Vector3, model_scale: float=0.62) -> Node3D:
	var editable_pot:=get_node_or_null("EditableModels/BrothPotModel_EditorPreview") as Node3D
	if is_instance_valid(editable_pot):
		editable_pot.add_to_group("placeable_object")
		editable_pot.set_meta("place_radius",0.72)
		_apply_broth_pot_material(editable_pot)
		_add_model_collision(editable_pot,"BrothPotCollision")
		return editable_pot
	var resource: Resource=load("res://assets/models/broth_pot/broth_pot.fbx")
	if not resource is PackedScene: return null
	var pot:Node3D=(resource as PackedScene).instantiate() as Node3D
	pot.name="BrothPotModel"
	pot.position=world_position
	pot.rotation_degrees=Vector3(0,180,0)
	pot.scale=Vector3.ONE*model_scale
	add_child(pot)
	pot.add_to_group("placeable_object")
	pot.set_meta("place_radius",0.72)
	_apply_broth_pot_material(pot)
	return pot

func _apply_broth_pot_material(pot: Node) -> void:
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

func _add_broth_stock_model(path: String, node_name: String, world_position: Vector3, model_scale: float) -> Node3D:
	var resource: Resource=load(path)
	if not resource is PackedScene: return null
	var model: Node3D=(resource as PackedScene).instantiate() as Node3D
	if not is_instance_valid(model): return null
	model.name=node_name
	model.position=world_position
	# FBX ???????????????????諛몃마??潁뺛깺苡???????????饔낅떽?????? 180????????ル뭽?????????? ??????? ????????????룸㎗???????????????怨뺤른??????怨쀫뮡?壤굿??곸읆????ル폆???遺얘턁?????????
	model.rotation_degrees=Vector3.ZERO
	model.scale=Vector3.ONE*model_scale
	add_child(model)
	# Keep the FBX-imported materials and UVs intact. Replacing the material
	# here causes the placed package texture to become fragmented or tiled.
	return model

func _add_malatang_pot_model(world_position: Vector3) -> Node3D:
	var editable_model:=get_node_or_null("EditableModels/MalatangCookingPotModel") as Node3D
	if is_instance_valid(editable_model):
		editable_model.add_to_group("placeable_object")
		editable_model.set_meta("place_radius",0.72)
		_apply_malatang_pot_material(editable_model)
		_add_model_collision(editable_model,"MalatangPotCollision")
		return editable_model
	var pot_resource: Resource=load("res://assets/models/malatang_pot.fbx")
	var pot_model: Node3D=Node3D.new()
	pot_model.name="MalatangCookingPotModel"
	if not pot_resource is PackedScene: return pot_model
	pot_model=(pot_resource as PackedScene).instantiate() as Node3D
	pot_model.name="MalatangCookingPotModel"
	pot_model.position=world_position
	pot_model.rotation_degrees=Vector3(0,180,0)
	pot_model.scale=Vector3.ONE*0.62
	add_child(pot_model)
	pot_model.add_to_group("placeable_object")
	pot_model.set_meta("place_radius",0.72)
	_apply_malatang_pot_material(pot_model)
	_add_model_collision(pot_model,"MalatangPotCollision")
	return pot_model

func _apply_malatang_pot_material(root: Node) -> void:
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

func _instantiate_serving_bowl() -> Node3D:
	var bowl_resource: Resource=load("res://assets/models/serving_bowl.fbx")
	if not bowl_resource is PackedScene: return null
	var bowl_model: Node3D=(bowl_resource as PackedScene).instantiate() as Node3D
	_apply_serving_bowl_material(bowl_model)
	return bowl_model

func _add_world_serving_bowl(world_position: Vector3) -> Node3D:
	var bowl_model:=_instantiate_serving_bowl()
	if not is_instance_valid(bowl_model): return null
	bowl_model.name="PlacedServingBowl"
	bowl_model.position=world_position
	bowl_model.rotation_degrees=Vector3.ZERO
	bowl_model.scale=Vector3.ONE*0.22
	add_child(bowl_model)
	return bowl_model

func _create_food_tray_visual(tray_name: String) -> Node3D:
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

func _add_world_food_tray(world_position: Vector3) -> Node3D:
	var tray:=_create_food_tray_visual("PlacedFoodTray")
	tray.global_position=world_position-Vector3(0,0.10,0)
	add_child(tray)
	return tray

func _spawn_finished_food_tray() -> void:
	if is_instance_valid(food_tray_world): food_tray_world.queue_free()
	food_tray_world=_create_food_tray_visual("FinishedFoodTray")
	var surface_y:=_placement_surface_y(prep_table_place) if is_instance_valid(prep_table_place) else 1.60
	var tray_position:=prep_table_place.global_position if is_instance_valid(prep_table_place) else Vector3(4.6,surface_y,-9.0)
	food_tray_world.global_position=Vector3(tray_position.x,surface_y+0.05,tray_position.z)
	add_child(food_tray_world)
	var food_bowl:=_instantiate_serving_bowl()
	if is_instance_valid(food_bowl):
		food_bowl.name="FoodOnTray"
		food_bowl.position=Vector3(0,0.16,0)
		food_bowl.scale=Vector3.ONE*0.22
		food_tray_world.add_child(food_bowl)
	var interaction:=box("FinishedFoodTrayInteraction",Vector3(0,0.12,0),Vector3(1.08,0.24,0.76),Color.WHITE,food_tray_world,true)
	interaction.visible=false
	interactable(interaction,"Finished food tray")
	interaction_data(interaction,"food_tray")
	food_tray_world.visible=true

func _apply_serving_bowl_material(root: Node) -> void:
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color.WHITE
	var color_texture:=load("res://assets/models/serving_bowl.png") as Texture2D
	if color_texture: material.albedo_texture=color_texture
	var normal_texture:=load("res://assets/models/serving_bowl_normal.png") as Texture2D
	if normal_texture:
		material.normal_enabled=true
		material.normal_texture=normal_texture
	var metallic_texture:=load("res://assets/models/serving_bowl_metallic.png") as Texture2D
	if metallic_texture:
		material.metallic=1.0
		material.metallic_texture=metallic_texture
	var roughness_texture:=load("res://assets/models/serving_bowl_roughness.png") as Texture2D
	if roughness_texture:
		material.roughness=1.0
		material.roughness_texture=roughness_texture
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_overlay=material

func _instantiate_delivery_container() -> Node3D:
	var resource: Resource=load("res://assets/models/delivery_container.fbx")
	if not resource is PackedScene: return null
	var model: Node3D=(resource as PackedScene).instantiate() as Node3D
	_apply_delivery_container_material(model)
	return model

func _apply_delivery_container_material(root: Node) -> void:
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color.WHITE
	var color_texture:=load("res://assets/models/delivery_container_albedo.png") as Texture2D
	if color_texture: material.albedo_texture=color_texture
	var normal_texture:=load("res://assets/models/delivery_container_normal.png") as Texture2D
	if normal_texture:
		material.normal_enabled=true
		material.normal_texture=normal_texture
	var metallic_texture:=load("res://assets/models/delivery_container_metallic.png") as Texture2D
	if metallic_texture:
		material.metallic=1.0
		material.metallic_texture=metallic_texture
	var roughness_texture:=load("res://assets/models/delivery_container_roughness.png") as Texture2D
	if roughness_texture:
		material.roughness=1.0
		material.roughness_texture=roughness_texture
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_overlay=material

func _add_child_customer_model(customer: Node3D) -> bool:
	var child_resource: Resource=load("res://assets/models/child_customer/child_customer.fbx")
	if not child_resource is PackedScene:
		return false
	var child_model: Node3D=(child_resource as PackedScene).instantiate() as Node3D
	child_model.name="ChildCustomerModel"
	# FBX ???????????諛몃마嶺뚮??????ル늉筌?????????꾩룆梨띰쭕????????????? ??????? ???????怨뺤른?????????? ??????嶺뚮ㅎ?????????諛몃마嶺뚮??????ル늉筌???????諛몃마嶺뚮??????????????????遺얘턁??????????????怨몄）.
	child_model.position=Vector3(0,-0.85,0)
	child_model.rotation_degrees=Vector3(0,180,0)
	child_model.scale=Vector3.ONE*1.08
	customer.add_child(child_model)
	_apply_child_customer_material(child_model)
	_import_child_sit_animation(child_model)
	_import_child_eating_animation(child_model)
	var seated_resource: Resource=load("res://assets/models/child_customer/seated_pose.fbx")
	if seated_resource is PackedScene:
		var seated_model: Node3D=(seated_resource as PackedScene).instantiate() as Node3D
		seated_model.name="SeatedChildCustomerModel"
		seated_model.position=Vector3(0,-1.30,-0.08)
		seated_model.rotation_degrees=Vector3(0,180,0)
		seated_model.scale=Vector3.ONE*1.08
		seated_model.visible=false
		customer.add_child(seated_model)
		_apply_child_customer_material(seated_model)
	return true

func _import_child_sit_animation(child_model: Node3D) -> void:
	var animation_resource: Resource=load("res://assets/models/child_customer/seated_animation.fbx")
	if not animation_resource is PackedScene: return
	var animation_scene: Node3D=(animation_resource as PackedScene).instantiate() as Node3D
	var source_player:=_find_animation_player(animation_scene)
	var target_player:=_find_animation_player(child_model)
	if not source_player or not target_player:
		animation_scene.free()
		return
	var library:=target_player.get_animation_library("")
	if not library:
		library=AnimationLibrary.new()
		target_player.add_animation_library("",library)
	var selected_clip: Animation
	for animation_name in source_player.get_animation_list():
		var lowered:=String(animation_name).to_lower()
		if lowered=="reset" or lowered.ends_with("/reset"): continue
		var clip:=source_player.get_animation(animation_name)
		if clip and (selected_clip==null or lowered.contains("sit") or lowered.contains("stand")):
			selected_clip=clip
	if selected_clip:
		if library.has_animation("StandToSit"):
			library.remove_animation("StandToSit")
		library.add_animation("StandToSit",selected_clip.duplicate())
	animation_scene.free()

func _import_child_eating_animation(child_model: Node3D) -> void:
	var animation_resource: Resource=load("res://assets/models/child_customer/customer_eating_animation.fbx")
	if not animation_resource is PackedScene: return
	var animation_scene: Node3D=(animation_resource as PackedScene).instantiate() as Node3D
	var source_player:=_find_animation_player(animation_scene)
	var target_player:=_find_animation_player(child_model)
	if not source_player or not target_player:
		animation_scene.free()
		return
	var library:=target_player.get_animation_library("")
	if not library:
		library=AnimationLibrary.new()
		target_player.add_animation_library("",library)
	var selected_clip: Animation
	for animation_name in source_player.get_animation_list():
		var lowered:=String(animation_name).to_lower()
		if lowered=="reset" or lowered.ends_with("/reset"): continue
		var clip:=source_player.get_animation(animation_name)
		if clip and (selected_clip==null or lowered.contains("eat") or lowered.contains("food")):
			selected_clip=clip
	if selected_clip:
		if library.has_animation("Eat"): library.remove_animation("Eat")
		var eat_clip:Animation=selected_clip.duplicate()
		eat_clip.loop_mode=Animation.LOOP_LINEAR
		library.add_animation("Eat",eat_clip)
	animation_scene.free()

func _apply_child_customer_material(root: Node) -> void:
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color.WHITE
	var color_texture:=load("res://assets/models/child_customer/child_customer.png") as Texture2D
	if color_texture: material.albedo_texture=color_texture
	var normal_texture:=load("res://assets/models/child_customer/child_customer_normal.png") as Texture2D
	if normal_texture:
		material.normal_enabled=true
		material.normal_texture=normal_texture
	var metallic_texture:=load("res://assets/models/child_customer/child_customer_metallic.png") as Texture2D
	if metallic_texture:
		material.metallic=1.0
		material.metallic_texture=metallic_texture
	var roughness_texture:=load("res://assets/models/child_customer/child_customer_roughness.png") as Texture2D
	if roughness_texture:
		material.roughness=1.0
		material.roughness_texture=roughness_texture
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_overlay=material

func _add_customer_spoon(customer: Node3D) -> void:
	var spoon_resource: Resource=load("res://assets/models/spoon.fbx")
	if not spoon_resource is PackedScene: return
	var spoon: Node3D=(spoon_resource as PackedScene).instantiate() as Node3D
	spoon.name="CustomerSpoon"
	spoon.position=Vector3(0.18,0.62,-0.30)
	spoon.rotation_degrees=Vector3(90,0,0)
	spoon.scale=Vector3.ONE*0.075
	# ?????????????????꾨굴???????????◈?볝럸????????꾩룆梨띰쭕??????????????????????????怨뺤른?????????? ?????????????怨몄）.
	spoon.visible=false
	customer.add_child(spoon)
	_apply_spoon_material(spoon)

func _apply_spoon_material(root: Node) -> void:
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color.WHITE
	var color_texture:=load("res://assets/models/spoon.png") as Texture2D
	if color_texture: material.albedo_texture=color_texture
	var normal_texture:=load("res://assets/models/spoon_normal.png") as Texture2D
	if normal_texture:
		material.normal_enabled=true
		material.normal_texture=normal_texture
	var metallic_texture:=load("res://assets/models/spoon_metallic.png") as Texture2D
	if metallic_texture:
		material.metallic=1.0
		material.metallic_texture=metallic_texture
	var roughness_texture:=load("res://assets/models/spoon_roughness.png") as Texture2D
	if roughness_texture:
		material.roughness=1.0
		material.roughness_texture=roughness_texture
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_overlay=material

func _add_stainless_table_model(world_position: Vector3) -> Node3D:
	var editable_model:=get_node_or_null("EditableModels/StainlessPrepTableModel") as Node3D
	if is_instance_valid(editable_model):
		_apply_stainless_table_material(editable_model)
		_add_model_collision(editable_model,"PrepTableCollision")
		return editable_model
	var table_resource: Resource=load("res://assets/models/stainless_table.fbx")
	if not table_resource is PackedScene: return null
	var table_model: Node3D=(table_resource as PackedScene).instantiate() as Node3D
	table_model.name="StainlessPrepTableModel"
	table_model.position=world_position
	table_model.rotation_degrees=Vector3.ZERO
	table_model.scale=Vector3(1.18,0.92,0.98)
	add_child(table_model)
	_apply_stainless_table_material(table_model)
	_add_model_collision(table_model,"PrepTableCollision")
	return table_model

func _apply_stainless_table_material(root: Node) -> void:
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
	if metallic_texture:
		material.metallic=0.48
		material.metallic_texture=metallic_texture
	var roughness_texture:=load("res://assets/models/stainless_table_roughness.png") as Texture2D
	if roughness_texture:
		material.roughness=0.32
		material.roughness_texture=roughness_texture
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_overlay=material

func _add_spice_level_3_model(world_position: Vector3) -> Node3D:
	var editable_spice:=get_node_or_null("EditableModels/SpiceLevel3Editable") as Node3D
	if is_instance_valid(editable_spice):
		_apply_spice_level_material(editable_spice)
		return editable_spice
	var spice_resource: Resource=load("res://assets/models/spice_level_3.fbx")
	var spice_model: Node3D=Node3D.new()
	spice_model.name="SpiceLevel3Model"
	if spice_resource is PackedScene:
		spice_model=(spice_resource as PackedScene).instantiate() as Node3D
		spice_model.name="SpiceLevel3Model"
		spice_model.position=world_position
		# Turn the numbered/front side toward the back of the table.
		spice_model.rotation_degrees=Vector3(0,180,0)
		spice_model.scale=Vector3.ONE*0.30
		add_child(spice_model)
		_apply_spice_level_material(spice_model)
	return spice_model

func _apply_spice_level_material(root: Node) -> void:
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color.WHITE
	var color_texture:=load("res://assets/models/spice_level_3.png") as Texture2D
	if color_texture: material.albedo_texture=color_texture
	var normal_texture:=load("res://assets/models/spice_level_3_normal.png") as Texture2D
	if normal_texture:
		material.normal_enabled=true
		material.normal_texture=normal_texture
	var metallic_texture:=load("res://assets/models/spice_level_3_metallic.png") as Texture2D
	if metallic_texture:
		material.metallic=1.0
		material.metallic_texture=metallic_texture
	var roughness_texture:=load("res://assets/models/spice_level_3_roughness.png") as Texture2D
	if roughness_texture:
		material.roughness=1.0
		material.roughness_texture=roughness_texture
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_overlay=material

func _apply_order_monitor_material(root: Node) -> void:
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

func _build_broth_steam(pos: Vector3) -> void:
	broth_steam=GPUParticles3D.new()
	broth_steam.name="BrothSteam"
	broth_steam.position=pos
	broth_steam.amount=24
	broth_steam.lifetime=1.5
	broth_steam.emitting=false
	var process:=ParticleProcessMaterial.new()
	process.direction=Vector3(0,1,0)
	process.spread=22.0
	process.initial_velocity_min=0.45
	process.initial_velocity_max=0.9
	process.gravity=Vector3(0,0.12,0)
	process.scale_min=0.12
	process.scale_max=0.28
	broth_steam.process_material=process
	var quad:=QuadMesh.new()
	quad.size=Vector2(0.34,0.34)
	var steam_material:=StandardMaterial3D.new()
	steam_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	steam_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	steam_material.albedo_color=Color(0.92,0.95,0.95,0.32)
	steam_material.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
	quad.material=steam_material
	broth_steam.draw_pass_1=quad
	add_child(broth_steam)

func _build_cooking_flame(pos: Vector3) -> void:
	if is_instance_valid(cooking_manager):
		cooking_manager.build_flame(pos)
		return
	# ?????????レ쑓??????????꾩룆梨띰쭕????????ル뭽??????????⑤뜪????????????ル뭽???????遺얘턁????? ????????????????????????耀붾굝??????????????怨뺤른???????????????????꿔꺂???猷명ц땻??????諛몃마??潁뺛깺苡????饔낅떽???????
	# ??????????????꾩룆梨띰쭕?????????????????????レ쑓????????????怨뺤른?????????꾩룆梨띰쭕??縕????????????????????대첐??????嚥???癲?????????? ??????饔낅떽???????

func _set_cooking_flame_active(active: bool) -> void:
	if is_instance_valid(cooking_manager): cooking_manager.set_flame_active(active)

func _play_broth_pour(color: Color, wall_z: float = -7.5) -> void:
	# The old implementation spawned a yellow cylinder in front of the pot.
	# The downloaded filled-pot model is now the only visual state change.
	return

func _start_broth_boil_effect() -> void:
	if is_instance_valid(broth_manager): broth_manager.start_boil_effect()

func _stop_broth_boil_effect() -> void:
	if is_instance_valid(broth_manager): broth_manager.stop_boil_effect()

func _play_ladle_scoop_animation() -> void:
	if is_instance_valid(carrying_manager):
		carrying_manager.play_ladle_scoop_animation()
		return

func _create_courier_actor(actor_name: String) -> Node3D:
	return courier_manager.create_courier_actor(actor_name)
func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found:=_find_animation_player(child)
		if found:
			return found
	return null

func _configure_courier_animations(actor: Node3D, courier_model: Node3D) -> void:
	courier_manager.configure_courier_animations(actor,courier_model)
func _set_courier_walking(actor: Node3D, walking: bool) -> void:
	if is_instance_valid(courier_manager): courier_manager.set_walking(actor,walking)

func _align_courier_feet_to_floor(actor: Node3D, courier_model: Node3D) -> void:
	courier_manager.align_courier_feet_to_floor(actor,courier_model)
func _set_courier_status(actor: Node3D, text: String, color:=Color.WHITE) -> void:
	if is_instance_valid(courier_manager): courier_manager.set_status(actor,text,color)

func _set_courier_active(actor: Node3D, active: bool) -> void:
	if is_instance_valid(courier_manager): courier_manager.set_active(actor,active)

func _build_first_person_tools(camera_node: Camera3D) -> void:
	carrying_manager.build_first_person_tools(camera_node)
func _build_first_person_ladle(camera_node: Camera3D, tools: Node3D) -> void:
	if is_instance_valid(carrying_manager): carrying_manager.build_first_person_ladle(camera_node,tools)

func _build_first_person_hand(parent: Node3D, hand_name: String, hand_position: Vector3, hand_rotation: Vector3) -> Node3D:
	if is_instance_valid(carrying_manager): return carrying_manager.build_first_person_hand(parent,hand_name,hand_position,hand_rotation)
	return null

func _play_tool_pickup_animation(tool: Node3D, hand: Node3D) -> void:
	if is_instance_valid(carrying_manager): carrying_manager.play_tool_pickup_animation(tool,hand)

func _build_tool_pickup_station() -> void:
	carrying_manager.build_tool_pickup_station()
func _add_world_tool_model(path: String, world_position: Vector3, rotation: Vector3, model_scale: float, is_tongs: bool) -> Node3D:
	var resource: Resource=load(path)
	if not resource is PackedScene: return null
	var model: Node3D=(resource as PackedScene).instantiate() as Node3D
	model.position=world_position+Vector3(0,-0.18,0) if path.contains("dining_table") else world_position
	model.rotation_degrees=rotation
	model.scale=Vector3.ONE*model_scale
	add_child(model)
	if is_tongs: _apply_tongs_material(model)
	else: _apply_ingredient_bowl_material(model)
	return model

func _instantiate_empty_bowl() -> Node3D:
	var resource: Resource=load("res://assets/models/malatang_empty_bowl.fbx")
	if not resource is PackedScene: return null
	var model:Node3D=(resource as PackedScene).instantiate() as Node3D
	if is_instance_valid(model):
		_apply_empty_bowl_material(model)
	return model

func _build_bowl_stack(anchor: Vector3, count: int=5) -> void:
	if is_instance_valid(carrying_manager): carrying_manager.build_bowl_stack(anchor,count)

func _take_bowl_from_stack(take_all: bool=false) -> int:
	if is_instance_valid(carrying_manager): return carrying_manager.take_bowl_from_stack(take_all)
	return 0

func _refresh_held_bowl_stack_visual() -> void:
	for bowl in held_bowl_stack_visuals:
		if is_instance_valid(bowl): bowl.queue_free()
	held_bowl_stack_visuals.clear()
	if not has_bowl or held_bowl_count<=1 or not is_instance_valid(held_bowl): return
	for index in range(1,held_bowl_count):
		var bowl:=_instantiate_empty_bowl()
		if not is_instance_valid(bowl): continue
		bowl.name="HeldEmptyBowl_%d"%index
		# held_bowl????????꾩룆梨띰쭕???????????關?쒎첎????????????????????대첉?????雅?굛肄?????????濡ろ뜐筌????????癲됱빖???????ル맪???????關?쒎첎?嫄?濚밸쮦????????遺얘턁????傭?끆???嶺뚮?猷볠꽴???????怨뺤른??????怨쀫뮡?壤굿??곸읆????ル폆????饔낅떽???????
		bowl.position=Vector3(0.0,float(index)*0.60,0.0)
		bowl.rotation_degrees=Vector3.ZERO
		bowl.scale=Vector3.ONE
		held_bowl.add_child(bowl)
		held_bowl_stack_visuals.append(bowl)

func _apply_ingredient_bowl_material(root: Node) -> void:
	var metal:=_make_shared_steel_material()
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_overlay=metal

func _apply_empty_bowl_material(root: Node) -> void:
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

func _set_held_render_front(root: Node) -> void:
	if not is_instance_valid(root) or root.has_meta("held_render_front"): return
	root.set_meta("held_render_front",true)
	var meshes:Array[MeshInstance3D]=[]
	if root is MeshInstance3D: meshes.append(root as MeshInstance3D)
	for child in root.find_children("*","MeshInstance3D",true,false):
		meshes.append(child as MeshInstance3D)
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

func _update_held_tool_visibility() -> void:
	if is_instance_valid(carrying_manager): carrying_manager.update_visibility()

func _make_ladle_sprite(sprite_name: String, world_position: Vector3, pixel_size_value: float) -> Sprite3D:
	if is_instance_valid(carrying_manager): return carrying_manager.make_ladle_sprite(sprite_name,world_position,pixel_size_value)
	return null

func _make_ladle_model(state: String) -> Node3D:
	if is_instance_valid(carrying_manager): return carrying_manager.make_ladle_model(state)
	return null

func _apply_ladle_material(root: Node, state: String) -> void:
	if is_instance_valid(carrying_manager):
		carrying_manager.apply_ladle_material(root,state)
	return

func _refresh_held_ladle_model() -> void:
	if is_instance_valid(carrying_manager): carrying_manager.refresh_held_ladle_model()

func _set_ladle_state(next_state: String) -> void:
	ladle_state=next_state
	_refresh_held_ladle_model()

func _empty_ladle() -> void:
	_set_ladle_state("empty")

func _update_player_arm_visibility() -> void:
	if is_instance_valid(player_visual_manager):
		player_visual_manager.update_arm_visibility()
		return
	if not player_skeleton: return
	# Keep the real left arm visible while carrying the bowl.
	var left_visible:=player_was_moving or has_bowl or has_steel_bowl
	var right_visible:=player_was_moving or has_tongs or has_steel_bowl
	_set_arm_chain_visible("Left",left_visible)
	_set_arm_chain_visible("Right",right_visible)

func _set_arm_chain_visible(side: String, should_show: bool) -> void:
	if not player_skeleton: return
	for bone_index in range(player_skeleton.get_bone_count()):
		var bone_name:=str(player_skeleton.get_bone_name(bone_index))
		if not bone_name.contains(side): continue
		if not (bone_name.contains("Arm") or bone_name.contains("Hand") or bone_name.contains("Finger") or bone_name.contains("Thumb")): continue
		_set_single_arm_visible(player_skeleton.get_bone_name(bone_index),should_show)

func _set_single_arm_visible(bone_name: StringName, should_show: bool) -> void:
	if not player_skeleton: return
	var bone_index:=player_skeleton.find_bone(bone_name)
	if bone_index<0: return
	if should_show:
		player_skeleton.set_bone_pose_scale(bone_index,Vector3.ONE)
		# Remove a previous hidden-arm override so animation can control the arm again.
		var visible_pose:=player_skeleton.get_bone_global_pose(bone_index)
		player_skeleton.set_bone_global_pose_override(bone_index,visible_pose,0.0,false)
	else:
		# AnimationPlayer can overwrite local scale, therefore hide through a global pose override.
		var hidden_pose:=player_skeleton.get_bone_global_pose(bone_index)
		hidden_pose.basis=hidden_pose.basis.orthonormalized().scaled(Vector3.ONE*0.001)
		player_skeleton.set_bone_global_pose_override(bone_index,hidden_pose,1.0,true)

func _apply_tongs_material(root: Node) -> void:
	if is_instance_valid(asset_material_manager):
		asset_material_manager.apply_tongs_material(root)
	return

func _update_held_tool_stabilization() -> void:
	if is_instance_valid(player_visual_manager):
		player_visual_manager.stabilize_held_bowl()
	return

func _make_shared_steel_material() -> StandardMaterial3D:
	if is_instance_valid(asset_material_manager): return asset_material_manager.make_shared_steel_material()
	return StandardMaterial3D.new()

func _add_bean_sprouts_model(parent: Node3D, model_position: Vector3) -> Node3D:
	if is_instance_valid(ingredient_manager): return ingredient_manager.add_bean_sprouts_model(parent,model_position)
	return null

func _add_tofu_skin_model(parent: Node3D, model_position: Vector3) -> Node3D:
	if is_instance_valid(ingredient_manager): return ingredient_manager.add_tofu_skin_model(parent,model_position)
	return null

func _add_shrimp_ball_model(parent: Node3D, model_position: Vector3) -> Node3D:
	if is_instance_valid(ingredient_manager): return ingredient_manager.add_shrimp_ball_model(parent,model_position)
	return null

func _add_sausage_model(parent: Node3D, model_position: Vector3) -> Node3D:
	if is_instance_valid(ingredient_manager): return ingredient_manager.add_sausage_model(parent,model_position)
	return null

func _add_bok_choy_model(parent: Node3D, model_position: Vector3) -> Node3D:
	if is_instance_valid(ingredient_manager): return ingredient_manager.add_bok_choy_model(parent,model_position)
	return null

func _add_wood_ear_model(parent: Node3D, model_position: Vector3) -> Node3D:
	if is_instance_valid(ingredient_manager): return ingredient_manager.add_wood_ear_model(parent,model_position)
	return null

func _add_glass_noodle_model(parent: Node3D, model_position: Vector3) -> Node3D:
	if is_instance_valid(ingredient_manager): return ingredient_manager.add_glass_noodle_model(parent,model_position)
	return null

func _add_bunja_model(parent: Node3D, model_position: Vector3) -> Node3D:
	if is_instance_valid(ingredient_manager): return ingredient_manager.add_bunja_model(parent,model_position)
	return null

func _add_gun_dubu_model(parent: Node3D, model_position: Vector3) -> Node3D:
	if is_instance_valid(ingredient_manager): return ingredient_manager.add_gun_dubu_model(parent,model_position)
	return null

func _add_albaegi_cabbage_model(parent: Node3D, model_position: Vector3) -> Node3D:
	if is_instance_valid(ingredient_manager): return ingredient_manager.add_albaegi_cabbage_model(parent,model_position)
	return null

func _add_enoki_model(parent: Node3D, model_position: Vector3) -> Node3D:
	if is_instance_valid(ingredient_manager): return ingredient_manager.add_enoki_model(parent,model_position)
	return null

func _apply_courier_material(root: Node) -> void:
	if is_instance_valid(courier_manager):
		courier_manager.apply_courier_material(root)
	return

func _ingredient_color(ingredient_name: String) -> Color:
	if is_instance_valid(ingredient_manager): return ingredient_manager.ingredient_color(ingredient_name)
	return Color.WHITE

func _animate_tongs_and_add_visual(ingredient_name: String) -> void:
	if is_instance_valid(ingredient_manager): ingredient_manager.animate_tongs_and_add_visual(ingredient_name)

func _clear_basket_visuals() -> void:
	if not is_instance_valid(held_basket_items): return
	for child in held_basket_items.get_children(): child.queue_free()

func _clear_held_preview() -> void:
	if is_instance_valid(held_placement_preview): held_placement_preview.queue_free()
	if is_instance_valid(held_preview_outline): held_preview_outline.queue_free()
	held_preview_outline=null
	held_preview_material=null
	held_placement_preview=null
	held_preview_source=null

func _placement_surface_y(surface: Node3D) -> float:
	return placement_manager.surface_y(surface)

func _placement_offset_y(surface: Node3D) -> float:
	return placement_manager.offset_y(surface)

func _view_plane_point(surface: Node3D) -> Dictionary:
	return placement_manager.view_plane_point(surface)

func _get_table_placement_point(surface: Node3D, minimum_distance: float=2.2, object_radius: float=0.0, ignored: Node=null) -> Dictionary:
	return placement_manager.table_placement_point(surface,minimum_distance,object_radius,ignored)

func _held_place_radius() -> float:
	return placement_manager.held_radius()

func _get_placement_surface_from_view() -> Node3D:
	return placement_manager.placement_surface_from_view()

func _is_place_position_free(point: Vector3, radius: float, ignored: Node=null) -> bool:
	return placement_manager.is_place_position_free(point,radius,ignored)

func _get_model_world_aabb(root: Node3D) -> AABB:
	return placement_manager.model_world_aabb(root)

func _snap_model_bottom_to_surface(root: Node3D, surface_y: float, clearance: float=0.025) -> void:
	placement_manager.snap_model_bottom(root,surface_y,clearance)

func _is_held_blocked_by_placeable() -> bool:
	if is_instance_valid(carrying_manager): return carrying_manager.is_held_blocked_by_placeable()
	return false

func _update_held_preview(blocked: bool) -> void:
	if is_instance_valid(carrying_manager): carrying_manager.update_held_preview(blocked)

func _place_interaction_prompt_near(target: Node) -> void:
	if is_instance_valid(ui_manager): ui_manager.place_interaction_prompt_near(target)

func _set_highlight(target: Node) -> void:
	placement_manager.set_highlight(target)

func _start_tutorial_quests() -> void:
	if is_instance_valid(tutorial_manager): tutorial_manager.start_quests()

func _update_tutorial_quest(force:=false) -> void:
	if is_instance_valid(tutorial_manager): tutorial_manager.update_quest(force)

func _build_tutorial_quest_ui() -> void:
	if is_instance_valid(tutorial_manager): tutorial_manager.build_quest_ui()

func _update_tutorial_page() -> void:
	var pages:Array[Array]=[
		["Move with W A S D", "Look around with the mouse and press E to interact."],
		["Accept an order", "Open the order monitor and accept a delivery order."],
		["Prepare ingredients", "Pick up ingredients one at a time and place them in the bowl."],
		["Finish the meal", "Cook the broth, complete the order, and deliver it."]
	]
	var page:=pages[clampi(tutorial_step,0,pages.size()-1)]
	tutorial_title.text=str(page[0])
	tutorial_body.text=str(page[1])
	tutorial_button.text="Next" if tutorial_step<pages.size()-1 else "Finish (Enter)"

func _advance_tutorial() -> void:
	if not tutorial_active: return
	if tutorial_step<3:
		tutorial_step+=1
		_update_tutorial_page()
		return
	tutorial_active=false
	tutorial_seen=true
	if is_instance_valid(tutorial_overlay): tutorial_overlay.visible=false
	var player:=get_node_or_null("Player") as CharacterBody3D
	if is_instance_valid(player): player.input_locked=false
	if is_instance_valid(held_tools): held_tools.visible=true
	_set_gameplay_hud_visible(true)
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	_save_game(false)

func _build_ui() -> void:
	ui_manager.build_ui()
func _apply_ui_theme() -> void:
	var button_normal:=StyleBoxFlat.new(); button_normal.bg_color=Color("#26313b"); button_normal.border_color=Color("#536575"); button_normal.set_border_width_all(1); button_normal.set_corner_radius_all(5); button_normal.content_margin_left=14; button_normal.content_margin_right=14
	var button_hover:=button_normal.duplicate(); button_hover.bg_color=Color("#37566a"); button_hover.border_color=Color("#69c6d8")
	var button_pressed:=button_normal.duplicate(); button_pressed.bg_color=Color("#1a8292"); button_pressed.border_color=Color("#92efff")
	for button in [receipt_toggle_button]:
		if is_instance_valid(button):
			button.add_theme_stylebox_override("normal",button_normal)
			button.add_theme_stylebox_override("hover",button_hover)
			button.add_theme_stylebox_override("pressed",button_pressed)
			button.add_theme_color_override("font_color",Color("#e8f5f7"))
			button.add_theme_color_override("font_hover_color",Color.WHITE)
	var monitor_buttons:=order_panel.find_children("", "Button", true, false)
	for button in monitor_buttons:
		button.add_theme_stylebox_override("normal",button_normal)
		button.add_theme_stylebox_override("hover",button_hover)
		button.add_theme_stylebox_override("pressed",button_pressed)
		button.add_theme_color_override("font_color",Color("#e8f5f7"))
		button.add_theme_color_override("font_hover_color",Color.WHITE)
		button.add_theme_font_size_override("font_size",16)
	if is_instance_valid(prompt_label):
		prompt_label.add_theme_color_override("font_color",Color("#ffe082"))
		prompt_label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.85))
		prompt_label.add_theme_constant_override("shadow_offset_x",2)
		prompt_label.add_theme_constant_override("shadow_offset_y",2)

func _build_order_panel(layer: CanvasLayer) -> void:
	ui_manager.build_order_panel(layer)
func _show_reset_confirmation() -> void:
	if is_instance_valid(reset_confirmation): reset_confirmation.popup_centered(Vector2(480,220))

func _show_next_day_confirmation() -> void:
	if is_instance_valid(day_manager): day_manager.show_next_day_confirmation()

func _reset_game() -> void:
	if is_instance_valid(save_manager): save_manager.reset_game()

func _generate_orders() -> void:
	if is_instance_valid(order_manager):
		order_manager.generate_orders()
		return
	return

func _update_pending_order_deadlines(delta: float) -> void:
	if is_instance_valid(order_manager): order_manager.update_deadlines(delta)
func _refresh_order_panel() -> void:
	ui_manager.refresh_order_panel()
func _style_monitor_controls() -> void:
	if is_instance_valid(ui_manager): ui_manager.style_monitor_controls()

func _show_orders() -> void:
	if is_instance_valid(ui_manager): ui_manager.show_orders()

func _show_shop() -> void:
	if is_instance_valid(ui_manager): ui_manager.show_shop()

func _show_upgrades() -> void:
	if is_instance_valid(ui_manager): ui_manager.show_upgrades()

func _show_management() -> void:
	if is_instance_valid(ui_manager): ui_manager.show_management()

func _refresh_shop_panel() -> void:
	ui_manager.refresh_shop_panel_korean()
func _ingredient_icon_path(ingredient_name: String) -> String:
	var paths:Dictionary={
		"\uCCAD\uACBD\uCC44":"res://assets/ui/ingredients/cheonggyeongchae.svg",
		"\uC54C\uBC30\uAE30\uBC30\uCD94":"res://assets/ui/ingredients/albaechu.svg",
		"\uAC74\uB450\uBD80":"res://assets/ui/ingredients/gan_doufu.svg",
		"\uBAA9\uC774\uBC84\uC12F":"res://assets/ui/ingredients/mokiboseot.svg",
		"\uD301\uC774\uBC84\uC12F":"res://assets/ui/ingredients/paengiboseot.svg",
		"\uC219\uC8FC":"res://assets/ui/ingredients/sukju.svg",
		"\uC911\uAD6D\uB2F9\uBA74":"res://assets/ui/ingredients/jung_guk.svg",
		"\uBD84\uBAA8\uC790":"res://assets/ui/ingredients/bunmoja.svg",
		"\uD53C\uC26C\uBCFC":"res://assets/ui/ingredients/fishball.svg",
		"\uC18C\uC2DC\uC9C0":"res://assets/ui/ingredients/sausage.svg"
	}
	return str(paths.get(ingredient_name,"res://assets/ui/ingredients/cheonggyeongchae.svg"))

func _ingredient_order_icon_path(ingredient_name: String) -> String:
	# Use the real texture for ingredients that have a completed 3D model.
	# Other ingredients intentionally keep the temporary UI icons.
	for index in INGREDIENTS.size():
		if str(INGREDIENTS[index][0])!=ingredient_name: continue
		if index==2: return "res://assets/models/tofu_skin.png"
		if index==6: return "res://assets/models/bean_sprouts.png"
		break
	return _ingredient_icon_path(ingredient_name)

func _ingredient_model_path(ingredient_name: String) -> String:
	if is_instance_valid(ingredient_manager): return ingredient_manager.ingredient_model_path(ingredient_name)
	return ""

func _make_ingredient_model_preview(ingredient_name: String, preview_size: int) -> Control:
	if is_instance_valid(ingredient_manager): return ingredient_manager.make_model_preview(ingredient_name,preview_size)
	return null

func _apply_bean_sprouts_preview_material(root: Node) -> void:
	if is_instance_valid(ingredient_manager): ingredient_manager.apply_bean_sprouts_preview_material(root)

func _apply_tofu_skin_preview_material(root: Node) -> void:
	if is_instance_valid(ingredient_manager): ingredient_manager.apply_tofu_skin_preview_material(root)

func _purchase_cart_total() -> int:
	if is_instance_valid(economy_manager): return economy_manager.purchase_cart_total()
	return 0

func _purchase_cart_summary() -> String:
	if is_instance_valid(economy_manager): return economy_manager.purchase_cart_summary()
	return "Cart is empty."

func _add_ingredient_to_cart(ingredient_name: String) -> void:
	if is_instance_valid(economy_manager): economy_manager.add_ingredient_to_cart(ingredient_name)

func _add_packaging_to_cart() -> void:
	if is_instance_valid(economy_manager): economy_manager.add_packaging_to_cart()

func _add_broth_to_cart() -> void:
	if is_instance_valid(economy_manager): economy_manager.add_broth_to_cart()

func _checkout_purchase_cart() -> void:
	if is_instance_valid(economy_manager): economy_manager.checkout_purchase_cart()

func _buy_ingredient(ingredient_name: String) -> void:
	if is_instance_valid(economy_manager): economy_manager.add_ingredient_to_cart(ingredient_name)

func _buy_packaging() -> void:
	if is_instance_valid(economy_manager): economy_manager.add_packaging_to_cart()

func _refresh_upgrade_panel() -> void:
	var description:=Label.new()
	description.text="가게 업그레이드"
	description.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	order_list.add_child(description)
	_add_upgrade_button("재료 보관량", "stock", 50000, "재료 보관량 +5")
	_add_upgrade_button("조리 속도", "cooking", 65000, "조리 시간 단축")
	_add_upgrade_button("이동 속도", "movement", 60000, "이동 속도 증가")
	if store_stage==1 and not pending_upgrades.has("stage2"):
		_add_upgrade_button("가게 2단계 확장", "stage2", 350000, "매장 손님 공간 잠금 해제")
	elif store_stage==2 and not pending_upgrades.has("stage3"):
		_add_upgrade_button("가게 3단계 확장", "stage3", 700000, "테이블 공간 확장")
	var day_button:=Button.new()
	day_button.text="영업 종료 및 정산"
	day_button.custom_minimum_size=Vector2(0,58)
	day_button.pressed.connect(_end_day)
	order_list.add_child(day_button)

func _add_upgrade_button(title: String, key: String, price: int, detail: String) -> void:
	var button:=Button.new()
	button.text="%s · %d원\\n%s | 현재 레벨 %d" % [title,price,detail,int(upgrade_levels.get(key,0))]
	button.custom_minimum_size=Vector2(0,65)
	button.pressed.connect(_purchase_upgrade.bind(key,price,title))
	order_list.add_child(button)

func _purchase_upgrade(key: String, price: int, title: String) -> void:
	if money<price:
		return
	if money<price: result_label.text="?????怨뺤른?????????援쏂굜???????????됱삩???????Β???????釉먮폁????????????怨몄）."; return
	if pending_upgrades.has(key): result_label.text="???? ????關?쒎첎?嫄??????????? ?????????熬곣벀嫄?????꾤뙴??????????怨몄）."; return
	money-=price; pending_upgrades.append(key); result_label.text=title+" ?????????????꾩룆梨띰쭕????????關?쒎첎?嫄???????????"; _save_game(false); _refresh_order_panel(); _refresh_hud()

func _end_day() -> void:
	if not current_order.is_empty() or cooking or not cooked_food.is_empty() or pending_customer_payment>0:
		result_label.text="??遺얘턁???????꿔꺂??????????熬곣벀嫄?????꾤뙴?????????諛몄カ??轅붽틓?????곸뒭????????븍툖???紐꽺?? ??????꾩룆梨띰쭕????????????????????????깅뼂?耀붾굝???壤굿?怨쀫ぁ???? ???????????????諛몄カ?????????"
		return
	if not is_instance_valid(fade_overlay):
		_show_settlement_after_transition()
		return
	fade_overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	var transition:=create_tween()
	transition.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	transition.tween_property(fade_overlay,"color",Color(0,0,0,1),0.45)
	transition.tween_callback(_show_settlement_after_transition)
	transition.tween_interval(0.35)
	transition.tween_property(fade_overlay,"color",Color(0,0,0,0),0.55)
	transition.tween_callback(func(): fade_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE)

func _show_settlement_after_transition() -> void:
	if is_instance_valid(ui_manager): ui_manager.show_settlement_after_transition()

func _refresh_settlement_panel() -> void:
	var average_rating:float=daily_rating_total/float(daily_completed_orders) if daily_completed_orders>0 else rating
	var net_profit:int=daily_sales-daily_material_cost
	var title:=Label.new()
	title.text="\uC601\uC5C5 \uC815\uC0B0"
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",28)
	title.add_theme_color_override("font_color",Color("#294052"))
	order_list.add_child(title)
	var subtitle:=Label.new()
	subtitle.text="\uC624\uB298\uC758 \uC601\uC5C5 \uACB0\uACFC\uC640 \uB2E4\uC74C \uB0A0 \uC900\uBE44 \uC0C1\uD0DC\uC785\uB2C8\uB2E4."
	subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	order_list.add_child(subtitle)
	var stats:=GridContainer.new()
	stats.columns=3
	stats.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stats.add_theme_constant_override("h_separation",12)
	stats.add_theme_constant_override("v_separation",12)
	order_list.add_child(stats)
	var values:Array=[["\uC624\uB298 \uB9E4\uCD9C",str(daily_sales)+"\uC6D0"],["\uC7AC\uB8CC\uBE44",str(daily_material_cost)+"\uC6D0"],["\uC21C\uC774\uC775",str(net_profit)+"\uC6D0"],["\uBCF4\uC720\uAE08",str(money)+"\uC6D0"],["\uC644\uB8CC \uC8FC\uBB38",str(daily_completed_orders)+"\uAC74"],["\uD3C9\uC810",("%.1f" % average_rating)+"\uC810"]]
	for item in values:
		var card:=PanelContainer.new()
		card.custom_minimum_size=Vector2(0,112)
		var card_style:=StyleBoxFlat.new()
		card_style.bg_color=Color("#ffffff")
		card_style.border_color=Color("#d2b98e")
		card_style.set_border_width_all(1)
		card_style.set_corner_radius_all(8)
		card.add_theme_stylebox_override("panel",card_style)
		var content:=VBoxContainer.new()
		content.alignment=BoxContainer.ALIGNMENT_CENTER
		card.add_child(content)
		var key_label:=Label.new()
		key_label.text=item[0]
		key_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(key_label)
		var value_label:=Label.new()
		value_label.text=item[1]
		value_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		value_label.add_theme_font_size_override("font_size",24)
		value_label.add_theme_color_override("font_color",Color("#294052"))
		content.add_child(value_label)
		stats.add_child(card)
	var pending:=Label.new()
	pending.text="\uB2E4\uC74C \uB0A0 \uC5C5\uADF8\uB808\uC774\uB4DC: "+("\uC5C6\uC74C" if pending_upgrades.is_empty() else ", ".join(pending_upgrades))
	pending.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	pending.add_theme_font_size_override("font_size",17)
	order_list.add_child(pending)
	var next_day:=Button.new()
	next_day.text="Confirm - %d day start" % (day+1)
	next_day.custom_minimum_size=Vector2(0,58)
	next_day.pressed.connect(_start_next_day)
	order_list.add_child(next_day)
func _start_next_day() -> void:
	if not is_instance_valid(fade_overlay):
		_advance_to_next_day()
		return
	fade_overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	var transition:=create_tween()
	transition.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	transition.tween_property(fade_overlay,"color",Color(0,0,0,1),0.45)
	transition.tween_callback(_advance_to_next_day)
	transition.tween_interval(0.35)
	transition.tween_property(fade_overlay,"color",Color(0,0,0,0),0.55)
	transition.tween_callback(func(): fade_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE)

func _advance_to_next_day() -> void:
	if is_instance_valid(day_manager):
		day_manager.advance_to_next_day()
		return
	day+=1; daily_sales=0; daily_material_cost=0; daily_completed_orders=0; daily_rating_total=0.0
	game_clock_minutes=OPENING_HOUR*60.0
	auto_close_day=0
	current_order.clear(); customer_order.clear(); basket.clear(); cooked_food.clear(); selected_spice=0; remaining_time=0.0; cooking=false
	pending_customer_payment=0; pending_customer_stars=0.0; _clear_basket_visuals(); _reset_courier()
	if is_instance_valid(customer_manager): customer_manager.clear_for_new_day(CUSTOMER_EXIT_POSITION)
	active_customer=null; active_customer_table_position=Vector3.ZERO
	for key in pending_upgrades:
		if key=="stage2": store_stage=maxi(store_stage,2); dining_unlocked=true
		elif key=="stage3": store_stage=maxi(store_stage,3); dining_unlocked=true
		else: upgrade_levels[key]=int(upgrade_levels.get(key,0))+1
	_load_stage_layout()
	pending_upgrades.clear(); _apply_store_structure(); _apply_upgrade_effects(); _generate_orders(); result_label.text="Day %d started 쨌 Stage %d" % [day,store_stage]; monitor_mode="orders"; _save_game(false); _refresh_order_panel(); _refresh_hud()

func _apply_upgrade_effects() -> void:
	var player:=get_node_or_null("Player")
	if player: player.speed=5.0+float(upgrade_levels["movement"])*0.75

func _create_dining_tables() -> void:
	world_manager.create_dining_tables()
func _build_kitchen_sight_barrier(parent: Node3D) -> void:
	# Keep a central passage open while blocking the dining area's direct view into the kitchen.
	box("KitchenSightBlockLeft",Vector3(-3.45,1.45,-3.0),Vector3(3.1,2.9,0.32),Color("#d8d1c5"),parent)
	box("KitchenSightBlockRight",Vector3(4.15,1.45,-3.0),Vector3(3.1,2.9,0.32),Color("#d8d1c5"),parent)
	box("KitchenSightHeader",Vector3(0.35,3.15,-3.0),Vector3(4.7,0.35,0.32),Color("#d8d1c5"),parent)

func _set_dining_table_interaction_collision(enabled: bool) -> void:
	var area:=get_node_or_null("DiningArea")
	if not area: area=get_node_or_null("EditableModels/DiningArea")
	if not area: return
	for child in area.get_children():
		if not child.name.begins_with("DiningTable_"): continue
		var body:=child.get_node_or_null("StaticBody3D") as StaticBody3D
		if body: body.collision_layer=1 if enabled else 0

func _add_dining_furniture_model(path: String, world_position: Vector3, rotation: Vector3, model_scale: float, model_name: String, parent: Node3D) -> Node3D:
	return world_manager.add_dining_furniture_model(path,world_position,rotation,model_scale,model_name,parent)
func _apply_store_structure() -> void:
	var old_structure:=get_node_or_null("StageStructure")
	if not old_structure: old_structure=get_node_or_null("EditableModels/StageStructure")
	var structure:Node3D
	if old_structure:
		structure=old_structure as Node3D
	else:
		structure=Node3D.new(); structure.name="StageStructure"; add_child(structure)
	# All upgrades now expand the same room. Do not create the old divider,
	# kitchen sight barrier, or a second-stage shell: those walls split the
	# dining tables into a separate-looking scene.
	_create_dining_tables()

func _spawn_customer() -> void:
	if is_instance_valid(customer_manager): customer_manager.spawn_customer()

func _dining_table_center_position(table_index: int) -> Vector3:
	if is_instance_valid(customer_manager): return customer_manager.dining_table_center_position(table_index)
	return Vector3.ZERO

func _dining_seat_position(seat_index: int) -> Vector3:
	if is_instance_valid(customer_manager): return customer_manager.dining_seat_position(seat_index)
	return Vector3.ZERO

func customer_reached_counter(customer: CharacterBody3D) -> void:
	if is_instance_valid(customer_manager): customer_manager.customer_reached_counter(customer)

func _prepare_customer_order(customer: CharacterBody3D) -> void:
	if is_instance_valid(customer_manager): customer_manager.prepare_customer_order(customer)

func customer_reached_table(customer: CharacterBody3D) -> void:
	if is_instance_valid(customer_manager): customer_manager.customer_reached_table(customer)

func customer_reached_payment(customer: CharacterBody3D) -> void:
	if is_instance_valid(customer_manager): customer_manager.customer_reached_payment(customer)

func customer_left(customer: CharacterBody3D) -> void:
	if is_instance_valid(customer_manager): customer_manager.customer_left(customer)

func _accept_customer_order(interaction_node: Node = null) -> void:
	if is_instance_valid(service_manager): service_manager.accept_customer_order(interaction_node)

func _accept_customer_payment() -> void:
	if is_instance_valid(service_manager): service_manager.accept_customer_payment()

func _open_monitor() -> void:
	ui_manager.open_monitor()
func _close_monitor() -> void:
	if not monitor_camera_focused:
		monitor_backdrop.visible=false
		order_panel.visible=false
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		return
	order_panel.visible=false
	monitor_backdrop.visible=false
	monitor_backdrop.modulate.a=1.0
	order_panel.modulate.a=1.0
	monitor_camera_focused=false
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	var player:=get_node_or_null("Player") as CharacterBody3D
	if is_instance_valid(player):
		player.global_transform=monitor_player_original_transform
	camera.global_transform=monitor_camera_original_transform
	camera.rotation=monitor_camera_original_rotation
	camera.fov=monitor_camera_original_fov
	_finish_monitor_return()

func _finish_monitor_return() -> void:
	if is_instance_valid(ui_manager): ui_manager.finish_monitor_return()

func _set_gameplay_hud_visible(show_hud: bool) -> void:
	if is_instance_valid(ui_manager): ui_manager.set_gameplay_hud_visible(show_hud)

func _show_monitor_message(message: String) -> void:
	if is_instance_valid(ui_manager): ui_manager.show_monitor_message(message)

func _toggle_order_receipt() -> void:
	if is_instance_valid(ui_manager): ui_manager.toggle_order_receipt()

func _set_receipt_open(open_state: bool, animate: bool = true) -> void:
	if is_instance_valid(ui_manager): ui_manager.set_receipt_open(open_state,animate)

func _accept_order(order: Dictionary) -> void:
	if is_instance_valid(order_manager): order_manager.accept_order(order)

func _refresh_hud() -> void:
	if is_instance_valid(ui_manager): ui_manager.refresh_hud()

func _format_receipt_items(items: Array) -> String:
	if is_instance_valid(ui_manager): return ui_manager.format_receipt_items(items)
	return ""

func _sync_held_broth_stock_state() -> void:
	if is_instance_valid(broth_manager): broth_manager.sync_held_stock_state()

func _has_any_held_object() -> bool:
	if is_instance_valid(carrying_manager): return carrying_manager.has_any_held_object()
	return has_broth_pot or has_broth_stock_pack or has_ladle or has_tongs or has_bowl or has_steel_bowl

func _handle_interaction(node: Node, from_mouse: bool=false, whole_stack: bool=false) -> void:
	if is_instance_valid(interaction_manager): interaction_manager.handle_interaction(node,from_mouse,whole_stack)
func _place_held_object_on_table(surface: Node3D, whole_stack: bool=false) -> void:
	if is_instance_valid(carrying_manager): carrying_manager.place_held_object_on_table(surface,whole_stack)
func _start_cooking() -> void:
	cooking_manager.start_cooking()
func _auto_pickup_finished_food() -> void:
	if is_instance_valid(cooking_manager): cooking_manager.auto_pickup_finished_food()

func _pickup_food_tray() -> void:
	if is_instance_valid(cooking_manager): cooking_manager.pickup_food_tray()

func _on_cooking_finished(food: Dictionary) -> void:
	if is_instance_valid(cooking_manager): cooking_manager.apply_finished_food(food)

func _can_prepare_broth() -> bool:
	if is_instance_valid(broth_manager): return broth_manager.can_prepare()
	return not broth_making and broth_servings<=10

func _update_broth_liquid_visual() -> void:
	if is_instance_valid(broth_manager): broth_manager.update_liquid_visual()

func _add_broth_water(use_sink_stream:=false) -> void:
	if is_instance_valid(broth_manager): broth_manager.add_water(use_sink_stream)

func _run_sink_water() -> void:
	if is_instance_valid(broth_manager): broth_manager.run_sink_water()

func _set_broth_pot_carried_collision(carried: bool) -> void:
	for pot_model in [broth_pot_model,broth_pot_filled_model]:
		if not is_instance_valid(pot_model): continue
		pot_model.set_meta("interaction_disabled",carried)
		var model_body:=pot_model.get_node_or_null("BrothPotCollision") as StaticBody3D
		if not is_instance_valid(model_body): model_body=pot_model.get_node_or_null("BrothPotFilledCollision") as StaticBody3D
		if is_instance_valid(model_body):
			model_body.collision_layer=0 if carried else 1
			model_body.collision_mask=0 if carried else 1
	var interaction_body:StaticBody3D=null
	if is_instance_valid(broth_pot_interaction): interaction_body=broth_pot_interaction.get_node_or_null("StaticBody3D") as StaticBody3D
	if is_instance_valid(interaction_body):
		interaction_body.collision_layer=0 if carried else 1
		interaction_body.collision_mask=0 if carried else 1
	if is_instance_valid(broth_pot_interaction):
		broth_pot_interaction.set_meta("interaction_disabled",carried)

func _set_broth_pot_filled_visual(filled: bool) -> void:
	if is_instance_valid(broth_manager):
		broth_manager.set_pot_filled_visual(filled)
		return
	if is_instance_valid(broth_pot_filled_model):
		# Do not restore the editor/home transform here. The filled pot can have
		# been placed anywhere by the player, so changing its visual state must
		# preserve its current transform.
		broth_pot_filled_model.visible=filled
	var liquid_parent:Node3D=broth_pot_filled_model if filled and is_instance_valid(broth_pot_filled_model) else broth_pot_model
	if is_instance_valid(broth_liquid) and is_instance_valid(liquid_parent):
		if broth_liquid.get_parent()!=liquid_parent:
			broth_liquid.reparent(liquid_parent)
		broth_liquid.position=Vector3(0,0.45,0)
		broth_liquid.rotation=Vector3.ZERO
		_update_broth_liquid_visual()
	if is_instance_valid(broth_pot_model): broth_pot_model.visible=not filled
	if is_instance_valid(broth_pot_interaction):
		broth_pot_interaction.set_meta("highlight_target",broth_pot_filled_model if filled and is_instance_valid(broth_pot_filled_model) else broth_pot_model)

func _toggle_broth_pot() -> void:
	broth_manager.toggle_broth_pot()
func _drop_broth_pot_at_home() -> void:
	if not has_broth_pot or not is_instance_valid(carried_broth_pot_model): return
	has_broth_pot=false
	carried_broth_pot_model.reparent(self,true)
	carried_broth_pot_model.global_transform=broth_pot_home_transform
	_set_broth_pot_carried_collision(false)
	_set_broth_pot_filled_visual(is_instance_valid(broth_pot_filled_model) and broth_pot_filled_model==carried_broth_pot_model)
	carried_broth_pot_model=null
	if is_instance_valid(broth_pot_drop_zone): broth_pot_drop_zone.set_meta("interaction_disabled",true)
	result_label.text="????????繹???????꾩룆梨띰쭕????????????????????????????"
	_clear_held_preview()
	_set_highlight(null)
	_refresh_hud()

func _open_broth_stock_at_source(source: Node) -> void:
	broth_manager.open_broth_stock_at_source(source)
func _broth_stock_node_is_open(node: Node) -> bool:
	if is_instance_valid(broth_manager): return broth_manager.stock_node_is_open(node)
	if not is_instance_valid(node): return false
	if node==broth_stock_open_model: return true
	return bool(node.get_meta("broth_stock_open",false))

func _pickup_broth_stock_pack(clicked_open: bool=false) -> void:
	if has_broth_stock_pack:
		result_label.text="????????繹??????????? ??????關履????????????????怨몄）. E??????????????????????癒꺜??壤굿??뼿??????耀붾굝???????"
		return
	if broth_stock_packs<=0:
		result_label.text="????????????繹?????????????繹먮굞??????????怨몄）. ?????????????????熬곣뫖利??????????????饔낅떽???壤굿??곸읆???"
		return
	if _has_any_held_object():
		result_label.text="???????ル????? ????????????살퓢?????癲됱빖???嶺뚮슡????筌뤾쑬???ш끽維???????????????????怨몄）. ?????븍툖???紐꽺?? ??????關履????????????????????ル???????????????耀붾굝???????"
		_refresh_hud()
		return
	var picked_open:=clicked_open or broth_stock_open_in_world
	broth_stock_packs-=1
	has_broth_stock_pack=true
	broth_stock_pack_open=picked_open
	broth_stock_open_in_world=false
	if is_instance_valid(broth_stock_model): broth_stock_model.visible=broth_stock_packs>0
	if is_instance_valid(broth_stock_open_model):
		broth_stock_open_model.visible=false
		var open_body:=broth_stock_open_model.get_node_or_null("BrothStockOpenCollision") as StaticBody3D
		if is_instance_valid(open_body):
			open_body.collision_layer=0
			open_body.collision_mask=0
	_set_broth_stock_source_enabled(false)
	_update_held_tool_visibility()
	result_label.text="??? ????????????繹????????????????? ??????꾩룆梨띰쭕??????E?????????????????耀붾굝???????" if picked_open else "????? ????????????繹????????????????? E??????????????????????癒꺜??壤굿??뼿??????耀붾굝???????"
	_refresh_hud()

func _pickup_placed_broth_stock(node: Node) -> void:
	if has_broth_stock_pack:
		result_label.text="????????繹??????????? ??????關履????????????????怨몄）."
		_refresh_hud()
		return
	if _has_any_held_object():
		result_label.text="???????ル????? ????????????살퓢?????癲됱빖???嶺뚮슡????筌뤾쑬???ш끽維???????????????????怨몄）. ?????븍툖???紐꽺?? ??????關履????????????????????ル???????????????耀붾굝???????"
		_refresh_hud()
		return
	if not is_instance_valid(node): return
	# Picking up a placed pack returns the same item; it must not consume
	# another inventory pack.
	has_broth_stock_pack=true
	broth_stock_pack_open=bool(node.get_meta("broth_stock_open",false))
	node.queue_free()
	_update_held_tool_visibility()
	result_label.text="????????? ????????繹???????????????꾨굴???????????? ??????꾩룆梨띰쭕?????????????????耀붾굝???????" if broth_stock_pack_open else "??????????? ????????繹???????????????꾨굴???????????? E??????????????????????癒꺜??壤굿??뼿??????耀붾굝???????"
	_clear_held_preview()
	_set_highlight(null)
	_refresh_hud()

func _open_broth_stock_pack() -> void:
	if not has_broth_stock_pack: return
	if broth_stock_pack_open:
		result_label.text="???? ??? ????????????繹??????????????怨몄）. ??????꾩룆梨띰쭕??????E?????????????????耀붾굝???????"
		return
	broth_stock_pack_open=true
	_update_held_tool_visibility()
	result_label.text="????????????繹??????????????????? ??????꾩룆梨띰쭕??????E?????????????????耀붾굝???????"
	_refresh_hud()

func _add_broth_stock_from_pack() -> void:
	if is_instance_valid(broth_manager): broth_manager.add_stock_from_held_pack()

func _add_broth_stock() -> void:
	if is_instance_valid(broth_manager): broth_manager.add_stock_from_source()

func _add_broth_base() -> void:
	if is_instance_valid(broth_manager): broth_manager.add_base()

func _make_broth() -> void:
	if is_instance_valid(broth_manager): broth_manager.make_broth()

func _play_broth_chime() -> void:
	if is_instance_valid(broth_manager): broth_manager.play_completion_chime()

func _face_courier_toward(courier: Node3D, target_position: Vector3) -> void:
	if is_instance_valid(courier_manager): courier_manager.face_toward(courier,target_position)

func _summon_courier() -> void:
	if is_instance_valid(courier_manager): courier_manager.summon()

func _send_courier_away() -> void:
	if is_instance_valid(courier_manager): courier_manager.send_away()

func _reset_queue_tweens() -> void:
	if is_instance_valid(courier_manager): courier_manager.reset_queue_tweens()

func _reset_courier() -> void:
	if is_instance_valid(courier_manager): courier_manager.reset()

func _deliver_food(courier_order_id: int=-1) -> void:
	if is_instance_valid(service_manager): service_manager.deliver_food(courier_order_id)

func _serve_table(target_table: Node = null) -> void:
	if is_instance_valid(service_manager): service_manager.serve_table(target_table)

func _is_left_click_interaction(interaction_type: String) -> bool:
	if is_instance_valid(interaction_manager): return interaction_manager.is_left_click_interaction(interaction_type)
	return false

func _input(event: InputEvent) -> void:
	if is_instance_valid(interaction_manager): interaction_manager.handle_input(event)

func _process(_delta: float) -> void:
	_update_tutorial_quest()
	if not camera: return
	if get_tree().paused: return
	if is_instance_valid(game_loop_manager): game_loop_manager.tick(_delta)

	if is_instance_valid(interaction_manager) and interaction_manager.update_frame_interaction(): return

func _fail_order() -> void:
	if is_instance_valid(service_manager): service_manager.reset()
	if is_instance_valid(active_customer):
		active_customer.remove_meta("interaction")
		active_customer.remove_meta("interaction_type")
		var customer_proxy:=active_customer.get_node_or_null("CustomerInteractionProxy") as Node3D
		if customer_proxy:
			customer_proxy.remove_meta("interaction")
			customer_proxy.remove_meta("interaction_type")
		active_customer.call("leave_after_payment",CUSTOMER_EXIT_POSITION)
	customer_order.clear()
	pending_customer_payment=0
	pending_customer_stars=0.0
	_reset_courier()
	if is_instance_valid(serving_bowl_view): serving_bowl_view.visible=false
	if is_instance_valid(food_tray_view): food_tray_view.visible=false
	has_food_tray=false
	if is_instance_valid(food_tray_world):
		food_tray_world.queue_free()
		food_tray_world=null
	if is_instance_valid(placed_food_tray):
		placed_food_tray.queue_free()
		placed_food_tray=null
	_empty_ladle()
	current_order.clear(); basket.clear(); _clear_basket_visuals(); cooked_food.clear(); selected_spice=0; remaining_time=0.0
	rating=maxf(1.0,rating-0.2); result_label.text="??????諛몄カ??轅붽틓?????곸뒭????????????? ?????怨뺤른???????????ル뭽????????????????怨몄）."
	if orders.is_empty(): _generate_orders()
	_save_game(false)
	_refresh_hud()
