class_name ParryVFX
extends Node3D
## ระบบเอฟเฟกต์ Parry ระดับพรีเมียม (Hitstop, Star Flare, Expanding Shockwave, Sparks, Camera Shake, Screen Flash)
## ออกแบบมาให้ทำงานทันทีโดยไม่ต้องพึ่ง Texture ภายนอก (ใช้ Procedural Shaders + Mesh Instances)

const FLASH_SHADER = preload("res://art/vfx/parry_flash.gdshader")
const SHOCKWAVE_SHADER = preload("res://art/vfx/parry_shockwave.gdshader")
const GROUP := "skill_effects"


## เรียกใช้ฟังก์ชันนี้เมื่อเกิดการ Parry สำเร็จ
static func spawn(parent: Node, clash_position: Vector3, direction: int = 1, is_player: bool = true) -> Node3D:
	var root := Node3D.new()
	root.name = "ParryClashVFX"
	root.add_to_group(GROUP)
	root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	parent.add_child(root)
	root.global_position = clash_position

	# ปรับโทนสี: ถ้าเป็นฝ่ายขาว/ผู้เล่น Parry ได้จะเป็นสีทองสว่าง (Holy Gold), ถ้าฝ่ายดำจะเป็นสีม่วง/เงิน (Shadow Void)
	var core_color := Color(1.0, 0.98, 0.85, 1.0) if is_player else Color(0.9, 0.8, 1.0, 1.0)
	var glow_color := Color(1.0, 0.6, 0.1, 1.0) if is_player else Color(0.65, 0.2, 1.0, 1.0)

	# 1. แฟลชดาวกระจายตรงกลางจุดปะทะ (Star Flare Core)
	_spawn_star_flare(root, core_color, glow_color)

	# 2. วงแหวนคลื่นกระแทก 3 มิติ (Expanding Shockwave Ring)
	_spawn_shockwave(root, glow_color, direction)

	# 3. สะเก็ดประกายไฟดาบพุ่งกระจาย (Radial Sparks Burst)
	_spawn_spark_burst(root, glow_color, 16)

	# 4. หยุดเวลาชั่วพริบตา (Hitstop / Micro Time-Freeze สไตล์ Sekiro / Street Fighter)
	_apply_hitstop(root.get_tree(), 0.065, 0.05)

	# 5. กระตุกกล้องสั่นสะเทือน (Camera Trauma Shake)
	_trigger_camera_shake(root, 0.55)

	# 6. แสงวาบเต็มจอ (Screen Flash)
	_spawn_screen_flash(root, core_color)

	# ลบเอฟเฟกต์ทั้งหมดเมื่อเล่นจบ (0.45 วินาที)
	var cleanup_timer := root.get_tree().create_timer(0.45, true, false, true)
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(root):
			root.queue_free()
	)

	return root


## 1. แฟลชดาวกระจายตรงกลาง
static func _spawn_star_flare(parent: Node3D, core_col: Color, glow_col: Color) -> void:
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(2.4, 2.4)
	quad.mesh = mesh
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mat := ShaderMaterial.new()
	mat.shader = FLASH_SHADER
	mat.set_shader_parameter("core_color", core_col)
	mat.set_shader_parameter("glow_color", glow_col)
	mat.set_shader_parameter("intensity", 4.5)
	quad.material_override = mat

	# บิลบอร์ดหันหากล้องเสมอ
	var billboard_mat := StandardMaterial3D.new()
	billboard_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED

	parent.add_child(quad)
	quad.scale = Vector3.ONE * 0.2

	var tween := parent.create_tween()
	tween.set_speed_scale(1.0)
	# ขยายเร็วมากใน 0.04 วิ แล้วหดหาย
	tween.tween_property(quad, "scale", Vector3.ONE * 1.5, 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(quad, "scale", Vector3.ZERO, 0.15).set_ease(Tween.EASE_IN)


## 2. คลื่นกระแทกวงแหวนขยายตัว
static func _spawn_shockwave(parent: Node3D, ring_col: Color, direction: int) -> void:
	var shockwave := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(3.5, 3.5)
	shockwave.mesh = quad
	shockwave.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# เอียงตามทิศทางที่ปัดดาบ (LEFT / RIGHT / TOP)
	if direction == 2: # TOP
		shockwave.rotation_degrees.x = 90.0
	elif direction == 0: # LEFT
		shockwave.rotation_degrees = Vector3(15.0, 45.0, -30.0)
	else: # RIGHT
		shockwave.rotation_degrees = Vector3(15.0, -45.0, 30.0)

	var mat := ShaderMaterial.new()
	mat.shader = SHOCKWAVE_SHADER
	mat.set_shader_parameter("ring_color", ring_col)
	mat.set_shader_parameter("intensity", 5.0)
	mat.set_shader_parameter("progress", 0.0)
	shockwave.material_override = mat

	parent.add_child(shockwave)
	shockwave.scale = Vector3.ONE * 0.4

	var tween := parent.create_tween()
	tween.parallel().tween_method(func(val: float):
		if is_instance_valid(mat):
			mat.set_shader_parameter("progress", val)
	, 0.0, 1.0, 0.28)
	tween.parallel().tween_property(shockwave, "scale", Vector3.ONE * 1.8, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## 3. สะเก็ดประกายไฟดาบพุ่งกระจาย (Radial Sparks)
static func _spawn_spark_burst(parent: Node3D, spark_col: Color, count: int) -> void:
	var spark_mat := StandardMaterial3D.new()
	spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mat.albedo_color = Color(spark_col.r * 2.5, spark_col.g * 2.2, spark_col.b * 1.5, 1.0)
	spark_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD

	for i in count:
		var spark := MeshInstance3D.new()
		var box := BoxMesh.new()
		var len := randf_range(0.25, 0.55)
		box.size = Vector3(0.03, 0.03, len)
		spark.mesh = box
		spark.material_override = spark_mat
		spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		parent.add_child(spark)

		# สุ่มทิศทางพุ่งเป็นทรงกรวย/รัศมี
		var angle := (float(i) / float(count)) * TAU + randf_range(-0.2, 0.2)
		var elevation := randf_range(-0.4, 0.6)
		var dir := Vector3(cos(angle), elevation, sin(angle)).normalized()

		# หันหัวแท่งสี่เหลี่ยมไปตามทิศที่พุ่ง
		spark.look_at(spark.global_position + dir)

		var speed := randf_range(7.0, 14.0)
		var target_pos := dir * (speed * 0.2)
		var duration := randf_range(0.18, 0.28)

		var tween := spark.create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "position", target_pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(spark, "scale", Vector3(0.1, 0.1, 0.0), duration).set_ease(Tween.EASE_IN)


## 4. Hitstop (หยุดเฟรมชั่วคราว)
static func _apply_hitstop(tree: SceneTree, duration_real_sec: float, time_scale: float) -> void:
	if tree == null:
		return
	var prev_scale := Engine.time_scale
	Engine.time_scale = time_scale
	# Timer ที่ละเว้น time_scale เพื่อกลับคืนความเร็วปกติได้ตามเวลาจริง
	var timer := tree.create_timer(duration_real_sec, true, false, true)
	timer.timeout.connect(func():
		Engine.time_scale = prev_scale
	)


## 5. สั่งกล้องสั่นสะเทือน (Trauma Shake)
static func _trigger_camera_shake(node: Node, amount: float) -> void:
	var viewport := node.get_viewport()
	if viewport == null:
		return
	var camera := viewport.get_camera_3d()
	if camera != null and camera.has_method("shake"):
		camera.call("shake", amount)


## 6. แสงวาบเต็มหน้าจอ (Screen Flash)
static func _spawn_screen_flash(node: Node, flash_col: Color) -> void:
	var tree := node.get_tree()
	if tree == null or tree.root == null:
		return

	var canvas := CanvasLayer.new()
	canvas.layer = 100
	tree.root.add_child(canvas)

	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.color = Color(flash_col.r, flash_col.g, flash_col.b, 0.28)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(rect)

	var tween := canvas.create_tween()
	# ปล่อยให้เวลาวิ่งจริงแม้โดน hitstop
	tween.tween_property(rect, "color:a", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(canvas.queue_free)
