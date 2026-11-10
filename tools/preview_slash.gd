extends SceneTree
var elapsed := 0.0
var stage: Node3D
var shot := false

func _initialize() -> void:
	stage = Node3D.new()
	root.add_child.call_deferred(stage)
	setup.call_deferred()

func setup() -> void:
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(0, 6, 8)
	camera.look_at(Vector3(0, 1, 0))
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.018, 0.025, 0.045)
	environment.environment = env
	stage.add_child(environment)
	for i in 3:
		var label := Label3D.new()
		label.text = ["LEFT", "RIGHT", "TOP / HEAVY"][i]
		label.position = Vector3((i - 1) * 4.0, 0, 1.7)
		label.font_size = 64
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		stage.add_child(label)
	spawn_all()
	if "--capture" in OS.get_cmdline_user_args():
		Engine.time_scale = 0.0
		shot = true
		capture.call_deferred()

func spawn_all() -> void:
	for i in 3:
		preload("res://scripts/skills/blood_slash.gd").spawn(stage, Vector3((i - 1) * 4.0, 0, 0), Vector3.FORWARD, i, i == 2)

func _process(delta: float) -> bool:
	elapsed += delta
	if elapsed > 1.0:
		elapsed = 0.0
		spawn_all()
	if "--capture" in OS.get_cmdline_user_args() and not shot and elapsed > 0.045:
		shot = true
		capture.call_deferred()
	return false

func capture() -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/vfx/slash_preview.png")
	quit()
