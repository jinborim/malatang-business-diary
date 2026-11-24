extends Node

## 매장 서비스 한 건의 상태를 관리합니다.
## 손님 주문부터 결제까지의 데이터만 담당하고, 이동·UI·월드 오브젝트는 main이 담당합니다.

signal state_changed(previous_state: String, next_state: String)
signal service_started(customer: Node, order: Dictionary)
signal payment_ready(amount: int, stars: float, review: String)
signal service_completed(amount: int, stars: float)

const IDLE := "idle"
const COOKING := "cooking"
const EATING := "eating"
const WAITING_PAYMENT := "waiting_payment"

var state := IDLE
var customer: Node
var table_position := Vector3.ZERO
var order: Dictionary = {}
var payment_amount := 0
var payment_stars := 0.0
var payment_review := ""
var host: Node

func setup(game_host: Node) -> void:
	host=game_host

func has_active_service() -> bool:
	return state != IDLE

func can_accept_order() -> bool:
	return state == IDLE

func begin_customer_order(selected_customer: Node, selected_order: Dictionary, time_left: float) -> bool:
	if not is_instance_valid(selected_customer) or selected_order.is_empty() or not can_accept_order():
		return false
	customer = selected_customer
	table_position = selected_customer.get_meta("table_position", Vector3.ZERO)
	order = selected_order.duplicate(true)
	order["time"] = time_left
	payment_amount = 0
	payment_stars = 0.0
	payment_review = ""
	_set_state(COOKING)
	service_started.emit(customer, order.duplicate(true))
	return true

func mark_payment_ready(selected_customer: Node, amount: int, stars: float, review: String) -> bool:
	if not is_instance_valid(selected_customer) or amount <= 0:
		return false
	customer = selected_customer
	payment_amount = amount
	payment_stars = stars
	payment_review = review
	_set_state(EATING)
	_set_state(WAITING_PAYMENT)
	payment_ready.emit(payment_amount, payment_stars, payment_review)
	return true

func complete_payment() -> Dictionary:
	if state != WAITING_PAYMENT or payment_amount <= 0:
		return {}
	var result := {
		"customer": customer,
		"table_position": table_position,
		"amount": payment_amount,
		"stars": payment_stars,
		"review": payment_review
	}
	_set_state(IDLE)
	service_completed.emit(int(result["amount"]), float(result["stars"]))
	_clear()
	return result

func reset() -> void:
	_set_state(IDLE)
	_clear()

func accept_customer_order(interaction_node: Node = null) -> void:
	if not is_instance_valid(host): return
	if not host._is_shop_open():
		host.result_label.text="영업시간은 오전 10시부터 오후 10시까지입니다."
		return
	var selected_customer:=interaction_node as CharacterBody3D
	if not selected_customer and interaction_node: selected_customer=interaction_node.get_parent() as CharacterBody3D
	if not is_instance_valid(selected_customer): return
	if host.pending_customer_payment>0:
		host.result_label.text="먼저 계산 대기 중인 손님의 결제를 받아주세요."
		return
	var selected_order: Variant=selected_customer.get_meta("customer_order",{})
	if not selected_order is Dictionary or (selected_order as Dictionary).is_empty(): return
	if not host.current_order.is_empty():
		host.result_label.text="현재 주문을 먼저 완료하세요."
		return
	host.active_customer=selected_customer
	host.active_customer_table_position=selected_customer.get_meta("table_position",Vector3.ZERO)
	host.current_order=(selected_order as Dictionary).duplicate(true)
	selected_customer.set_meta("customer_order",{})
	host.customer_order.clear()
	host.basket.clear()
	host.cooked_food.clear()
	host.selected_spice=0
	host.remaining_time=float(host.current_order["time"])
	if not begin_customer_order(host.active_customer,host.current_order,host.remaining_time):
		host.result_label.text="이미 진행 중인 매장 서비스가 있습니다."
		return
	selected_customer.remove_meta("interaction")
	selected_customer.remove_meta("interaction_type")
	var customer_proxy:=selected_customer.get_node_or_null("CustomerInteractionProxy") as Node3D
	if customer_proxy:
		customer_proxy.remove_meta("interaction")
		customer_proxy.remove_meta("interaction_type")
	selected_customer.call("set_status","주문 확인 · 음식 기다리는 중",Color("#bfe8ff"))
	host.result_label.text="테이블 주문을 받았습니다. 음식을 준비하세요."
	host._refresh_hud()

func accept_customer_payment() -> void:
	if not is_instance_valid(host) or not is_instance_valid(host.active_customer) or host.pending_customer_payment<=0: return
	complete_payment()
	host.active_customer.call("clear_eating_items")
	host.money+=host.pending_customer_payment
	host.daily_sales+=host.pending_customer_payment
	host.daily_completed_orders+=1
	host.daily_rating_total+=host.pending_customer_stars
	host.rating=clampf((host.rating*host.completed_orders+host.pending_customer_stars)/float(host.completed_orders+1),1.0,5.0)
	host.completed_orders+=1
	host.result_label.text="식사 결제 완료 · +%d원"%host.pending_customer_payment
	host.customer_status_label.text="결제를 받았습니다. 손님이 퇴장합니다."
	host.active_customer.remove_meta("interaction")
	host.active_customer.remove_meta("interaction_type")
	host.active_customer.call("leave_after_payment",host.CUSTOMER_EXIT_POSITION)
	host.pending_customer_payment=0
	host.pending_customer_stars=0.0
	host._save_game(false)
	host._refresh_hud()

func deliver_food(courier_order_id: int=-1) -> void:
	if not is_instance_valid(host): return
	if host.cooked_food.is_empty() or host.current_order.is_empty():
		host.result_label.text="전달할 완성품이 없습니다."
		return
	if str(host.current_order.get("channel","delivery"))=="dinein":
		host.result_label.text="이 음식은 매장 손님에게 서빙해야 합니다."
		return
	if not is_instance_valid(host.delivery_container_view) or not host.delivery_container_view.visible:
		host.result_label.text="완성된 음식을 배달 용기에 먼저 담아주세요."
		return
	if not host.courier_ready:
		host.result_label.text="배달원이 카운터에 도착할 때까지 잠시 기다려 주세요."
		return
	var expected_order_id:=int(host.current_order.get("id",-1))
	if courier_order_id>=0 and courier_order_id!=expected_order_id:
		host.rating=maxf(1.0,host.rating-0.15)
		host.result_label.text="잘못된 배달원입니다! 주문 #%d 배달원을 찾으세요. 별점이 감소했습니다."%expected_order_id
		host._set_courier_status(host.delivery_courier,"주문 #%d · 여기입니다!"%expected_order_id,Color("#ff9d8e"))
		host._refresh_hud()
		return
	if host.packaging<=0:
		host.result_label.text="포장 용기가 없습니다. 모니터에서 구매하세요."
		return
	host.packaging-=1
	var expected:Array=host.current_order.ingredients
	var actual:Array=host.cooked_food.ingredients
	var correct:=0
	for item in expected:
		if actual.count(item)>0: correct+=1
	var extra: int=maxi(0,actual.size()-correct)
	var ingredient_score: float=float(correct)/float(maxi(1,expected.size()))
	var spice_ok: bool=int(host.cooked_food["spice"])==int(host.current_order["spice"])
	var delay_penalty: float=clampf(maxf(0.0,host.courier_wait_seconds-10.0)*0.012,0.0,0.25)
	var score: float=clampf(ingredient_score-(float(extra)*0.08)+(0.15 if spice_ok else -0.2)-delay_penalty,0.0,1.0)
	var stars: float=clampf(1.0+score*4.0,1.0,5.0)
	var earned: int=host.economy_manager.delivery_reward(int(host.current_order["reward"]),score)
	host.money+=earned
	host.daily_sales+=earned
	host.daily_completed_orders+=1
	host.daily_rating_total+=stars
	host.rating=clamp((host.rating*host.completed_orders+stars)/(host.completed_orders+1),1.0,5.0)
	host.completed_orders+=1
	var delay_text: String="" if delay_penalty<=0.0 else "  (배달원 대기 지연)"
	host.result_label.text="배달 완료: ★ %.1f  +%d원%s"%[stars,earned,delay_text]
	if is_instance_valid(host.delivery_container_view): host.delivery_container_view.visible=false
	if is_instance_valid(host.courier_package): host.courier_package.visible=true
	host._send_courier_away()
	host._empty_ladle()
	if not host.tutorial_seen and host.tutorial_step==7: host.tutorial_delivery_done=true
	host.current_order.clear()
	host.cooked_food.clear()
	host.selected_spice=0
	if host.orders.is_empty(): host._generate_orders()
	host._save_game(false)
	host._refresh_hud()

func serve_table(target_table: Node = null) -> void:
	if not is_instance_valid(host): return
	if is_instance_valid(target_table) and is_instance_valid(host.active_customer):
		var table_distance:float=target_table.global_position.distance_to(host.active_customer_table_position)
		if table_distance>1.6:
			host.money=maxi(0,host.money-host.WRONG_TABLE_PENALTY)
			host.result_label.text="잘못된 테이블입니다. %d원이 차감되었습니다."%host.WRONG_TABLE_PENALTY
			host._refresh_hud()
			return
	if host.cooked_food.is_empty() or host.current_order.is_empty():
		host.result_label.text="서빙할 음식이 없습니다."
		return
	if str(host.current_order.get("channel","delivery"))!="dinein":
		host.result_label.text="현재 음식은 배달 주문입니다."
		return
	if not host.has_food_tray or not is_instance_valid(host.serving_bowl_view) or not host.serving_bowl_view.visible:
		host.result_label.text="쟁반 위에 완성 음식을 올리고 테이블로 가져가세요."
		return
	var expected:Array=host.current_order["ingredients"]
	var actual:Array=host.cooked_food["ingredients"]
	var correct:=0
	for item in expected:
		if actual.count(item)>0: correct+=1
	var extra:int=maxi(0,actual.size()-correct)
	var ingredient_score:float=float(correct)/float(maxi(1,expected.size()))
	var spice_ok:bool=int(host.cooked_food["spice"])==int(host.current_order["spice"])
	var score:float=clampf(ingredient_score-float(extra)*0.08+(0.15 if spice_ok else -0.2),0.0,1.0)
	var stars:float=clampf(1.0+score*4.0,1.0,5.0)
	var earned:int=host.economy_manager.dine_in_reward(int(host.current_order["reward"]),score,300)
	var review:="정확하고 맛있어요!" if stars>=4.0 else ("조금 아쉬웠어요." if stars>=2.5 else "주문과 다른 음식이 왔어요.")
	host.pending_customer_payment=earned
	host.pending_customer_stars=stars
	mark_payment_ready(host.active_customer,earned,stars,review)
	host.result_label.text="식사 완료 ★ %.1f  · 모니터에서 결제를 받아주세요."%stars
	host.customer_status_label.text="★ %.1f  %s\n손님이 모니터로 이동합니다."%[stars,review]
	if is_instance_valid(host.placed_serving_bowl): host.placed_serving_bowl.queue_free()
	if is_instance_valid(host.placed_food_tray): host.placed_food_tray.queue_free()
	var bowl_position:Vector3=host.active_customer_table_position+Vector3(0,1.38,0)
	if is_instance_valid(host.active_customer):
		var customer_offset:Vector3=host.active_customer.global_position-host.active_customer_table_position
		customer_offset.y=0.0
		customer_offset.x=clampf(customer_offset.x,-0.65,0.65)
		customer_offset.z=clampf(customer_offset.z,-0.27,0.27)
		bowl_position=host.active_customer_table_position+customer_offset+Vector3(0,1.38,0)
	host.placed_serving_bowl=host._add_world_serving_bowl(bowl_position)
	host.serving_bowl_view.visible=false
	if is_instance_valid(host.food_tray_view): host.food_tray_view.visible=false
	host.placed_food_tray=host._add_world_food_tray(bowl_position)
	host.has_food_tray=false
	if is_instance_valid(host.food_tray_world):
		host.food_tray_world.queue_free()
		host.food_tray_world=null
	host._empty_ladle()
	host.current_order.clear()
	host.cooked_food.clear()
	host.selected_spice=0
	if is_instance_valid(host.active_customer): host.active_customer.call("eat_then_pay",host.CUSTOMER_PAYMENT_POSITION,stars,review)
	host._save_game(false)
	host._refresh_hud()

func _set_state(next_state: String) -> void:
	if state == next_state:
		return
	var previous_state := state
	state = next_state
	state_changed.emit(previous_state, next_state)

func _clear() -> void:
	customer = null
	table_position = Vector3.ZERO
	order.clear()
	payment_amount = 0
	payment_stars = 0.0
	payment_review = ""
