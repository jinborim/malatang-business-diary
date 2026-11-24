extends Node

# 입력과 마우스 상호작용을 main.gd에서 분리한 매니저입니다.
var host

func setup(game_host: Node) -> void:
	host=game_host

func tutorial_allows_interaction(_type: String) -> bool:
	return true

func find_nearby_interaction(origin: Vector3, forward: Vector3) -> Node:
	var best: Node=null
	var best_score:=INF
	for candidate in host.get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(candidate) or not candidate is Node3D: continue
		var node:=candidate as Node3D
		if not node.is_inside_tree() or not node.has_meta("interaction"): continue
		if bool(node.get_meta("interaction_disabled",false)): continue
		if not tutorial_allows_interaction(str(node.get_meta("interaction_type",""))): continue
		var offset:=node.global_position-origin
		var distance:=offset.length()
		if distance>2.6 or distance<0.05: continue
		var aim:=forward.dot(offset.normalized())
		if aim<0.88: continue
		var score:=distance+(1.0-aim)*2.5
		if score<best_score: best_score=score; best=node
	return best

func is_left_click_interaction(interaction_type: String) -> bool:
	if not is_instance_valid(host): return false
	return interaction_type in ["ingredient", "spice", "toggle_tongs", "toggle_bowl", "toggle_steel_bowl", "toggle_ladle", "broth_stock", "broth", "pot", "food_tray"] or (interaction_type=="place_surface" and host._has_any_held_object())

func handle_input(event: InputEvent) -> void:
	if not is_instance_valid(host): return
	if event is InputEventMouseButton:
		var mouse_event:=event as InputEventMouseButton
		var carrying_object:bool=host._has_any_held_object()
		if mouse_event.pressed and mouse_event.button_index==MOUSE_BUTTON_RIGHT and carrying_object:
			host.held_place_rotation_y=fmod(host.held_place_rotation_y+90.0,360.0)
			host._update_held_preview(host.held_collision_was_blocked)
			get_viewport().set_input_as_handled()
			return
		if mouse_event.pressed and mouse_event.button_index==MOUSE_BUTTON_LEFT and is_instance_valid(host.focused_interaction):
			var interaction_type:=str(host.focused_interaction.get_meta("interaction_type",""))
			if is_left_click_interaction(interaction_type):
				host._handle_interaction(host.focused_interaction,true,mouse_event.shift_pressed)
				get_viewport().set_input_as_handled()
				return
	if not event is InputEventKey: return
	var key_event:=event as InputEventKey
	if host.tutorial_active and key_event.pressed and not key_event.echo and key_event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:
		host._advance_tutorial()
		get_viewport().set_input_as_handled()
func handle_interaction(node: Node, from_mouse: bool=false, whole_stack: bool=false) -> void:
	var type:=str(node.get_meta("interaction_type","")); var value=node.get_meta("interaction_value",null)
	# A ladle contents only survives while pouring into the intended target.
	# Interacting with any unrelated station empties it back to the normal ladle.
	if host.has_ladle and host.ladle_state!="empty" and type not in ["broth","pot","toggle_bowl","spice"]:
		host._set_ladle_state("empty")
	if type=="spice":
		if not host.cooking_pot_broth_added:
			host.result_label.text="먼저 국자로 조리 냄비에 육수를 넣어주세요."
			host._refresh_hud()
			return
		if not host.has_ladle:
			host.result_label.text="맵기를 선택하려면 먼저 국자를 들어주세요."
			host._refresh_hud()
			return
		if host.ladle_state!="empty":
			host.result_label.text="국자가 비어 있을 때만 맵기를 담을 수 있습니다."
			host._refresh_hud()
			return
		host.selected_spice=int(value)
		host._refresh_held_ladle_model()
		host._play_ladle_scoop_animation()
		host.result_label.text="맵기 %d단계를 국자에 담았습니다."%host.selected_spice
		host._refresh_hud()
		return
	match type:
		"monitor": host._open_monitor()
		"food_tray": host._pickup_food_tray()
		"toggle_tongs":
			if not host.has_tongs and host._has_any_held_object():
				host.result_label.text="물건은 한 번에 하나만 들 수 있습니다. 먼저 들고 있는 물건을 내려놓으세요."
				host._refresh_hud()
				return
			host.has_tongs=not host.has_tongs
			host._update_held_tool_visibility()
			if host.has_tongs: host._play_tool_pickup_animation(host.held_tongs,host.tongs_hand)
			host.result_label.text="집게를 들었습니다." if host.has_tongs else "집게를 작업대에 내려놓았습니다."
		"toggle_bowl":
			if host.has_ladle and host.ladle_state=="malatang":
				host._set_ladle_state("empty")
				if is_instance_valid(host.serving_bowl_view): host.serving_bowl_view.visible=true
				host.result_label.text="완성된 마라탕을 그릇에 담았습니다. 손님에게 가져다주세요."
				host._refresh_hud()
				return
			if host.has_ladle and host.ladle_state!="empty":
				host._empty_ladle()
				host.result_label.text="국자 내용물을 그릇으로 옮겼습니다. 일반 국자로 돌아왔습니다."
				host._refresh_hud()
				return
			if not host.cooked_food.is_empty():
				# 완성 그릇을 받을 때 기존 도구는 자동으로 작업대에 돌려놓습니다.
				host.has_tongs=false
				host.has_bowl=false
				host._update_held_tool_visibility()
				if host.has_tongs or host.has_bowl:
					host.result_label.text="완성 그릇을 들기 전에 집게와 재료 그릇을 먼저 내려놓으세요."
				else:
					if not is_instance_valid(host.serving_bowl_view):
						host.serving_bowl_view=host._instantiate_serving_bowl()
						if is_instance_valid(host.serving_bowl_view):
							host.serving_bowl_view.name="HeldServingBowl"
							host.serving_bowl_view.position=Vector3(-0.48,-0.42,-0.92)
							host.serving_bowl_view.rotation_degrees=Vector3(8,0,0)
							host.serving_bowl_view.scale=Vector3.ONE*0.22
							host.camera.add_child(host.serving_bowl_view)
					if is_instance_valid(host.serving_bowl_view): host.serving_bowl_view.visible=true
					host.result_label.text="완성 그릇을 들었습니다. 테이블까지 가져가세요."
				host._update_held_tool_visibility()
				return
			if bool(node.get_meta("placed_empty_bowl",false)) and host.has_bowl:
				host.result_label.text="먼저 들고 있는 접시를 내려놓으세요."
				host._refresh_hud()
				return
			if not host.has_bowl and host._has_any_held_object():
				host.result_label.text="물건은 한 번에 하나만 들 수 있습니다. 먼저 들고 있는 물건을 내려놓으세요."
				host._refresh_hud()
				return
			if not host.has_bowl:
				if bool(node.get_meta("placed_empty_bowl",false)):
					node.queue_free()
				else:
					# 처음 그릇 더미를 집을 때는 더미 전체를 한 번에 듭니다.
					host.held_bowl_count=host._take_bowl_from_stack(true)
					if host.held_bowl_count<=0:
						host.held_bowl_count=1 if bool(node.get_meta("placed_empty_bowl",false)) else 0
				if host.held_bowl_count<=0:
					host.result_label.text="빈 그릇이 없습니다."
					host._refresh_hud()
					return
				host.has_bowl=true
				host._update_held_tool_visibility()
				host._play_tool_pickup_animation(host.held_bowl,host.bowl_hand)
				host.result_label.text="빈 그릇 %d개를 들었습니다."%host.held_bowl_count
			else:
				host.has_bowl=false
				host.held_bowl_count=0
				host._update_held_tool_visibility()
				host.result_label.text="빈 그릇을 내려놓을 준비가 되었습니다."
		"toggle_steel_bowl":
			if not host.has_steel_bowl:
				host.has_steel_bowl=true
				if is_instance_valid(host.world_steel_bowl): host.world_steel_bowl.visible=false
				host._update_held_tool_visibility()
				host.result_label.text="쇠그릇을 양손으로 들었습니다."
			else:
				host.has_steel_bowl=false
				host._update_held_tool_visibility()
				host.result_label.text="쇠그릇을 내려놓을 준비가 되었습니다."
			host._refresh_hud()
		"toggle_ladle":
			if not host.has_ladle and host._has_any_held_object():
				host.result_label.text="물건은 한 번에 하나만 들 수 있습니다. 먼저 들고 있는 물건을 내려놓으세요."
				host._refresh_hud()
				return
			if host.has_ladle:
				host._empty_ladle()
				host.has_ladle=false
				host.result_label.text="국자를 내려놓았습니다."
			else:
				host.has_ladle=true
				host._set_ladle_state("empty")
				host.result_label.text="일반 국자를 들었습니다."
			host._update_held_tool_visibility()
			if host.has_ladle and is_instance_valid(host.held_ladle): host._play_tool_pickup_animation(host.held_ladle,host.tongs_hand)
		"ingredient":
			if host.current_order.is_empty(): host.result_label.text="먼저 주문을 수락하세요."
			elif not host.cooking_pot_broth_added: host.result_label.text="먼저 국자로 조리 냄비에 육수를 넣어주세요."
			elif not host.has_tongs: host.result_label.text="작업대에서 집게를 먼저 집어주세요."
			elif not host.cooked_food.is_empty(): host.result_label.text="이미 조리가 끝났습니다."
			elif int(host.stock.get(str(value),0))<=0: host.result_label.text=str(value)+" 재고가 없습니다."
			else:
				host.basket.append(str(value)); host.stock[str(value)]=int(host.stock.get(str(value),0))-1; host._animate_tongs_and_add_visual(str(value)); host.result_label.text=str(value)+" 담기 완료"
		"spice":
			host.selected_spice=int(value); host.result_label.text="맵기 %d단계를 선택했습니다."%host.selected_spice
		"pot":
			if host.has_ladle and host.ladle_state=="broth":
				host.broth_servings=maxi(0,host.broth_servings-1)
				host.cooking_pot_broth_added=true
				host._update_broth_liquid_visual()
				if host.broth_servings<=0:
					host._set_broth_pot_filled_visual(false)
				host._set_ladle_state("empty")
				host.result_label.text="육수를 조리 냄비에 부었습니다. 재료와 소스를 넣고 끓여주세요."
			elif host.has_ladle and host.ladle_state=="empty" and not host.cooked_food.is_empty():
				host._set_ladle_state("malatang")
				host.result_label.text="마라탕을 국자에 담았습니다. 그릇으로 옮겨주세요."
			else:
				host._start_cooking()
		"broth_water": host._add_broth_water()
		"broth_pot_drop": host._drop_broth_pot_at_home()
		"sink_water": host._run_sink_water()
		"broth_stock":
			if bool(node.get_meta("placed_broth_stock",false)):
				host._pickup_placed_broth_stock(node)
			elif host._broth_stock_node_is_open(node) or host.broth_stock_open_in_world:
				# Once the pack has been opened, E should pick up the opened pack,
				# including when the ray still reaches the old source proxy.
				host._pickup_broth_stock_pack(true)
			elif from_mouse:
				# The visible open FBX and the hidden interaction proxy can be
				# different nodes. Synchronize from the node actually hit.
				var clicked_open:bool=host.broth_stock_open_in_world or node==host.broth_stock_open_model or bool(node.get_meta("broth_stock_open",false))
				host._pickup_broth_stock_pack(clicked_open)
			else: host._open_broth_stock_at_source(node)
		"broth_base": host._add_broth_base()
		"broth":
			host._sync_held_broth_stock_state()
			if host.has_broth_stock_pack:
				if host.broth_stock_pack_open: host._add_broth_stock_from_pack()
				else: host._open_broth_stock_pack()
			elif host.has_broth_pot:
				host._toggle_broth_pot()
			elif host.has_ladle and host.ladle_state=="empty" and host.broth_servings>0:
				host._set_ladle_state("broth")
				host._play_ladle_scoop_animation()
				host.result_label.text="육수를 국자에 담았습니다. 다른 곳으로 옮겨주세요."
			elif host.broth_water_added or host.broth_stock_added or host.broth_base_added:
				host._make_broth()
			else:
				host._toggle_broth_pot()
		"delivery": host._deliver_food()
		"courier": host._deliver_food(int(value))
		"customer_order": host._accept_customer_order(node)
		"customer_payment": host._accept_customer_payment()
		"table": host._serve_table(node)
		"place_surface": host._place_held_object_on_table(node,whole_stack)
		"trash":
			if host.has_broth_stock_pack:
				host.has_broth_stock_pack=false
				host.broth_stock_pack_open=false
				host._update_held_tool_visibility()
				host.result_label.text="뜯은 사골 육수 포장지를 버렸습니다."
				host._refresh_hud()
				return
			host.basket.clear(); host._clear_basket_visuals(); host.result_label.text="바구니를 비웠습니다."
	host._refresh_hud()

func update_frame_interaction() -> bool:
	if host.order_panel and host.order_panel.visible:
		host._set_highlight(null)
		if Input.is_action_just_pressed("ui_cancel"): host._close_monitor()
		return true
	var floor_surface:=get_node_or_null("Floor") as Node3D
	if is_instance_valid(floor_surface):
		var carrying_object:bool=host._has_any_held_object()
		floor_surface.set_meta("interaction_disabled",not carrying_object)
	host._set_dining_table_interaction_collision(is_instance_valid(host.serving_bowl_view) and host.serving_bowl_view.visible)
	var from:Vector3=host.camera.global_position; var forward:Vector3=-host.camera.global_basis.z; var to:Vector3=from + forward*7.0
	var q:=PhysicsRayQueryParameters3D.create(from,to); var hit:Dictionary=host.get_world_3d().direct_space_state.intersect_ray(q)
	host.prompt_label.text=""
	host.focused_interaction=null
	if is_instance_valid(host.prompt_background): host.prompt_background.visible=false
	if is_instance_valid(host.prompt_mouse_icon): host.prompt_mouse_icon.visible=false
	var highlight_target:Node=null
	var fallback_interaction:Node=null
	if hit:
		var n:Node=hit.collider
		while n and not n.has_meta("interaction"): n=n.get_parent()
		if n and bool(n.get_meta("interaction_disabled",false)): n=null
		if n and not host._tutorial_allows_interaction(str(n.get_meta("interaction_type",""))): n=null
		# While carrying an object, do not let the carried pot's old broth/drop
		# proxy consume E. The surface under the crosshair must handle placement.
		if n and host._has_any_held_object():
			var hit_type:=str(n.get_meta("interaction_type",""))
			# A carried host.stock pack, ladle, or bowl must still be able to interact
			# with the broth pot. Only hide the pot's old proxy while the pot itself
			# is the object being carried.
			if host.has_broth_pot and hit_type in ["broth", "broth_pot_drop"]: n=null
		fallback_interaction=n
	# Placement surfaces can be invisible guide planes, so they may not be
	# returned by the physics ray or nearby-node search. Still expose the same
	# generic "내려놓기" action when the host.camera is aimed at a valid surface.
	if not fallback_interaction and host._has_any_held_object():
		var placement_surface:Node3D=host._get_placement_surface_from_view()
		if is_instance_valid(placement_surface): fallback_interaction=placement_surface
	# When an object is being carried, never fall back to a nearby interaction.
	# The nearby search can find the carried pot's original proxy and make the
	# pot appear to teleport back when E is pressed. While carrying, only the
	# ray-hit interaction (for example the sink) or a placement surface may
	# receive the interaction key.
	var carrying_object_now:bool=host._has_any_held_object()
	if not fallback_interaction and not carrying_object_now:
		fallback_interaction=host._find_nearby_interaction(from,forward)
	# A floor/table placement proxy must never be interactive while empty-handed.
	# Otherwise the player sees "내려놓기" and E reports that there is no item.
	if fallback_interaction and str(fallback_interaction.get_meta("interaction_type",""))=="place_surface" and not carrying_object_now:
		fallback_interaction=null
	if fallback_interaction:
		var n:=fallback_interaction
		if n:
			host.focused_interaction=n
			highlight_target=n
			# 배치 판정용 투명 표면은 실제 오브젝트가 아니므로
			# 하이라이트 외곽선을 만들지 않는다. 이 표면을 강조하면
			# 스텐리 테이블 전체가 초록색으로 채워져 보인다.
			if str(n.get_meta("interaction_type",""))=="place_surface":
				highlight_target=null
			var explicit_target:Variant=null
			if n.has_meta("highlight_target"):
				explicit_target=n.get_meta("highlight_target")
			if explicit_target is Node and is_instance_valid(explicit_target): highlight_target=explicit_target
			if str(n.get_meta("interaction_type",""))=="delivery":
				highlight_target=null
			if str(n.get_meta("interaction_type",""))=="monitor":
				var monitor_visual:=host.get_node_or_null("EditableModels/OrderMonitorModel") as Node3D
				if not monitor_visual: monitor_visual=host.get_node_or_null("OrderMonitorModel") as Node3D
				if is_instance_valid(monitor_visual): highlight_target=monitor_visual
			if str(n.get_meta("interaction_type","")) in ["customer_order","customer_payment"] and n.name=="CustomerInteractionProxy":
				highlight_target=n.get_parent()
		# 테이블과 손님은 메시지 전체가 초록색으로 채워질 수 있어
		# 외곽선 효과를 표시하지 않습니다. 상호작용과 E키 문구는 유지합니다.
		if n:
			if is_instance_valid(host.prompt_background): host.prompt_background.visible=true
			if str(n.get_meta("interaction_type",""))=="broth_stock":
				var stock_is_open:bool=host._broth_stock_node_is_open(n) or host.broth_stock_open_in_world
				host.prompt_label.text="[🖱 왼쪽] 집기" if stock_is_open else "[🖱 왼쪽] 집기\n[E] 절취선 뜯기"
				if is_instance_valid(host.prompt_mouse_icon): host.prompt_mouse_icon.visible=true
			else:
				var interaction_type:=str(n.get_meta("interaction_type",""))
				var use_mouse:bool=host._is_left_click_interaction(interaction_type)
				if is_instance_valid(host.prompt_mouse_icon): host.prompt_mouse_icon.visible=use_mouse
				if interaction_type=="toggle_bowl" and not host.has_bowl and not host.bowl_stack_models.is_empty():
					host.prompt_label.text="[왼쪽 클릭] 전체 그릇 집기"
				elif interaction_type=="place_surface" and host.has_bowl and host.held_bowl_count>1:
					host.prompt_label.text="[왼쪽 클릭] 그릇 하나 놓기\n[Shift 키 + 왼쪽 클릭] 전체 놓기"
				elif interaction_type=="spice" and host.has_ladle:
					host.prompt_label.text="[왼쪽 클릭] 국자로 맵기 단계 담기"
				else:
					host.prompt_label.text=("[왼쪽 클릭] " if use_mouse else "[E 키] ") + str(n.get_meta("interaction"))
			host._place_interaction_prompt_near(n)
			if Input.is_action_just_pressed("interact"): host._handle_interaction(n)
	host._set_highlight(highlight_target)

	return false
