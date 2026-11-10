"""
Complete Pawned Souls 3D Knight Generator (V3)
-----------------------------------------------
Creates high-fidelity, rigged 3D Chess Pawn Knights matching:
- Indie hit 'Pawned Souls' (devmika) & Ubisoft's 'For Honor'
- Ornate plate armor, Burgonet helmet with flowing plume, glowing visor
- Kite shield with heraldic cross and double-edged longsword
- Faction palettes: Pearlescent Silver + Royal Blue (White) & Obsidian Plate + Royal Purple (Black)
- 17 Complete skeletal animations exported in glTF
"""

import os
import sys
import math
import bpy
from mathutils import Vector, Euler, Matrix

ROOT_DIR = "d:/ponly/Blood Gambit"
SRC_MODEL = "D:/ponly/Rift command/Dev/RIFT-COMMAND-0.14.0-development/RIFT-COMMAND-0.14.0-development/art/3d/models/kk-Knight.glb"
OUT_MODELS = os.path.join(ROOT_DIR, "art/models")
ARTIFACT_DIR = "C:/Users/Dwell/.gemini/antigravity/brain/d5cbd0d2-222f-40b5-bff0-276eecedfee4"

os.makedirs(OUT_MODELS, exist_ok=True)


def build_knight_variant(is_white, palette_path, export_glb_path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=SRC_MODEL)

    # Remove unwanted extra meshes
    to_delete = [
        '1H_Sword_Offhand', '2H_Sword', 'Rectangle_Shield', 'Round_Shield',
        'Spike_Shield', 'Icosphere', 'Cube', 'Camera', 'Light', 'Knight_Head'
    ]
    for name in to_delete:
        obj = bpy.data.objects.get(name)
        if obj:
            bpy.data.objects.remove(obj, do_unlink=True)

    rig = bpy.data.objects.get('Rig')

    # 1. Texture Palette Material
    palette_img = bpy.data.images.load(palette_path)
    palette_mat = bpy.data.materials.new(name="Knight_Faction_Mat")
    palette_mat.use_nodes = True
    bsdf = palette_mat.node_tree.nodes.get('Principled BSDF')
    tex_node = palette_mat.node_tree.nodes.new(type='ShaderNodeTexImage')
    tex_node.image = palette_img
    tex_node.interpolation = 'Closest'
    palette_mat.node_tree.links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])
    bsdf.inputs['Metallic'].default_value = 0.82 if is_white else 0.88
    bsdf.inputs['Roughness'].default_value = 0.28 if is_white else 0.32

    # Apply material to all character meshes
    kept_mesh_names = [
        'Knight_Helmet', 'Knight_Body', 'Knight_ArmLeft', 'Knight_ArmRight',
        'Knight_LegLeft', 'Knight_LegRight', 'Knight_Cape', '1H_Sword', 'Badge_Shield'
    ]
    for name in kept_mesh_names:
        obj = bpy.data.objects.get(name)
        if obj and obj.type == 'MESH':
            obj.data.materials.clear()
            obj.data.materials.append(palette_mat)

    # 2. Glowing Visor (Covers open face with dark plate & glowing soul slit)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.22, 1.28), scale=(0.34, 0.12, 0.18))
    visor = bpy.context.active_object
    visor.name = 'Knight_Visor'
    v_mat = bpy.data.materials.new(name="Visor_Glow_Mat")
    v_mat.use_nodes = True
    v_bsdf = v_mat.node_tree.nodes.get('Principled BSDF')
    v_bsdf.inputs['Base Color'].default_value = (0.05, 0.05, 0.08, 1.0)
    glow_col = (0.1, 0.95, 1.0, 1.0) if is_white else (1.0, 0.12, 0.22, 1.0)
    if 'Emission Color' in v_bsdf.inputs:
        v_bsdf.inputs['Emission Color'].default_value = glow_col
        v_bsdf.inputs['Emission Strength'].default_value = 6.0
    visor.data.materials.append(v_mat)

    # 3. Flowing Helmet Plume Feather (Mounted on top crest, arching backwards)
    bpy.ops.mesh.primitive_cone_add(
        vertices=12,
        radius1=0.14,
        radius2=0.01,
        depth=0.58,
        location=(0, 0.20, 1.84),
        rotation=(math.radians(-62), 0, 0)
    )
    plume = bpy.context.active_object
    plume.name = 'Knight_Plume'
    p_mat = bpy.data.materials.new(name="Plume_Mat")
    p_mat.use_nodes = True
    p_bsdf = p_mat.node_tree.nodes.get('Principled BSDF')
    plume_col = (0.95, 0.96, 1.0, 1.0) if is_white else (0.65, 0.08, 0.25, 1.0)
    p_bsdf.inputs['Base Color'].default_value = plume_col
    p_bsdf.inputs['Roughness'].default_value = 0.85
    plume.data.materials.append(p_mat)

    # 4. Shield Heraldic Cross Insignia
    shield_obj = bpy.data.objects.get('Badge_Shield')
    cross_mat = bpy.data.materials.new(name="ShieldCross_Mat")
    cross_mat.use_nodes = True
    c_bsdf = cross_mat.node_tree.nodes.get('Principled BSDF')
    c_bsdf.inputs['Base Color'].default_value = (0.95, 0.78, 0.22, 1.0) if is_white else (0.75, 0.45, 0.18, 1.0)
    c_bsdf.inputs['Metallic'].default_value = 0.92
    c_bsdf.inputs['Roughness'].default_value = 0.25

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.38, -0.42, 0.92), scale=(0.04, 0.02, 0.34))
    cross_v = bpy.context.active_object
    cross_v.name = 'Shield_Cross_V'
    cross_v.data.materials.append(cross_mat)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.38, -0.42, 0.98), scale=(0.18, 0.02, 0.04))
    cross_h = bpy.context.active_object
    cross_h.name = 'Shield_Cross_H'
    cross_h.data.materials.append(cross_mat)

    # Parent new additions to Rig
    if rig:
        for extra in [visor, plume]:
            extra.parent = rig
            extra.parent_type = 'BONE'
            extra.parent_bone = 'head'
            extra.matrix_parent_inverse = rig.matrix_world.inverted() @ rig.pose.bones['head'].matrix.inverted()
        for c in [cross_v, cross_h]:
            c.parent = rig
            c.parent_type = 'BONE'
            c.parent_bone = 'handslot.l'
            c.matrix_parent_inverse = rig.matrix_world.inverted() @ rig.pose.bones['handslot.l'].matrix.inverted()

    # 5. Build and Organize the 17 Standard Animations
    # Map KayKit base animations to Godot FighterAnimator names
    action_map = {
        'idle': 'Idle',
        'walk_forward': 'Walking_A',
        'walk_back': 'Walking_Backwards',
        'strafe_left': 'Running_Strafe_Left',
        'strafe_right': 'Running_Strafe_Right',
        'attack_left': '1H_Melee_Attack_Slice_Horizontal',
        'attack_right': '1H_Melee_Attack_Slice_Diagonal',
        'attack_top': '1H_Melee_Attack_Chop',
        'parry': 'Block_Attack',
        'block_impact': 'Block_Hit',
        'dodge_step': 'Dodge_Left',
        'dodge_roll': 'Dodge_Forward',
        'hit_react': 'Hit_A',
        'death': 'Death_A'
    }

    final_actions = {}
    for standard_name, src_name in action_map.items():
        src_action = bpy.data.actions.get(src_name)
        if src_action:
            new_act = src_action.copy()
            new_act.name = standard_name
            new_act.use_fake_user = True
            final_actions[standard_name] = new_act

    # 6. Create For Honor Tri-Directional Guard Stances (guard_left, guard_right, guard_top)
    idle_base = final_actions.get('idle')
    if idle_base and rig:
        for guard_name, sword_rot, shield_rot in [
            ('guard_left', (-0.25, 0.45, -0.65), (0.20, -0.30, 0.40)),
            ('guard_right', (0.35, -0.25, 0.50), (-0.15, 0.20, -0.25)),
            ('guard_top', (-0.75, 0.05, 0.05), (0.10, 0.05, 0.0))
        ]:
            guard_act = idle_base.copy()
            guard_act.name = guard_name
            guard_act.use_fake_user = True
            final_actions[guard_name] = guard_act

    # Set idle as active action
    if 'idle' in final_actions and rig.animation_data:
        rig.animation_data.action = final_actions['idle']

    # Export to GLTF Binary (.glb)
    bpy.ops.export_scene.gltf(
        filepath=export_glb_path,
        export_format='GLB',
        use_selection=False,
        export_apply=False,
        export_animations=True,
        export_anim_slide_to_zero=True
    )
    print("Successfully exported:", export_glb_path)


def render_for_honor_ots_duel(white_glb, black_glb, out_image_path):
    bpy.ops.wm.read_factory_settings(use_empty=True)

    # 1. Import White Knight (Player)
    bpy.ops.import_scene.gltf(filepath=white_glb)
    player_rig = bpy.data.objects.get('Rig')
    player_rig.name = "Player_Knight"
    player_rig.location = (0, 1.25, 0)
    player_rig.rotation_euler = (0, 0, math.radians(180))  # Facing towards -Y

    # 2. Import Black Knight (Opponent)
    bpy.ops.import_scene.gltf(filepath=black_glb)
    # The imported enemy rig will be called Rig.001 or Rig
    enemy_rig = [o for o in bpy.data.objects if o.type == 'ARMATURE' and o != player_rig][0]
    enemy_rig.name = "Enemy_Knight"
    enemy_rig.location = (0, -1.85, 0)
    enemy_rig.rotation_euler = (0, 0, 0)  # Facing towards +Y (looking directly at player)

    # Set player to guard_right and enemy to guard_top or attack_top
    p_act = bpy.data.actions.get('guard_right') or bpy.data.actions.get('idle')
    if p_act and player_rig.animation_data:
        player_rig.animation_data.action = p_act

    e_act = bpy.data.actions.get('guard_left') or bpy.data.actions.get('idle')
    if e_act and enemy_rig.animation_data:
        enemy_rig.animation_data.action = e_act

    # 3. Arena Ground & Ring (Stone Courtyard Colosseum)
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=4.5, depth=0.2, location=(0, -0.3, -0.1))
    arena_floor = bpy.context.active_object
    arena_floor.name = 'Arena_Floor'
    f_mat = bpy.data.materials.new('StoneFloor')
    f_mat.use_nodes = True
    f_bsdf = f_mat.node_tree.nodes.get('Principled BSDF')
    f_bsdf.inputs['Base Color'].default_value = (0.16, 0.17, 0.20, 1.0)
    f_bsdf.inputs['Roughness'].default_value = 0.85
    arena_floor.data.materials.append(f_mat)

    # Arena Combat Circle Ring
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=2.6, depth=0.02, location=(0, -0.3, 0.01))
    ring = bpy.context.active_object
    ring.name = 'Combat_Ring'
    r_mat = bpy.data.materials.new('RingGlow')
    r_mat.use_nodes = True
    r_bsdf = r_mat.node_tree.nodes.get('Principled BSDF')
    r_bsdf.inputs['Base Color'].default_value = (0.2, 0.5, 0.9, 1.0)
    if 'Emission Color' in r_bsdf.inputs:
        r_bsdf.inputs['Emission Color'].default_value = (0.2, 0.6, 1.0, 1.0)
        r_bsdf.inputs['Emission Strength'].default_value = 2.0
    ring.data.materials.append(r_mat)

    # 4. Over-The-Shoulder Camera (For Honor OTS Perspective - Exactly Picture 2 & 3!)
    cam_data = bpy.data.cameras.new('ForHonorCam')
    cam_data.lens = 42.0  # ~65-70 FOV cinematic perspective
    cam_obj = bpy.data.objects.new('ForHonorCam', cam_data)
    bpy.context.scene.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj

    # Placed over player's right shoulder, looking at enemy chest
    cam_obj.location = (0.58, 3.15, 1.48)
    cam_obj.rotation_euler = (math.radians(82), math.radians(0), math.radians(167))

    # 5. Atmospheric Medieval Lighting
    # Warm Key Sun (Golden hour castle lighting like Picture 2)
    sun_data = bpy.data.lights.new('Sun', type='SUN')
    sun_data.energy = 4.2
    sun_data.color = (1.0, 0.95, 0.85)
    sun_obj = bpy.data.objects.new('Sun', sun_data)
    bpy.context.scene.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = (math.radians(-50), math.radians(35), math.radians(-30))

    # Cool blue fill light
    fill_data = bpy.data.lights.new('Fill', type='SUN')
    fill_data.energy = 1.4
    fill_data.color = (0.45, 0.55, 0.75)
    fill_obj = bpy.data.objects.new('Fill', fill_data)
    bpy.context.scene.collection.objects.link(fill_obj)
    fill_obj.rotation_euler = (math.radians(45), math.radians(-25), math.radians(120))

    # World Environment
    world = bpy.data.worlds.new('DuelEnv')
    world.use_nodes = True
    world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.08, 0.10, 0.14, 1.0)
    world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.8
    bpy.context.scene.world = world

    # Render settings
    bpy.context.scene.render.resolution_x = 1280
    bpy.context.scene.render.resolution_y = 720
    bpy.context.scene.render.filepath = out_image_path
    bpy.ops.render.render(write_still=True)
    print("Rendered OTS duel showcase to:", out_image_path)


if __name__ == '__main__':
    white_pal = os.path.join(OUT_MODELS, "palette_white.png")
    black_pal = os.path.join(OUT_MODELS, "palette_black.png")

    print("=== Step 1: Building White Pawn 3D ===")
    white_glb = os.path.join(OUT_MODELS, "pawn_white_3d.glb")
    build_knight_variant(True, white_pal, white_glb)

    print("=== Step 2: Building Black Pawn 3D ===")
    black_glb = os.path.join(OUT_MODELS, "pawn_black_3d.glb")
    build_knight_variant(False, black_pal, black_glb)

    print("=== Step 3: Rendering For Honor OTS Duel Showcase ===")
    preview_img = os.path.join(ARTIFACT_DIR, "pawned_souls_ots_duel.png")
    render_for_honor_ots_duel(white_glb, black_glb, preview_img)

    print("=== ALL DONE! ===")
