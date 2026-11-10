extends SceneTree
var result := -1

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var player: FighterController = scene.get_node("Arena/Player")
	var enemy: FighterController = scene.get_node("Arena/Enemy")
	for defender in [player, enemy]:
		defender.hit_resolved.connect(func(value: int): result = value)
		for direction in 3:
			for guard in 3:
				defender.reset_fighter()
				defender.set_guard_direction(guard)
				defender.receive_hit(AttackData.new(defender.target, direction, 10, 5))
				assert(result == (FighterController.HitResult.BLOCKED if direction == guard else FighterController.HitResult.HIT))
			defender.reset_fighter()
			defender.set_guard_direction(direction)
			defender.parry()
			defender.receive_hit(AttackData.new(defender.target, direction, 10, 5))
			assert(result == FighterController.HitResult.PARRIED)
	for direction in 3:
		assert(player.local_visual_direction(direction) == direction)
		assert(enemy.local_visual_direction(direction) == ([1, 0, 2][direction]))
		for heavy in [false, true]:
			enemy.reset_fighter()
			enemy.start_attack(direction, heavy)
			var animator: FighterAnimator = enemy.get_node("Animator")
			assert(animator.animation_player.current_animation == ["placeholder/attack_right", "placeholder/attack_left", "placeholder/attack_top"][direction])
			enemy._change_state(FighterController.State.ATTACKING, enemy.attack_recovery)
			assert(is_equal_approx(animator.animation_player.current_animation_position, 0.45))
	var input: CombatInputController = scene.get_node("CombatInputController")
	player.reset_fighter()
	input.request_guard_direction(CombatInputController.GuardDirection.LEFT)
	input._perform_attack(false)
	assert(input._has_queued_attack)
	input._apply_pending_guard()
	assert(input.current_guard_direction == CombatInputController.GuardDirection.LEFT)
	assert(not input._has_queued_attack)
	assert(player.state == FighterController.State.WINDUP)
	assert(player.attack_direction == CombatInputController.GuardDirection.LEFT)
	print("PASS: 18 block cases, 6 parries, mirrored animation lanes, release timing, queued mouse attack")
	quit()
