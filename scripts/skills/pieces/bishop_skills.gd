class_name BishopSkills
extends RefCounted
## สกิลของ Bishop (บิชอป): วาร์ปแนวทแยง และโจมตีระยะไกลที่หลบยาก


static func create() -> Array[Skill]:
	var list: Array[Skill] = [WarpBomb.new(), CrossWave.new(), SanctuaryHex.new()]
	return list


## Skill 1: วาร์ปแนวทแยงไปข้างศัตรู แล้ววางระเบิดใต้เท้าศัตรู (ต้องเดินออกจากวงก่อนระเบิด)
class WarpBomb extends Skill:
	const WARP_DISTANCE := 3.0
	const BLAST_RADIUS := 2.2
	const FUSE_TIME := 1.2

	func _init() -> void:
		display_name = "Warp Bomb"
		description = "วาร์ปเฉียงไปข้างศัตรู แล้ววางระเบิดใต้เท้า: Block ไม่ได้ ต้องเดินหรือกลิ้งออกจากวง"
		cooldown = 9.0
		stamina_cost = 20.0
		ai_min_range = 0.0
		ai_max_range = 6.0

	func execute(fighter: FighterController, token: int) -> void:
		fighter.skill_hint = "WARP + BOMB"
		if not await _wait(fighter, token, 0.15):
			return

		var forward := fighter.flat_direction_to_target()
		var side := forward.cross(Vector3.UP) * ([-1.0, 1.0].pick_random() as float)
		var destination := fighter.clamp_to_arena(fighter.global_position + (forward + side).normalized() * WARP_DISTANCE)
		var arena := fighter.get_parent()
		SkillEffects.spawn_flash(arena, fighter.global_position + Vector3.UP, 1.0, Color(0.6, 0.3, 1.0))
		fighter.teleport_to(destination)
		fighter.set_iframes(0.2)
		SkillEffects.spawn_flash(arena, destination + Vector3.UP, 1.0, Color(0.6, 0.3, 1.0))

		var attack := _create_attack(fighter, 25.0, 20.0, CombatInputController.GuardDirection.TOP)
		attack.unblockable = true
		attack.unparryable = true
		attack.knockback = 6.0
		SkillBomb.plant(fighter, attack, fighter.target.global_position, BLAST_RADIUS, FUSE_TIME)
		await _wait(fighter, token, 0.2)


## Skill 2: ยิงคลื่นกากบาทกว้าง ๆ กลิ้งหลบด้วย I-frames ไม่ได้ (ต้อง Block ถูกทิศ หรือเดินหลบด้านข้าง)
class CrossWave extends Skill:
	const WIDTH := 2.4

	func _init() -> void:
		display_name = "Cross Wave"
		description = "ยิงคลื่นกากบาทกว้าง กลิ้งหลบไม่ได้: ต้อง Block ถูกทิศหรือเดินหลบออกข้าง"
		cooldown = 10.0
		stamina_cost = 20.0
		ai_min_range = 2.5
		ai_max_range = 12.0

	func execute(fighter: FighterController, token: int) -> void:
		var direction := fighter.guard_direction
		fighter.attack_direction = direction
		fighter.skill_hint = "CROSS WAVE %s (NO ROLL)" % CombatInputController.GuardDirection.keys()[direction]
		if not await _wait(fighter, token, 0.5):
			return

		var attack := _create_attack(fighter, 18.0, 15.0, direction)
		attack.ignore_iframes = true
		attack.parry_stuns_attacker = false

		var visual := Node3D.new()
		for angle in [45.0, -45.0]:
			var bar := SkillEffects.box(Vector3(WIDTH, 0.18, 0.3), Color(0.7, 0.4, 1.0))
			bar.rotation_degrees.z = angle
			visual.add_child(bar)
		SkillProjectile.launch(fighter, attack, visual, 10.0, WIDTH, 14.0, 1.2)
		await _wait(fighter, token, 0.2)


## Skill 3: เขตอาคมศักดิ์สิทธิ์ / คำสาปเงา (Sanctuary / Void Hex)
## กางอาคมบนพื้น ฟื้นฟู Stamina ของตนเอง และส่งคลื่นพลังงานผลักศัตรู
class SanctuaryHex extends Skill:
	const RADIUS := 3.0

	func _init() -> void:
		display_name = "Sanctuary"
		description = "กางอาคมศักดิ์สิทธิ์บนพื้น ฟื้นฟู Stamina และส่งคลื่นพลังงานผลักศัตรู"
		cooldown = 12.0
		stamina_cost = 10.0
		ai_min_range = 0.0
		ai_max_range = 5.0

	func execute(fighter: FighterController, token: int) -> void:
		fighter.skill_hint = "SANCTUARY"
		var col := Color(1.0, 0.9, 0.4) if fighter.is_white_faction else Color(0.6, 0.2, 0.9)
		SkillEffects.spawn_flash(fighter.get_parent(), fighter.global_position, RADIUS, col)

		fighter.stamina = minf(fighter.stamina + 35.0, fighter.max_stamina)
		if not await _wait(fighter, token, 0.3):
			return

		var attack := _create_attack(fighter, 12.0, 15.0, CombatInputController.GuardDirection.TOP)
		attack.unblockable = true
		attack.knockback = 5.0
		_hit_area(fighter, attack, fighter.global_position, RADIUS)
		await _wait(fighter, token, 0.2)

