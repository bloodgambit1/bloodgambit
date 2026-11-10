class_name PixelSpriteAnimator
extends Node
## จัดการอนิเมชั่น 2.5D พิกเซลอาร์ตแท้ 100% สำหรับการดวลสไตล์ For Honor
## - สลับเฟรมอนิเมชั่นที่เรนเดอร์จาก Blender โดยแยกชิ้นส่วนอนาโตมี (หันซ้าย, หันขวา, การ์ดบน, ท่าฟัน 3 ทิศ, ท่าแพรี่, ท่าโดนฟัน)
## - ทุกเฟรมเป็นพิกเซลอาร์ตคมชัด 100% ไม่มีความกลมมนเละ
## - ควบคุมร่วมกับฟิสิกส์ 2.5D: ย่อ-ยืด (Squash & Stretch), สั่นสะเทือนเมื่อโดนตี, และ Parry Flash

const ANIM_DATA := {
	"white": {
		"idle": [
			preload("res://art/sprites/animated_pixel/white_pawn/idle_0.png"),
			preload("res://art/sprites/animated_pixel/white_pawn/idle_1.png"),
			preload("res://art/sprites/animated_pixel/white_pawn/idle_2.png"),
			preload("res://art/sprites/animated_pixel/white_pawn/idle_3.png"),
		],
		"guard_left": [preload("res://art/sprites/animated_pixel/white_pawn/guard_left.png")],
		"guard_right": [preload("res://art/sprites/animated_pixel/white_pawn/guard_right.png")],
		"guard_top": [preload("res://art/sprites/animated_pixel/white_pawn/guard_top.png")],
		"slash_left": [
			preload("res://art/sprites/animated_pixel/white_pawn/slash_left_0.png"),
			preload("res://art/sprites/animated_pixel/white_pawn/slash_left_1.png"),
			preload("res://art/sprites/animated_pixel/white_pawn/slash_left_2.png"),
			preload("res://art/sprites/animated_pixel/white_pawn/slash_left_3.png"),
		],
		"slash_right": [
			preload("res://art/sprites/animated_pixel/white_pawn/slash_right_0.png"),
			preload("res://art/sprites/animated_pixel/white_pawn/slash_right_1.png"),
			preload("res://art/sprites/animated_pixel/white_pawn/slash_right_2.png"),
			preload("res://art/sprites/animated_pixel/white_pawn/slash_right_3.png"),
		],
		"slash_top": [
			preload("res://art/sprites/animated_pixel/white_pawn/slash_top_0.png"),
			preload("res://art/sprites/animated_pixel/white_pawn/slash_top_1.png"),
			preload("res://art/sprites/animated_pixel/white_pawn/slash_top_2.png"),
			preload("res://art/sprites/animated_pixel/white_pawn/slash_top_3.png"),
		],
		"parry": [
			preload("res://art/sprites/animated_pixel/white_pawn/parry_0.png"),
			preload("res://art/sprites/animated_pixel/white_pawn/parry_1.png"),
			preload("res://art/sprites/animated_pixel/white_pawn/parry_2.png"),
		],
		"hit_react": [
			preload("res://art/sprites/animated_pixel/white_pawn/hit_react_0.png"),
			preload("res://art/sprites/animated_pixel/white_pawn/hit_react_1.png"),
			preload("res://art/sprites/animated_pixel/white_pawn/hit_react_2.png"),
		],
	},
	"black": {
		"idle": [
			preload("res://art/sprites/animated_pixel/black_pawn/idle_0.png"),
			preload("res://art/sprites/animated_pixel/black_pawn/idle_1.png"),
			preload("res://art/sprites/animated_pixel/black_pawn/idle_2.png"),
			preload("res://art/sprites/animated_pixel/black_pawn/idle_3.png"),
		],
		"guard_left": [preload("res://art/sprites/animated_pixel/black_pawn/guard_left.png")],
		"guard_right": [preload("res://art/sprites/animated_pixel/black_pawn/guard_right.png")],
		"guard_top": [preload("res://art/sprites/animated_pixel/black_pawn/guard_top.png")],
		"slash_left": [
			preload("res://art/sprites/animated_pixel/black_pawn/slash_left_0.png"),
			preload("res://art/sprites/animated_pixel/black_pawn/slash_left_1.png"),
			preload("res://art/sprites/animated_pixel/black_pawn/slash_left_2.png"),
			preload("res://art/sprites/animated_pixel/black_pawn/slash_left_3.png"),
		],
		"slash_right": [
			preload("res://art/sprites/animated_pixel/black_pawn/slash_right_0.png"),
			preload("res://art/sprites/animated_pixel/black_pawn/slash_right_1.png"),
			preload("res://art/sprites/animated_pixel/black_pawn/slash_right_2.png"),
			preload("res://art/sprites/animated_pixel/black_pawn/slash_right_3.png"),
		],
		"slash_top": [
			preload("res://art/sprites/animated_pixel/black_pawn/slash_top_0.png"),
			preload("res://art/sprites/animated_pixel/black_pawn/slash_top_1.png"),
			preload("res://art/sprites/animated_pixel/black_pawn/slash_top_2.png"),
			preload("res://art/sprites/animated_pixel/black_pawn/slash_top_3.png"),
		],
		"parry": [
			preload("res://art/sprites/animated_pixel/black_pawn/parry_0.png"),
			preload("res://art/sprites/animated_pixel/black_pawn/parry_1.png"),
			preload("res://art/sprites/animated_pixel/black_pawn/parry_2.png"),
		],
		"hit_react": [
			preload("res://art/sprites/animated_pixel/black_pawn/hit_react_0.png"),
			preload("res://art/sprites/animated_pixel/black_pawn/hit_react_1.png"),
			preload("res://art/sprites/animated_pixel/black_pawn/hit_react_2.png"),
		],
	}
}

@export var fighter: FighterController
@export var sprite: Sprite3D

var _time := 0.0
var _base_scale := Vector3.ONE
var _hit_shake := 0.0
var _flash_timer := 0.0
var _original_modulate := Color.WHITE

# ตัวควบคุม Action Frames
var _current_anim := "idle"
var _anim_frame_idx := 0
var _anim_timer := 0.0
var _anim_fps := 10.0
var _anim_loop := true
var _action_lock_timer := 0.0


func _ready() -> void:
	if fighter == null and get_parent() is FighterController:
		fighter = get_parent() as FighterController

	if fighter != null:
		fighter.attack_started.connect(_on_attack_started)
		fighter.hit_resolved.connect(_on_hit_resolved)
		fighter.parry_started.connect(_on_parry_started)
		fighter.state_changed.connect(_on_state_changed)


func set_sprite(new_sprite: Sprite3D) -> void:
	sprite = new_sprite
	if sprite != null:
		_base_scale = Vector3.ONE
		_original_modulate = sprite.modulate
		sprite.position = Vector3.ZERO
		sprite.rotation = Vector3.ZERO
		play_anim("idle", 8.0, true)


func play_anim(anim_name: String, fps: float = 10.0, loop: bool = false, lock_duration: float = 0.0) -> void:
	if _current_anim == anim_name and _action_lock_timer > 0.0:
		return
	_current_anim = anim_name
	_anim_fps = fps
	_anim_loop = loop
	_anim_frame_idx = 0
	_anim_timer = 0.0
	_action_lock_timer = lock_duration
	_apply_current_frame()


func _apply_current_frame() -> void:
	if sprite == null or fighter == null:
		return
	var faction := "white" if fighter.is_white_faction else "black"
	var faction_data: Dictionary = ANIM_DATA.get(faction, {})
	var frames: Array = faction_data.get(_current_anim, faction_data.get("idle", []))
	if frames.is_empty():
		return

	var idx := clampi(_anim_frame_idx, 0, frames.size() - 1)
	var tex: Texture2D = frames[idx]
	if sprite.texture != tex:
		sprite.texture = tex
		var tex_h := float(tex.get_height())
		sprite.pixel_size = 2.35 / tex_h
		sprite.offset.y = tex_h * 0.5


func _process(delta: float) -> void:
	if fighter == null or sprite == null or not is_instance_valid(sprite):
		return

	_time += delta

	# คืนค่าแสง Flash สี
	if _flash_timer > 0.0:
		_flash_timer = maxf(_flash_timer - delta, 0.0)
		if _flash_timer <= 0.0:
			sprite.modulate = _original_modulate

	# สั่นสะเทือนเมื่อโดนโจมตี
	if _hit_shake > 0.0:
		_hit_shake = maxf(_hit_shake - delta * 5.5, 0.0)
		sprite.position.x = randf_range(-1.0, 1.0) * _hit_shake * 0.12
	else:
		sprite.position.x = 0.0

	# นับถอยหลัง Action Lock
	if _action_lock_timer > 0.0:
		_action_lock_timer = maxf(_action_lock_timer - delta, 0.0)

	# เลื่อนเฟรมอนิเมชั่น
	var faction := "white" if fighter.is_white_faction else "black"
	var frames: Array = ANIM_DATA[faction].get(_current_anim, [])
	if not frames.is_empty():
		_anim_timer += delta
		var frame_time := 1.0 / maxf(_anim_fps, 1.0)
		if _anim_timer >= frame_time:
			_anim_timer -= frame_time
			if _anim_frame_idx + 1 < frames.size():
				_anim_frame_idx += 1
				_apply_current_frame()
			elif _anim_loop:
				_anim_frame_idx = 0
				_apply_current_frame()
			elif _action_lock_timer <= 0.0:
				_return_to_guard_stance()

	# ถ้าไม่ได้ล็อกท่าโจมตีอยู่ ให้เล่นท่าตามสถานะ
	if _action_lock_timer <= 0.0:
		match fighter.state:
			FighterController.State.IDLE:
				_update_idle_guard_stance()
			FighterController.State.WINDUP:
				_update_windup_stance()
			FighterController.State.ATTACKING:
				pass # ท่าฟันถูกสั่งจาก _on_attack_started แล้ว
			FighterController.State.STUNNED:
				play_anim("hit_react", 10.0, false, 0.25)
			FighterController.State.DODGE:
				sprite.scale.y = lerpf(sprite.scale.y, _base_scale.y * 0.75, delta * 18.0)
				sprite.scale.x = lerpf(sprite.scale.x, _base_scale.x * 1.25, delta * 18.0)
			FighterController.State.DEAD:
				sprite.rotation.x = lerpf(sprite.rotation.x, -deg_to_rad(85.0), delta * 5.0)
				sprite.position.y = lerpf(sprite.position.y, 0.05, delta * 5.0)
				sprite.modulate.a = lerpf(sprite.modulate.a, 0.35, delta * 4.0)


func _update_idle_guard_stance() -> void:
	# ถ้ากำลังเดิน ให้เล่น idle loop
	if fighter.move_input.length_squared() > 0.05:
		if _current_anim != "idle":
			play_anim("idle", 8.0, true)
		return

	# ถ้าหยุดนิ่ง แสดงท่าหันตามทิศการ์ดที่ตั้งอยู่จริง
	match fighter.guard_direction:
		CombatInputController.GuardDirection.LEFT:
			play_anim("guard_left", 1.0, false)
		CombatInputController.GuardDirection.RIGHT:
			play_anim("guard_right", 1.0, false)
		CombatInputController.GuardDirection.TOP:
			play_anim("guard_top", 1.0, false)


func _update_windup_stance() -> void:
	# แสดงเฟรมง้างดาบของท่าฟันนั้นๆ (Frame 0 ของท่าฟัน)
	var slash_anim := "slash_right"
	match fighter.attack_direction:
		CombatInputController.GuardDirection.LEFT:
			slash_anim = "slash_left"
		CombatInputController.GuardDirection.RIGHT:
			slash_anim = "slash_right"
		CombatInputController.GuardDirection.TOP:
			slash_anim = "slash_top"

	if _current_anim != slash_anim or _anim_frame_idx != 0:
		play_anim(slash_anim, 1.0, false)
		_anim_frame_idx = 0
		_apply_current_frame()


func _return_to_guard_stance() -> void:
	_update_idle_guard_stance()


# ---------------------------------------------------------------- ตอบสนองต่อสัญญาณการต่อสู้

func _on_attack_started(direction: CombatInputController.GuardDirection, is_heavy: bool) -> void:
	var slash_anim := "slash_right"
	match direction:
		CombatInputController.GuardDirection.LEFT:
			slash_anim = "slash_left"
		CombatInputController.GuardDirection.RIGHT:
			slash_anim = "slash_right"
		CombatInputController.GuardDirection.TOP:
			slash_anim = "slash_top"

	var fps := 12.0 if is_heavy else 15.0
	play_anim(slash_anim, fps, false, 0.38)

	var tween := create_tween()
	var squash := Vector3(1.18, 0.84, 1.0) if is_heavy else Vector3(1.12, 0.90, 1.0)
	tween.tween_property(sprite, "scale", _base_scale * squash, 0.05).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "scale", _base_scale, 0.18)


func _on_parry_started() -> void:
	play_anim("parry", 14.0, false, 0.30)
	var tween := create_tween()
	tween.tween_property(sprite, "position:y", 0.16, 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position:y", 0.0, 0.15)


func _on_hit_resolved(result: FighterController.HitResult) -> void:
	if sprite == null:
		return

	match result:
		FighterController.HitResult.PARRIED:
			play_anim("parry", 14.0, false, 0.35)
			sprite.modulate = Color(2.5, 2.3, 1.4) if fighter.is_white_faction else Color(2.0, 1.3, 2.5)
			_flash_timer = 0.15

		FighterController.HitResult.HIT:
			play_anim("hit_react", 12.0, false, 0.28)
			sprite.modulate = Color(3.0, 0.3, 0.3)
			_flash_timer = 0.18
			_hit_shake = 1.0

		FighterController.HitResult.BLOCKED:
			play_anim("parry", 12.0, false, 0.20)
			sprite.modulate = Color(1.8, 1.8, 2.0)
			_flash_timer = 0.08


func _on_state_changed(new_state: FighterController.State) -> void:
	if sprite == null:
		return
	if new_state == FighterController.State.IDLE:
		sprite.position = Vector3.ZERO
		sprite.rotation = Vector3.ZERO
		_return_to_guard_stance()
