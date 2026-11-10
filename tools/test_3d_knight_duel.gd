extends SceneTree

func _init() -> void:
    print("=== TESTING 3D KNIGHT SYSTEM IN GODOT ===")
    var packed: PackedScene = load("res://scenes/main.tscn")
    var main_scene: Node = packed.instantiate()
    root.add_child(main_scene)

    var player: FighterController = main_scene.get_node("Arena/Player") as FighterController
    var enemy: FighterController = main_scene.get_node("Arena/Enemy") as FighterController

    print("Setting up duel: White Pawn vs Black Pawn...")
    player.setup_for_duel("White Pawn", 60.0, 60.0, ChessPiece.Type.PAWN, true)
    enemy.setup_for_duel("Black Pawn", 60.0, 60.0, ChessPiece.Type.PAWN, false)

    # Verify Knight3D
    assert(player.knight_3d != null, "Player must have Knight3D")
    assert(enemy.knight_3d != null, "Enemy must have Knight3D")
    print("PASS: Both fighters have Knight3D instantiated!")

    var player_anim: AnimationPlayer = player.knight_3d.get_animation_player()
    var enemy_anim: AnimationPlayer = enemy.knight_3d.get_animation_player()
    assert(player_anim != null, "Player Knight3D must have AnimationPlayer")
    assert(enemy_anim != null, "Enemy Knight3D must have AnimationPlayer")
    print("PASS: Both 3D models have valid AnimationPlayer!")

    # Verify Animator node
    var p_animator: FighterAnimator = player.get_node("Animator") as FighterAnimator
    assert(p_animator.animation_player == player_anim, "Player Animator must bind to 3D AnimationPlayer")
    print("PASS: FighterAnimator bound directly to 3D AnimationPlayer!")

    # Test guard stance changes
    print("Testing guard stances...")
    player.set_guard_direction(CombatInputController.GuardDirection.LEFT)
    p_animator._update_locomotion()
    assert(player_anim.current_animation == "guard_left", "Player should be playing guard_left")
    print("  -> Guard LEFT: OK")

    player.set_guard_direction(CombatInputController.GuardDirection.RIGHT)
    p_animator._update_locomotion()
    assert(player_anim.current_animation == "guard_right", "Player should be playing guard_right")
    print("  -> Guard RIGHT: OK")

    player.set_guard_direction(CombatInputController.GuardDirection.TOP)
    p_animator._update_locomotion()
    assert(player_anim.current_animation == "guard_top", "Player should be playing guard_top")
    print("  -> Guard TOP: OK")

    # Test attacks
    print("Testing attack triggers...")
    player.start_attack(CombatInputController.GuardDirection.LEFT, false)
    assert(player_anim.current_animation == "attack_left", "Player should play attack_left")
    print("  -> Attack LEFT: OK")

    player.reset_fighter()
    player.start_attack(CombatInputController.GuardDirection.RIGHT, false)
    assert(player_anim.current_animation == "attack_right", "Player should play attack_right")
    print("  -> Attack RIGHT: OK")

    player.reset_fighter()
    player.start_attack(CombatInputController.GuardDirection.TOP, true)
    assert(player_anim.current_animation == "attack_top", "Player should play attack_top")
    print("  -> Attack TOP: OK")

    # Test parry
    player.reset_fighter()
    player.parry()
    assert(player_anim.current_animation == "parry", "Player should play parry")
    print("  -> Parry: OK")

    # Test dodge
    player.reset_fighter()
    player.dodge()
    assert(player_anim.current_animation == "dodge_step", "Player should play dodge_step")
    print("  -> Dodge step: OK")

    # Test double tap roll
    player.reset_fighter()
    player.dodge_is_roll = true
    p_animator._on_state_changed(FighterController.State.DODGE)
    assert(player_anim.current_animation == "dodge_roll", "Player should play dodge_roll")
    print("  -> Dodge roll: OK")

    print("\nALL 3D KNIGHT TESTS PASSED WITH 100% SUCCESS!")
    quit(0)
