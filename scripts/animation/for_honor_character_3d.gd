class_name ForHonorCharacter3D
extends Node3D
## ตัวละคร 3D เต็มรูปแบบสไตล์ For Honor
## - โหลดโมเดล 3D Rigged (.glb) ที่เจนจาก Blender 4.5
## - ควบคุม AnimationPlayer เล่นท่า idle, attack_left/right/top, parry, hit_react
## - หันหน้าประจันหน้ากับศัตรูในสังเวียน 3 มิติตลอดเวลา

const MODEL_WHITE := preload("res://art/models/knight_white.glb")
const MODEL_BLACK := preload("res://art/models/knight_black.glb")

@export var is_white_faction := true

var model_instance: Node3D
var anim_player: AnimationPlayer
var current_anim := "idle"


func _ready() -> void:
	_spawn_3d_model()


func setup(white_faction: bool) -> void:
	is_white_faction = white_faction
	_spawn_3d_model()


func _spawn_3d_model() -> void:
	if model_instance != null and is_instance_valid(model_instance):
		model_instance.queue_free()

	var scene_res := MODEL_WHITE if is_white_faction else MODEL_BLACK
	model_instance = scene_res.instantiate() as Node3D
	# หันหน้าเข้าหาแกน -Z ตามมาตรฐานของ Godot Character Controller
	model_instance.rotation.y = deg_to_rad(180.0)
	add_child(model_instance)

	anim_player = model_instance.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim_player != null:
		# ตั้งค่า idle ให้วนลูป
		if anim_player.has_animation("idle"):
			var idle_anim := anim_player.get_animation("idle")
			idle_anim.loop_mode = Animation.LOOP_LINEAR
		anim_player.animation_finished.connect(_on_animation_finished)
		anim_player.play("idle", 0.15)


func play_idle() -> void:
	if anim_player != null and anim_player.has_animation("idle"):
		current_anim = "idle"
		anim_player.play("idle", 0.15)


func play_attack(direction: CombatInputController.GuardDirection) -> void:
	if anim_player == null:
		return

	var anim_name := "attack_top"
	match direction:
		CombatInputController.GuardDirection.LEFT:
			anim_name = "attack_left"
		CombatInputController.GuardDirection.RIGHT:
			anim_name = "attack_right"
		CombatInputController.GuardDirection.TOP:
			anim_name = "attack_top"

	if anim_player.has_animation(anim_name):
		current_anim = anim_name
		anim_player.play(anim_name, 0.06, 1.3)


func play_parry() -> void:
	if anim_player != null and anim_player.has_animation("parry"):
		current_anim = "parry"
		anim_player.play("parry", 0.05, 1.4)


func play_hit_react() -> void:
	if anim_player != null and anim_player.has_animation("hit_react"):
		current_anim = "hit_react"
		anim_player.play("hit_react", 0.05, 1.2)


func _on_animation_finished(anim_name: StringName) -> void:
	# เมื่อจบท่าฟัน หรือโดนฟัน ให้กลับมาท่า Idle อัตโนมัติ
	if anim_name != "idle":
		play_idle()
