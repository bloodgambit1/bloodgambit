class_name LowPoly
extends RefCounted
## Step 8: ตัวช่วยสร้างโมเดล low-poly ด้วยโค้ด
## ทุกชิ้นจะถูกแปลงเป็นผิวเหลี่ยม (flat shading: แต่ละหน้าสามเหลี่ยมมีแสงเงาของตัวเอง)
## และบิดจุดยอดเล็กน้อย (jitter) ให้ดูเป็นหินแกะ/โลหะบุบ ไม่เรียบเหมือนรูปทรงในโปรแกรม

## คูณสีทุกวัสดุที่สร้าง (เช่น ทำหมากฝ่ายดำให้เข้มขึ้น)
static var tint := Color.WHITE
## ถ้าตั้งไว้ ทุกชิ้นจะใช้วัสดุนี้แทน (เช่น ทำรูปปั้นหินทั้งตัว)
static var forced_material: Material = null


static func material(color: Color, roughness := 0.85, metallic := 0.0) -> Material:
	if forced_material != null:
		return forced_material
	var result := StandardMaterial3D.new()
	result.albedo_color = Color(color.r * tint.r, color.g * tint.g, color.b * tint.b, color.a)
	result.roughness = roughness
	result.metallic = metallic
	return result


## วัสดุเรืองแสง (energy มากกว่า 1 จะเกิดแสงฟุ้ง/Glow)
static func glow_material(color: Color, energy := 3.0) -> Material:
	if forced_material != null:
		return forced_material
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.emission_enabled = true
	result.emission = color
	result.emission_energy_multiplier = energy
	return result


static func box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


## top = 0 จะได้กรวย, sides น้อย = เหลี่ยมชัด
static func cylinder(top: float, bottom: float, height: float, sides := 6) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 0
	return mesh


static func sphere(radius: float, sides := 6, rings := 3) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = sides
	mesh.rings = rings
	return mesh


## สร้างชิ้นส่วน 1 ชิ้นแล้วใส่ใต้ parent
static func add(parent: Node3D, mesh: Mesh, mat: Material, position := Vector3.ZERO,
		rotation_degrees := Vector3.ZERO, scale := Vector3.ONE, jitter := 0.0, seed := 0) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = faceted(mesh, jitter, seed)
	instance.material_override = mat
	instance.position = position
	instance.rotation_degrees = rotation_degrees
	instance.scale = scale
	parent.add_child(instance)
	return instance


## แปลง mesh ให้เป็นผิวเหลี่ยม + บิดจุดยอด (จุดที่ตำแหน่งเดียวกันจะบิดเท่ากัน ผิวจึงไม่แตกเป็นรู)
static func faceted(source: Mesh, jitter := 0.0, seed := 0) -> ArrayMesh:
	var arrays := source.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if jitter > 0.0:
		for i in vertices.size():
			vertices[i] += _noise(vertices[i], seed) * jitter

	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := indices.size() if not indices.is_empty() else vertices.size()
	for t in range(0, count - 2, 3):
		var ia := indices[t] if not indices.is_empty() else t
		var ib := indices[t + 1] if not indices.is_empty() else t + 1
		var ic := indices[t + 2] if not indices.is_empty() else t + 2
		var a := vertices[ia]
		var b := vertices[ib]
		var c := vertices[ic]
		var normal := (b - a).cross(c - a)
		if normal.length_squared() < 1e-12:
			continue  # สามเหลี่ยมแบน (เช่น ปลายกรวย) ข้ามไป
		normal = normal.normalized()
		if normal.dot(normals[ia] + normals[ib] + normals[ic]) < 0.0:
			normal = -normal
		tool.set_normal(normal)
		tool.add_vertex(a)
		tool.add_vertex(b)
		tool.add_vertex(c)
	return tool.commit()


static func _noise(point: Vector3, seed: int) -> Vector3:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([Vector3i((point * 997.0).round()), seed])
	return Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
