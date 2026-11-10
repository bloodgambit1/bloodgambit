"""
Blender 4.5 Automation: Rigged Knight Combat Poses & Sprite Generator
---------------------------------------------------------------------
สร้างโมเดลอัศวิน 3D ละเอียดสวยงาม พร้อม Rigging ท่าทางการต่อสู้ครบชุด:
- idle, windup_left, attack_left, windup_right, attack_right, windup_top, attack_top, parry, hit_react
- เรนเดอร์ 2 มุมมองหลัก:
    1. Player View (Back view - หันหลังให้กล้อง หันหน้าเข้าหาคู่ต่อสู้ มองเห็นดาบขวา โล่ซ้าย พู่หมวก)
    2. Enemy View (Front view - หันหน้าเข้าหากล้อง มองเห็นเกราะหน้า กะบังหมวก ดาบและโล่)
- จัดกึ่งกลางพอดีเป๊ะ รองเท้าวางชิดระนาบพื้นเท่ากันทั้งมุมหน้าและมุมหลัง
"""

import os
import sys
import math
from pathlib import Path
import bpy
import mathutils

ROOT_DIR = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT_DIR / "art" / "sprites" / "animated_knight"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for m in list(bpy.data.materials):
        bpy.data.materials.remove(m)
    for m in list(bpy.data.meshes):
        bpy.data.meshes.remove(m)
    for c in list(bpy.data.cameras):
        bpy.data.cameras.remove(c)
    for l in list(bpy.data.lights):
        bpy.data.lights.remove(l)


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
                bsdf.inputs["Emission Strength"].default_value = 1.5
    return mat


def add_part(mesh_fn, name, world_loc, scale=(1, 1, 1), mat=None, parent=None, rot_euler=(0, 0, 0), **kwargs):
    """สร้างชิ้นส่วนและผูก Parent อย่างถูกต้องโดยคงตำแหน่ง World Coordinates ไว้"""
    mesh_fn(location=world_loc, **kwargs)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    obj.rotation_euler = rot_euler
    if mat:
        obj.data.materials.append(mat)
    if parent:
        obj.parent = parent
        obj.matrix_parent_inverse = parent.matrix_world.inverted()
    return obj


def build_knight(is_white=True):
    """สร้างโมเดลอัศวินสไตล์ Fantasy Low-Poly / Pixel Art พร้อมข้อต่อ Hierarchical Rig"""
    if is_white:
        steel = create_material("Steel", (0.85, 0.88, 0.94, 1.0), metallic=0.85, roughness=0.25)
        dark_metal = create_material("DarkMetal", (0.35, 0.38, 0.45, 1.0), metallic=0.7, roughness=0.4)
        gold = create_material("Gold", (0.98, 0.82, 0.28, 1.0), metallic=0.9, roughness=0.2)
        cloth = create_material("Cloth", (0.18, 0.42, 0.88, 1.0), roughness=0.6)
        plume = create_material("Plume", (0.95, 0.96, 1.0, 1.0), roughness=0.7)
        visor_glow = create_material("Visor", (0.2, 0.6, 1.0, 1.0), emission=(0.4, 0.8, 1.0, 1.0))
    else:
        steel = create_material("DarkSteel", (0.22, 0.20, 0.28, 1.0), metallic=0.85, roughness=0.3)
        dark_metal = create_material("Obsidian", (0.12, 0.10, 0.16, 1.0), metallic=0.9, roughness=0.3)
        gold = create_material("DarkGold", (0.75, 0.55, 0.18, 1.0), metallic=0.9, roughness=0.25)
        cloth = create_material("DarkCloth", (0.40, 0.12, 0.55, 1.0), roughness=0.6)
        plume = create_material("DarkPlume", (0.68, 0.20, 0.92, 1.0), roughness=0.7)
        visor_glow = create_material("Visor", (0.9, 0.2, 0.4, 1.0), emission=(1.0, 0.2, 0.5, 1.0))

    # 1. Root
    root = bpy.data.objects.new("Knight_Root", None)
    bpy.context.scene.collection.objects.link(root)
    root.location = (0, 0, 0)

    # 2. Pelvis / สะโพก
    pelvis = add_part(bpy.ops.mesh.primitive_cube_add, "Pelvis", (0, 0, 0.82), (0.42, 0.28, 0.22), steel, root, size=1.0)
    # เข็มขัดทอง
    add_part(bpy.ops.mesh.primitive_cube_add, "Belt", (0, 0, 0.89), (0.44, 0.30, 0.08), gold, pelvis, size=1.0)

    # 3. Torso / ลำตัวและเกราะอก
    torso = add_part(bpy.ops.mesh.primitive_cube_add, "Torso", (0, 0, 1.15), (0.46, 0.32, 0.44), steel, pelvis, size=1.0)
    # ผ้าคาดอก / แถบสี
    add_part(bpy.ops.mesh.primitive_cube_add, "Tabard", (0, -0.01, 1.15), (0.26, 0.33, 0.46), cloth, torso, size=1.0)
    # ขลิบทองเกราะอก
    add_part(bpy.ops.mesh.primitive_cube_add, "ChestTrim", (0, -0.16, 1.22), (0.36, 0.04, 0.12), gold, torso, size=1.0)

    # 4. Head & Helmet / หัวและหมวกเกราะ
    head = add_part(bpy.ops.mesh.primitive_uv_sphere_add, "Head", (0, 0, 1.55), (0.24, 0.25, 0.26), steel, torso, radius=1.0)
    # กะบังหมวก (Visor slit) ด้านหน้า
    add_part(bpy.ops.mesh.primitive_cube_add, "Visor", (0, -0.22, 1.55), (0.24, 0.06, 0.05), visor_glow, head, size=1.0)
    # ยอดหมวกทรงกรวย
    add_part(bpy.ops.mesh.primitive_cone_add, "HelmTop", (0, 0, 1.76), (0.20, 0.20, 0.22), steel, head, radius1=1.0, depth=1.0)
    # พู่ขนนก (Plume) พลิ้วไปด้านหลัง
    plume_obj = add_part(bpy.ops.mesh.primitive_uv_sphere_add, "Plume", (0, 0.14, 1.88), (0.12, 0.28, 0.16), plume, head, radius=1.0,
                         rot_euler=(math.radians(-25), 0, 0))

    # 5. Right Arm & Sword / แขนขวาและดาบ
    shoulder_r = bpy.data.objects.new("Shoulder_R", None)
    bpy.context.scene.collection.objects.link(shoulder_r)
    shoulder_r.location = (0.34, 0, 1.30)
    shoulder_r.parent = torso
    shoulder_r.matrix_parent_inverse = torso.matrix_world.inverted()

    # สนับไหล่ขวา (Pauldron)
    add_part(bpy.ops.mesh.primitive_uv_sphere_add, "Pauldron_R", (0.35, 0, 1.33), (0.16, 0.18, 0.15), gold, shoulder_r, radius=1.0)
    # ท่อนแขนขวา
    arm_r = add_part(bpy.ops.mesh.primitive_cylinder_add, "Arm_R", (0.35, 0, 1.10), (0.09, 0.09, 0.28), steel, shoulder_r, radius=1.0, depth=1.0)

    # มือขวา (Hand_R)
    hand_r = bpy.data.objects.new("Hand_R", None)
    bpy.context.scene.collection.objects.link(hand_r)
    hand_r.location = (0.35, -0.05, 0.94)
    hand_r.parent = arm_r
    hand_r.matrix_parent_inverse = arm_r.matrix_world.inverted()

    # โกร่งดาบ (Crossguard)
    add_part(bpy.ops.mesh.primitive_cube_add, "Sword_Guard", (0.35, -0.05, 0.96), (0.28, 0.06, 0.05), gold, hand_r, size=1.0)
    # ด้ามดาบ (Hilt)
    add_part(bpy.ops.mesh.primitive_cylinder_add, "Sword_Hilt", (0.35, -0.05, 0.88), (0.03, 0.03, 0.14), dark_metal, hand_r, radius=1.0, depth=1.0)
    # ลูกตุ้มดาบ (Pommel)
    add_part(bpy.ops.mesh.primitive_uv_sphere_add, "Sword_Pommel", (0.35, -0.05, 0.80), (0.05, 0.05, 0.05), gold, hand_r, radius=1.0)
    # ใบดาบ (Blade) ยาวคมเงาวับ
    blade = add_part(bpy.ops.mesh.primitive_cube_add, "Sword_Blade", (0.35, -0.05, 1.48), (0.08, 0.02, 0.98), steel, hand_r, size=1.0)

    # 6. Left Arm & Shield / แขนซ้ายและโล่
    shoulder_l = bpy.data.objects.new("Shoulder_L", None)
    bpy.context.scene.collection.objects.link(shoulder_l)
    shoulder_l.location = (-0.34, 0, 1.30)
    shoulder_l.parent = torso
    shoulder_l.matrix_parent_inverse = torso.matrix_world.inverted()

    # สนับไหล่ซ้าย
    add_part(bpy.ops.mesh.primitive_uv_sphere_add, "Pauldron_L", (-0.35, 0, 1.33), (0.16, 0.18, 0.15), gold, shoulder_l, radius=1.0)
    # ท่อนแขนซ้าย
    arm_l = add_part(bpy.ops.mesh.primitive_cylinder_add, "Arm_L", (-0.35, 0, 1.10), (0.09, 0.09, 0.28), steel, shoulder_l, radius=1.0, depth=1.0)

    # โล่ฮีตเตอร์ (Shield)
    shield_anchor = bpy.data.objects.new("Shield_Anchor", None)
    bpy.context.scene.collection.objects.link(shield_anchor)
    shield_anchor.location = (-0.36, -0.12, 1.08)
    shield_anchor.parent = arm_l
    shield_anchor.matrix_parent_inverse = arm_l.matrix_world.inverted()

    # ตัวโล่หลัก
    shield = add_part(bpy.ops.mesh.primitive_cube_add, "Shield_Body", (-0.36, -0.15, 1.08), (0.38, 0.06, 0.62), cloth, shield_anchor, size=1.0)
    # ขอบโล่เหล็ก
    add_part(bpy.ops.mesh.primitive_cube_add, "Shield_Rim", (-0.36, -0.16, 1.08), (0.40, 0.04, 0.64), steel, shield_body if 'shield_body' in locals() else shield, size=1.0)
    # กางเขนทองบนโล่ (Holy/Arcane Cross)
    add_part(bpy.ops.mesh.primitive_cube_add, "Shield_Cross_V", (-0.36, -0.18, 1.08), (0.08, 0.03, 0.52), gold, shield, size=1.0)
    add_part(bpy.ops.mesh.primitive_cube_add, "Shield_Cross_H", (-0.36, -0.18, 1.16), (0.28, 0.03, 0.08), gold, shield, size=1.0)

    # 7. Legs & Feet / ขาและเกราะเท้า (ยืนบนระนาบ Z = 0)
    for side_name, x in [("Leg_L", -0.18), ("Leg_R", 0.18)]:
        # ต้นขา
        add_part(bpy.ops.mesh.primitive_cylinder_add, f"{side_name}_Thigh", (x, 0, 0.62), (0.11, 0.11, 0.32), steel, pelvis, radius=1.0, depth=1.0)
        # สนับเข่า
        add_part(bpy.ops.mesh.primitive_uv_sphere_add, f"{side_name}_Knee", (x, -0.06, 0.46), (0.09, 0.09, 0.09), gold, pelvis, radius=1.0)
        # น่องขา
        add_part(bpy.ops.mesh.primitive_cylinder_add, f"{side_name}_Shin", (x, 0, 0.28), (0.10, 0.10, 0.28), steel, pelvis, radius=1.0, depth=1.0)
        # เกราะเท้า (Sabaton) วางติดพื้น Z = 0.05
        add_part(bpy.ops.mesh.primitive_cube_add, f"{side_name}_Foot", (x, -0.06, 0.06), (0.13, 0.26, 0.10), steel, pelvis, size=1.0)

    return {
        "root": root,
        "pelvis": pelvis,
        "torso": torso,
        "head": head,
        "shoulder_r": shoulder_r,
        "arm_r": arm_r,
        "hand_r": hand_r,
        "shoulder_l": shoulder_l,
        "arm_l": arm_l,
        "shield": shield_anchor,
    }


def apply_pose(rig, pose_name):
    """กำหนดองศาท่าทางต่อสู้ให้อัศวินชัดเจนทุกมิติ"""
    torso = rig["torso"]
    head = rig["head"]
    shoulder_r = rig["shoulder_r"]
    arm_r = rig["arm_r"]
    hand_r = rig["hand_r"]
    shoulder_l = rig["shoulder_l"]
    arm_l = rig["arm_l"]
    shield = rig["shield"]

    # รีเซ็ตเป็นค่าศูนย์
    for obj in [torso, head, shoulder_r, arm_r, hand_r, shoulder_l, arm_l, shield]:
        obj.rotation_euler = (0, 0, 0)
        obj.location = obj.location  # คงเดิม

    if pose_name == "idle":
        # ท่ายืนต่อสู้: หันลำตัวเฉียงเล็กน้อย ยกโล่ป้องอก ดาบตั้งชี้ขึ้น
        torso.rotation_euler = (0, 0, math.radians(-10))
        shoulder_l.rotation_euler = (math.radians(-30), math.radians(10), math.radians(20))
        arm_l.rotation_euler = (math.radians(-20), 0, math.radians(10))
        shield.rotation_euler = (math.radians(15), 0, math.radians(-10))
        shoulder_r.rotation_euler = (math.radians(20), math.radians(-15), math.radians(-15))
        arm_r.rotation_euler = (math.radians(25), 0, math.radians(-15))
        hand_r.rotation_euler = (math.radians(45), 0, math.radians(-10))

    elif pose_name == "windup_left":
        # ง้างฟันซ้าย: บิดลำตัวไปทางขวา ดึงดาบขึ้นขวา โล่เปิดออกเล็กน้อย
        torso.rotation_euler = (0, math.radians(-5), math.radians(35))
        shoulder_r.rotation_euler = (math.radians(-35), math.radians(-40), math.radians(50))
        arm_r.rotation_euler = (math.radians(-20), 0, math.radians(40))
        hand_r.rotation_euler = (math.radians(60), math.radians(30), 0)
        shoulder_l.rotation_euler = (math.radians(20), 0, math.radians(-30))

    elif pose_name == "attack_left":
        # ฟันซ้าย (Slash Left): ตวัดดาบเฉือนจากขวาไปซ้าย ลำตัวบิดตามแรงเหวี่ยง
        torso.rotation_euler = (math.radians(12), math.radians(10), math.radians(-45))
        shoulder_r.rotation_euler = (math.radians(-65), math.radians(55), math.radians(-50))
        arm_r.rotation_euler = (math.radians(-30), 0, math.radians(-40))
        hand_r.rotation_euler = (math.radians(-20), math.radians(-45), 0)
        shoulder_l.rotation_euler = (math.radians(30), 0, math.radians(25))

    elif pose_name == "windup_right":
        # ง้างฟันขวา: ดึงดาบไปทางซ้าย บิดตัวไปซ้าย
        torso.rotation_euler = (0, math.radians(5), math.radians(-35))
        shoulder_r.rotation_euler = (math.radians(-50), math.radians(30), math.radians(-40))
        arm_r.rotation_euler = (math.radians(-25), 0, math.radians(-35))
        hand_r.rotation_euler = (math.radians(50), math.radians(-20), 0)
        shoulder_l.rotation_euler = (math.radians(-20), 0, math.radians(25))

    elif pose_name == "attack_right":
        # ฟันขวา (Slash Right): ตวัดดาบเฉือนจากซ้ายไปขวา
        torso.rotation_euler = (math.radians(12), math.radians(-10), math.radians(45))
        shoulder_r.rotation_euler = (math.radians(-60), math.radians(-60), math.radians(45))
        arm_r.rotation_euler = (math.radians(-35), 0, math.radians(40))
        hand_r.rotation_euler = (math.radians(-20), math.radians(45), 0)
        shoulder_l.rotation_euler = (math.radians(-35), 0, math.radians(-20))

    elif pose_name == "windup_top":
        # ง้างฟันบน (Overhead Windup): ยกดาบขึ้นสองแขนเหนือหัว
        torso.rotation_euler = (math.radians(-12), 0, 0)
        shoulder_r.rotation_euler = (math.radians(-110), 0, math.radians(-25))
        arm_r.rotation_euler = (math.radians(-40), 0, 0)
        hand_r.rotation_euler = (math.radians(80), 0, 0)
        shoulder_l.rotation_euler = (math.radians(-60), 0, math.radians(30))

    elif pose_name == "attack_top":
        # ฟันผ่าลงมาตรงๆ (Overhead Slam): ฟาดดาบลงมาข้างหน้าอย่างรุนแรง
        torso.rotation_euler = (math.radians(28), 0, 0)
        shoulder_r.rotation_euler = (math.radians(-45), 0, math.radians(-10))
        arm_r.rotation_euler = (math.radians(-20), 0, 0)
        hand_r.rotation_euler = (math.radians(-45), 0, 0)
        shoulder_l.rotation_euler = (math.radians(20), 0, math.radians(-25))

    elif pose_name == "parry":
        # ปัดดาบสะท้อน (Parry / Shield Deflect): พุ่งโล่ไปข้างหน้าพร้อมเฉียงดาบรับ
        torso.rotation_euler = (math.radians(12), 0, 0)
        shoulder_l.rotation_euler = (math.radians(-75), math.radians(15), math.radians(25))
        arm_l.rotation_euler = (math.radians(-25), 0, 0)
        shield.rotation_euler = (math.radians(30), math.radians(-10), 0)
        shoulder_r.rotation_euler = (math.radians(-70), math.radians(-25), math.radians(35))
        hand_r.rotation_euler = (math.radians(45), math.radians(35), 0)

    elif pose_name == "hit_react":
        # โดนฟัน (Hit React): หงายหลัง ตัวเซ แขนกางออก
        torso.rotation_euler = (math.radians(-30), math.radians(-10), math.radians(-15))
        head.rotation_euler = (math.radians(-25), 0, math.radians(10))
        shoulder_r.rotation_euler = (math.radians(45), 0, math.radians(-45))
        shoulder_l.rotation_euler = (math.radians(40), 0, math.radians(45))


def setup_render_engine(resolution=256):
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE_NEXT' if hasattr(bpy.types, 'RenderSettings') and 'BLENDER_EEVEE_NEXT' in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items else 'BLENDER_EEVEE'
    scene.render.resolution_x = resolution
    scene.render.resolution_y = resolution
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if hasattr(scene, "eevee") and hasattr(scene.eevee, "taa_render_samples"):
        scene.eevee.taa_render_samples = 16


def render_all_knight_combat_poses():
    setup_render_engine(256)
    scene = bpy.context.scene

    poses = [
        "idle",
        "windup_left",
        "attack_left",
        "windup_right",
        "attack_right",
        "windup_top",
        "attack_top",
        "parry",
        "hit_react",
    ]

    for is_white in [True, False]:
        faction_name = "white" if is_white else "black"
        clear_scene()
        rig = build_knight(is_white)

        # แสงหลักและ Rim Light
        light_data = bpy.data.lights.new(name="KeyLight", type='SUN')
        light_data.energy = 3.5
        light_obj = bpy.data.objects.new(name="KeyLight", object_data=light_data)
        light_obj.rotation_euler = (math.radians(50), math.radians(20), math.radians(35))
        scene.collection.objects.link(light_obj)

        rim_data = bpy.data.lights.new(name="RimLight", type='SUN')
        rim_data.energy = 2.2
        rim_data.color = (0.75, 0.88, 1.0) if is_white else (0.85, 0.40, 1.0)
        rim_obj = bpy.data.objects.new(name="RimLight", object_data=rim_data)
        rim_obj.rotation_euler = (math.radians(-50), 0, math.radians(-145))
        scene.collection.objects.link(rim_obj)

        # Fill Light ด้านล่างให้รายละเอียดใต้เกราะชัดเจน
        fill_data = bpy.data.lights.new(name="FillLight", type='SUN')
        fill_data.energy = 1.0
        fill_obj = bpy.data.objects.new(name="FillLight", object_data=fill_data)
        fill_obj.rotation_euler = (math.radians(-20), math.radians(45), 0)
        scene.collection.objects.link(fill_obj)

        # กล้อง Orthographic กึ่งกลางตัวละครที่ Z = 1.02
        cam_data = bpy.data.cameras.new(name="DuelCam")
        cam_data.type = 'ORTHO'
        cam_data.ortho_scale = 2.35  # พอดีตัวละคร เท้าชิดขอบล่าง หัวไม่ล้นขอบบน
        cam_obj = bpy.data.objects.new(name="DuelCam", object_data=cam_data)
        scene.collection.objects.link(cam_obj)
        scene.camera = cam_obj

        # จุดเล็งเป้ากึ่งกลางลำตัว
        target_center = mathutils.Vector((0.0, 0.0, 1.02))

        # 2 มุมมองการเล่น:
        # back: ผู้เล่นยืนหันหลังให้กล้อง หันหน้าเข้าหาคู่ต่อสู้ (Y = -3.2 looking at +Y)
        # front: ศัตรูยืนหันหน้าเข้าหากล้อง (Y = +3.2 looking at -Y)
        views = [
            ("back", mathutils.Vector((0.0, -3.2, 1.26))),
            ("front", mathutils.Vector((0.0, 3.2, 1.26))),
        ]

        print(f"=== Rendering Poses for: {faction_name.upper()} Knight ===")

        for view_name, cam_pos in views:
            cam_obj.location = cam_pos
            cam_obj.rotation_euler = (target_center - cam_pos).to_track_quat('-Z', 'Y').to_euler()

            for pose in poses:
                apply_pose(rig, pose)
                bpy.context.view_layer.update()

                out_file = OUT_DIR / f"{faction_name}_{view_name}_{pose}.png"
                scene.render.filepath = str(out_file)
                bpy.ops.render.render(write_still=True)
                print(f"  [Rendered] {out_file.name}")

    print("=== All 36 Knight combat poses rendered successfully! ===")


if __name__ == "__main__":
    render_all_knight_combat_poses()
