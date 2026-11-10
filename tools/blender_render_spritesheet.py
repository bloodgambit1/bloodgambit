"""
Blender 4.5 Automation: Multi-Directional Sprite Sheet Generator for Godot
--------------------------------------------------------------------------
สคริปต์เรนเดอร์โมเดล 3D ออกมาเป็น Sprite Sheet 8 ทิศทาง (Isometric / Top-Down)
สไตล์ Pixel Art สำหรับเกมหมากรุก Blood Gambit ใน Godot Engine

วิธีรันจาก Command Line:
  & "C:\\Program Files\\Blender Foundation\\Blender 4.5\\blender.exe" --background [path_to_model.blend] --python tools/blender_render_spritesheet.py -- [output_dir] [res]

หรือทดสอบเรนเดอร์โมเดลตัวอย่าง:
  & "C:\\Program Files\\Blender Foundation\\Blender 4.5\\blender.exe" --background --python tools/blender_render_spritesheet.py
"""

import sys
import os
import math
from pathlib import Path
import bpy

# 8 ทิศทางมาตรฐานของเกม 2.5D / Isometric (เริ่มจากหน้าตรง หมุนตามเข็มนาฬิกา)
DIRECTIONS = [
    ("south", 0.0),            # ด้านหน้าตรง (0 องศา)
    ("south_east", 45.0),      # หน้าขวา (45 องศา)
    ("east", 90.0),            # ด้านขวา (90 องศา)
    ("north_east", 135.0),     # หลังขวา (135 องศา)
    ("north", 180.0),          # ด้านหลังตรง (180 องศา)
    ("north_west", 225.0),     # หลังซ้าย (225 องศา)
    ("west", 270.0),           # ด้านซ้าย (270 องศา)
    ("south_west", 315.0),     # หน้าซ้าย (315 องศา)
]


def setup_pixel_art_render_settings(scene, resolution=128):
    """ตั้งค่า Render Engine ให้ได้ภาพ Pixel Art คมชัด พื้นหลังโปร่งใส"""
    scene.render.engine = 'BLENDER_EEVEE_NEXT' if hasattr(bpy.types, 'RenderSettings') and 'BLENDER_EEVEE_NEXT' in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items else 'BLENDER_EEVEE'
    scene.render.resolution_x = resolution
    scene.render.resolution_y = resolution
    scene.render.resolution_percentage = 100
    
    # พื้นหลังโปร่งใส (Alpha Transparent)
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.image_settings.color_depth = '8'

    # ปรับ Filter ให้ขอบคม ไม่เบลอ (Pixel Art Crisp Filter)
    if hasattr(scene.render, "filter_size"):
        scene.render.filter_size = 0.5


def setup_camera_and_lighting(scene, elevation_deg=30.0, ortho_scale=3.2):
    """ตั้งค่ากล้อง Orthographic และแสง 3 จุด (Key / Fill / Rim) สำหรับสไปรต์ตัวละคร"""
    # ลบกล้องเดิมถ้ามี
    for obj in list(scene.objects):
        if obj.type in ('CAMERA', 'LIGHT'):
            bpy.data.objects.remove(obj, do_unlink=True)

    # 1. กล้องแบบ Orthographic
    cam_data = bpy.data.cameras.new(name="SpriteCam")
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = ortho_scale
    cam_obj = bpy.data.objects.new(name="SpriteCam", object_data=cam_data)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj

    # ตำแหน่งกล้อง: สูงขึ้นทำมุมเอียงมองลงมาที่ตัวละคร (Elevation 30 องศา)
    dist = 10.0
    rad_elev = math.radians(elevation_deg)
    cam_obj.location = (0.0, -dist * math.cos(rad_elev), dist * math.sin(rad_elev))
    cam_obj.rotation_euler = (math.radians(90.0 - elevation_deg), 0.0, 0.0)

    # 2. Key Light (แสงหลักด้านบนเฉียง)
    key_light_data = bpy.data.lights.new(name="KeyLight", type='SUN')
    key_light_data.energy = 3.5
    key_light_data.color = (1.0, 0.98, 0.92)
    key_light = bpy.data.objects.new(name="KeyLight", object_data=key_light_data)
    key_light.rotation_euler = (math.radians(45.0), math.radians(-30.0), math.radians(45.0))
    scene.collection.objects.link(key_light)

    # 3. Rim Light (แสงขอบตัดหลัง เพิ่มมิติสไตล์พิกเซล)
    rim_light_data = bpy.data.lights.new(name="RimLight", type='SUN')
    rim_light_data.energy = 2.0
    rim_light_data.color = (0.75, 0.85, 1.0)
    rim_light = bpy.data.objects.new(name="RimLight", object_data=rim_light_data)
    rim_light.rotation_euler = (math.radians(-45.0), math.radians(15.0), math.radians(-135.0))
    scene.collection.objects.link(rim_light)

    return cam_obj


def create_sample_pawn_mesh():
    """สร้างโมเดลหมากเบี้ยตัวอย่างหากผู้ใช้เปิดรันแบบไม่มีโมเดล"""
    bpy.ops.mesh.primitive_cylinder_add(radius=0.5, depth=0.3, location=(0, 0, 0.15))
    base = bpy.context.active_object
    base.name = "Pawn_Sample"

    bpy.ops.mesh.primitive_cone_add(radius1=0.4, radius2=0.2, depth=1.0, location=(0, 0, 0.8))
    cone = bpy.context.active_object
    cone.parent = base

    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.35, location=(0, 0, 1.5))
    head = bpy.context.active_object
    head.parent = base

    # โล่ขนาดเล็กด้านหน้าซ้าย
    bpy.ops.mesh.primitive_cube_add(size=0.4, location=(-0.35, -0.25, 0.9))
    shield = bpy.context.active_object
    shield.scale = (0.3, 0.1, 0.6)
    shield.parent = base

    # ดาบสั้นมือขวา
    bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.8, location=(0.4, -0.1, 0.9))
    sword = bpy.context.active_object
    sword.rotation_euler = (math.radians(30), 0, 0)
    sword.parent = base

    return base


def get_character_root_object():
    """ค้นหาวัตถุหลัก (Armature หรือ Root Mesh) ของตัวละครใน Scene"""
    armatures = [o for o in bpy.data.objects if o.type == 'ARMATURE']
    if armatures:
        return armatures[0]
    meshes = [o for o in bpy.data.objects if o.type == 'MESH' and o.parent is None]
    if meshes:
        return meshes[0]
    return create_sample_pawn_mesh()


def render_all_directions(output_base_dir, resolution=128):
    """วนลูปเรนเดอร์ตัวละครใน 8 ทิศทาง"""
    scene = bpy.context.scene
    setup_pixel_art_render_settings(scene, resolution)
    setup_camera_and_lighting(scene, elevation_deg=32.0, ortho_scale=2.6)

    root_obj = get_character_root_object()
    original_rot_z = root_obj.rotation_euler.z

    root_dir = Path(__file__).resolve().parents[1]
    out_path = Path(output_base_dir)
    if not out_path.is_absolute():
        out_path = root_dir / out_path
    out_path.mkdir(parents=True, exist_ok=True)

    print(f"=== Starting 8-Direction Render for '{root_obj.name}' ===")
    print(f"Target Output Directory: {out_path.resolve()}")

    # ตรวจสอบว่าโมเดลมี Action / Animation หรือไม่
    actions = list(bpy.data.actions)
    if not actions:
        # ถ้าไม่มีอนิเมชั่น ให้เรนเดอร์ภาพนิ่ง 1 เฟรม ต่อทิศ
        for dir_name, angle_deg in DIRECTIONS:
            root_obj.rotation_euler.z = original_rot_z + math.radians(angle_deg)
            bpy.context.view_layer.update()
            
            frame_file = out_path / f"{root_obj.name}_{dir_name}.png"
            scene.render.filepath = str(frame_file)
            bpy.ops.render.render(write_still=True)
            print(f"  [Rendered] {dir_name}: {frame_file.name}")
    else:
        # มี Action ให้เรนเดอร์ทุกทิศทางตามแต่ละ Action
        for action in actions:
            action_name = action.name.replace(" ", "_").lower()
            action_dir = out_path / action_name
            action_dir.mkdir(parents=True, exist_ok=True)

            if root_obj.animation_data:
                root_obj.animation_data.action = action

            start_f = int(action.frame_range[0])
            end_f = int(action.frame_range[1])

            print(f"Rendering Action: {action.name} (Frames {start_f}-{end_f})")
            for dir_name, angle_deg in DIRECTIONS:
                root_obj.rotation_euler.z = original_rot_z + math.radians(angle_deg)
                bpy.context.view_layer.update()

                dir_subdir = action_dir / dir_name
                dir_subdir.mkdir(parents=True, exist_ok=True)

                for f in range(start_f, end_f + 1):
                    scene.frame_set(f)
                    frame_file = dir_subdir / f"frame_{f:03d}.png"
                    scene.render.filepath = str(frame_file)
                    bpy.ops.render.render(write_still=True)

    # คืนค่ามุมหมุนเดิม
    root_obj.rotation_euler.z = original_rot_z
    print("=== Multi-directional render completed successfully! ===")


if __name__ == "__main__":
    # รับอาร์กิวเมนต์เพิ่มเติมถ้ามี
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    output_dir = args[0] if len(args) > 0 else "art/sprites/pawn"
    res = int(args[1]) if len(args) > 1 else 128

    render_all_directions(output_dir, res)
