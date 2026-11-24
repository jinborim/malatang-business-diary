extends Node

# 배달원의 표시 상태와 방향 처리를 담당합니다.
var host

func setup(game_host) -> void:
	host=game_host

func set_status(actor: Node3D, text: String, color:=Color.WHITE) -> void:
	if not is_instance_valid(actor): return
	var label:=actor.get_node_or_null("StatusLabel") as Label3D
	if is_instance_valid(label):
		label.text=text
		label.modulate=color

func set_active(actor: Node3D, active: bool) -> void:
	if not is_instance_valid(actor): return
	actor.visible=active
	var body:=actor.get_node_or_null("InteractionBody") as StaticBody3D
	if is_instance_valid(body): body.collision_layer=1 if active else 0

func face_toward(actor: Node3D, target_position: Vector3) -> void:
	if not is_instance_valid(actor): return
	var look_target:=target_position
	look_target.y=actor.global_position.y
	if actor.global_position.distance_squared_to(look_target)>0.001:
		actor.look_at(look_target,Vector3.UP)

func set_walking(actor: Node3D, walking: bool) -> void:
	if not is_instance_valid(actor): return
	var animation_player:AnimationPlayer=actor.get_meta("animation_player",null) as AnimationPlayer
	if not animation_player: return
	var walk_animation:StringName=actor.get_meta("walk_animation",&"")
	var idle_animation:StringName=actor.get_meta("idle_animation",&"")
	if walking:
		if walk_animation!=&"":
			animation_player.speed_scale=0.82
			animation_player.play(walk_animation,0.12)
		return
	animation_player.speed_scale=1.0
	if idle_animation!=&"":
		animation_player.play(idle_animation,0.15)
	elif walk_animation!=&"":
		animation_player.play(walk_animation)
		var animation:=animation_player.get_animation(walk_animation)
		if animation: animation_player.seek(animation.length*0.5,true)
		animation_player.pause()
	else:
		animation_player.stop()

func align_feet_to_floor(actor: Node3D, courier_model: Node3D) -> void:
	var minimum_y:float=INF
	var mesh_nodes:Array[Node]=courier_model.find_children("*","MeshInstance3D",true,false)
	for node in mesh_nodes:
		var mesh_instance:=node as MeshInstance3D
		if not mesh_instance or not mesh_instance.mesh: continue
		var bounds:=mesh_instance.get_aabb()
		for x_index in 2:
			for y_index in 2:
				for z_index in 2:
					var corner:=bounds.position+Vector3(bounds.size.x*float(x_index),bounds.size.y*float(y_index),bounds.size.z*float(z_index))
					minimum_y=minf(minimum_y,actor.to_local(mesh_instance.to_global(corner)).y)
	if minimum_y<INF: courier_model.position.y+=0.03-minimum_y

func summon() -> void:
	if not is_instance_valid(host) or not is_instance_valid(host.delivery_courier) or host.courier_moving or host.courier_ready: return
	host.courier_moving=true
	host.courier_wait_seconds=0.0
	reset_queue_tweens()
	host.delivery_courier.position=host.COURIER_ENTRANCE
	face_toward(host.delivery_courier,host.COURIER_WAITING)
	set_active(host.delivery_courier,true)
	var active_order_id:=int(host.current_order.get("id",-1))
	host.delivery_courier.set_meta("interaction_value",active_order_id)
	set_status(host.delivery_courier,"주문 #%d · 입장 중"%active_order_id,Color("#8ee7ff"))
	if is_instance_valid(host.courier_package): host.courier_package.visible=false
	for index in host.courier_queue_visuals.size():
		var queued:Node3D=host.courier_queue_visuals[index]
		queued.position=host.COURIER_ENTRANCE+Vector3(0,0,0.55*float(index+1))
		face_toward(queued,host.COURIER_QUEUE_POSITIONS[index])
		set_active(queued,true)
		var queued_order_id: int=int(host.orders[index].get("id",100+index)) if index<host.orders.size() else 100+index
		queued.set_meta("interaction_value",queued_order_id)
		set_status(queued,"주문 #%d · 대기"%queued_order_id,Color("#ffe39a"))
		var queue_tween:Tween=host.create_tween()
		host.courier_queue_tweens.append(queue_tween)
		queue_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		queue_tween.tween_interval(0.35*float(index+1))
		queue_tween.tween_property(queued,"position",host.COURIER_QUEUE_POSITIONS[index],1.4)
	host.courier_tween=host.create_tween()
	host._set_courier_walking(host.delivery_courier,true)
	host.courier_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	host.courier_tween.tween_property(host.delivery_courier,"position",host.COURIER_WAITING,1.4)
	await host.courier_tween.finished
	host._set_courier_walking(host.delivery_courier,false)
	face_toward(host.delivery_courier,host.COURIER_WAITING+Vector3(0,0,-1.0))
	host.courier_moving=false
	host.courier_ready=true
	set_status(host.delivery_courier,"주문 #%d · %s"%[active_order_id,"음식 수령" if not host.cooked_food.is_empty() else "음식 준비 대기"],Color("#a8ffb0" if not host.cooked_food.is_empty() else "#ffe39a"))
	if not host.cooked_food.is_empty(): host.result_label.text="배달원이 도착했습니다. 완성된 음식을 전달하세요."

func send_away() -> void:
	if not is_instance_valid(host) or not is_instance_valid(host.delivery_courier): return
	host.courier_ready=false
	host.courier_moving=true
	set_status(host.delivery_courier,"수령 완료 · 퇴장",Color("#a8ffb0"))
	for index in host.courier_queue_visuals.size():
		var queued:Node3D=host.courier_queue_visuals[index]
		if not is_instance_valid(queued): continue
		var next_position:Vector3=host.COURIER_WAITING if index==0 else host.COURIER_QUEUE_POSITIONS[index-1]
		face_toward(queued,next_position)
		set_status(queued,"앞으로 이동",Color("#8ee7ff"))
		var queue_tween:Tween=host.create_tween()
		host.courier_queue_tweens.append(queue_tween)
		queue_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		queue_tween.tween_property(queued,"position",next_position,0.8)
	host.courier_tween=host.create_tween()
	face_toward(host.delivery_courier,host.COURIER_ENTRANCE)
	host._set_courier_walking(host.delivery_courier,true)
	host.courier_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	host.courier_tween.tween_interval(0.45)
	host.courier_tween.tween_property(host.delivery_courier,"position",host.COURIER_ENTRANCE,1.4)
	await host.courier_tween.finished
	host._set_courier_walking(host.delivery_courier,false)
	if is_instance_valid(host.courier_package): host.courier_package.visible=false
	set_active(host.delivery_courier,false)
	for queued in host.courier_queue_visuals:
		if is_instance_valid(queued): set_active(queued,false)
	host.courier_moving=false
	host.courier_wait_seconds=0.0
	reset_queue_tweens()

func reset_queue_tweens() -> void:
	if not is_instance_valid(host): return
	for tween in host.courier_queue_tweens:
		if tween and tween.is_valid(): tween.kill()
	host.courier_queue_tweens.clear()

func apply_courier_material(root:Node) -> void:
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color.WHITE
	var color_texture:=load("res://assets/models/delivery_courier.png") as Texture2D
	if color_texture: material.albedo_texture=color_texture
	var normal_texture:=load("res://assets/models/delivery_courier_normal.png") as Texture2D
	if normal_texture:
		material.normal_enabled=true
		material.normal_texture=normal_texture
	material.metallic=0.18
	material.roughness=0.62
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_overlay=material

func reset() -> void:
	if not is_instance_valid(host): return
	if host.courier_tween and host.courier_tween.is_valid(): host.courier_tween.kill()
	reset_queue_tweens()
	host.courier_ready=false
	host.courier_moving=false
	host.courier_wait_seconds=0.0
	if is_instance_valid(host.courier_package): host.courier_package.visible=false
	if is_instance_valid(host.delivery_courier):
		host._set_courier_walking(host.delivery_courier,false)
		set_active(host.delivery_courier,false)
		host.delivery_courier.position=host.COURIER_ENTRANCE
		host.delivery_courier.rotation.y=0.0
		set_status(host.delivery_courier,"배달 대기",Color("#ffffff"))
	for index in host.courier_queue_visuals.size():
		var queued:Node3D=host.courier_queue_visuals[index]
		if is_instance_valid(queued): set_active(queued,false)
		queued.position=host.COURIER_ENTRANCE+Vector3(0,0,0.55*float(index+1))
func create_courier_actor(actor_name: String) -> Node3D:
	var actor:=Node3D.new()
	actor.name=actor_name
	actor.position=host.COURIER_ENTRANCE
	actor.visible=false
	add_child(actor)
	var courier_resource: Resource=load("res://assets/models/delivery_courier.fbx")
	if courier_resource is PackedScene:
		var courier_model: Node3D=(courier_resource as PackedScene).instantiate() as Node3D
		courier_model.name="DeliveryCourierModel"
		courier_model.rotation_degrees=Vector3(0,180,0)
		courier_model.scale=Vector3.ONE*1.08
		actor.add_child(courier_model)
		host._apply_courier_material(courier_model)
		host._align_courier_feet_to_floor(actor,courier_model)
		host._configure_courier_animations(actor,courier_model)
	else:
		host.cylinder("Body",Vector3(0,0.9,0),0.38,1.25,Color("#20252a"),actor,false)
		var head:MeshInstance3D=host.cylinder("Helmet",Vector3(0,1.82,0),0.32,0.5,Color("#111418"),actor,false)
		head.rotation_degrees.x=90
	var status:=Label3D.new()
	status.name="StatusLabel"
	status.position=Vector3(0,2.45,0)
	status.text="배달 대기"
	status.font_size=34
	status.outline_size=8
	status.modulate=Color("#ffffff")
	status.outline_modulate=Color("#17202a")
	status.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	status.no_depth_test=true
	actor.add_child(status)
	var interaction_body:=StaticBody3D.new()
	interaction_body.name="InteractionBody"
	interaction_body.collision_layer=0
	interaction_body.collision_mask=0
	var interaction_shape:=CollisionShape3D.new()
	var capsule:=CapsuleShape3D.new()
	capsule.radius=0.48
	capsule.height=2.2
	interaction_shape.position=Vector3(0,1.1,0)
	interaction_shape.shape=capsule
	interaction_body.add_child(interaction_shape)
	actor.add_child(interaction_body)
	host.interactable(actor,"배달원 주문 확인")
	host.interaction_data(actor,"courier",-1)
	# The courier must remain completely hidden until a delivery order is accepted.
	host._set_courier_active(actor,false)
	return actor

func configure_courier_animations(actor: Node3D, courier_model: Node3D) -> void:
	var animation_player:AnimationPlayer=host._find_animation_player(courier_model)
	if not animation_player:
		return
	var walk_animation: StringName=&""
	var idle_animation: StringName=&""
	var run_animation: StringName=&""
	var fallback_animation: StringName=&""
	for animation_name in animation_player.get_animation_list():
		var lowered:=String(animation_name).to_lower()
		if lowered=="reset" or lowered.ends_with("/reset"):
			continue
		if fallback_animation==&"":
			fallback_animation=animation_name
		if walk_animation==&"" and lowered.contains("walk"):
			walk_animation=animation_name
		if run_animation==&"" and lowered.contains("run"):
			run_animation=animation_name
		if idle_animation==&"" and lowered.contains("idle"):
			idle_animation=animation_name
	if walk_animation==&"":
		walk_animation=run_animation if run_animation!=&"" else fallback_animation
	for animation_name in [walk_animation,idle_animation]:
		if animation_name!=&"":
			var animation:Animation=animation_player.get_animation(animation_name)
			if animation:
				animation.loop_mode=Animation.LOOP_LINEAR
	actor.set_meta("animation_player",animation_player)
	actor.set_meta("walk_animation",walk_animation)
	actor.set_meta("idle_animation",idle_animation)
	host._set_courier_walking(actor,false)

func align_courier_feet_to_floor(actor: Node3D, courier_model: Node3D) -> void:
	if is_instance_valid(host.courier_manager): host.courier_manager.align_feet_to_floor(actor,courier_model)
