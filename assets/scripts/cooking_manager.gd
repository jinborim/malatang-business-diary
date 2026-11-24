extends Node

signal cooking_finished(food: Dictionary)

var host: Node
var busy := false

func setup(game_host: Node) -> void:
	host=game_host

func build_flame(pos: Vector3) -> void:
	host.cooking_flame=Node3D.new()
	host.cooking_flame.name="CookingFlame"
	host.cooking_flame.position=pos
	host.cooking_flame.visible=false
	host.add_child(host.cooking_flame)
	var flame_material:=StandardMaterial3D.new()
	flame_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	flame_material.albedo_color=Color(1.0,0.24,0.025,0.92)
	flame_material.emission_enabled=true
	flame_material.emission=Color(1.0,0.08,0.01)
	flame_material.emission_energy_multiplier=2.8
	flame_material.no_depth_test=false
	for flame_data in [[0.0,0.0,0.18],[0.10,0.02,0.14],[-0.10,-0.02,0.15]]:
		var flame:=MeshInstance3D.new()
		var mesh:=CylinderMesh.new()
		mesh.top_radius=0.015; mesh.bottom_radius=flame_data[2]; mesh.height=0.30+flame_data[2]*0.35
		flame.mesh=mesh; flame.material_override=flame_material
		flame.position=Vector3(flame_data[0],0.14,flame_data[1]); flame.rotation_degrees=Vector3(0,float(flame_data[0])*35.0,0)
		host.cooking_flame.add_child(flame)
	host.cooking_flame_light=OmniLight3D.new()
	host.cooking_flame_light.name="CookingFlameLight"
	host.cooking_flame_light.light_color=Color(1.0,0.20,0.03)
	host.cooking_flame_light.light_energy=1.4
	host.cooking_flame_light.omni_range=2.2
	host.cooking_flame_light.shadow_enabled=false
	host.cooking_flame.add_child(host.cooking_flame_light)

func set_flame_active(active: bool) -> void:
	if not is_instance_valid(host.cooking_flame): return
	if is_instance_valid(host.cooking_flame_tween): host.cooking_flame_tween.kill()
	host.cooking_flame.visible=active
	if is_instance_valid(host.cooking_flame_light): host.cooking_flame_light.visible=active
	if not active: return
	host.cooking_flame.scale=Vector3.ONE
	host.cooking_flame_tween=host.create_tween().set_loops()
	host.cooking_flame_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	host.cooking_flame_tween.tween_property(host.cooking_flame,"scale",Vector3(1.0,1.12,1.0),0.16)
	host.cooking_flame_tween.tween_property(host.cooking_flame,"scale",Vector3(0.92,0.88,0.92),0.13)

func validate_start() -> bool:
	if not is_instance_valid(host): return true
	if not host.cooking_pot_broth_added:
		host.result_label.text="먼저 국자로 조리 냄비에 육수를 넣어주세요."
		return false
	if host.current_order.is_empty():
		host.result_label.text="진행 중인 주문이 없습니다."
		return false
	if host.basket.is_empty():
		host.result_label.text="재료를 먼저 담아주세요."
		return false
	if host.selected_spice==0:
		host.result_label.text="숫자키 1, 2, 3 또는 소스통으로 맵기를 선택하세요."
		return false
	if host.broth_servings<=0:
		host.result_label.text="마라 육수가 없습니다. 육수 냄비에서 먼저 만들어주세요."
		return false
	if host.cooking or not host.cooked_food.is_empty(): return false
	return true

func start(ingredients: Array[String], spice: int, duration: float) -> void:
	if busy: return
	busy=true
	_run(ingredients.duplicate(),spice,duration)

func _run(ingredients: Array[String], spice: int, duration: float) -> void:
	await get_tree().create_timer(duration).timeout
	busy=false
	cooking_finished.emit({"ingredients":ingredients,"spice":spice})

func apply_finished_food(food: Dictionary) -> void:
	if not is_instance_valid(host): return
	host.cooked_food=food
	host.basket.clear()
	host._clear_basket_visuals()
	host.cooking=false
	host._set_cooking_flame_active(false)
	host._auto_pickup_finished_food()
	var channel:=str(host.current_order.get("channel","delivery"))
	if is_instance_valid(host.delivery_container_view): host.delivery_container_view.visible=channel=="delivery"
	host.result_label.text="조리 완료! 집게와 재료 그릇을 내려놓은 뒤 완성 그릇을 받으세요."
	if channel=="delivery": host.result_label.text="조리 완료! 배달 용기에 담아 배달원에게 전달하세요."
	if channel=="delivery":
		if host.courier_ready:
			host._set_courier_status(host.delivery_courier,"주문 #%d · 음식 수령"%int(host.current_order.get("id",-1)),Color("#a8ffb0"))
		else:
			host._summon_courier()
	host._refresh_hud()

func auto_pickup_finished_food() -> void:
	if not is_instance_valid(host): return
	# 조리가 끝나면 재료용 그릇과 집게는 자동으로 정리합니다.
	host.has_tongs=false
	host.has_bowl=false
	host.held_bowl_count=0
	host._update_held_tool_visibility()
	if str(host.current_order.get("channel","delivery"))!="dinein": return
	if not is_instance_valid(host.serving_bowl_view):
		host.serving_bowl_view=host._instantiate_serving_bowl()
		if is_instance_valid(host.serving_bowl_view):
			host.serving_bowl_view.name="HeldServingBowl"
			host.serving_bowl_view.position=Vector3(-0.48,-0.42,-0.92)
			host.serving_bowl_view.rotation_degrees=Vector3(8,0,0)
			host.serving_bowl_view.scale=Vector3.ONE*0.22
			host.camera.add_child(host.serving_bowl_view)
	host._spawn_finished_food_tray()
	host.result_label.text="완성 음식이 쟁반에 놓였습니다. 쟁반을 들어 테이블로 가져가세요."

func pickup_food_tray() -> void:
	if not is_instance_valid(host): return
	if host.has_food_tray:
		host.result_label.text="이미 음식 쟁반을 들고 있습니다."
		return
	if not is_instance_valid(host.food_tray_world): return
	host.has_food_tray=true
	host.food_tray_world.visible=false
	if not is_instance_valid(host.food_tray_view):
		host.food_tray_view=host._create_food_tray_visual("HeldFoodTray")
		if is_instance_valid(host.camera): host.camera.add_child(host.food_tray_view)
	if is_instance_valid(host.food_tray_view):
		host.food_tray_view.position=Vector3(-0.48,-0.50,-0.92)
		host.food_tray_view.rotation_degrees=Vector3(8,0,0)
		host.food_tray_view.scale=Vector3.ONE*0.72
		host.food_tray_view.visible=true
	if is_instance_valid(host.serving_bowl_view): host.serving_bowl_view.visible=true
	host.result_label.text="음식 쟁반을 들었습니다. 손님 테이블로 가져가세요."
func start_cooking() -> void:
	if is_instance_valid(host.cooking_manager):
		if not host.cooking_manager.validate_start(): return
		host.cooking_pot_broth_added=false
		host.cooking=true
		host._set_cooking_flame_active(true)
		host.result_label.text="마라 육수 1인분 사용 · 조리 중..."
		host._save_game(false)
		host._refresh_hud()
		host.cooking_manager.start(host.basket.duplicate(),host.selected_spice,maxf(1.0,3.0-float(host.upgrade_levels["cooking"])*0.4))
		return
	if not host.cooking_pot_broth_added:
		host.result_label.text="먼저 국자로 조리 냄비에 육수를 넣어주세요."
		return
	if host.current_order.is_empty(): host.result_label.text="진행 중인 주문이 없습니다."; return
	if host.basket.is_empty(): host.result_label.text="재료를 먼저 담아주세요."; return
	if host.selected_spice==0: host.result_label.text="숫자키 1, 2, 3 또는 소스통으로 맵기를 선택하세요."; return
	if host.broth_servings<=0: host.result_label.text="마라 육수가 없습니다. 육수 냄비에서 먼저 만들어주세요."; return
	if host.cooking or not host.cooked_food.is_empty(): return
	var cooking_time: float=maxf(1.0,3.0-float(host.upgrade_levels["cooking"])*0.4)
	host._set_cooking_flame_active(true)
	host.cooking_pot_broth_added=false; host.cooking=true; host.result_label.text="마라탕 조리 중..."; host._save_game(false); host._refresh_hud(); await get_tree().create_timer(cooking_time).timeout
	host.cooked_food={"ingredients":host.basket.duplicate(),"spice":host.selected_spice}; host.basket.clear(); host._clear_basket_visuals(); host.cooking=false; host._set_cooking_flame_active(false)
	host._auto_pickup_finished_food()
	if true:
		host.result_label.text="조리 완료! 집게와 재료 그릇을 내려놓은 뒤 완성 그릇을 받으세요."
		host._refresh_hud()
	if str(host.current_order.get("channel","delivery"))=="dinein":
		if is_instance_valid(host.serving_bowl_view): host.serving_bowl_view.visible=true
		host.result_label.text="조리 완료! 완성 그릇을 들고 테이블로 가져가세요."
	else:
		if host.courier_ready:
			host._set_courier_status(host.delivery_courier,"주문 #%d · 음식 수령"%int(host.current_order.get("id",-1)),Color("#a8ffb0"))
			host.result_label.text="조리 완료! 배달원에게 음식을 전달하세요."
		else:
			host._summon_courier()

