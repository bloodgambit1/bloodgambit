extends SceneTree

func _init() -> void:
    print("Testing Pawn 3D Model Instance in Godot...")
    var packed: PackedScene = load("res://art/models/pawn_white_3d.glb")
    var inst: Node3D = packed.instantiate() as Node3D
    root.add_child(inst)
    
    # Check meshes and materials
    var meshes: Array[MeshInstance3D] = []
    for c in inst.find_children("*", "MeshInstance3D", true, false):
        meshes.append(c as MeshInstance3D)
    print("Total MeshInstance3D found: ", meshes.size())
    for m in meshes.slice(0, 5):
        print("  Mesh: ", m.name, " path: ", m.get_path())
    
    var anim_player: AnimationPlayer = inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
    print("AnimationPlayer: ", anim_player)
    if anim_player:
        print("Animations: ", anim_player.get_animation_list())
        anim_player.play("idle")
        print("Played idle successfully!")
    quit(0)
