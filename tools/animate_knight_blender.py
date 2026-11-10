import bpy
import math
import os
import sys

# Run inside Blender 4.5
# Renders 2.5D articulated pixel art combat animation frames

BASE_DIR = "d:/ponly/Blood Gambit"

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def setup_ortho_camera(width=160, height=290, ortho_scale=2.75):
    cam_data = bpy.data.cameras.new("OrthoCam")
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = ortho_scale
    
    cam_obj = bpy.data.objects.new("Camera", cam_data)
    bpy.context.scene.collection.objects.link(cam_obj)
    cam_obj.location = (0.0, -5.0, 1.35)
    cam_obj.rotation_euler = (math.radians(90.0), 0.0, 0.0)
    
    bpy.context.scene.camera = cam_obj
    bpy.context.scene.render.resolution_x = width
    bpy.context.scene.render.resolution_y = height
    bpy.context.scene.render.film_transparent = True
    bpy.context.scene.render.image_settings.file_format = 'PNG'
    bpy.context.scene.render.image_settings.color_mode = 'RGBA'
    return cam_obj

def create_piece_plane(name, img_path, width, height, z_offset=0.0):
    mesh = bpy.data.meshes.new(name + "_mesh")
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    
    hw = width * 0.5
    hh = height * 0.5
    verts = [
        (-hw, z_offset, -hh),
        ( hw, z_offset, -hh),
        ( hw, z_offset,  hh),
        (-hw, z_offset,  hh)
    ]
    faces = [(0, 1, 2, 3)]
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    
    uv_layer = mesh.uv_layers.new(name="UVMap")
    uvs = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]
    for loop_idx, loop in enumerate(mesh.loops):
        uv_layer.data[loop_idx].uv = uvs[loop_idx % 4]
        
    mat = bpy.data.materials.new(name + "_mat")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    
    tex_node = nodes.new("ShaderNodeTexImage")
    tex_img = bpy.data.images.load(img_path)
    tex_img.colorspace_settings.name = 'sRGB'
    tex_node.image = tex_img
    tex_node.interpolation = 'Closest' # Crisp nearest-neighbor pixel art!
    
    emission = nodes.new("ShaderNodeEmission")
    emission.inputs['Strength'].default_value = 1.0
    mat.node_tree.links.new(tex_node.outputs['Color'], emission.inputs['Color'])
    
    transparent = nodes.new("ShaderNodeBsdfTransparent")
    mix = nodes.new("ShaderNodeMixShader")
    mat.node_tree.links.new(tex_node.outputs['Alpha'], mix.inputs['Fac'])
    mat.node_tree.links.new(transparent.outputs['BSDF'], mix.inputs[1])
    mat.node_tree.links.new(emission.outputs['Emission'], mix.inputs[2])
    
    output = nodes.new("ShaderNodeOutputMaterial")
    mat.node_tree.links.new(mix.outputs['Shader'], output.inputs['Surface'])
    
    mat.blend_method = 'CLIP' if hasattr(mat, 'blend_method') else 'OPAQUE'
    obj.data.materials.append(mat)
    
    return obj

def build_rig(faction="white"):
    parts_dir = os.path.join(BASE_DIR, f"art/sprites/segmented/{faction}_pawn")
    
    scale = 2.35
    aspect = 155.0 / 282.0 if faction == "white" else 142.0 / 275.0
    total_w = scale * aspect
    
    arm_data = bpy.data.armatures.new("PawnArmature")
    arm_obj = bpy.data.objects.new("Armature", arm_data)
    bpy.context.scene.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj
    
    bpy.ops.object.mode_set(mode='EDIT')
    
    root_b = arm_data.edit_bones.new("root")
    root_b.head = (0, 0, 0)
    root_b.tail = (0, 0, 0.4)
    
    torso_b = arm_data.edit_bones.new("torso")
    torso_b.parent = root_b
    torso_b.head = (0, 0, 1.05)
    torso_b.tail = (0, 0, 1.70)
    
    head_b = arm_data.edit_bones.new("head")
    head_b.parent = torso_b
    head_b.head = (0, 0, 1.70)
    head_b.tail = (0, 0, 2.30)
    
    shield_b = arm_data.edit_bones.new("shield_arm")
    shield_b.parent = torso_b
    is_left_side = (faction == "white")
    sx = -total_w * 0.28 if is_left_side else total_w * 0.28
    shield_b.head = (sx, 0, 1.55)
    shield_b.tail = (sx * 1.3, 0, 1.15)
    
    sword_b = arm_data.edit_bones.new("sword_arm")
    sword_b.parent = torso_b
    swx = total_w * 0.26 if is_left_side else -total_w * 0.26
    sword_b.head = (swx, 0, 1.55)
    sword_b.tail = (swx * 1.3, 0, 0.95)
    
    legs_b = arm_data.edit_bones.new("legs")
    legs_b.parent = root_b
    legs_b.head = (0, 0, 0.95)
    legs_b.tail = (0, 0, 0.15)
    
    bpy.ops.object.mode_set(mode='OBJECT')
    
    # Load and create piece planes
    head_img = os.path.join(parts_dir, "head.png")
    torso_img = os.path.join(parts_dir, "torso.png")
    shield_img = os.path.join(parts_dir, "shield.png")
    sword_img = os.path.join(parts_dir, "sword.png")
    legs_img = os.path.join(parts_dir, "legs.png")
    
    head_plane = create_piece_plane("Head", head_img, total_w, scale, z_offset=0.005)
    torso_plane = create_piece_plane("Torso", torso_img, total_w, scale, z_offset=0.0)
    shield_plane = create_piece_plane("Shield", shield_img, total_w, scale, z_offset=-0.015)
    sword_plane = create_piece_plane("Sword", sword_img, total_w, scale, z_offset=-0.010)
    legs_plane = create_piece_plane("Legs", legs_img, total_w, scale, z_offset=0.010)
    
    planes = {
        "head": head_plane,
        "torso": torso_plane,
        "shield_arm": shield_plane,
        "sword_arm": sword_plane,
        "legs": legs_plane
    }
    
    for bone_name, plane in planes.items():
        plane.location = (0, 0, scale * 0.5)
        plane.parent = arm_obj
        plane.parent_type = 'BONE'
        plane.parent_bone = bone_name
        plane.matrix_parent_inverse = arm_obj.matrix_world.inverted()
        
    return arm_obj, planes

def set_bone_transform(arm_obj, bone_name, rot_euler_deg=(0,0,0), loc=(0,0,0), scale=(1,1,1)):
    p_bone = arm_obj.pose.bones.get(bone_name)
    if not p_bone:
        return
    p_bone.rotation_mode = 'XYZ'
    p_bone.rotation_euler = (math.radians(rot_euler_deg[0]), math.radians(rot_euler_deg[1]), math.radians(rot_euler_deg[2]))
    p_bone.location = loc
    p_bone.scale = scale

def reset_pose(arm_obj):
    for p_bone in arm_obj.pose.bones:
        p_bone.rotation_mode = 'XYZ'
        p_bone.rotation_euler = (0, 0, 0)
        p_bone.location = (0, 0, 0)
        p_bone.scale = (1, 1, 1)

def render_frame(output_path):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    bpy.context.scene.render.filepath = output_path
    bpy.ops.render.render(write_still=True)
    print(f"Rendered: {output_path}")

def generate_animations(faction="white"):
    out_dir = os.path.join(BASE_DIR, f"art/sprites/animated_pixel/{faction}_pawn")
    is_white = (faction == "white")
    
    clear_scene()
    setup_ortho_camera()
    arm_obj, planes = build_rig(faction)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode='POSE')
    
    # ---------------- 1. Idle (4 frames breathing cycle)
    for f in range(4):
        reset_pose(arm_obj)
        t = f / 4.0 * math.pi * 2.0
        breath = math.sin(t)
        set_bone_transform(arm_obj, "torso", rot_euler_deg=(0, 0, 0), loc=(0, 0, breath * 0.02), scale=(1.0 - breath*0.015, 1.0, 1.0 + breath*0.025))
        set_bone_transform(arm_obj, "head", rot_euler_deg=(0, 0, breath * 1.5), loc=(0, 0, breath * 0.01))
        set_bone_transform(arm_obj, "shield_arm", rot_euler_deg=(0, 0, -breath * 2.0))
        set_bone_transform(arm_obj, "sword_arm", rot_euler_deg=(0, 0, breath * 2.0))
        render_frame(os.path.join(out_dir, f"idle_{f}.png"))
        
    # ---------------- 2. Guard Stances (Left, Right, Top)
    # Guard Left (หันซ้าย)
    reset_pose(arm_obj)
    # Twists body left, raises shield forward into blocking position, sword tucked back
    rot_dir = 1.0 if is_white else -1.0
    set_bone_transform(arm_obj, "torso", rot_euler_deg=(0, -rot_dir * 14.0, -rot_dir * 6.0), loc=(-rot_dir * 0.05, 0, 0))
    set_bone_transform(arm_obj, "head", rot_euler_deg=(0, -rot_dir * 18.0, -rot_dir * 4.0))
    set_bone_transform(arm_obj, "shield_arm", rot_euler_deg=(0, 0, -rot_dir * 15.0), loc=(-rot_dir * 0.08, -0.04, 0.04))
    set_bone_transform(arm_obj, "sword_arm", rot_euler_deg=(0, 0, -rot_dir * 18.0), loc=(rot_dir * 0.04, 0.02, -0.02))
    render_frame(os.path.join(out_dir, "guard_left.png"))
    
    # Guard Right (หันขวา)
    reset_pose(arm_obj)
    # Twists body right, sword held high and ready to strike, shield guards ribs
    set_bone_transform(arm_obj, "torso", rot_euler_deg=(0, rot_dir * 14.0, rot_dir * 6.0), loc=(rot_dir * 0.05, 0, 0))
    set_bone_transform(arm_obj, "head", rot_euler_deg=(0, rot_dir * 18.0, rot_dir * 4.0))
    set_bone_transform(arm_obj, "sword_arm", rot_euler_deg=(0, 0, rot_dir * 28.0), loc=(rot_dir * 0.06, -0.03, 0.08))
    set_bone_transform(arm_obj, "shield_arm", rot_euler_deg=(0, 0, rot_dir * 10.0), loc=(rot_dir * 0.03, 0.02, 0.02))
    render_frame(os.path.join(out_dir, "guard_right.png"))
    
    # Guard Top (การ์ดบน)
    reset_pose(arm_obj)
    # Standing tall, sword held high above head, shield centered
    set_bone_transform(arm_obj, "torso", rot_euler_deg=(0, 0, 0), loc=(0, 0, 0.04), scale=(0.96, 1.0, 1.04))
    set_bone_transform(arm_obj, "head", rot_euler_deg=(-5.0, 0, 0), loc=(0, 0, 0.05))
    set_bone_transform(arm_obj, "sword_arm", rot_euler_deg=(0, 0, 48.0 if is_white else -48.0), loc=(0, -0.04, 0.16))
    set_bone_transform(arm_obj, "shield_arm", rot_euler_deg=(0, 0, 15.0 if is_white else -15.0), loc=(0.04 if is_white else -0.04, -0.02, 0.06))
    render_frame(os.path.join(out_dir, "guard_top.png"))
    
    # ---------------- 3. Slash Left (4 frames)
    # f0: Windup back left
    reset_pose(arm_obj)
    set_bone_transform(arm_obj, "torso", rot_euler_deg=(0, -rot_dir * 18.0, -rot_dir * 8.0), loc=(-rot_dir * 0.06, 0.04, -0.04))
    set_bone_transform(arm_obj, "sword_arm", rot_euler_deg=(0, 0, -rot_dir * 35.0), loc=(-rot_dir * 0.12, 0.06, -0.08))
    set_bone_transform(arm_obj, "shield_arm", rot_euler_deg=(0, 0, rot_dir * 15.0))
    render_frame(os.path.join(out_dir, "slash_left_0.png"))
    
    # f1: Lunge start
    reset_pose(arm_obj)
    set_bone_transform(arm_obj, "torso", rot_euler_deg=(0, 0, 0), loc=(0, -0.05, -0.02))
    set_bone_transform(arm_obj, "sword_arm", rot_euler_deg=(0, 0, 0), loc=(0, -0.04, 0.04))
    render_frame(os.path.join(out_dir, "slash_left_1.png"))
    
    # f2: Full horizontal slash impact across body
    reset_pose(arm_obj)
    set_bone_transform(arm_obj, "torso", rot_euler_deg=(0, rot_dir * 24.0, rot_dir * 12.0), loc=(rot_dir * 0.12, -0.08, -0.03))
    set_bone_transform(arm_obj, "sword_arm", rot_euler_deg=(0, 0, rot_dir * 65.0), loc=(rot_dir * 0.22, -0.08, 0.10))
    set_bone_transform(arm_obj, "head", rot_euler_deg=(0, -rot_dir * 10.0, rot_dir * 5.0))
    render_frame(os.path.join(out_dir, "slash_left_2.png"))
    
    # f3: Follow-through & recovery
    reset_pose(arm_obj)
    set_bone_transform(arm_obj, "torso", rot_euler_deg=(0, rot_dir * 10.0, rot_dir * 4.0), loc=(rot_dir * 0.04, -0.02, 0))
    set_bone_transform(arm_obj, "sword_arm", rot_euler_deg=(0, 0, rot_dir * 30.0), loc=(rot_dir * 0.08, 0, 0.02))
    render_frame(os.path.join(out_dir, "slash_left_3.png"))
    
    # ---------------- 4. Slash Right (4 frames)
    # f0: Windup high right
    reset_pose(arm_obj)
    set_bone_transform(arm_obj, "torso", rot_euler_deg=(0, rot_dir * 22.0, rot_dir * 10.0), loc=(rot_dir * 0.06, 0.04, 0.02))
    set_bone_transform(arm_obj, "sword_arm", rot_euler_deg=(0, 0, rot_dir * 52.0), loc=(rot_dir * 0.14, 0.05, 0.16))
    set_bone_transform(arm_obj, "shield_arm", rot_euler_deg=(0, 0, -rot_dir * 12.0))
    render_frame(os.path.join(out_dir, "slash_right_0.png"))
    
    # f1: Downward acceleration
    reset_pose(arm_obj)
    set_bone_transform(arm_obj, "torso", rot_euler_deg=(0, rot_dir * 8.0, rot_dir * 4.0), loc=(0, -0.04, 0.02))
    set_bone_transform(arm_obj, "sword_arm", rot_euler_deg=(0, 0, rot_dir * 18.0), loc=(rot_dir * 0.06, -0.04, 0.08))
    render_frame(os.path.join(out_dir, "slash_right_1.png"))
    
    # f2: Heavy diagonal slash cleave
    reset_pose(arm_obj)
    set_bone_transform(arm_obj, "torso", rot_euler_deg=(0, -rot_dir * 20.0, -rot_dir * 10.0), loc=(-rot_dir * 0.10, -0.08, -0.06))
    set_bone_transform(arm_obj, "sword_arm", rot_euler_deg=(0, 0, -rot_dir * 55.0), loc=(-rot_dir * 0.18, -0.06, -0.12))
    render_frame(os.path.join(out_dir, "slash_right_2.png"))
    
    # f3: Follow-through
    reset_pose(arm_obj)
    set_bone_transform(arm_obj, "torso", rot_euler_deg=(0, -rot_dir * 6.0, 0), loc=(0, 0, 0))
    set_bone_transform(arm_obj, "sword_arm", rot_euler_deg=(0, 0, -rot_dir * 20.0), loc=(0, 0, 0))
    render_frame(os.path.join(out_dir, "slash_right_3.png"))
    
    # ---------------- 5. Slash Top / Overhead (4 frames)
    # f0: High overhead arch
    reset_pose(arm_obj)
    set_bone_transform(arm_obj, "torso", rot_euler_deg=(-10.0, 0, 0), loc=(0, 0.05, 0.08), scale=(0.95, 1.0, 1.10))
    set_bone_transform(arm_obj, "sword_arm", rot_euler_deg=(0, 0, 70.0 if is_white else -70.0), loc=(0, 0.04, 0.28))
    set_bone_transform(arm_obj, "head", rot_euler_deg=(-15.0, 0, 0), loc=(0, 0.02, 0.08))
    render_frame(os.path.join(out_dir, "slash_top_0.png"))
    
    # f1: Downward strike start
    reset_pose(arm_obj)
    set_bone_transform(arm_obj, "torso", rot_euler_deg=(5.0, 0, 0), loc=(0, -0.04, 0.02))
    set_bone_transform(arm_obj, "sword_arm", rot_euler_deg=(0, 0, 25.0 if is_white else -25.0), loc=(0, -0.04, 0.12))
    render_frame(os.path.join(out_dir, "slash_top_1.png"))
    
    # f2: Crushing downward impact
    reset_pose(arm_obj)
    set_bone_transform(arm_obj, "torso", rot_euler_deg=(20.0, 0, 0), loc=(0, -0.08, -0.12), scale=(1.08, 1.0, 0.88))
    set_bone_transform(arm_obj, "sword_arm", rot_euler_deg=(0, 0, -40.0 if is_white else 40.0), loc=(0, -0.08, -0.22))
    set_bone_transform(arm_obj, "shield_arm", rot_euler_deg=(0, 0, 20.0 if is_white else -20.0), loc=(0, -0.04, -0.06))
    render_frame(os.path.join(out_dir, "slash_top_2.png"))
    
    # f3: Ground brace recovery
    reset_pose(arm_obj)
    set_bone_transform(arm_obj, "torso", rot_euler_deg=(5.0, 0, 0), loc=(0, -0.02, -0.04))
    set_bone_transform(arm_obj, "sword_arm", rot_euler_deg=(0, 0, 0), loc=(0, 0, 0))
    render_frame(os.path.join(out_dir, "slash_top_3.png"))
    
    # ---------------- 6. Parry Deflect (3 frames)
    # f0: Anticipation brace
    reset_pose(arm_obj)
    set_bone_transform(arm_obj, "torso", rot_euler_deg=(0, 0, 0), loc=(0, 0.02, -0.04), scale=(1.06, 1.0, 0.94))
    render_frame(os.path.join(out_dir, "parry_0.png"))
    
    # f1: Violent upward deflect strike!
    reset_pose(arm_obj)
    set_bone_transform(arm_obj, "torso", rot_euler_deg=(-8.0, 0, 0), loc=(0, -0.04, 0.12), scale=(0.92, 1.0, 1.15))
    set_bone_transform(arm_obj, "sword_arm", rot_euler_deg=(0, 0, 55.0 if is_white else -55.0), loc=(0.04 if is_white else -0.04, -0.06, 0.22))
    set_bone_transform(arm_obj, "shield_arm", rot_euler_deg=(0, 0, -25.0 if is_white else 25.0), loc=(-0.08 if is_white else 0.08, -0.06, 0.16))
    render_frame(os.path.join(out_dir, "parry_1.png"))
    
    # f2: Solid lock
    reset_pose(arm_obj)
    set_bone_transform(arm_obj, "torso", loc=(0, 0, 0.04))
    set_bone_transform(arm_obj, "sword_arm", rot_euler_deg=(0, 0, 30.0 if is_white else -30.0), loc=(0, 0, 0.08))
    render_frame(os.path.join(out_dir, "parry_2.png"))
    
    # ---------------- 7. Hit React (3 frames)
    # f0: Severe knockback impact
    reset_pose(arm_obj)
    set_bone_transform(arm_obj, "torso", rot_euler_deg=(-18.0, 0, 0), loc=(0, 0.15, -0.08), scale=(1.05, 1.0, 0.90))
    set_bone_transform(arm_obj, "head", rot_euler_deg=(-28.0, 0, 0), loc=(0, 0.12, 0.02))
    set_bone_transform(arm_obj, "sword_arm", rot_euler_deg=(0, 0, -35.0 if is_white else 35.0), loc=(0.10 if is_white else -0.10, 0.10, -0.05))
    set_bone_transform(arm_obj, "shield_arm", rot_euler_deg=(0, 0, 35.0 if is_white else -35.0), loc=(-0.10 if is_white else 0.10, 0.10, -0.05))
    render_frame(os.path.join(out_dir, "hit_react_0.png"))
    
    # f1: Stagger recovery
    reset_pose(arm_obj)
    set_bone_transform(arm_obj, "torso", rot_euler_deg=(-6.0, 0, 0), loc=(0, 0.06, -0.03))
    render_frame(os.path.join(out_dir, "hit_react_1.png"))
    
    # f2: Bracing feet
    reset_pose(arm_obj)
    set_bone_transform(arm_obj, "torso", loc=(0, 0, 0))
    render_frame(os.path.join(out_dir, "hit_react_2.png"))

if __name__ == "__main__":
    print("Generating White Pawn animations in Blender...")
    generate_animations("white")
    print("Generating Black Pawn animations in Blender...")
    generate_animations("black")
    print("All animations generated successfully!")
