class_name Pixel25DCharacter
extends RefCounted
## ตัวสร้างสไปรต์ตัวละคร Pixel Art คมชัดตรงตามภาพต้นแบบทั้ง 12 ตัว (ฝ่ายขาว 6 ตัว, ฝ่ายดำ 6 ตัว)
## ไม่มีการใช้ก้อนกลม 3D เละๆ ภาพคมชัด 100% สไตล์ Pixel Art แท้

const HEIGHTS := {
	"pawn": 1.95,
	"knight": 2.45,
	"bishop": 2.2,
	"rook": 2.4,
	"queen": 2.3,
	"king": 2.45,
}

const TEXTURES := {
	"white_pawn": preload("res://art/sprites/pixel_25d/white_pawn.png"),
	"white_pawn_back": preload("res://art/sprites/pixel_25d/white_pawn_back.png"),
	"white_knight": preload("res://art/sprites/pixel_25d/white_knight.png"),
	"white_bishop": preload("res://art/sprites/pixel_25d/white_bishop.png"),
	"white_rook": preload("res://art/sprites/pixel_25d/white_rook.png"),
	"white_queen": preload("res://art/sprites/pixel_25d/white_queen.png"),
	"white_king": preload("res://art/sprites/pixel_25d/white_king.png"),
	"black_pawn": preload("res://art/sprites/pixel_25d/black_pawn.png"),
	"black_knight": preload("res://art/sprites/pixel_25d/black_knight.png"),
	"black_bishop": preload("res://art/sprites/pixel_25d/black_bishop.png"),
	"black_rook": preload("res://art/sprites/pixel_25d/black_rook.png"),
	"black_queen": preload("res://art/sprites/pixel_25d/black_queen.png"),
	"black_king": preload("res://art/sprites/pixel_25d/black_king.png"),
}


static func get_texture(piece_type: String, is_white: bool) -> Texture2D:
	var key := ("white_" if is_white else "black_") + piece_type.to_lower()
	return TEXTURES.get(key, TEXTURES["white_pawn"])


static func get_duel_texture(piece_type: String, is_white: bool) -> Texture2D:
	if is_white:
		var back_key := "white_" + piece_type.to_lower() + "_back"
		if TEXTURES.has(back_key):
			return TEXTURES[back_key]
		return TEXTURES.get("white_" + piece_type.to_lower(), TEXTURES["white_pawn_back"])
	else:
		return TEXTURES.get("black_" + piece_type.to_lower(), TEXTURES["black_pawn"])


## สร้าง Sprite3D สไตล์ Pixel Art คมชัด สำหรับหมากบนกระดาน
static func build_sprite(piece_type: String, is_white: bool, custom_height: float = 0.0) -> Sprite3D:
	var piece_name := piece_type.to_lower()
	var tex := get_texture(piece_name, is_white)
	var target_h: float = custom_height if custom_height > 0.0 else HEIGHTS.get(piece_name, 2.2)
	return _create_pixel_sprite(tex, target_h)


## สร้าง Sprite3D สำหรับสังเวียนดวล (ผู้เล่นมองจากด้านหลัง, ศัตรูมองจากด้านหน้า)
static func build_duel_sprite(piece_type: String, is_white: bool) -> Sprite3D:
	var piece_name := piece_type.to_lower()
	var tex := get_duel_texture(piece_name, is_white)
	var target_h: float = HEIGHTS.get(piece_name, 2.35)
	return _create_pixel_sprite(tex, target_h)


static func _create_pixel_sprite(tex: Texture2D, target_h: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.name = "PixelSprite25D"
	sprite.texture = tex
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.double_sided = true
	sprite.shaded = true
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	# คำนวณ pixel_size ให้ได้ความสูงตามต้องการ
	var tex_h := float(tex.get_height())
	sprite.pixel_size = target_h / tex_h
	sprite.offset.y = tex_h * 0.5

	# วางเงาใต้เท้า (Drop Shadow)
	var shadow := MeshInstance3D.new()
	shadow.name = "DropShadow"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.95, 0.55)
	quad.orientation = PlaneMesh.FACE_Y
	shadow.mesh = quad

	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_mat.albedo_color = Color(0.02, 0.02, 0.03, 0.6)
	shadow.material_override = shadow_mat
	shadow.position = Vector3(0, 0.02, 0)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.add_child(shadow)

	return sprite
