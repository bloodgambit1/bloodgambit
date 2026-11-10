extends SceneTree
## Step 8: ถ่ายภาพ concept art แบบ low-poly ทั้ง 12 ภาพ แล้วบันทึกไว้ที่ art/concepts/
## วิธีรัน (ต้องมีหน้าต่าง ห้ามใช้ --headless เพราะต้องเรนเดอร์ภาพจริง):
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1600x900 --script res://tools/render_concept_art.gd
## รันเฉพาะบางภาพ: ใส่ชื่อต่อท้ายหลัง -- เช่น  -- arena_pawn char_queen

const OUTPUT_DIR := "res://art/concepts/"
const SHOTS := [
	"arena_pawn", "arena_knight", "arena_rook", "arena_royal",
	"char_pawn", "char_knight", "char_rook", "char_bishop", "char_queen", "char_king",
	"view_topdown_board", "view_over_shoulder",
]
const CHARACTER_THEMES := {
	"pawn": "pawn", "knight": "knight", "rook": "rook", "bishop": "royal", "queen": "royal", "king": "royal",
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var wanted := OS.get_cmdline_user_args()
	for shot: String in SHOTS:
		if not wanted.is_empty() and shot not in wanted:
			continue
		var stage := Node3D.new()
		root.add_child(stage)
		var square := _build_shot(stage, shot)
		await _settle()
		var image := root.get_viewport().get_texture().get_image()
		if square:
			var side := image.get_height()
			image = image.get_region(Rect2i((image.get_width() - side) / 2, 0, side, side))
		var path := OUTPUT_DIR + shot + ".png"
		image.save_png(ProjectSettings.globalize_path(path))
		print("saved ", path)
		stage.queue_free()
		await process_frame
		await process_frame
	quit()


## รอให้เงา แสงฟุ้ง และประกายไฟเข้าที่ก่อนถ่าย
func _settle() -> void:
	for i in 12:
		await process_frame
	await create_timer(0.4).timeout


## คืนค่า true ถ้าเป็นภาพสี่เหลี่ยมจัตุรัส (ภาพตัวละคร)
func _build_shot(stage: Node3D, shot: String) -> bool:
	if shot.begins_with("arena_"):
		var theme := shot.trim_prefix("arena_")
		stage.add_child(LowPolyArena.build(theme))
		_camera(stage, Vector3(0, 7.5, 15.5), Vector3(0, 1.5, -2), 60)
		return false

	if shot.begins_with("char_"):
		var type := shot.trim_prefix("char_")
		var height: float = LowPolyCharacters.HEIGHTS[type]
		stage.add_child(LowPolyArena.build(CHARACTER_THEMES[type], 1, 5, false))
		var character := LowPolyCharacters.build(type, type == "pawn")
		character.rotation_degrees.y = 180.0  # หันหน้าเข้ากล้อง
		stage.add_child(character)
		_rim_light(stage, height)
		_camera(stage, Vector3(height * 0.85, height * 0.6, height * 1.95), Vector3(0, height * 0.45, 0), 45)
		return true

	if shot == "view_topdown_board":
		_build_board_view(stage)
		return false

	_build_over_shoulder(stage)
	return false


func _camera(stage: Node3D, position: Vector3, look_target: Vector3, fov: float) -> Camera3D:
	var camera := Camera3D.new()
	camera.fov = fov
	stage.add_child(camera)
	camera.look_at_from_position(position, look_target)
	camera.make_current()
	return camera


func _rim_light(stage: Node3D, height: float) -> void:
	var key := SpotLight3D.new()
	key.light_energy = 6.0
	key.spot_range = 12.0
	key.spot_angle = 35.0
	key.shadow_enabled = true
	stage.add_child(key)
	key.look_at_from_position(Vector3(height * 1.2, height * 1.4, height * 1.0), Vector3(0, height * 0.5, 0))
	var rim := OmniLight3D.new()
	rim.light_color = Color(0.6, 0.7, 1.0)
	rim.light_energy = 2.5
	rim.omni_range = 6.0
	rim.position = Vector3(-height * 0.6, height * 0.9, -height * 0.9)
	stage.add_child(rim)


## กระดาน 8x8 มองจากบนลงล่าง พร้อมหมากทุกตัวในตำแหน่งเริ่มต้น
func _build_board_view(stage: Node3D) -> void:
	stage.add_child(LowPolyArena.build("cathedral_board", 8, 22))
	var back_rank := ["rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook"]
	for team in 2:
		LowPoly.tint = Color.WHITE if team == 0 else Color(0.45, 0.42, 0.5)
		var base_material := LowPoly.glow_material(Color(0.9, 0.85, 0.7) if team == 0 else Color(0.8, 0.15, 0.2), 0.8)
		for x in 8:
			for row in 2:
				var rank := (row if team == 0 else 7 - row)
				var type: String = back_rank[x] if row == 0 else "pawn"
				var piece := LowPolyCharacters.build(type)
				piece.scale = Vector3.ONE * (0.6 if type == "knight" else 0.75)
				piece.position = Vector3((x - 3.5) * 2.0, 0.0, (3.5 - rank) * 2.0)
				piece.rotation_degrees.y = 0.0 if team == 0 else 180.0
				stage.add_child(piece)
				var base := LowPoly.add(stage, LowPoly.cylinder(0.5, 0.55, 0.05, 8), base_material, piece.position + Vector3(0, 0.03, 0))
				base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	LowPoly.tint = Color.WHITE
	var camera := _camera(stage, Vector3(0, 24, 0.01), Vector3.ZERO, 55)
	camera.rotation_degrees = Vector3(-90, 0, 0)


## มุมข้ามไหล่: Pawn ตัวเล็กเผชิญหน้า Queen ยักษ์ ดาบปะทะกันมีประกายไฟ
func _build_over_shoulder(stage: Node3D) -> void:
	stage.add_child(LowPolyArena.build("royal", 3, 18))
	var pawn := LowPolyCharacters.build("pawn")
	pawn.position = Vector3(-0.3, 0, 1.6)
	stage.add_child(pawn)
	var highlight := LowPoly.add(stage, LowPoly.box(Vector3(1.9, 0.03, 1.9)), LowPoly.glow_material(Color(0.6, 0.3, 1.0), 1.4), Vector3(0, 0.015, 2.0))
	highlight.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var queen := LowPolyCharacters.build("queen")
	queen.scale = Vector3.ONE * 2.6
	queen.position = Vector3(0.8, 0, -3.2)
	queen.rotation_degrees.y = 15.0
	stage.add_child(queen)

	var clash := Vector3(0.05, 1.05, 0.35)
	stage.add_child(_sparks(clash))
	var flash := OmniLight3D.new()
	flash.light_color = Color(1.0, 0.65, 0.25)
	flash.light_energy = 3.0
	flash.omni_range = 4.0
	flash.position = clash
	stage.add_child(flash)
	_camera(stage, Vector3(1.5, 1.5, 5.4), Vector3(-0.4, 2.4, -2.5), 58)


func _sparks(at: Vector3) -> CPUParticles3D:
	var spark_mesh := BoxMesh.new()
	spark_mesh.size = Vector3(0.025, 0.025, 0.12)
	spark_mesh.material = LowPoly.glow_material(Color(1.0, 0.7, 0.25), 8.0)
	var sparks := CPUParticles3D.new()
	sparks.mesh = spark_mesh
	sparks.amount = 160
	sparks.lifetime = 0.9
	sparks.preprocess = 0.9
	sparks.explosiveness = 0.1
	sparks.direction = Vector3(0, 1, 0.3)
	sparks.spread = 180.0
	sparks.initial_velocity_min = 1.5
	sparks.initial_velocity_max = 4.5
	sparks.gravity = Vector3(0, -5, 0)
	sparks.particle_flag_align_y = true
	sparks.scale_amount_min = 0.6
	sparks.scale_amount_max = 1.4
	sparks.position = at
	return sparks
