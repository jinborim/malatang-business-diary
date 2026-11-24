extends Node

var host:Node

func setup(game_host:Node) -> void:
	host=game_host

func update_arm_visibility() -> void:
	if not is_instance_valid(host.player_skeleton): return
	var left_visible:bool=host.player_was_moving or host.has_bowl or host.has_steel_bowl
	var right_visible:bool=host.player_was_moving or host.has_tongs or host.has_steel_bowl
	set_arm_chain_visible("Left",left_visible)
	set_arm_chain_visible("Right",right_visible)

func set_arm_chain_visible(side:String, should_show:bool) -> void:
	if not is_instance_valid(host.player_skeleton): return
	for bone_index in range(host.player_skeleton.get_bone_count()):
		var bone_name:=str(host.player_skeleton.get_bone_name(bone_index))
		if bone_name.contains(side) and (bone_name.contains("Arm") or bone_name.contains("Hand") or bone_name.contains("Finger") or bone_name.contains("Thumb")):
			set_single_arm_visible(host.player_skeleton.get_bone_name(bone_index),should_show)

func set_single_arm_visible(bone_name:StringName, should_show:bool) -> void:
	if not is_instance_valid(host.player_skeleton): return
	var bone_index:int=host.player_skeleton.find_bone(bone_name)
	if bone_index<0: return
	if should_show:
		host.player_skeleton.set_bone_pose_scale(bone_index,Vector3.ONE)
		host.player_skeleton.set_bone_global_pose_override(bone_index,host.player_skeleton.get_bone_global_pose(bone_index),0.0,false)
	else:
		var hidden_pose:Transform3D=host.player_skeleton.get_bone_global_pose(bone_index)
		hidden_pose.basis=hidden_pose.basis.orthonormalized().scaled(Vector3.ONE*0.001)
		host.player_skeleton.set_bone_global_pose_override(bone_index,hidden_pose,1.0,true)

func stabilize_held_bowl() -> void:
	if not is_instance_valid(host.camera): return
	var basis:Basis=host.camera.global_transform.basis.orthonormalized()
	var target:Vector3=host.camera.global_position
	if not host.player_body_hidden and is_instance_valid(host.left_hand_attachment):
		target=host.left_hand_attachment.global_position+basis.x*0.015+basis.y*0.055+(-basis.z)*0.045
	else: target+=basis.x*-0.52+basis.y*-0.31+(-basis.z)*0.66
	if is_instance_valid(host.held_bowl):
		host.held_bowl.global_position=target
		host.held_bowl.global_rotation=Vector3(0.0,host.camera.global_rotation.y,0.0)
		host.held_bowl.scale=Vector3.ONE*0.17

func set_player_arms_visible(should_show: bool) -> void:
	if not is_instance_valid(host.player_skeleton) or host.player_arms_visible==should_show: return
	host.player_arms_visible=should_show
	if should_show: pose_player_arms_for_tools()
	for bone_name in [&"mixamorig_LeftArm",&"mixamorig_RightArm"]:
		var bone_index:int=host.player_skeleton.find_bone(bone_name)
		if bone_index<0: continue
		host.player_skeleton.set_bone_pose_scale(bone_index,Vector3.ONE if should_show else Vector3.ONE*0.001)
		if not should_show:
			var hidden_pose:Transform3D=host.player_skeleton.get_bone_global_pose(bone_index)
			hidden_pose.basis=hidden_pose.basis.scaled(Vector3.ONE*0.001)
			host.player_skeleton.set_bone_global_pose_override(bone_index,hidden_pose,1.0,true)

func update_player_animation() -> void:
	if not is_instance_valid(host.player_body) or not host.player_skeleton: return
	var moving:=Vector2(host.player_body.velocity.x,host.player_body.velocity.z).length_squared()>0.04
	if moving==host.player_was_moving: return
	host.player_was_moving=moving
	if moving:
		host.player_skeleton.clear_bones_global_pose_override()
		host.player_arms_visible=true
		for bone_name in [&"mixamorig_LeftArm",&"mixamorig_RightArm"]:
			var bone_index:int=host.player_skeleton.find_bone(bone_name)
			if bone_index>=0: host.player_skeleton.set_bone_pose_scale(bone_index,Vector3.ONE)
		if host.player_animation_player and not host.player_walking_animation.is_empty():
			host.player_animation_player.play(host.player_walking_animation,0.15,1.0)
	else:
		if host.player_animation_player: host.player_animation_player.stop()
		if host.has_tongs or host.has_bowl or host.has_steel_bowl:
			pose_player_arms_for_tools()
			host.player_arms_visible=true
		else:
			host.player_arms_visible=true
			set_player_arms_visible(false)

func _basis_with_y_axis(direction: Vector3, reference: Vector3=Vector3.FORWARD) -> Basis:
	var y_axis:=direction.normalized()
	var x_axis:=reference.cross(y_axis).normalized()
	if x_axis.length_squared()<0.01: x_axis=Vector3.RIGHT
	var z_axis:=x_axis.cross(y_axis).normalized()
	return Basis(x_axis,y_axis,z_axis).orthonormalized()

func pose_player_arms_for_tools() -> void:
	if not host.player_skeleton: return
	var poses:=[
		[&"mixamorig_LeftArm",Vector3(0.176,1.378,-0.043),Vector3(0.31,1.15,0.18)],
		[&"mixamorig_LeftForeArm",Vector3(0.31,1.15,0.18),Vector3(0.25,1.08,0.48)],
		[&"mixamorig_LeftHand",Vector3(0.25,1.08,0.48),Vector3(0.22,1.05,0.64)],
		[&"mixamorig_RightArm",Vector3(-0.169,1.378,-0.043),Vector3(-0.31,1.15,0.18)],
		[&"mixamorig_RightForeArm",Vector3(-0.31,1.15,0.18),Vector3(-0.25,1.08,0.48)],
		[&"mixamorig_RightHand",Vector3(-0.25,1.08,0.48),Vector3(-0.22,1.05,0.64)]
	]
	for pose in poses:
		var bone_name: StringName=pose[0] as StringName
		var start: Vector3=pose[1] as Vector3
		var target: Vector3=pose[2] as Vector3
		var bone_index:int=host.player_skeleton.find_bone(bone_name)
		if bone_index<0: continue
		var transform:=Transform3D(_basis_with_y_axis(target-start),start)
		host.player_skeleton.set_bone_global_pose_override(bone_index,transform,1.0,true)

func apply_player_material(root: Node) -> void:
	var material:=StandardMaterial3D.new()
	material.albedo_texture=load("res://assets/models/player_character_rigged.png") as Texture2D
	material.normal_enabled=true
	material.normal_texture=load("res://assets/models/player_character_rigged_normal.png") as Texture2D
	material.metallic_texture=load("res://assets/models/player_character_rigged_metallic.png") as Texture2D
	material.roughness_texture=load("res://assets/models/player_character_rigged_roughness.png") as Texture2D
	material.roughness=0.75
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if mesh_instance: mesh_instance.material_overlay=material

func add_player_character_model(player: CharacterBody3D) -> void:
	var player_resource: Resource=load("res://assets/models/player_character_rigged.fbx")
	if not player_resource is PackedScene: return
	var player_model: Node3D=(player_resource as PackedScene).instantiate() as Node3D
	player_model.name="PlayerCharacterModel"
	player_model.position=Vector3(0,-1.02,0.02)
	player_model.rotation_degrees=Vector3(0,180,0)
	player_model.scale=Vector3.ONE*1.15
	player.add_child(player_model)
	player_model.visible=not host.player_body_hidden
	apply_player_material(player_model)
	host.player_skeleton=player_model.find_child("Skeleton3D",true,false) as Skeleton3D
	host.player_animation_player=player_model.find_child("AnimationPlayer",true,false) as AnimationPlayer
	if host.player_animation_player:
		for animation_name in host.player_animation_player.get_animation_list():
			if str(animation_name).to_lower().contains("walk"):
				host.player_walking_animation=animation_name
				break
	if not host.player_skeleton: return
	# Hide only the head in first person; torso, arms and legs remain visible.
	for bone_name in [&"mixamorig_Head",&"mixamorig_HeadTop_End",&"headfront"]:
		var bone_index:int=host.player_skeleton.find_bone(bone_name)
		if bone_index>=0: host.player_skeleton.set_bone_pose_scale(bone_index,Vector3(0.001,0.001,0.001))
	host.right_hand_attachment=BoneAttachment3D.new()
	host.right_hand_attachment.name="RightHandToolSocket"
	host.right_hand_attachment.bone_name=&"mixamorig_RightHand"
	host.player_skeleton.add_child(host.right_hand_attachment)
	host.left_hand_attachment=BoneAttachment3D.new()
	host.left_hand_attachment.name="LeftHandToolSocket"
	host.left_hand_attachment.bone_name=&"mixamorig_LeftHand"
	host.player_skeleton.add_child(host.left_hand_attachment)
	pose_player_arms_for_tools()
	set_player_arms_visible(false)
