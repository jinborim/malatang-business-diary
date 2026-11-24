extends Node
class_name CustomerManager

var customers: Array[CharacterBody3D] = []
var host: Node

func setup(game_host: Node) -> void:
	host=game_host

func spawn_customer() -> void:
	if not is_instance_valid(host) or not host.dining_unlocked: return
	var table_count:int=4 if host.store_stage>=3 else 2
	if not has_capacity(table_count): return
	var table_index:int=find_free_table(table_count)
	if table_index<0: return
	# 기본 손님은 혼자 방문하므로 테이블의 안쪽 좌석 하나만 사용합니다.
	var seat_index:int=table_index*2
	var customer:=CharacterBody3D.new()
	customer.name="StoreCustomer"
	customer.set_script(load("res://assets/scripts/customer.gd"))
	var collision:=CollisionShape3D.new()
	var shape:=CapsuleShape3D.new()
	shape.radius=0.38
	shape.height=1.75
	collision.shape=shape
	customer.add_child(collision)
	collision.position=Vector3(0,0.25,0)
	if not host._add_child_customer_model(customer):
		host.cylinder("CustomerBody",Vector3(0,0.55,0),0.38,1.1,Color("#6d82a8"),customer,false)
		var head:MeshInstance3D=host.cylinder("CustomerHead",Vector3(0,1.3,0),0.28,0.48,Color("#e1b99c"),customer,false)
		head.rotation_degrees.x=90
	var customer_proxy:MeshInstance3D=host.box("CustomerInteractionProxy",Vector3(0,0.95,0),Vector3(0.9,1.8,0.9),Color(0,0,0,0),customer)
	customer_proxy.visible=false
	var bubble:=Label3D.new()
	bubble.name="StatusBubble"
	bubble.position=Vector3(0,2.05,0)
	bubble.text="입장 중..."
	bubble.font_size=32
	bubble.outline_size=8
	bubble.modulate=Color("#ffffff")
	bubble.outline_modulate=Color("#263238")
	bubble.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	bubble.no_depth_test=true
	customer.add_child(bubble)
	var meal_bowl:MeshInstance3D=host.cylinder("MealBowl",Vector3(0,0.72,-0.72),0.34,0.16,Color("#d9d9d6"),customer,false)
	meal_bowl.name="MealBowl"
	meal_bowl.visible=false
	var broth:MeshInstance3D=host.cylinder("Broth",Vector3(0,0.82,-0.72),0.27,0.035,Color("#b83228"),customer,false)
	broth.name="MealBroth"
	broth.visible=false
	host.add_child(customer)
	register_customer(customer)
	var seat_position:Vector3=host._dining_seat_position(seat_index)
	var table_center_position:Vector3=host._dining_table_center_position(table_index)
	customer.set_meta("table_index",table_index)
	customer.set_meta("table_position",Vector3(table_center_position.x,0.65,table_center_position.z))
	customer.call("setup",host,host.CUSTOMER_EXIT_POSITION,seat_position)
	var table_center:=Vector3(table_center_position.x,customer.global_position.y,table_center_position.z)
	customer.set_meta("table_center",table_center)
	customer.look_at(table_center,Vector3.UP)

func dining_table_center_position(table_index: int) -> Vector3:
	var row:int=floori(float(table_index)/2.0)
	var column:int=table_index%2
	var fallback:=Vector3(1.8+column*3.2,0.65,0.9+row*3.0)
	if not is_instance_valid(host): return fallback
	var area:=host.get_node_or_null("EditableModels/DiningArea") as Node3D
	if not area: area=host.get_node_or_null("DiningArea") as Node3D
	if area:
		var table_model:=area.get_node_or_null("DiningTableModel_%d"%(table_index+1)) as Node3D
		if is_instance_valid(table_model): return table_model.global_position
	return fallback

func dining_seat_position(seat_index: int) -> Vector3:
	var table_index:int=floori(float(seat_index)/2.0)
	var side:int=-1 if seat_index%2==0 else 1
	if is_instance_valid(host):
		var area:=host.get_node_or_null("EditableModels/DiningArea") as Node3D
		if not area: area=host.get_node_or_null("DiningArea") as Node3D
		if area:
			var chair_model:=area.get_node_or_null("ChairModel_%d_%d"%[table_index,side]) as Node3D
			if is_instance_valid(chair_model): return Vector3(chair_model.global_position.x,0.9,chair_model.global_position.z)
	var table_center:=dining_table_center_position(table_index)
	return Vector3(table_center.x,0.9,table_center.z+side*1.35)

func cleanup_invalid() -> void:
	for index in range(customers.size() - 1, -1, -1):
		if not is_instance_valid(customers[index]):
			customers.remove_at(index)

func has_capacity(capacity: int) -> bool:
	cleanup_invalid()
	return customers.size() < capacity

func occupied_table_indices() -> Array[int]:
	cleanup_invalid()
	var occupied: Array[int] = []
	for customer in customers:
		if is_instance_valid(customer):
			occupied.append(int(customer.get_meta("table_index", -1)))
	return occupied

func find_free_table(capacity: int) -> int:
	var occupied:=occupied_table_indices()
	for table_index in capacity:
		if not occupied.has(table_index):
			return table_index
	return -1

func register_customer(customer: CharacterBody3D) -> void:
	cleanup_invalid()
	if not customers.has(customer):
		customers.append(customer)

func unregister_customer(customer: CharacterBody3D) -> void:
	customers.erase(customer)

func all_customers() -> Array[CharacterBody3D]:
	cleanup_invalid()
	var copied: Array[CharacterBody3D] = []
	copied.append_array(customers)
	return copied

func clear_for_new_day(exit_position: Vector3) -> void:
	cleanup_invalid()
	for customer in customers:
		if is_instance_valid(customer):
			customer.call("leave_after_payment", exit_position)
	customers.clear()

func prepare_customer_order(customer: CharacterBody3D) -> void:
	if not is_instance_valid(host) or not is_instance_valid(customer): return
	var shuffled:Array=host.INGREDIENTS.duplicate()
	shuffled.shuffle()
	var wanted:Array[String]=[]
	var count:=randi_range(1,5)
	for i in count: wanted.append(str(shuffled[i][0]))
	var order: Dictionary={"id":1000+host.completed_orders+all_customers().size(),"ingredients":wanted,"spice":randi_range(1,3),"reward":6000+count*800,"time":240,"channel":"dinein"}
	customer.set_meta("customer_order",order)
	host.interactable(customer,"손님 주문 받기")
	host.interaction_data(customer,"customer_order")
	var customer_proxy:=customer.get_node_or_null("CustomerInteractionProxy") as Node3D
	if customer_proxy:
		host.interactable(customer_proxy,"손님 주문 받기")
		host.interaction_data(customer_proxy,"customer_order")
	customer.call("set_status","주문할게요! [E]",Color("#fff2a8"))
	host.customer_status_label.text="손님: 주문할게요!\n[E]로 주문을 받아주세요."

func customer_reached_table(customer: CharacterBody3D) -> void:
	prepare_customer_order(customer)

func customer_reached_counter(customer: CharacterBody3D) -> void:
	customer_reached_table(customer)

func customer_reached_payment(customer: CharacterBody3D) -> void:
	if not is_instance_valid(host) or not is_instance_valid(customer): return
	if is_instance_valid(host.placed_serving_bowl):
		host.placed_serving_bowl.queue_free()
		host.placed_serving_bowl=null
	if is_instance_valid(host.placed_food_tray):
		host.placed_food_tray.queue_free()
		host.placed_food_tray=null
	host.interactable(customer,"손님 결제 받기")
	host.interaction_data(customer,"customer_payment")
	customer.call("set_status","결제할게요! [E]",Color("#fff2a8"))
	host.customer_status_label.text="손님이 모니터 앞에서 결제를 기다리고 있습니다."

func customer_left(customer: CharacterBody3D) -> void:
	if not is_instance_valid(host): return
	unregister_customer(customer)
	if is_instance_valid(host.service_manager) and host.service_manager.customer==customer:
		host.service_manager.reset()
	if host.active_customer==customer: host.active_customer=null
	if is_instance_valid(host.placed_serving_bowl):
		host.placed_serving_bowl.queue_free()
		host.placed_serving_bowl=null
	if is_instance_valid(host.placed_food_tray):
		host.placed_food_tray.queue_free()
		host.placed_food_tray=null
	host.active_customer_table_position=Vector3.ZERO
	host.customer_status_label.text=""
