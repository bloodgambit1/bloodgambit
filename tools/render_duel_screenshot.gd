extends SceneTree

func _init() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var main_scene: Node = packed.instantiate()
	root.add_child(main_scene)

	var player: FighterController = main_scene.get_node("Arena/Player") as FighterController
	var enemy: FighterController = main_scene.get_node("Arena/Enemy") as FighterController
	var duel_cam: DuelCameraController = main_scene.get_node("Arena/DuelCamera") as DuelCameraController
	var hud: CanvasLayer = main_scene.get_node("DebugHUD") as CanvasLayer
	var arena: Node3D = main_scene.get_node("Arena") as Node3D

	# Setup fighters
	player.setup_for_duel("White Pawn", 60.0, 60.0, ChessPiece.Type.PAWN, true)
	enemy.setup_for_duel("Black Pawn", 60.0, 60.0, ChessPiece.Type.PAWN, false)

	# Position arena and activate
	arena.visible = true
	arena.global_position = Vector3.ZERO
	player.position = Vector3(0.0, 0.0, 2.5)
	enemy.position = Vector3(0.0, 0.0, -1.5)

	# Set enemy to Windup attack state so we can see the red incoming attack indicator!
	enemy.attack_direction = CombatInputController.GuardDirection.TOP
	enemy.state = FighterController.State.WINDUP
	enemy._state_timer = 0.15 # In parry window to see flash and warning!

	# Set player guard to TOP to parry
	player.guard_direction = CombatInputController.GuardDirection.TOP

	# Activate duel camera
	duel_cam.snap_to_target()
	duel_cam.make_current()

	hud.visible = true

	# Wait a couple of physics frames
	_wait_and_capture(main_scene)


func _wait_and_capture(main_scene: Node) -> void:
	for i in range(15):
		await process_frame

	var img := root.get_viewport().get_texture().get_image()
	var out_path := "d:/ponly/Blood Gambit/build/for_honor_duel_verified.png"
	img.save_png(out_path)
	print("Saved screenshot to: ", out_path)
	quit(0)
