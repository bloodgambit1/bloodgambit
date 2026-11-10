extends SceneTree

func _init() -> void:
    print("=== INSPECTING 3D MODELS ===")
    for path in ["res://art/models/pawn_white_3d.glb", "res://art/models/pawn_black_3d.glb"]:
        print("Checking: ", path)
        var scene: PackedScene = load(path)
        if scene == null:
            print("ERROR: Failed to load ", path)
            continue
        var inst: Node = scene.instantiate()
        print("Instantiated: ", inst.name)
        _print_tree(inst, "  ")
        var anim_player: AnimationPlayer = _find_anim_player(inst)
        if anim_player:
            print("Found AnimationPlayer: ", anim_player.name)
            for anim_name in anim_player.get_animation_list():
                print("  - ", anim_name)
        else:
            print("No AnimationPlayer found!")
    quit(0)

func _find_anim_player(n: Node) -> AnimationPlayer:
    if n is AnimationPlayer:
        return n
    for child in n.get_children():
        var found := _find_anim_player(child)
        if found:
            return found
    return null

func _print_tree(n: Node, indent: String) -> void:
    print(indent, n.name, " (", n.get_class(), ")")
    for child in n.get_children():
        _print_tree(child, indent + "  ")
