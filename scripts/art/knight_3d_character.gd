class_name Knight3DCharacter
extends Node3D

## Pawned Souls 3D Stylized Knight Character Controller
## Instantiates the true 3D GLB model with full skeletal rig and 17 animations.

const WHITE_KNIGHT_SCENE := preload("res://art/models/pawn_white_3d.glb")
const BLACK_KNIGHT_SCENE := preload("res://art/models/pawn_black_3d.glb")

var model_root: Node3D
var anim_player: AnimationPlayer
var is_white: bool = true

static func build(is_white_faction: bool) -> Knight3DCharacter:
	var char_node := Knight3DCharacter.new()
	char_node.name = "Knight3D"
	char_node.is_white = is_white_faction
	return char_node

func _ready() -> void:
	_ensure_model()

func _ensure_model() -> void:
	if model_root != null:
		return
	var packed: PackedScene = WHITE_KNIGHT_SCENE if is_white else BLACK_KNIGHT_SCENE
	if packed == null:
		push_error("Failed to load 3D knight GLB for faction: " + ("White" if is_white else "Black"))
		return

	model_root = packed.instantiate() as Node3D
	# หมุน 180 องศา (PI) เพื่อให้ด้านหน้าของตัวละคร (+Z ในไฟล์ GLB) หันไปทางทิศหน้าของ Godot (-Z) พอดี
	model_root.rotation.y = PI
	# ปรับสเกลโมเดลให้ขนาดสมส่วน (0.8) ไม่ใหญ่เทอะทะจนบังศัตรูมิดจอ
	model_root.scale = Vector3(0.80, 0.80, 0.80)
	add_child(model_root)
	anim_player = model_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_setup_shadows_and_lighting(model_root)

func _setup_shadows_and_lighting(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mi.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
	for child in node.get_children():
		_setup_shadows_and_lighting(child)

func get_animation_player() -> AnimationPlayer:
	_ensure_model()
	return anim_player
