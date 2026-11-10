class_name PawnSkills
extends RefCounted
## ชุดสกิลของ Pawn (เบี้ย): ว่องไว กระแทกโล่เปิดช่อง สไลด์ฟันข้าง (En Passant) และเลื่อนขั้นควีนชั่วคราว


static func create() -> Array[Skill]:
	var list: Array[Skill] = [ShieldBashThrust.new(), EnPassantStrike.new(), Coronation.new()]
	return list


## Skill 1: กระแทกโล่เปิดช่องแล้วแทงสวน (Shield Bash & Thrust)
## กระแทกโล่ทำลาย Posture สูง แล้วแทงทะลุเกราะตามทันที
class ShieldBashThrust extends Skill:
	func _init() -> void:
		display_name = "Shield Bash"
		description = "กระแทกโล่เปิดช่องทำลาย Posture แล้วแทงดาบทะลุเกราะซ้ำทันที"
		cooldown = 6.0
		stamina_cost = 15.0
		ai_min_range = 0.0
		ai_max_range = 2.2

	func execute(fighter: FighterController, token: int) -> void:
		fighter.attack_direction = fighter.guard_direction
		fighter.skill_hint = "SHIELD BASH"
		if not await _wait(fighter, token, 0.2):
			return

		# จังหวะ 1: ชนด้วยโล่
		var bash_attack := _create_attack(fighter, 8.0, 28.0, fighter.guard_direction)
		bash_attack.attack_name = "Shield Bash"
		bash_attack.knockback = 4.0
		var hit := _hit_in_range(fighter, bash_attack, 2.0)

		if not await _wait(fighter, token, 0.25):
			return

		# จังหวะ 2: พุ่งแทงดาบทะลุเกราะ (Armor-Piercing)
		fighter.skill_hint = "THRUST (PIERCING)"
		var thrust_attack := _create_attack(fighter, 16.0, 15.0, CombatInputController.GuardDirection.TOP)
		thrust_attack.attack_name = "Lunging Thrust"
		thrust_attack.armor_piercing = true
		_hit_in_range(fighter, thrust_attack, 2.4)
		await _wait(fighter, token, 0.2)


## Skill 2: สไลด์ฟันทะลวงข้าง (En Passant)
## สไลด์เฉียงหลบการโจมตี (อมตะ I-frames) อ้อมไปตวัดฟันด้านข้างของเป้าหมาย
class EnPassantStrike extends Skill:
	const DASH_SPEED := 12.0
	const DASH_TIME := 0.35

	func _init() -> void:
		display_name = "En Passant"
		description = "สไลด์เฉียงหลบการโจมตี (อมตะชั่วขณะ) อ้อมไปฟันด้านข้างของเป้าหมาย"
		cooldown = 8.0
		stamina_cost = 20.0
		ai_min_range = 1.5
		ai_max_range = 5.0

	func execute(fighter: FighterController, token: int) -> void:
		var target := fighter.target
		if target == null:
			return

		var forward := fighter.flat_direction_to_target()
		var side_sign: float = [-1.0, 1.0].pick_random()
		var side := forward.cross(Vector3.UP) * side_sign

		fighter.attack_direction = CombatInputController.GuardDirection.LEFT if side_sign < 0.0 else CombatInputController.GuardDirection.RIGHT
		fighter.skill_hint = "EN PASSANT"

		# ให้ I-frames ขณะสไลด์
		fighter.set_iframes(DASH_TIME + 0.1)
		fighter.skill_velocity = (forward * 0.7 + side * 0.9).normalized() * DASH_SPEED

		if not await _wait(fighter, token, DASH_TIME):
			return

		fighter.skill_velocity = Vector3.ZERO
		# หมุนหันหน้าหาเป้าหมายใหม่
		fighter.look_at_target()

		# ฟันเข้าด้านข้าง
		var attack := _create_attack(fighter, 22.0, 20.0, fighter.attack_direction)
		attack.attack_name = "En Passant Flank"
		_hit_in_range(fighter, attack, 2.5)
		await _wait(fighter, token, 0.2)


## Skill 3: เลื่อนขั้นควีนชั่วคราว (Coronation)
## ปลดปล่อยพลังราชินี: ฟื้นฟู Stamina + HP ทันที และได้รับ Hyper Armor 4 วินาที
class Coronation extends Skill:
	func _init() -> void:
		display_name = "Coronation"
		description = "ปลดปล่อยพลังราชินี: ฟื้น Stamina และ HP ทันที พร้อมได้รับ Hyper Armor 4 วินาที"
		cooldown = 18.0
		stamina_cost = 5.0
		ai_min_range = 0.0
		ai_max_range = 8.0

	func execute(fighter: FighterController, token: int) -> void:
		fighter.skill_hint = "CORONATION AWAKEN"
		fighter.hyper_armor = true

		# ระเบิดออร่าพลัง
		var aura_col := Color(1.0, 0.85, 0.25) if fighter.is_white_faction else Color(0.7, 0.25, 1.0)
		SkillEffects.spawn_flash(fighter.get_parent(), fighter.global_position + Vector3.UP * 0.8, 2.5, aura_col)

		# ฟื้นฟูพลัง
		fighter.stamina = fighter.max_stamina
		fighter.hp = minf(fighter.hp + 20.0, fighter.max_hp)

		fighter.log_event("%s ตื่นรู้พลังราชินี! (Hyper Armor 4s + ฟื้นฟูพลัง)" % fighter.fighter_name)

		# รักษาสถานะ Hyper Armor ชั่วคราว
		await _wait(fighter, token, 4.0)
		fighter.hyper_armor = false
