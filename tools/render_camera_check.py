import bpy, math, os
from mathutils import Vector

white_glb = 'd:/ponly/Blood Gambit/art/models/pawn_white_3d.glb'
black_glb = 'd:/ponly/Blood Gambit/art/models/pawn_black_3d.glb'

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for c in [bpy.data.actions, bpy.data.materials, bpy.data.meshes, bpy.data.armatures, bpy.data.cameras, bpy.data.lights]:
    for item in list(c):
        c.remove(item)

bpy.ops.import_scene.gltf(filepath=white_glb)
w_arm = bpy.context.selected_objects[0] if bpy.context.selected_objects else None
for o in bpy.context.selected_objects:
    if o.type == 'ARMATURE': w_arm = o; break
if w_arm:
    w_arm.location = (0, -1.2, 0)
    if w_arm.animation_data and bpy.data.actions.get('guard_right'):
        w_arm.animation_data.action = bpy.data.actions.get('guard_right')

bpy.ops.import_scene.gltf(filepath=black_glb)
b_arm = None
for o in bpy.context.selected_objects:
    if o.type == 'ARMATURE' and o != w_arm: b_arm = o; break
if b_arm:
    b_arm.location = (0, 2.2, 0)
    b_arm.rotation_euler = (0, 0, math.pi)
    if b_arm.animation_data and bpy.data.actions.get('guard_left'):
        b_arm.animation_data.action = bpy.data.actions.get('guard_left')

# Arena Floor
bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=8.0, depth=0.2, location=(0,0,-0.1))

# Sun
bpy.ops.object.light_add(type='SUN', location=(3, -5, 10))
sun = bpy.context.active_object
sun.data.energy = 4.0
sun.rotation_euler = (math.radians(50), math.radians(20), math.radians(-30))

# Point lights (torches)
bpy.ops.object.light_add(type='POINT', location=(-3, 0.5, 2))
bpy.context.active_object.data.color = (1.0, 0.6, 0.2)
bpy.context.active_object.data.energy = 300

bpy.ops.object.light_add(type='POINT', location=(3, 0.5, 2))
bpy.context.active_object.data.color = (1.0, 0.6, 0.2)
bpy.context.active_object.data.energy = 300

# Camera with look_at
cam_data = bpy.data.cameras.new('TestCam')
cam_data.lens = 38.0
cam = bpy.data.objects.new('TestCam', cam_data)
bpy.context.collection.objects.link(cam)

cam_pos = Vector((1.3, -4.6, 2.3))
target_pos = Vector((0.0, 0.5, 1.2))
direction = target_pos - cam_pos
rot_quat = direction.to_track_quat('-Z', 'Y')
cam.location = cam_pos
cam.rotation_euler = rot_quat.to_euler()

scene = bpy.context.scene
scene.camera = cam
scene.render.engine = 'BLENDER_EEVEE_NEXT' if hasattr(bpy.types, 'RenderSettings') and 'BLENDER_EEVEE_NEXT' in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items else 'BLENDER_EEVEE'
scene.render.resolution_x = 1280
scene.render.resolution_y = 720
out_img = 'C:/Users/Dwell/.gemini/antigravity/brain/d5cbd0d2-222f-40b5-bff0-276eecedfee4/pawned_souls_3d_preview.png'
scene.render.filepath = out_img
scene.render.image_settings.file_format = 'PNG'
bpy.ops.render.render(write_still=True)
print('RENDER FINISHED!')
