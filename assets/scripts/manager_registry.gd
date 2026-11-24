extends Node

## Creates and wires the gameplay managers used by main.gd.
##
## Keeping this dependency list in one place makes startup changes safer:
## manager construction order, setup arguments, and signal connections are no
## longer mixed with world/UI initialization in the scene controller.

const MANAGER_SPECS := [
	{"property": "customer_manager", "script": "customer_manager.gd", "node_name": "CustomerManager"},
	{"property": "save_manager", "script": "save_manager.gd", "node_name": "SaveManager"},
	{"property": "order_manager", "script": "order_manager.gd", "node_name": "OrderManager"},
	{"property": "cooking_manager", "script": "cooking_manager.gd", "node_name": "CookingManager"},
	{"property": "day_manager", "script": "day_manager.gd", "node_name": "DayManager"},
	{"property": "economy_manager", "script": "economy_manager.gd", "node_name": "EconomyManager"},
	{"property": "service_manager", "script": "service_manager.gd", "node_name": "ServiceManager"},
	{"property": "interaction_manager", "script": "interaction_manager.gd", "node_name": "InteractionManager"},
	{"property": "carrying_manager", "script": "carrying_manager.gd", "node_name": "CarryingManager"},
	{"property": "broth_manager", "script": "broth_manager.gd", "node_name": "BrothManager"},
	{"property": "ui_manager", "script": "ui_manager.gd", "node_name": "UIManager"},
	{"property": "tutorial_manager", "script": "tutorial_manager.gd", "node_name": "TutorialManager"},
	{"property": "placement_manager", "script": "placement_manager.gd", "node_name": "PlacementManager"},
	{"property": "asset_material_manager", "script": "asset_material_manager.gd", "node_name": "AssetMaterialManager"},
	{"property": "player_visual_manager", "script": "player_visual_manager.gd", "node_name": "PlayerVisualManager"},
	{"property": "ingredient_manager", "script": "ingredient_manager.gd", "node_name": "IngredientManager"},
	{"property": "courier_manager", "script": "courier_manager.gd", "node_name": "CourierManager"},
	{"property": "world_manager", "script": "world_manager.gd", "node_name": "WorldManager"},
	{"property": "layout_manager", "script": "layout_manager.gd", "node_name": "LayoutManager"},
	{"property": "game_clock_manager", "script": "game_clock_manager.gd", "node_name": "GameClockManager"},
	{"property": "game_loop_manager", "script": "game_loop_manager.gd", "node_name": "GameLoopManager"},
	{"property": "lifecycle_manager", "script": "lifecycle_manager.gd", "node_name": "LifecycleManager"},
	{"property": "world_asset_manager", "script": "world_asset_manager.gd", "node_name": "WorldAssetManager"},
	{"property": "game_flow_manager", "script": "game_flow_manager.gd", "node_name": "GameFlowManager"},
]

const SCRIPT_ROOT := "res://assets/scripts/"
var host: Node

func setup(game_host: Node, ingredients: Array, opening_hour: int, customer_exit: Vector3) -> void:
	host = game_host
	_create_managers(ingredients, opening_hour, customer_exit)

func _create_managers(ingredients: Array, opening_hour: int, customer_exit: Vector3) -> void:
	for spec in MANAGER_SPECS:
		var manager_script: Script = load(SCRIPT_ROOT + str(spec["script"])) as Script
		var manager: Node
		if manager_script:
			manager = manager_script.new() as Node
		if not is_instance_valid(manager):
			push_error("Could not create manager: " + str(spec["script"]))
			continue
		manager.name = str(spec["node_name"])
		host.add_child(manager)
		host.set(str(spec["property"]), manager)
		_setup_manager(manager, str(spec["property"]), ingredients, opening_hour, customer_exit)

	var cooking_manager: Node = host.get("cooking_manager")
	if is_instance_valid(cooking_manager):
		cooking_manager.connect("cooking_finished", Callable(host, "_on_cooking_finished"))

func _setup_manager(manager: Node, property_name: String, ingredients: Array, opening_hour: int, customer_exit: Vector3) -> void:
	match property_name:
		"order_manager": manager.call("setup", host, ingredients)
		"day_manager": manager.call("setup", host, opening_hour, customer_exit)
		_:
			manager.call("setup", host)
