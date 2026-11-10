class_name KnightSkills
extends RefCounted
## สกิลของ Knight (ม้า): เน้นความคล่องตัว กระโดดข้ามหัว และพุ่งแทง


static func create() -> Array[Skill]:
	var list: Array[Skill] = [LeapStrike.new(), PiercingThrust.new(), TrampleCharge.new()]
	return list


## Skill 1: กระโดดข้ามหัวศัตรูไปลงด้านหลัง แล้วฟันลงจากด้านบน (อมตะตอนลอยตัว)
class LeapStrike extends Skill:
	const FLIGHT_TIME := 1.0
	const LAND_BEHIND_DISTANCE := 1.6

	func _init() -> void:
		display_name = "Leap Strike"
		description = "กระโดดข้ามหัวไปลงหลังศัตรู แล้วฟันลงจากด้านบน (อมตะขณะลอยตัว)"
		cooldown = 8.0
		stamina_cost = 20.0
		ai_min_range = 1.5
		ai_max_range = 5.0

	func execute(fighter: FighterController, token: int) -> void:
		fighter.attack_direction = CombatInputController.GuardDirection.TOP
		fighter.skill_hint = "LEAP -> TOP"
		if not await _wait(fighter, token, 0.25):
			return

		var target := fighter.target
		var landing := fighter.clamp_to_arena(target.global_position + fighter.flat_direction_to_target() * LAND_BEHIND_DISTANCE)
		var horizontal := landing - fighter.global_position
		horizontal.y = 0.0
		fighter.skill_velocity = horizontal / FLIGHT_TIME
		fighter.velocity.y = fighter.gravity * FLIGHT_TIME * 0.5  # ขึ้นแล้วตกถึงพื้นพอดีเมื่อครบ FLIGHT_TIME
		fighter.set_pass_through_target(true)
		fighter.set_iframes(FLIGHT_TIME * 0.8)
		if not await _wait(fighter, token, FLIGHT_TIME):
			return

		fighter.skill_velocity = Vector3.ZERO
		fighter.set_pass_through_target(false)
		var attack := _create_attack(fighter, 22.0, 20.0, CombatInputController.GuardDirection.TOP)
		_hit_in_range(fighter, attack, 2.6)


## Skill 2: พุ่งแทงไปข้างหน้า ทะลุเกราะ (Block แล้วยังโดน 70% และทะลุ Hyper Armor)
class PiercingThrust extends Skill:
	func _init() -> void:
		display_name = "Piercing Thrust"
		description = "พุ่งแทงไกล 4 เมตร ทะลุเกราะ: Block แล้วยังโดนดาเมจ และทะลุ Hyper Armor"
		cooldown = 6.0
		stamina_cost = 15.0
		ai_min_range = 2.0
		ai_max_range = 4.5

	func execute(fighter: FighterController, token: int) -> void:
		var direction := fighter.guard_direction
		fighter.attack_direction = direction
		fighter.skill_hint = "THRUST %s (PIERCING)" % CombatInputController.GuardDirection.keys()[direction]
		if not await _wait(fighter, token, 0.35):
			return

		var result := await _dash_until_contact(fighter, token, 16.0, 0.25, 1.7)
		if result == 1:
			var attack := _create_attack(fighter, 18.0, 15.0, direction)
			attack.armor_piercing = true
			fighter.target.receive_hit(attack)
		elif result == 0:
			fighter.log_event("%s วืด!" % display_name)


## Skill 3: ม้าศึกพุ่งกระแทกทลายแถว (Trample Charge)
## พุ่งเข้าชนด้วยความเร็วสูง ทลาย Posture และทำให้ศัตรูกระเด็น
class TrampleCharge extends Skill:
	func _init() -> void:
		display_name = "Trample Charge"
		description = "พุ่งม้าเข้ากระแทกอย่างแรง ทำลาย Posture และผลักศัตรูกระเด็น"
		cooldown = 9.0
		stamina_cost = 22.0
		ai_min_range = 2.5
		ai_max_range = 6.0

	func execute(fighter: FighterController, token: int) -> void:
		fighter.attack_direction = CombatInputController.GuardDirection.TOP
		fighter.skill_hint = "TRAMPLE CHARGE"
		fighter.hyper_armor = true
		if not await _wait(fighter, token, 0.3):
			return

		var result := await _dash_until_contact(fighter, token, 18.0, 0.45, 1.8)
		if result == 1:
			var attack := _create_attack(fighter, 24.0, 35.0, CombatInputController.GuardDirection.TOP)
			attack.attack_name = display_name
			attack.knockback = 8.0
			fighter.target.receive_hit(attack)
		elif result == 0:
			fighter.log_event("%s วืด!" % display_name)

