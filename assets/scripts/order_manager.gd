extends Node

var host
var ingredients: Array

func setup(game_host: Node, source_ingredients: Array) -> void:
	host=game_host
	ingredients=source_ingredients

func generate_orders() -> void:
	if not host or not host._is_shop_open():
		if host: host.orders.clear()
		return
	host.orders.clear()
	for index in 3:
		host.orders.append(make_delivery_order())
	host._refresh_order_panel()

func make_delivery_order() -> Dictionary:
	var shuffled:=ingredients.duplicate()
	shuffled.shuffle()
	var max_ingredients:int=mini(ingredients.size(),6+floori(float(host.day-1)/2.0))
	var count:=randi_range(1,max_ingredients)
	var wanted:Array[String]=[]
	for index in count:
		wanted.append(str(shuffled[index][0]))
	var order_id: int = int(host.next_delivery_order_id)
	host.next_delivery_order_id+=1
	var difficulty_time_bonus:int=mini(45,(host.day-1)*4)
	return {"id":order_id,"ingredients":wanted,"spice":randi_range(1,3),"reward":5000+count*850,"time":randi_range(180,240)-difficulty_time_bonus,"accept_time":180,"channel":"delivery"}

func update_deadlines(delta: float) -> void:
	if not host or not host._is_shop_open():
		if host: host.orders.clear()
		return
	if host.orders.is_empty(): return
	var expired_count:=0
	for index in range(host.orders.size()-1,-1,-1):
		host.orders[index]["accept_time"]=maxf(0.0,float(host.orders[index].get("accept_time",45.0))-delta)
		if float(host.orders[index]["accept_time"])<=0.0:
			host.orders.remove_at(index)
			expired_count+=1
	for index in expired_count:
		host.orders.append(make_delivery_order())
	if expired_count>0:
		host.result_label.text="주문 수락 시간이 지나 %d건이 취소되었습니다."%expired_count
	host.pending_order_ui_tick+=delta
	if host.pending_order_ui_tick>=0.5:
		host.pending_order_ui_tick=0.0
		if host.order_panel and host.order_panel.visible and host.monitor_mode=="orders": host._refresh_order_panel()

func accept_order(selected_order: Dictionary) -> void:
	if not host or selected_order.is_empty(): return
	host._set_receipt_open(true)
	if not host._is_shop_open():
		host.result_label.text="영업시간은 오전 10시부터 오후 10시까지입니다."
		return
	if not host.current_order.is_empty():
		host.result_label.text="이미 진행 중인 주문이 있습니다."
		return
	host.current_order=selected_order.duplicate(true)
	host.orders.erase(selected_order)
	host.basket.clear()
	host._clear_basket_visuals()
	host.selected_spice=0
	host.cooked_food.clear()
	host.remaining_time=float(host.current_order["time"])
	host.result_label.text="주문을 수락했습니다."
	host._close_monitor()
	host._refresh_hud()
	if str(host.current_order.get("channel","delivery"))!="dinein": host._summon_courier()
