extends CharacterBody3D

var target := Vector3.ZERO
var moving := false
var speed := 2.2
var state := "entering"
var manager: Node
var walk_time := 0.0
var move_elapsed := 0.0
var arrival_sent := false
var animation_player: AnimationPlayer
var walk_animation: StringName = &""
var idle_animation: StringName = &""
var sit_animation: StringName = &""
var eat_animation: StringName = &""
var eating_tween: Tween

func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found:=_find_animation_player(child)
		if found:
			return found
	return null

func _configure_animations() -> void:
	animation_player=_find_animation_player(self)
	if not animation_player: return
	var fallback: StringName=&""
	var exact_walking: StringName=&""
	var exact_sit: StringName=&""
	for animation_name in animation_player.get_animation_list():
		var lowered:=String(animation_name).to_lower()
		if lowered=="reset" or lowered.ends_with("/reset"): continue
		if fallback==&"": fallback=animation_name
		if lowered=="walking" or lowered.ends_with("/walking"): exact_walking=animation_name
		if lowered=="sit" or lowered.ends_with("/sit") or lowered.contains("sitting") or lowered.contains("stand_to_sit") or lowered.contains("stand to sit"): exact_sit=animation_name
		if walk_animation==&"" and lowered.contains("walk"): walk_animation=animation_name
		if idle_animation==&"" and (lowered.contains("idle") or lowered.contains("stand")): idle_animation=animation_name
		if sit_animation==&"" and (lowered.contains("sit") or lowered.contains("sitting")): sit_animation=animation_name
		if eat_animation==&"" and (lowered.contains("eat") or lowered.contains("food") or lowered.contains("dining")): eat_animation=animation_name
	if idle_animation==&"": idle_animation=fallback
	if exact_walking!=&"": walk_animation=exact_walking
	if exact_sit!=&"": sit_animation=exact_sit
	if walk_animation==&"": walk_animation=idle_animation
	if sit_animation!=&"":
		var sit_clip:=animation_player.get_animation(sit_animation)
		if sit_clip: sit_clip.loop_mode=Animation.LOOP_LINEAR

func _play_animation(animation_name: StringName) -> void:
	if animation_player and animation_name!=&"":
		if animation_player.current_animation!=animation_name or not animation_player.is_playing():
			animation_player.speed_scale=1.0
			animation_player.play(animation_name)
			animation_player.seek(0.0,true)

func _start_eating_animation() -> void:
	if eating_tween and eating_tween.is_valid(): eating_tween.kill()
	if eat_animation!=&"": _play_animation(eat_animation)
	var bowl:=get_node_or_null("MealBowl") as Node3D
	var broth:=get_node_or_null("MealBroth") as Node3D
	var spoon:=get_node_or_null("CustomerSpoon") as Node3D
	if bowl: bowl.visible=true
	if broth: broth.visible=true
	if not spoon: return
	spoon.visible=true
	spoon.position=Vector3(0.18,0.76,-0.56)
	eating_tween=create_tween().set_loops()
	eating_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	eating_tween.tween_property(spoon,"position",Vector3(0.12,1.12,-0.40),0.55)
	eating_tween.tween_interval(0.18)
	eating_tween.tween_property(spoon,"position",Vector3(0.18,0.76,-0.56),0.55)
	eating_tween.tween_interval(0.35)

func _stop_eating_animation() -> void:
	if eating_tween and eating_tween.is_valid(): eating_tween.kill()
	eating_tween=null
	if idle_animation!=&"": _play_animation(idle_animation)
	var spoon:=get_node_or_null("CustomerSpoon") as Node3D
	if spoon:
		spoon.visible=false
		spoon.position=Vector3(0.18,0.62,-0.30)

func _set_seated_pose() -> void:
	var model:=get_node_or_null("ChildCustomerModel") as Node3D
	if model:
		# 앉기 애니메이션에 골반 이동이 포함되어 있으므로 별도 하강 보정을 하지 않습니다.
		model.position.y=-0.85
		model.visible=true
	var seated_model:=get_node_or_null("SeatedChildCustomerModel") as Node3D
	if seated_model:
		seated_model.position=Vector3(0,-1.30,-0.08)
		seated_model.visible=false
		var seated_animation_player:=_find_animation_player(seated_model)
		if seated_animation_player:
			var seated_clip: StringName=&""
			for animation_name in seated_animation_player.get_animation_list():
				if not String(animation_name).to_lower().contains("reset"):
					seated_clip=animation_name
					break
			if seated_clip!=&"":
				seated_animation_player.play(seated_clip)
				var clip:=seated_animation_player.get_animation(seated_clip)
				if clip: seated_animation_player.seek(maxf(0.0,clip.length-0.01),true)
				seated_animation_player.pause()
	var selected_sit:=sit_animation
	if animation_player and animation_player.get_animation("StandToSit"):
		selected_sit=&"StandToSit"
	if animation_player and selected_sit!=&"":
		animation_player.stop()
		animation_player.speed_scale=1.0
		animation_player.play(selected_sit)
		var sit_clip:=animation_player.get_animation(selected_sit)
		var seated_time:float=0.55
		if sit_clip: seated_time=maxf(0.0,sit_clip.length-0.05)
		animation_player.seek(seated_time,true)
		animation_player.pause()
		return
	# Imported animations are optional; keep a deterministic seated fallback.
	if seated_model:
		seated_model.visible=true
		if model: model.visible=false
	else:
		_apply_manual_seated_pose()

func _apply_manual_seated_pose() -> void:
	var model:=get_node_or_null("ChildCustomerModel") as Node3D
	if not model: return
	var skeleton:=model.find_child("Skeleton3D",true,false) as Skeleton3D
	if not skeleton: return
	skeleton.reset_bone_poses()
	var upper_leg_rotation:=Quaternion(Vector3.RIGHT,deg_to_rad(-78.0))
	var lower_leg_rotation:=Quaternion(Vector3.RIGHT,deg_to_rad(105.0))
	for bone_name in [&"mixamorig:LeftUpLeg",&"mixamorig:RightUpLeg"]:
		var bone_index:int=skeleton.find_bone(bone_name)
		if bone_index>=0: skeleton.set_bone_pose_rotation(bone_index,upper_leg_rotation)
	for bone_name in [&"mixamorig:LeftLeg",&"mixamorig:RightLeg"]:
		var bone_index:int=skeleton.find_bone(bone_name)
		if bone_index>=0: skeleton.set_bone_pose_rotation(bone_index,lower_leg_rotation)
	var hips_index:=skeleton.find_bone(&"mixamorig:Hips")
	if hips_index>=0: skeleton.set_bone_pose_position(hips_index,Vector3(0,-0.30,0))
	var spine_index:=skeleton.find_bone(&"mixamorig:Spine")
	if spine_index>=0: skeleton.set_bone_pose_rotation(spine_index,Quaternion(Vector3.RIGHT,deg_to_rad(8.0)))
	for bone_name in [&"mixamorig:LeftArm",&"mixamorig:RightArm"]:
		var bone_index:int=skeleton.find_bone(bone_name)
		if bone_index>=0: skeleton.set_bone_pose_rotation(bone_index,Quaternion(Vector3.RIGHT,deg_to_rad(-18.0)))

func _set_standing_pose() -> void:
	var model:=get_node_or_null("ChildCustomerModel") as Node3D
	if model:
		model.visible=true
		model.position.y=-0.92
	var seated_model:=get_node_or_null("SeatedChildCustomerModel") as Node3D
	if seated_model: seated_model.visible=false
	if animation_player:
		animation_player.speed_scale=1.0

func _play_sit_transition() -> void:
	var model:=get_node_or_null("ChildCustomerModel") as Node3D
	var seated_model:=get_node_or_null("SeatedChildCustomerModel") as Node3D
	var selected_sit:=sit_animation
	if animation_player and animation_player.get_animation("StandToSit"):
		selected_sit=&"StandToSit"
	if model:
		model.visible=true
		model.position.y=-0.85
	if seated_model:
		seated_model.visible=false
	if animation_player and selected_sit!=&"":
		animation_player.stop()
		animation_player.speed_scale=1.0
		animation_player.play(selected_sit)
		var sit_clip:=animation_player.get_animation(selected_sit)
		var transition_time:float=0.65
		if sit_clip:
			transition_time=clampf(sit_clip.length,0.25,1.5)
		await get_tree().create_timer(transition_time).timeout
		if not is_instance_valid(self):
			return
	_set_seated_pose()

func setup(game_manager: Node, start: Vector3, counter: Vector3) -> void:
	manager = game_manager
	_configure_animations()
	global_position = start
	state = "entering"
	target = counter
	moving = true
	move_elapsed = 0.0
	arrival_sent = false
	collision_mask = 0
	_set_standing_pose()
	_play_animation(walk_animation)
	set_status("입장 중...", Color("#ffffff"))

func set_status(message: String, color: Color = Color.WHITE) -> void:
	var bubble := get_node_or_null("StatusBubble") as Label3D
	if bubble:
		bubble.text = message
		bubble.modulate = color

func move_to_table(table_position: Vector3) -> void:
	state = "to_table"
	target = table_position
	moving = true
	move_elapsed = 0.0
	arrival_sent = false
	_play_animation(walk_animation)
	set_status("자리로 이동 중...", Color("#bfe8ff"))

func eat_and_leave(exit_position: Vector3, stars: float, review: String) -> void:
	state = "eating"
	moving = false
	set_status("맛있게 먹는 중...", Color("#a8ffb0"))
	_start_eating_animation()
	await get_tree().create_timer(5.0).timeout
	if not is_instance_valid(self):
		return
	_stop_eating_animation()
	set_status("★ %.1f  %s" % [stars, review], Color("#fff2a8"))
	await get_tree().create_timer(3.0).timeout
	if not is_instance_valid(self):
		return
	var bowl := get_node_or_null("MealBowl") as Node3D
	var broth := get_node_or_null("MealBroth") as Node3D
	if bowl: bowl.visible = false
	if broth: broth.visible = false
	state = "leaving"
	target = exit_position
	moving = true
	move_elapsed = 0.0
	arrival_sent = false
	set_status("잘 먹었습니다!", Color("#ffffff"))

func eat_then_pay(payment_position: Vector3, stars: float, review: String) -> void:
	state = "eating"
	moving = false
	set_status("맛있게 먹는 중...", Color("#a8ffb0"))
	_start_eating_animation()
	await get_tree().create_timer(5.0).timeout
	if not is_instance_valid(self):
		return
	_stop_eating_animation()
	set_status("★ %.1f  %s" % [stars, review], Color("#fff2a8"))
	await get_tree().create_timer(3.0).timeout
	if not is_instance_valid(self):
		return
	var bowl := get_node_or_null("MealBowl") as Node3D
	var broth := get_node_or_null("MealBroth") as Node3D
	if bowl: bowl.visible = false
	if broth: broth.visible = false
	state = "payment"
	target = payment_position
	moving = true
	move_elapsed = 0.0
	arrival_sent = false
	set_status("계산하러 이동 중...", Color("#bfe8ff"))

func leave_after_payment(exit_position: Vector3) -> void:
	state = "leaving"
	target = exit_position
	moving = true
	move_elapsed = 0.0
	arrival_sent = false
	_play_animation(walk_animation)
	set_status("감사합니다!", Color("#ffffff"))

func clear_eating_items() -> void:
	_stop_eating_animation()
	var spoon:=get_node_or_null("CustomerSpoon") as Node3D
	var bowl:=get_node_or_null("MealBowl") as Node3D
	var broth:=get_node_or_null("MealBroth") as Node3D
	if spoon: spoon.queue_free()
	if bowl: bowl.queue_free()
	if broth: broth.queue_free()

func _finish_move() -> void:
	if arrival_sent:
		return
	arrival_sent = true
	moving = false
	velocity = Vector3.ZERO
	if state == "entering" and manager:
		look_at(Vector3(get_meta("table_center",global_position+Vector3(0,0,-1))),Vector3.UP)
		await _play_sit_transition()
		if not is_instance_valid(self):
			return
		manager.customer_reached_counter(self)
	elif state == "to_table" and manager:
		look_at(Vector3(get_meta("table_center",global_position+Vector3(0,0,-1))),Vector3.UP)
		await _play_sit_transition()
		if not is_instance_valid(self):
			return
		manager.customer_reached_table(self)
	elif state == "payment" and manager:
		_set_standing_pose()
		_play_animation(idle_animation)
		manager.customer_reached_payment(self)
	elif state == "leaving":
		_set_standing_pose()
		_play_animation(walk_animation)
		if manager:
			manager.customer_left(self)
		queue_free()

func _physics_process(delta: float) -> void:
	if not moving:
		return
	_play_animation(walk_animation)
	walk_time += delta
	move_elapsed += delta
	var flat_target := Vector3(target.x, global_position.y, target.z)
	var difference := flat_target - global_position
	var distance := difference.length()
	if distance <= maxf(0.18, speed * delta) or move_elapsed >= 10.0:
		global_position = flat_target
		_finish_move()
		return
	var direction := difference.normalized()
	look_at(global_position + direction, Vector3.UP)
	global_position += direction * minf(speed * delta, distance)
	var body := get_node_or_null("CustomerBody") as Node3D
	if body:
		body.position.y = 0.55 + sin(walk_time * 9.0) * 0.035
