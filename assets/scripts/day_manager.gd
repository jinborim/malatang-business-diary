extends Node

var host
var opening_hour:=10
var exit_position:=Vector3.ZERO

func setup(game_host, start_hour: int, customer_exit: Vector3) -> void:
	host=game_host
	opening_hour=start_hour
	exit_position=customer_exit

func show_next_day_confirmation() -> void:
	if is_instance_valid(host) and is_instance_valid(host.next_day_confirmation):
		host.next_day_confirmation.popup_centered(Vector2(520,240))

func advance_to_next_day() -> void:
	if not host: return
	host.day+=1
	host.daily_sales=0
	host.daily_material_cost=0
	host.daily_completed_orders=0
	host.daily_rating_total=0.0
	host.game_clock_minutes=opening_hour*60.0
	host.auto_close_day=0
	host.current_order.clear()
	host.customer_order.clear()
	host.basket.clear()
	host.cooked_food.clear()
	host.selected_spice=0
	host.remaining_time=0.0
	host.cooking=false
	host.pending_customer_payment=0
	host.pending_customer_stars=0.0
	host._clear_basket_visuals()
	host._reset_courier()
	if is_instance_valid(host.customer_manager): host.customer_manager.clear_for_new_day(exit_position)
	host.active_customer=null
	host.active_customer_table_position=Vector3.ZERO
	for key in host.pending_upgrades:
		if key=="stage2":
			host.store_stage=maxi(host.store_stage,2)
			host.dining_unlocked=true
		elif key=="stage3":
			host.store_stage=maxi(host.store_stage,3)
			host.dining_unlocked=true
		else:
			host.upgrade_levels[key]=int(host.upgrade_levels.get(key,0))+1
	host.pending_upgrades.clear()
	# Reload the selected editable layout after applying upgrades. Without this,
	# the saved stage value changed but the old stage's scene stayed instantiated.
	host._load_stage_layout()
	host._apply_store_structure()
	host._apply_upgrade_effects()
	host._generate_orders()
	host.result_label.text="%d일차 영업을 시작합니다. 가게 %d단계"%[host.day,host.store_stage]
	host.monitor_mode="orders"
	host._save_game(false)
	host._refresh_order_panel()
	host._refresh_hud()
