class_name MainMenu
extends Control
## Blood Gambit - Main Menu Controller
## หน้าเมนูหลัก: โหมด Standard, Ranked, PvE Gauntlet, ตั้งค่ากราฟฟิก & เสียง, คู่มือการเล่น

var _main_panel: PanelContainer
var _modal_overlay: ColorRect
var _modal_container: PanelContainer

enum ModalType { NONE, STANDARD_SETUP, RANKED_QUEUE, PVE_SETUP, SETTINGS, CODEX }
var _current_modal := ModalType.NONE

var graphics_preset := 2
var bloom_enabled := true
var shadows_enabled := true
var selected_pve_skill := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_layout()
	_build_modal_layer()


func _build_layout() -> void:
	# 1. พื้นหลังสีดำโกธิก
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.045, 0.07, 1.0)
	add_child(bg)

	# 2. จัดตำแหน่งทุกอย่างไว้ตรงกลางหน้าจอด้วย CenterContainer
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var main_vbox := VBoxContainer.new()
	main_vbox.custom_minimum_size = Vector2(460, 0)
	main_vbox.add_theme_constant_override("separation", 14)
	center.add_child(main_vbox)

	# 3. โลโก้รูปภาพ Blood Gambit
	var logo_rect := TextureRect.new()
	logo_rect.texture = preload("res://art/ui/splash_blood_gambit.png")
	logo_rect.custom_minimum_size = Vector2(380, 160)
	logo_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	main_vbox.add_child(logo_rect)

	# 4. คำโปรย
	var sub_lbl := Label.new()
	sub_lbl.text = "- SOULS OF THE BOARD -"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 14)
	sub_lbl.add_theme_color_override("font_color", Color(0.45, 0.80, 1.0))
	main_vbox.add_child(sub_lbl)

	# 5. แผงปุ่มเมนูหลัก
	_main_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.09, 0.14, 0.92)
	style.border_color = Color(0.35, 0.78, 1.0, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	_main_panel.add_theme_stylebox_override("panel", style)
	main_vbox.add_child(_main_panel)

	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 10)
	_main_panel.add_child(btn_vbox)

	var b1 := _make_menu_btn("STANDARD MATCH (30-40 MIN)", Color(0.3, 0.75, 1.0))
	b1.pressed.connect(_open_modal.bind(ModalType.STANDARD_SETUP))
	btn_vbox.add_child(b1)

	var b2 := _make_menu_btn("RANKED MATCH (COMPETITIVE)", Color(1.0, 0.8, 0.25))
	b2.pressed.connect(_open_modal.bind(ModalType.RANKED_QUEUE))
	btn_vbox.add_child(b2)

	var b3 := _make_menu_btn("PVE GAUNTLET: PAWN'S REBELLION", Color(1.0, 0.35, 0.4))
	b3.pressed.connect(_open_modal.bind(ModalType.PVE_SETUP))
	btn_vbox.add_child(b3)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	btn_vbox.add_child(row)

	var b4 := _make_menu_btn("SETTINGS", Color(0.8, 0.85, 0.95))
	b4.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b4.pressed.connect(_open_modal.bind(ModalType.SETTINGS))
	row.add_child(b4)

	var b5 := _make_menu_btn("HOW TO PLAY", Color(0.8, 0.85, 0.95))
	b5.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b5.pressed.connect(_open_modal.bind(ModalType.CODEX))
	row.add_child(b5)


func _make_menu_btn(btn_text: String, text_col: Color) -> Button:
	var btn := Button.new()
	btn.text = btn_text
	btn.custom_minimum_size = Vector2(0, 42)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 0.8))

	var b_style := StyleBoxFlat.new()
	b_style.bg_color = Color(0.11, 0.14, 0.20, 0.95)
	b_style.border_color = text_col.darkened(0.3)
	b_style.set_border_width_all(1)
	b_style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", b_style)

	var h_style := b_style.duplicate() as StyleBoxFlat
	h_style.bg_color = Color(0.18, 0.24, 0.35, 0.98)
	h_style.border_color = text_col
	btn.add_theme_stylebox_override("hover", h_style)

	var p_style := b_style.duplicate() as StyleBoxFlat
	p_style.bg_color = Color(0.24, 0.30, 0.42, 1.0)
	p_style.border_color = Color.WHITE
	btn.add_theme_stylebox_override("pressed", p_style)

	var f_style := b_style.duplicate() as StyleBoxFlat
	f_style.border_color = text_col
	f_style.set_border_width_all(2)
	btn.add_theme_stylebox_override("focus", f_style)

	return btn


func _build_modal_layer() -> void:
	_modal_overlay = ColorRect.new()
	_modal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_overlay.color = Color(0.02, 0.03, 0.05, 0.85)
	_modal_overlay.visible = false
	add_child(_modal_overlay)

	var modal_center := CenterContainer.new()
	modal_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_overlay.add_child(modal_center)

	_modal_container = PanelContainer.new()
	_modal_container.custom_minimum_size = Vector2(500, 340)
	var m_style := StyleBoxFlat.new()
	m_style.bg_color = Color(0.08, 0.10, 0.15, 0.98)
	m_style.border_color = Color(0.35, 0.78, 1.0, 0.85)
	m_style.set_border_width_all(2)
	m_style.set_corner_radius_all(8)
	m_style.content_margin_left = 24
	m_style.content_margin_right = 24
	m_style.content_margin_top = 20
	m_style.content_margin_bottom = 20
	_modal_container.add_theme_stylebox_override("panel", m_style)
	modal_center.add_child(_modal_container)


func _open_modal(type: ModalType) -> void:
	_current_modal = type
	_modal_overlay.visible = true
	for child in _modal_container.get_children():
		child.queue_free()

	match type:
		ModalType.STANDARD_SETUP:
			_render_standard_modal()
		ModalType.RANKED_QUEUE:
			_render_ranked_modal()
		ModalType.PVE_SETUP:
			_render_pve_modal()
		ModalType.SETTINGS:
			_render_settings_modal()
		ModalType.CODEX:
			_render_codex_modal()


func _close_modal() -> void:
	_current_modal = ModalType.NONE
	_modal_overlay.visible = false


# --- Modal Views ---

func _render_standard_modal() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	_modal_container.add_child(vbox)

	var h := Label.new()
	h.text = "STANDARD MATCH SETUP"
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_font_size_override("font_size", 20)
	h.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
	vbox.add_child(h)

	var desc := Label.new()
	desc.text = "กระดาน 8x8 สมบูรณ์แบบ เลือดหนา ดวลสูสี 60-90 วินาที\nแมตช์ความยาว 30-40 นาที พร้อมระบบพักรบฟื้นฟูเลือด"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	vbox.add_child(desc)

	var diff_label := Label.new()
	diff_label.text = "AI Difficulty: Grandmaster (มาตรฐาน)"
	diff_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(diff_label)

	var faction_label := Label.new()
	faction_label.text = "Faction: White Order (คุณคุมฝ่ายขาว)"
	faction_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(faction_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vbox.add_child(row)

	var cancel_btn := _make_menu_btn("CANCEL", Color(0.8, 0.4, 0.4))
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(_close_modal)
	row.add_child(cancel_btn)

	var start_btn := _make_menu_btn("START MATCH", Color(0.3, 0.9, 0.4))
	start_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	row.add_child(start_btn)


func _render_ranked_modal() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	_modal_container.add_child(vbox)

	var h := Label.new()
	h.text = "RANKED MATCHMAKING"
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_font_size_override("font_size", 20)
	h.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	vbox.add_child(h)

	var rank_badge := Label.new()
	rank_badge.text = "YOUR RANK: GOLD II (1,420 ELO)"
	rank_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_badge.add_theme_font_size_override("font_size", 18)
	rank_badge.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	vbox.add_child(rank_badge)

	var desc := Label.new()
	desc.text = "Rapid Clock: 15 นาทีต่อคน\nชนะ: +25 Elo + กล่องสมบัติ Ranked Chest | แพ้: -18 Elo"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	vbox.add_child(desc)

	var status_text := Label.new()
	status_text.text = "Ready to search for opponent..."
	status_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_text)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vbox.add_child(row)

	var cancel_btn := _make_menu_btn("BACK", Color(0.8, 0.4, 0.4))
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(_close_modal)
	row.add_child(cancel_btn)

	var find_btn := _make_menu_btn("FIND MATCH", Color(1.0, 0.75, 0.2))
	find_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	find_btn.pressed.connect(func():
		status_text.text = "Searching for opponent (Gold Rank)..."
		await get_tree().create_timer(1.5).timeout
		status_text.text = "Match Found! Connecting..."
		await get_tree().create_timer(0.8).timeout
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	row.add_child(find_btn)


func _render_pve_modal() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_modal_container.add_child(vbox)

	var h := Label.new()
	h.text = "PVE GAUNTLET: PAWN'S REBELLION"
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_font_size_override("font_size", 18)
	h.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	vbox.add_child(h)

	var desc := Label.new()
	desc.text = "เดินอิสระ 360 องศา ฟันนัวตะลุมบอนฝ่าฝูงเบี้ยปีศาจจนถึงบอส King!\nเลือกยืม 1 สกิลชั้นสูงมาติดตั้งให้เบี้ยของคุณ:"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	vbox.add_child(desc)

	var skills_box := VBoxContainer.new()
	skills_box.add_theme_constant_override("separation", 6)
	vbox.add_child(skills_box)

	var sk1 := _make_menu_btn("[KNIGHT] Leap Strike (กระโดดข้ามหัวผ่ากลางวง)", Color(0.3, 0.8, 1.0))
	sk1.pressed.connect(func(): selected_pve_skill = 0; _select_skill_feedback(sk1, skills_box))
	skills_box.add_child(sk1)

	var sk2 := _make_menu_btn("[ROOK] Fortress Charge (พุ่งชนรถถังไถแหลก)", Color(0.8, 0.8, 0.8))
	sk2.pressed.connect(func(): selected_pve_skill = 1; _select_skill_feedback(sk2, skills_box))
	skills_box.add_child(sk2)

	var sk3 := _make_menu_btn("[BISHOP] Holy Cross (คลื่นดาบอาคมทแยงมุม)", Color(0.85, 0.6, 1.0))
	sk3.pressed.connect(func(): selected_pve_skill = 2; _select_skill_feedback(sk3, skills_box))
	skills_box.add_child(sk3)

	var sk4 := _make_menu_btn("[QUEEN] Blade Cyclone (พายุหมุน 360 องศา)", Color(1.0, 0.4, 0.6))
	sk4.pressed.connect(func(): selected_pve_skill = 3; _select_skill_feedback(sk4, skills_box))
	skills_box.add_child(sk4)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vbox.add_child(row)

	var cancel_btn := _make_menu_btn("BACK", Color(0.8, 0.4, 0.4))
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(_close_modal)
	row.add_child(cancel_btn)

	var start_btn := _make_menu_btn("ENTER GAUNTLET", Color(0.95, 0.25, 0.3))
	start_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	row.add_child(start_btn)


func _select_skill_feedback(selected: Button, box: VBoxContainer) -> void:
	for b: Button in box.get_children():
		b.text = b.text.replace("> ", "")
	selected.text = "> " + selected.text


func _render_settings_modal() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	_modal_container.add_child(vbox)

	var h := Label.new()
	h.text = "SETTINGS"
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_font_size_override("font_size", 20)
	h.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	vbox.add_child(h)

	var b_bloom := _make_menu_btn("Bloom & Glow: ON", Color(0.35, 0.8, 1.0))
	b_bloom.pressed.connect(func():
		bloom_enabled = not bloom_enabled
		b_bloom.text = "Bloom & Glow: " + ("ON" if bloom_enabled else "OFF")
	)
	vbox.add_child(b_bloom)

	var b_shadow := _make_menu_btn("Shadow Quality: HIGH", Color(0.35, 0.8, 1.0))
	b_shadow.pressed.connect(func():
		shadows_enabled = not shadows_enabled
		b_shadow.text = "Shadow Quality: " + ("HIGH" if shadows_enabled else "OFF")
	)
	vbox.add_child(b_shadow)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var back_btn := _make_menu_btn("SAVE & BACK", Color(0.3, 0.9, 0.4))
	back_btn.pressed.connect(_close_modal)
	vbox.add_child(back_btn)


func _render_codex_modal() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_modal_container.add_child(vbox)

	var h := Label.new()
	h.text = "HOW TO PLAY: CODEX"
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_font_size_override("font_size", 20)
	h.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	vbox.add_child(h)

	var text := Label.new()
	text.text = """1. CHESSBOARD (กระดาน 8x8):
   - คลิกเลือกหมากขาว -> ช่องที่เดินได้จะเป็นสีฟ้า/แดง (กินศัตรู)
   - แต่ละฝ่ายมีเวลา Rapid Clock คนละ 15 นาที
   - หมากที่พักรบ 2 เทิร์นโดยไม่ถูกโจมตี จะฟื้นฟูเลือด +20% HP

2. COMBAT DUEL (ดวลดาบ For Honor OTS):
   - เลื่อนเมาส์หรือปุ่มทัชสกรีนเพื่อเลือกการ์ด 3 ทิศทาง: LEFT / TOP / RIGHT
   - ฟันสวนในทิศทางการ์ดเดียวกันเพื่อ Parry เมื่อเห็นแสงสีขาววาบ ([PARRY NOW!])
   - หลบหลีกด้วย Spacebar / ปุ่ม Dodge
   - สลับมุมกล้องด้วยปุ่ม V หรือเลื่อน Mouse Wheel เพื่อซูมกล้อง"""
	text.add_theme_font_size_override("font_size", 12)
	text.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	vbox.add_child(text)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var back_btn := _make_menu_btn("CLOSE", Color(0.8, 0.8, 0.9))
	back_btn.pressed.connect(_close_modal)
	vbox.add_child(back_btn)
