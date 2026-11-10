class_name SkillEffects
extends RefCounted
## ตัวช่วยสร้างภาพเอฟเฟกต์ง่าย ๆ ของสกิล (ไว้เปลี่ยนเป็น particle สวย ๆ ทีหลัง)
## ทุกเอฟเฟกต์อยู่ในกลุ่ม GROUP เพื่อให้ ChessArenaManager ลบทิ้งได้ตอนจบการดวล

const GROUP := "skill_effects"


static func make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


static func box(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = make_material(color)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


## ทรงกลมขยายแล้วจางหาย (ใช้กับระเบิด กระทืบพื้น ระเบิดพลัง วาร์ป)
static func spawn_flash(parent: Node, world_position: Vector3, radius: float, color: Color) -> void:
	var mesh := SphereMesh.new()
	var material := make_material(Color(color, 0.55))
	mesh.material = material
	var flash := MeshInstance3D.new()
	flash.mesh = mesh
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flash.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	flash.add_to_group(GROUP)
	parent.add_child(flash)
	flash.global_position = world_position
	flash.scale = Vector3.ONE * 0.2

	var tween := flash.create_tween()
	tween.tween_property(flash, "scale", Vector3.ONE * radius, 0.25)
	tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.4)
	tween.tween_callback(flash.queue_free)
