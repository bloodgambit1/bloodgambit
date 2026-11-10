class_name HD2DCharacter
extends Node3D
## ตัวละคร 3D สไตล์ HD-2D (Octopath Traveler Style)
## - แยกเลเยอร์มิติความลึกในพื้นที่ 3D จริง: Body (Z=0), Shield (Z=+0.08), Sword (Z=+0.12)
## - รับแสงและเงา 3D แบบ Dynamic (shaded = true, cast_shadow = ON)
## - มี WeaponPivot และ ShieldPivot หมุนฟันและยกโล่ปัดป้องในโลก 3D อย่างแท้จริง
## - มีวงดาบแสง 3D (Slash Arc) ตวัดตามคมดาบ

const LAYER_TEXTURES := {
	"white_back_body": preload("res://art/sprites/hd2d/white_back_body.png"),
	"white_back_shield": preload("res://art/sprites/hd2d/white_back_shield.png"),
	"white_back_sword": preload("res://art/sprites/hd2d/white_back_sword.png"),

	"white_front_body": preload("res://art/sprites/hd2d/white_front_body.png"),
	"white_front_shield": preload("res://art/sprites/hd2d/white_front_shield.png"),
	"white_front_sword": preload("res://art/sprites/hd2d/white_front_sword.png"),

	"black_back_body": preload("res://art/sprites/hd2d/black_back_body.png"),
	"black_back_shield": preload("res://art/sprites/hd2d/black_back_shield.png"),
	"black_back_sword": preload("res://art/sprites/hd2d/black_back_sword.png"),

	"black_front_body": preload("res://art/sprites/hd2d/black_front_body.png"),
	"black_front_shield": preload("res://art/sprites/hd2d/black_front_shield.png"),
	"black_front_sword": preload("res://art/sprites/hd2d/black_front_sword.png"),
}

const TARGET_HEIGHT := 2.35

@export var is_white_faction := true
@export var is_back_view := true

var body_sprite: Sprite3D
var shield_pivot: Node3D
var shield_sprite: Sprite3D
var weapon_pivot: Node3D
var weapon_sprite: Sprite3D
var slash_arc: MeshInstance3D
var drop_shadow: MeshInstance3D

var _time := 0.0
var _current_state := "idle"
var _slash_tween: Tween
var _parry_tween: Tween


func _ready() -> void:
	_build_hd2d_layers()


func setup(white_faction: bool, back_view: bool) -> void:
	is_white_faction = white_faction
	is_back_view = back_view
	_apply_textures()


func _build_hd2d_layers() -> void:
	# 1. Drop Shadow ใต้เท้า (Z = 0, Y = 0.02)
	drop_shadow = MeshInstance3D.new()
	drop_shadow.name = "DropShadow"
	var quad := QuadMesh.new()
	quad.size = Vector2(1.1, 0.65)
	quad.orientation = PlaneMesh.FACE_Y
	drop_shadow.mesh = quad
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_mat.albedo_color = Color(0.01, 0.01, 0.02, 0.6)
	drop_shadow.material_override = shadow_mat
	drop_shadow.position = Vector3(0, 0.02, 0)
	drop_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(drop_shadow)

	# 2. Body Layer (Z = 0.0)
	body_sprite = Sprite3D.new()
	body_sprite.name = "BodyLayer"
	_configure_hd2d_sprite(body_sprite)
	body_sprite.position = Vector3(0, 0, 0)
	add_child(body_sprite)

	# 3. Shield Pivot & Layer (Z = +0.07 มิติความลึกด้านหน้าลำตัว)
	shield_pivot = Node3D.new()
	shield_pivot.name = "ShieldPivot"
	# จุดหมุนของโล่อยู่บริเวณหัวไหล่ซ้าย
	var shield_x := -0.28 if is_back_view else 0.28
	var shield_z := 0.08 if is_back_view else -0.08
	shield_pivot.position = Vector3(shield_x, 1.15, shield_z)
	add_child(shield_pivot)

	shield_sprite = Sprite3D.new()
	shield_sprite.name = "ShieldLayer"
	_configure_hd2d_sprite(shield_sprite)
	shield_sprite.position = Vector3(-shield_x, -1.15, 0.0)
	shield_pivot.add_child(shield_sprite)

	# 4. Weapon Pivot & Layer (Z = +0.10 มิติความลึกด้านหน้า)
	weapon_pivot = Node3D.new()
	weapon_pivot.name = "WeaponPivot"
	# จุดหมุนของดาบอยู่ที่ด้ามจับมือขวา (X ~ 0.35, Y ~ 0.95)
	var weapon_x := 0.35 if is_back_view else -0.35
	var weapon_z := 0.10 if is_back_view else -0.10
	weapon_pivot.position = Vector3(weapon_x, 0.95, weapon_z)
	add_child(weapon_pivot)

	weapon_sprite = Sprite3D.new()
	weapon_sprite.name = "WeaponLayer"
	_configure_hd2d_sprite(weapon_sprite)
	weapon_sprite.position = Vector3(-weapon_x, -0.95, 0.0)
	weapon_pivot.add_child(weapon_sprite)

	# 5. วงดาบแสง 3D (Slash Arc Trail)
	_build_slash_arc()

	_apply_textures()


func _configure_hd2d_sprite(s: Sprite3D) -> void:
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.double_sided = true
	# หัวใจของ HD-2D: รับแสงเงา 3D และทอดเงาลงพื้น/ทับเลเยอร์อื่น
	s.shaded = true
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _build_slash_arc() -> void:
	slash_arc = MeshInstance3D.new()
	slash_arc.name = "SlashArc3D"
	var arc_mesh := TorusMesh.new()
	arc_mesh.inner_radius = 0.85
	arc_mesh.outer_radius = 1.35
	arc_mesh.ring_segments = 16
	arc_mesh.rings = 24
	slash_arc.mesh = arc_mesh

	var arc_mat := StandardMaterial3D.new()
	arc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var arc_color := Color(1.8, 1.6, 0.9, 0.0) if is_white_faction else Color(1.6, 0.8, 2.0, 0.0)
	arc_mat.albedo_color = arc_color
	arc_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	slash_arc.material_override = arc_mat
	slash_arc.scale = Vector3(0.01, 0.01, 0.01)
	slash_arc.position = Vector3(0, 1.15, 0.12)
	add_child(slash_arc)


func _apply_textures() -> void:
	var faction := "white" if is_white_faction else "black"
	var view := "back" if is_back_view else "front"

	var body_key := "%s_%s_body" % [faction, view]
	var shield_key := "%s_%s_shield" % [faction, view]
	var sword_key := "%s_%s_sword" % [faction, view]

	if LAYER_TEXTURES.has(body_key) and body_sprite != null:
		var tex: Texture2D = LAYER_TEXTURES[body_key]
		body_sprite.texture = tex
		var h := float(tex.get_height())
		body_sprite.pixel_size = TARGET_HEIGHT / h
		body_sprite.offset.y = h * 0.5

	if LAYER_TEXTURES.has(shield_key) and shield_sprite != null:
		var tex: Texture2D = LAYER_TEXTURES[shield_key]
		shield_sprite.texture = tex
		var h := float(tex.get_height())
		shield_sprite.pixel_size = TARGET_HEIGHT / h
		shield_sprite.offset.y = h * 0.5

	if LAYER_TEXTURES.has(sword_key) and weapon_sprite != null:
		var tex: Texture2D = LAYER_TEXTURES[sword_key]
		weapon_sprite.texture = tex
		var h := float(tex.get_height())
		weapon_sprite.pixel_size = TARGET_HEIGHT / h
		weapon_sprite.offset.y = h * 0.5


func _process(delta: float) -> void:
	_time += delta
	if _current_state == "idle":
		_process_idle(delta)


func _process_idle(delta: float) -> void:
	# หายใจและส่ายอาวุธแบบ HD-2D ในมิติ 3D
	var breath := sin(_time * 3.2)
	if body_sprite:
		body_sprite.scale.y = lerpf(body_sprite.scale.y, 1.0 + breath * 0.02, delta * 8.0)
		body_sprite.scale.x = lerpf(body_sprite.scale.x, 1.0 - breath * 0.01, delta * 8.0)

	if shield_pivot:
		# โล่ขยับตามการหายใจเบาๆ ในแกน Z และ Y
		shield_pivot.rotation.z = lerpf(shield_pivot.rotation.z, breath * 0.04, delta * 6.0)
		shield_pivot.position.y = lerpf(shield_pivot.position.y, 1.15 + breath * 0.015, delta * 6.0)

	if weapon_pivot:
		# ดาบแกว่งพร้อมสู้ในโลก 3D
		weapon_pivot.rotation.z = lerpf(weapon_pivot.rotation.z, -breath * 0.06, delta * 6.0)
		weapon_pivot.position.y = lerpf(weapon_pivot.position.y, 0.95 + breath * 0.02, delta * 6.0)


# ---------------------------------------------------------------- HD-2D Actions (ฟัน, ง้าง, แพรี่)

func play_windup(direction: CombatInputController.GuardDirection) -> void:
	_current_state = "windup"
	if weapon_pivot == null or shield_pivot == null:
		return

	if _slash_tween and _slash_tween.is_valid():
		_slash_tween.kill()

	_slash_tween = create_tween().set_parallel(true)

	match direction:
		CombatInputController.GuardDirection.LEFT:
			# ง้างฟันซ้าย: ดึงดาบไปทางขวาด้านหลัง บิดแกน 3D
			_slash_tween.tween_property(weapon_pivot, "rotation:z", deg_to_rad(65.0), 0.2).set_trans(Tween.TRANS_QUAD)
			_slash_tween.tween_property(weapon_pivot, "rotation:y", deg_to_rad(-25.0), 0.2)
			_slash_tween.tween_property(weapon_pivot, "position:z", 0.02, 0.2)
			_slash_tween.tween_property(shield_pivot, "position:z", 0.14, 0.2)

		CombatInputController.GuardDirection.RIGHT:
			# ง้างฟันขวา: ดึงดาบข้ามไหล่ซ้าย
			_slash_tween.tween_property(weapon_pivot, "rotation:z", deg_to_rad(-55.0), 0.2).set_trans(Tween.TRANS_QUAD)
			_slash_tween.tween_property(weapon_pivot, "rotation:y", deg_to_rad(30.0), 0.2)
			_slash_tween.tween_property(shield_pivot, "position:z", 0.05, 0.2)

		CombatInputController.GuardDirection.TOP:
			# ง้างฟันบน: ยกดาบขึ้นสองแขนสูงเหนือหัว
			_slash_tween.tween_property(weapon_pivot, "rotation:x", deg_to_rad(-60.0), 0.2).set_trans(Tween.TRANS_QUAD)
			_slash_tween.tween_property(weapon_pivot, "position:y", 1.35, 0.2)
			_slash_tween.tween_property(shield_pivot, "position:y", 1.05, 0.2)


func play_attack(direction: CombatInputController.GuardDirection) -> void:
	_current_state = "attacking"
	if weapon_pivot == null:
		return

	if _slash_tween and _slash_tween.is_valid():
		_slash_tween.kill()

	_slash_tween = create_tween()

	# ปล่อยคลื่นแสงวงดาบ 3D (Slash Arc)
	_trigger_slash_arc(direction)

	match direction:
		CombatInputController.GuardDirection.LEFT:
			# ตวัดฟันซ้าย: เหวี่ยงดาบผ่านแกน 3D ข้ามไปด้านซ้าย
			_slash_tween.parallel().tween_property(weapon_pivot, "rotation:z", deg_to_rad(-75.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_slash_tween.parallel().tween_property(weapon_pivot, "position:z", 0.22, 0.12)
			_slash_tween.parallel().tween_property(body_sprite, "rotation:z", deg_to_rad(8.0), 0.12)

		CombatInputController.GuardDirection.RIGHT:
			# ตวัดฟันขวา: เหวี่ยงดาบเฉือนจากซ้ายไปขวา
			_slash_tween.parallel().tween_property(weapon_pivot, "rotation:z", deg_to_rad(80.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_slash_tween.parallel().tween_property(weapon_pivot, "position:z", 0.22, 0.12)
			_slash_tween.parallel().tween_property(body_sprite, "rotation:z", deg_to_rad(-8.0), 0.12)

		CombatInputController.GuardDirection.TOP:
			# ฟันผ่าบน: สับดาบลงมาข้างหน้าอย่างรุนแรง
			_slash_tween.parallel().tween_property(weapon_pivot, "rotation:x", deg_to_rad(55.0), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_slash_tween.parallel().tween_property(weapon_pivot, "position:y", 0.70, 0.10)
			_slash_tween.parallel().tween_property(weapon_pivot, "position:z", 0.30, 0.10)

	_slash_tween.tween_interval(0.18)
	_slash_tween.tween_callback(func():
		_current_state = "idle"
		_reset_to_idle()
	)


func play_parry() -> void:
	_current_state = "parry"
	if shield_pivot == null or weapon_pivot == null:
		return

	if _parry_tween and _parry_tween.is_valid():
		_parry_tween.kill()

	_parry_tween = create_tween()
	# โล่พุ่งกระแทกไปข้างหน้าในแกน Z (+0.32m) พร้อมเอียงปัดป้องแบบ 3D
	_parry_tween.parallel().tween_property(shield_pivot, "position:z", 0.38, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_parry_tween.parallel().tween_property(shield_pivot, "rotation:x", deg_to_rad(-18.0), 0.08)
	_parry_tween.parallel().tween_property(weapon_pivot, "position:z", 0.22, 0.08)
	_parry_tween.parallel().tween_property(weapon_pivot, "rotation:z", deg_to_rad(45.0), 0.08)

	# แฟลชแสงสะท้อนโล่
	if shield_sprite:
		var flash_color := Color(2.5, 2.2, 1.2) if is_white_faction else Color(2.2, 1.2, 2.6)
		_parry_tween.parallel().tween_property(shield_sprite, "modulate", flash_color, 0.05)
		_parry_tween.parallel().tween_property(shield_sprite, "modulate", Color.WHITE, 0.25).set_delay(0.08)

	_parry_tween.tween_interval(0.20)
	_parry_tween.tween_callback(func():
		_current_state = "idle"
		_reset_to_idle()
	)


func play_hit_react() -> void:
	_current_state = "hit"
	if _slash_tween and _slash_tween.is_valid():
		_slash_tween.kill()

	var tween := create_tween()
	# หงายหลังในแกน Z ถอยหลัง
	tween.parallel().tween_property(body_sprite, "rotation:x", deg_to_rad(-22.0), 0.08)
	tween.parallel().tween_property(shield_pivot, "position:x", -0.42 if is_back_view else 0.42, 0.08)
	tween.parallel().tween_property(weapon_pivot, "position:x", 0.50 if is_back_view else -0.50, 0.08)
	tween.parallel().tween_property(body_sprite, "modulate", Color(3.0, 0.3, 0.3), 0.06)

	tween.tween_interval(0.18)
	tween.tween_callback(func():
		body_sprite.modulate = Color.WHITE
		_current_state = "idle"
		_reset_to_idle()
	)


func _reset_to_idle() -> void:
	var reset_tween := create_tween().set_parallel(true)
	var shield_x := -0.28 if is_back_view else 0.28
	var shield_z := 0.08 if is_back_view else -0.08
	var weapon_x := 0.35 if is_back_view else -0.35
	var weapon_z := 0.10 if is_back_view else -0.10

	if shield_pivot:
		reset_tween.tween_property(shield_pivot, "position", Vector3(shield_x, 1.15, shield_z), 0.18)
		reset_tween.tween_property(shield_pivot, "rotation", Vector3.ZERO, 0.18)
	if weapon_pivot:
		reset_tween.tween_property(weapon_pivot, "position", Vector3(weapon_x, 0.95, weapon_z), 0.18)
		reset_tween.tween_property(weapon_pivot, "rotation", Vector3.ZERO, 0.18)
	if body_sprite:
		reset_tween.tween_property(body_sprite, "rotation", Vector3.ZERO, 0.18)
		reset_tween.tween_property(body_sprite, "scale", Vector3.ONE, 0.18)


func _trigger_slash_arc(direction: CombatInputController.GuardDirection) -> void:
	if slash_arc == null:
		return
	var arc_mat := slash_arc.material_override as StandardMaterial3D
	if arc_mat == null:
		return

	var arc_color := Color(2.0, 1.8, 1.0, 0.85) if is_white_faction else Color(1.8, 0.9, 2.4, 0.85)
	arc_mat.albedo_color = arc_color

	match direction:
		CombatInputController.GuardDirection.LEFT:
			slash_arc.rotation = Vector3(0, deg_to_rad(30.0), deg_to_rad(-45.0))
		CombatInputController.GuardDirection.RIGHT:
			slash_arc.rotation = Vector3(0, deg_to_rad(-30.0), deg_to_rad(45.0))
		CombatInputController.GuardDirection.TOP:
			slash_arc.rotation = Vector3(deg_to_rad(90.0), 0, 0)

	slash_arc.scale = Vector3(0.3, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(slash_arc, "scale", Vector3(1.15, 1.15, 1.15), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(arc_mat, "albedo_color:a", 0.0, 0.14)
	tween.tween_callback(func():
		slash_arc.scale = Vector3(0.01, 0.01, 0.01)
	)
