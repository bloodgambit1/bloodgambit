extends SceneTree

func _process(_delta: float) -> bool:
	var packed: PackedScene = load("res://art/models/pawn_white_3d.glb")
	var inst: Node3D = packed.instantiate() as Node3D
	root.add_child(inst)
	
	# wait 1 frame
	inst.force_update_transform()
	
	var visor := inst.find_child("Knight_Visor", true, false) as Node3D
	var helmet := inst.find_child("Knight_Helmet", true, false) as Node3D
	var shield := inst.find_child("Badge_Shield", true, false) as Node3D
	var sword := inst.find_child("1H_Sword", true, false) as Node3D
	var cape := inst.find_child("Knight_Cape", true, false) as Node3D
	
	print("Visor global pos: ", visor.global_position if visor else "none")
	print("Helmet global pos: ", helmet.global_position if helmet else "none")
	print("Cape global pos: ", cape.global_position if cape else "none")
	print("Shield global pos: ", shield.global_position if shield else "none")
	print("Sword global pos: ", sword.global_position if sword else "none")
	quit(0)
	return true
