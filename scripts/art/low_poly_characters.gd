class_name LowPolyCharacters
extends RefCounted
## Step 8: สร้างตัวละครหมากรุกแบบ low-poly ด้วยโค้ด (หันหน้าไปทางแกน -Z เหมือนตัวละครในเกม)
## build("pawn" | "knight" | "rook" | "bishop" | "queen" | "king", t_pose)
## ส่วนสูงโดยประมาณ: Pawn 1.6 / Knight 2.9 (ขี่หมาป่า) / Rook 3.2 / Bishop 2.7 / Queen 2.8 / King 2.9 เมตร

## ความสูงจริงของโมเดล (ใช้วางหลอด HP / ย่อขนาดในเกม)
const MODEL_HEIGHTS := {"pawn": 1.65, "knight": 3.0, "rook": 3.4, "bishop": 3.05, "queen": 2.9, "king": 2.95}
## ความสูงสำหรับจัดมุมกล้องตอนถ่ายภาพ (เผื่อพื้นที่อาวุธ)
const HEIGHTS := {"pawn": 1.6, "knight": 3.4, "rook": 3.9, "bishop": 2.7, "queen": 2.8, "king": 2.9}


## ชื่อโมเดลตามชนิดหมากในเกม
static func type_name(piece_type: ChessPiece.Type) -> String:
	return ChessPiece.Type.keys()[piece_type].to_lower()


static func build(type: String, t_pose := false) -> Node3D:
	var root := Node3D.new()
	root.name = type.capitalize()
	match type:
		"pawn": _pawn(root, t_pose)
		"knight": _knight(root)
		"rook": _rook(root)
		"bishop": _bishop(root)
		"queen": _queen(root)
		"king": _king(root)
	return root


# ---------------------------------------------------------------- วัสดุที่ใช้ร่วมกัน

static func _steel() -> Material:
	return LowPoly.material(Color(0.55, 0.57, 0.62), 0.45, 0.8)


static func _dark_steel() -> Material:
	return LowPoly.material(Color(0.14, 0.14, 0.17), 0.5, 0.7)


static func _gold() -> Material:
	return LowPoly.material(Color(0.9, 0.68, 0.22), 0.35, 0.9)


static func _skin() -> Material:
	return LowPoly.material(Color(0.82, 0.66, 0.55), 0.8)


## ดาบ: ใบดาบชี้ขึ้นแกน +Y จากจุด grip
static func _sword(parent: Node3D, position: Vector3, rotation_degrees: Vector3, blade_length: float,
		blade_width: float, blade_material: Material, guard_material: Material) -> Node3D:
	var sword := Node3D.new()
	sword.position = position
	sword.rotation_degrees = rotation_degrees
	parent.add_child(sword)
	LowPoly.add(sword, LowPoly.box(Vector3(blade_width, blade_length, blade_width * 0.25)), blade_material, Vector3(0, blade_length * 0.5 + 0.1, 0))
	LowPoly.add(sword, LowPoly.cylinder(0.0, blade_width * 0.5, blade_width * 0.9, 4), blade_material,
		Vector3(0, blade_length + 0.1 + blade_width * 0.45, 0), Vector3(0, 45, 0), Vector3(1, 1, 0.25))
	LowPoly.add(sword, LowPoly.box(Vector3(blade_width * 3.2, blade_width * 0.5, blade_width * 0.6)), guard_material, Vector3(0, 0.1, 0))
	LowPoly.add(sword, LowPoly.cylinder(0.03, 0.03, 0.25, 5), LowPoly.material(Color(0.25, 0.15, 0.1)), Vector3(0, -0.05, 0))
	return sword


# ---------------------------------------------------------------- Pawn

static func _pawn(root: Node3D, t_pose: bool) -> void:
	var body := LowPoly.material(Color(0.2, 0.45, 0.78), 0.7)
	var iron := LowPoly.material(Color(0.42, 0.44, 0.48), 0.55, 0.7)
	var dark := LowPoly.material(Color(0.12, 0.12, 0.14))
	# ลำตัวแคปซูลเหลี่ยม + ขาสั้น ๆ
	LowPoly.add(root, LowPoly.box(Vector3(0.18, 0.32, 0.2)), dark, Vector3(-0.16, 0.16, 0))
	LowPoly.add(root, LowPoly.box(Vector3(0.18, 0.32, 0.2)), dark, Vector3(0.16, 0.16, 0))
	LowPoly.add(root, LowPoly.cylinder(0.36, 0.42, 0.75, 8), body, Vector3(0, 0.68, 0), Vector3.ZERO, Vector3.ONE, 0.02, 1)
	LowPoly.add(root, LowPoly.sphere(0.42, 8, 4), body, Vector3(0, 0.36, 0), Vector3.ZERO, Vector3(1, 0.5, 1))
	# หมวกเหล็กบุบ ๆ
	LowPoly.add(root, LowPoly.sphere(0.4, 7, 4), iron, Vector3(0, 1.12, 0), Vector3.ZERO, Vector3(1, 0.95, 1), 0.035, 2)
	LowPoly.add(root, LowPoly.cylinder(0.44, 0.44, 0.08, 8), iron, Vector3(0, 0.98, 0), Vector3.ZERO, Vector3.ONE, 0.02, 3)
	LowPoly.add(root, LowPoly.cylinder(0.0, 0.07, 0.22, 4), iron, Vector3(0, 1.58, 0))
	LowPoly.add(root, LowPoly.box(Vector3(0.36, 0.05, 0.06)), dark, Vector3(0, 1.07, -0.37))

	var shield := LowPoly.material(Color(0.4, 0.26, 0.15), 0.85)
	if t_pose:
		LowPoly.add(root, LowPoly.box(Vector3(0.5, 0.14, 0.14)), body, Vector3(-0.62, 0.86, 0))
		LowPoly.add(root, LowPoly.box(Vector3(0.5, 0.14, 0.14)), body, Vector3(0.62, 0.86, 0))
		LowPoly.add(root, LowPoly.cylinder(0.32, 0.32, 0.06, 8), shield, Vector3(-0.92, 0.86, 0), Vector3(0, 0, 90), Vector3.ONE, 0.03, 4)
		LowPoly.add(root, LowPoly.sphere(0.08, 5, 3), iron, Vector3(-0.96, 0.86, 0))
		_sword(root, Vector3(0.92, 0.86, 0), Vector3.ZERO, 0.55, 0.08, _steel(), iron)
	else:
		LowPoly.add(root, LowPoly.box(Vector3(0.14, 0.4, 0.14)), body, Vector3(-0.44, 0.78, -0.12), Vector3(-30, 0, 15))
		LowPoly.add(root, LowPoly.box(Vector3(0.14, 0.4, 0.14)), body, Vector3(0.44, 0.82, -0.12), Vector3(-50, 0, -10))
		LowPoly.add(root, LowPoly.cylinder(0.32, 0.32, 0.06, 8), shield, Vector3(-0.5, 0.8, -0.35), Vector3(80, 25, 0), Vector3.ONE, 0.03, 4)
		LowPoly.add(root, LowPoly.sphere(0.08, 5, 3), iron, Vector3(-0.52, 0.8, -0.4))
		_sword(root, Vector3(0.48, 0.85, -0.35), Vector3(-55, 0, -20), 0.55, 0.08, _steel(), iron)


# ---------------------------------------------------------------- Knight (ขี่หมาป่าเกราะ)

static func _knight(root: Node3D) -> void:
	var fur := LowPoly.material(Color(0.22, 0.2, 0.21), 0.95)
	var armor := _dark_steel()
	var eye := LowPoly.glow_material(Color(1.0, 0.45, 0.1), 4.0)
	# หมาป่า
	LowPoly.add(root, LowPoly.box(Vector3(0.9, 0.8, 2.0)), fur, Vector3(0, 1.15, 0), Vector3(-6, 0, 0), Vector3.ONE, 0.1, 10)
	LowPoly.add(root, LowPoly.box(Vector3(1.0, 0.25, 1.2)), armor, Vector3(0, 1.58, 0.05), Vector3(-6, 0, 0), Vector3.ONE, 0.05, 11)
	LowPoly.add(root, LowPoly.box(Vector3(0.62, 0.6, 0.75)), fur, Vector3(0, 1.55, -1.15), Vector3(-10, 0, 0), Vector3.ONE, 0.06, 12)
	LowPoly.add(root, LowPoly.box(Vector3(0.36, 0.3, 0.55)), fur, Vector3(0, 1.42, -1.65), Vector3(5, 0, 0), Vector3.ONE, 0.04, 13)
	LowPoly.add(root, LowPoly.box(Vector3(0.64, 0.18, 0.5)), armor, Vector3(0, 1.85, -1.15), Vector3(-10, 0, 0))
	for side in [-1.0, 1.0]:
		LowPoly.add(root, LowPoly.cylinder(0.0, 0.1, 0.3, 4), fur, Vector3(0.2 * side, 2.0, -1.0))
		LowPoly.add(root, LowPoly.box(Vector3(0.08, 0.06, 0.04)), eye, Vector3(0.17 * side, 1.62, -1.53))
		LowPoly.add(root, LowPoly.box(Vector3(0.24, 1.0, 0.26)), fur, Vector3(0.32 * side, 0.52, -0.7), Vector3(-25, 0, 0), Vector3.ONE, 0.04, 14)
		LowPoly.add(root, LowPoly.box(Vector3(0.26, 1.0, 0.28)), fur, Vector3(0.32 * side, 0.52, 0.72), Vector3(22, 0, 0), Vector3.ONE, 0.04, 15)
	LowPoly.add(root, LowPoly.box(Vector3(0.18, 0.18, 0.9)), fur, Vector3(0, 1.3, 1.35), Vector3(-25, 0, 0))

	# ผู้ขี่ สวมหมวกทรงหัวม้า
	LowPoly.add(root, LowPoly.cylinder(0.34, 0.28, 0.75, 7), armor, Vector3(0, 2.1, 0.05), Vector3(-10, 0, 0), Vector3.ONE, 0.03, 16)
	for side in [-1.0, 1.0]:
		LowPoly.add(root, LowPoly.box(Vector3(0.18, 0.55, 0.22)), armor, Vector3(0.5 * side, 1.62, 0.0), Vector3(0, 0, 20 * side))
		LowPoly.add(root, LowPoly.sphere(0.18, 6, 3), armor, Vector3(0.36 * side, 2.38, 0.05), Vector3.ZERO, Vector3(1, 0.8, 1), 0.02, 17)
	LowPoly.add(root, LowPoly.box(Vector3(0.3, 0.38, 0.4)), armor, Vector3(0, 2.68, 0.05), Vector3(-15, 0, 0), Vector3.ONE, 0.02, 18)
	LowPoly.add(root, LowPoly.box(Vector3(0.24, 0.24, 0.42)), armor, Vector3(0, 2.6, -0.3), Vector3(25, 0, 0), Vector3.ONE, 0.02, 19)
	LowPoly.add(root, LowPoly.box(Vector3(0.06, 0.32, 0.45)), _gold(), Vector3(0, 2.9, 0.1), Vector3(-15, 0, 0))
	LowPoly.add(root, LowPoly.box(Vector3(0.26, 0.04, 0.04)), eye, Vector3(0, 2.66, -0.16))
	# ง้าวยาวชี้ไปข้างหน้า
	var halberd := Node3D.new()
	halberd.position = Vector3(0.45, 2.15, -0.1)
	halberd.rotation_degrees = Vector3(-72, 0, 0)
	root.add_child(halberd)
	LowPoly.add(halberd, LowPoly.cylinder(0.04, 0.04, 3.2, 5), LowPoly.material(Color(0.25, 0.17, 0.1)), Vector3(0, 0.9, 0))
	LowPoly.add(halberd, LowPoly.box(Vector3(0.05, 0.45, 0.4)), _steel(), Vector3(0, 2.25, 0.2), Vector3.ZERO, Vector3.ONE, 0.03, 20)
	LowPoly.add(halberd, LowPoly.cylinder(0.0, 0.07, 0.45, 4), _steel(), Vector3(0, 2.7, 0))


# ---------------------------------------------------------------- Rook (ป้อมเดินได้)

static func _rook(root: Node3D) -> void:
	var stone := LowPoly.material(Color(0.3, 0.2, 0.38), 0.75, 0.2)
	var gold := _gold()
	LowPoly.add(root, LowPoly.box(Vector3(0.55, 0.45, 0.6)), stone, Vector3(-0.45, 0.22, 0), Vector3.ZERO, Vector3.ONE, 0.04, 30)
	LowPoly.add(root, LowPoly.box(Vector3(0.55, 0.45, 0.6)), stone, Vector3(0.45, 0.22, 0), Vector3.ZERO, Vector3.ONE, 0.04, 31)
	LowPoly.add(root, LowPoly.cylinder(0.95, 1.1, 2.2, 8), stone, Vector3(0, 1.5, 0), Vector3.ZERO, Vector3.ONE, 0.05, 32)
	LowPoly.add(root, LowPoly.cylinder(1.13, 1.13, 0.14, 8), gold, Vector3(0, 0.55, 0))
	LowPoly.add(root, LowPoly.cylinder(1.0, 1.0, 0.14, 8), gold, Vector3(0, 2.2, 0))
	LowPoly.add(root, LowPoly.cylinder(1.12, 0.98, 0.45, 8), stone, Vector3(0, 2.8, 0), Vector3.ZERO, Vector3.ONE, 0.03, 33)
	for i in 8:
		var angle := TAU * i / 8.0
		LowPoly.add(root, LowPoly.box(Vector3(0.38, 0.4, 0.32)), stone, Vector3(cos(angle) * 0.95, 3.2, sin(angle) * 0.95),
			Vector3(0, -rad_to_deg(angle), 0), Vector3.ONE, 0.03, 34 + i)
	LowPoly.add(root, LowPoly.box(Vector3(0.9, 0.12, 0.1)), LowPoly.glow_material(Color(1.0, 0.75, 0.25), 2.5), Vector3(0, 2.45, -0.96))
	for side in [-1.0, 1.0]:
		LowPoly.add(root, LowPoly.box(Vector3(0.75, 0.6, 0.85)), stone, Vector3(1.25 * side, 2.35, 0), Vector3(0, 0, 10 * side), Vector3.ONE, 0.08, 45)
		LowPoly.add(root, LowPoly.box(Vector3(0.45, 1.1, 0.45)), stone, Vector3(1.35 * side, 1.55, -0.1), Vector3(-15, 0, 5 * side), Vector3.ONE, 0.06, 46)
		LowPoly.add(root, LowPoly.box(Vector3(0.5, 0.45, 0.5)), gold, Vector3(1.4 * side, 0.95, -0.3), Vector3.ZERO, Vector3.ONE, 0.04, 47)
	# ค้อนยักษ์
	var hammer := Node3D.new()
	hammer.position = Vector3(1.4, 0.95, -0.3)
	hammer.rotation_degrees = Vector3(-35, 0, -10)
	root.add_child(hammer)
	LowPoly.add(hammer, LowPoly.cylinder(0.07, 0.07, 2.4, 6), LowPoly.material(Color(0.2, 0.15, 0.12)), Vector3(0, 0.8, 0))
	LowPoly.add(hammer, LowPoly.box(Vector3(1.0, 0.65, 0.65)), LowPoly.material(Color(0.22, 0.2, 0.24), 0.9), Vector3(0, 2.1, 0), Vector3.ZERO, Vector3.ONE, 0.12, 48)
	LowPoly.add(hammer, LowPoly.box(Vector3(1.05, 0.12, 0.7)), gold, Vector3(0, 2.1, 0))


# ---------------------------------------------------------------- Bishop (นักบวชลอยตัว)

static func _bishop(root: Node3D) -> void:
	var robe := LowPoly.material(Color(0.55, 0.07, 0.1), 0.8)
	var gold := _gold()
	var float_height := 0.3
	var body := Node3D.new()
	body.position.y = float_height
	root.add_child(body)
	LowPoly.add(root, LowPoly.cylinder(0.6, 0.6, 0.03, 8), LowPoly.glow_material(Color(0.7, 0.35, 1.0), 1.5), Vector3(0, 0.02, 0))

	LowPoly.add(body, LowPoly.cylinder(0.3, 0.72, 1.5, 7), robe, Vector3(0, 0.75, 0), Vector3.ZERO, Vector3.ONE, 0.05, 50)
	LowPoly.add(body, LowPoly.cylinder(0.74, 0.74, 0.08, 7), gold, Vector3(0, 0.05, 0))
	LowPoly.add(body, LowPoly.box(Vector3(0.14, 1.4, 0.05)), gold, Vector3(0, 0.75, -0.5), Vector3(-15, 0, 0))
	LowPoly.add(body, LowPoly.cylinder(0.26, 0.38, 0.45, 7), robe, Vector3(0, 1.7, 0), Vector3.ZERO, Vector3.ONE, 0.03, 51)
	LowPoly.add(body, LowPoly.cylinder(0.42, 0.42, 0.1, 7), gold, Vector3(0, 1.9, 0))
	LowPoly.add(body, LowPoly.sphere(0.19, 6, 4), _skin(), Vector3(0, 2.1, -0.02), Vector3.ZERO, Vector3(0.85, 1.15, 0.9), 0.02, 52)
	LowPoly.add(body, LowPoly.cylinder(0.0, 0.12, 0.3, 5), LowPoly.material(Color(0.85, 0.85, 0.82)), Vector3(0, 1.88, -0.12), Vector3(180, 0, 0))
	# หมวกไมเตอร์
	var cream := LowPoly.material(Color(0.92, 0.88, 0.78), 0.8)
	LowPoly.add(body, LowPoly.cylinder(0.0, 0.2, 0.6, 4), cream, Vector3(0, 2.55, 0), Vector3(0, 45, 0), Vector3(1, 1, 0.6))
	LowPoly.add(body, LowPoly.box(Vector3(0.05, 0.5, 0.2)), gold, Vector3(0, 2.5, -0.04))
	# แขนเสื้อ
	for side in [-1.0, 1.0]:
		LowPoly.add(body, LowPoly.cylinder(0.1, 0.17, 0.7, 6), robe, Vector3(0.4 * side, 1.45, -0.1), Vector3(-20, 0, 25 * side))
	# ไม้เท้ากางเขน + ลูกแก้วเรืองแสง
	var staff := Node3D.new()
	staff.position = Vector3(0.62, 0.0, -0.25)
	body.add_child(staff)
	LowPoly.add(staff, LowPoly.cylinder(0.035, 0.035, 2.5, 6), gold, Vector3(0, 1.25, 0))
	LowPoly.add(staff, LowPoly.box(Vector3(0.5, 0.06, 0.06)), gold, Vector3(0, 2.25, 0))
	LowPoly.add(staff, LowPoly.box(Vector3(0.06, 0.45, 0.06)), gold, Vector3(0, 2.45, 0))
	LowPoly.add(staff, LowPoly.sphere(0.14, 6, 4), LowPoly.glow_material(Color(0.75, 0.35, 1.0), 6.0), Vector3(0, 2.75, 0))
	var orb_light := OmniLight3D.new()
	orb_light.light_color = Color(0.75, 0.35, 1.0)
	orb_light.light_energy = 1.5
	orb_light.omni_range = 3.0
	orb_light.position = Vector3(0, 2.75, 0)
	staff.add_child(orb_light)


# ---------------------------------------------------------------- Queen

static func _queen(root: Node3D) -> void:
	var violet := LowPoly.material(Color(0.27, 0.12, 0.34), 0.55, 0.45)
	var gold := _gold()
	LowPoly.add(root, LowPoly.cylinder(0.28, 0.85, 1.6, 8), violet, Vector3(0, 0.8, 0), Vector3.ZERO, Vector3.ONE, 0.05, 60)
	LowPoly.add(root, LowPoly.cylinder(0.87, 0.87, 0.1, 8), gold, Vector3(0, 0.06, 0))
	LowPoly.add(root, LowPoly.cylinder(0.62, 0.62, 0.08, 8), gold, Vector3(0, 0.75, 0))
	LowPoly.add(root, LowPoly.cylinder(0.34, 0.24, 0.65, 7), violet, Vector3(0, 1.9, 0), Vector3.ZERO, Vector3.ONE, 0.03, 61)
	LowPoly.add(root, LowPoly.cylinder(0.27, 0.27, 0.1, 7), gold, Vector3(0, 1.62, 0))
	for side in [-1.0, 1.0]:
		LowPoly.add(root, LowPoly.sphere(0.24, 6, 3), violet, Vector3(0.4 * side, 2.18, 0), Vector3.ZERO, Vector3(1, 0.75, 1), 0.03, 62)
		LowPoly.add(root, LowPoly.cylinder(0.0, 0.12, 0.3, 4), gold, Vector3(0.52 * side, 2.32, 0), Vector3(0, 0, -40 * side))
		LowPoly.add(root, LowPoly.cylinder(0.07, 0.09, 0.8, 6), violet, Vector3(0.3 * side, 1.75, -0.3), Vector3(-55, 0, 10 * side))
	LowPoly.add(root, LowPoly.sphere(0.17, 6, 4), _skin(), Vector3(0, 2.45, 0), Vector3.ZERO, Vector3(0.9, 1.1, 0.95), 0.01, 63)
	LowPoly.add(root, LowPoly.cylinder(0.05, 0.2, 0.7, 6), LowPoly.material(Color(0.08, 0.05, 0.08)), Vector3(0, 2.25, 0.12), Vector3(15, 0, 0))
	LowPoly.add(root, LowPoly.box(Vector3(0.22, 0.04, 0.03)), LowPoly.glow_material(Color(1.0, 0.75, 0.3), 4.0), Vector3(0, 2.47, -0.15))
	# มงกุฎหนาม
	LowPoly.add(root, LowPoly.cylinder(0.2, 0.2, 0.1, 8), gold, Vector3(0, 2.6, 0))
	for i in 6:
		var angle := TAU * i / 6.0
		LowPoly.add(root, LowPoly.cylinder(0.0, 0.05, 0.3 if i % 2 == 0 else 0.2, 4), gold,
			Vector3(cos(angle) * 0.18, 2.75, sin(angle) * 0.18), Vector3(sin(angle) * 15, 0, -cos(angle) * 15))
	# ดาบใหญ่ออร่าม่วง ชี้เฉียงลงไปข้างหน้า
	var blade := LowPoly.glow_material(Color(0.55, 0.3, 0.85), 1.1)
	var sword := _sword(root, Vector3(0.0, 1.55, -0.55), Vector3(-130, 20, 0), 1.6, 0.13, blade, gold)
	var aura := OmniLight3D.new()
	aura.light_color = Color(0.7, 0.35, 1.0)
	aura.light_energy = 1.2
	aura.omni_range = 3.0
	aura.position = Vector3(0, 1.0, 0)
	sword.add_child(aura)


# ---------------------------------------------------------------- King

static func _king(root: Node3D) -> void:
	var plate := _dark_steel()
	var gold := _gold()
	var cape := LowPoly.material(Color(0.45, 0.06, 0.08), 0.85)
	for side in [-1.0, 1.0]:
		LowPoly.add(root, LowPoly.box(Vector3(0.32, 0.7, 0.36)), plate, Vector3(0.25 * side, 0.35, 0), Vector3.ZERO, Vector3.ONE, 0.03, 70)
	LowPoly.add(root, LowPoly.cylinder(0.5, 0.65, 0.6, 8), plate, Vector3(0, 0.9, 0), Vector3.ZERO, Vector3.ONE, 0.04, 71)
	LowPoly.add(root, LowPoly.cylinder(0.62, 0.5, 1.05, 8), plate, Vector3(0, 1.65, 0), Vector3.ZERO, Vector3.ONE, 0.04, 72)
	LowPoly.add(root, LowPoly.cylinder(0.55, 0.55, 0.1, 8), gold, Vector3(0, 1.2, 0))
	LowPoly.add(root, LowPoly.box(Vector3(1.1, 2.0, 0.08)), cape, Vector3(0, 1.25, 0.55), Vector3(8, 0, 0), Vector3.ONE, 0.05, 73)
	for side in [-1.0, 1.0]:
		LowPoly.add(root, LowPoly.box(Vector3(0.55, 0.35, 0.65)), plate, Vector3(0.62 * side, 2.15, 0), Vector3(0, 0, -15 * side), Vector3.ONE, 0.06, 74)
		LowPoly.add(root, LowPoly.box(Vector3(0.6, 0.06, 0.7)), gold, Vector3(0.62 * side, 2.0, 0), Vector3(0, 0, -15 * side))
		LowPoly.add(root, LowPoly.cylinder(0.12, 0.14, 0.75, 6), plate, Vector3(0.4 * side, 1.6, -0.35), Vector3(-60, 0, -15 * side))
	LowPoly.add(root, LowPoly.sphere(0.22, 6, 4), _skin(), Vector3(0, 2.38, 0), Vector3.ZERO, Vector3(0.95, 1.05, 0.95), 0.01, 75)
	LowPoly.add(root, LowPoly.cylinder(0.0, 0.22, 0.55, 6), LowPoly.material(Color(0.5, 0.45, 0.42)), Vector3(0, 2.1, -0.13), Vector3(160, 0, 0), Vector3.ONE, 0.02, 76)
	# มงกุฎหนัก
	LowPoly.add(root, LowPoly.cylinder(0.26, 0.24, 0.16, 8), gold, Vector3(0, 2.6, 0))
	for i in 5:
		var angle := TAU * i / 5.0
		LowPoly.add(root, LowPoly.cylinder(0.0, 0.07, 0.25, 4), gold, Vector3(cos(angle) * 0.22, 2.78, sin(angle) * 0.22))
	LowPoly.add(root, LowPoly.box(Vector3(0.08, 0.08, 0.05)), LowPoly.glow_material(Color(1.0, 0.15, 0.1), 4.0), Vector3(0, 2.6, -0.26))
	# ดาบใหญ่สองมือ ปักลงด้านหน้า
	_sword(root, Vector3(0, 1.62, -0.6), Vector3(180, 0, 0), 1.45, 0.2, LowPoly.material(Color(0.5, 0.5, 0.58), 0.3, 0.85), gold)
