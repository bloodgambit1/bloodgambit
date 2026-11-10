class_name AttackData
extends RefCounted
## ข้อมูลของการโจมตี 1 ครั้ง ส่งให้ FighterController.receive_hit() ตัดสินว่า Block / Parry / หลบ / โดน
## ฟันปกติใช้ค่าเริ่มต้นทั้งหมด ส่วนสกิลเปิดคุณสมบัติพิเศษตามต้องการ

var attacker: FighterController
var attack_name := "Attack"
var direction: CombatInputController.GuardDirection
var damage := 10.0
var posture_damage := 10.0
## จุดกำเนิดแรงผลัก (ค่าเริ่มต้น = ตำแหน่งผู้โจมตีตอนสร้าง)
var origin := Vector3.ZERO

## ตั้งการ์ดรับไม่ได้ (แต่ยัง Parry หรือหลบได้ ถ้าไม่ได้ปิดไว้)
var unblockable := false
## Parry ไม่ได้
var unparryable := false
## Block ได้แต่ยังโดนดาเมจ 70% และทะลุ Hyper Armor
var armor_piercing := false
## กลิ้งหลบด้วย I-frames ไม่ได้
var ignore_iframes := false
## โดนหรือ Block ก็การ์ดแตก ติด Stunned
var guard_break := false
## ความเร็วแรงผลัก (m/s) 0 = ไม่ผลัก
var knockback := 0.0
## Parry สำเร็จแล้วผู้โจมตีติด Stunned ไหม (กระสุน/ระเบิดตั้งเป็น false = แค่ปัดทิ้ง)
var parry_stuns_attacker := true


func _init(from: FighterController, attack_direction: CombatInputController.GuardDirection, attack_damage: float, attack_posture_damage: float) -> void:
	attacker = from
	direction = attack_direction
	damage = attack_damage
	posture_damage = attack_posture_damage
	if from != null:
		origin = from.global_position
