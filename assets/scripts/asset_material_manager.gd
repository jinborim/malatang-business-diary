extends Node

var host:Node

func setup(game_host:Node) -> void:
	host=game_host

func make_shared_steel_material() -> StandardMaterial3D:
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color("#ffffff")
	var texture:=load("res://assets/models/ingredient_bowl.png") as Texture2D
	if texture: material.albedo_texture=texture
	var normal:=load("res://assets/models/ingredient_bowl_normal.png") as Texture2D
	if normal:
		material.normal_enabled=true
		material.normal_texture=normal
	var metallic:=load("res://assets/models/ingredient_bowl_metallic.png") as Texture2D
	if metallic: material.metallic_texture=metallic
	var roughness:=load("res://assets/models/ingredient_bowl_roughness.png") as Texture2D
	if roughness: material.roughness_texture=roughness
	material.metallic=0.92
	material.roughness=0.2
	return material

func apply_tongs_material(root:Node) -> void:
	var material:=make_shared_steel_material()
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh_instance:=child as MeshInstance3D
		if not is_instance_valid(mesh_instance): continue
		mesh_instance.material_overlay=material
		if not mesh_instance.mesh: continue
		for surface in range(mesh_instance.mesh.get_surface_count()): mesh_instance.set_surface_override_material(surface,material)
