class_name GuardBreakSkill
extends Skill
## Guard Break (ทะลวงการ์ด): ท่าพื้นฐานที่ทุกตัวใช้ได้ ไม่มี Cooldown (ไม่ได้อยู่ในช่องสกิล)
## ง้างสั้น ๆ แล้วกระชากการ์ดศัตรูระยะประชิด: Block/Parry ไม่ได้ โดนแล้วการ์ดแตกติด Stunned
## วิธีแก้: กลิ้งหลบ (I-frames), ถอยออกนอกระยะ หรือฟันใส่ตอนอีกฝ่ายกำลังง้าง

const WINDUP := 0.3
const REACH := 1.9


func _init() -> void:
	display_name = "Guard Break"
	description = "กระชากการ์ดระยะประชิด: กันไม่ได้ โดนแล้ว Stunned"
	cooldown = 0.0
	stamina_cost = 15.0
	ai_min_range = 0.0
	ai_max_range = REACH


func execute(fighter: FighterController, token: int) -> void:
	fighter.attack_direction = fighter.guard_direction
	fighter.skill_hint = "GUARD BREAK"
	if not await _wait(fighter, token, WINDUP):
		return

	var attack := _create_attack(fighter, 0.0, 0.0, fighter.guard_direction)
	attack.unblockable = true
	attack.unparryable = true
	attack.guard_break = true
	_hit_in_range(fighter, attack, REACH)
