"""Run with Blender --background --python tools/build_slash.py."""
import bpy
import math
from pathlib import Path

root = Path(__file__).resolve().parents[1]
out = root / 'art' / 'vfx'
out.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
vertices, faces = [], []
steps = 48
for i in range(steps + 1):
    t = i / steps
    angle = math.radians(-75 + 150 * t)
    width = 0.32 * math.sin(math.pi * t) ** 0.7 + 0.005
    for radius in (1.65 - width, 1.65):
        vertices.append((math.sin(angle) * radius, -math.cos(angle) * radius, 0))
for i in range(steps):
    a = i * 2
    faces.append((a, a + 1, a + 3, a + 2))
mesh = bpy.data.meshes.new('BloodSlashRibbon')
mesh.from_pydata(vertices, [], faces)
mesh.update()
obj = bpy.data.objects.new('BloodSlashRibbon', mesh)
bpy.context.collection.objects.link(obj)
bpy.context.view_layer.objects.active = obj
obj.select_set(True)
uv = mesh.uv_layers.new(name='UVMap')
for poly in mesh.polygons:
    for idx in poly.loop_indices:
        vertex = mesh.loops[idx].vertex_index
        uv.data[idx].uv = (vertex // 2 / steps, vertex % 2)
# Keep the authoring file outside Godot's imported assets.
bpy.ops.wm.save_as_mainfile(filepath=str(root / 'tools' / 'vfx_source' / 'blood_slash.blend'))
bpy.ops.export_scene.gltf(filepath=str(out / 'blood_slash.glb'), export_format='GLB', use_selection=True)
bpy.ops.export_scene.fbx(filepath=str(out / 'blood_slash.fbx'), use_selection=True, axis_forward='-Z', axis_up='Y')

