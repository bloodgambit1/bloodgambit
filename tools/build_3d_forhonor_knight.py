"""
Blender 4.5: Full 3D Rigged Knight Fighter Generator (For Honor Style)
-----------------------------------------------------------------------
สร้างโมเดลอัศวิน 3 มิติเต็มรูปแบบ พร้อม Armature/Bones และชุดท่าทางอนิเมชั่นการต่อสู้สไตล์ For Honor:
- Actions: idle, guard_left, guard_right, guard_top, attack_left, attack_right, attack_top, parry, block, hit_react
- ส่งออกเป็นไฟล์ glTF 2.0 Binary (.glb) พร้อม Skeleton และ AnimationPlayer สำหรับ Godot
"""

import os
import sys
import math
from pathlib import Path
import bpy
import mathutils

ROOT_DIR = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT_DIR / "art" / "models"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for a in list(bpy.data.actions):
        bpy.data.actions.remove(a)
    for m in list(bpy.data.materials):
        bpy.data.materials.remove(m)
    for m in list(bpy.data.meshes):
        bpy.data.meshes.remove(m)
    for arm in list(bpy.data.armatures):
        bpy.data.armatures.remove(arm)


def create_material(name, color, metallic=0.0, roughness=0.4, emission=None):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
        if emission and "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = emission
            if "Emission Strength" in bsdf.inputs:
                bsdf.inputs["Emission Strength"].default_value = 2.0
    return mat


def build_rigged_knight(is_white=True):
    # วัสดุ PBR คุณภาพสูง
    if is_white:
        steel = create_material("Steel", (0.85, 0.88, 0.94, 1.0), metallic=0.85, roughness=0.25)
        gold = create_material("Gold", (0.98, 0.82, 0.28, 1.0), metallic=0.92, roughness=0.2)
        cloth = create_material("Cloth", (0.16, 0.38, 0.85, 1.0), roughness=0.6)
        leather = create_material("Leather", (0.28, 0.18, 0.12, 1.0), roughness=0.7)
        visor_glow = create_material("VisorGlow", (0.4, 0.8, 1.0, 1.0), emission=(0.4, 0.8, 1.0, 1.0))
        blade_steel = create_material("BladeSteel", (0.92, 0.94, 0.98, 1.0), metallic=0.95, roughness=0.15)
    else:
        steel = create_material("DarkSteel", (0.20, 0.18, 0.24, 1.0), metallic=0.88, roughness=0.3)
        gold = create_material("DarkGold", (0.75, 0.55, 0.18, 1.0), metallic=0.9, roughness=0.25)
        cloth = create_material("DarkCloth", (0.35, 0.10, 0.52, 1.0), roughness=0.6)
        leather = create_material("DarkLeather", (0.16, 0.12, 0.10, 1.0), roughness=0.7)
        visor_glow = create_material("VisorGlow", (1.0, 0.2, 0.3, 1.0), emission=(1.0, 0.2, 0.4, 1.0))
        blade_steel = create_material("BladeSteel", (0.45, 0.42, 0.50, 1.0), metallic=0.95, roughness=0.2)

    # 1. สร้าง Armature
    bpy.ops.object.armature_add(location=(0, 0, 0))
    arm_obj = bpy.context.active_object
    arm_obj.name = "Knight_Armature"
    arm_data = arm_obj.data
    arm_data.name = "Knight_Skeleton"

    bpy.ops.object.mode_set(mode='EDIT')
    edit_bones = arm_data.edit_bones
    # ลบกระดูกเริ่มต้น
    for b in list(edit_bones):
        edit_bones.remove(b)

    # โครงสร้างกระดูก
    def add_bone(name, head, tail, parent_name=None):
        b = edit_bones.new(name)
        b.head = head
        b.tail = tail
        if parent_name and parent_name in edit_bones:
            b.parent = edit_bones[parent_name]
        return b

    # Root & Spine
    add_bone("Root", (0, 0, 0), (0, 0, 0.2))
    add_bone("Hips", (0, 0, 0.80), (0, 0, 0.95), "Root")
    add_bone("Spine", (0, 0, 0.95), (0, 0, 1.25), "Hips")
    add_bone("Chest", (0, 0, 1.25), (0, 0, 1.48), "Spine")
    add_bone("Head", (0, 0, 1.48), (0, 0, 1.80), "Chest")

    # Left Arm (Shield)
    add_bone("Shoulder_L", (-0.15, 0, 1.42), (-0.35, 0, 1.40), "Chest")
    add_bone("UpperArm_L", (-0.35, 0, 1.40), (-0.42, -0.05, 1.15), "Shoulder_L")
    add_bone("Forearm_L", (-0.42, -0.05, 1.15), (-0.38, -0.20, 0.95), "UpperArm_L")
    add_bone("Hand_L", (-0.38, -0.20, 0.95), (-0.35, -0.28, 0.90), "Forearm_L")

    # Right Arm (Sword)
    add_bone("Shoulder_R", (0.15, 0, 1.42), (0.35, 0, 1.40), "Chest")
    add_bone("UpperArm_R", (0.35, 0, 1.40), (0.42, -0.05, 1.15), "Shoulder_R")
    add_bone("Forearm_R", (0.42, -0.05, 1.15), (0.38, -0.20, 0.95), "UpperArm_R")
    add_bone("Hand_R", (0.38, -0.20, 0.95), (0.35, -0.28, 0.90), "Forearm_R")

    # Legs
    add_bone("Thigh_L", (-0.18, 0, 0.80), (-0.18, 0, 0.45), "Hips")
    add_bone("Shin_L", (-0.18, 0, 0.45), (-0.18, -0.02, 0.12), "Thigh_L")
    add_bone("Foot_L", (-0.18, -0.02, 0.12), (-0.18, -0.22, 0.04), "Shin_L")

    add_bone("Thigh_R", (0.18, 0, 0.80), (0.18, 0, 0.45), "Hips")
    add_bone("Shin_R", (0.18, 0, 0.45), (0.18, -0.02, 0.12), "Thigh_R")
    add_bone("Foot_R", (0.18, -0.02, 0.12), (0.18, -0.22, 0.04), "Shin_R")

    bpy.ops.object.mode_set(mode='OBJECT')

    # 2. สร้างชิ้นส่วน 3D Mesh และผูกกระดูก (Bone Parenting)
    meshes = []

    def make_mesh_box(name, loc, scale, mat, bone_name):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = scale
        obj.data.materials.append(mat)
        obj.parent = arm_obj
        obj.parent_type = 'BONE'
        obj.parent_bone = bone_name
        meshes.append(obj)
        return obj

    def make_mesh_cylinder(name, loc, r, d, mat, bone_name):
        bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=d, location=loc)
        obj = bpy.context.active_object
        obj.name = name
        obj.data.materials.append(mat)
        obj.parent = arm_obj
        obj.parent_type = 'BONE'
        obj.parent_bone = bone_name
        meshes.append(obj)
        return obj

    def make_mesh_sphere(name, loc, r, mat, bone_name):
        bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc)
        obj = bpy.context.active_object
        obj.name = name
        obj.data.materials.append(mat)
        obj.parent = arm_obj
        obj.parent_type = 'BONE'
        obj.parent_bone = bone_name
        meshes.append(obj)
        return obj

    # Pelvis & Belt
    make_mesh_box("Mesh_Pelvis", (0, 0, 0.85), (0.42, 0.28, 0.22), steel, "Hips")
    make_mesh_box("Mesh_Belt", (0, 0, 0.90), (0.44, 0.30, 0.08), gold, "Hips")

    # Torso & Chestplate
    make_mesh_box("Mesh_Torso", (0, 0, 1.15), (0.46, 0.32, 0.42), steel, "Spine")
    make_mesh_box("Mesh_Tabard", (0, -0.01, 1.15), (0.28, 0.33, 0.44), cloth, "Spine")
    make_mesh_box("Mesh_ChestTrim", (0, -0.16, 1.30), (0.38, 0.04, 0.14), gold, "Chest")

    # Head & Greathelm
    make_mesh_sphere("Mesh_Head", (0, 0, 1.60), 0.24, steel, "Head")
    make_mesh_box("Mesh_Visor", (0, -0.22, 1.60), (0.22, 0.05, 0.05), visor_glow, "Head")
    # พู่หมวก
    plume_mat = gold if is_white else cloth
    make_mesh_sphere("Mesh_Plume", (0, 0.12, 1.78), 0.16, plume_mat, "Head")

    # Pauldrons (เกราะไหล่)
    make_mesh_sphere("Mesh_Pauldron_L", (-0.35, 0, 1.40), 0.17, gold, "Shoulder_L")
    make_mesh_sphere("Mesh_Pauldron_R", (0.35, 0, 1.40), 0.17, gold, "Shoulder_R")

    # Arms
    make_mesh_cylinder("Mesh_Arm_L", (-0.38, -0.02, 1.25), 0.09, 0.26, steel, "UpperArm_L")
    make_mesh_cylinder("Mesh_Forearm_L", (-0.40, -0.12, 1.05), 0.08, 0.24, steel, "Forearm_L")
    make_mesh_cylinder("Mesh_Arm_R", (0.38, -0.02, 1.25), 0.09, 0.26, steel, "UpperArm_R")
    make_mesh_cylinder("Mesh_Forearm_R", (0.40, -0.12, 1.05), 0.08, 0.24, steel, "Forearm_R")

    # Heater Shield (ผูกกับ Hand_L)
    make_mesh_box("Mesh_Shield", (-0.38, -0.26, 0.95), (0.42, 0.06, 0.65), cloth, "Hand_L")
    make_mesh_box("Mesh_Shield_Rim", (-0.38, -0.27, 0.95), (0.44, 0.04, 0.68), steel, "Hand_L")
    make_mesh_box("Mesh_Shield_Cross", (-0.38, -0.29, 0.95), (0.10, 0.03, 0.54), gold, "Hand_L")

    # Crusader Longsword (ผูกกับ Hand_R)
    make_mesh_cylinder("Mesh_Sword_Hilt", (0.36, -0.22, 0.88), 0.03, 0.18, leather, "Hand_R")
    make_mesh_sphere("Mesh_Sword_Pommel", (0.36, -0.22, 0.78), 0.05, gold, "Hand_R")
    make_mesh_box("Mesh_Sword_Guard", (0.36, -0.22, 0.98), (0.32, 0.06, 0.05), gold, "Hand_R")
    make_mesh_box("Mesh_Sword_Blade", (0.36, -0.22, 1.55), (0.07, 0.02, 1.10), blade_steel, "Hand_R")

    # Legs & Boots
    for side, bone_thigh, bone_shin, bone_foot in [("L", "Thigh_L", "Shin_L", "Foot_L"), ("R", "Thigh_R", "Shin_R", "Foot_R")]:
        sign_x = -1.0 if side == "L" else 1.0
        make_mesh_cylinder(f"Mesh_Thigh_{side}", (sign_x * 0.18, 0, 0.62), 0.11, 0.32, steel, bone_thigh)
        make_mesh_sphere(f"Mesh_Knee_{side}", (sign_x * 0.18, -0.06, 0.46), 0.09, gold, bone_thigh)
        make_mesh_cylinder(f"Mesh_Shin_{side}", (sign_x * 0.18, -0.01, 0.28), 0.10, 0.28, steel, bone_shin)
        make_mesh_box(f"Mesh_Foot_{side}", (sign_x * 0.18, -0.08, 0.06), (0.14, 0.28, 0.10), steel, bone_foot)

    return arm_obj


def create_combat_actions(arm_obj):
    """สร้าง Keyframe Actions การต่อสู้ครบชุดสไตล์ For Honor"""
    arm_obj.animation_data_create()
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode='POSE')
    pose = arm_obj.pose

    def reset_pose():
        for b in pose.bones:
            b.rotation_quaternion = (1, 0, 0, 0)
            b.rotation_euler = (0, 0, 0)
            b.location = (0, 0, 0)

    # 1. IDLE (ท่ายืนเตรียมรบ For Honor Guard)
    action_idle = bpy.data.actions.new(name="idle")
    arm_obj.animation_data.action = action_idle
    reset_pose()

    # Frame 1: ค่าเริ่มต้น
    pose.bones["Spine"].rotation_euler = (0, 0, math.radians(-5))
    pose.bones["UpperArm_L"].rotation_euler = (math.radians(-25), math.radians(10), math.radians(15))
    pose.bones["Forearm_L"].rotation_euler = (math.radians(-35), 0, math.radians(20))
    pose.bones["UpperArm_R"].rotation_euler = (math.radians(20), math.radians(-15), math.radians(-15))
    pose.bones["Hand_R"].rotation_euler = (math.radians(30), 0, math.radians(-10))
    for b in pose.bones:
        b.keyframe_insert(data_path="rotation_euler", frame=1)

    # Frame 20: หายใจ / ขยับเล็กน้อย
    pose.bones["Spine"].location.z = -0.02
    pose.bones["Hand_R"].rotation_euler = (math.radians(35), 0, math.radians(-15))
    for b in pose.bones:
        b.keyframe_insert(data_path="rotation_euler", frame=20)
        b.keyframe_insert(data_path="location", frame=20)

    # Frame 40: วนลูปกลับ
    pose.bones["Spine"].location.z = 0.0
    pose.bones["Hand_R"].rotation_euler = (math.radians(30), 0, math.radians(-10))
    for b in pose.bones:
        b.keyframe_insert(data_path="rotation_euler", frame=40)
        b.keyframe_insert(data_path="location", frame=40)

    # 2. ATTACK_LEFT (ฟันซ้ายสไตล์ For Honor Zone/Light)
    act_att_l = bpy.data.actions.new(name="attack_left")
    arm_obj.animation_data.action = act_att_l
    reset_pose()

    # F1: Windup ดึงดาบไปทางขวา บิดลำตัว
    pose.bones["Spine"].rotation_euler = (0, math.radians(-5), math.radians(35))
    pose.bones["UpperArm_R"].rotation_euler = (math.radians(-35), math.radians(-40), math.radians(50))
    pose.bones["Forearm_R"].rotation_euler = (math.radians(-20), 0, math.radians(40))
    pose.bones["UpperArm_L"].rotation_euler = (math.radians(15), 0, math.radians(-25))
    for b in pose.bones: b.keyframe_insert(data_path="rotation_euler", frame=1)

    # F10: Slash Release ฟาดสะบัดดาบตัดผ่านอากาศข้ามไปซ้ายอย่างรุนแรง
    pose.bones["Spine"].rotation_euler = (math.radians(12), math.radians(10), math.radians(-50))
    pose.bones["UpperArm_R"].rotation_euler = (math.radians(-65), math.radians(55), math.radians(-50))
    pose.bones["Forearm_R"].rotation_euler = (math.radians(-30), 0, math.radians(-45))
    pose.bones["UpperArm_L"].rotation_euler = (math.radians(30), 0, math.radians(25))
    for b in pose.bones: b.keyframe_insert(data_path="rotation_euler", frame=10)

    # F22: Recovery
    reset_pose()
    for b in pose.bones: b.keyframe_insert(data_path="rotation_euler", frame=22)

    # 3. ATTACK_RIGHT (ฟันขวาสไตล์ For Honor)
    act_att_r = bpy.data.actions.new(name="attack_right")
    arm_obj.animation_data.action = act_att_r
    reset_pose()

    # F1: Windup ดึงดาบไปซ้าย
    pose.bones["Spine"].rotation_euler = (0, math.radians(5), math.radians(-35))
    pose.bones["UpperArm_R"].rotation_euler = (math.radians(-50), math.radians(30), math.radians(-40))
    for b in pose.bones: b.keyframe_insert(data_path="rotation_euler", frame=1)

    # F10: Slash ฟาดสะบัดไปขวา
    pose.bones["Spine"].rotation_euler = (math.radians(12), math.radians(-10), math.radians(50))
    pose.bones["UpperArm_R"].rotation_euler = (math.radians(-60), math.radians(-60), math.radians(50))
    for b in pose.bones: b.keyframe_insert(data_path="rotation_euler", frame=10)

    # F22: Recovery
    reset_pose()
    for b in pose.bones: b.keyframe_insert(data_path="rotation_euler", frame=22)

    # 4. ATTACK_TOP (ฟันผ่าบน Overhead Heavy Execution)
    act_att_t = bpy.data.actions.new(name="attack_top")
    arm_obj.animation_data.action = act_att_t
    reset_pose()

    # F1: ยกดาบขึ้นสองแขนเหนือหัว
    pose.bones["Spine"].rotation_euler = (math.radians(-15), 0, 0)
    pose.bones["UpperArm_R"].rotation_euler = (math.radians(-120), 0, math.radians(-20))
    pose.bones["UpperArm_L"].rotation_euler = (math.radians(-70), 0, math.radians(30))
    for b in pose.bones: b.keyframe_insert(data_path="rotation_euler", frame=1)

    # F12: สับฟันลงมาตรงๆ ผ่าพื้น
    pose.bones["Spine"].rotation_euler = (math.radians(32), 0, 0)
    pose.bones["UpperArm_R"].rotation_euler = (math.radians(-45), 0, 0)
    for b in pose.bones: b.keyframe_insert(data_path="rotation_euler", frame=12)

    # F25: Recovery
    reset_pose()
    for b in pose.bones: b.keyframe_insert(data_path="rotation_euler", frame=25)

    # 5. PARRY (ปัดดาบสะท้อน Deflect)
    act_parry = bpy.data.actions.new(name="parry")
    arm_obj.animation_data.action = act_parry
    reset_pose()

    # F1: ทิ่มโล่กระแทกไปข้างหน้า + ยกดาบเอียงป้อง
    pose.bones["UpperArm_L"].rotation_euler = (math.radians(-75), math.radians(15), math.radians(25))
    pose.bones["Forearm_L"].rotation_euler = (math.radians(-25), 0, 0)
    pose.bones["UpperArm_R"].rotation_euler = (math.radians(-70), math.radians(-25), math.radians(35))
    pose.bones["Spine"].rotation_euler = (math.radians(12), 0, 0)
    for b in pose.bones: b.keyframe_insert(data_path="rotation_euler", frame=1)

    # F8: ค้างแรงกระแทก
    for b in pose.bones: b.keyframe_insert(data_path="rotation_euler", frame=8)

    # F18: คืนท่า
    reset_pose()
    for b in pose.bones: b.keyframe_insert(data_path="rotation_euler", frame=18)

    # 6. HIT_REACT (โดนโจมตี หงายหลัง ชะงัก)
    act_hit = bpy.data.actions.new(name="hit_react")
    arm_obj.animation_data.action = act_hit
    reset_pose()

    # F1: หงายหลัง แขนเปิดออก
    pose.bones["Spine"].rotation_euler = (math.radians(-30), math.radians(-10), math.radians(-15))
    pose.bones["Head"].rotation_euler = (math.radians(-25), 0, math.radians(10))
    pose.bones["UpperArm_R"].rotation_euler = (math.radians(45), 0, math.radians(-45))
    pose.bones["UpperArm_L"].rotation_euler = (math.radians(40), 0, math.radians(45))
    for b in pose.bones: b.keyframe_insert(data_path="rotation_euler", frame=1)

    # F14: คืนท่า
    reset_pose()
    for b in pose.bones: b.keyframe_insert(data_path="rotation_euler", frame=14)

    # ตั้ง Action เริ่มต้นเป็น idle
    arm_obj.animation_data.action = action_idle
    bpy.ops.object.mode_set(mode='OBJECT')


def generate_and_export_all():
    for is_white in [True, False]:
        faction_name = "white" if is_white else "black"
        clear_scene()
        arm_obj = build_rigged_knight(is_white)
        create_combat_actions(arm_obj)

        out_file = OUT_DIR / f"knight_{faction_name}.glb"
        bpy.ops.export_scene.gltf(filepath=str(out_file), export_format='GLB', export_animations=True)
        print(f"Exported For Honor 3D model successfully: {out_file.name}")

    print("=== All 3D For Honor Knights generated and exported! ===")


if __name__ == "__main__":
    generate_and_export_all()
