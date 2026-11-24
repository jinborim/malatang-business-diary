extends Node

## Runs the simulation-only part of the frame loop. Rendering and raycast UI
## remain in main, while timers and recurring gameplay rules live here.

var host: Node

func setup(game_host: Node) -> void:
	host=game_host

func tick(delta: float) -> void:
	if is_instance_valid(host.held_collision_area):
		var carrying_object:bool=host._has_any_held_object()
		host.held_collision_area.monitoring=carrying_object
		if host.has_broth_pot: host.held_collision_area.position=Vector3(0.04,-0.68,-1.54)
		elif host.has_broth_stock_pack: host.held_collision_area.position=Vector3(0.36,-0.50,-1.34)
		else: host.held_collision_area.position=Vector3(0.34,-0.50,-1.20)
		if carrying_object and is_instance_valid(host.player_body):
			var held_blocked: bool = host._is_held_blocked_by_placeable()
			if held_blocked:
				if not host.held_collision_was_blocked and host.held_safe_player_position!=Vector3.ZERO: host.player_body.global_position=host.held_safe_player_position
				host.player_body.velocity=Vector3.ZERO; host.held_collision_was_blocked=true
			else:
				host.held_safe_player_position=host.player_body.global_position; host.held_collision_was_blocked=false
			host._update_held_preview(host.held_collision_was_blocked)
		else:
			host.held_collision_was_blocked=false; host._update_held_preview(false)
	if is_instance_valid(host.player_body) and host.player_body.global_position.y < -3.0:
		host.player_body.global_position=Vector3(0,1.1,-2.5 if host.store_stage==1 else 3.0); host.player_body.velocity=Vector3.ZERO
	host.game_clock_minutes+=delta*host.GAME_MINUTES_PER_REAL_MINUTE/60.0
	var clock_minute:=int(host.game_clock_minutes)
	if clock_minute!=host.last_clock_minute:
		host.last_clock_minute=clock_minute; host._refresh_hud()
		if is_instance_valid(host.order_panel) and host.order_panel.visible: host._refresh_order_panel()
	if host.game_clock_minutes>=float(host.CLOSING_HOUR*60) and host.auto_close_day!=host.day and host.monitor_mode!="settlement":
		if not host.current_order.is_empty(): host._fail_order()
		if not host.cooking and not host.cooked_food.is_empty(): host.cooked_food.clear(); host._clear_basket_visuals()
		if host.pending_customer_payment>0:
			host.pending_customer_payment=0; host.pending_customer_stars=0.0
			if is_instance_valid(host.active_customer): host.active_customer.call("leave_after_payment",host.CUSTOMER_EXIT_POSITION)
		if host.current_order.is_empty() and not host.cooking: host.auto_close_day=host.day; host._end_day()
	host._update_player_animation(); host._update_player_arm_visibility(); host._update_held_tool_stabilization(); host._update_pending_order_deadlines(delta)
	if host._is_shop_open() and host.orders.is_empty() and host.current_order.is_empty(): host._generate_orders()
	if host.courier_ready and not host.cooked_food.is_empty():
		host.courier_wait_seconds+=delta
		if host.courier_wait_seconds>=10.0: host._set_courier_status(host.delivery_courier,"Waiting... %d sec"%int(host.courier_wait_seconds),Color("#ff9d8e"))
	var table_capacity:int=4 if host.store_stage>=3 else 2
	if host._is_shop_open() and host.dining_unlocked and is_instance_valid(host.customer_manager) and host.customer_manager.has_capacity(table_capacity):
		host.customer_spawn_timer-=delta
		if host.customer_spawn_timer<=0.0: host.customer_spawn_timer=12.0; host._spawn_customer()
	if not host.current_order.is_empty():
		host.remaining_time=maxf(0.0,host.remaining_time-delta)
		if host.remaining_time<=0.0: host._fail_order()
		elif int(host.remaining_time)%2==0: host._refresh_hud()
	if host.has_ladle and host.ladle_state=="empty":
		if Input.is_key_pressed(KEY_1): host.selected_spice=1; host._refresh_held_ladle_model(); host._refresh_hud()
		elif Input.is_key_pressed(KEY_2): host.selected_spice=2; host._refresh_held_ladle_model(); host._refresh_hud()
		elif Input.is_key_pressed(KEY_3): host.selected_spice=3; host._refresh_held_ladle_model(); host._refresh_hud()
