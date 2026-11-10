class_name LowPolyArena
extends RefCounted
## Step 8: สร้างฉากสังเวียน low-poly 4 ธีม (ใช้ทำภาพ concept และใช้เป็นฉากดวลในเกมได้)
##   "pawn"   = สนามหินโกธิกยามสนธยา แสงฟ้า + ยอดคริสตัลดำ
##   "knight" = สนามทะเลทรายแดดจัด แสงส้มแดง + หินแหลมและเสาปรักหักพัง
##   "rook"   = สนามภูเขาไฟ หินลอยเหนือลาวา + ป้อมเหล็กมืด
##   "royal"  = มหาวิหารศักดิ์สิทธิ์ (King/Queen) หินอ่อนม่วงขาว + ยอดโบสถ์และรูปปั้น

const TILE := 2.0

const THEMES := {
	"cathedral_board": {
		"floor": Color(0.20, 0.25, 0.36), "floor_alt": Color(0.10, 0.12, 0.18), "floor_jitter": 0.02,
		"glow": Color(0.35, 0.78, 1.0), "structure": Color(0.18, 0.20, 0.28), "window": Color(0.35, 0.78, 1.0),
		"sky_top": Color(0.08, 0.12, 0.22), "sky_horizon": Color(0.25, 0.35, 0.50),
		"ambient": Color(0.60, 0.65, 0.78), "fog": Color(0.12, 0.16, 0.26), "fog_density": 0.008,
		"sun": Color(0.95, 0.95, 1.0), "sun_energy": 1.4,
	},
	"pawn": {
		"floor": Color(0.20, 0.25, 0.36), "floor_alt": Color(0.10, 0.12, 0.18), "floor_jitter": 0.02,
		"glow": Color(0.35, 0.78, 1.0), "structure": Color(0.18, 0.20, 0.28), "window": Color(0.35, 0.78, 1.0),
		"sky_top": Color(0.08, 0.12, 0.22), "sky_horizon": Color(0.25, 0.35, 0.50),
		"ambient": Color(0.60, 0.65, 0.78), "fog": Color(0.12, 0.16, 0.26), "fog_density": 0.008,
		"sun": Color(0.95, 0.95, 1.0), "sun_energy": 1.4,
	},
	"knight": {
		"floor": Color(0.58, 0.4, 0.23), "floor_alt": Color(0.5, 0.33, 0.18), "floor_jitter": 0.14,
		"glow": Color(1.0, 0.32, 0.08), "structure": Color(0.52, 0.34, 0.2), "window": Color(1.0, 0.5, 0.2),
		"sky_top": Color(0.45, 0.3, 0.2), "sky_horizon": Color(0.95, 0.68, 0.4),
		"ambient": Color(0.75, 0.55, 0.38), "fog": Color(0.8, 0.6, 0.4), "fog_density": 0.014,
		"sun": Color(1.0, 0.82, 0.58), "sun_energy": 1.7,
	},
	"rook": {
		"floor": Color(0.13, 0.1, 0.1), "floor_alt": Color(0.1, 0.08, 0.08), "floor_jitter": 0.16,
		"glow": Color(1.0, 0.3, 0.05), "structure": Color(0.12, 0.11, 0.13), "window": Color(1.0, 0.25, 0.05),
		"sky_top": Color(0.03, 0.005, 0.005), "sky_horizon": Color(0.4, 0.08, 0.02),
		"ambient": Color(0.55, 0.22, 0.12), "fog": Color(0.3, 0.07, 0.02), "fog_density": 0.022,
		"sun": Color(1.0, 0.5, 0.3), "sun_energy": 0.45,
	},
	"royal": {
		"floor": Color(0.36, 0.24, 0.52), "floor_alt": Color(0.82, 0.8, 0.88), "floor_jitter": 0.02,
		"glow": Color(0.72, 0.35, 1.0), "structure": Color(0.17, 0.15, 0.22), "window": Color(0.8, 0.5, 1.0),
		"sky_top": Color(0.02, 0.01, 0.05), "sky_horizon": Color(0.16, 0.08, 0.24),
		"ambient": Color(0.4, 0.32, 0.55), "fog": Color(0.12, 0.07, 0.2), "fog_density": 0.02,
		"sun": Color(0.75, 0.65, 1.0), "sun_energy": 0.5,
	},
}


## board_tiles = จำนวนช่องที่มีเส้นเรืองแสงตรงกลาง (3 = สังเวียนดวล, 8 = กระดานเต็ม)
## floor_tiles = ขนาดพื้นทั้งหมด (ช่อง), with_structures = มีสิ่งก่อสร้างรอบสนามไหม
## with_lighting = ใส่ท้องฟ้า/หมอก/แสงอาทิตย์ของธีมมาด้วย (ในเกมปิดไว้ เพราะฉากหลักคุมแสงเอง)
static func build(theme_name: String, board_tiles := 3, floor_tiles := 18, with_structures := true, with_lighting := true) -> Node3D:
	var theme: Dictionary = THEMES[theme_name]
	var root := Node3D.new()
	root.name = "Arena_%s" % theme_name
	if with_lighting:
		root.add_child(create_environment(theme))
		root.add_child(_create_sun(theme))
	_build_floor(root, theme, theme_name, floor_tiles)
	_build_glow_grid(root, theme, board_tiles, theme.floor_jitter + 0.03)

	if with_structures:
		match theme_name:
			"pawn": _build_castle_colosseum(root, theme)
			"knight": _build_desert_ruins(root, theme)
			"rook": _build_iron_fortress(root, theme)
			"royal", "cathedral_board": _build_cathedral(root, theme)
	return root


static func create_environment(theme: Dictionary) -> WorldEnvironment:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = theme.sky_top
	sky_material.sky_horizon_color = theme.sky_horizon
	sky_material.ground_horizon_color = theme.sky_horizon
	sky_material.ground_bottom_color = theme.sky_top
	var sky := Sky.new()
	sky.sky_material = sky_material

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = theme.ambient
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.glow_enabled = true
	environment.glow_intensity = 0.9
	environment.glow_bloom = 0.12
	environment.glow_hdr_threshold = 0.9
	environment.ssao_enabled = true
	environment.fog_enabled = true
	environment.fog_light_color = theme.fog
	environment.fog_density = theme.fog_density
	environment.fog_sky_affect = 0.4

	var world := WorldEnvironment.new()
	world.environment = environment
	return world


static func _create_sun(theme: Dictionary) -> DirectionalLight3D:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 35, 0)
	sun.light_color = theme.sun
	sun.light_energy = theme.sun_energy
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	return sun


# ---------------------------------------------------------------- พื้น

static func _build_floor(root: Node3D, theme: Dictionary, theme_name: String, floor_tiles: int) -> void:
	var floor_root := Node3D.new()
	floor_root.name = "Floor"
	root.add_child(floor_root)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(theme_name)

	# สร้างวัสดุไว้ไม่กี่แบบแล้วสุ่มใช้ (สีพื้นต่างกันเล็กน้อยให้ดูเป็นธรรมชาติ)
	var palette: Array[Material] = []
	for i in 6:
		var base: Color = theme.floor if i % 2 == 0 else theme.floor_alt
		palette.append(LowPoly.material(base.lightened(rng.randf_range(-0.08, 0.08)), 0.9))

	var is_royal := theme_name == "royal"
	var is_lava := theme_name == "rook"
	var half := floor_tiles * 0.5
	for x in floor_tiles:
		for z in floor_tiles:
			var center := Vector3((x - half + 0.5) * TILE, 0.0, (z - half + 0.5) * TILE)
			var size := TILE - (0.18 if is_lava else 0.06)
			var height := 0.4
			var y := -height * 0.5
			if is_lava:
				y += rng.randf_range(-0.12, 0.05)  # หินลอยสูงต่ำไม่เท่ากัน
			var mat: Material
			if is_royal:
				mat = palette[0] if (x + z) % 2 == 0 else palette[1]
			else:
				mat = palette[rng.randi() % palette.size()]
			LowPoly.add(floor_root, LowPoly.box(Vector3(size, height, size)), mat, center + Vector3(0, y, 0),
				Vector3.ZERO, Vector3.ONE, theme.floor_jitter, x * 131 + z)

	if is_lava:
		var lava := LowPoly.add(floor_root, LowPoly.box(Vector3(floor_tiles * TILE + 40, 0.2, floor_tiles * TILE + 40)),
			LowPoly.glow_material(Color(1.0, 0.28, 0.04), 2.2), Vector3(0, -0.75, 0))
		lava.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in 30:
			var bubble := Vector3(rng.randf_range(-half, half) * TILE, -0.6, rng.randf_range(-half, half) * TILE)
			LowPoly.add(floor_root, LowPoly.sphere(rng.randf_range(0.3, 0.7), 5, 3), LowPoly.glow_material(Color(1.0, 0.45, 0.08), 3.0),
				bubble, Vector3.ZERO, Vector3(1, 0.4, 1), 0.1, i)


## เส้นกรอบหิน/รูนโบราณล้อมรอบสังเวียน (สไตล์สนามประลอง For Honor บรรยากาศสมจริง)
static func _build_glow_grid(root: Node3D, theme: Dictionary, board_tiles: int, lift: float) -> void:
	var grid := Node3D.new()
	grid.name = "GlowGrid"
	root.add_child(grid)
	var line_material := LowPoly.glow_material(theme.glow * 0.7, 0.45)
	var length := board_tiles * TILE
	var half := length * 0.5
	for i in board_tiles + 1:
		var offset := -half + i * TILE
		var line_x := LowPoly.add(grid, LowPoly.box(Vector3(length + 0.04, 0.015, 0.04)), line_material, Vector3(0, lift, offset))
		var line_z := LowPoly.add(grid, LowPoly.box(Vector3(0.04, 0.015, length + 0.04)), line_material, Vector3(offset, lift, 0))
		line_x.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		line_z.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var light := OmniLight3D.new()
	light.light_color = theme.glow.lerp(Color(1.0, 0.85, 0.65), 0.5)
	light.light_energy = 0.65
	light.omni_range = maxf(8.0, length)
	light.position = Vector3(0, 1.8, 0)
	grid.add_child(light)


# ---------------------------------------------------------------- สิ่งก่อสร้างรอบสนาม

## จุดสุ่มเป็นวงรอบสนาม (เว้นด้านหน้ากล้อง +Z ไว้บางส่วนไม่ให้บังภาพ)
static func _ring_points(count: int, min_radius: float, max_radius: float, seed: int) -> Array[Vector3]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var points: Array[Vector3] = []
	for i in count:
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(min_radius, max_radius)
		var point := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		if point.z > min_radius * 0.6 and absf(point.x) < min_radius * 0.8:
			continue
		points.append(point)
	return points


static func _build_wall_ring(root: Node3D, color: Color, radius: float, height: float, seed: int) -> void:
	var wall_material := LowPoly.material(color, 0.9)
	var segments := 28
	for i in segments:
		var angle := TAU * i / segments
		var position := Vector3(cos(angle) * radius, height * 0.5, sin(angle) * radius)
		if position.z > radius * 0.5:
			continue
		var wall := LowPoly.add(root, LowPoly.box(Vector3(radius * TAU / segments + 0.4, height, 1.2)), wall_material,
			position, Vector3(0, -rad_to_deg(angle) + 90, 0), Vector3.ONE, 0.25, seed + i)
		wall.name = "Wall%d" % i
		# ใบเสมาบนกำแพง
		for k in 3:
			LowPoly.add(root, LowPoly.box(Vector3(0.8, 0.8, 1.3)), wall_material,
				position + Vector3(0, height * 0.5 + 0.4, 0) + Vector3(-sin(angle), 0, cos(angle)) * ((k - 1) * 1.6),
				Vector3(0, -rad_to_deg(angle) + 90, 0), Vector3.ONE, 0.15, seed + i * 7 + k)


## สนามประลองป้อมปราการหิน 3D สไตล์ For Honor (กำแพงหิน, เสาคบเพลิงไฟลุกโชน, ธงศึก และชั้นวางอาวุธ)
static func _build_castle_colosseum(root: Node3D, theme: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var stone_wall_mat := LowPoly.material(theme.structure, 0.90)
	var stone_trim_mat := LowPoly.material(theme.structure.lightened(0.12), 0.85)
	var wood_mat := LowPoly.material(Color(0.28, 0.18, 0.10), 0.88)
	var iron_mat := LowPoly.material(Color(0.12, 0.13, 0.15), 0.5, 0.7)
	var fire_mat := LowPoly.glow_material(Color(1.0, 0.55, 0.1), 3.5)
	var banner_white_mat := LowPoly.material(Color(0.85, 0.82, 0.75), 0.9)
	var banner_black_mat := LowPoly.material(Color(0.25, 0.12, 0.35), 0.9)

	# 1. กำแพงหินทรงป้อมปราการ 8 เหลี่ยมล้อมรอบสังเวียน (Wall Ring with Battlements)
	var wall_radius := 14.0
	var wall_height := 5.2
	var segments := 16
	for i in segments:
		var angle := TAU * i / segments
		if sin(angle) > 0.85: # เว้นด้านหลังกล้องเปิดโล่ง
			continue
		var pos := Vector3(cos(angle) * wall_radius, wall_height * 0.5, sin(angle) * wall_radius)
		var rot_y := -rad_to_deg(angle) + 90
		# ตัวกำแพงหิน
		LowPoly.add(root, LowPoly.box(Vector3(wall_radius * TAU / segments + 0.3, wall_height, 1.4)), stone_wall_mat, pos, Vector3(0, rot_y, 0))
		# ขอบคานหินด้านบน
		LowPoly.add(root, LowPoly.box(Vector3(wall_radius * TAU / segments + 0.5, 0.4, 1.6)), stone_trim_mat, pos + Vector3(0, wall_height * 0.5 + 0.2, 0), Vector3(0, rot_y, 0))
		# ใบเสมาบนกำแพง
		for k in 2:
			var offset_tangent := Vector3(-sin(angle), 0, cos(angle)) * ((k - 0.5) * 2.2)
			LowPoly.add(root, LowPoly.box(Vector3(1.1, 0.9, 1.6)), stone_wall_mat, pos + Vector3(0, wall_height * 0.5 + 0.65, 0) + offset_tangent, Vector3(0, rot_y, 0))

	# 2. เสาหินและคบเพลิงล้อมรอบสังเวียน (8 เสา)
	var pillar_radius := 8.5
	var pillar_count := 8
	for i in pillar_count:
		var angle := TAU * i / pillar_count
		if sin(angle) > 0.8: # เว้นมุมมองกล้อง
			continue
		var p_pos := Vector3(cos(angle) * pillar_radius, 0, sin(angle) * pillar_radius)
		# ฐานเสาหิน
		LowPoly.add(root, LowPoly.box(Vector3(1.4, 0.6, 1.4)), stone_trim_mat, p_pos + Vector3(0, 0.3, 0))
		# ตัวเสาหิน 8 เหลี่ยม
		LowPoly.add(root, LowPoly.cylinder(0.45, 0.55, 3.8, 8), stone_wall_mat, p_pos + Vector3(0, 2.2, 0))
		# หัวเสา
		LowPoly.add(root, LowPoly.box(Vector3(1.3, 0.5, 1.3)), stone_trim_mat, p_pos + Vector3(0, 4.35, 0))

		# คบเพลิงกระถางไฟเหล็ก (Brazier)
		var brazier_pos := p_pos + Vector3(0, 3.2, 0) - p_pos.normalized() * 0.65
		# ก้านเหล็กยื่น
		LowPoly.add(root, LowPoly.box(Vector3(0.12, 0.12, 0.7)), iron_mat, brazier_pos + p_pos.normalized() * 0.35, Vector3(0, -rad_to_deg(angle), 0))
		# ชามใส่ไฟ
		LowPoly.add(root, LowPoly.cylinder(0.35, 0.18, 0.3, 6), iron_mat, brazier_pos)
		# เปลวไฟเรืองแสง
		var flame := LowPoly.add(root, LowPoly.sphere(0.22, 5, 4), fire_mat, brazier_pos + Vector3(0, 0.22, 0))
		flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		# ไฟส่องสว่างเรืองแสงรอบคบเพลิง
		var torch_light := OmniLight3D.new()
		torch_light.light_color = Color(1.0, 0.65, 0.22)
		torch_light.light_energy = 1.8
		torch_light.omni_range = 9.0
		torch_light.position = brazier_pos + Vector3(0, 0.35, 0)
		root.add_child(torch_light)

	# 3. ธงศึกประจำฝ่าย (Heraldic Banners) แขวนบนกำแพง
	for i in range(2):
		var b_angle := -PI * 0.25 if i == 0 else -PI * 0.75
		var b_pos := Vector3(cos(b_angle) * (wall_radius - 0.7), wall_height - 1.2, sin(b_angle) * (wall_radius - 0.7))
		var mat := banner_white_mat if i == 0 else banner_black_mat
		# ราวไม้แขวนธง
		LowPoly.add(root, LowPoly.box(Vector3(2.4, 0.12, 0.12)), wood_mat, b_pos + Vector3(0, 1.2, 0), Vector3(0, -rad_to_deg(b_angle) + 90, 0))
		# ผืนธง
		var banner := LowPoly.add(root, LowPoly.box(Vector3(1.8, 2.5, 0.04)), mat, b_pos, Vector3(0, -rad_to_deg(b_angle) + 90, 0))
		banner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# 4. ชั้นวางอาวุธ (Weapon Racks) ริมสังเวียน
	var rack_pos := Vector3(-7.2, 0, 1.0)
	LowPoly.add(root, LowPoly.box(Vector3(2.2, 0.1, 0.6)), wood_mat, rack_pos + Vector3(0, 0.05, 0))
	LowPoly.add(root, LowPoly.box(Vector3(0.1, 1.6, 0.1)), wood_mat, rack_pos + Vector3(-1.0, 0.8, 0))
	LowPoly.add(root, LowPoly.box(Vector3(0.1, 1.6, 0.1)), wood_mat, rack_pos + Vector3(1.0, 0.8, 0))
	LowPoly.add(root, LowPoly.box(Vector3(2.2, 0.1, 0.1)), wood_mat, rack_pos + Vector3(0, 1.3, 0))
	for s in 4:
		var spear_x := (s - 1.5) * 0.5
		LowPoly.add(root, LowPoly.cylinder(0.025, 0.025, 2.2, 4), wood_mat, rack_pos + Vector3(spear_x, 1.1, 0.05), Vector3(12, 0, 0))
		LowPoly.add(root, LowPoly.box(Vector3(0.08, 0.35, 0.02)), iron_mat, rack_pos + Vector3(spear_x, 2.2, -0.15), Vector3(12, 0, 0))


static func _build_desert_ruins(root: Node3D, theme: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var rock_material := LowPoly.material(theme.structure, 0.95)
	var stone_material := LowPoly.material(Color(0.68, 0.55, 0.4), 0.95)
	for point in _ring_points(26, 19.0, 34.0, 22):
		var size := rng.randf_range(2.0, 6.0)
		LowPoly.add(root, LowPoly.sphere(size, 6, 4), rock_material, point + Vector3(0, size * 0.3, 0),
			Vector3(0, rng.randf_range(0, 360), 0), Vector3(1, rng.randf_range(0.8, 2.2), 1), size * 0.3, rng.randi())
	for point in _ring_points(16, 15.0, 24.0, 23):
		var height := rng.randf_range(3.0, 8.0)
		if rng.randf() < 0.3:
			# เสาล้ม
			LowPoly.add(root, LowPoly.cylinder(0.75, 0.8, height, 6), stone_material, point + Vector3(0, 0.6, 0),
				Vector3(90, rng.randf_range(0, 360), 0), Vector3.ONE, 0.12, rng.randi())
			continue
		LowPoly.add(root, LowPoly.cylinder(0.7, 0.85, height, 6), stone_material, point + Vector3(0, height * 0.5, 0),
			Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-5, 5)), Vector3.ONE, 0.12, rng.randi())
		LowPoly.add(root, LowPoly.box(Vector3(2.0, 0.6, 2.0)), stone_material, point + Vector3(0, height + 0.2, 0),
			Vector3(rng.randf_range(-12, 12), rng.randf_range(0, 90), rng.randf_range(-12, 12)), Vector3.ONE, 0.2, rng.randi())


static func _build_iron_fortress(root: Node3D, theme: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var iron_material := LowPoly.material(theme.structure, 0.55, 0.65)
	var window_material := LowPoly.glow_material(theme.window, 4.0)
	_build_wall_ring(root, theme.structure, 21.0, 7.0, 400)
	for point in _ring_points(14, 23.0, 34.0, 32):
		var height := rng.randf_range(10.0, 18.0)
		var radius := rng.randf_range(2.5, 4.0)
		LowPoly.add(root, LowPoly.cylinder(radius * 0.85, radius, height, 8), iron_material, point + Vector3(0, height * 0.5, 0),
			Vector3.ZERO, Vector3.ONE, 0.2, rng.randi())
		for k in 8:
			var angle := TAU * k / 8.0
			LowPoly.add(root, LowPoly.box(Vector3(1.0, 1.2, 1.0)), iron_material,
				point + Vector3(cos(angle) * radius * 0.85, height + 0.6, sin(angle) * radius * 0.85),
				Vector3(0, -rad_to_deg(angle), 0), Vector3.ONE, 0.1, rng.randi())
		for k in 3:
			var slit := LowPoly.add(root, LowPoly.box(Vector3(0.3, 1.4, 0.3)), window_material,
				point + Vector3(0, height * (0.35 + k * 0.18), 0) - point.normalized() * radius * 0.92)
			slit.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# แสงลาวาจากด้านล่าง
	for i in 6:
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.35, 0.05)
		light.light_energy = 2.5
		light.omni_range = 14.0
		light.position = Vector3(cos(TAU * i / 6.0) * 12.0, -0.3, sin(TAU * i / 6.0) * 12.0)
		root.add_child(light)


static func _build_cathedral(root: Node3D, theme: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var stone_material := LowPoly.material(theme.structure, 0.8)
	var window_material := LowPoly.glow_material(theme.window, 3.0)
	for point in _ring_points(18, 22.0, 34.0, 42):
		var base_height := rng.randf_range(5.0, 9.0)
		var spire_height := rng.randf_range(6.0, 12.0)
		var width := rng.randf_range(2.5, 4.0)
		var facing := Vector3(0, rad_to_deg(atan2(point.x, point.z)), 0)
		LowPoly.add(root, LowPoly.box(Vector3(width, base_height, width)), stone_material, point + Vector3(0, base_height * 0.5, 0),
			facing, Vector3.ONE, 0.15, rng.randi())
		LowPoly.add(root, LowPoly.cylinder(0.0, width * 0.62, spire_height, 4), stone_material,
			point + Vector3(0, base_height + spire_height * 0.5, 0), facing + Vector3(0, 45, 0), Vector3.ONE, 0.1, rng.randi())
		for k in 4:
			var corner := Vector3(width * 0.5 * (1 if k % 2 == 0 else -1), 0, width * 0.5 * (1 if k < 2 else -1))
			LowPoly.add(root, LowPoly.cylinder(0.0, 0.35, 2.5, 4), stone_material,
				point + corner + Vector3(0, base_height + 1.25, 0), Vector3.ZERO, Vector3.ONE, 0.05, rng.randi())
		var window := LowPoly.add(root, LowPoly.box(Vector3(0.9, 2.2, 0.2)), window_material,
			point + Vector3(0, base_height * 0.55, 0) - point.normalized() * (width * 0.52), facing)
		window.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# ค้ำยันลอยฟ้า (flying buttress) เอนเข้าหาสนาม
		LowPoly.add(root, LowPoly.box(Vector3(0.6, base_height * 0.9, 0.6)), stone_material,
			point - point.normalized() * (width * 0.5 + 1.6) + Vector3(0, base_height * 0.4, 0),
			Vector3(-18, facing.y, 0),
			Vector3.ONE, 0.05, rng.randi())

	# รูปปั้นหินของ King และ Queen ยืนเฝ้ารอบสนาม
	var statue_material := LowPoly.material(Color(0.32, 0.3, 0.36), 0.9)
	LowPoly.forced_material = statue_material
	var statue_types := ["king", "queen", "bishop", "king", "queen", "bishop"]
	for i in statue_types.size():
		var angle := PI + (i - 2.5) * 0.42
		var statue := LowPolyCharacters.build(statue_types[i])
		statue.scale = Vector3.ONE * 1.6
		statue.position = Vector3(cos(angle) * 17.0, 1.2, sin(angle) * 17.0 - 2.0)
		statue.rotation.y = atan2(-statue.position.x, -statue.position.z) + PI
		root.add_child(statue)
		LowPoly.add(root, LowPoly.box(Vector3(2.4, 1.2, 2.4)), statue_material, statue.position - Vector3(0, 0.6, 0),
			Vector3(0, rad_to_deg(statue.rotation.y), 0), Vector3.ONE, 0.05, i)
	LowPoly.forced_material = null
