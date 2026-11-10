extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	for direction in 3:
		for heavy in [false, true]:
			var effect: Node3D = preload("res://scripts/skills/blood_slash.gd").spawn(stage, Vector3.ZERO, Vector3.FORWARD, direction, heavy)
			assert(effect.is_in_group("skill_effects"))
			assert(effect.find_children("*", "MeshInstance3D", true, false).size() == 2)
	await create_timer(0.4).timeout
	assert(get_nodes_in_group("skill_effects").is_empty(), "Slash effects must clean themselves up")
	print("PASS: all six slash variants spawn and clean up")
	stage.queue_free()
	quit()
