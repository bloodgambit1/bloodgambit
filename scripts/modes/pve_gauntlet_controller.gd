class_name PvEGauntletController
extends Node3D
## โหมด PvE Gauntlet: "Pawn's Rebellion" (กบฏเบี้ยท้าชิงบัลลังก์)
## - เดินได้อย่างอิสระ 360 องศา ไม่ติดช่องกระดาน
## - ผู้เล่นเป็นตัวเบี้ย (Pawn) เสมอ พร้อม 1 สกิลชั้นสูงที่เลือกยืมมา (Knight Leap / Rook Charge / Bishop Cross / Queen Cyclone)
## - ต่อสู้กับฝูงเบี้ยปีศาจแบบตะลุมบอน ➔ องครักษ์ ➔ บอสยักษ์ The Cursed King

@export var player_pawn: FighterController
@export var camera: Camera3D
@export var arena_root: Node3D

enum BorrowedSkillType { KNIGHT_LEAP, ROOK_CHARGE, BISHOP_CROSS, QUEEN_CYCLONE }
var selected_borrowed_skill := BorrowedSkillType.KNIGHT_LEAP

var wave := 1
var enemies_alive: Array[FighterController] = []
var wave_active := false
var _wave_label: Label
var _status_ui: CanvasLayer

func _ready() -> void:
	_create_pve_ui()
	_setup_player()
	start_wave(1)


func _create_pve_ui() -> void:
	_status_ui = CanvasLayer.new()
	_status_ui.layer = 10
	add_child(_status_ui)

	# ป้ายบอก Wave ด้านบน
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_top = 16
	panel.offset_left = 60
	panel.offset_right = -60
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.11, 0.85)
	style.border_color = Color(0.85, 0.25, 0.25, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	_status_ui.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	_wave_label = Label.new()
	_wave_label.text = "💀 PVE GAUNTLET: WAVE 1 (PAWN HORDE) 💀"
	_wave_label.add_theme_font_size_override("font_size", 18)
	_wave_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	hbox.add_child(_wave_label)

	# ปุ่มกลับหน้าเมนู
	var back_btn := Button.new()
	back_btn.text = "← MENU"
	back_btn.offset_left = 20
	back_btn.offset_top = 20
	back_btn.custom_minimum_size = Vector2(80, 36)
	back_btn.pressed.connect(_on_back_pressed)
	_status_ui.add_child(back_btn)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _setup_player() -> void:
	if player_pawn == null:
		return
	player_pawn.setup_for_duel("White Pawn", 160.0, 160.0, ChessPiece.Type.PAWN, true)

	# ติดตั้งสกิลพิเศษที่ยืมมา
	if player_pawn.skills != null:
		var skill_list: Array[Skill] = []
		match selected_borrowed_skill:
			BorrowedSkillType.KNIGHT_LEAP:
				skill_list.append(KnightSkills.LeapStrike.new())
			BorrowedSkillType.ROOK_CHARGE:
				skill_list.append(RookSkills.RamCharge.new())
			BorrowedSkillType.BISHOP_CROSS:
				skill_list.append(BishopSkills.DiagonalSmite.new())
			BorrowedSkillType.QUEEN_CYCLONE:
				skill_list.append(QueenSkills.BladeStorm.new())
		player_pawn.skills.load_skills(skill_list)


func start_wave(w: int) -> void:
	wave = w
	wave_active = true
	match wave:
		1:
			_wave_label.text = "💀 WAVE 1: PAWN HORDE (กำจัดเบี้ยปีศาจ 4 ตัว) 💀"
			_spawn_enemy_wave(4, ChessPiece.Type.PAWN)
		2:
			_wave_label.text = "💀 WAVE 2: VANGUARD (เบี้ย 5 ตัว + ม้าศึก Knight 1 ตัว) 💀"
			_spawn_enemy_wave(5, ChessPiece.Type.PAWN)
			_spawn_single_enemy(Vector3(0, 0, -8), ChessPiece.Type.KNIGHT, "Elite Knight")
		3:
			_wave_label.text = "👑 FINAL WAVE: THE CURSED MONARCH (บอสยักษ์ราชาปีศาจ) 👑"
			_spawn_single_enemy(Vector3(0, 0, -8), ChessPiece.Type.KING, "The Cursed King", 450.0)


func _spawn_enemy_wave(count: int, type: ChessPiece.Type) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in count:
		var ang := float(i) * TAU / float(count)
		var spawn_pos := Vector3(cos(ang) * 9.0, 0.0, sin(ang) * 9.0 - 4.0)
		_spawn_single_enemy(spawn_pos, type, "Corrupted Pawn #%d" % (i + 1), 80.0)


func _spawn_single_enemy(pos: Vector3, type: ChessPiece.Type, display_name: String, hp: float = 120.0) -> void:
	var enemy := CharacterBody3D.new() as FighterController
	enemy.set_script(preload("res://scripts/combat/fighter_controller.gd"))
	enemy.fighter_name = display_name
	enemy.is_white_faction = false
	enemy.target = player_pawn
	add_child(enemy)
	enemy.position = pos
	enemy.setup_for_duel(display_name, hp, hp, type, false)

	# AI Controller
	var ai := Node.new()
	ai.set_script(preload("res://scripts/combat/combat_ai.gd"))
	ai.set("fighter", enemy)
	enemy.add_child(ai)

	enemy.died.connect(_on_enemy_killed.bind(enemy))
	enemies_alive.append(enemy)


func _on_enemy_killed(enemy: FighterController) -> void:
	enemies_alive.erase(enemy)
	if enemies_alive.is_empty() and wave_active:
		wave_active = false
		if wave < 3:
			await get_tree().create_timer(2.0).timeout
			start_wave(wave + 1)
		else:
			_wave_label.text = "🏆 VICTORY! THE MONARCH HAS FALLEN! 🏆"
