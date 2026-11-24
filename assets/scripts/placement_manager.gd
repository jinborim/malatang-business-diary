extends Node

var host:Node

func setup(game_host:Node) -> void:
	host=game_host

func surface_y(surface:Node3D) -> float:
	if not is_instance_valid(surface): return 0.0
	return float(surface.get_meta("place_surface_y",surface.global_position.y))

func offset_y(surface:Node3D) -> float:
	if not is_instance_valid(surface): return 0.12
	return float(surface.get_meta("place_offset_y",0.12))

func held_radius() -> float:
	if is_instance_valid(host.carrying_manager): return host.carrying_manager.held_place_radius()
	return 0.28

func view_plane_point(surface:Node3D) -> Dictionary:
	if not is_instance_valid(host.camera) or not is_instance_valid(surface): return {"point":Vector3.ZERO,"valid":false}
	var forward:Vector3=-host.camera.global_basis.z
	if absf(forward.y)<0.001: return {"point":Vector3.ZERO,"valid":false}
	var distance:float=(surface_y(surface)-host.camera.global_position.y)/forward.y
	if distance<=0.0 or distance>20.0: return {"point":Vector3.ZERO,"valid":false}
	var point:Vector3=host.camera.global_position+forward*distance
	var half_extents:Vector2=surface.get_meta("place_half_extents",Vector2(3.50,0.75))
	var inside:=absf(point.x-surface.global_position.x)<=half_extents.x and absf(point.z-surface.global_position.z)<=half_extents.y
	return {"point":point,"valid":inside}

func placement_surface_from_view() -> Node3D:
	if not is_instance_valid(host.camera): return null
	var from:Vector3=host.camera.global_position
	var to:Vector3=from+(-host.camera.global_basis.z)*7.0
	var hit:Dictionary=host.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to))
	if hit:
		var node:Node=hit.collider
		while is_instance_valid(node) and not node.has_meta("interaction_type"): node=node.get_parent()
		if is_instance_valid(node) and str(node.get_meta("interaction_type",""))=="place_surface": return node as Node3D
		if is_instance_valid(host.prep_table_place) and hit.has("position"):
			var hit_position:Vector3=hit.position
			var table_y:=surface_y(host.prep_table_place)
			var table_half:Vector2=host.prep_table_place.get_meta("place_half_extents",Vector2(3.50,0.75))
			var on_table:=absf(hit_position.x-host.prep_table_place.global_position.x)<=table_half.x and absf(hit_position.z-host.prep_table_place.global_position.z)<=table_half.y
			if on_table and absf(hit_position.y-table_y)<=0.35: return host.prep_table_place
		return null
	if is_instance_valid(host.prep_table_place) and bool(view_plane_point(host.prep_table_place).get("valid",false)): return host.prep_table_place
	var floor_surface:=host.get_node_or_null("Floor") as Node3D
	if is_instance_valid(floor_surface) and bool(view_plane_point(floor_surface).get("valid",false)): return floor_surface
	return null

func table_placement_point(surface:Node3D, minimum_distance:float=2.2, object_radius:float=0.0, ignored:Node=null) -> Dictionary:
	if not is_instance_valid(host.camera) or not is_instance_valid(surface): return {"point":Vector3.ZERO,"can_place":false}
	var forward:Vector3=-host.camera.global_basis.z
	var distance:=minimum_distance
	if absf(forward.y)>0.001:
		var plane_distance:float=(surface_y(surface)-host.camera.global_position.y)/forward.y
		if plane_distance>0.0: distance=plane_distance
	var point:Vector3=host.camera.global_position+forward*distance
	var half_extents:Vector2=surface.get_meta("place_half_extents",Vector2(3.50,0.75))
	var inside_table:=absf(point.x-surface.global_position.x)<=half_extents.x and absf(point.z-surface.global_position.z)<=half_extents.y
	var place_y:=surface_y(surface)+offset_y(surface)
	var free_space:=object_radius<=0.0 or is_place_position_free(Vector3(point.x,place_y,point.z),object_radius,ignored)
	return {"point":Vector3(point.x,place_y,point.z),"can_place":inside_table and free_space}

func is_place_position_free(point:Vector3, radius:float, ignored:Node=null) -> bool:
	for candidate in host.get_tree().get_nodes_in_group("placeable_object"):
		if not is_instance_valid(candidate) or candidate==ignored or not candidate is Node3D: continue
		var node:=candidate as Node3D
		if not node.visible: continue
		if host.has_broth_pot and (node==host.broth_pot_model or node==host.broth_pot_filled_model): continue
		if is_instance_valid(ignored) and (node==ignored or node.is_ancestor_of(ignored) or ignored.is_ancestor_of(node)): continue
		if str(node.get_meta("interaction_type",""))=="place_surface": continue
		if absf(point.y-node.global_position.y)>0.80: continue
		var other_radius:=float(node.get_meta("place_radius",0.30))
		var delta:=Vector2(point.x-node.global_position.x,point.z-node.global_position.z)
		if delta.length()<radius+other_radius+0.04: return false
	return true

func model_world_aabb(root:Node3D) -> AABB:
	var bounds:=AABB()
	var has_bounds:=false
	var meshes:Array[MeshInstance3D]=[]
	if root is MeshInstance3D: meshes.append(root as MeshInstance3D)
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if is_instance_valid(mesh_instance) and mesh_instance.mesh: meshes.append(mesh_instance)
	for mesh_instance in meshes:
		if not is_instance_valid(mesh_instance) or not mesh_instance.mesh: continue
		var local_bounds:=mesh_instance.get_aabb()
		for index in 8:
			var corner:=local_bounds.position+Vector3(local_bounds.size.x if (index&1)!=0 else 0.0,local_bounds.size.y if (index&2)!=0 else 0.0,local_bounds.size.z if (index&4)!=0 else 0.0)
			var world_corner:=mesh_instance.global_transform*corner
			if not has_bounds:
				bounds=AABB(world_corner,Vector3.ZERO)
				has_bounds=true
			else: bounds=bounds.expand(world_corner)
	return bounds

func snap_model_bottom(root:Node3D, surface_height:float, clearance:float=0.025) -> void:
	if not is_instance_valid(root): return
	var bounds:=model_world_aabb(root)
	if bounds.size.y<=0.0001: return
	root.global_position.y+=(surface_height+clearance)-bounds.position.y

func set_highlight(target:Node) -> void:
	if not is_instance_valid(host): return
	var highlight_target:Variant=target.get_meta("highlight_target",target) if is_instance_valid(target) else target
	if highlight_target is Node: target=highlight_target as Node
	if host.highlighted_target==target and (target==null or is_instance_valid(target)): return
	for mesh in host.highlighted_meshes:
		if is_instance_valid(mesh): mesh.queue_free()
	host.highlighted_meshes.clear()
	host.highlighted_target=target
	if target==null: return
	var meshes:Array[MeshInstance3D]=[]
	if target is MeshInstance3D and target.mesh: meshes.append(target)
	else:
		for child in target.find_children("*","MeshInstance3D",true,false):
			var child_mesh:=child as MeshInstance3D
			if child_mesh and child_mesh.is_visible_in_tree() and child_mesh.mesh and child_mesh.name!="__InteractionOutline" and child_mesh.name!="__InteractionSilhouette" and not child_mesh.is_queued_for_deletion(): meshes.append(child_mesh)
	if meshes.is_empty(): return
	var outline_shader:=Shader.new()
	outline_shader.code="shader_type spatial;\nrender_mode unshaded, cull_front, depth_draw_opaque;\nuniform vec4 outline_color : source_color = vec4(0.2, 1.0, 0.45, 1.0);\nuniform float outline_width = 0.012;\nvoid vertex(){ VERTEX += NORMAL * outline_width; }\nvoid fragment(){ ALBEDO = outline_color.rgb; EMISSION = outline_color.rgb; }"
	for source in meshes:
		var silhouette_material:=ShaderMaterial.new()
		silhouette_material.shader=outline_shader
		silhouette_material.render_priority=1
		var source_scale:=source.global_transform.basis.get_scale()
		var max_scale:=maxf(maxf(absf(source_scale.x),absf(source_scale.y)),absf(source_scale.z))
		silhouette_material.set_shader_parameter("outline_width",0.012/maxf(max_scale,0.001))
		var silhouette:=MeshInstance3D.new()
		silhouette.name="__InteractionSilhouette"
		silhouette.mesh=source.mesh
		silhouette.global_transform=source.global_transform
		silhouette.material_override=silhouette_material
		silhouette.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		host.add_child(silhouette)
		host.highlighted_meshes.append(silhouette)
