"""
Blender 4.5: HD-2D Layered Pixel Art Extractor (Octopath Traveler Style)
-------------------------------------------------------------------------
เรนเดอร์ชิ้นส่วนตัวละครแยกเลเยอร์ 3D เพื่อสร้างเอฟเฟกต์ HD-2D แบบสมบูรณ์:
1. Body Layer: ลำตัว หมวกเกราะ ขา (ไม่มีดาบและโล่)
2. Shield Layer: โล่ฮีตเตอร์พร้อมตรากางเขน (แยกแกนหมุน 3D อิสระ)
3. Sword Layer: ดาบครูเซเดอร์คมเหล็กขลิบทอง (แยกจุดหมุน Pivot ที่ด้ามจับเพื่อฟันในโลก 3D)
เรนเดอร์ทั้ง 2 ฝ่าย (White / Black) และ 2 มุมมอง (Back View / Front View)
"""

import os
import sys
import math
from pathlib import Path
import bpy
import mathutils

ROOT_DIR = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT_DIR / "art" / "sprites" / "hd2d"
OUT_DIR.mkdir(parents=True, exist_ok=True)

sys.path.append(str(ROOT_DIR))
from tools.build_knight_poses import clear_scene, build_knight, setup_render_engine


def hide_objects(obj_names, hide=True):
    for name in obj_names:
        obj = bpy.data.objects.get(name)
        if obj:
            obj.hide_render = hide


def get_all_sword_objs():
    return ["Shoulder_R", "Pauldron_R", "Arm_R", "Hand_R", "Sword_Guard", "Sword_Hilt", "Sword_Pommel", "Sword_Blade"]


def get_all_shield_objs():
    return ["Shoulder_L", "Pauldron_L", "Arm_L", "Shield_Anchor", "Shield_Body", "Shield_Rim", "Shield_Cross_V", "Shield_Cross_H"]


def render_hd2d_layers():
    setup_render_engine(256)
    scene = bpy.context.scene

    target_center = mathutils.Vector((0.0, 0.0, 1.02))
    views = [
        ("back", mathutils.Vector((0.0, -3.2, 1.26))),
        ("front", mathutils.Vector((0.0, 3.2, 1.26))),
    ]

    for is_white in [True, False]:
        faction = "white" if is_white else "black"
        clear_scene()
        rig = build_knight(is_white)

        # จัดแสงแบบ HD-2D: Rim Light ชัดเจน + Key Light + Fill Light
        key = bpy.data.lights.new(name="Key", type='SUN')
        key.energy = 3.6
        key_obj = bpy.data.objects.new(name="Key", object_data=key)
        key_obj.rotation_euler = (math.radians(50), math.radians(20), math.radians(35))
        scene.collection.objects.link(key_obj)

        rim = bpy.data.lights.new(name="Rim", type='SUN')
        rim.energy = 2.8
        rim.color = (0.8, 0.9, 1.0) if is_white else (0.85, 0.45, 1.0)
        rim_obj = bpy.data.objects.new(name="Rim", object_data=rim)
        rim_obj.rotation_euler = (math.radians(-50), 0, math.radians(-145))
        scene.collection.objects.link(rim_obj)

        fill = bpy.data.lights.new(name="Fill", type='SUN')
        fill.energy = 1.0
        fill_obj = bpy.data.objects.new(name="Fill", object_data=fill)
        fill_obj.rotation_euler = (math.radians(-20), math.radians(45), 0)
        scene.collection.objects.link(fill_obj)

        cam_data = bpy.data.cameras.new(name="Cam")
        cam_data.type = 'ORTHO'
        cam_data.ortho_scale = 2.35
        cam_obj = bpy.data.objects.new(name="Cam", object_data=cam_data)
        scene.collection.objects.link(cam_obj)
        scene.camera = cam_obj

        sword_objs = get_all_sword_objs()
        shield_objs = get_all_shield_objs()

        for view_name, cam_pos in views:
            cam_obj.location = cam_pos
            cam_obj.rotation_euler = (target_center - cam_pos).to_track_quat('-Z', 'Y').to_euler()

            # 1. Body Layer (ซ่อนดาบและโล่)
            hide_objects(sword_objs, True)
            hide_objects(shield_objs, True)
            bpy.context.view_layer.update()
            out_file = OUT_DIR / f"{faction}_{view_name}_body.png"
            scene.render.filepath = str(out_file)
            bpy.ops.render.render(write_still=True)
            print(f"[HD-2D Layer] {out_file.name}")

            # 2. Shield Layer (แสดงเฉพาะโล่และแขนซ้าย)
            hide_objects(sword_objs, True)
            hide_objects(shield_objs, False)
            # ซ่อนส่วนตัว
            for name in ["Knight_Root", "Pelvis", "Belt", "Torso", "Tabard", "ChestTrim", "Head", "Visor", "HelmTop", "Plume",
                         "Leg_L_Thigh", "Leg_L_Knee", "Leg_L_Shin", "Leg_L_Foot",
                         "Leg_R_Thigh", "Leg_R_Knee", "Leg_R_Shin", "Leg_R_Foot"]:
                obj = bpy.data.objects.get(name)
                if obj: obj.hide_render = True

            bpy.context.view_layer.update()
            out_file = OUT_DIR / f"{faction}_{view_name}_shield.png"
            scene.render.filepath = str(out_file)
            bpy.ops.render.render(write_still=True)
            print(f"[HD-2D Layer] {out_file.name}")

            # 3. Sword Layer (แสดงเฉพาะดาบและแขนขวา)
            hide_objects(shield_objs, True)
            hide_objects(sword_objs, False)
            bpy.context.view_layer.update()
            out_file = OUT_DIR / f"{faction}_{view_name}_sword.png"
            scene.render.filepath = str(out_file)
            bpy.ops.render.render(write_still=True)
            print(f"[HD-2D Layer] {out_file.name}")

            # คืนค่าแสดงผลทั้งหมด
            for obj in bpy.data.objects:
                obj.hide_render = False

    print("=== All HD-2D layers rendered successfully! ===")


if __name__ == "__main__":
    render_hd2d_layers()
