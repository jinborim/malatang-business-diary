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
	host._apply_player_material(player_model)
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
	host._pose_player_arms_for_tools()
	host._set_player_arms_visible(false)
