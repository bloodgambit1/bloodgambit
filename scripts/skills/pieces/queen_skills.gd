class_name QueenSkills
extends RefCounted
## สกิลของ Queen (ควีน): คอมโบหลายทิศ และโจมตีระยะไกล


static func create() -> Array[Skill]:
	var list: Array[Skill] = [BladeStorm.new(), SwordWave.new(), StarlightThrust.new()]
	return list


## Skill 1: พายุฟัน 3 ทิศติดกัน ซ้าย -> ขวา -> บน (ต้องเปลี่ยนการ์ดตามให้ทันทุกครั้ง)
class BladeStorm extends Skill:
	const SEQUENCE := [
		CombatInputController.GuardDirection.LEFT,
		CombatInputController.GuardDirection.RIGHT,
		CombatInputController.GuardDirection.TOP,
	]
	const TELEGRAPH_TIME := 0.35

	func _init() -> void:
		display_name = "Blade Storm"
		description = "ฟันติดกัน 3 ทิศ ซ้าย -> ขวา -> บน: ต้องเปลี่ยนการ์ดตามให้ทันทุกดาบ"
		cooldown = 9.0
		stamina_cost = 25.0
		ai_min_range = 0.0
		ai_max_range = 2.4

	func execute(fighter: FighterController, token: int) -> void:
		for i in SEQUENCE.size():
			var direction: CombatInputController.GuardDirection = SEQUENCE[i]
			fighter.attack_direction = direction
			fighter.skill_hint = "STORM %s (%d/3)" % [CombatInputController.GuardDirection.keys()[direction], i + 1]
			if not await _wait(fighter, token, TELEGRAPH_TIME):
				return
			var attack := _create_attack(fighter, 10.0, 10.0, direction)
			attack.attack_name = "%s %d/3" % [display_name, i + 1]
			_hit_in_range(fighter, attack, 2.6)


## Skill 2: ยิงคลื่นดาบระยะไกล (Block ได้ถ้าการ์ดถูกทิศ, Parry ได้แค่ปัดทิ้ง)
class SwordWave extends Skill:
	func _init() -> void:
		display_name = "Sword Wave"
		description = "ยิงคลื่นดาบระยะไกล 16 เมตร: Block ถูกทิศ, Parry ปัดทิ้ง หรือหลบก็ได้"
		cooldown = 7.0
		stamina_cost = 15.0
		ai_min_range = 2.5
		ai_max_range = 14.0

	func execute(fighter: FighterController, token: int) -> void:
		var direction := fighter.guard_direction
		fighter.attack_direction = direction
		fighter.skill_hint = "SWORD WAVE %s" % CombatInputController.GuardDirection.keys()[direction]
		if not await _wait(fighter, token, 0.4):
			return

		var attack := _create_attack(fighter, 20.0, 15.0, direction)
		attack.parry_stuns_attacker = false
		var visual := SkillEffects.box(Vector3(1.0, 0.12, 0.35), Color(0.4, 0.9, 1.0))
		SkillProjectile.launch(fighter, attack, visual, 14.0, 1.0, 16.0, 1.2)
		await _wait(fighter, token, 0.15)


## Skill 3: หอกดาราจักรทิ่มแทง (Starlight Thrust)
## พุ่งแทงทะลวงระยะไกลด้วยความเร็วสูง ทะลุเกราะและเจาะทะลุ Hyper Armor
class StarlightThrust extends Skill:
	func _init() -> void:
		display_name = "Starlight Thrust"
		description = "พุ่งแทงทะลวงระยะไกล ทะลุเกราะ (Block ยังโดน 70%) และทลาย Hyper Armor"
		cooldown = 8.0
		stamina_cost = 20.0
		ai_min_range = 2.0
		ai_max_range = 6.0

	func execute(fighter: FighterController, token: int) -> void:
		var dir := fighter.guard_direction
		fighter.attack_direction = dir
		fighter.skill_hint = "STARLIGHT THRUST"
		if not await _wait(fighter, token, 0.25):
			return

		var result := await _dash_until_contact(fighter, token, 20.0, 0.35, 1.8)
		if result == 1:
			var attack := _create_attack(fighter, 26.0, 20.0, dir)
			attack.attack_name = display_name
			attack.armor_piercing = true
			fighter.target.receive_hit(attack)
		elif result == 0:
			fighter.log_event("%s วืด!" % display_name)

