class_name FighterAnimator
extends Node
## Step 7: เชื่อมสถานะของ FighterController เข้ากับอนิเมชัน (ใส่เป็นโหนดลูกชื่อ "Animator" ใต้ตัวละคร)
##
## วิธีทำงาน: ฟังสัญญาณจาก FighterController แล้วสั่ง AnimationPlayer เล่นท่า (crossfade ให้ลื่น)
##   ยืน/เดิน (IDLE, EXHAUSTED) -> เลือกท่าเดินตาม move_input: หน้า / ถอย / สไลด์ซ้าย / สไลด์ขวา
##   attack_started            -> ท่าฟันตามทิศ LEFT / RIGHT / TOP (ปรับความเร็วให้ตรงกับเวลาง้าง)
##   hit_resolved              -> สะดุ้ง (โดน) / กันกระแทก (Block)
##   state DODGE / STUNNED / DEAD -> กลิ้ง-สไลด์ / มึน / ตาย
##
## AnimationPlayer: ถ้าไม่ได้ใส่เอง จะค้นหาในโมเดลที่อยู่ใต้ตัวละครให้อัตโนมัติ
##   ถ้าไม่เจอเลย (ยังใช้แคปซูล) จะสร้างอนิเมชันชั่วคราวให้ (PlaceholderAnimations)
## ชื่อท่าแต่ละช่อง: เปิดเกมครั้งแรกแล้วดูแท็บ Output จะมีรายชื่ออนิเมชันทั้งหมดให้ก๊อปมาใส่

@export var animation_player: AnimationPlayer
## สร้างอนิเมชันชั่วคราวให้แคปซูล ถ้าหา AnimationPlayer ไม่เจอ
@export var create_placeholder_animations := true

@export_group("Locomotion")
@export var anim_idle := "idle"
@export var anim_walk_forward := "walk_forward"
@export var anim_walk_back := "walk_back"
@export var anim_strafe_left := "strafe_left"
@export var anim_strafe_right := "strafe_right"
@export var anim_exhausted := ""
@export var anim_guard_left := "guard_left"
@export var anim_guard_right := "guard_right"
@export var anim_guard_top := "guard_top"

@export_group("Attacks")
@export var anim_attack_left := "attack_left"
@export var anim_attack_right := "attack_right"
@export var anim_attack_top := "attack_top"
## ท่า Heavy แยก (ว่าง = ใช้ท่า Light ทิศเดียวกันแต่เล่นช้าลง)
@export var anim_heavy_left := ""
@export var anim_heavy_right := ""
@export var anim_heavy_top := ""
## ว่าง = ใช้ท่าฟันบน
@export var anim_guard_break := "attack_top"
## ท่ากลางสำหรับทุกสกิล (ว่าง = ใช้ท่าฟันบน)
@export var anim_skill := "attack_top"
## ท่าเฉพาะของแต่ละสกิล: { "ชื่อสกิล": "ชื่ออนิเมชัน" } เช่น { "Leap Strike": "mixamo/Jump Attack" }
@export var skill_animations := {}

@export_group("Reactions")
@export var anim_hit_react := "hit_react"
@export var anim_block_impact := "block_impact"
@export var anim_parry := "parry"
@export var anim_parry_deflect := "parry"
## ว่าง = ใช้ท่าสะดุ้ง
@export var anim_stunned := "hit_react"
@export var anim_death := "death"

@export_group("Dodge")
@export var anim_dodge_roll := "dodge_roll"
## ว่าง = ใช้ท่ากลิ้งแบบเร่งความเร็ว
@export var anim_dodge_step := "dodge_step"

@export_group("Tuning")
## เวลา crossfade ตอนเปลี่ยนท่าเดิน
@export var locomotion_blend := 0.2
## เวลา crossfade ตอนเข้าท่าโจมตี/ตอบสนอง (สั้น = ตอบสนองไว)
@export var action_blend := 0.08
## ดันจอยน้อยกว่านี้ = ยืนนิ่ง
@export var move_threshold := 0.15
## ล็อกกระดูกสะโพก (Hips) ไม่ให้ท่าพาตัวเลื่อนไปเอง (ใช้กับท่า Mixamo ที่ไม่ได้ติ๊ก In Place)
@export var lock_root_motion := true
## พิมพ์รายชื่ออนิเมชันทั้งหมดตอนเริ่มเกม
@export var print_animation_list := true

var fighter: FighterController

var _current := ""
var _action_lock_until := 0.0
var _warned := {}


func _ready() -> void:
	# รอให้ตัวละครโหลดลูกครบก่อน (สร้าง AnimationPlayer ชั่วคราวระหว่างนั้นไม่ได้)
	_setup.call_deferred()


func _setup() -> void:
	fighter = get_parent() as FighterController
	if fighter == null:
		push_warning("FighterAnimator ต้องอยู่ใต้โหนด FighterController")
		set_process(false)
		return

	if animation_player == null:
		animation_player = _find_animation_player()
	if animation_player == null and create_placeholder_animations:
		animation_player = PlaceholderAnimations.create(fighter)
		_fill_placeholder_names()
	if animation_player == null:
		push_warning("FighterAnimator (%s): ไม่พบ AnimationPlayer" % fighter.name)
		set_process(false)
		return

	_prepare_animations()
	if print_animation_list:
		print("[Animator] %s ใช้ AnimationPlayer '%s' มีท่า: %s" % [fighter.name, animation_player.name, ", ".join(animation_player.get_animation_list())])

	_connect_signals()


func _connect_signals() -> void:
	if fighter == null:
		return
	if not fighter.state_changed.is_connected(_on_state_changed):
		fighter.state_changed.connect(_on_state_changed)
	if not fighter.attack_started.is_connected(_on_attack_started):
		fighter.attack_started.connect(_on_attack_started)
	if not fighter.skill_started.is_connected(_on_skill_started):
		fighter.skill_started.connect(_on_skill_started)
	if not fighter.hit_resolved.is_connected(_on_hit_resolved):
		fighter.hit_resolved.connect(_on_hit_resolved)
	if not fighter.parry_started.is_connected(_on_parry_started):
		fighter.parry_started.connect(_on_parry_started)
	if fighter.has_signal("guard_direction_changed") and not fighter.guard_direction_changed.is_connected(_on_guard_direction_changed):
		fighter.guard_direction_changed.connect(_on_guard_direction_changed)


func bind_animation_player(new_player: AnimationPlayer) -> void:
	if new_player == null:
		return
	if fighter == null:
		fighter = get_parent() as FighterController
	_connect_signals()
	animation_player = new_player
	_current = ""
	_action_lock_until = 0.0
	_prepare_animations()
	if print_animation_list:
		print("[Animator] %s bind 3D AnimationPlayer '%s' with %d anims: %s" % [
			fighter.name if fighter else "Fighter",
			animation_player.name,
			animation_player.get_animation_list().size(),
			", ".join(animation_player.get_animation_list())
		])
	if fighter != null:
		var walking_state := fighter.state == FighterController.State.IDLE or fighter.state == FighterController.State.EXHAUSTED
		if walking_state:
			_update_locomotion()


func _on_guard_direction_changed(_new_dir: CombatInputController.GuardDirection) -> void:
	if fighter == null:
		return
	var walking_state := fighter.state == FighterController.State.IDLE or fighter.state == FighterController.State.EXHAUSTED
	if walking_state and _now() >= _action_lock_until:
		_update_locomotion()


func _process(_delta: float) -> void:
	var walking_state := fighter.state == FighterController.State.IDLE or fighter.state == FighterController.State.EXHAUSTED
	if walking_state and _now() >= _action_lock_until:
		_update_locomotion()


# ---------------------------------------------------------------- ตอบสนองสัญญาณจากตัวละคร

func _on_state_changed(state: FighterController.State) -> void:
	match state:
		FighterController.State.ATTACKING:
			# Placeholder impact starts at 0.45: synchronize with damage/VFX release.
			if _current.begins_with("placeholder/attack_"):
				animation_player.play(_current, 0.0, 0.55 / fighter.attack_recovery)
				animation_player.seek(0.45, true)
		FighterController.State.DODGE:
			if fighter.dodge_is_roll:
				_play_fitted(anim_dodge_roll, fighter.roll_duration)
			elif not _play_fitted(anim_dodge_step, fighter.step_duration):
				_play_fitted(anim_dodge_roll, fighter.step_duration)
		FighterController.State.STUNNED:
			if not _play(anim_stunned, action_blend):
				_play(anim_hit_react, action_blend, 1.0, true)
		FighterController.State.DEAD:
			_play(anim_death, action_blend)
		FighterController.State.IDLE, FighterController.State.EXHAUSTED:
			_update_locomotion()


func _on_attack_started(direction: CombatInputController.GuardDirection, is_heavy: bool) -> void:
	direction = fighter.local_visual_direction(direction) as CombatInputController.GuardDirection
	var duration := (fighter.heavy_windup if is_heavy else fighter.light_windup) + fighter.attack_recovery
	var heavy_name: String = [anim_heavy_left, anim_heavy_right, anim_heavy_top][direction]
	var light_name: String = [anim_attack_left, anim_attack_right, anim_attack_top][direction]
	if not (is_heavy and _play_fitted(heavy_name, duration)):
		_play_fitted(light_name, duration)
	if _current.begins_with("placeholder/attack_"):
		var windup := fighter.heavy_windup if is_heavy else fighter.light_windup
		animation_player.play(_current, action_blend, 0.45 / windup)
		animation_player.seek(0.0, true)


func _on_skill_started(skill: Skill) -> void:
	_action_lock_until = 0.0
	var anim_name: String = skill_animations.get(skill.display_name, "")
	if anim_name.is_empty():
		anim_name = anim_guard_break if skill is GuardBreakSkill else anim_skill
	if not _play(anim_name, action_blend, 1.0, true):
		_play(anim_attack_top, action_blend, 1.0, true)


func _on_hit_resolved(result: FighterController.HitResult) -> void:
	if fighter.state == FighterController.State.DEAD or fighter.state == FighterController.State.STUNNED:
		return
	match result:
		FighterController.HitResult.HIT:
			if not fighter.hyper_armor:
				_play_one_shot(anim_hit_react)
		FighterController.HitResult.BLOCKED:
			_play_one_shot(anim_block_impact)
		FighterController.HitResult.PARRIED:
			if _has(anim_parry_deflect):
				_play_one_shot(anim_parry_deflect)
			else:
				_play_one_shot(anim_parry)


func _on_parry_started() -> void:
	_play_one_shot(anim_parry)


# ---------------------------------------------------------------- ท่าเดิน (Strafe)

func _update_locomotion() -> void:
	if fighter == null:
		fighter = get_parent() as FighterController
	if fighter == null:
		return
	var input := fighter.move_input
	var exhausted := fighter.state == FighterController.State.EXHAUSTED
	var anim_name := anim_idle
	if input.length() >= move_threshold:
		if absf(input.y) >= absf(input.x):
			anim_name = anim_walk_forward if input.y > 0.0 else anim_walk_back
		else:
			anim_name = anim_strafe_right if input.x > 0.0 else anim_strafe_left
	elif exhausted and not anim_exhausted.is_empty():
		anim_name = anim_exhausted
	else:
		# Standing in place: hold 3D For Honor / Pawned Souls guard stance!
		var dir := fighter.local_visual_direction(fighter.guard_direction)
		match dir:
			CombatInputController.GuardDirection.LEFT:
				if not anim_guard_left.is_empty() and _has(anim_guard_left):
					anim_name = anim_guard_left
			CombatInputController.GuardDirection.RIGHT:
				if not anim_guard_right.is_empty() and _has(anim_guard_right):
					anim_name = anim_guard_right
			CombatInputController.GuardDirection.TOP:
				if not anim_guard_top.is_empty() and _has(anim_guard_top):
					anim_name = anim_guard_top
	_play(anim_name, locomotion_blend, 0.7 if exhausted else 1.0)


# ---------------------------------------------------------------- เล่นอนิเมชัน

## เล่นท่า (ถ้าเป็นท่าเดิมที่เล่นอยู่จะไม่เริ่มใหม่ ยกเว้น restart = true) คืนค่า false ถ้าไม่มีท่านี้
func _play(anim_name: String, blend: float, speed: float = 1.0, restart: bool = false) -> bool:
	if not _has(anim_name):
		return false
	if anim_name == _current and not restart and animation_player.is_playing():
		return true
	animation_player.play(anim_name, blend, speed)
	if restart:
		animation_player.seek(0.0, true)
	_current = anim_name
	return true


## เล่นท่าโดยปรับความเร็วให้จบพอดีกับ duration (เช่น ท่าฟันให้ตรงกับเวลาง้าง + ค้างท่า)
func _play_fitted(anim_name: String, duration: float) -> bool:
	if not _has(anim_name) or duration <= 0.0:
		return false
	var speed := animation_player.get_animation(anim_name).length / duration
	return _play(anim_name, action_blend, speed, true)


## เล่นท่าสั้น ๆ ทับท่าเดิน (สะดุ้ง, กันกระแทก, Parry) แล้วค่อยกลับไปเดินเมื่อท่าจบ
func _play_one_shot(anim_name: String) -> void:
	if _play(anim_name, action_blend, 1.0, true):
		_action_lock_until = _now() + animation_player.get_animation(anim_name).length


func _has(anim_name: String) -> bool:
	if anim_name.is_empty():
		return false
	if animation_player.has_animation(anim_name):
		return true
	if not _warned.has(anim_name):
		_warned[anim_name] = true
		push_warning("FighterAnimator (%s): ไม่พบท่า '%s' (ดูชื่อที่ถูกต้องในแท็บ Output)" % [fighter.name, anim_name])
	return false


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


# ---------------------------------------------------------------- เตรียมอนิเมชัน

func _find_animation_player() -> AnimationPlayer:
	for node in fighter.find_children("*", "AnimationPlayer", true, false):
		return node
	return null


func _fill_placeholder_names() -> void:
	for property: String in PlaceholderAnimations.DEFAULT_NAMES:
		if String(get(property)).is_empty():
			set(property, PlaceholderAnimations.DEFAULT_NAMES[property])


## ตั้งให้ท่าเดิน/ยืน/มึนวนซ้ำ ท่าอื่นเล่นครั้งเดียว และล็อก Hips ไม่ให้ท่าพาตัวเลื่อน
func _prepare_animations() -> void:
	var looping := [
		anim_idle, anim_walk_forward, anim_walk_back, anim_strafe_left, anim_strafe_right,
		anim_exhausted, anim_stunned, anim_guard_left, anim_guard_right, anim_guard_top
	]
	for anim_name in animation_player.get_animation_list():
		var animation := animation_player.get_animation(anim_name)
		animation.loop_mode = Animation.LOOP_LINEAR if anim_name in looping else Animation.LOOP_NONE
		if lock_root_motion:
			_lock_hips_position(animation, anim_name)


func _lock_hips_position(animation: Animation, anim_name: String) -> void:
	for track in animation.get_track_count():
		if animation.track_get_type(track) != Animation.TYPE_POSITION_3D:
			continue
		if not String(animation.track_get_path(track)).to_lower().ends_with("hips"):
			continue
		if animation.track_is_compressed(track):
			push_warning("FighterAnimator: ท่า '%s' ถูกบีบอัด ล็อก Hips ไม่ได้ (ปิด Compression ตอน Import หรือติ๊ก In Place ใน Mixamo)" % anim_name)
			return
		var first: Vector3 = animation.track_get_key_value(track, 0)
		for key in animation.track_get_key_count(track):
			var value: Vector3 = animation.track_get_key_value(track, key)
			animation.track_set_key_value(track, key, Vector3(first.x, value.y, first.z))
