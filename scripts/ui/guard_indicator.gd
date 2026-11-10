extends Control
## For Honor "Art of Battle" Tri-Directional Stance Widget & Combat UI
## - Stance Widget 3 ทิศทาง (TOP, LEFT, RIGHT) สไตล์ For Honor แท้ (โปร่งแสง ไม่บดบังตัวละคร)
## - ผู้เล่น: ปีกทิศที่ตั้งการ์ดเรืองแสงสีขาว-ฟ้า พร้อมลูกศร Chevron คมชัด (ไม่มีตัวหนังสือรกบังตัวละคร)
## - ศัตรู: Widget อยู่ที่หน้าอกศัตรู ปีกทิศง้างฟันกะพริบสีแดงเพลิง และกะพริบแสงสีขาววาบ (⚡ PARRY NOW! ⚡)
## - หลอดเลือดและชื่อศัตรูแบบ Overhead ลอยเหนือหัวศัตรูเหมือน For Honor 100%
## - วงแหวน Lock-on พื้นรอบเท้าศัตรู

var player: FighterController
var enemy: FighterController

const COLOR_STEEL_DARK := Color(0.05, 0.07, 0.10, 0.45)
const COLOR_STEEL_RIM := Color(0.55, 0.65, 0.78, 0.60)
const COLOR_ACTIVE_GUARD_FILL := Color(0.20, 0.55, 0.90, 0.55)
const COLOR_ACTIVE_GUARD_RIM := Color(0.95, 0.98, 1.0, 0.98)

const COLOR_ATTACK_RED := Color(0.95, 0.18, 0.10, 0.85)
const COLOR_ATTACK_RIM := Color(2.0, 0.40, 0.20, 1.0)
const COLOR_PARRY_FLASH := Color(3.0, 3.0, 3.2, 1.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if player == null or enemy == null:
		return
	if not is_visible_in_tree() or not player.is_inside_tree() or not player.is_visible_in_tree():
		return
	if not enemy.is_inside_tree() or not enemy.is_visible_in_tree():
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var viewport_size := get_viewport_rect().size

	# 1. วงแหวน Lock-On บนพื้นที่เท้าศัตรู (บาง คม สไตล์ For Honor)
	_draw_lockon_ground(camera, enemy.global_position)

	# 2. หลอดเลือดและชื่อศัตรู Overhead Lock-on Bar (สไตล์ For Honor แท้ เหนือหัวศัตรู)
	_draw_enemy_overhead_hud(camera, enemy)

	# 3. Stance Widget ของผู้เล่น (Player Guard Widget)
	# วางระดับอก/หลังส่วนบน (Vector3.UP * 1.05) มองเห็นชัด ไม่บดบังเอว/สะโพก
	var player_anchor := player.global_position + Vector3.UP * 1.05
	if not camera.is_position_behind(player_anchor):
		var p_center := camera.unproject_position(player_anchor)
		var p_radius := clampf(viewport_size.y * 0.050, 32.0, 44.0)
		p_center.x = clampf(p_center.x, p_radius + 20.0, viewport_size.x - p_radius - 20.0)
		p_center.y = clampf(p_center.y, p_radius + 60.0, viewport_size.y - p_radius - 40.0)

		_draw_for_honor_widget(p_center, p_radius, player.guard_direction, -1, false, false)

	# 4. Stance Widget ของศัตรู (Enemy Indicator ที่หน้าอกศัตรู + Attack Alert + Parry Flash)
	var enemy_anchor := enemy.global_position + Vector3.UP * 0.95
	if not camera.is_position_behind(enemy_anchor):
		var e_center := camera.unproject_position(enemy_anchor)
		var e_radius := clampf(viewport_size.y * 0.050, 32.0, 44.0)

		var is_attacking: bool = enemy.state == FighterController.State.WINDUP or enemy.state == FighterController.State.ATTACKING
		var attack_dir: int = enemy.attack_direction if is_attacking else -1

		# ตรวจสอบหน้าต่าง Parry (ช่วง 0.28s สุดท้ายก่อนดาบปะทะ เพื่อให้เห็นชัดบนมือถือ)
		var is_parry_window := false
		if enemy.state == FighterController.State.WINDUP:
			is_parry_window = enemy._state_timer <= 0.28

		_draw_for_honor_widget(e_center, e_radius, enemy.guard_direction if not is_attacking else -1, attack_dir, is_parry_window, true)

		# ข้อความเตือนจังหวะ Parry ใน For Honor
		if is_attacking:
			if is_parry_window:
				_draw_outlined_text(e_center + Vector2(0, -e_radius * 1.25), "⚡ PARRY NOW! ⚡", 16, COLOR_PARRY_FLASH)
			else:
				var att_type := "HEAVY ATTACK" if enemy.attack_is_heavy else "ATTACK"
				_draw_outlined_text(e_center + Vector2(0, -e_radius * 1.25), att_type, 13, Color(1.0, 0.4, 0.25))


func _draw_for_honor_widget(center: Vector2, radius: float, selected_guard: int, incoming_attack: int, is_parry_flash: bool, is_enemy: bool) -> void:
	# รูปทรงปีก 3 ทิศทางสไตล์ For Honor Stance Widget
	# 0 = LEFT, 1 = RIGHT, 2 = TOP
	var wing_points := [
		# LEFT Wing (ปีกซ้าย)
		[
			Vector2(-0.85, -0.32), Vector2(-0.32, -0.10), Vector2(-0.28, 0.22),
			Vector2(-0.06, 0.52), Vector2(-0.15, 0.72), Vector2(-0.82, 0.18)
		],
		# RIGHT Wing (ปีกขวา)
		[
			Vector2(0.85, -0.32), Vector2(0.32, -0.10), Vector2(0.28, 0.22),
			Vector2(0.06, 0.52), Vector2(0.15, 0.72), Vector2(0.82, 0.18)
		],
		# TOP Wing (ปีกบน)
		[
			Vector2(-0.78, -0.42), Vector2(0.0, -0.92), Vector2(0.78, -0.42),
			Vector2(0.42, -0.26), Vector2(0.0, -0.52), Vector2(-0.42, -0.26)
		],
	]

	for i in 3:
		var pts := PackedVector2Array()
		for p: Vector2 in wing_points[i]:
			pts.append(center + p * radius)

		var is_selected := (i == selected_guard)
		var is_attack_lane := (i == incoming_attack)

		var fill_color := COLOR_STEEL_DARK
		var border_color := COLOR_STEEL_RIM
		var border_width := 1.8

		if is_selected:
			fill_color = COLOR_ACTIVE_GUARD_FILL
			border_color = COLOR_ACTIVE_GUARD_RIM
			border_width = 2.6
		elif is_attack_lane:
			if is_parry_flash:
				var flash_pulse := 0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.05)
				fill_color = Color(COLOR_PARRY_FLASH.r, COLOR_PARRY_FLASH.g, COLOR_PARRY_FLASH.b, flash_pulse)
				border_color = Color.WHITE
				border_width = 3.5
			else:
				var pulse := 0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.024)
				fill_color = Color(COLOR_ATTACK_RED.r, COLOR_ATTACK_RED.g, COLOR_ATTACK_RED.b, pulse * 0.90)
				border_color = COLOR_ATTACK_RIM
				border_width = 2.8

		draw_colored_polygon(pts, fill_color)

		pts.append(pts[0])
		draw_polyline(pts, border_color, border_width, true)

		# วาดเครื่องหมาย Chevron ชี้ทิศทางด้านใน
		_draw_stance_chevron(center, radius, i, is_selected, is_attack_lane, is_parry_flash)

	# วงกลมแกนกลางสไตล์ For Honor
	var center_color := Color(0.03, 0.05, 0.08, 0.75) if not is_enemy else Color(0.12, 0.03, 0.04, 0.75)
	draw_circle(center, radius * 0.18, center_color)
	draw_arc(center, radius * 0.19, 0, TAU, 28, COLOR_STEEL_RIM, 1.5, true)
	draw_circle(center, 2.0, Color(0.9, 0.95, 1.0, 0.9))


func _draw_stance_chevron(center: Vector2, radius: float, dir_idx: int, selected: bool, attacking: bool, parry_flash: bool) -> void:
	var chevron_col := Color(0.55, 0.62, 0.72, 0.55)
	if selected:
		chevron_col = Color(1.0, 1.0, 1.0, 0.98)
	elif attacking:
		chevron_col = Color.WHITE if parry_flash else Color(1.9, 0.6, 0.3, 1.0)

	var icon_pos := center
	match dir_idx:
		0:  # LEFT
			icon_pos += Vector2(-radius * 0.48, 0.08 * radius)
			_draw_arrow(icon_pos, Vector2(-1, 0), radius * 0.16, chevron_col)
		1:  # RIGHT
			icon_pos += Vector2(radius * 0.48, 0.08 * radius)
			_draw_arrow(icon_pos, Vector2(1, 0), radius * 0.16, chevron_col)
		2:  # TOP
			icon_pos += Vector2(0, -radius * 0.52)
			_draw_arrow(icon_pos, Vector2(0, -1), radius * 0.16, chevron_col)


func _draw_arrow(pos: Vector2, dir: Vector2, size: float, color: Color) -> void:
	var perp := Vector2(-dir.y, dir.x)
	var tip := pos + dir * size
	var left := pos - dir * (size * 0.5) + perp * (size * 0.8)
	var right := pos - dir * (size * 0.5) - perp * (size * 0.8)

	var pts := PackedVector2Array([tip, left, right])
	draw_colored_polygon(pts, color)


## วาดหลอดเลือดและชื่อศัตรูเหนือหัว สไตล์ For Honor (Overhead Lock-On Bar)
func _draw_enemy_overhead_hud(camera: Camera3D, enemy_char: FighterController) -> void:
	var head_pos := enemy_char.global_position + Vector3(0, 1.85, 0)
	if camera.is_position_behind(head_pos):
		return

	var screen_pos := camera.unproject_position(head_pos)
	var bar_w := 140.0
	var bar_h := 8.0
	var bar_x := screen_pos.x - bar_w * 0.5
	var bar_y := screen_pos.y

	# 1. ป้ายสัญลักษณ์ Faction Shield / Crest เล็ก ๆ
	var crest_center := Vector2(screen_pos.x - bar_w * 0.5 - 14.0, bar_y + 2.0)
	var crest_pts := PackedVector2Array([
		crest_center + Vector2(0, -8),
		crest_center + Vector2(7, -3),
		crest_center + Vector2(5, 7),
		crest_center + Vector2(0, 10),
		crest_center + Vector2(-5, 7),
		crest_center + Vector2(-7, -3),
	])
	draw_colored_polygon(crest_pts, Color(0.85, 0.18, 0.15, 0.95))
	crest_pts.append(crest_pts[0])
	draw_polyline(crest_pts, Color(1.0, 0.85, 0.4), 1.4, true)

	# 2. ชื่อศัตรู (เช่น Raider / Black Pawn)
	var font := get_theme_default_font()
	var font_sz := 14
	var enemy_title: String = enemy_char.fighter_name.to_upper()
	draw_string_outline(font, Vector2(bar_x, bar_y - 6), enemy_title, HORIZONTAL_ALIGNMENT_LEFT, int(bar_w), font_sz, 3, Color(0.01, 0.02, 0.04, 0.95))
	draw_string(font, Vector2(bar_x, bar_y - 6), enemy_title, HORIZONTAL_ALIGNMENT_LEFT, int(bar_w), font_sz, Color(1.0, 0.35, 0.3))

	# 3. กรอบและพื้นหลังหลอดเลือด
	var bg_rect := Rect2(bar_x, bar_y, bar_w, bar_h)
	draw_rect(bg_rect, Color(0.06, 0.08, 0.12, 0.85), true)
	draw_rect(bg_rect, Color(0.45, 0.52, 0.62, 0.85), false, 1.2)

	# 4. เนื้อหลอด HP ศัตรู (สีเขียว/แดงแบ่งช่องตามแบบ For Honor)
	var hp_ratio := clampf(enemy_char.hp / maxf(enemy_char.max_hp, 1.0), 0.0, 1.0)
	var fill_w := bar_w * hp_ratio
	if fill_w > 0.0:
		var hp_col := Color(0.25, 0.82, 0.45).lerp(Color(0.88, 0.22, 0.18), 1.0 - hp_ratio)
		draw_rect(Rect2(bar_x + 1, bar_y + 1, fill_w - 2, bar_h - 2), hp_col, true)

	# เส้นขีดแบ่งช่องหลอดเลือด (Segments)
	for seg in range(1, 4):
		var seg_x := bar_x + (bar_w / 4.0) * seg
		draw_line(Vector2(seg_x, bar_y), Vector2(seg_x, bar_y + bar_h), Color(0.05, 0.07, 0.1, 0.7), 1.0)

	# 5. หลอด Posture/Stamina ศัตรู ขนาดเล็กใต้หลอด HP
	var pos_h := 3.0
	var pos_y := bar_y + bar_h + 3.0
	draw_rect(Rect2(bar_x, pos_y, bar_w, pos_h), Color(0.06, 0.08, 0.12, 0.75), true)
	var posture_ratio := clampf(enemy_char.posture / maxf(enemy_char.max_posture, 1.0), 0.0, 1.0)
	if posture_ratio > 0.0:
		draw_rect(Rect2(bar_x, pos_y, bar_w * posture_ratio, pos_h), Color(0.95, 0.78, 0.25), true)


func _draw_lockon_ground(camera: Camera3D, enemy_pos: Vector3) -> void:
	var floor_pos := enemy_pos + Vector3(0, 0.03, 0)
	if camera.is_position_behind(floor_pos):
		return

	var segments := 36
	var r := 1.15
	var screen_pts := PackedVector2Array()

	for i in range(segments + 1):
		var ang := float(i) * TAU / float(segments)
		var world_pt := floor_pos + Vector3(cos(ang) * r, 0, sin(ang) * r)
		if camera.is_position_behind(world_pt):
			return
		screen_pts.append(camera.unproject_position(world_pt))

	var ring_col := Color(0.85, 0.92, 1.0, 0.55)
	draw_polyline(screen_pts, ring_col, 1.8, true)

	for b_ang in [0.25 * PI, 0.75 * PI, 1.25 * PI, 1.75 * PI]:
		var b_pt := floor_pos + Vector3(cos(b_ang) * r, 0, sin(b_ang) * r)
		var b_scr := camera.unproject_position(b_pt)
		draw_circle(b_scr, 2.5, Color(1.0, 0.9, 0.5, 0.85))


func _draw_outlined_text(pos: Vector2, text: String, font_size: int, color: Color) -> void:
	var font := get_theme_default_font()
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var draw_pos := pos - Vector2(sz.x * 0.5, 0)

	draw_string_outline(font, draw_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, 3, Color(0.01, 0.02, 0.04, 0.95))
	draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)
