"""
High Quality Pawned Souls 3D Knight Sculptor & GLB Exporter (V2)
---------------------------------------------------------------
Crafts seamlessly articulated, hard-surface dark fantasy 3D Chess Pawn Knights:
- Gorget neck guard, cupped pauldrons, elbow couters, knee poleyns (zero gaps)
- Correct upward-pointing sword bone so longsword points forward at enemy
- Heroic combat guard stances (Left, Right, Top) inspired by For Honor & Pawned Souls
- Double-edged steel longsword and curved heraldic kite shield with gold rim
- 17 skeletal animations
- Exports clean GLBs and renders high-res preview image
"""

import bpy
import math
import os
from mathutils import Vector, Euler

ROOT_DIR = "d:/ponly/Blood Gambit"
OUT_DIR = os.path.join(ROOT_DIR, "art/models")
ARTIFACT_DIR = "C:/Users/Dwell/.gemini/antigravity/brain/d5cbd0d2-222f-40b5-bff0-276eecedfee4"
os.makedirs(OUT_DIR, exist_ok=True)

def clear_all():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for c in [bpy.data.actions, bpy.data.materials, bpy.data.meshes, bpy.data.armatures, bpy.data.cameras, bpy.data.lights]:
        for item in list(c):
            c.remove(item)

def create_knight_material(name, base_rgb, metallic=0.9, roughness=0.35, emission_rgb=None, emission_strength=1.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    tree = mat.node_tree
    nodes = tree.nodes
    nodes.clear()

    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.location = (200, 0)
    bsdf.inputs['Base Color'].default_value = (base_rgb[0], base_rgb[1], base_rgb[2], 1.0)
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness

    if emission_rgb:
        if 'Emission Color' in bsdf.inputs:
            bsdf.inputs['Emission Color'].default_value = (emission_rgb[0], emission_rgb[1], emission_rgb[2], 1.0)
            bsdf.inputs['Emission Strength'].default_value = emission_strength
        elif 'Emission' in bsdf.inputs:
            bsdf.inputs['Emission'].default_value = (emission_rgb[0], emission_rgb[1], emission_rgb[2], 1.0)

    out_node = nodes.new(type='ShaderNodeOutputMaterial')
    out_node.location = (450, 0)
    tree.links.new(bsdf.outputs['BSDF'], out_node.inputs['Surface'])
    return mat

def create_hard_surface_mesh(primitive_type, name, loc=(0,0,0), rot=(0,0,0), scale=(1,1,1), mat=None, **kwargs):
    if primitive_type == 'cylinder':
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=kwargs.get('vertices', 16),
            radius=kwargs.get('radius', 0.2),
            depth=kwargs.get('depth', 0.4),
            location=loc,
            rotation=rot
        )
    elif primitive_type == 'box':
        bpy.ops.mesh.primitive_cube_add(
            size=1.0,
            location=loc,
            rotation=rot
        )
    elif primitive_type == 'sphere':
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=kwargs.get('segments', 16),
            ring_count=kwargs.get('rings', 12),
            radius=kwargs.get('radius', 0.2),
            location=loc,
            rotation=rot
        )
    elif primitive_type == 'cone':
        bpy.ops.mesh.primitive_cone_add(
            vertices=kwargs.get('vertices', 16),
            radius1=kwargs.get('r1', 0.2),
            radius2=kwargs.get('r2', 0.0),
            depth=kwargs.get('depth', 0.4),
            location=loc,
            rotation=rot
        )

    obj = bpy.context.active_object
    obj.name = name
    obj.scale = (obj.scale.x * scale[0], obj.scale.y * scale[1], obj.scale.z * scale[2])

    if mat:
        obj.data.materials.append(mat)

    bpy.ops.object.shade_smooth()
    mod = obj.modifiers.new(name="EdgeSplit", type='EDGE_SPLIT')
    mod.split_angle = math.radians(kwargs.get('split_angle', 34.0))

    return obj

def build_chiseled_3d_knight(is_white=True):
    clear_all()

    # Faction Materials
    if is_white:
        armor_mat = create_knight_material("WhitePlate", (0.86, 0.88, 0.94), metallic=0.92, roughness=0.28)
        gold_mat = create_knight_material("RoyalGold", (0.95, 0.75, 0.18), metallic=0.95, roughness=0.22)
        cloth_mat = create_knight_material("AzureTabard", (0.10, 0.26, 0.75), metallic=0.0, roughness=0.70)
        visor_mat = create_knight_material("CyanSoul", (0.1, 0.95, 1.0), metallic=0.0, roughness=0.1, emission_rgb=(0.1, 0.95, 1.0), emission_strength=6.0)
        steel_mat = create_knight_material("PolishedSteel", (0.95, 0.96, 0.98), metallic=0.98, roughness=0.15)
        leather_mat = create_knight_material("BrownLeather", (0.24, 0.15, 0.10), metallic=0.0, roughness=0.60)
        plume_mat = create_knight_material("WhiteFeather", (0.95, 0.96, 1.0), metallic=0.0, roughness=0.85)
    else:
        armor_mat = create_knight_material("ObsidianPlate", (0.12, 0.13, 0.16), metallic=0.92, roughness=0.32)
        gold_mat = create_knight_material("AntiqueBronze", (0.72, 0.42, 0.16), metallic=0.90, roughness=0.30)
        cloth_mat = create_knight_material("DreadVelvet", (0.26, 0.06, 0.38), metallic=0.0, roughness=0.70)
        visor_mat = create_knight_material("RubySoul", (1.0, 0.10, 0.20), metallic=0.0, roughness=0.1, emission_rgb=(1.0, 0.10, 0.20), emission_strength=6.5)
        steel_mat = create_knight_material("DarkSteel", (0.32, 0.33, 0.37), metallic=0.96, roughness=0.22)
        leather_mat = create_knight_material("DarkLeather", (0.14, 0.10, 0.08), metallic=0.0, roughness=0.60)
        plume_mat = create_knight_material("CrimsonFeather", (0.75, 0.08, 0.18), metallic=0.0, roughness=0.85)

    # 1. Armature (+Y Forward convention)
    bpy.ops.object.armature_add(location=(0, 0, 0))
    arm_obj = bpy.context.active_object
    arm_obj.name = "Knight_Armature"
    arm_data = arm_obj.data
    arm_data.name = "Knight_Rig"

    bpy.ops.object.mode_set(mode='EDIT')
    eb = arm_data.edit_bones
    for b in list(eb):
        eb.remove(b)

    def add_bone(name, head, tail, parent=None):
        b = eb.new(name)
        b.head = Vector(head)
        b.tail = Vector(tail)
        if parent and parent in eb:
            b.parent = eb[parent]
        return b

    # Rig hierarchy
    add_bone("Hips", (0, 0, 0.95), (0, 0, 1.15))
    add_bone("Spine", (0, 0, 1.15), (0, 0, 1.42), "Hips")
    add_bone("Chest", (0, 0, 1.42), (0, 0, 1.68), "Spine")
    add_bone("Neck", (0, 0, 1.68), (0, 0, 1.80), "Chest")
    add_bone("Head", (0, 0, 1.80), (0, 0, 2.10), "Neck")
    add_bone("Plume", (0, 0.10, 2.05), (0, -0.32, 2.15), "Head")

    # Left arm (Shield)
    add_bone("Shoulder_L", (-0.12, 0, 1.58), (-0.28, 0, 1.56), "Chest")
    add_bone("UpperArm_L", (-0.28, 0, 1.56), (-0.36, 0.06, 1.25), "Shoulder_L")
    add_bone("Forearm_L", (-0.36, 0.06, 1.25), (-0.32, 0.22, 1.05), "UpperArm_L")
    add_bone("Hand_L", (-0.32, 0.22, 1.05), (-0.28, 0.28, 1.00), "Forearm_L")
    add_bone("Shield_Mount", (-0.32, 0.24, 1.06), (-0.32, 0.42, 1.06), "Forearm_L")

    # Right arm (Sword)
    add_bone("Shoulder_R", (0.12, 0, 1.58), (0.28, 0, 1.56), "Chest")
    add_bone("UpperArm_R", (0.28, 0, 1.56), (0.36, 0.06, 1.25), "Shoulder_R")
    add_bone("Forearm_R", (0.36, 0.06, 1.25), (0.32, 0.20, 1.05), "UpperArm_R")
    add_bone("Hand_R", (0.32, 0.20, 1.05), (0.28, 0.28, 1.00), "Forearm_R")
    # Sword mount points UP along the blade!
    add_bone("Sword_Mount", (0.30, 0.22, 1.02), (0.30, 0.22, 1.60), "Hand_R")

    # Legs
    add_bone("Thigh_L", (-0.16, 0, 0.95), (-0.16, 0, 0.52), "Hips")
    add_bone("Shin_L", (-0.16, 0, 0.52), (-0.16, 0.02, 0.14), "Thigh_L")
    add_bone("Foot_L", (-0.16, 0.02, 0.14), (-0.16, 0.24, 0.04), "Shin_L")

    add_bone("Thigh_R", (0.16, 0, 0.95), (0.16, 0, 0.52), "Hips")
    add_bone("Shin_R", (0.16, 0, 0.52), (0.16, 0.02, 0.14), "Thigh_R")
    add_bone("Foot_R", (0.16, 0.02, 0.14), (0.16, 0.24, 0.04), "Shin_R")

    bpy.ops.object.mode_set(mode='OBJECT')

    # 2. Sculpted Armor Meshes
    mesh_objects = []

    def bind_to(obj, bone_name):
        obj.parent = arm_obj
        obj.parent_type = 'BONE'
        obj.parent_bone = bone_name
        obj.matrix_parent_inverse = arm_obj.matrix_world.inverted() @ arm_obj.pose.bones[bone_name].matrix.inverted()
        mesh_objects.append(obj)
        return obj

    # --- NECK / GORGET: Seamless collar connecting chest and helmet
    gorget = create_hard_surface_mesh('cylinder', "GorgetCollar", loc=(0, 0.01, 1.70), scale=(1.0, 0.9, 1.0), vertices=12, radius=0.15, depth=0.16, mat=armor_mat)
    bind_to(gorget, "Neck")
    gorget_trim = create_hard_surface_mesh('cylinder', "GorgetTrim", loc=(0, 0.01, 1.66), scale=(1.05, 0.95, 1.0), vertices=12, radius=0.155, depth=0.03, mat=gold_mat)
    bind_to(gorget_trim, "Neck")

    # --- HELMET: Sculpted Burgonet with Crest & Glowing Visor
    h_dome = create_hard_surface_mesh('sphere', "HelmetDome", loc=(0, 0.01, 1.94), scale=(0.95, 1.06, 0.95), radius=0.21, rings=10, segments=16, mat=armor_mat)
    bind_to(h_dome, "Head")

    h_comb = create_hard_surface_mesh('box', "HelmetComb", loc=(0, 0.02, 2.10), scale=(0.04, 0.36, 0.12), mat=gold_mat)
    bind_to(h_comb, "Head")

    h_chin = create_hard_surface_mesh('cylinder', "HelmetBevor", loc=(0, 0.04, 1.82), scale=(1.05, 0.95, 0.7), vertices=12, radius=0.19, depth=0.18, mat=armor_mat)
    bind_to(h_chin, "Head")

    h_slit = create_hard_surface_mesh('box', "VisorSlit", loc=(0, 0.20, 1.88), scale=(0.22, 0.035, 0.035), mat=visor_mat)
    bind_to(h_slit, "Head")

    plume1 = create_hard_surface_mesh('cone', "PlumeFeather1", loc=(0, -0.15, 2.18), rot=(math.radians(65), 0, 0), scale=(0.6, 1.4, 0.8), r1=0.14, r2=0.01, depth=0.38, mat=plume_mat)
    bind_to(plume1, "Plume")
    plume2 = create_hard_surface_mesh('cone', "PlumeFeather2", loc=(0, -0.32, 2.08), rot=(math.radians(75), 0, 0), scale=(0.5, 1.2, 0.7), r1=0.11, r2=0.01, depth=0.32, mat=plume_mat)
    bind_to(plume2, "Plume")

    # --- CHEST: Gothic Cuirass with Medial Ridge & Overlapping Pauldrons
    c_plate = create_hard_surface_mesh('cylinder', "Breastplate", loc=(0, 0.02, 1.48), scale=(1.18, 0.86, 1.0), vertices=10, radius=0.26, depth=0.34, mat=armor_mat)
    bind_to(c_plate, "Chest")

    c_ridge = create_hard_surface_mesh('box', "BreastplateRidge", loc=(0, 0.21, 1.48), rot=(math.radians(12), 0, 0), scale=(0.04, 0.05, 0.32), mat=gold_mat)
    bind_to(c_ridge, "Chest")

    c_crest = create_hard_surface_mesh('cylinder', "ChestInsignia", loc=(0, 0.21, 1.56), rot=(math.radians(90), 0, 0), vertices=8, radius=0.065, depth=0.03, mat=gold_mat)
    bind_to(c_crest, "Chest")

    # Pauldrons cupping the shoulder (inset tightly against the chest)
    p_l = create_hard_surface_mesh('sphere', "Pauldron_L", loc=(-0.28, 0.02, 1.56), scale=(1.05, 1.05, 0.85), radius=0.17, segments=12, rings=8, mat=armor_mat)
    bind_to(p_l, "Shoulder_L")
    p_trim_l = create_hard_surface_mesh('cylinder', "PauldronTrim_L", loc=(-0.28, 0.02, 1.48), scale=(1.02, 1.02, 1.0), vertices=12, radius=0.175, depth=0.03, mat=gold_mat)
    bind_to(p_trim_l, "Shoulder_L")

    p_r = create_hard_surface_mesh('sphere', "Pauldron_R", loc=(0.28, 0.02, 1.56), scale=(1.05, 1.05, 0.85), radius=0.17, segments=12, rings=8, mat=armor_mat)
    bind_to(p_r, "Shoulder_R")
    p_trim_r = create_hard_surface_mesh('cylinder', "PauldronTrim_R", loc=(0.28, 0.02, 1.48), scale=(1.02, 1.02, 1.0), vertices=12, radius=0.175, depth=0.03, mat=gold_mat)
    bind_to(p_trim_r, "Shoulder_R")

    # --- WAIST & HIPS: Faulds, Leather Belt, Faction Tabard
    w_plate = create_hard_surface_mesh('cylinder', "WaistArmor", loc=(0, 0, 1.24), scale=(1.10, 0.84, 1.0), vertices=10, radius=0.22, depth=0.22, mat=armor_mat)
    bind_to(w_plate, "Spine")

    belt = create_hard_surface_mesh('cylinder', "Belt", loc=(0, 0, 1.13), scale=(1.12, 0.86, 1.0), vertices=12, radius=0.23, depth=0.06, mat=leather_mat)
    bind_to(belt, "Spine")

    buckle = create_hard_surface_mesh('box', "BeltBuckle", loc=(0, 0.20, 1.13), scale=(0.08, 0.03, 0.07), mat=gold_mat)
    bind_to(buckle, "Spine")

    tabard_f = create_hard_surface_mesh('box', "TabardFront", loc=(0, 0.19, 0.88), rot=(math.radians(-4), 0, 0), scale=(0.26, 0.02, 0.44), mat=cloth_mat)
    bind_to(tabard_f, "Hips")

    tabard_b = create_hard_surface_mesh('box', "TabardBack", loc=(0, -0.18, 0.90), rot=(math.radians(4), 0, 0), scale=(0.28, 0.02, 0.48), mat=cloth_mat)
    bind_to(tabard_b, "Hips")

    # --- LEFT ARM & HERALDIC KITE SHIELD
    arm_l = create_hard_surface_mesh('cylinder', "Arm_L", loc=(-0.32, 0.03, 1.40), vertices=8, radius=0.07, depth=0.30, mat=armor_mat)
    bind_to(arm_l, "UpperArm_L")

    couter_l = create_hard_surface_mesh('sphere', "Couter_L", loc=(-0.36, 0.06, 1.25), radius=0.075, segments=8, rings=6, mat=gold_mat)
    bind_to(couter_l, "Forearm_L")

    forearm_l = create_hard_surface_mesh('cylinder', "Forearm_L", loc=(-0.34, 0.14, 1.15), vertices=8, radius=0.065, depth=0.26, mat=armor_mat)
    bind_to(forearm_l, "Forearm_L")

    glove_l = create_hard_surface_mesh('box', "Gauntlet_L", loc=(-0.30, 0.24, 1.02), scale=(0.09, 0.11, 0.09), mat=leather_mat)
    bind_to(glove_l, "Hand_L")

    # Curved Heraldic Kite Shield (Held securely forward on forearm)
    shield_b = create_hard_surface_mesh('box', "ShieldBody", loc=(-0.32, 0.32, 1.06), scale=(0.42, 0.035, 0.68), mat=armor_mat)
    bind_to(shield_b, "Shield_Mount")

    shield_r = create_hard_surface_mesh('box', "ShieldRim", loc=(-0.32, 0.32, 1.06), scale=(0.45, 0.045, 0.71), mat=gold_mat)
    bind_to(shield_r, "Shield_Mount")

    cross_v = create_hard_surface_mesh('box', "ShieldCrossV", loc=(-0.32, 0.35, 1.08), scale=(0.08, 0.02, 0.52), mat=gold_mat)
    bind_to(cross_v, "Shield_Mount")

    cross_h = create_hard_surface_mesh('box', "ShieldCrossH", loc=(-0.32, 0.35, 1.16), scale=(0.28, 0.02, 0.08), mat=gold_mat)
    bind_to(cross_h, "Shield_Mount")

    # --- RIGHT ARM & CRUCIFORM LONGSWORD
    arm_r = create_hard_surface_mesh('cylinder', "Arm_R", loc=(0.32, 0.03, 1.40), vertices=8, radius=0.07, depth=0.30, mat=armor_mat)
    bind_to(arm_r, "UpperArm_R")

    couter_r = create_hard_surface_mesh('sphere', "Couter_R", loc=(0.36, 0.06, 1.25), radius=0.075, segments=8, rings=6, mat=gold_mat)
    bind_to(couter_r, "Forearm_R")

    forearm_r = create_hard_surface_mesh('cylinder', "Forearm_R", loc=(0.34, 0.14, 1.15), vertices=8, radius=0.065, depth=0.26, mat=armor_mat)
    bind_to(forearm_r, "Forearm_R")

    glove_r = create_hard_surface_mesh('box', "Gauntlet_R", loc=(0.30, 0.24, 1.02), scale=(0.09, 0.11, 0.09), mat=leather_mat)
    bind_to(glove_r, "Hand_R")

    # Longsword (Sharp Blade with fuller, gold crossguard, wheel pommel)
    s_blade = create_hard_surface_mesh('box', "SwordBlade", loc=(0.30, 0.22, 1.55), scale=(0.07, 0.015, 0.90), mat=steel_mat)
    bind_to(s_blade, "Sword_Mount")

    s_tip = create_hard_surface_mesh('cone', "SwordTip", loc=(0.30, 0.22, 2.05), rot=(0, 0, math.radians(45)), vertices=4, r1=0.045, r2=0.0, depth=0.15, mat=steel_mat)
    bind_to(s_tip, "Sword_Mount")

    s_guard = create_hard_surface_mesh('box', "SwordCrossguard", loc=(0.30, 0.22, 1.08), scale=(0.26, 0.045, 0.05), mat=gold_mat)
    bind_to(s_guard, "Sword_Mount")

    s_grip = create_hard_surface_mesh('cylinder', "SwordGrip", loc=(0.30, 0.22, 0.96), vertices=8, radius=0.025, depth=0.20, mat=leather_mat)
    bind_to(s_grip, "Sword_Mount")

    s_pommel = create_hard_surface_mesh('sphere', "SwordPommel", loc=(0.30, 0.22, 0.84), scale=(1.0, 0.75, 1.2), radius=0.048, segments=8, rings=6, mat=gold_mat)
    bind_to(s_pommel, "Sword_Mount")

    # --- LEGS & GREAVES
    thigh_l = create_hard_surface_mesh('cylinder', "Thigh_L_Mesh", loc=(-0.16, 0, 0.74), vertices=8, radius=0.09, depth=0.42, mat=armor_mat)
    bind_to(thigh_l, "Thigh_L")
    shin_l = create_hard_surface_mesh('cylinder', "Shin_L_Mesh", loc=(-0.16, 0.01, 0.33), vertices=8, radius=0.075, depth=0.38, mat=armor_mat)
    bind_to(shin_l, "Shin_L")
    knee_l = create_hard_surface_mesh('sphere', "Poleyn_L", loc=(-0.16, 0.07, 0.52), scale=(1.0, 1.2, 0.9), radius=0.08, segments=8, rings=6, mat=gold_mat)
    bind_to(knee_l, "Shin_L")
    foot_l = create_hard_surface_mesh('box', "Sabaton_L", loc=(-0.16, 0.10, 0.04), scale=(0.11, 0.22, 0.08), mat=armor_mat)
    bind_to(foot_l, "Foot_L")

    thigh_r = create_hard_surface_mesh('cylinder', "Thigh_R_Mesh", loc=(0.16, 0, 0.74), vertices=8, radius=0.09, depth=0.42, mat=armor_mat)
    bind_to(thigh_r, "Thigh_R")
    shin_r = create_hard_surface_mesh('cylinder', "Shin_R_Mesh", loc=(0.16, 0.01, 0.33), vertices=8, radius=0.075, depth=0.38, mat=armor_mat)
    bind_to(shin_r, "Shin_R")
    knee_r = create_hard_surface_mesh('sphere', "Poleyn_R", loc=(0.16, 0.07, 0.52), scale=(1.0, 1.2, 0.9), radius=0.08, segments=8, rings=6, mat=gold_mat)
    bind_to(knee_r, "Shin_R")
    foot_r = create_hard_surface_mesh('box', "Sabaton_R", loc=(0.16, 0.10, 0.04), scale=(0.11, 0.22, 0.08), mat=armor_mat)
    bind_to(foot_r, "Foot_R")

    # 3. Skeletal Combat Animations
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode='POSE')

    created_actions = []

    def make_action(name):
        act = bpy.data.actions.new(name=name)
        act.use_fake_user = True
        if not arm_obj.animation_data:
            arm_obj.animation_data_create()
        arm_obj.animation_data.action = act
        created_actions.append(act)
        return act

    def key(bone_name, f, loc=None, rot=None, scale=None):
        pb = arm_obj.pose.bones.get(bone_name)
        if not pb:
            return
        pb.rotation_mode = 'XYZ'
        if loc is not None:
            pb.location = loc
            pb.keyframe_insert(data_path="location", frame=f)
        if rot is not None:
            pb.rotation_euler = Euler((math.radians(rot[0]), math.radians(rot[1]), math.radians(rot[2])), 'XYZ')
            pb.keyframe_insert(data_path="rotation_euler", frame=f)
        if scale is not None:
            pb.scale = scale
            pb.keyframe_insert(data_path="scale", frame=f)

    # 1: IDLE (sword tilted forward 25°, shield ready)
    make_action("idle")
    for f in [1, 15, 30]:
        t = (f - 1) / 29.0 * math.pi * 2.0
        b = math.sin(t)
        key("Spine", f, rot=(b * 1.5, 0, 0), loc=(0, 0, b * 0.015))
        key("Chest", f, rot=(-b * 1.0, 0, 0))
        key("Head", f, rot=(b * 1.0, 0, 0))
        key("Plume", f, rot=(b * 4.0, 0, 0))
        key("UpperArm_L", f, rot=(10.0, 0, -10.0 - b * 1.5))
        key("Shield_Mount", f, rot=(0, 0, b * 1.0))
        key("UpperArm_R", f, rot=(15.0, 0, 10.0 + b * 1.5))
        key("Sword_Mount", f, rot=(-25.0 - b * 2.0, 0, -10.0))

    # 2: WALK_FORWARD
    make_action("walk_forward")
    for f, leg_phase in [(1, 0.0), (8, 0.5), (15, 1.0), (22, 1.5), (30, 2.0)]:
        angle_l = math.sin(leg_phase * math.pi) * 24.0
        angle_r = -math.sin(leg_phase * math.pi) * 24.0
        bob = abs(math.cos(leg_phase * math.pi)) * 0.03
        key("Hips", f, loc=(0, 0, bob))
        key("Thigh_L", f, rot=(angle_l, 0, 0))
        key("Shin_L", f, rot=(max(0.0, -angle_l * 0.8), 0, 0))
        key("Thigh_R", f, rot=(angle_r, 0, 0))
        key("Shin_R", f, rot=(max(0.0, -angle_r * 0.8), 0, 0))
        key("Spine", f, rot=(3.0, 0, -angle_l * 0.15))
        key("UpperArm_L", f, rot=(10.0, 0, -15.0 + angle_r * 0.2))
        key("UpperArm_R", f, rot=(15.0, 0, 10.0 + angle_l * 0.3))
        key("Sword_Mount", f, rot=(-20.0, 0, 0))

    # 3: WALK_BACK
    make_action("walk_back")
    for f, leg_phase in [(1, 0.0), (8, 0.5), (15, 1.0), (22, 1.5), (30, 2.0)]:
        angle_l = -math.sin(leg_phase * math.pi) * 18.0
        angle_r = math.sin(leg_phase * math.pi) * 18.0
        key("Thigh_L", f, rot=(angle_l, 0, 0))
        key("Thigh_R", f, rot=(angle_r, 0, 0))
        key("Spine", f, rot=(-4.0, 0, 0))
        key("UpperArm_L", f, rot=(15.0, 0, -20.0))
        key("Shield_Mount", f, rot=(10.0, 0, 0))
        key("Sword_Mount", f, rot=(-25.0, 0, 0))

    # 4: STRAFE_LEFT
    make_action("strafe_left")
    for f, p in [(1, 0.0), (6, 0.5), (12, 1.0), (18, 1.5), (24, 2.0)]:
        s = math.sin(p * math.pi) * 16.0
        key("Hips", f, loc=(-s * 0.003, 0, 0))
        key("Thigh_L", f, rot=(0, 0, -s))
        key("Thigh_R", f, rot=(0, 0, -s))
        key("Spine", f, rot=(0, 0, 5.0))
        key("Sword_Mount", f, rot=(-25.0, 0, 0))

    # 5: STRAFE_RIGHT
    make_action("strafe_right")
    for f, p in [(1, 0.0), (6, 0.5), (12, 1.0), (18, 1.5), (24, 2.0)]:
        s = math.sin(p * math.pi) * 16.0
        key("Hips", f, loc=(s * 0.003, 0, 0))
        key("Thigh_L", f, rot=(0, 0, s))
        key("Thigh_R", f, rot=(0, 0, s))
        key("Spine", f, rot=(0, 0, -5.0))
        key("Sword_Mount", f, rot=(-25.0, 0, 0))

    # 6: GUARD_LEFT (Shield braced forward, sword held ready pointing at enemy)
    make_action("guard_left")
    for f in [1, 15, 30]:
        t = (f - 1) / 29.0 * math.pi * 2.0
        b = math.sin(t)
        key("Spine", f, rot=(b * 1.5, 0, 16.0), loc=(-0.03, 0, b * 0.015))
        key("Chest", f, rot=(-b * 1.0, 0, 8.0))
        key("Head", f, rot=(b * 1.0, 0, -14.0)) # Head locks on enemy
        key("Plume", f, rot=(b * 4.0, 0, 0))
        # Left arm: Shield thrust forward to protect body
        key("UpperArm_L", f, rot=(25.0, 0, -20.0))
        key("Forearm_L", f, rot=(-15.0, 0, 25.0))
        key("Shield_Mount", f, rot=(10.0, 0, 10.0 + b * 1.0))
        # Right arm: Sword pointing forward
        key("UpperArm_R", f, rot=(10.0, 0, -10.0))
        key("Forearm_R", f, rot=(15.0, 0, -15.0))
        key("Sword_Mount", f, rot=(-45.0 - b * 2.0, 0, -20.0))

    # 7: GUARD_RIGHT (Right sword high guard, blade pointing forward-up, shield tucked)
    make_action("guard_right")
    for f in [1, 15, 30]:
        t = (f - 1) / 29.0 * math.pi * 2.0
        b = math.sin(t)
        key("Spine", f, rot=(b * 1.5, 0, -16.0), loc=(0.03, 0, b * 0.015))
        key("Chest", f, rot=(-b * 1.0, 0, -8.0))
        key("Head", f, rot=(b * 1.0, 0, 14.0))
        key("Plume", f, rot=(b * 4.0, 0, 0))
        # Right arm: Sword raised forward
        key("UpperArm_R", f, rot=(25.0, 0, 20.0))
        key("Forearm_R", f, rot=(20.0, 0, 15.0))
        key("Sword_Mount", f, rot=(-50.0 - b * 2.0, 0, 15.0))
        # Left arm: Shield guarding torso
        key("UpperArm_L", f, rot=(15.0, 0, 5.0))
        key("Shield_Mount", f, rot=(0, 0, -5.0 + b * 1.0))

    # 8: GUARD_TOP (High Ox Guard: Sword raised high above head pointing at enemy throat)
    make_action("guard_top")
    for f in [1, 15, 30]:
        t = (f - 1) / 29.0 * math.pi * 2.0
        b = math.sin(t)
        key("Spine", f, rot=(4.0 + b * 1.5, 0, 0), loc=(0, 0, 0.03 + b * 0.015))
        key("Chest", f, rot=(4.0 - b * 1.0, 0, 0))
        key("Head", f, rot=(-2.0 + b * 1.0, 0, 0))
        key("Plume", f, rot=(b * 4.0, 0, 0))
        # Sword raised high overhead, blade angled forward 65°
        key("UpperArm_R", f, rot=(55.0, 0, 35.0))
        key("Forearm_R", f, rot=(40.0, 0, 10.0))
        key("Sword_Mount", f, rot=(-65.0 - b * 2.0, 0, 5.0))
        # Shield held in front
        key("UpperArm_L", f, rot=(20.0, 0, -10.0))
        key("Shield_Mount", f, rot=(10.0, 0, 0))

    # 9: ATTACK_LEFT (Windup left, then horizontal blade cleave!)
    make_action("attack_left")
    key("Spine", 1, rot=(0, 0, 0))
    # f6: Windup left
    key("Spine", 6, rot=(0, 0, 24.0), loc=(-0.06, -0.04, 0))
    key("UpperArm_R", 6, rot=(20.0, 0, -35.0))
    key("Sword_Mount", 6, rot=(30.0, 0, -45.0))
    # f13: Impact slash forward-across
    key("Spine", 13, rot=(0, 0, -28.0), loc=(0.10, 0.18, -0.04))
    key("Chest", 13, rot=(0, 0, -16.0))
    key("UpperArm_R", 13, rot=(35.0, 0, 65.0))
    key("Forearm_R", 13, rot=(10.0, 0, 35.0))
    key("Sword_Mount", 13, rot=(75.0, 0, 70.0))
    key("Plume", 13, rot=(-15.0, 0, -20.0))
    # f24: Return
    key("Spine", 24, rot=(0, 0, 0), loc=(0, 0, 0))
    key("UpperArm_R", 24, rot=(15.0, 0, 10.0))
    key("Sword_Mount", 24, rot=(25.0, 0, -10.0))

    # 10: ATTACK_RIGHT (Windup right, heavy downward diagonal slash!)
    make_action("attack_right")
    key("Spine", 1, rot=(0, 0, 0))
    # f6: Windup high right
    key("Spine", 6, rot=(0, 0, -25.0), loc=(0.06, -0.04, 0.02))
    key("UpperArm_R", 6, rot=(65.0, 0, 45.0))
    key("Sword_Mount", 6, rot=(80.0, 0, 25.0))
    # f13: Heavy diagonal downward cleave!
    key("Spine", 13, rot=(-12.0, 0, 20.0), loc=(-0.08, 0.18, -0.06))
    key("UpperArm_R", 13, rot=(-10.0, 0, -30.0))
    key("Sword_Mount", 13, rot=(15.0, 0, -60.0))
    key("Plume", 13, rot=(12.0, 0, 20.0))
    # f24: Return
    key("Spine", 24, rot=(0, 0, 0), loc=(0, 0, 0))
    key("UpperArm_R", 24, rot=(15.0, 0, 10.0))
    key("Sword_Mount", 24, rot=(25.0, 0, -10.0))

    # 11: ATTACK_TOP (High leap overhead vertical smash!)
    make_action("attack_top")
    key("Spine", 1, rot=(0, 0, 0))
    # f8: Overhead windup
    key("Spine", 8, rot=(12.0, 0, 0), loc=(0, -0.06, 0.12))
    key("UpperArm_R", 8, rot=(80.0, 0, 20.0))
    key("Sword_Mount", 8, rot=(85.0, 0, 0))
    key("UpperArm_L", 8, rot=(35.0, 0, -15.0))
    # f15: Downward vertical cleave!
    key("Spine", 15, rot=(-22.0, 0, 0), loc=(0, 0.22, -0.12))
    key("Chest", 15, rot=(-12.0, 0, 0))
    key("UpperArm_R", 15, rot=(-15.0, 0, 0))
    key("Sword_Mount", 15, rot=(10.0, 0, 0))
    key("Plume", 15, rot=(30.0, 0, 0))
    # f28: Recover
    key("Spine", 28, rot=(0, 0, 0), loc=(0, 0, 0))
    key("UpperArm_R", 28, rot=(15.0, 0, 10.0))
    key("Sword_Mount", 28, rot=(25.0, 0, -10.0))

    # 12: PARRY (Explosive upward deflect with blade & shield push)
    make_action("parry")
    key("Spine", 1, rot=(0, 0, 0))
    # f6: Deflect thrust
    key("Spine", 6, rot=(10.0, 0, 0), loc=(0, 0.05, 0.06))
    key("UpperArm_R", 6, rot=(50.0, 0, 30.0))
    key("Sword_Mount", 6, rot=(75.0, 0, 15.0))
    key("UpperArm_L", 6, rot=(25.0, 0, -25.0))
    key("Shield_Mount", 6, rot=(20.0, 0, 10.0))
    # f16: Hold solid guard
    key("Spine", 16, rot=(0, 0, 0), loc=(0, 0, 0))
    key("UpperArm_R", 16, rot=(15.0, 0, 10.0))
    key("Sword_Mount", 16, rot=(25.0, 0, -10.0))

    # 13: BLOCK_IMPACT
    make_action("block_impact")
    key("Spine", 1, rot=(0, 0, 0))
    key("Spine", 4, rot=(-8.0, 0, 0), loc=(0, -0.06, -0.03))
    key("UpperArm_L", 4, rot=(30.0, 0, -30.0))
    key("Shield_Mount", 4, rot=(-10.0, 0, 15.0))
    key("Spine", 14, rot=(0, 0, 0), loc=(0, 0, 0))

    # 14: DODGE_STEP
    make_action("dodge_step")
    key("Spine", 1, rot=(0, 0, 0))
    key("Hips", 4, loc=(0, -0.12, -0.06))
    key("Spine", 4, rot=(12.0, 0, 0))
    key("Thigh_L", 4, rot=(-18.0, 0, 0))
    key("Shin_L", 4, rot=(30.0, 0, 0))
    key("Hips", 12, loc=(0, 0, 0))
    key("Spine", 12, rot=(0, 0, 0))

    # 15: DODGE_ROLL
    make_action("dodge_roll")
    key("Hips", 1, loc=(0, 0, 0), rot=(0, 0, 0))
    key("Hips", 5, loc=(0, 0.10, -0.38), rot=(45.0, 0, 0))
    key("Spine", 5, rot=(35.0, 0, 0))
    key("Hips", 13, loc=(0, 0.32, -0.52), rot=(180.0, 0, 0))
    key("Hips", 20, loc=(0, 0.18, -0.22), rot=(310.0, 0, 0))
    key("Hips", 26, loc=(0, 0, 0), rot=(360.0, 0, 0))
    key("Spine", 26, rot=(0, 0, 0))

    # 16: HIT_REACT
    make_action("hit_react")
    key("Spine", 1, rot=(0, 0, 0))
    key("Spine", 5, rot=(18.0, 0, 0), loc=(0, -0.20, -0.06))
    key("Head", 5, rot=(22.0, 0, 0))
    key("UpperArm_R", 5, rot=(10.0, 0, -25.0))
    key("UpperArm_L", 5, rot=(-12.0, 0, 25.0))
    key("Spine", 18, rot=(0, 0, 0), loc=(0, 0, 0))
    key("Head", 18, rot=(0, 0, 0))

    # 17: DEATH
    make_action("death")
    key("Spine", 1, rot=(0, 0, 0), loc=(0, 0, 0))
    key("Spine", 14, rot=(-14.0, 0, 0), loc=(0, -0.05, -0.42))
    key("Thigh_L", 14, rot=(55.0, 0, 0))
    key("Shin_L", 14, rot=(-75.0, 0, 0))
    key("Thigh_R", 14, rot=(45.0, 0, 0))
    key("Shin_R", 14, rot=(-65.0, 0, 0))
    key("Sword_Mount", 14, rot=(80.0, 0, 0))
    key("Spine", 30, rot=(-60.0, 0, 0), loc=(0, 0.18, -0.70))
    key("Head", 30, rot=(-22.0, 0, 0))

    arm_obj.animation_data.action = bpy.data.actions.get("idle")

    bpy.ops.object.mode_set(mode='OBJECT')

    # Export to GLB
    bpy.ops.object.select_all(action='DESELECT')
    arm_obj.select_set(True)
    for m in mesh_objects:
        m.select_set(True)

    filename = "pawn_white_3d.glb" if is_white else "pawn_black_3d.glb"
    out_path = os.path.join(OUT_DIR, filename)

    print(f"Exporting {filename} to {out_path}...")
    bpy.ops.export_scene.gltf(
        filepath=out_path,
        use_selection=True,
        export_format='GLB',
        export_yup=True,
        export_apply=True,
        export_animations=True,
        export_all_influences=True
    )
    print(f"Successfully exported: {filename}")

def render_duel_scene():
    clear_all()
    # Import White Knight
    white_glb = os.path.join(OUT_DIR, "pawn_white_3d.glb")
    bpy.ops.import_scene.gltf(filepath=white_glb)
    white_arm = None
    for obj in bpy.context.selected_objects:
        if obj.type == 'ARMATURE':
            white_arm = obj
            break
    if white_arm:
        white_arm.location = (0, -1.2, 0)
        if white_arm.animation_data and bpy.data.actions.get("guard_right"):
            white_arm.animation_data.action = bpy.data.actions.get("guard_right")

    # Import Black Knight
    black_glb = os.path.join(OUT_DIR, "pawn_black_3d.glb")
    bpy.ops.import_scene.gltf(filepath=black_glb)
    black_arm = None
    for obj in bpy.context.selected_objects:
        if obj.type == 'ARMATURE' and obj != white_arm:
            black_arm = obj
            break
    if black_arm:
        black_arm.location = (0, 2.2, 0)
        black_arm.rotation_euler = (0, 0, math.pi)
        if black_arm.animation_data and bpy.data.actions.get("guard_left"):
            black_arm.animation_data.action = bpy.data.actions.get("guard_left")

    # Colosseum Floor
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=10.0, depth=0.2, location=(0, 0, -0.1))
    f_obj = bpy.context.active_object
    f_mat = create_knight_material("StoneFloor", (0.09, 0.10, 0.13), metallic=0.1, roughness=0.7)
    f_obj.data.materials.append(f_mat)

    # Lighting
    # Torch Left
    bpy.ops.object.light_add(type='POINT', location=(-3.5, 0.5, 2.8))
    tl = bpy.context.active_object
    tl.data.color = (1.0, 0.6, 0.2)
    tl.data.energy = 450.0

    # Torch Right
    bpy.ops.object.light_add(type='POINT', location=(3.5, 0.5, 2.8))
    tr = bpy.context.active_object
    tr.data.color = (1.0, 0.65, 0.25)
    tr.data.energy = 450.0

    # Moonlight Sun
    bpy.ops.object.light_add(type='SUN', location=(2, -3, 8))
    sun = bpy.context.active_object
    sun.data.color = (0.7, 0.82, 1.0)
    sun.data.energy = 3.5
    sun.rotation_euler = (math.radians(45), math.radians(15), math.radians(-20))

    # Rim light from behind Black Knight
    bpy.ops.object.light_add(type='POINT', location=(0, 3.8, 2.5))
    rim = bpy.context.active_object
    rim.data.color = (0.8, 0.2, 0.4)
    rim.data.energy = 280.0

    # Camera: Over-The-Shoulder framed view
    cam_data = bpy.data.cameras.new("DuelCam")
    cam_data.lens = 42.0
    cam_obj = bpy.data.objects.new("DuelCam", cam_data)
    bpy.context.collection.objects.link(cam_obj)

    cam_pos = Vector((1.3, -4.5, 2.2))
    target_pos = Vector((0.0, 0.6, 1.3))
    direction = target_pos - cam_pos
    rot_quat = direction.to_track_quat('-Z', 'Y')
    cam_obj.location = cam_pos
    cam_obj.rotation_euler = rot_quat.to_euler()

    scene = bpy.context.scene
    scene.camera = cam_obj
    scene.render.engine = 'BLENDER_EEVEE_NEXT' if hasattr(bpy.types, 'RenderSettings') and 'BLENDER_EEVEE_NEXT' in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items else 'BLENDER_EEVEE'
    scene.render.resolution_x = 1280
    scene.render.resolution_y = 720
    out_img = os.path.join(ARTIFACT_DIR, "pawned_souls_3d_preview.png")
    scene.render.filepath = out_img
    scene.render.image_settings.file_format = 'PNG'

    print(f"Rendering updated 3D preview to {out_img}...")
    bpy.ops.render.render(write_still=True)
    print("Preview render done!")

if __name__ == "__main__":
    print("--- BUILDING WHITE KNIGHT 3D ---")
    build_chiseled_3d_knight(is_white=True)

    print("--- BUILDING BLACK KNIGHT 3D ---")
    build_chiseled_3d_knight(is_white=False)

    print("--- RENDERING DUEL PREVIEW ---")
    render_duel_scene()
    print("ALL DONE!")
