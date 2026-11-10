class_name DirectionalSpriteController
extends Node3D
## ตัวจัดการสไปรต์ 8 ทิศทาง (8-Directional Sprite Controller) สำหรับ Godot
## คำนวณมุมระหว่างตัวละครกับกล้อง เพื่อเลือกภาพสไปรต์ในทิศทางที่ถูกต้อง (0 = หน้า, 2 = ขวา, 4 = หลัง, 6 = ซ้าย ฯลฯ)

enum Direction {
	SOUTH = 0,       # ด้านหน้าตรง (หันหากล้อง)
	SOUTH_EAST = 1,  # หน้าขวา
	EAST = 2,        # ด้านขวา
	NORTH_EAST = 3,  # หลังขวา
	NORTH = 4,       # ด้านหลังตรง
	NORTH_WEST = 5,  # หลังซ้าย
	WEST = 6,        # ด้านซ้าย
	SOUTH_WEST = 7,  # หน้าซ้าย
}

const DIRECTION_SUFFIXES := [
	"south",
	"south_east",
	"east",
	"north_east",
	"north",
	"north_west",
	"west",
	"south_west"
]

@export var fighter: FighterController
@export var animated_sprite: AnimatedSprite3D
@export var current_action := "idle"

var current_direction: Direction = Direction.SOUTH


func _ready() -> void:
	if fighter == null and get_parent() is FighterController:
		fighter = get_parent() as FighterController


func _process(_delta: float) -> void:
	if fighter == null or animated_sprite == null:
		return

	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return

	var new_dir := get_relative_direction(cam)
	if new_dir != current_direction:
		current_direction = new_dir
		_update_sprite_animation()


## คำนวณทิศทาง 8 ด้าน สัมพัทธ์ระหว่างมุมมองกล้องกับทิศที่ตัวละครหันหน้า
func get_relative_direction(camera: Camera3D) -> Direction:
	# เวกเตอร์ที่ตัวละครหันหน้าไป (แกน -Z ในระนาบ XZ)
	var facing_dir := -fighter.global_transform.basis.z
	facing_dir.y = 0.0
	facing_dir = facing_dir.normalized()

	# เวกเตอร์จากตัวละครไปยังกล้อง
	var cam_dir := camera.global_position - fighter.global_position
	cam_dir.y = 0.0
	cam_dir = cam_dir.normalized()

	if facing_dir.length_squared() < 0.001 or cam_dir.length_squared() < 0.001:
		return Direction.SOUTH

	# คำนวณมุมสัมพัทธ์ (0 ถึง 360 องศา)
	var angle := facing_dir.signed_angle_to(cam_dir, Vector3.UP)
	var deg := rad_to_deg(angle)
	if deg < 0.0:
		deg += 360.0

	# แบ่งออกเป็น 8 ส่วน (ส่วนละ 45 องศา ชดเชยจุดกึ่งกลาง 22.5 องศา)
	var sector := int(floor((deg + 22.5) / 45.0)) % 8
	return sector as Direction


func play_action(action_name: String) -> void:
	current_action = action_name
	_update_sprite_animation()


func _update_sprite_animation() -> void:
	if animated_sprite == null:
		return
	var dir_str := DIRECTION_SUFFIXES[current_direction]
	var full_anim_name := "%s_%s" % [current_action, dir_str]

	# ถ้ามีอนิเมชั่นทิศนั้นให้เล่น ถ้าไม่มีให้ถอยไปเล่นชื่อแอคชั่นหลัก
	if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(full_anim_name):
		animated_sprite.play(full_anim_name)
	elif animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(current_action):
		animated_sprite.play(current_action)
