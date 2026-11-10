class_name ChessPiece
extends Node3D
## Step 4: ตัวหมาก 1 ตัว มีชนิด ฝ่าย ตำแหน่งบนกระดาน และ HP ของตัวเอง (HP ค้างข้ามการดวลแต่ละครั้ง)

const Pixel25DCharacter = preload("res://scripts/art/pixel_25d_character.gd")

enum Type { PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING }
enum Team { WHITE, BLACK }

const MAX_HP := {
	Type.PAWN: 120.0,
	Type.KNIGHT: 160.0,
	Type.BISHOP: 160.0,
	Type.ROOK: 220.0,
	Type.QUEEN: 260.0,
	Type.KING: 320.0,
}
## ค่าความสำคัญของหมาก (AI ใช้เลือกว่าจะกินตัวไหน)
const VALUES := {
	Type.PAWN: 1,
	Type.KNIGHT: 3,
	Type.BISHOP: 3,
	Type.ROOK: 5,
	Type.QUEEN: 9,
	Type.KING: 100,
}
const BASE_COLORS := {
	Team.WHITE: Color(0.9, 0.85, 0.7),
	Team.BLACK: Color(0.8, 0.15, 0.2),
}
## ย้อมสีโมเดลฝ่ายดำให้เข้มกว่าฝ่ายขาว
const BLACK_TINT := Color(0.45, 0.42, 0.5)
## ย่อโมเดลให้พอดีช่องกระดาน (ช่องละ 3 เมตร)
const MODEL_SCALE := 0.75
const BAR_WIDTH := 2.0

var type: Type = Type.PAWN
var team: Team = Team.WHITE
var board_pos := Vector2i.ZERO
var has_moved := false
var turns_rested := 0
var max_hp := 0.0
var hp := 0.0

var _bar_facing := Basis.IDENTITY
var _visuals: Node3D
var _bar_fill: MeshInstance3D
var _bar_material: StandardMaterial3D


## เรียกก่อน add_child: bar_facing = ทิศของกล้องกระดาน เพื่อให้หลอด HP หันเข้าหากล้อง
func setup(new_type: Type, new_team: Team, bar_facing: Basis) -> void:
	type = new_type
	team = new_team
	max_hp = MAX_HP[type]
	hp = max_hp
	_bar_facing = bar_facing
	_build_visuals()


func display_name() -> String:
	return "%s %s" % ["White" if team == Team.WHITE else "Black", Type.keys()[type].capitalize()]


func value() -> int:
	return VALUES[type]


## เดินถึงแถวสุดท้าย: Pawn กลายเป็น Queen (HP คงสัดส่วนเดิม)
func promote_to_queen() -> void:
	var ratio := hp / max_hp
	type = Type.QUEEN
	max_hp = MAX_HP[type]
	hp = max_hp * ratio
	_build_visuals()


func update_hp_bar() -> void:
	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	_bar_fill.scale.x = maxf(ratio, 0.001)
	_bar_fill.position.x = -BAR_WIDTH * (1.0 - ratio) * 0.5
	# อัปเดตทันที ไม่ต้องรอ physics tick ถัดไป (เพราะเปิด Physics Interpolation ไว้)
	_bar_fill.reset_physics_interpolation()
	_bar_material.albedo_color = Color(0.9, 0.15, 0.1).lerp(Color(0.2, 0.85, 0.25), ratio)


func _build_visuals() -> void:
	if _visuals != null:
		_visuals.free()
	_visuals = Node3D.new()
	add_child(_visuals)

	# ถ้าเป็น Pawn ให้ใช้โมเดล 3D Knight เต็มรูปแบบ (หันหน้าเข้าหาคู่ต่อสู้)
	# ถ้าเป็นตัวอื่น ให้ใช้สไปรต์พิกเซลอาร์ต 2.5D คมชัด
	if type == Type.PAWN:
		var knight := Knight3DCharacter.build(team == Team.WHITE)
		_visuals.add_child(knight)
		if team == Team.BLACK:
			knight.rotation.y = PI
		var ap := knight.get_animation_player()
		if ap != null and ap.has_animation("idle"):
			ap.play("idle")
	else:
		var type_name := LowPolyCharacters.type_name(type)
		var sprite := Pixel25DCharacter.build_sprite(type_name, team == Team.WHITE, 1.85)
		_visuals.add_child(sprite)

	# ฐานเรืองแสงบอกฝ่าย
	var base := LowPoly.add(_visuals, LowPoly.cylinder(0.85, 0.9, 0.08, 16), LowPoly.glow_material(BASE_COLORS[team], 0.9), Vector3(0, 0.04, 0))
	base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var height: float = 1.85

	# หลอด HP: กล่องบาง ๆ 2 ชั้น (พื้นหลังเข้ม + ส่วนที่เหลือ) หมุนให้หันเข้าหากล้องกระดาน
	var bar := Node3D.new()
	bar.position.y = height + 0.5
	bar.basis = _bar_facing
	_visuals.add_child(bar)

	var background_material := StandardMaterial3D.new()
	background_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	background_material.albedo_color = Color(0.05, 0.05, 0.05)
	var background_mesh := BoxMesh.new()
	background_mesh.size = Vector3(BAR_WIDTH + 0.08, 0.26, 0.02)
	background_mesh.material = background_material
	var background := MeshInstance3D.new()
	background.mesh = background_mesh
	background.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bar.add_child(background)

	_bar_material = StandardMaterial3D.new()
	_bar_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var fill_mesh := BoxMesh.new()
	fill_mesh.size = Vector3(BAR_WIDTH, 0.18, 0.02)
	fill_mesh.material = _bar_material
	_bar_fill = MeshInstance3D.new()
	_bar_fill.mesh = fill_mesh
	_bar_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bar_fill.position.z = 0.02  # ขยับเข้าหากล้องนิดนึง ไม่ให้จมในพื้นหลัง
	bar.add_child(_bar_fill)

	update_hp_bar()
