class_name Skill
extends RefCounted
## คลาสแม่ของสกิลทุกท่า: สกิลใหม่ให้ extends Skill แล้วตั้งค่าใน _init() และเขียนท่าใน execute()
##
## กติกาสำคัญตอนเขียน execute():
##   ทุกครั้งที่ await (รอเวลา) ให้เช็กผลของ _wait() / _wait_physics_frame()
##   ถ้าได้ false แปลว่าสกิลโดนขัด/โดน Parry/ตาย -> ต้อง return ออกทันที

var display_name := "Skill"
var description := ""
var cooldown := 5.0
var stamina_cost := 15.0
## ระยะที่ AI จะเลือกใช้สกิลนี้
var ai_min_range := 0.0
var ai_max_range := 2.5


## เขียนท่าของสกิลที่นี่ (เป็น coroutine ใช้ await ได้)
func execute(_fighter: FighterController, _token: int) -> void:
	pass


# ---------------------------------------------------------------- ตัวช่วยสำหรับสกิลลูก

## รอเวลา แล้วบอกว่าสกิลยังทำงานต่อได้ไหม
func _wait(fighter: FighterController, token: int, seconds: float) -> bool:
	if seconds > 0.0:
		await fighter.get_tree().create_timer(seconds, false, true).timeout
	return fighter.is_skill_running(token)


func _wait_physics_frame(fighter: FighterController, token: int) -> bool:
	await fighter.get_tree().physics_frame
	return fighter.is_skill_running(token)


func _create_attack(fighter: FighterController, damage: float, posture_damage: float,
		direction: CombatInputController.GuardDirection) -> AttackData:
	var attack := AttackData.new(fighter, direction, damage, posture_damage)
	attack.attack_name = display_name
	return attack


## ตีระยะประชิด: โดนถ้าเป้าอยู่ในระยะ
func _hit_in_range(fighter: FighterController, attack: AttackData, reach: float) -> bool:
	if fighter.target == null or fighter.flat_distance_to_target() > reach:
		fighter.log_event("%s วืด!" % display_name)
		return false
	fighter.target.receive_hit(attack)
	return true


## ตีวงกว้างรอบจุด center
func _hit_area(fighter: FighterController, attack: AttackData, center: Vector3, radius: float) -> bool:
	var target := fighter.target
	if target == null:
		return false
	var offset := target.global_position - center
	offset.y = 0.0
	if offset.length() > radius:
		fighter.log_event("%s ไม่โดน!" % display_name)
		return false
	target.receive_hit(attack)
	return true


## พุ่งไปข้างหน้า หยุดเมื่อชนเป้า
## คืนค่า 1 = ชน, 0 = พุ่งจนสุดแล้วไม่โดน, -1 = สกิลโดนขัด
func _dash_until_contact(fighter: FighterController, token: int, speed: float, duration: float, contact_range: float) -> int:
	fighter.skill_velocity = fighter.flat_direction_to_target() * speed
	var elapsed := 0.0
	while elapsed < duration:
		if not await _wait_physics_frame(fighter, token):
			return -1
		elapsed += fighter.get_physics_process_delta_time()
		if fighter.flat_distance_to_target() <= contact_range:
			fighter.skill_velocity = Vector3.ZERO
			return 1
	fighter.skill_velocity = Vector3.ZERO
	return 0
