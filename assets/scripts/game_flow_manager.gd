extends Node

## Coordinates scene-level game flow without owning the underlying state.
## Persistent values remain on the main scene for compatibility with the
## existing gameplay managers.

var host: Node

func setup(game_host: Node) -> void:
	host=game_host

func end_day() -> void:
	if not host.current_order.is_empty() or host.cooking or not host.cooked_food.is_empty() or host.pending_customer_payment>0:
		host.result_label.text="영업 중인 주문을 먼저 마무리해주세요."
		return
	if not is_instance_valid(host.fade_overlay):
		host._show_settlement_after_transition()
		return
	host.fade_overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	var transition:=host.create_tween()
	transition.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	transition.tween_property(host.fade_overlay,"color",Color(0,0,0,1),0.45)
	transition.tween_callback(host._show_settlement_after_transition)
	transition.tween_interval(0.35)
	transition.tween_property(host.fade_overlay,"color",Color(0,0,0,0),0.55)
	transition.tween_callback(func(): host.fade_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE)

func start_next_day() -> void:
	if not is_instance_valid(host.fade_overlay):
		host._advance_to_next_day()
		return
	host.fade_overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	var transition:=host.create_tween()
	transition.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	transition.tween_property(host.fade_overlay,"color",Color(0,0,0,1),0.45)
	transition.tween_callback(host._advance_to_next_day)
	transition.tween_interval(0.35)
	transition.tween_property(host.fade_overlay,"color",Color(0,0,0,0),0.55)
	transition.tween_callback(func(): host.fade_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE)

func apply_upgrade_effects() -> void:
	var player:=host.get_node_or_null("Player")
	if player: player.speed=5.0+float(host.upgrade_levels["movement"])*0.75

func apply_store_structure() -> void:
	var old_structure:=host.get_node_or_null("StageStructure")
	if not old_structure: old_structure=host.get_node_or_null("EditableModels/StageStructure")
	if not old_structure:
		var structure:=Node3D.new()
		structure.name="StageStructure"
		host.add_child(structure)
	# All upgrades share one continuous shop shell.
	host._create_dining_tables()
