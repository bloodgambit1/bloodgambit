class_name SkillBomb
extends Node3D
## ระเบิดที่วางไว้บนพื้น: กะพริบนับถอยหลัง แล้วระเบิดโดนเป้าที่ยังยืนอยู่ในวง

var attack: AttackData
var target: FighterController
var radius := 2.0
var fuse := 1.2

var _core: MeshInstance3D


static func plant(fighter: FighterController, attack: AttackData, world_position: Vector3,
		blast_radius: float, fuse_time: float) -> SkillBomb:
	var bomb := SkillBomb.new()
	bomb.attack = attack
	bomb.target = fighter.target
	bomb.radius = blast_radius
	bomb.fuse = fuse_time
	bomb.add_to_group(SkillEffects.GROUP)
	fighter.get_parent().add_child(bomb)
	bomb.global_position = Vector3(world_position.x, fighter.global_position.y, world_position.z)
	bomb.reset_physics_interpolation()
	return bomb


func _ready() -> void:
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.35
	core_mesh.height = 0.7
	core_mesh.material = SkillEffects.make_material(Color(1.0, 0.2, 0.1))
	_core = MeshInstance3D.new()
	_core.mesh = core_mesh
	_core.position.y = 0.35
	add_child(_core)

	# วงบนพื้นบอกรัศมีระเบิด
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = radius
	ring_mesh.bottom_radius = radius
	ring_mesh.height = 0.02
	ring_mesh.material = SkillEffects.make_material(Color(1.0, 0.2, 0.1, 0.25))
	var ring := MeshInstance3D.new()
	ring.mesh = ring_mesh
	ring.position.y = 0.02
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)


func _physics_process(delta: float) -> void:
	fuse -= delta
	_core.visible = fmod(fuse, 0.2) > 0.1
	if fuse <= 0.0:
		_explode()


func _explode() -> void:
	SkillEffects.spawn_flash(get_parent(), global_position + Vector3.UP * 0.5, radius, Color(1.0, 0.5, 0.1))
	if target != null and target.state != FighterController.State.DEAD:
		var offset := target.global_position - global_position
		offset.y = 0.0
		if offset.length() <= radius:
			target.receive_hit(attack)
		else:
			print("[Skill] %s ระเบิดไม่โดน" % attack.attack_name)
	queue_free()
