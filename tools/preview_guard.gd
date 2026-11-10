extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var manager: ChessArenaManager = scene.get_node("ChessArenaManager")
	manager.set_process(false)
	manager.set_process_unhandled_input(false)
	manager._set_pieces_visible(false)
	manager._show_arena_theme("pawn")
	var arena: Node3D = scene.get_node("Arena")
	arena.position = Vector3(0, 2, 0)
	arena.visible = true
	manager._place_fighters()
	manager._set_combat_active(true)
	scene.get_node("Arena/EnemyAI").active = false
	var player: FighterController = scene.get_node("Arena/Player")
	var enemy: FighterController = scene.get_node("Arena/Enemy")
	player.setup_for_duel("Player", 100, 100, ChessPiece.Type.PAWN)
	enemy.setup_for_duel("Enemy", 100, 100, ChessPiece.Type.PAWN)
	enemy.rotation.y = PI
	var camera: DuelCameraController = scene.get_node("Arena/DuelCamera")
	camera.snap_to_target()
	camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for direction in 3:
		player.set_guard_direction(direction)
		enemy.set_guard_direction(direction)
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art/vfx/guard_%s.png" % ["left", "right", "top"][direction])
	enemy.start_attack(CombatInputController.GuardDirection.RIGHT, true)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/vfx/guard_warning.png")
	quit()
