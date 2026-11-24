extends Node3D

# Main scene controller.

const GAME_CONFIG = preload("res://assets/scripts/game_config.gd")
const MAIN_BOOTSTRAP = preload("res://assets/scripts/main_bootstrap.gd")
const INGREDIENTS = preload("res://assets/scripts/ingredient_catalog.gd").ALL

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
var world_asset_manager
var game_flow_manager
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
	MAIN_BOOTSTRAP.run(self)

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
	if is_instance_valid(player_visual_manager): player_visual_manager.set_player_arms_visible(should_show)
func _update_player_animation() -> void:
	if is_instance_valid(player_visual_manager): player_visual_manager.update_player_animation()
func _pose_player_arms_for_tools() -> void:
	if is_instance_valid(player_visual_manager): player_visual_manager.pose_player_arms_for_tools()
func _apply_player_material(root: Node) -> void:
	if is_instance_valid(player_visual_manager): player_visual_manager.apply_player_material(root)
func _add_order_monitor_model() -> void:
	if is_instance_valid(world_asset_manager):
		world_asset_manager.add_order_monitor_model()
		return
func _add_gas_stove_model(world_position: Vector3, model_scale: float = 0.72) -> void:
	if is_instance_valid(world_asset_manager):
		world_asset_manager.add_gas_stove_model(world_position,model_scale)
		return
func _apply_gas_stove_material(root: Node) -> void:
	if is_instance_valid(world_asset_manager): world_asset_manager.apply_gas_stove_material(root)
func _add_sink_model(world_position: Vector3, model_scale: float=0.72) -> Node3D:
	if is_instance_valid(world_asset_manager): return world_asset_manager.add_sink_model(world_position,model_scale)
	return null
func _apply_sink_material(root: Node) -> void:
	if is_instance_valid(world_asset_manager): world_asset_manager.apply_sink_material(root)
func _add_broth_pot_model(world_position: Vector3, model_scale: float=0.62) -> Node3D:
	if is_instance_valid(world_asset_manager): return world_asset_manager.add_broth_pot_model(world_position,model_scale)
	return null
func _apply_broth_pot_material(pot: Node) -> void:
	if is_instance_valid(world_asset_manager): world_asset_manager.apply_broth_pot_material(pot)
func _add_broth_stock_model(path: String, node_name: String, world_position: Vector3, model_scale: float) -> Node3D:
	if is_instance_valid(world_asset_manager): return world_asset_manager.add_broth_stock_model(path,node_name,world_position,model_scale)
	return null
func _add_malatang_pot_model(world_position: Vector3) -> Node3D:
	if is_instance_valid(world_asset_manager): return world_asset_manager.add_malatang_pot_model(world_position)
	return null
func _apply_malatang_pot_material(root: Node) -> void:
	if is_instance_valid(world_asset_manager): world_asset_manager.apply_malatang_pot_material(root)
func _instantiate_serving_bowl() -> Node3D:
	if is_instance_valid(world_asset_manager): return world_asset_manager.instantiate_serving_bowl()
	return null
func _add_world_serving_bowl(world_position: Vector3) -> Node3D:
	if is_instance_valid(world_asset_manager): return world_asset_manager.add_world_serving_bowl(world_position)
	return null
func _create_food_tray_visual(tray_name: String) -> Node3D:
	if is_instance_valid(world_asset_manager): return world_asset_manager.create_food_tray_visual(tray_name)
	return null
func _add_world_food_tray(world_position: Vector3) -> Node3D:
	if is_instance_valid(world_asset_manager): return world_asset_manager.add_world_food_tray(world_position)
	return null
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
	if is_instance_valid(world_asset_manager): world_asset_manager.apply_serving_bowl_material(root)
func _instantiate_delivery_container() -> Node3D:
	if is_instance_valid(world_asset_manager): return world_asset_manager.instantiate_delivery_container()
	return null
func _apply_delivery_container_material(root: Node) -> void:
	if is_instance_valid(world_asset_manager): world_asset_manager.apply_delivery_container_material(root)
func _add_child_customer_model(customer: Node3D) -> bool:
	if is_instance_valid(world_asset_manager): return world_asset_manager.add_child_customer_model(customer)
	return false
func _import_child_sit_animation(child_model: Node3D) -> void:
	if is_instance_valid(world_asset_manager): world_asset_manager.import_child_sit_animation(child_model)
func _import_child_eating_animation(child_model: Node3D) -> void:
	if is_instance_valid(world_asset_manager): world_asset_manager.import_child_eating_animation(child_model)
func _apply_child_customer_material(root: Node) -> void:
	if is_instance_valid(world_asset_manager): world_asset_manager.apply_child_customer_material(root)
func _add_customer_spoon(customer: Node3D) -> void:
	if is_instance_valid(world_asset_manager): world_asset_manager.add_customer_spoon(customer)
func _apply_spoon_material(root: Node) -> void:
	if is_instance_valid(world_asset_manager): world_asset_manager.apply_spoon_material(root)
func _add_stainless_table_model(world_position: Vector3) -> Node3D:
	if is_instance_valid(world_asset_manager): return world_asset_manager.add_stainless_table_model(world_position)
	return null
func _apply_stainless_table_material(root: Node) -> void:
	if is_instance_valid(world_asset_manager): world_asset_manager.apply_stainless_table_material(root)
func _add_spice_level_3_model(world_position: Vector3) -> Node3D:
	if is_instance_valid(world_asset_manager): return world_asset_manager.add_spice_level_3_model(world_position)
	return null
func _apply_spice_level_material(root: Node) -> void:
	if is_instance_valid(world_asset_manager): world_asset_manager.apply_spice_level_material(root)
func _apply_order_monitor_material(root: Node) -> void:
	if is_instance_valid(world_asset_manager): world_asset_manager.apply_order_monitor_material(root)
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
	if is_instance_valid(carrying_manager): return carrying_manager.add_world_tool_model(path,world_position,rotation,model_scale,is_tongs)
	return null
func _instantiate_empty_bowl() -> Node3D:
	if is_instance_valid(carrying_manager): return carrying_manager.instantiate_empty_bowl()
	return null
func _build_bowl_stack(anchor: Vector3, count: int=5) -> void:
	if is_instance_valid(carrying_manager): carrying_manager.build_bowl_stack(anchor,count)

func _take_bowl_from_stack(take_all: bool=false) -> int:
	if is_instance_valid(carrying_manager): return carrying_manager.take_bowl_from_stack(take_all)
	return 0

func _refresh_held_bowl_stack_visual() -> void:
	if is_instance_valid(carrying_manager): carrying_manager.refresh_held_bowl_stack_visual()
func _apply_ingredient_bowl_material(root: Node) -> void:
	if is_instance_valid(asset_material_manager): asset_material_manager.apply_ingredient_bowl_material(root)
func _apply_empty_bowl_material(root: Node) -> void:
	if is_instance_valid(carrying_manager): carrying_manager.apply_empty_bowl_material(root)
func _set_held_render_front(root: Node) -> void:
	if is_instance_valid(carrying_manager): carrying_manager.set_held_render_front(root)
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
	if is_instance_valid(player_visual_manager): player_visual_manager.update_arm_visibility()
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
	if is_instance_valid(tutorial_manager): tutorial_manager.update_tutorial_page()
func _advance_tutorial() -> void:
	if is_instance_valid(tutorial_manager): tutorial_manager.advance_tutorial()
func _build_ui() -> void:
	ui_manager.build_ui()
func _apply_ui_theme() -> void:
	if is_instance_valid(ui_manager): ui_manager.apply_ui_theme()
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
	if is_instance_valid(ui_manager): return ui_manager.ingredient_icon_path(ingredient_name)
	return ""
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
	if is_instance_valid(ui_manager): ui_manager.refresh_upgrade_panel()

func _purchase_upgrade(key: String, price: int, title: String) -> void:
	if money<price:
		return
	if money<price: result_label.text="?????怨뺤른?????????援쏂굜???????????됱삩???????Β???????釉먮폁????????????怨몄）."; return
	if pending_upgrades.has(key): result_label.text="???? ????關?쒎첎?嫄??????????? ?????????熬곣벀嫄?????꾤뙴??????????怨몄）."; return
	money-=price; pending_upgrades.append(key); result_label.text=title+" ?????????????꾩룆梨띰쭕????????關?쒎첎?嫄???????????"; _save_game(false); _refresh_order_panel(); _refresh_hud()

func _end_day() -> void:
	if is_instance_valid(game_flow_manager): game_flow_manager.end_day()
func _show_settlement_after_transition() -> void:
	if is_instance_valid(ui_manager): ui_manager.show_settlement_after_transition()

func _refresh_settlement_panel() -> void:
	if is_instance_valid(ui_manager): ui_manager.refresh_settlement_panel()
func _start_next_day() -> void:
	if is_instance_valid(game_flow_manager): game_flow_manager.start_next_day()
func _advance_to_next_day() -> void:
	if is_instance_valid(day_manager): day_manager.advance_to_next_day()
func _apply_upgrade_effects() -> void:
	if is_instance_valid(game_flow_manager): game_flow_manager.apply_upgrade_effects()
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
	if is_instance_valid(game_flow_manager): game_flow_manager.apply_store_structure()
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
	if is_instance_valid(ui_manager): ui_manager.close_monitor()
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
	if is_instance_valid(broth_manager): broth_manager.set_pot_carried_collision(carried)
func _set_broth_pot_filled_visual(filled: bool) -> void:
	if is_instance_valid(broth_manager): broth_manager.set_pot_filled_visual(filled)
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
