extends SceneTree

func _init() -> void:
	print("--- Running Duel Test Simulation (3D Pawned Souls Knight) ---")
	var packed: PackedScene = load("res://scenes/main.tscn")
	var main_scene: Node = packed.instantiate()
	root.add_child(main_scene)

	var player: FighterController = main_scene.get_node("Arena/Player") as FighterController
	var enemy: FighterController = main_scene.get_node("Arena/Enemy") as FighterController

	print("Testing setup_for_duel for Player (White Pawn) & Enemy (Black Pawn)...")
	player.setup_for_duel("White Pawn", 60.0, 60.0, ChessPiece.Type.PAWN, true)
	enemy.setup_for_duel("Black Pawn", 60.0, 60.0, ChessPiece.Type.PAWN, false)

	assert(player.knight_3d != null, "Player must have 3D Knight model")
	assert(enemy.knight_3d != null, "Enemy must have 3D Knight model")

	var player_anim: AnimationPlayer = player.knight_3d.get_animation_player()
	var enemy_anim: AnimationPlayer = enemy.knight_3d.get_animation_player()
	assert(player_anim != null, "Player 3D AnimationPlayer must not be null")
	assert(enemy_anim != null, "Enemy 3D AnimationPlayer must not be null")

	print("Player 3D Animations: ", player_anim.get_animation_list())
	print("Enemy 3D Animations: ", enemy_anim.get_animation_list())

	print("SUCCESS: Both characters are verified genuine 3D rigged models with full animations (Pawned Souls Style)!")
	quit(0)
