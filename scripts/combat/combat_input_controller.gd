class_name CombatInputController
extends Node
## Step 1 + 6: ระบบรับคำสั่งต่อสู้ รองรับทั้ง PC (เมาส์ + คีย์บอร์ด) และมือถือ (ทัชสกรีน)
## รวมคำสั่งจากทุกอุปกรณ์ให้เป็นสัญญาณชุดเดียว แล้วให้ FighterController ฟัง
##
## PC:
##   ขยับเมาส์ = เปลี่ยนทิศการ์ด (ซ้าย / ขวา / บน)
##   คลิกซ้าย = LightAttack, คลิกขวา = HeavyAttack, คลิกกลาง หรือ G = Guard Break
##   W/A/S/D = เดิน (เดินหน้า/ซ้าย/ถอย/ขวา รอบตัวศัตรู)
##   E = Feint, Q = Parry (ระหว่างง้าง Heavy = Feint), Space = Dodge (กด 2 ทีติดกัน = กลิ้ง)
##   R = Skill 1, F = Skill 2, C = Skill 3 (เฉพาะ Rook), Esc = ปล่อยเมาส์ออกจากเกม
##
## มือถือ (UI อยู่ใน scenes/ui/mobile_controls.tscn):
##   จอยซ้าย = เดิน, แผ่นต่อสู้ขวา = เปลี่ยนการ์ด/ฟัน/Guard Break, ปุ่มรอบ ๆ = Dodge / Parry / Skill
##
## Auto-detect: เปิดเกมบนมือถือ = แสดง UI มือถือ, บน PC = ซ่อน
##   ระหว่างเล่นถ้าแตะจอจริงจะสลับเป็นมือถือ ถ้าใช้เมาส์/คีย์บอร์ดจริงจะสลับกลับเป็น PC
##   ทดสอบบน PC: กด F1 เพื่อบังคับเปิด UI มือถือ (ใช้คลิก/ลากเมาส์แทนนิ้ว) กด F1 อีกทีเพื่อกลับ

enum GuardDirection { LEFT, RIGHT, TOP }

signal guard_direction_changed(new_direction: GuardDirection)
signal light_attack_requested(direction: GuardDirection)
signal heavy_attack_requested(direction: GuardDirection)
signal guard_break_requested
signal feint_requested
signal parry_requested
signal dodge_requested
## slot: 0 = Skill 1, 1 = Skill 2, 2 = Skill 3
signal skill_requested(slot: int)

## หน่วงเวลาก่อนการ์ดเปลี่ยนทิศจริง ใช้เท่ากันทั้งเมาส์และทัช เพื่อไม่ให้ฝั่งไหนได้เปรียบ
const GUARD_SWITCH_DELAY := 0.1
## ค่าที่ใช้บอกว่า "ไม่มีทิศ" (เช่น ขยับเมาส์ลงล่าง ซึ่งไม่มีการ์ดล่าง)
const NO_DIRECTION := -1
## ชื่อ action ของปุ่มสกิลแต่ละช่อง
const SKILL_ACTIONS := ["skill_1", "skill_2", "skill_3"]

## UI มือถือ (ลากโหนด MobileControls มาใส่)
@export var mobile_controls: MobileControls
## สลับโหมด PC/มือถือเองตามอุปกรณ์ที่ผู้เล่นใช้จริง
@export var auto_detect_device := true
## บังคับเปิด UI มือถือตั้งแต่เริ่มเกม (ทดสอบบน PC) และปิด Auto-detect
@export var force_touch_mode := false
@export var show_debug_text := false

@export_group("Mouse")
## ต้องขยับเมาส์สะสมกี่พิกเซลถึงจะนับว่าเปลี่ยนทิศการ์ด
@export var mouse_guard_threshold := 40.0
## ความเร็วที่การขยับเล็ก ๆ น้อย ๆ จะค่อย ๆ หายไป (กันมือสั่นแล้วการ์ดเปลี่ยนเอง)
@export var mouse_accumulator_decay := 8.0

var current_guard_direction: GuardDirection = GuardDirection.RIGHT
## ปิดไว้ตอนอยู่บนกระดานหมากรุก (ดู set_input_enabled)
var input_enabled := true

var _is_touch_mode := false

var _has_pending_guard := false
var _pending_guard_direction: GuardDirection = GuardDirection.RIGHT
var _guard_switch_timer := 0.0

# การโจมตีจากการปัดจอจะรอให้การ์ดหันไปทิศนั้นก่อน (ดีเลย์เท่ากับฝั่ง PC)
var _has_queued_attack := false
var _queued_attack_is_heavy := false

var _mouse_accumulator := Vector2.ZERO

var _debug_layer: CanvasLayer
var _debug_label: Label
var _last_action := "-"


func _ready() -> void:
	_register_input_actions()
	_create_debug_label()
	_connect_mobile_controls()
	if force_touch_mode:
		auto_detect_device = false
	_set_touch_mode(force_touch_mode or is_touch_device())


## เครื่องนี้เป็นมือถือ/แท็บเล็ตไหม (รวมเกมเว็บที่เปิดบนมือถือ)
static func is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")


## แปลงทิศการขยับ (พิกัดจอ: y บวก = ลง) เป็นทิศการ์ด หรือ NO_DIRECTION ถ้าเป็นทิศลง
static func direction_from_vector(v: Vector2) -> int:
	if absf(v.y) > absf(v.x):
		return GuardDirection.TOP if v.y < 0.0 else NO_DIRECTION
	return GuardDirection.LEFT if v.x < 0.0 else GuardDirection.RIGHT


func _process(delta: float) -> void:
	if _has_pending_guard:
		_guard_switch_timer -= delta
		if _guard_switch_timer <= 0.0:
			_apply_pending_guard()

	_mouse_accumulator = _mouse_accumulator.lerp(Vector2.ZERO, clampf(mouse_accumulator_decay * delta, 0.0, 1.0))


## ทิศที่ผู้เล่นอยากเดิน: x = ขวา(+)/ซ้าย(-), y = หน้า(+)/หลัง(-)
## รวมคีย์บอร์ด/จอยเกม กับจอยสติ๊กบนจอ (ใช้พร้อมกันได้)
func get_move_vector() -> Vector2:
	if not input_enabled:
		return Vector2.ZERO
	var move := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	if mobile_controls != null:
		move += mobile_controls.get_move_vector()
	return move.limit_length(1.0)


## เปิด/ปิดการรับคำสั่งต่อสู้ทั้งหมด พร้อมซ่อน/แสดง UI และปล่อย/จับเมาส์ให้
func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	_has_pending_guard = false
	_has_queued_attack = false
	_apply_mode()


# ---------------------------------------------------------------- PC / Mobile mode

func _set_touch_mode(enabled: bool) -> void:
	_is_touch_mode = enabled
	print("[Combat] Input mode = %s" % ("TOUCH" if enabled else "PC"))
	_apply_mode()


## แสดง UI มือถือเฉพาะตอน "โหมดทัช + กำลังต่อสู้" และจับเมาส์เฉพาะตอน "โหมด PC + กำลังต่อสู้"
func _apply_mode() -> void:
	_mouse_accumulator = Vector2.ZERO
	if mobile_controls != null:
		mobile_controls.set_active(_is_touch_mode and input_enabled)
	if _debug_layer != null:
		_debug_layer.visible = input_enabled and show_debug_text
	var capture := input_enabled and not _is_touch_mode
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if capture else Input.MOUSE_MODE_VISIBLE
	_update_debug_label()


## Auto-detect: ดูว่าผู้เล่นกำลังใช้อุปกรณ์อะไรจริง ๆ
## ข้ามอีเวนต์ที่ Godot จำลองขึ้น (device = -1) เช่น การแตะที่จำลองจากเมาส์ หรือเมาส์ที่จำลองจากนิ้ว
func _input(event: InputEvent) -> void:
	if not auto_detect_device or event.device == InputEvent.DEVICE_ID_EMULATION:
		return

	var wants_touch: bool
	if event is InputEventScreenTouch and event.pressed:
		wants_touch = true
	elif (event is InputEventKey and event.pressed) or event is InputEventMouseButton or event is InputEventMouseMotion:
		wants_touch = false
	else:
		return

	if wants_touch != _is_touch_mode:
		print("[Combat] Auto-detect: ตรวจพบ%s" % ("การแตะจอ" if wants_touch else "เมาส์/คีย์บอร์ด"))
		_set_touch_mode(wants_touch)


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return

	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F1:
		# บังคับเปิด UI มือถือไว้ทดสอบ (ปิด Auto-detect ไม่ให้เมาส์สลับกลับเอง) / กดอีกทีกลับเป็น PC + Auto
		auto_detect_device = _is_touch_mode
		_set_touch_mode(not _is_touch_mode)
		return

	# โหมดทัช: UI มือถือจัดการเองหมดแล้ว
	if not _is_touch_mode:
		_handle_pc_input(event)


# ---------------------------------------------------------------- Guard

func request_guard_direction(direction: GuardDirection) -> void:
	if _has_pending_guard:
		if direction == _pending_guard_direction:
			return
		if direction == current_guard_direction:
			_has_pending_guard = false
			print("[Guard] ยกเลิกการเปลี่ยน กลับมาที่ %s" % _dir_name(direction))
			_update_debug_label()
			return
	elif direction == current_guard_direction:
		return

	# จับเวลาจากคำสั่งแรก ถ้าเปลี่ยนใจระหว่างรอ แค่เปลี่ยนเป้าหมาย ไม่เริ่มนับใหม่
	if not _has_pending_guard:
		_guard_switch_timer = GUARD_SWITCH_DELAY
	_has_pending_guard = true
	_pending_guard_direction = direction
	print("[Guard] ขอเปลี่ยน -> %s (อีก %.2fs)" % [_dir_name(direction), _guard_switch_timer])
	_update_debug_label()


func _apply_pending_guard() -> void:
	_has_pending_guard = false
	current_guard_direction = _pending_guard_direction
	print("[Guard] เปลี่ยนเป็น %s แล้ว" % _dir_name(current_guard_direction))
	guard_direction_changed.emit(current_guard_direction)
	_update_debug_label()

	if _has_queued_attack:
		_has_queued_attack = false
		_perform_attack(_queued_attack_is_heavy)


# ---------------------------------------------------------------- Actions

func _perform_attack(is_heavy: bool) -> void:
	# A click during the guard-switch delay must use the requested side too.
	if _has_pending_guard:
		_has_queued_attack = true
		_queued_attack_is_heavy = is_heavy
		return
	if is_heavy:
		_log_action("HeavyAttack", "ทิศ %s" % _dir_name(current_guard_direction))
		heavy_attack_requested.emit(current_guard_direction)
	else:
		_log_action("LightAttack", "ทิศ %s" % _dir_name(current_guard_direction))
		light_attack_requested.emit(current_guard_direction)


## หันการ์ดไปทิศนั้นก่อน แล้วค่อยโจมตี (ใช้กับการปัดจอ)
func _attack_toward(direction: GuardDirection, is_heavy: bool) -> void:
	request_guard_direction(direction)
	if _has_pending_guard:
		_has_queued_attack = true
		_queued_attack_is_heavy = is_heavy
		print("[Combat] รอการ์ดหันไป %s ก่อนโจมตี" % _dir_name(direction))
	else:
		_perform_attack(is_heavy)


func _do_guard_break() -> void:
	_log_action("Guard Break")
	guard_break_requested.emit()


func _do_feint() -> void:
	_log_action("Feint")
	feint_requested.emit()


func _do_parry() -> void:
	_log_action("Parry")
	parry_requested.emit()


func _do_dodge() -> void:
	_log_action("Dodge")
	dodge_requested.emit()


func _do_skill(slot: int) -> void:
	_log_action("Skill %d" % (slot + 1))
	skill_requested.emit(slot)


# ---------------------------------------------------------------- PC input

func _handle_pc_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		print("[Combat] ปล่อยเมาส์แล้ว (คลิกในจอเกมเพื่อกลับมาเล่น)")
		return

	# ถ้าเมาส์ยังไม่ถูกจับ คลิกแรกใช้แค่จับเมาส์กลับเข้าเกม ไม่นับเป็นการโจมตี
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseButton and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseMotion:
		_mouse_accumulator += event.relative
		if _mouse_accumulator.length() >= mouse_guard_threshold:
			var direction := direction_from_vector(_mouse_accumulator)
			if direction != NO_DIRECTION:
				request_guard_direction(direction)
			_mouse_accumulator = Vector2.ZERO
		return

	if event.is_action_pressed("light_attack"):
		_perform_attack(false)
	elif event.is_action_pressed("heavy_attack"):
		_perform_attack(true)
	elif event.is_action_pressed("guard_break"):
		_do_guard_break()
	elif event.is_action_pressed("feint"):
		_do_feint()
	elif event.is_action_pressed("parry"):
		_do_parry()
	elif event.is_action_pressed("dodge"):
		_do_dodge()
	else:
		for slot in SKILL_ACTIONS.size():
			if event.is_action_pressed(SKILL_ACTIONS[slot]):
				_do_skill(slot)


# ---------------------------------------------------------------- Mobile input

func _connect_mobile_controls() -> void:
	if mobile_controls == null:
		return
	mobile_controls.guard_requested.connect(request_guard_direction)
	mobile_controls.light_attack_requested.connect(_attack_toward.bind(false))
	mobile_controls.heavy_attack_requested.connect(_attack_toward.bind(true))
	mobile_controls.guard_break_requested.connect(_do_guard_break)
	mobile_controls.parry_requested.connect(_do_parry)
	mobile_controls.dodge_requested.connect(_do_dodge)
	mobile_controls.skill_requested.connect(_do_skill)


# ---------------------------------------------------------------- Helpers

func _dir_name(direction: GuardDirection) -> String:
	return GuardDirection.keys()[direction]


func _log_action(action_name: String, detail: String = "") -> void:
	_last_action = action_name if detail.is_empty() else "%s (%s)" % [action_name, detail]
	print("[Combat] %s" % _last_action)
	_update_debug_label()


## ลงทะเบียนปุ่มให้อัตโนมัติ ถ้าตั้งเองใน Project Settings > Input Map แล้ว จะใช้ของที่ตั้งไว้แทน
func _register_input_actions() -> void:
	_add_mouse_action("light_attack", MOUSE_BUTTON_LEFT)
	_add_mouse_action("heavy_attack", MOUSE_BUTTON_RIGHT)
	if _add_key_action("guard_break", KEY_G):
		var middle_click := InputEventMouseButton.new()
		middle_click.button_index = MOUSE_BUTTON_MIDDLE
		InputMap.action_add_event("guard_break", middle_click)
	_add_key_action("feint", KEY_E)
	_add_key_action("parry", KEY_Q)
	_add_key_action("dodge", KEY_SPACE)
	# physical_keycode = ตำแหน่งปุ่มบนคีย์บอร์ด จึงใช้ได้แม้เปิดแป้นภาษาไทยอยู่
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("skill_1", KEY_R)
	_add_key_action("skill_2", KEY_F)
	_add_key_action("skill_3", KEY_C)


## คืนค่า true ถ้าเพิ่งสร้าง action ใหม่ (false = มีอยู่แล้วใน Input Map)
func _add_key_action(action: StringName, key: Key) -> bool:
	if InputMap.has_action(action):
		return false
	InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)
	return true


func _add_mouse_action(action: StringName, button: MouseButton) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event := InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)


# ---------------------------------------------------------------- Debug UI

func _create_debug_label() -> void:
	_debug_layer = CanvasLayer.new()
	add_child(_debug_layer)
	_debug_label = Label.new()
	_debug_label.position = Vector2(16, 16)
	_debug_label.add_theme_font_size_override("font_size", 24)
	_debug_layer.add_child(_debug_label)


func _update_debug_label() -> void:
	if _debug_label == null:
		return
	var guard_text := _dir_name(current_guard_direction)
	if _has_pending_guard:
		guard_text += "  ->  %s" % _dir_name(_pending_guard_direction)
	_debug_label.text = "Mode: %s%s  (F1 = switch)\nGuard: %s\nLast action: %s" % [
		"TOUCH" if _is_touch_mode else "PC",
		" [auto]" if auto_detect_device else "",
		guard_text,
		_last_action,
	]
