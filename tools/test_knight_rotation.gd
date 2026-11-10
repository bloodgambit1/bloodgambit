extends SceneTree

func _process(_delta: float) -> bool:
	var char_node := Knight3DCharacter.build(true)
	root.add_child(char_node)
	char_node.force_update_transform()
	
	var visor := char_node.find_child("Knight_Visor", true, false) as Node3D
	var shield := char_node.find_child("Badge_Shield", true, false) as Node3D
	var sword := char_node.find_child("1H_Sword", true, false) as Node3D
	var cape := char_node.find_child("Knight_Cape", true, false) as Node3D
	
	print("--- Knight3D with rotation.y = PI ---")
	print("Visor pos: ", visor.global_position if visor else "none")
	print("Shield pos: ", shield.global_position if shield else "none")
	print("Sword pos: ", sword.global_position if sword else "none")
	print("Cape pos: ", cape.global_position if cape else "none")
	quit(0)
	return true
