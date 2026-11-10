class_name CombatAI
extends Node
## Step 3: สมองกลศัตรูสำหรับดวล 1v1
##   - คุมระยะ: เดินเข้าเมื่อไกล ถอยเมื่อใกล้ และสุ่มเดินวนซ้าย/ขวา
##   - บุก: สุ่มเปลี่ยนการ์ด และโจมตีสลับซ้าย/ขวา/บน (ไม่ฟันทิศเดิมซ้ำติดกัน) บางทีก็ Feint
##   - รับ: ตอนผู้เล่นฟันมา มีโอกาส Block / Parry / ถอยหลบ
##   - สกิล: ถ้ามีสกิลที่พร้อมใช้และระยะเหมาะ มีโอกาสใช้แทนการฟันปกติ และพยายามกลิ้งหลบสกิลของผู้เล่น
## AI สั่งตัวละครผ่านฟังก์ชันเดียวกับที่ผู้เล่นใช้ จึงต้องทำตามกฎเดียวกันทุกอย่าง

## นักสู้ที่ AI ตัวนี้ควบคุม
@export var fighter: FighterController
@export var active := true

@export_group("Spacing")
## ระยะที่ชอบยืน (ควรน้อยกว่า Attack Range ของตัวเอง)
@export var preferred_distance := 1.9
## ห่างจากระยะที่ชอบไม่เกินนี้ถือว่าพอดีแล้ว
@export var distance_tolerance := 0.35
@export var move_decision_interval_min := 0.5
@export var move_decision_interval_max := 1.2
## โอกาสที่จะเดินวนข้างแทนการยืนนิ่ง
@export_range(0.0, 1.0) var strafe_chance := 0.6

@export_group("Offense")
@export var attack_interval_min := 1.2
@export var attack_interval_max := 2.5
@export_range(0.0, 1.0) var heavy_chance := 0.35
## โอกาสที่ Heavy จะเป็นท่าหลอก
@export_range(0.0, 1.0) var feint_chance := 0.3
@export var guard_change_interval_min := 0.8
@export var guard_change_interval_max := 2.0
## โอกาสที่จะใช้สกิล (ถ้ามีสกิลพร้อมและอยู่ในระยะ) แทนการฟันปกติ
@export_range(0.0, 1.0) var skill_chance := 0.4
## โอกาสที่จะใช้ Guard Break เมื่ออยู่ประชิดตัว
@export_range(0.0, 1.0) var guard_break_chance := 0.15

@export_group("Defense")
## เวลาที่ AI ใช้ตอบสนองต่อท่าของผู้เล่น
@export var reaction_time := 0.3
@export_range(0.0, 1.0) var parry_chance := 0.2
@export_range(0.0, 1.0) var block_chance := 0.45
@export_range(0.0, 1.0) var dodge_chance := 0.15
## โอกาสที่จะกลิ้งหลบเมื่อผู้เล่นใช้สกิล
@export_range(0.0, 1.0) var skill_roll_chance := 0.4

var _move_timer := 0.0
var _strafe := 0.0
var _attack_timer := 0.0
var _guard_timer := 0.0
var _feint_timer := 0.0
var _last_attack_direction := -1


func _ready() -> void:
	_attack_timer = randf_range(attack_interval_min, attack_interval_max)
	_guard_timer = randf_range(guard_change_interval_min, guard_change_interval_max)
	if fighter != null and fighter.target != null:
		fighter.target.attack_started.connect(_on_target_attack_started)
		fighter.target.skill_started.connect(_on_target_skill_started)


func _process(delta: float) -> void:
	if not _can_think():
		if fighter != null:
			fighter.move_input = Vector2.ZERO
		return

	_update_movement(delta)
	_update_guard(delta)
	_update_feint(delta)
	_update_attack(delta)


func _can_think() -> bool:
	# can_process(): สัญญาณยังเข้ามาได้แม้สังเวียนถูกปิดอยู่ จึงต้องเช็กเองด้วย
	return active and can_process() and fighter != null and fighter.state != FighterController.State.DEAD \
		and fighter.target != null and fighter.target.state != FighterController.State.DEAD


func _distance_to_target() -> float:
	return fighter.global_position.distance_to(fighter.target.global_position)


# ---------------------------------------------------------------- Spacing

func _update_movement(delta: float) -> void:
	_move_timer -= delta
	if _move_timer <= 0.0:
		_move_timer = randf_range(move_decision_interval_min, move_decision_interval_max)
		_strafe = [-1.0, 1.0].pick_random() if randf() < strafe_chance else 0.0

	var forward := 0.0
	var gap := _distance_to_target() - preferred_distance
	if fighter.state == FighterController.State.EXHAUSTED:
		forward = -1.0  # เหนื่อยแล้ว ถอยออกไปตั้งหลัก
	elif gap > distance_tolerance:
		forward = 1.0
	elif gap < -distance_tolerance:
		forward = -1.0

	fighter.move_input = Vector2(_strafe, forward)


# ---------------------------------------------------------------- Offense

func _update_guard(delta: float) -> void:
	_guard_timer -= delta
	if _guard_timer > 0.0 or fighter.state != FighterController.State.IDLE:
		return
	_guard_timer = randf_range(guard_change_interval_min, guard_change_interval_max)
	fighter.set_guard_direction(_random_direction_except(fighter.guard_direction))


func _update_feint(delta: float) -> void:
	if _feint_timer <= 0.0:
		return
	_feint_timer -= delta
	if _feint_timer <= 0.0 and fighter.state == FighterController.State.WINDUP and fighter.attack_is_heavy:
		fighter.feint()


func _update_attack(delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer > 0.0 or fighter.state != FighterController.State.IDLE:
		return
	if randf() < skill_chance and _try_use_skill():
		_attack_timer = randf_range(attack_interval_min, attack_interval_max)
		return
	if _distance_to_target() <= GuardBreakSkill.REACH and randf() < guard_break_chance:
		_attack_timer = randf_range(attack_interval_min, attack_interval_max)
		fighter.guard_break()
		return
	if _distance_to_target() > fighter.attack_range:
		return  # รอจนเข้าระยะก่อน

	_attack_timer = randf_range(attack_interval_min, attack_interval_max)
	var direction := _random_direction_except(_last_attack_direction)
	_last_attack_direction = direction

	# หันการ์ดไปทิศที่จะฟันก่อน แล้วรอเท่ากับดีเลย์เปลี่ยนการ์ดของผู้เล่น
	fighter.set_guard_direction(direction)
	await get_tree().create_timer(CombatInputController.GUARD_SWITCH_DELAY).timeout
	if not _can_think() or fighter.state != FighterController.State.IDLE:
		return

	var is_heavy := randf() < heavy_chance
	fighter.start_attack(direction, is_heavy)
	if is_heavy and randf() < feint_chance:
		_feint_timer = fighter.heavy_windup * 0.5


## สุ่มใช้สกิลที่ Cooldown พร้อมและระยะเหมาะกับสกิลนั้น
func _try_use_skill() -> bool:
	var skills := fighter.skills
	if skills == null:
		return false
	var distance := _distance_to_target()
	var ready_slots: Array[int] = []
	for slot in skills.skills.size():
		var skill := skills.skills[slot]
		if skills.cooldowns.is_ready(slot) and distance >= skill.ai_min_range and distance <= skill.ai_max_range:
			ready_slots.append(slot)
	if ready_slots.is_empty():
		return false
	return skills.try_use(ready_slots.pick_random())


func _random_direction_except(excluded: int) -> CombatInputController.GuardDirection:
	var choices: Array = CombatInputController.GuardDirection.values()
	choices.erase(excluded)
	return choices.pick_random()


# ---------------------------------------------------------------- Defense

func _on_target_attack_started(direction: CombatInputController.GuardDirection, is_heavy: bool) -> void:
	if not _can_think():
		return

	await get_tree().create_timer(reaction_time).timeout
	if not _can_think() or fighter.state != FighterController.State.IDLE:
		return

	var target_windup := fighter.target.heavy_windup if is_heavy else fighter.target.light_windup
	var time_until_hit := target_windup - reaction_time
	var roll := randf()

	if roll < parry_chance:
		fighter.set_guard_direction(direction)
		await _wait(time_until_hit - fighter.parry_window * 0.5)
		if _can_think():
			fighter.parry()
	elif roll < parry_chance + block_chance:
		fighter.set_guard_direction(direction)
	elif roll < parry_chance + block_chance + dodge_chance:
		await _wait(time_until_hit - fighter.step_duration)
		if _can_think():
			fighter.move_input = Vector2(0.0, -1.0)  # ถอยหลังออกนอกระยะดาบ
			fighter.dodge()


func _on_target_skill_started(_skill: Skill) -> void:
	if not _can_think():
		return

	await get_tree().create_timer(reaction_time).timeout
	if not _can_think() or fighter.state != FighterController.State.IDLE:
		return

	if randf() < skill_roll_chance:
		fighter.move_input = Vector2([-1.0, 1.0].pick_random(), -0.5)
		fighter.dodge()
		fighter.dodge()  # กด 2 ที = กลิ้ง
	else:
		fighter.set_guard_direction(fighter.target.attack_direction)


func _wait(seconds: float) -> void:
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout
