class_name SkillProjectile
extends Node3D
## กระสุนของสกิล (คลื่นดาบ, คลื่นกากบาท, รอยผ่าพื้น): พุ่งเป็นเส้นตรงไปทางที่เป้ายืนตอนยิง
## โดนเป้าได้ครั้งเดียว ถ้าเป้าเดินหลบออกนอกความกว้างของคลื่นก็ไม่โดน

var attack: AttackData
var target: FighterController
var travel_velocity := Vector3.ZERO
## ความกว้างของคลื่น (เมตร) ยิ่งกว้างยิ่งหลบด้านข้างยาก
var hit_width := 1.0
var max_distance := 15.0

var _travelled := 0.0

const TARGET_RADIUS := 0.5


## ยิงออกจากตัว fighter ไปทางเป้า: visual ควรหันไปทางแกน -Z
static func launch(fighter: FighterController, attack: AttackData, visual: Node3D,
		speed: float, width: float, distance: float, height: float) -> SkillProjectile:
	var projectile := SkillProjectile.new()
	projectile.attack = attack
	projectile.target = fighter.target
	projectile.hit_width = width
	projectile.max_distance = distance
	var direction := fighter.flat_direction_to_target()
	projectile.travel_velocity = direction * speed
	projectile.add_child(visual)
	projectile.add_to_group(SkillEffects.GROUP)

	fighter.get_parent().add_child(projectile)
	projectile.global_position = fighter.global_position + direction * 0.8 + Vector3.UP * height
	projectile.global_basis = Basis.looking_at(direction)
	projectile.reset_physics_interpolation()
	return projectile


func _physics_process(delta: float) -> void:
	var step := travel_velocity * delta
	global_position += step
	_travelled += step.length()

	if target != null and target.state != FighterController.State.DEAD:
		var offset := target.global_position - global_position
		offset.y = 0.0
		if offset.length() <= hit_width * 0.5 + TARGET_RADIUS:
			target.receive_hit(attack)
			queue_free()
			return

	if _travelled >= max_distance:
		queue_free()
