extends Node3D
## VFX 01: a short world-space ribbon, independent of combat damage.
const RIBBON = preload("res://art/vfx/blood_slash.glb")
const SHADER = preload("res://art/vfx/blood_slash.gdshader")

static func spawn(parent: Node, at: Vector3, forward: Vector3, direction: int, heavy: bool) -> Node3D:
	var effect := Node3D.new()
	effect.name = "BloodSlash"
	effect.add_to_group("skill_effects")
	effect.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	parent.add_child(effect)
	effect.global_position = at + Vector3.UP * 1.15
	effect.global_basis = Basis.looking_at(forward)
	var pivot := Node3D.new()
	effect.add_child(pivot)
	if direction == 2:
		pivot.rotation.z = PI * 0.5
	else:
		pivot.rotation.z = -0.18 if direction == 0 else 0.18
	var size := 1.2 if heavy else 1.0
	pivot.scale = Vector3.ONE * size
	var duration := 0.26 if heavy else 0.18
	var sign_dir := -1.0 if direction == 0 else 1.0
	pivot.rotation.y = -0.5 * sign_dir
	for layer in 2:
		var ribbon: Node3D = RIBBON.instantiate()
		pivot.add_child(ribbon)
		ribbon.scale = Vector3.ONE * (1.0 - layer * 0.13)
		ribbon.position.y = layer * 0.025
		var material := ShaderMaterial.new()
		material.shader = SHADER
		material.set_shader_parameter("tint", Color(1.0, 0.07, 0.025) if layer == 0 else Color(1.0, 0.45, 0.08))
		for child in ribbon.find_children("*", "MeshInstance3D", true, false):
			child.material_override = material
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var fade := effect.create_tween()
		fade.tween_method(func(value: float): material.set_shader_parameter("strength", value), 1.0, 0.0, duration)
	var motion := effect.create_tween()
	motion.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	motion.tween_property(pivot, "rotation:y", 0.5 * sign_dir, duration)
	motion.tween_callback(effect.queue_free)
	return effect
