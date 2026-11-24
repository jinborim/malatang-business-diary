extends Node

## Loads the editable store shell and keeps layout-specific adjustments out of
## the gameplay controller.

var host: Node

func setup(game_host: Node) -> void:
	host = game_host

func load_stage_layout() -> void:
	var old_layout := host.get_node_or_null("EditableModels")
	if old_layout: old_layout.free()
	var layout_path: String = host.STAGE3_LAYOUT_PATH if host.store_stage >= 3 else host.UNIFIED_LAYOUT_PATH
	var layout_scene := load(layout_path) as PackedScene
	if not layout_scene: return
	var layout := layout_scene.instantiate() as Node3D
	if not layout: return
	layout.name = "EditableModels"
	host.add_child(layout)

func shift_kitchen_layout_toward_wall(layout: Node3D) -> void:
	if not is_instance_valid(layout): return
	var kitchen_names: Array[String] = ["IngredientShowcase_Editable", "CommercialGasStoveModel", "MalatangCookingPotModel", "StainlessPrepTableModel", "KitchenSinkModel_EditorPreview", "BrothPotModel_EditorPreview", "BrothStockPack_EditorPreview", "KitchenTongsPickupModel", "IngredientBowlPickupModel", "SpiceLevel3Editable", "ToolStation", "TongsPickup", "BowlPickup", "KitchenCounter", "BrothStation"]
	for node_name in kitchen_names:
		var node := layout.get_node_or_null(node_name) as Node3D
		if is_instance_valid(node): node.position.z -= 1.0
