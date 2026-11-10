"""
Render 3D Pawned Souls Duel Preview
----------------------------------
Renders a high-resolution preview of the White Knight vs Black Knight in the
dark fantasy 3D Colosseum arena with For Honor combat stances.
"""

import bpy
import math
import os
from mathutils import Vector, Euler

ARTIFACT_DIR = "C:/Users/Dwell/.gemini/antigravity/brain/d5cbd0d2-222f-40b5-bff0-276eecedfee4"
OUT_IMG = os.path.join(ARTIFACT_DIR, "pawned_souls_3d_preview.png")

# Clear scene
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for c in [bpy.data.actions, bpy.data.materials, bpy.data.meshes, bpy.data.armatures, bpy.data.cameras, bpy.data.lights]:
    for item in list(c):
        c.remove(item)

# Import White Knight GLB
white_glb = "d:/ponly/Blood Gambit/art/models/pawn_white_3d.glb"
bpy.ops.import_scene.gltf(filepath=white_glb)
white_arm = None
for obj in bpy.context.selected_objects:
    if obj.type == 'ARMATURE':
        white_arm = obj
        break

if white_arm:
    white_arm.location = (0, -1.8, 0)
    # Pose White Knight in guard stance with sword ready
    if white_arm.animation_data and bpy.data.actions.get("guard_right"):
        white_arm.animation_data.action = bpy.data.actions.get("guard_right")

# Import Black Knight GLB
black_glb = "d:/ponly/Blood Gambit/art/models/pawn_black_3d.glb"
bpy.ops.import_scene.gltf(filepath=black_glb)
black_arm = None
for obj in bpy.context.selected_objects:
    if obj.type == 'ARMATURE' and obj != white_arm:
        black_arm = obj
        break

if black_arm:
    black_arm.location = (0, 2.2, 0)
    black_arm.rotation_euler = (0, 0, math.pi) # Facing White Knight
    if black_arm.animation_data and bpy.data.actions.get("guard_left"):
        black_arm.animation_data.action = bpy.data.actions.get("guard_left")

# Environment: Arena Floor & Walls
# Stone floor
bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=12.0, depth=0.4, location=(0, 0, -0.2))
floor_obj = bpy.context.active_object
floor_obj.name = "ArenaFloor"
mat_floor = bpy.data.materials.new("FloorStone")
mat_floor.use_nodes = True
bsdf_f = mat_floor.node_tree.nodes.get("Principled BSDF")
if bsdf_f:
    bsdf_f.inputs['Base Color'].default_value = (0.08, 0.09, 0.12, 1.0)
    bsdf_f.inputs['Roughness'].default_value = 0.65
floor_obj.data.materials.append(mat_floor)

# Arena perimeter wall
bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=11.5, depth=4.0, location=(0, 0, 1.8))
wall_obj = bpy.context.active_object
wall_obj.name = "ArenaWall"
mat_wall = bpy.data.materials.new("WallStone")
mat_wall.use_nodes = True
bsdf_w = mat_wall.node_tree.nodes.get("Principled BSDF")
if bsdf_w:
    bsdf_w.inputs['Base Color'].default_value = (0.06, 0.07, 0.10, 1.0)
    bsdf_w.inputs['Roughness'].default_value = 0.8
wall_obj.data.materials.append(mat_wall)

# Lighting: Dramatic Dark Fantasy Duel Lighting
# 1. Warm Torch Firelight (Left Brazier)
bpy.ops.object.light_add(type='POINT', location=(-4.5, 0.0, 3.2))
torch_l = bpy.context.active_object
torch_l.data.color = (1.0, 0.55, 0.15)
torch_l.data.energy = 450.0

# 2. Warm Torch Firelight (Right Brazier)
bpy.ops.object.light_add(type='POINT', location=(4.5, 0.0, 3.2))
torch_r = bpy.context.active_object
torch_r.data.color = (1.0, 0.60, 0.20)
torch_r.data.energy = 450.0

# 3. Cool Moonlight Key Light
bpy.ops.object.light_add(type='SUN', location=(3.0, -5.0, 12.0))
sun = bpy.context.active_object
sun.data.color = (0.65, 0.78, 1.0)
sun.data.energy = 3.5
sun.rotation_euler = (math.radians(50), math.radians(20), math.radians(-25))

# 4. Fill light behind player
bpy.ops.object.light_add(type='POINT', location=(0.0, -4.5, 2.5))
fill = bpy.context.active_object
fill.data.color = (0.4, 0.6, 1.0)
fill.data.energy = 120.0

# Camera: Third-person Over-The-Shoulder (For Honor / Pawned Souls perspective)
cam_data = bpy.data.cameras.new("DuelCam")
cam_data.lens = 48.0
cam_obj = bpy.data.objects.new("DuelCam", cam_data)
bpy.context.collection.objects.link(cam_obj)
cam_obj.location = (0.75, -4.6, 2.3)
cam_obj.rotation_euler = (math.radians(78), 0, math.radians(8))

# Render settings
scene = bpy.context.scene
scene.camera = cam_obj
scene.render.engine = 'BLENDER_EEVEE_NEXT' if hasattr(bpy.types, 'RenderSettings') and 'BLENDER_EEVEE_NEXT' in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items else 'BLENDER_EEVEE'
scene.render.resolution_x = 1280
scene.render.resolution_y = 720
scene.render.filepath = OUT_IMG
scene.render.image_settings.file_format = 'PNG'

print(f"Rendering 3D Pawned Souls Duel Preview to {OUT_IMG}...")
bpy.ops.render.render(write_still=True)
print("Render complete!")
