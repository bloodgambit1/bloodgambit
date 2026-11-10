extends SceneTree
## พรีวิวตัวละคร 2.5D ในสังเวียน
## วิธีรัน:
##   ./Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 --script res://tools/preview_25d_arena.gd -- --capture

var stage: Node3D
var camera: Camera3D

func _initialize() -> void:
	stage = Node3D.new()
	root.add_child.call_deferred(stage)
	setup.call_deferred()

func setup() -> void:
	camera = Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(0, 2.2, 4.2)
	camera.look_at(Vector3(0, 1.1, 0))

	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.05, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.65, 0.75)
	env.ambient_light_energy = 1.0
	environment.environment = env
	stage.add_child(environment)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 30, 0)
	light.light_energy = 1.2
	stage.add_child(light)

	# สร้างพื้นเวทีสังเวียน
	var floor_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(8.0, 0.2, 8.0)
	floor_mesh.mesh = box
	floor_mesh.position.y = -0.1
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.18, 0.2, 0.25)
	floor_mesh.material_override = floor_mat
	stage.add_child(floor_mesh)

	# สร้างตัวละคร 2.5D ฝ่ายขาว (Player - Knight)
	var white_knight := Pixel25DCharacter.build_sprite("knight", true)
	white_knight.position = Vector3(-1.2, 0, 0)
	stage.add_child(white_knight)

	# สร้างตัวละคร 2.5D ฝ่ายดำ (Enemy - King)
	var black_king := Pixel25DCharacter.build_sprite("king", false)
	black_king.position = Vector3(1.2, 0, 0)
	stage.add_child(black_king)

	# ป้ายกำกับ
	var label := Label3D.new()
	label.text = "2.5D PIXEL ART CHESS DUEL"
	label.position = Vector3(0, 2.8, 0)
	label.font_size = 48
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	stage.add_child(label)

	if "--capture" in OS.get_cmdline_user_args():
		capture.call_deferred()

func capture() -> void:
	for i in 6:
		await process_frame
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png("res://art/sprites/preview_25d_duel.png")
	print("Captured 2.5D duel preview to art/sprites/preview_25d_duel.png")
	quit()
