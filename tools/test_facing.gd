extends SceneTree

var _done := false

func _process(_delta: float) -> bool:
    if _done:
        return true
    _done = true
    var packed: PackedScene = load("res://art/models/pawn_white_3d.glb")
    var inst: Node3D = packed.instantiate() as Node3D
    root.add_child(inst)
    
    var visor := inst.find_child("VisorSlit", true, false) as Node3D
    var shield := inst.find_child("ShieldBody", true, false) as Node3D
    var sword := inst.find_child("SwordBlade", true, false) as Node3D
    
    print("Visor global pos: ", visor.global_position if visor else "null")
    print("Shield global pos: ", shield.global_position if shield else "null")
    print("Sword global pos: ", sword.global_position if sword else "null")
    quit(0)
    return true
