class_name FighterDebugHUD
extends CanvasLayer
## UI ตอนต่อสู้: แสดงหลอดเลือด/สเตมินา/โพสเจอร์ที่มุมซ้ายล่าง และคู่มือการเล่นที่ด้านขวาจอ

const SKILL_KEYS := ["R", "F", "C"]

@export var player: FighterController
@export var enemy: FighterController

# Player HUD (ซ้ายล่าง)
var _player_panel: PanelContainer
var _player_name_label: Label
var _player_state_label: Label
var _player_hp_bar: ProgressBar
var _player_hp_text: Label
var _player_stamina_bar: ProgressBar
var _player_stamina_text: Label
var _player_posture_bar: ProgressBar
var _player_posture_text: Label
var _player_skills_box: HBoxContainer
var _player_skill_slots: Array[PanelContainer] = []

# Enemy HUD (บนกลาง)
var _enemy_panel: PanelContainer
var _enemy_name_label: Label
var _enemy_state_label: Label
var _enemy_hp_bar: ProgressBar
var _enemy_hp_text: Label
var _enemy_posture_bar: ProgressBar

# Combat Guide (คู่มือด้านขวา)
var _guide_panel: PanelContainer
var _guide_visible := true
var _toggle_btn: Button


func _ready() -> void:
	# เข็มทิศบอกทิศการ์ดเดิม (Guard Indicator)
	var indicator := preload("res://scripts/ui/guard_indicator.gd").new()
	indicator.player = player
	indicator.enemy = enemy
	add_child(indicator)

	# สร้าง UI ทั้งหมด
	_build_player_hud()
	_build_enemy_hud()
	_build_combat_guide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_H:
			_toggle_guide()


# ---------------------------------------------------------------- สร้าง UI ซ้ายล่าง (Player HUD)

func _build_player_hud() -> void:
	_player_panel = PanelContainer.new()
	_player_panel.name = "PlayerHUD"
	_player_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.05, 0.07, 0.11, 0.88), Color(0.85, 0.72, 0.25, 0.75)))
	add_child(_player_panel)

	# ล็อกตำแหน่งที่มุมซ้ายล่าง
	_player_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_player_panel.position = Vector2(24, -24)
	_player_panel.custom_minimum_size = Vector2(340, 0)
	_player_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_player_panel.add_child(vbox)

	# แถวบน: ชื่อตัวละคร + สถานะ
	var top_row := HBoxContainer.new()
	vbox.add_child(top_row)

	_player_name_label = Label.new()
	_player_name_label.text = "PLAYER"
	_player_name_label.add_theme_font_size_override("font_size", 16)
	_player_name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	top_row.add_child(_player_name_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	_player_state_label = Label.new()
	_player_state_label.text = "IDLE"
	_player_state_label.add_theme_font_size_override("font_size", 13)
	top_row.add_child(_player_state_label)

	# หลอด HP (เลือด) สีแดงเลือดหมู
	var hp_data := _create_bar_container("HP", Color(0.9, 0.2, 0.25))
	_player_hp_bar = hp_data["bar"]
	_player_hp_text = hp_data["text"]
	_style_bar(_player_hp_bar, Color(0.85, 0.18, 0.22), Color(0.25, 0.05, 0.06, 0.8))
	vbox.add_child(hp_data["root"])

	# หลอด Stamina สีเขียวมรกต
	var sta_data := _create_bar_container("STAMINA", Color(0.3, 0.85, 0.45))
	_player_stamina_bar = sta_data["bar"]
	_player_stamina_text = sta_data["text"]
	_style_bar(_player_stamina_bar, Color(0.2, 0.82, 0.45), Color(0.06, 0.2, 0.1, 0.8))
	vbox.add_child(sta_data["root"])

	# หลอด Posture สีทองอำพัน
	var pos_data := _create_bar_container("POSTURE", Color(0.95, 0.75, 0.2))
	_player_posture_bar = pos_data["bar"]
	_player_posture_text = pos_data["text"]
	_style_bar(_player_posture_bar, Color(0.95, 0.72, 0.18), Color(0.25, 0.18, 0.05, 0.8))
	vbox.add_child(pos_data["root"])

	# ช่องแสดงสกิล R / F / C
	_player_skills_box = HBoxContainer.new()
	_player_skills_box.add_theme_constant_override("separation", 6)
	vbox.add_child(_player_skills_box)

	for i in 3:
		var slot_panel := PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(100, 32)
		slot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.1, 0.13, 0.18, 0.9), Color(0.3, 0.35, 0.45, 0.6), 4))

		var slot_lbl := Label.new()
		slot_lbl.name = "Label"
		slot_lbl.text = "[%s] --" % SKILL_KEYS[i]
		slot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_lbl.add_theme_font_size_override("font_size", 12)
		slot_panel.add_child(slot_lbl)

		_player_skills_box.add_child(slot_panel)
		_player_skill_slots.append(slot_panel)


# ---------------------------------------------------------------- สร้าง UI บนกลาง (Enemy Boss HUD)

func _build_enemy_hud() -> void:
	_enemy_panel = PanelContainer.new()
	_enemy_panel.name = "EnemyHUD"
	_enemy_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.06, 0.05, 0.08, 0.85), Color(0.65, 0.3, 0.85, 0.6)))
	add_child(_enemy_panel)

	_enemy_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_enemy_panel.position = Vector2(0, 16)
	_enemy_panel.custom_minimum_size = Vector2(420, 0)
	_enemy_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_enemy_panel.add_child(vbox)

	var top_row := HBoxContainer.new()
	vbox.add_child(top_row)

	_enemy_name_label = Label.new()
	_enemy_name_label.text = "ENEMY"
	_enemy_name_label.add_theme_font_size_override("font_size", 14)
	_enemy_name_label.add_theme_color_override("font_color", Color(0.9, 0.65, 1.0))
	top_row.add_child(_enemy_name_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	_enemy_state_label = Label.new()
	_enemy_state_label.text = "IDLE"
	_enemy_state_label.add_theme_font_size_override("font_size", 12)
	top_row.add_child(_enemy_state_label)

	# หลอด HP ศัตรู
	var hp_data := _create_bar_container("ENEMY HP", Color(0.85, 0.3, 0.4))
	_enemy_hp_bar = hp_data["bar"]
	_enemy_hp_text = hp_data["text"]
	_style_bar(_enemy_hp_bar, Color(0.8, 0.2, 0.35), Color(0.2, 0.05, 0.08, 0.8))
	vbox.add_child(hp_data["root"])

	# หลอด Posture ศัตรู
	var pos_data := _create_bar_container("POSTURE", Color(0.9, 0.7, 0.3))
	_enemy_posture_bar = pos_data["bar"]
	_style_bar(_enemy_posture_bar, Color(0.9, 0.65, 0.2), Color(0.2, 0.15, 0.05, 0.8))
	vbox.add_child(pos_data["root"])


# ---------------------------------------------------------------- สร้างคู่มือการเล่นด้านขวา (Combat Guide)

func _build_combat_guide() -> void:
	_guide_panel = PanelContainer.new()
	_guide_panel.name = "CombatGuidePanel"
	_guide_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.06, 0.09, 0.9), Color(0.7, 0.6, 0.35, 0.85), 8))
	add_child(_guide_panel)

	# ตรึงขอบขวากลางจอ
	_guide_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_guide_panel.position = Vector2(-20, 0)
	_guide_panel.custom_minimum_size = Vector2(270, 0)
	_guide_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_guide_panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_guide_panel.add_child(vbox)

	# หัวข้อคู่มือ
	var header := Label.new()
	header.text = "⚔️ คู่มือการต่อสู้ (COMBAT)"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	vbox.add_child(header)

	var sep1 := HSeparator.new()
	vbox.add_child(sep1)

	# หมวดปุ่มควบคุม
	var ctrl_title := Label.new()
	ctrl_title.text = "🎮 ปุ่มควบคุม:"
	ctrl_title.add_theme_font_size_override("font_size", 12)
	ctrl_title.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	vbox.add_child(ctrl_title)

	var controls_text := [
		"WASD : เดินรอบทิศทาง",
		"เลื่อนเมาส์ : เลือกทิศการ์ด (ซ้าย/ขวา/บน)",
		"คลิกซ้าย : ฟันธรรมดา (Light)",
		"คลิกค้าง : ง้างฟันหนัก (Heavy)",
		"Q : PARRY ปัดป้อง (ศัตรูชะงัก)",
		"E : FEINT หลอกล่อ ยกเลิกง้าง",
		"Space : กลิ้ง/สไลด์หลบ (I-frames)",
		"R / F / C : กดใช้สกิล 1, 2, 3",
	]
	for line in controls_text:
		var lbl := Label.new()
		lbl.text = "• " + line
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
		vbox.add_child(lbl)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	# หมวดเคล็ดลับการรบ
	var tip_title := Label.new()
	tip_title.text = "💡 เทคนิคการดวล:"
	tip_title.add_theme_font_size_override("font_size", 12)
	tip_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	vbox.add_child(tip_title)

	var tips_text := [
		"• ตั้งการ์ดให้ตรงทิศดาบศัตรูเพื่อ Block",
		"• กด Q ให้ตรงจังหวะดาบเข้าตัวเพื่อ Parry!",
		"• ตีทลาย Posture ให้แตกเพื่อเปิดช่องปลิดชีพ",
	]
	for line in tips_text:
		var lbl := Label.new()
		lbl.text = line
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl)

	# ปุ่ม Toggle ซ่อน/แสดงคู่มือ
	_toggle_btn = Button.new()
	_toggle_btn.text = "ซ่อนคู่มือ (กด H)"
	_toggle_btn.add_theme_font_size_override("font_size", 11)
	_toggle_btn.pressed.connect(_toggle_guide)
	vbox.add_child(_toggle_btn)


func _toggle_guide() -> void:
	_guide_visible = not _guide_visible
	_guide_panel.visible = _guide_visible
	if _toggle_btn != null:
		_toggle_btn.text = "ซ่อนคู่มือ (กด H)" if _guide_visible else "แสดงคู่มือ (กด H)"


# ---------------------------------------------------------------- อัปเดตข้อมูลทุกเฟรม

func _process(_delta: float) -> void:
	_update_player_hud()
	_update_enemy_hud()


func _update_player_hud() -> void:
	if player == null:
		return

	_player_name_label.text = "%s (%s)" % [
		player.fighter_name.to_upper(),
		"WHITE" if player.is_white_faction else "BLACK"
	]
	_player_state_label.text = "[%s]" % player.state_name()
	_player_state_label.modulate = FighterController.STATE_COLORS.get(player.state, Color.WHITE)

	# อัปเดตตัวเลขและหลอด HP
	_player_hp_bar.max_value = player.max_hp
	_player_hp_bar.value = player.hp
	_player_hp_text.text = "%d / %d" % [int(player.hp), int(player.max_hp)]

	# Stamina
	_player_stamina_bar.max_value = player.max_stamina
	_player_stamina_bar.value = player.stamina
	_player_stamina_text.text = "%d / %d" % [int(player.stamina), int(player.max_stamina)]

	# Posture
	_player_posture_bar.max_value = player.max_posture
	_player_posture_bar.value = player.posture
	_player_posture_text.text = "%d / %d" % [int(player.posture), int(player.max_posture)]

	# สกิล
	var skills := player.skills
	for i in 3:
		if i >= _player_skill_slots.size():
			continue
		var slot_panel := _player_skill_slots[i]
		var slot_lbl := slot_panel.get_node("Label") as Label
		if skills != null and i < skills.skills.size():
			var sk := skills.skills[i]
			var cd := skills.cooldowns.get_remaining(i)
			if cd <= 0.0:
				slot_lbl.text = "[%s] %s" % [SKILL_KEYS[i], sk.display_name]
				slot_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
			else:
				slot_lbl.text = "[%s] %.1fs" % [SKILL_KEYS[i], cd]
				slot_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
		else:
			slot_lbl.text = "[%s] --" % SKILL_KEYS[i]
			slot_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))


func _update_enemy_hud() -> void:
	if enemy == null:
		return

	_enemy_name_label.text = "%s (%s)" % [
		enemy.fighter_name.to_upper(),
		"WHITE" if enemy.is_white_faction else "BLACK"
	]
	_enemy_state_label.text = "[%s]" % enemy.state_name()
	_enemy_state_label.modulate = FighterController.STATE_COLORS.get(enemy.state, Color.WHITE)

	_enemy_hp_bar.max_value = enemy.max_hp
	_enemy_hp_bar.value = enemy.hp
	_enemy_hp_text.text = "%d / %d" % [int(enemy.hp), int(enemy.max_hp)]

	_enemy_posture_bar.max_value = enemy.max_posture
	_enemy_posture_bar.value = enemy.posture


# ---------------------------------------------------------------- ตัวช่วยจัดสไตล์ UI

static func _create_bar_container(title: String, title_col: Color) -> Dictionary:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 2)

	var label_row := HBoxContainer.new()
	root.add_child(label_row)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.add_theme_color_override("font_color", title_col)
	label_row.add_child(title_lbl)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_row.add_child(sp)

	var val_lbl := Label.new()
	val_lbl.name = "Text"
	val_lbl.text = "100 / 100"
	val_lbl.add_theme_font_size_override("font_size", 11)
	val_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	label_row.add_child(val_lbl)

	var bar := ProgressBar.new()
	bar.name = "Bar"
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	root.add_child(bar)

	return {"root": root, "bar": bar, "text": val_lbl}


static func _style_bar(bar: ProgressBar, fill_color: Color, bg_color: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = bg_color
	bg.set_corner_radius_all(3)

	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(3)

	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)


static func _make_panel_style(bg_col: Color, border_col: Color, radius: int = 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_col
	style.set_border_width_all(1)
	style.border_color = border_col
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
