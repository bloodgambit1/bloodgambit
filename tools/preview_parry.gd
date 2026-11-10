extends SceneTree
## ตัวพรีวิวเอฟเฟกต์ Parry ใน Godot
## วิธีรัน:
##   ./Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/preview_parry.gd
## บันทึกภาพ Screenshot:
##   ./Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/preview_parry.gd -- --capture

var elapsed := 0.0
var stage: Node3D
var shot := false
var camera: Camera3D

const ParryVFX = preload("res://scripts/vfx/parry_vfx.gd")

func _initialize() -> void:
	stage = Node3D.new()
	root.add_child.call_deferred(stage)
	setup.call_deferred()

func setup() -> void:
	camera = Camera3D.new()
	camera.set_script(preload("res://scripts/camera/duel_camera_controller.gd"))
	stage.add_child(camera)
	camera.position = Vector3(0, 2.2, 3.8)
	camera.look_at(Vector3(0, 1.2, 0))

	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.025, 0.04)
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.25
	environment.environment = env
	stage.add_child(environment)

	# แสงไฟอ่อน ๆ
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 30, 0)
	light.light_energy = 0.8
	stage.add_child(light)

	# จำลองหุ่น 2 ตัวยืนปะทะกัน (Defender & Attacker)
	var defender := MeshInstance3D.new()
	var pawn_box := BoxMesh.new()
	pawn_box.size = Vector3(0.5, 1.6, 0.5)
	defender.mesh = pawn_box
	defender.position = Vector3(0, 0.8, 0.7)
	stage.add_child(defender)

	var attacker := MeshInstance3D.new()
	attacker.mesh = pawn_box
	attacker.position = Vector3(0, 0.8, -0.7)
	stage.add_child(attacker)

	# ป้ายบอกสถานะ
	var label := Label3D.new()
	label.text = "PARRY CLASH SYSTEM"
	label.position = Vector3(0, 2.4, 0)
	label.font_size = 48
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	stage.add_child(label)

	spawn_parry()

	if "--capture" in OS.get_cmdline_user_args():
		shot = true
		capture.call_deferred()

func spawn_parry() -> void:
	# สลับแสดงผลทั้ง 2 ฝ่าย: ฝ่ายขาว (ทอง) ทางซ้าย, ฝ่ายดำ (ม่วงวอยด์) ทางขวา
	ParryVFX.spawn(stage, Vector3(-1.4, 1.2, 0), 1, true)
	ParryVFX.spawn(stage, Vector3(1.4, 1.2, 0), 0, false)
	if camera and camera.has_method("shake"):
		camera.call("shake", 0.5)

func _process(delta: float) -> bool:
	elapsed += delta
	if elapsed > 1.2:
		elapsed = 0.0
		spawn_parry()
	if "--capture" in OS.get_cmdline_user_args() and not shot and elapsed > 0.05:
		shot = true
		capture.call_deferred()
	return false

func capture() -> void:
	await RenderingServer.frame_post_draw
	await create_timer(0.08, true, false, true).timeout
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png("res://art/vfx/parry_preview.png")
	print("Captured parry preview to art/vfx/parry_preview.png")
	quit()
