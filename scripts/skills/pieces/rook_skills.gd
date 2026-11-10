class_name RookSkills
extends RefCounted
## สกิลของ Rook (เรือ): ตัวถึก ตีหนัก ดันหน้า (มี 3 สกิล: R / F / C)


static func create() -> Array[Skill]:
	var list: Array[Skill] = [FortressStrike.new(), SiegeCharge.new(), GroundStomp.new()]
	return list


## Skill 1: ฟันหนักพร้อม Hyper Armor (โดนตีระหว่างง้างแล้วท่าไม่หลุด)
class FortressStrike extends Skill:
	func _init() -> void:
		display_name = "Fortress Strike"
		description = "ฟันหนักพร้อม Hyper Armor: โดนตีระหว่างง้างท่าก็ไม่หลุด"
		cooldown = 7.0
		stamina_cost = 20.0
		ai_min_range = 0.0
		ai_max_range = 2.4

	func execute(fighter: FighterController, token: int) -> void:
		var direction := fighter.guard_direction
		fighter.attack_direction = direction
		fighter.hyper_armor = true
		fighter.skill_hint = "FORTRESS %s (HYPER ARMOR)" % CombatInputController.GuardDirection.keys()[direction]
		if not await _wait(fighter, token, 0.9):
			return

		var attack := _create_attack(fighter, 32.0, 30.0, direction)
		_hit_in_range(fighter, attack, 2.6)


## Skill 2: พุ่งชนแบบ Unblockable (Block ไม่ได้ แต่ Parry หรือหลบได้)
class SiegeCharge extends Skill:
	func _init() -> void:
		display_name = "Siege Charge"
		description = "พุ่งชน 6 เมตร Unblockable และกระเด็น: ต้อง Parry หรือหลบเท่านั้น"
		cooldown = 9.0
		stamina_cost = 25.0
		ai_min_range = 2.5
		ai_max_range = 6.0

	func execute(fighter: FighterController, token: int) -> void:
		var direction := fighter.guard_direction
		fighter.attack_direction = direction
		fighter.skill_hint = "CHARGE (UNBLOCKABLE)"
		if not await _wait(fighter, token, 0.4):
			return

		var result := await _dash_until_contact(fighter, token, 12.0, 0.5, 1.7)
		if result == 1:
			var attack := _create_attack(fighter, 20.0, 20.0, direction)
			attack.unblockable = true
			attack.knockback = 10.0
			fighter.target.receive_hit(attack)
		elif result == 0:
			fighter.log_event("%s วืด!" % display_name)


## Skill 3: กระทืบพื้นทำลายการ์ด (Block ก็การ์ดแตก Parry ไม่ได้ ต้องกลิ้งหรือถอยออกนอกวง)
class GroundStomp extends Skill:
	const RADIUS := 3.2

	func _init() -> void:
		display_name = "Ground Stomp"
		description = "กระทืบพื้นรอบตัว ทำลายการ์ด: Block ก็ Stunned, Parry ไม่ได้ ต้องกลิ้งหรือถอยออก"
		cooldown = 12.0
		stamina_cost = 20.0
		ai_min_range = 0.0
		ai_max_range = 2.8

	func execute(fighter: FighterController, token: int) -> void:
		fighter.attack_direction = CombatInputController.GuardDirection.TOP
		fighter.skill_hint = "STOMP (GUARD BREAK)"
		if not await _wait(fighter, token, 0.55):
			return

		SkillEffects.spawn_flash(fighter.get_parent(), fighter.global_position, RADIUS, Color(0.9, 0.7, 0.3))
		var attack := _create_attack(fighter, 8.0, 0.0, CombatInputController.GuardDirection.TOP)
		attack.guard_break = true
		attack.unparryable = true
		_hit_area(fighter, attack, fighter.global_position, RADIUS)
