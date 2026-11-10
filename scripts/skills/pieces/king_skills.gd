class_name KingSkills
extends RefCounted
## สกิลของ King (คิง): ควบคุมพื้นที่ และท่าประหารที่ต้องหลบอย่างเดียว


static func create() -> Array[Skill]:
	var list: Array[Skill] = [RoyalBurst.new(), ExecutionFissure.new(), KingsGambit.new()]
	return list


## Skill 1: ระเบิดพลังรอบตัว ผลักศัตรูกระเด็นและขัดท่าที่กำลังง้าง (กันไม่ได้ ต้องกลิ้งหลบหรืออยู่นอกวง)
class RoyalBurst extends Skill:
	const RADIUS := 3.5

	func _init() -> void:
		display_name = "Royal Burst"
		description = "ระเบิดพลังรอบตัว ผลักกระเด็นและขัดท่าศัตรู: กันไม่ได้ ต้องกลิ้งหรืออยู่นอกวง"
		cooldown = 10.0
		stamina_cost = 20.0
		ai_min_range = 0.0
		ai_max_range = 3.0

	func execute(fighter: FighterController, token: int) -> void:
		fighter.attack_direction = CombatInputController.GuardDirection.TOP
		fighter.hyper_armor = true
		fighter.skill_hint = "BURST (PUSH)"
		if not await _wait(fighter, token, 0.3):
			return

		SkillEffects.spawn_flash(fighter.get_parent(), fighter.global_position + Vector3.UP, RADIUS, Color(1.0, 0.85, 0.3))
		var attack := _create_attack(fighter, 6.0, 10.0, CombatInputController.GuardDirection.TOP)
		attack.unblockable = true
		attack.unparryable = true
		attack.knockback = 12.0
		_hit_area(fighter, attack, fighter.global_position, RADIUS)


## Skill 2: ดาบประหารผ่าพื้น ส่งรอยแยกวิ่งตรงไปหาศัตรู Unblockable + Parry ไม่ได้ (ต้องหลบอย่างเดียว)
class ExecutionFissure extends Skill:
	const WIDTH := 1.2

	func _init() -> void:
		display_name = "Execution Fissure"
		description = "ผ่าพื้นส่งรอยแยกพุ่งตรง ดาเมจสูง Unblockable + Parry ไม่ได้: ต้องเดินหลบข้างหรือกลิ้ง"
		cooldown = 14.0
		stamina_cost = 30.0
		ai_min_range = 2.0
		ai_max_range = 10.0

	func execute(fighter: FighterController, token: int) -> void:
		fighter.attack_direction = CombatInputController.GuardDirection.TOP
		fighter.hyper_armor = true
		fighter.skill_hint = "EXECUTION (UNBLOCKABLE)"
		if not await _wait(fighter, token, 1.0):
			return

		var attack := _create_attack(fighter, 40.0, 30.0, CombatInputController.GuardDirection.TOP)
		attack.unblockable = true
		attack.unparryable = true
		var visual := SkillEffects.box(Vector3(WIDTH, 0.08, 1.6), Color(1.0, 0.15, 0.1))
		SkillProjectile.launch(fighter, attack, visual, 9.0, WIDTH, 12.0, 0.05)
		await _wait(fighter, token, 0.3)


## Skill 3: คิงส์แกมบิต - สวนกลับประหาร (King's Gambit)
## ตั้งท่าปัดป้องพิเศษ (Parry Window นานเป็นพิเศษ) หากศัตรูตีเข้ามาจะปัดดาบและฟันสวนประหารทันที
class KingsGambit extends Skill:
	func _init() -> void:
		display_name = "King's Gambit"
		description = "ตั้งท่าปัดป้องพิเศษ (Parry นานเป็นพิเศษ) หากศัตรูตีเข้ามาจะฟันเคาน์เตอร์ประหารทันที"
		cooldown = 15.0
		stamina_cost = 25.0
		ai_min_range = 0.0
		ai_max_range = 3.5

	func execute(fighter: FighterController, token: int) -> void:
		fighter.skill_hint = "KING'S GAMBIT"
		fighter.hyper_armor = true

		# เปิดหน้าต่าง Parry นาน 0.85 วินาที
		fighter.open_parry_window(0.85)

		var flash_col := Color(1.0, 0.85, 0.2) if fighter.is_white_faction else Color(0.75, 0.25, 1.0)
		SkillEffects.spawn_flash(fighter.get_parent(), fighter.global_position + Vector3.UP * 1.1, 1.8, flash_col)

		if not await _wait(fighter, token, 0.85):
			return

		# ปลดปล่อยการฟันสวนกลับ
		var attack := _create_attack(fighter, 35.0, 30.0, CombatInputController.GuardDirection.TOP)
		attack.attack_name = "Sovereign Counter"
		attack.armor_piercing = true
		_hit_in_range(fighter, attack, 2.6)
		await _wait(fighter, token, 0.25)

