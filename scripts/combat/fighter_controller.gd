class_name FighterController
extends CharacterBody3D
## Step 2-5: ค่าพลัง + State Machine + การเดินแบบล็อกเป้า + รองรับสกิล ใช้สคริปต์เดียวกันทั้งผู้เล่นและศัตรู
##   ผู้เล่น: ใส่ Input Controller ใน Inspector แล้วจะรับคำสั่งจากเมาส์/คีย์บอร์ด/ทัชเอง
##   ศัตรู:  ไม่ต้องใส่ Input Controller แต่ให้สคริปต์ AI ตั้ง move_input และเรียก start_attack(), parry() ฯลฯ แทน
##   สกิล:  ใส่โหนดลูกชื่อ "Skills" (สคริปต์ FighterSkills) แล้วเรียก use_skill(ช่อง)
##
## ทิศทางใช้มุมมองของ "หน้าจอผู้เล่น" ร่วมกัน: ศัตรูฟันมาจาก LEFT = ต้องตั้งการ์ด LEFT ถึงจะ Block ได้
## ตัวละครหันหน้าเข้าหา target ตลอด ดังนั้น move_input จึงเทียบกับทิศของศัตรู (หน้า = เดินเข้าหา)

enum State { IDLE, WINDUP, ATTACKING, STUNNED, EXHAUSTED, DODGE, SKILL, DEAD }
## ผลของการโดนโจมตี 1 ครั้ง (ใช้เลือกท่าตอบสนอง เช่น สะดุ้ง / กันกระแทก)
enum HitResult { HIT, BLOCKED, PARRIED, DODGED }

signal state_changed(new_state: State)
signal attack_started(direction: CombatInputController.GuardDirection, is_heavy: bool)
signal skill_started(skill: Skill)
signal parry_started
signal hit_resolved(result: HitResult)
signal guard_direction_changed(new_direction: CombatInputController.GuardDirection)
signal died

const STATE_COLORS := {
	State.WINDUP: Color(1.0, 0.85, 0.2),
	State.ATTACKING: Color(1.0, 0.45, 0.1),
	State.STUNNED: Color(0.7, 0.3, 1.0),
	State.EXHAUSTED: Color(0.4, 0.4, 0.4),
	State.DODGE: Color(0.3, 0.9, 0.9),
	State.SKILL: Color(1.0, 0.25, 0.6),
	State.DEAD: Color(0.1, 0.1, 0.1),
}

## ความเร็วเดินในแต่ละสถานะ (สถานะที่ไม่อยู่ในนี้ = เดินเองไม่ได้)
const STATE_SPEED_MULTIPLIERS := {
	State.IDLE: 1.0,
	State.WINDUP: 0.3,
	State.ATTACKING: 0.3,
	State.EXHAUSTED: 0.6,
}
## แรงผลักลดลงกี่ m/s ต่อวินาที
const KNOCKBACK_DECAY := 25.0
## Block ท่าทะลุเกราะได้ ยังโดนดาเมจเท่านี้
const ARMOR_PIERCING_BLOCKED_RATIO := 0.7

const ParryVFX = preload("res://scripts/vfx/parry_vfx.gd")
const Pixel25DCharacter = preload("res://scripts/art/pixel_25d_character.gd")
const PixelSpriteAnimator = preload("res://scripts/animation/pixel_sprite_animator.gd")
const HD2DCharacter = preload("res://scripts/art/hd2d_character.gd")
const Knight3DCharacterScript = preload("res://scripts/art/knight_3d_character.gd")

@export var fighter_name := "Fighter"
## ใส่เฉพาะตัวละครของผู้เล่น (ลากโหนด CombatInputController มาใส่)
@export var input_controller: CombatInputController
## คู่ต่อสู้ที่จะโดนฟัน
@export var target: FighterController
## โมเดลที่จะเปลี่ยนสีตามสถานะ (ไม่ใส่ก็ได้)
@export var body_mesh: MeshInstance3D
## สีตอน IDLE
@export var base_color := Color(0.85, 0.85, 0.85)
## เปลี่ยนแคปซูลเป็นโมเดล low-poly ตามชนิดหมากตอนเริ่มดวล (โมเดลจะอยู่ใต้ body_mesh จึงขยับตามอนิเมชันชั่วคราว)
@export var use_piece_models := true
## ย้อมสีโมเดล (ฝ่ายดำใช้สีเข้ม)
@export var model_tint := Color.WHITE
## ระบุว่าเป็นฝ่ายขาว (แสง/ทอง) หรือฝ่ายดำ (เงา/ม่วง)
@export var is_white_faction := true

@export_group("Stats")
@export var max_hp := 120.0
@export var max_stamina := 100.0
@export var max_posture := 100.0
@export var stamina_regen_per_sec := 20.0
## ต้องหยุดใช้ Stamina นานเท่านี้ก่อนจะเริ่มฟื้น
@export var stamina_regen_delay := 0.6
@export var posture_regen_per_sec := 8.0
@export var posture_regen_delay := 2.0

@export_group("Attack")
@export var light_windup := 0.55
@export var heavy_windup := 0.95
## เวลาค้างท่าหลังฟันออกไป (สถานะ ATTACKING)
@export var attack_recovery := 0.4
@export var light_damage := 14.0
@export var heavy_damage := 30.0
@export var light_posture_damage := 14.0
@export var heavy_posture_damage := 28.0
@export var light_stamina_cost := 10.0
@export var heavy_stamina_cost := 20.0

@export_group("Defense")
@export var feint_stamina_cost := 20.0
## กด Parry แล้วจะนับว่า Parry สำเร็จ ถ้าดาบศัตรูถึงตัวภายในเวลานี้ (ปรับ 0.33s ให้เหมาะกับทัชสกรีนมือถือ)
@export var parry_window := 0.33
## กด Parry ซ้ำได้อีกครั้งหลังผ่านไปเท่านี้ (กันกดรัว)
@export var parry_cooldown := 0.55
@export var parry_stamina_cost := 10.0
## true = ต้องตั้งการ์ดถูกทิศด้วยถึงจะ Parry ได้
@export var parry_requires_guard_direction := true
## สัดส่วน Stamina สูงสุดที่ศัตรูเสียเมื่อโดน Parry (0.3 = 30%)
@export_range(0.0, 1.0) var parried_stamina_loss_ratio := 0.3
@export var parried_stun_duration := 1.5
@export var guard_break_stun_duration := 2.0
@export var exhausted_duration := 4.0

@export_group("Movement")
@export var move_speed := 3.0
@export var backward_speed_multiplier := 0.75
## ความเร็วหันหน้าเข้าหาเป้า
@export var turn_speed := 12.0
## ศัตรูอยู่ห่างเกินระยะนี้ตอนดาบถึง = ฟันวืด
@export var attack_range := 2.3
## สกิลที่วาร์ป/กระโดด จะไม่พาตัวออกนอกระยะนี้จากกลางสังเวียน (โหนดแม่)
@export var arena_half_extent := 6.3

@export_group("Dodge")
## กด 1 ที: สไลด์สั้น ๆ (ไม่มี I-frames หลบได้ด้วยการออกนอกระยะดาบ)
@export var step_distance := 1.5
@export var step_duration := 0.2
@export var step_stamina_cost := 10.0
## กด 2 ทีติดกัน: กลิ้งไกลกว่า และอมตะช่วงต้น
@export var roll_distance := 3.2
@export var roll_duration := 0.45
@export var roll_iframe_duration := 0.35
@export var roll_stamina_cost := 15.0
## กด Dodge ครั้งที่ 2 ภายในเวลานี้หลังครั้งแรก = กลิ้ง
@export var double_tap_window := 0.3

var hp := 0.0
var stamina := 0.0
var posture := 0.0
var state: State = State.IDLE
var guard_direction: CombatInputController.GuardDirection = CombatInputController.GuardDirection.RIGHT
## ทิศและชนิดของท่าที่กำลังง้าง/ฟันอยู่ (ให้ AI กับ HUD อ่าน)
var attack_direction: CombatInputController.GuardDirection = CombatInputController.GuardDirection.RIGHT
var attack_is_heavy := false
## ทิศที่อยากเดิน: x = ขวา(+)/ซ้าย(-), y = เข้าหาเป้า(+)/ถอย(-)
var move_input := Vector2.ZERO
var dodge_is_roll := false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

## ---- ค่าที่สกิลตั้งได้ระหว่างอยู่ในสถานะ SKILL (ล้างให้เองเมื่อสกิลจบหรือโดนขัด)
var current_skill: Skill
## ความเร็วแนวราบที่สกิลบังคับ (พุ่ง/กระโดด)
var skill_velocity := Vector3.ZERO
## โดนตีแล้วไม่สะดุ้ง ท่าไม่หลุด (ยกเว้นโดนท่าทะลุเกราะ)
var hyper_armor := false
## ข้อความบอกใบ้ให้ HUD เช่น "CHARGE (UNBLOCKABLE)"
var skill_hint := ""

@onready var skills: FighterSkills = get_node_or_null("Skills")

var _guard_break_skill := GuardBreakSkill.new()

var _state_timer := 0.0
var _parry_window_timer := 0.0
var _parry_cooldown_timer := 0.0
var _iframe_timer := 0.0
var _dodge_velocity := Vector3.ZERO
var _knockback_velocity := Vector3.ZERO
var _last_step_time := -1000.0
var _stamina_regen_wait := 0.0
var _posture_regen_wait := 0.0
var _skill_token := 0
var _passing_through_target := false
var _material: StandardMaterial3D
var _model: Node3D
var _state_ring_material: StandardMaterial3D
var sprite_25d: Sprite3D
var sprite_animator_25d: PixelSpriteAnimator
var hd2d_character: HD2DCharacter
var knight_3d: Knight3DCharacter


func _ready() -> void:
	reset_fighter()
	_connect_input()
	if body_mesh != null:
		body_mesh.visible = false
	var visor := get_node_or_null("Visor") as Node3D
	if visor != null:
		visor.visible = false
	_apply_piece_model(ChessPiece.Type.PAWN)


func _process(delta: float) -> void:
	if state == State.DEAD:
		return

	_parry_window_timer = maxf(_parry_window_timer - delta, 0.0)
	_parry_cooldown_timer = maxf(_parry_cooldown_timer - delta, 0.0)
	_iframe_timer = maxf(_iframe_timer - delta, 0.0)
	_update_regen(delta)

	if _state_timer > 0.0:
		_state_timer -= delta
		if _state_timer <= 0.0:
			_on_state_timer_finished()


func _physics_process(delta: float) -> void:
	if input_controller != null:
		move_input = input_controller.get_move_vector()

	_face_target(delta)

	var horizontal := Vector3.ZERO
	if state == State.DODGE:
		horizontal = _dodge_velocity
	elif state == State.SKILL:
		horizontal = skill_velocity
	else:
		var speed: float = move_speed * STATE_SPEED_MULTIPLIERS.get(state, 0.0)
		if move_input.y < 0.0:
			speed *= backward_speed_multiplier
		horizontal = _get_move_direction(move_input) * speed

	horizontal += _knockback_velocity
	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, KNOCKBACK_DECAY * delta)

	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()


func reset_fighter() -> void:
	hp = max_hp
	stamina = max_stamina
	posture = max_posture
	_parry_window_timer = 0.0
	_parry_cooldown_timer = 0.0
	_iframe_timer = 0.0
	_knockback_velocity = Vector3.ZERO
	_stamina_regen_wait = 0.0
	_posture_regen_wait = 0.0
	_change_state(State.IDLE)


## เตรียมตัวก่อนดวล: รับชื่อ HP และชุดสกิลมาจากตัวหมากที่ลงสนาม (Stamina/Posture เริ่มเต็มใหม่ทุกครั้ง)
func setup_for_duel(display_name: String, current_hp: float, new_max_hp: float, piece_type: ChessPiece.Type, white_faction := true) -> void:
	is_white_faction = white_faction
	fighter_name = display_name
	max_hp = new_max_hp
	reset_fighter()
	hp = current_hp
	move_input = Vector2.ZERO
	velocity = Vector3.ZERO
	if skills != null:
		skills.load_skills(SkillLibrary.create_for(piece_type))
	_apply_piece_model(piece_type)


## ใส่โมเดล 3D แบบเต็มระบบ (Pawned Souls / Soulslike 3D Chess Character System)
func _apply_piece_model(_piece_type: ChessPiece.Type) -> void:
	if body_mesh != null:
		body_mesh.visible = false
		body_mesh.mesh = null
	var visor := get_node_or_null("Visor") as Node3D
	if visor != null:
		visor.visible = false

	if sprite_25d != null and is_instance_valid(sprite_25d):
		sprite_25d.queue_free()
		sprite_25d = null
	if sprite_animator_25d != null and is_instance_valid(sprite_animator_25d):
		sprite_animator_25d.queue_free()
		sprite_animator_25d = null

	if hd2d_character != null and is_instance_valid(hd2d_character):
		hd2d_character.queue_free()
		hd2d_character = null

	if knight_3d != null and is_instance_valid(knight_3d):
		knight_3d.queue_free()
		knight_3d = null

	# True 3D Knight Character System (Pawned Souls / Soulslike 3D Rigged Knight)
	knight_3d = Knight3DCharacterScript.build(is_white_faction)
	add_child(knight_3d)

	var anim := get_node_or_null("Animator") as FighterAnimator
	if anim != null and knight_3d != null:
		var ap := knight_3d.get_animation_player()
		if ap != null:
			anim.bind_animation_player(ap)


# ---------------------------------------------------------------- Actions (เรียกจาก Input หรือ AI)

func set_guard_direction(direction: CombatInputController.GuardDirection) -> void:
	if state == State.DEAD:
		return
	if guard_direction == direction:
		return
	guard_direction = direction
	guard_direction_changed.emit(guard_direction)


func start_attack(direction: CombatInputController.GuardDirection, is_heavy: bool) -> void:
	if state != State.IDLE:
		_log("โจมตีไม่ได้ ตอนนี้อยู่ในสถานะ %s" % state_name())
		return

	guard_direction = direction
	attack_direction = direction
	attack_is_heavy = is_heavy
	_change_state(State.WINDUP, heavy_windup if is_heavy else light_windup)
	_spend_stamina(heavy_stamina_cost if is_heavy else light_stamina_cost)
	_log("ง้าง %s จาก %s" % [_attack_name(), _dir_name(direction)])
	if hd2d_character != null:
		hd2d_character.play_windup(direction)
	attack_started.emit(direction, is_heavy)


func feint() -> void:
	if state != State.WINDUP:
		_log("Feint ได้เฉพาะตอนกำลังง้าง Heavy")
		return
	if not attack_is_heavy:
		_log("Light Attack ยกเลิกไม่ได้")
		return

	_spend_stamina(feint_stamina_cost)
	_log("FEINT! ยกเลิก Heavy (-%d Stamina)" % feint_stamina_cost)
	_change_state(State.IDLE)


## กด Parry ระหว่างง้าง Heavy = Feint ยกเลิกท่า (มือถือไม่มีปุ่ม Feint แยก)
func parry() -> void:
	if state == State.WINDUP and attack_is_heavy:
		feint()
		return
	if state != State.IDLE:
		_log("Parry ไม่ได้ ตอนนี้อยู่ในสถานะ %s" % state_name())
		return
	if _parry_cooldown_timer > 0.0:
		_log("Parry ยังไม่พร้อม")
		return

	_parry_window_timer = parry_window
	_parry_cooldown_timer = parry_cooldown
	_log("ตั้งท่า Parry ทาง %s" % _dir_name(guard_direction))
	_spend_stamina(parry_stamina_cost)
	if hd2d_character != null:
		hd2d_character.play_parry()
	parry_started.emit()


## เปิดหน้าต่าง Parry เป็นเวลานานพิเศษ (สำหรับสกิลเคาน์เตอร์ เช่น King's Gambit)
func open_parry_window(duration: float) -> void:
	_parry_window_timer = duration
	_parry_cooldown_timer = duration + 0.2
	if hd2d_character != null:
		hd2d_character.play_parry()
	parry_started.emit()


## กดครั้งแรก = สไลด์สั้น ถ้ากดซ้ำภายใน double_tap_window = เปลี่ยนเป็นกลิ้งพร้อม I-frames
## (ไม่รอดูว่าจะกดซ้ำไหม สไลด์ออกทันทีเพื่อให้ตอบสนองไว)
func dodge() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var is_double_tap := now - _last_step_time <= double_tap_window
	var can_roll := state == State.IDLE or (state == State.DODGE and not dodge_is_roll)
	if is_double_tap and can_roll and stamina > 0.0:
		_start_dodge(true)
		return

	if state != State.IDLE:
		_log("Dodge ไม่ได้ ตอนนี้อยู่ในสถานะ %s" % state_name())
		return
	_start_dodge(false)
	_last_step_time = now


## Guard Break: ใช้ระบบเดียวกับสกิล แต่ไม่มี Cooldown และทุกหมากใช้ได้
func guard_break() -> void:
	if not can_start_skill():
		_log("Guard Break ไม่ได้ ตอนนี้อยู่ในสถานะ %s" % state_name())
		return
	var token := begin_skill(_guard_break_skill)
	await _guard_break_skill.execute(self, token)
	end_skill(token)


func use_skill(slot: int) -> void:
	if skills == null:
		_log("ตัวนี้ไม่มีระบบสกิล")
		return
	skills.try_use(slot)


func _start_dodge(is_roll: bool) -> void:
	var direction := _get_move_direction(move_input).normalized()
	if direction == Vector3.ZERO:
		# ไม่ได้กดทิศ: กลิ้งต่อทิศเดิมของสไลด์ หรือถ้ายืนนิ่งก็ถอยหลัง
		direction = _dodge_velocity.normalized() if state == State.DODGE else -flat_direction_to_target()

	dodge_is_roll = is_roll
	var distance := roll_distance if is_roll else step_distance
	var duration := roll_duration if is_roll else step_duration
	_dodge_velocity = direction * distance / duration
	_change_state(State.DODGE, duration)

	if is_roll:
		set_iframes(roll_iframe_duration)
		_last_step_time = -1000.0
		_log("ROLL! (อมตะ %.2fs)" % roll_iframe_duration)
		_spend_stamina(roll_stamina_cost)
	else:
		_log("STEP DODGE")
		_spend_stamina(step_stamina_cost)


# ---------------------------------------------------------------- Skill API (ให้ FighterSkills และตัวสกิลเรียก)

func can_start_skill() -> bool:
	return state == State.IDLE and stamina > 0.0


## เข้าสถานะ SKILL แล้วคืน "ตั๋ว" ของสกิลนี้ ตัวสกิลต้องเช็ก is_skill_running(ตั๋ว) หลังรอทุกครั้ง
## ถ้าโดนขัด/โดน Parry/ตาย ตั๋วจะใช้ไม่ได้ และสกิลต้องหยุดทันที
func begin_skill(skill: Skill) -> int:
	_skill_token += 1
	_change_state(State.SKILL)
	current_skill = skill
	_spend_stamina(skill.stamina_cost)
	_log("ใช้สกิล %s!" % skill.display_name)
	skill_started.emit(skill)
	return _skill_token


func is_skill_running(token: int) -> bool:
	return state == State.SKILL and token == _skill_token


## สกิลเล่นจบ: เข้าช่วงค้างท่าเหมือนฟันปกติ
func end_skill(token: int) -> void:
	if is_skill_running(token):
		_change_state(State.ATTACKING, attack_recovery)


func set_iframes(seconds: float) -> void:
	_iframe_timer = maxf(_iframe_timer, seconds)


func apply_knockback(push_velocity: Vector3) -> void:
	push_velocity.y = 0.0
	_knockback_velocity = push_velocity


## ให้ตัวทะลุผ่านคู่ต่อสู้ได้ชั่วคราว (เช่นตอนกระโดดข้ามหัว)
func set_pass_through_target(enabled: bool) -> void:
	if target == null or enabled == _passing_through_target:
		return
	_passing_through_target = enabled
	if enabled:
		add_collision_exception_with(target)
	else:
		remove_collision_exception_with(target)


## ย้ายตัวทันที (วาร์ป)
func teleport_to(world_position: Vector3) -> void:
	global_position = world_position
	velocity = Vector3.ZERO
	reset_physics_interpolation()


## บีบตำแหน่งไม่ให้ออกนอกสังเวียน
func clamp_to_arena(world_position: Vector3) -> Vector3:
	var arena := get_parent() as Node3D
	if arena == null:
		return world_position
	var local := arena.to_local(world_position)
	local.x = clampf(local.x, -arena_half_extent, arena_half_extent)
	local.z = clampf(local.z, -arena_half_extent, arena_half_extent)
	return arena.to_global(local)


func _cleanup_skill() -> void:
	current_skill = null
	skill_velocity = Vector3.ZERO
	hyper_armor = false
	skill_hint = ""
	set_pass_through_target(false)


# ---------------------------------------------------------------- โดนโจมตี

## ถูกเรียกตอนท่าของอีกฝ่ายถึงตัว (ทั้งฟันปกติ สกิล กระสุน และระเบิด)
func receive_hit(attack: AttackData) -> void:
	if state == State.DEAD:
		return
	if _iframe_timer > 0.0:
		if not attack.ignore_iframes:
			_log("หลบ %s พ้นด้วย I-frames!" % attack.attack_name)
			hit_resolved.emit(HitResult.DODGED)
			return
		_log("%s กลิ้งหลบไม่ได้!" % attack.attack_name)

	var guard_matches := attack.direction == guard_direction
	var can_defend := state == State.IDLE or state == State.EXHAUSTED

	var parry_direction_ok := guard_matches or not parry_requires_guard_direction
	if can_defend and _parry_window_timer > 0.0 and parry_direction_ok and not attack.unparryable:
		_parry_window_timer = 0.0
		var clash_pos: Vector3
		if attack.attacker != null:
			clash_pos = global_position.lerp(attack.attacker.global_position, 0.45) + Vector3.UP * 1.2
		else:
			clash_pos = global_position + Vector3.UP * 1.2 + (-global_basis.z) * 0.8
		ParryVFX.spawn(get_parent(), clash_pos, local_visual_direction(attack.direction), is_white_faction)
		if attack.parry_stuns_attacker and attack.attacker != null:
			_log("PARRY %s สำเร็จ! %s ติด Stunned" % [attack.attack_name, attack.attacker.fighter_name])
			attack.attacker.apply_parried()
		else:
			_log("PARRY ปัด %s ทิ้ง!" % attack.attack_name)
		hit_resolved.emit(HitResult.PARRIED)
		return

	if can_defend and guard_matches and not attack.unblockable:
		_block(attack)
		return

	_take_hit(attack)


## ถูกเรียกเมื่อท่าของเราโดนอีกฝ่าย Parry
func apply_parried() -> void:
	var loss := max_stamina * parried_stamina_loss_ratio
	stamina = maxf(stamina - loss, 0.0)
	_stamina_regen_wait = stamina_regen_delay
	_log("โดน Parry! Stunned และเสีย %d Stamina" % loss)
	if hd2d_character != null:
		hd2d_character.play_hit_react()
	_change_state(State.STUNNED, parried_stun_duration)


func _block(attack: AttackData) -> void:
	hit_resolved.emit(HitResult.BLOCKED)
	if attack.guard_break:
		_log("BLOCK %s แต่การ์ดแตก!" % attack.attack_name)
		_break_guard()
	elif attack.armor_piercing:
		_log("BLOCK ไม่อยู่! %s ทะลุเกราะ" % attack.attack_name)
		if _apply_damage(attack.damage * ARMOR_PIERCING_BLOCKED_RATIO):
			return
		_take_posture_damage(attack.posture_damage)
	else:
		_log("BLOCK %s จาก %s" % [attack.attack_name, _dir_name(attack.direction)])
		_take_posture_damage(attack.posture_damage)
	_apply_knockback_from(attack, 0.5)


func _take_hit(attack: AttackData) -> void:
	hit_resolved.emit(HitResult.HIT)
	if hd2d_character != null:
		hd2d_character.play_hit_react()
	if _apply_damage(attack.damage):
		return
	_apply_knockback_from(attack, 1.0)

	if attack.guard_break:
		_break_guard()
		return
	if hyper_armor and not attack.armor_piercing:
		_log("Hyper Armor! ท่าไม่หลุด")
		return
	if state == State.WINDUP or state == State.SKILL:
		_log("ท่าโดนขัดจังหวะ")
		_change_state(State.IDLE)


## ลด HP คืนค่า true ถ้าตาย
func _apply_damage(amount: float) -> bool:
	if amount <= 0.0:
		return false
	hp = maxf(hp - amount, 0.0)
	_log("โดน -%d HP (เหลือ %d)" % [amount, hp])
	if hp > 0.0:
		return false
	_log("แพ้แล้ว!")
	_change_state(State.DEAD)
	died.emit()
	return true


func _apply_knockback_from(attack: AttackData, multiplier: float) -> void:
	if attack.knockback <= 0.0:
		return
	var away := global_position - attack.origin
	away.y = 0.0
	if away.length_squared() < 0.0001:
		away = -flat_direction_to_target()
	apply_knockback(away.normalized() * attack.knockback * multiplier)


func _take_posture_damage(amount: float) -> void:
	posture = maxf(posture - amount, 0.0)
	_posture_regen_wait = posture_regen_delay
	if posture <= 0.0:
		_break_guard()


func _break_guard() -> void:
	posture = 0.0
	_posture_regen_wait = posture_regen_delay
	_log("การ์ดแตก! Stunned")
	_change_state(State.STUNNED, guard_break_stun_duration)


# ---------------------------------------------------------------- State machine

func _change_state(new_state: State, duration: float = 0.0) -> void:
	# Stamina หมดเมื่อไร พอทำท่าปัจจุบันเสร็จจะเข้า Exhausted ทันที
	if new_state == State.IDLE and stamina <= 0.0:
		new_state = State.EXHAUSTED
		duration = exhausted_duration
		_log("Stamina หมด! Exhausted %.0f วินาที" % duration)

	if state == State.SKILL:
		_cleanup_skill()
	state = new_state
	_state_timer = duration
	_update_body_color()
	state_changed.emit(state)


func _on_state_timer_finished() -> void:
	match state:
		State.WINDUP:
			_release_attack()
		State.ATTACKING, State.EXHAUSTED, State.DODGE:
			_change_state(State.IDLE)
		State.STUNNED:
			if posture <= 0.0:
				posture = max_posture
			_change_state(State.IDLE)


func _release_attack() -> void:
	_change_state(State.ATTACKING, attack_recovery)
	if hd2d_character != null:
		hd2d_character.play_attack(attack_direction)
	preload("res://scripts/skills/blood_slash.gd").spawn(get_parent(), global_position, flat_direction_to_target(), local_visual_direction(attack_direction), attack_is_heavy)
	_log("ฟัน %s จาก %s!" % [_attack_name(), _dir_name(attack_direction)])
	if target == null:
		return
	var distance := flat_distance_to_target()
	if distance > attack_range:
		_log("ฟันวืด! เป้าอยู่ห่าง %.1f เมตร" % distance)
		return
	var attack := AttackData.new(self, attack_direction,
		heavy_damage if attack_is_heavy else light_damage,
		heavy_posture_damage if attack_is_heavy else light_posture_damage)
	attack.attack_name = _attack_name()
	target.receive_hit(attack)


func _spend_stamina(amount: float) -> void:
	stamina = maxf(stamina - amount, 0.0)
	_stamina_regen_wait = stamina_regen_delay
	if stamina <= 0.0 and state == State.IDLE:
		_change_state(State.IDLE)


func _update_regen(delta: float) -> void:
	var is_attacking := state == State.WINDUP or state == State.ATTACKING or state == State.SKILL
	if _stamina_regen_wait > 0.0:
		_stamina_regen_wait -= delta
	elif not is_attacking:
		stamina = minf(stamina + stamina_regen_per_sec * delta, max_stamina)

	if _posture_regen_wait > 0.0:
		_posture_regen_wait -= delta
	elif state != State.STUNNED:
		posture = minf(posture + posture_regen_per_sec * delta, max_posture)


# ---------------------------------------------------------------- Movement

func flat_direction_to_target() -> Vector3:
	var forward := -global_basis.z
	if target != null:
		forward = target.global_position - global_position
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return Vector3.FORWARD
	return forward.normalized()


## Combat directions share the player's view; opposing models face the other way.
## Keep damage/guard comparisons in screen space and convert only at rendering.
func local_visual_direction(direction: int) -> int:
	if input_controller == null and target != null and target.input_controller != null:
		if direction == CombatInputController.GuardDirection.LEFT:
			return CombatInputController.GuardDirection.RIGHT
		if direction == CombatInputController.GuardDirection.RIGHT:
			return CombatInputController.GuardDirection.LEFT
	return direction


func flat_distance_to_target() -> float:
	if target == null:
		return INF
	var offset := target.global_position - global_position
	offset.y = 0.0
	return offset.length()


## แปลง move_input (หน้า/ข้าง) เป็นทิศในโลก 3D โดยยึดทิศของเป้าเป็น "หน้า"
func _get_move_direction(input: Vector2) -> Vector3:
	var forward := flat_direction_to_target()
	var right := forward.cross(Vector3.UP)
	return (forward * input.y + right * input.x).limit_length(1.0)


## Lock-on: หมุนตัวให้หน้า (-Z) หันเข้าหาเป้าตลอด
func _face_target(delta: float) -> void:
	if target == null or state == State.DEAD:
		return
	var forward := flat_direction_to_target()
	var desired_yaw := atan2(-forward.x, -forward.z)
	rotation.y = lerp_angle(rotation.y, desired_yaw, clampf(turn_speed * delta, 0.0, 1.0))


# ---------------------------------------------------------------- Helpers

func _connect_input() -> void:
	if input_controller == null:
		return
	guard_direction = input_controller.current_guard_direction
	input_controller.guard_direction_changed.connect(set_guard_direction)
	input_controller.light_attack_requested.connect(start_attack.bind(false))
	input_controller.heavy_attack_requested.connect(start_attack.bind(true))
	input_controller.guard_break_requested.connect(guard_break)
	input_controller.feint_requested.connect(feint)
	input_controller.parry_requested.connect(parry)
	input_controller.dodge_requested.connect(dodge)
	input_controller.skill_requested.connect(use_skill)


func _update_body_color() -> void:
	if _state_ring_material != null:
		var ring_color: Color = STATE_COLORS.get(state, base_color)
		_state_ring_material.albedo_color = ring_color
		_state_ring_material.emission = ring_color
	if body_mesh == null:
		return
	if _material == null:
		_material = StandardMaterial3D.new()
		body_mesh.material_override = _material
	_material.albedo_color = STATE_COLORS.get(state, base_color)


func state_name() -> String:
	return State.keys()[state]


func _attack_name() -> String:
	return "Heavy" if attack_is_heavy else "Light"


func _dir_name(direction: CombatInputController.GuardDirection) -> String:
	return CombatInputController.GuardDirection.keys()[direction]


## ให้สคริปต์อื่น (เช่นสกิล) พิมพ์ข้อความในชื่อของนักสู้คนนี้
func log_event(message: String) -> void:
	_log(message)


func _log(message: String) -> void:
	print("[%s] %s" % [fighter_name, message])
