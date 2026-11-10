class_name ChessArenaManager
extends Node3D
## Step 4: กระดานหมากรุก 8x8 + เปลี่ยนเข้า/ออกสังเวียนต่อสู้ในฉากเดียว (ไม่โหลด Scene ใหม่)
##
## ลำดับเกม:
##   ตาเรา: คลิก/แตะหมากขาว -> ช่องที่เดินได้จะเป็นสีเขียว (สีแดง = กินได้) -> คลิกช่องปลายทาง
##   ตาศัตรู: AI เดินหมากดำ (ชอบกินตัวที่มีค่ามากด้วยตัวที่มีค่าน้อย)
##   เมื่อหมากเดินทับศัตรู: กล้องดิ่งลงไปที่ช่องนั้น -> สังเวียนยกขึ้นมาจากใต้กระดาน -> ดวลกันจริง
##   เมื่อฝ่ายใด HP หมด: สังเวียนจมลง กล้องซูมกลับ ผู้แพ้ถูกเอาออกจากกระดาน แล้วเล่นตาถัดไป
## ผู้เล่นคุมหมากขาวเสมอ ทั้งตอนเป็นฝ่ายบุกและฝ่ายตั้งรับ

signal _duel_finished(player_won: bool)

enum Phase { PLAYER_TURN, ENEMY_TURN, ANIMATING, DUEL, GAME_OVER }

const BACK_RANK := [
	ChessPiece.Type.ROOK, ChessPiece.Type.KNIGHT, ChessPiece.Type.BISHOP, ChessPiece.Type.QUEEN,
	ChessPiece.Type.KING, ChessPiece.Type.BISHOP, ChessPiece.Type.KNIGHT, ChessPiece.Type.ROOK,
]
const NO_CELL := Vector2i(-1, -1)
## ธีมสังเวียนตามหมากฝ่ายตั้งรับ (ดวลในถิ่นของฝ่ายที่โดนบุก)
const ARENA_THEMES := {
	ChessPiece.Type.PAWN: "pawn",
	ChessPiece.Type.KNIGHT: "knight",
	ChessPiece.Type.ROOK: "rook",
	ChessPiece.Type.BISHOP: "royal",
	ChessPiece.Type.QUEEN: "royal",
	ChessPiece.Type.KING: "royal",
}
const BOARD_THEME := "cathedral_board"

## ขนาดช่องละกี่เมตร
@export var tile_size := 3.0

@export_group("Scene References")
@export var board_camera: Camera3D
@export var duel_camera: DuelCameraController
## โหนดที่รวมพื้นสังเวียน ตัวละคร 2 ตัว AI และกล้องดวล
@export var arena: Node3D
@export var player_fighter: FighterController
@export var enemy_fighter: FighterController
@export var combat_input: CombatInputController
## UI ตอนต่อสู้ (จะซ่อนตอนอยู่บนกระดาน)
@export var combat_hud: CanvasLayer
## แสงหลักของฉาก (เปลี่ยนสีตามธีมสังเวียน)
@export var sun: DirectionalLight3D
## พื้นและเสาเดิมของสังเวียน (ซ่อนเมื่อใส่ฉากธีม low-poly)
@export var plain_arena_visuals: Array[Node3D] = []

@export_group("Board Camera")
@export var camera_height := 17.0
@export var camera_back := 15.0

@export_group("Transition")
@export var dive_duration := 0.7
@export var rise_duration := 0.8
@export var blend_duration := 0.5
## สังเวียนซ่อนอยู่ลึกใต้กระดานเท่าไร
@export var arena_hidden_depth := 12.0
## ยกพื้นสังเวียนให้สูงกว่าพื้นกระดานนิดนึง ไม่ให้ภาพกระพริบซ้อนกัน
@export var arena_floor_offset := 0.03
## หลังมีคนแพ้ รอกี่วินาทีก่อนกลับกระดาน
@export var duel_end_delay := 1.5
@export var enemy_think_time := 0.8

@export_group("Colors")
@export var light_tile_color := Color(0.20, 0.25, 0.36)
@export var dark_tile_color := Color(0.10, 0.12, 0.18)
@export var selected_color := Color(0.35, 0.78, 1.0)
@export var move_color := Color(0.22, 0.65, 0.95)
@export var capture_color := Color(0.95, 0.22, 0.25)

var _phase := Phase.PLAYER_TURN
var _pieces := {}  # Vector2i -> ChessPiece
var _tiles := {}   # Vector2i -> MeshInstance3D
var _selected: ChessPiece
var _legal_moves: Array[Vector2i] = []
var _board_camera_home: Transform3D
var _duel_over := false
var _selection_indicator: Node3D

var _status_label: Label
var _banner_label: Label
var _banner_tween: Tween
var white_time := 900.0 # 15 นาที Rapid Chess Clock
var black_time := 900.0
var _white_clock_label: Label
var _black_clock_label: Label
var _clock_panel: PanelContainer

var _world_environment: WorldEnvironment
var _themed_arenas := {}  # ชื่อธีม -> Node3D (สร้างครั้งแรกแล้วเก็บไว้ใช้ซ้ำ)
var _theme_environments := {}  # ชื่อธีม -> Environment


func _ready() -> void:
	_board_camera_home = _look_transform(
		global_position + Vector3(0.0, camera_height, camera_back),
		global_position + Vector3(0.0, 0.0, tile_size * 0.5))
	board_camera.global_transform = _board_camera_home
	board_camera.make_current()

	_world_environment = WorldEnvironment.new()
	add_child(_world_environment)
	_apply_lighting(BOARD_THEME)

	_build_board()
	_spawn_pieces()
	_create_board_ui()

	player_fighter.died.connect(_on_fighter_died.bind(player_fighter))
	enemy_fighter.died.connect(_on_fighter_died.bind(enemy_fighter))
	_set_combat_active(false)
	arena.visible = false
	arena.global_position = global_position + Vector3.DOWN * arena_hidden_depth

	_start_player_turn()


func _process(delta: float) -> void:
	if _phase == Phase.PLAYER_TURN:
		white_time = maxf(white_time - delta, 0.0)
		_update_clock_labels()
		if white_time <= 0.0:
			_game_over("DEFEAT", "Time has run out for White")
	elif _phase == Phase.ENEMY_TURN:
		black_time = maxf(black_time - delta, 0.0)
		_update_clock_labels()
		if black_time <= 0.0:
			_game_over("VICTORY", "Black ran out of time")


func _update_clock_labels() -> void:
	if _white_clock_label != null:
		var w_min := int(white_time) / 60
		var w_sec := int(white_time) % 60
		_white_clock_label.text = "WHITE %02d:%02d" % [w_min, w_sec]
	if _black_clock_label != null:
		var b_min := int(black_time) / 60
		var b_sec := int(black_time) % 60
		_black_clock_label.text = "BLACK %02d:%02d" % [b_min, b_sec]


func _unhandled_input(event: InputEvent) -> void:
	if _phase == Phase.GAME_OVER:
		var restart_key: bool = event is InputEventKey and event.pressed and event.physical_keycode == KEY_R
		var tapped: bool = event is InputEventMouseButton and event.pressed
		if restart_key or tapped:
			get_tree().reload_current_scene()
		return

	if _phase != Phase.PLAYER_TURN:
		return
	# บนมือถือ Godot แปลงการแตะจอเป็นคลิกซ้ายให้อยู่แล้ว
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := _cell_at_screen_point(event.position)
		if cell != NO_CELL:
			_on_cell_clicked(cell)


# ---------------------------------------------------------------- Board setup

func tile_to_local(cell: Vector2i) -> Vector3:
	return Vector3((cell.x - 3.5) * tile_size, 0.0, (3.5 - cell.y) * tile_size)


func _build_board() -> void:
	var board := Node3D.new()
	board.name = "Board"
	add_child(board)

	# 1. Dark obsidian gothic frame
	var frame_material := StandardMaterial3D.new()
	frame_material.albedo_color = Color(0.08, 0.09, 0.13)
	frame_material.metallic = 0.45
	frame_material.roughness = 0.55
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(tile_size * 8.0 + 1.2, 0.5, tile_size * 8.0 + 1.2)
	frame_mesh.material = frame_material
	var frame := MeshInstance3D.new()
	frame.mesh = frame_mesh
	frame.position.y = -0.4
	board.add_child(frame)

	# 2. 8x8 Board Tiles with dark slate/obsidian styling
	var tile_mesh := BoxMesh.new()
	tile_mesh.size = Vector3(tile_size - 0.04, 0.3, tile_size - 0.04)
	for x in 8:
		for y in 8:
			var cell := Vector2i(x, y)
			var tile := MeshInstance3D.new()
			tile.mesh = tile_mesh
			tile.position = tile_to_local(cell) + Vector3.DOWN * 0.15
			var mat := StandardMaterial3D.new()
			mat.metallic = 0.3
			mat.roughness = 0.65
			tile.material_override = mat
			board.add_child(tile)
			_tiles[cell] = tile

	# 3. Glowing Cyan Grid Lines (BoardGlowGrid) matching combat arena
	var grid := Node3D.new()
	grid.name = "BoardGlowGrid"
	board.add_child(grid)
	var glow_color := Color(0.35, 0.78, 1.0)
	var grid_mat := StandardMaterial3D.new()
	grid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grid_mat.albedo_color = glow_color * 1.6

	var total_length := 8.0 * tile_size
	var half_len := total_length * 0.5
	var line_thickness := 0.05
	var line_height := 0.015
	var line_y := 0.005

	for i in range(9):
		var offset := -half_len + i * tile_size
		# X line (runs along X, placed at offset on Z)
		var lx := MeshInstance3D.new()
		var bx := BoxMesh.new()
		bx.size = Vector3(total_length + line_thickness, line_height, line_thickness)
		bx.material = grid_mat
		lx.mesh = bx
		lx.position = Vector3(0.0, line_y, offset)
		lx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		grid.add_child(lx)

		# Z line (runs along Z, placed at offset on X)
		var lz := MeshInstance3D.new()
		var bz := BoxMesh.new()
		bz.size = Vector3(line_thickness, line_height, total_length + line_thickness)
		bz.material = grid_mat
		lz.mesh = bz
		lz.position = Vector3(offset, line_y, 0.0)
		lz.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		grid.add_child(lz)

	# 4. Selection wireframe indicator (glowing square outline)
	_selection_indicator = Node3D.new()
	_selection_indicator.name = "SelectionIndicator"
	_selection_indicator.visible = false
	board.add_child(_selection_indicator)

	var sel_mat := StandardMaterial3D.new()
	sel_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sel_mat.albedo_color = Color(1.0, 1.0, 1.0) * 2.2 # pure white wireframe glow
	var bar_w := 0.08
	var s_half := tile_size * 0.5 - bar_w * 0.5

	var bars_data := [
		Vector3(0.0, 0.02, -s_half), Vector3(tile_size, 0.02, bar_w),
		Vector3(0.0, 0.02, s_half), Vector3(tile_size, 0.02, bar_w),
		Vector3(-s_half, 0.02, 0.0), Vector3(bar_w, 0.02, tile_size),
		Vector3(s_half, 0.02, 0.0), Vector3(bar_w, 0.02, tile_size),
	]
	for idx in range(0, bars_data.size(), 2):
		var b_pos: Vector3 = bars_data[idx]
		var b_sz: Vector3 = bars_data[idx + 1]
		var bar_mesh := MeshInstance3D.new()
		var b_box := BoxMesh.new()
		b_box.size = b_sz
		b_box.material = sel_mat
		bar_mesh.mesh = b_box
		bar_mesh.position = b_pos
		bar_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_selection_indicator.add_child(bar_mesh)

	# 5. สถาปัตยกรรมมหาวิหารลอยฟ้ามหากาพย์ (Cathedral Surroundings, Soulfire Braziers, Cosmic Monoliths)
	_build_grand_cathedral_surroundings(board)

	_refresh_tile_colors()


func _build_grand_cathedral_surroundings(board: Node3D) -> void:
	var surroundings := Node3D.new()
	surroundings.name = "CathedralSurroundings"
	board.add_child(surroundings)

	# 1. 4 Soulfire Braziers at the 4 corners of the board
	var brazier_corners := [
		Vector3(-13.2, 0.0, -13.2),
		Vector3(13.2, 0.0, -13.2),
		Vector3(-13.2, 0.0, 13.2),
		Vector3(13.2, 0.0, 13.2),
	]
	var pillar_mat := StandardMaterial3D.new()
	pillar_mat.albedo_color = Color(0.12, 0.14, 0.20)
	pillar_mat.metallic = 0.5
	pillar_mat.roughness = 0.6

	var flame_mat := StandardMaterial3D.new()
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_mat.albedo_color = Color(0.35, 0.85, 1.0) * 2.8 # Soulfire blue glow

	for pos: Vector3 in brazier_corners:
		var pillar := MeshInstance3D.new()
		var p_mesh := CylinderMesh.new()
		p_mesh.top_radius = 0.55
		p_mesh.bottom_radius = 0.75
		p_mesh.height = 2.4
		p_mesh.material = pillar_mat
		pillar.mesh = p_mesh
		pillar.position = pos + Vector3(0, 0.8, 0)
		surroundings.add_child(pillar)

		var bowl := MeshInstance3D.new()
		var b_mesh := CylinderMesh.new()
		b_mesh.top_radius = 0.85
		b_mesh.bottom_radius = 0.45
		b_mesh.height = 0.4
		b_mesh.material = pillar_mat
		bowl.mesh = b_mesh
		bowl.position = pos + Vector3(0, 2.1, 0)
		surroundings.add_child(bowl)

		var flame := MeshInstance3D.new()
		var f_mesh := SphereMesh.new()
		f_mesh.radius = 0.35
		f_mesh.height = 0.7
		f_mesh.material = flame_mat
		flame.mesh = f_mesh
		flame.position = pos + Vector3(0, 2.45, 0)
		flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		surroundings.add_child(flame)

		var light := OmniLight3D.new()
		light.light_color = Color(0.4, 0.82, 1.0)
		light.light_energy = 1.2
		light.omni_range = 14.0
		light.position = pos + Vector3(0, 2.8, 0)
		surroundings.add_child(light)

	# 2. Outer Celestial Arcane Rings (วงแหวนอักขระเวทมนตร์รอบกระดาน)
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.albedo_color = Color(0.35, 0.78, 1.0) * 1.5

	var ring_segments := 32
	var ring_r := 16.5
	for seg in range(ring_segments):
		var ang1 := float(seg) * TAU / float(ring_segments)
		var ang2 := float(seg + 1) * TAU / float(ring_segments)
		var p1 := Vector3(cos(ang1) * ring_r, -0.2, sin(ang1) * ring_r)
		var p2 := Vector3(cos(ang2) * ring_r, -0.2, sin(ang2) * ring_r)
		var bar := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(p1.distance_to(p2) + 0.1, 0.04, 0.08)
		b.material = ring_mat
		bar.mesh = b
		bar.position = (p1 + p2) * 0.5
		bar.rotation.y = atan2(p2.x - p1.x, p2.z - p1.z) + PI * 0.5
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		surroundings.add_child(bar)

	# 3. Floating Obelisks / Cosmic Ruins in the Abyss (เสาศิลาลอยเคว้งรอบกระดาน)
	var monolith_positions := [
		Vector3(-20.0, 1.5, -8.0), Vector3(-22.0, -1.0, 12.0),
		Vector3(20.0, 2.0, -10.0), Vector3(22.0, 0.5, 9.0),
		Vector3(-8.0, -2.5, -22.0), Vector3(10.0, 3.0, -23.0),
		Vector3(-9.0, 0.8, 22.0), Vector3(11.0, -1.8, 21.0),
	]
	var mono_mat := StandardMaterial3D.new()
	mono_mat.albedo_color = Color(0.10, 0.12, 0.18)
	mono_mat.metallic = 0.6
	mono_mat.roughness = 0.5

	for m_idx in range(monolith_positions.size()):
		var m_pos: Vector3 = monolith_positions[m_idx]
		var mono := MeshInstance3D.new()
		var m_box := BoxMesh.new()
		m_box.size = Vector3(1.2, 5.5 + float(m_idx % 3) * 1.5, 1.2)
		m_box.material = mono_mat
		mono.mesh = m_box
		mono.position = m_pos
		mono.rotation = Vector3(0.08 * float(m_idx % 2 == 0), 0.3 * float(m_idx), -0.06 * float(m_idx % 2 == 1))
		surroundings.add_child(mono)

		# Glowing rune strip on monolith
		var rune_strip := MeshInstance3D.new()
		var r_box := BoxMesh.new()
		r_box.size = Vector3(0.1, 3.5, 0.1)
		r_box.material = ring_mat
		rune_strip.mesh = r_box
		rune_strip.position = m_pos + Vector3(0.58, 0, 0)
		rune_strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		surroundings.add_child(rune_strip)


func _spawn_pieces() -> void:
	for x in 8:
		_add_piece(BACK_RANK[x], ChessPiece.Team.WHITE, Vector2i(x, 0))
		_add_piece(ChessPiece.Type.PAWN, ChessPiece.Team.WHITE, Vector2i(x, 1))
		_add_piece(ChessPiece.Type.PAWN, ChessPiece.Team.BLACK, Vector2i(x, 6))
		_add_piece(BACK_RANK[x], ChessPiece.Team.BLACK, Vector2i(x, 7))


func _add_piece(type: ChessPiece.Type, team: ChessPiece.Team, cell: Vector2i) -> void:
	var piece := ChessPiece.new()
	piece.setup(type, team, _board_camera_home.basis)
	piece.board_pos = cell
	piece.position = tile_to_local(cell)
	add_child(piece)
	_pieces[cell] = piece


# ---------------------------------------------------------------- Turns

func _start_player_turn() -> void:
	_phase = Phase.PLAYER_TURN
	_set_status("YOUR TURN (White) - click a piece, then a highlighted square")


func _start_enemy_turn() -> void:
	_phase = Phase.ENEMY_TURN
	_set_status("ENEMY TURN - thinking...")
	await get_tree().create_timer(enemy_think_time).timeout

	var move := _choose_enemy_move()
	if move.is_empty():
		_game_over("DRAW", "Black has no legal moves")
		return
	_execute_move(move.piece, move.to)


func _end_turn(team: ChessPiece.Team) -> void:
	# ระบบพักรบฟื้นฟูเลือด (Field Recovery +20% สำหรับหมากที่ยืนคุมพื้นที่ 2 เทิร์นโดยไม่ถูกโจมตี)
	for p: ChessPiece in _pieces.values():
		if p.team == team:
			p.turns_rested += 1
			if p.turns_rested >= 2 and p.hp < p.max_hp:
				var heal := p.max_hp * 0.20
				p.hp = minf(p.hp + heal, p.max_hp)
				p.update_hp_bar()
				p.turns_rested = 0
				print("[Chess] %s ได้รับการพักรบ ฟื้นฟู HP +%d (เหลือ %d/%d)" % [p.display_name(), int(heal), int(p.hp), int(p.max_hp)])

	if team == ChessPiece.Team.WHITE:
		_start_enemy_turn()
	else:
		_start_player_turn()


## AI หมากรุกแบบง่าย: ชอบกินตัวที่มีค่ามาก โดยใช้ตัวที่มีค่าน้อย ถ้าไม่มีอะไรให้กินก็สุ่มเดิน
func _choose_enemy_move() -> Dictionary:
	var best := {}
	var best_score := -INF
	for piece: ChessPiece in _pieces.values():
		if piece.team != ChessPiece.Team.BLACK:
			continue
		for to in ChessRules.get_legal_moves(_pieces, piece):
			var score := randf()
			var victim: ChessPiece = _pieces.get(to)
			if victim != null:
				score += victim.value() * 10.0 - piece.value()
			if score > best_score:
				best_score = score
				best = {"piece": piece, "to": to}
	return best


func _on_cell_clicked(cell: Vector2i) -> void:
	if _selected != null and cell in _legal_moves:
		_execute_move(_selected, cell)
		return

	var clicked: ChessPiece = _pieces.get(cell)
	if clicked != null and clicked.team == ChessPiece.Team.WHITE:
		_selected = clicked
		_legal_moves = ChessRules.get_legal_moves(_pieces, clicked)
		_set_status("%s  (HP %d/%d) - %d moves" % [clicked.display_name(), clicked.hp, clicked.max_hp, _legal_moves.size()])
	else:
		_clear_selection()
	_refresh_tile_colors()


func _clear_selection() -> void:
	_selected = null
	_legal_moves.clear()
	_refresh_tile_colors()


func _execute_move(piece: ChessPiece, to: Vector2i) -> void:
	_clear_selection()
	_phase = Phase.ANIMATING
	var defender: ChessPiece = _pieces.get(to)

	if defender == null:
		print("[Chess] %s เดินไป %s" % [piece.display_name(), _cell_name(to)])
		await _move_piece(piece, to)
		_end_turn(piece.team)
		return

	print("[Chess] %s บุก %s ที่ %s!" % [piece.display_name(), defender.display_name(), _cell_name(to)])
	# พุ่งเข้าไปครึ่งทางก่อน แล้วค่อยตัดเข้าฉากดวล
	await _slide_piece(piece, tile_to_local(piece.board_pos).lerp(tile_to_local(to), 0.5))
	var winner := await _run_duel(piece, defender, to)
	if _phase == Phase.GAME_OVER:
		return
	if winner == piece:
		await _move_piece(piece, to)
	_end_turn(piece.team)


func _move_piece(piece: ChessPiece, to: Vector2i) -> void:
	_pieces.erase(piece.board_pos)
	_pieces[to] = piece
	piece.board_pos = to
	piece.has_moved = true
	piece.turns_rested = 0
	await _slide_piece(piece, tile_to_local(to))

	var last_rank := 7 if piece.team == ChessPiece.Team.WHITE else 0
	if piece.type == ChessPiece.Type.PAWN and to.y == last_rank:
		piece.promote_to_queen()
		print("[Chess] %s เลื่อนขั้นเป็น Queen!" % piece.display_name())


func _remove_piece(piece: ChessPiece) -> void:
	if _pieces.get(piece.board_pos) == piece:
		_pieces.erase(piece.board_pos)
	piece.queue_free()


func _game_over(title: String, detail: String) -> void:
	_phase = Phase.GAME_OVER
	_show_banner(title, 0.0)
	_set_status("%s - press R or tap to play again" % detail)


# ---------------------------------------------------------------- Duel

## ดวลกันจริงในสังเวียน แล้วคืนค่าหมากที่ชนะ
func _run_duel(attacker: ChessPiece, defender: ChessPiece, cell: Vector2i) -> ChessPiece:
	_phase = Phase.DUEL
	_duel_over = false
	var white := attacker if attacker.team == ChessPiece.Team.WHITE else defender
	var black := defender if white == attacker else attacker

	player_fighter.setup_for_duel(white.display_name(), white.hp, white.max_hp, white.type, true)
	enemy_fighter.setup_for_duel(black.display_name(), black.hp, black.max_hp, black.type, false)
	_show_arena_theme(ARENA_THEMES[defender.type])
	_set_status("DUEL: %s  vs  %s" % [white.display_name(), black.display_name()])

	await _transition_to_arena(cell)
	var player_won: bool = await _duel_finished

	# HP ที่เหลือจากการดวลติดตัวหมากกลับไปบนกระดาน
	white.hp = player_fighter.hp
	black.hp = enemy_fighter.hp
	white.update_hp_bar()
	black.update_hp_bar()
	var winner := white if player_won else black
	var loser := black if player_won else white

	await _transition_to_board()
	print("[Chess] %s ชนะ! %s ออกจากกระดาน" % [winner.display_name(), loser.display_name()])
	_remove_piece(loser)

	if loser.type == ChessPiece.Type.KING:
		if player_won:
			_game_over("VICTORY", "The Black King has fallen")
		else:
			_game_over("DEFEAT", "Your King has fallen")
	return winner


func _on_fighter_died(fighter: FighterController) -> void:
	if _phase != Phase.DUEL or _duel_over:
		return
	_duel_over = true
	var player_won := fighter == enemy_fighter
	_show_banner("VICTORY" if player_won else "DEFEAT", duel_end_delay)
	await get_tree().create_timer(duel_end_delay).timeout
	_duel_finished.emit(player_won)


func _transition_to_arena(cell: Vector2i) -> void:
	var square := to_global(tile_to_local(cell))

	# 1) กล้องดิ่งลงไปที่ช่อง
	await _tween_board_camera(_dive_transform(square), dive_duration)

	# 2) สังเวียนยกขึ้นมาจากใต้กระดาน (ซ่อนหมากบนกระดานระหว่างดวล)
	_set_pieces_visible(false)
	_place_fighters()
	arena.global_position = square + Vector3.DOWN * arena_hidden_depth
	arena.reset_physics_interpolation()
	arena.visible = true
	var rise := _create_physics_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rise.tween_property(arena, "global_position", square + Vector3.UP * arena_floor_offset, rise_duration)
	await rise.finished

	# เปิดการทำงานของ arena เพื่อให้อัปเดต physics transform ก่อนจับภาพกล้อง
	arena.process_mode = Node.PROCESS_MODE_INHERIT
	await get_tree().physics_frame

	# 3) ไหลกล้องไปที่มุมข้ามไหล่ แล้วสลับไปใช้กล้องดวลตัวจริง
	duel_camera.snap_to_target()
	await _tween_board_camera(duel_camera.global_transform, blend_duration)
	duel_camera.make_current()
	duel_camera.reset_physics_interpolation()

	_set_combat_active(true)
	_show_banner("FIGHT!", 0.8)


func _transition_to_board() -> void:
	_set_combat_active(false)
	# ลบกระสุน/ระเบิด/เอฟเฟกต์ที่ค้างอยู่ ไม่ให้ไปโผล่ในการดวลรอบหน้า
	get_tree().call_group(SkillEffects.GROUP, "queue_free")
	board_camera.global_transform = duel_camera.global_transform
	board_camera.reset_physics_interpolation()
	board_camera.make_current()

	var square := arena.global_position
	await _tween_board_camera(_dive_transform(square), blend_duration)

	var sink := _create_physics_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	sink.tween_property(arena, "global_position", square + Vector3.DOWN * arena_hidden_depth, rise_duration)
	await sink.finished
	arena.visible = false
	_set_pieces_visible(true)
	_apply_lighting(BOARD_THEME)

	await _tween_board_camera(_board_camera_home, dive_duration)


func _place_fighters() -> void:
	for fighter in [player_fighter, enemy_fighter]:
		fighter.velocity = Vector3.ZERO
		fighter.rotation = Vector3.ZERO
	player_fighter.position = Vector3(0.0, 0.0, 2.5)
	enemy_fighter.position = Vector3(0.0, 0.0, -1.5)


## ใส่ฉากสังเวียนธีม low-poly (Step 8) เข้าไปในสังเวียน แล้วเปลี่ยนท้องฟ้า/หมอก/แสงตามธีม
func _show_arena_theme(theme: String) -> void:
	if not _themed_arenas.has(theme):
		var visuals := LowPolyArena.build(theme, 3, 7, true, false)
		arena.add_child(visuals)
		_themed_arenas[theme] = visuals
	for key: String in _themed_arenas:
		_themed_arenas[key].visible = key == theme
	for node in plain_arena_visuals:
		node.visible = false
	_apply_lighting(theme)


func _apply_lighting(theme_name: String) -> void:
	var theme: Dictionary = LowPolyArena.THEMES[theme_name]
	if not _theme_environments.has(theme_name):
		var holder := LowPolyArena.create_environment(theme)
		_theme_environments[theme_name] = holder.environment
		holder.free()
	_world_environment.environment = _theme_environments[theme_name]
	if sun != null:
		sun.light_color = theme.sun
		sun.light_energy = maxf(theme.sun_energy, 0.6)


## เปิด/ปิดทุกอย่างของการต่อสู้: ตัวละคร, AI, กล้องดวล, ปุ่มควบคุม และ UI ต่อสู้
func _set_combat_active(active: bool) -> void:
	arena.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	combat_input.set_input_enabled(active)
	combat_hud.visible = active
	_status_label.visible = not active
	if _clock_panel != null:
		_clock_panel.visible = not active


func _set_pieces_visible(value: bool) -> void:
	for piece: ChessPiece in _pieces.values():
		piece.visible = value


# ---------------------------------------------------------------- Camera / tween helpers

func _look_transform(from: Vector3, target: Vector3) -> Transform3D:
	return Transform3D(Basis.IDENTITY, from).looking_at(target, Vector3.UP)


func _dive_transform(square: Vector3) -> Transform3D:
	return _look_transform(square + Vector3(0.0, 7.0, 5.0), square)


func _create_physics_tween() -> Tween:
	# อัปเดตใน physics tick ให้เข้ากับ Physics Interpolation ภาพจะได้ไม่กระตุก
	return create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)


func _tween_board_camera(to: Transform3D, duration: float) -> void:
	var from := board_camera.global_transform
	var tween := _create_physics_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(weight: float) -> void: board_camera.global_transform = from.interpolate_with(to, weight), 0.0, 1.0, duration)
	await tween.finished


func _slide_piece(piece: ChessPiece, target_position: Vector3) -> void:
	var tween := _create_physics_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(piece, "position", target_position, 0.35)
	await tween.finished


# ---------------------------------------------------------------- Picking / visuals

func _cell_at_screen_point(screen_point: Vector2) -> Vector2i:
	var origin := board_camera.project_ray_origin(screen_point)
	var direction := board_camera.project_ray_normal(screen_point)
	var hit: Variant = Plane(Vector3.UP, global_position.y).intersects_ray(origin, direction)
	if hit == null:
		return NO_CELL
	var local := to_local(hit)
	var cell := Vector2i(floori(local.x / tile_size + 4.0), floori(4.0 - local.z / tile_size))
	return cell if ChessRules.is_inside(cell) else NO_CELL


func _refresh_tile_colors() -> void:
	for cell: Vector2i in _tiles:
		var tile: MeshInstance3D = _tiles[cell]
		var mat: StandardMaterial3D = tile.material_override
		var is_selected := _selected != null and cell == _selected.board_pos
		var is_legal := cell in _legal_moves

		var base_color: Color = light_tile_color if (cell.x + cell.y) % 2 == 1 else dark_tile_color
		if is_selected:
			mat.albedo_color = selected_color
			mat.emission_enabled = true
			mat.emission = selected_color * 1.5
		elif is_legal:
			var is_capture := _pieces.has(cell)
			var c: Color = capture_color if is_capture else move_color
			mat.albedo_color = c
			mat.emission_enabled = true
			mat.emission = c * 1.8
		else:
			mat.albedo_color = base_color
			mat.emission_enabled = false

	if _selection_indicator != null:
		if _selected != null:
			_selection_indicator.visible = true
			_selection_indicator.position = tile_to_local(_selected.board_pos)
		else:
			_selection_indicator.visible = false


func _cell_name(cell: Vector2i) -> String:
	return "%s%d" % ["abcdefgh"[cell.x], cell.y + 1]


func _create_board_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)

	# 1. Rapid Chess Clock Bar (มุมมองนาฬิกาแข่งหมากรุกมาตรฐาน)
	_clock_panel = PanelContainer.new()
	_clock_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_clock_panel.offset_top = 10
	_clock_panel.offset_left = 32
	_clock_panel.offset_right = -32
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.08, 0.12, 0.85)
	panel_style.set_border_width_all(1)
	panel_style.border_color = Color(0.35, 0.78, 1.0, 0.6)
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	_clock_panel.add_theme_stylebox_override("panel", panel_style)
	layer.add_child(_clock_panel)

	var hbox := HBoxContainer.new()
	_clock_panel.add_child(hbox)

	_white_clock_label = Label.new()
	_white_clock_label.text = "WHITE 15:00"
	_white_clock_label.add_theme_font_size_override("font_size", 16)
	_white_clock_label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	hbox.add_child(_white_clock_label)

	var clock_spacer := Control.new()
	clock_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(clock_spacer)

	var mode_label := Label.new()
	mode_label.text = "⚔️ STANDARD MATCH (8x8) ⚔️"
	mode_label.add_theme_font_size_override("font_size", 13)
	mode_label.add_theme_color_override("font_color", Color(0.4, 0.82, 1.0))
	hbox.add_child(mode_label)

	var clock_spacer2 := Control.new()
	clock_spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(clock_spacer2)

	_black_clock_label = Label.new()
	_black_clock_label.text = "BLACK 15:00"
	_black_clock_label.add_theme_font_size_override("font_size", 16)
	_black_clock_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
	hbox.add_child(_black_clock_label)

	# 2. Status Label (ข้อความแจ้งเตือนคำสั่งเดินหมาก)
	_status_label = Label.new()
	_status_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_status_label.offset_top = 58
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 22)
	_status_label.add_theme_constant_override("outline_size", 8)
	_status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	layer.add_child(_status_label)

	_banner_label = Label.new()
	_banner_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_label.add_theme_font_size_override("font_size", 80)
	_banner_label.add_theme_constant_override("outline_size", 16)
	_banner_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner_label.modulate.a = 0.0
	layer.add_child(_banner_label)


func _set_status(text: String) -> void:
	_status_label.text = text


## hold_time = 0 ค้างไว้ตลอด
func _show_banner(text: String, hold_time: float) -> void:
	if _banner_tween != null:
		_banner_tween.kill()
	_banner_label.text = text
	_banner_label.modulate.a = 1.0
	if hold_time > 0.0:
		_banner_tween = create_tween()
		_banner_tween.tween_interval(hold_time)
		_banner_tween.tween_property(_banner_label, "modulate:a", 0.0, 0.4)
