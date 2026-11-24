import bpy
import math

OUTPUT = r"E:\GoDot\Malatang\malatang\assets\models\stage1_interior.glb"

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)

def material(name, color, metallic=0.0, roughness=0.7):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat

floor_mat = material("Stage1_Floor", (0.18, 0.20, 0.22), 0.05, 0.82)
wall_mat = material("Stage1_Wall", (0.82, 0.79, 0.72), 0.0, 0.86)
ceiling_mat = material("Stage1_Ceiling", (0.92, 0.89, 0.82), 0.0, 0.9)
trim_mat = material("Stage1_Trim", (0.24, 0.27, 0.29), 0.35, 0.35)
door_mat = material("Stage1_Entrance", (0.12, 0.15, 0.17), 0.15, 0.5)

def cube(name, location, dimensions, mat):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    return obj

# Blender Y is the front-to-back axis. The front entrance is at Y=0.6 and
# the rear kitchen wall is at Y=12, matching the Godot stage-1 footprint.
cube("InteriorFloor", (0, 6.3, -0.15), (18, 12, 0.3), floor_mat)
cube("InteriorBackWall", (0, 12, 2.5), (18, 0.25, 5), wall_mat)
cube("InteriorLeftWall", (-9, 6.3, 2.5), (0.25, 12, 5), wall_mat)
cube("InteriorRightWall", (9, 6.3, 2.5), (0.25, 12, 5), wall_mat)
cube("InteriorFrontWallLeft", (-2, 0.6, 2.5), (14, 0.25, 5), wall_mat)
cube("InteriorFrontWallRight", (8.35, 0.6, 2.5), (1.3, 0.25, 5), wall_mat)
cube("InteriorCeiling", (0, 6.3, 5.4), (18, 12, 0.25), ceiling_mat)

# Entrance frame only. No monitor desk or counter is created here.
cube("EntranceLeftPost", (5.0, 0.42, 2.2), (0.18, 0.35, 4.4), trim_mat)
cube("EntranceRightPost", (7.65, 0.42, 2.2), (0.18, 0.35, 4.4), trim_mat)
cube("EntranceHeader", (6.325, 0.42, 4.35), (2.8, 0.35, 0.22), trim_mat)
cube("RearKitchenTrim", (0, 11.78, 4.15), (17.6, 0.12, 0.22), trim_mat)

for obj in bpy.context.scene.objects:
    obj.select_set(True)

bpy.ops.export_scene.gltf(
    filepath=OUTPUT,
    export_format="GLB",
    use_selection=True,
    export_materials="EXPORT",
)
