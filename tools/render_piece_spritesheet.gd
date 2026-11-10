extends SceneTree
## เครื่องมือเรนเดอร์โมเดลหมากรุกใน Godot ออกเป็นภาพ 8 ทิศทาง (Godot-Side Directional Capture)
## วิธีรัน:
##   ./Godot_v4.7.2-stable_win64_console.exe --path . --resolution 512x512 --script res://tools/render_piece_spritesheet.gd -- pawn
## หากไม่ระบุชื่อหมาก จะเรนเดอร์ครบทั้ง 6 ตัว (pawn, knight, rook, bishop, queen, king)

const OUTPUT_DIR := "res://art/sprites/pieces_8dir/"
const PIECES := ["pawn", "knight", "rook", "bishop", "queen", "king"]

const DIRECTIONS := [
	{"name": "south", "angle": 0.0},
	{"name": "south_east", "angle": 45.0},
	{"name": "east", "angle": 90.0},
	{"name": "north_east", "angle": 135.0},
	{"name": "north", "angle": 180.0},
	{"name": "north_west", "angle": 225.0},
	{"name": "west", "angle": 270.0},
	{"name": "south_west", "angle": 315.0},
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var user_args := OS.get_cmdline_user_args()
	var targets: Array[String] = []

	for p in PIECES:
		if user_args.is_empty() or p in user_args:
			targets.append(p)

	for piece_type in targets:
		print("=== Rendering 8-Direction Sprites for: %s ===" % piece_type)
		var piece_dir := OUTPUT_DIR + piece_type + "/"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(piece_dir))

		for dir_info in DIRECTIONS:
			var stage := Node3D.new()
			root.add_child(stage)

			var height: float = LowPolyCharacters.HEIGHTS.get(piece_type, 2.5)

			# สร้างตัวละครหมาก
			var char_node := LowPolyCharacters.build(piece_type, false)
			char_node.rotation_degrees.y = 180.0 + dir_info["angle"]
			stage.add_child(char_node)

			# แสงไฟ
			var light := DirectionalLight3D.new()
			light.rotation_degrees = Vector3(-45, 30, 0)
			light.light_energy = 1.2
			stage.add_child(light)

			var rim_light := DirectionalLight3D.new()
			rim_light.rotation_degrees = Vector3(-30, -140, 0)
			rim_light.light_energy = 0.6
			rim_light.light_color = Color(0.8, 0.9, 1.0)
			stage.add_child(rim_light)

			# กล้อง Isometric / 3D
			var cam := Camera3D.new()
			cam.projection = Camera3D.PROJECTION_ORTHOGONAL
			cam.size = height * 1.5
			stage.add_child(cam)
			cam.position = Vector3(0, height * 0.5 + 4.0, 7.0)
			cam.look_at(Vector3(0, height * 0.45, 0))

			# รอรอบเรนเดอร์เข้าที่
			for i in 6:
				await process_frame
			await create_timer(0.05).timeout

			var img := root.get_viewport().get_texture().get_image()
			var side := mini(img.get_width(), img.get_height())
			var square_img := img.get_region(Rect2i((img.get_width() - side) / 2, (img.get_height() - side) / 2, side, side))

			var save_path := piece_dir + "%s_%s.png" % [piece_type, dir_info["name"]]
			square_img.save_png(ProjectSettings.globalize_path(save_path))
			print("  [Saved] %s" % save_path)

			stage.queue_free()
			await process_frame

	print("=== All 8-directional renders completed! ===")
	quit()
