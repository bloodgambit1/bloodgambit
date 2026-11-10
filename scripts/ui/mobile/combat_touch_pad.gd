@tool
class_name CombatTouchPad
extends Control
## Step 6: แผ่นสัมผัสต่อสู้ฝั่งขวาจอ (Smart Directional Combat Pad)
##   ปัดเร็ว ๆ ไป ซ้าย / ขวา / บน  = หันการ์ดไปทางนั้น + Light Attack
##   แตะค้างก่อน แล้วปัด           = Heavy Attack (ระหว่างง้างกดปุ่ม Parry = Feint ยกเลิกท่า)
##   ลากไปแล้วค้างนิ้วไว้           = เปลี่ยนการ์ดอย่างเดียว ไม่ฟัน (ใช้ตั้งรับ Block)
##   แตะตรงกลาง 1 ที               = Guard Break

signal guard_requested(direction: CombatInputController.GuardDirection)
signal light_attack_requested(direction: CombatInputController.GuardDirection)
signal heavy_attack_requested(direction: CombatInputController.GuardDirection)
signal guard_break_requested

## ต้องลากไกลเท่านี้ (พิกเซล) ถึงนับว่าปัด
@export var swipe_threshold := 45.0
## แตะค้างนานเท่านี้ก่อนเริ่มปัด = Heavy
@export var hold_time := 0.25
## ปัดแล้วปล่อยนิ้วภายในเวลานี้ = โจมตี (ถ้าค้างนิ้วไว้นานกว่านี้ = แค่ตั้งการ์ด)
@export var flick_time := 0.25
## แตะแล้วปล่อยเร็วกว่านี้ โดยไม่ลาก = Guard Break
@export var tap_time := 0.2
@export var pad_color := Color(1, 1, 1, 0.12)
@export var outline_color := Color(1, 1, 1, 0.4)
@export var highlight_color := Color(1.0, 0.85, 0.3, 0.6)
@export var heavy_color := Color(1.0, 0.35, 0.2, 0.8)

var _finger := -1
var _start_position := Vector2.ZERO
var _start_time := 0.0
var _direction := CombatInputController.NO_DIRECTION
var _direction_time := 0.0
var _is_heavy := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(_delta: float) -> void:
	if _finger != -1:
		queue_redraw()  # วาดวงชาร์จ Heavy ระหว่างแตะค้าง


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _finger == -1:
			if event.position.distance_to(_center()) > _radius():
				return  # แตะนอกวงกลม
			_finger = event.index
			_start_position = event.position
			_start_time = _now()
			_direction = CombatInputController.NO_DIRECTION
			_is_heavy = false
			accept_event()
		elif not event.pressed and event.index == _finger:
			_on_release(event.position)
			accept_event()
	elif event is InputEventScreenDrag and event.index == _finger:
		_on_drag(event.position)
		accept_event()


## ยกเลิกท่าที่ค้างอยู่ (เรียกตอนซ่อน UI)
func cancel() -> void:
	_finger = -1
	_direction = CombatInputController.NO_DIRECTION
	queue_redraw()


func _on_drag(touch_position: Vector2) -> void:
	var offset := touch_position - _start_position
	if offset.length() < swipe_threshold:
		return
	var direction := CombatInputController.direction_from_vector(offset)
	if direction == CombatInputController.NO_DIRECTION or direction == _direction:
		return

	if _direction == CombatInputController.NO_DIRECTION:
		_is_heavy = _now() - _start_time >= hold_time
	_direction = direction
	_direction_time = _now()
	guard_requested.emit(direction)
	queue_redraw()


func _on_release(touch_position: Vector2) -> void:
	_on_drag(touch_position)  # เผื่อปัดเร็วมากจนไม่มีอีเวนต์ลากเข้ามาเลย
	var now := _now()

	if _direction == CombatInputController.NO_DIRECTION:
		var is_tap := now - _start_time <= tap_time and touch_position.distance_to(_start_position) < swipe_threshold
		if is_tap:
			guard_break_requested.emit()
	elif now - _direction_time <= flick_time:
		if _is_heavy:
			heavy_attack_requested.emit(_direction)
		else:
			light_attack_requested.emit(_direction)

	cancel()


func _center() -> Vector2:
	return size * 0.5


func _radius() -> float:
	return minf(size.x, size.y) * 0.5 - 4.0


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _draw() -> void:
	var center := _center()
	var radius := _radius()
	draw_circle(center, radius, pad_color)
	draw_arc(center, radius, 0.0, TAU, 64, outline_color, 3.0, true)
	draw_arc(center, radius * 0.3, 0.0, TAU, 32, outline_color, 2.0, true)

	# ไฮไลต์ทิศที่กำลังเลือก (บน = -90 องศา, ซ้าย = 180, ขวา = 0)
	if _direction != CombatInputController.NO_DIRECTION:
		var angle: float = {
			CombatInputController.GuardDirection.LEFT: PI,
			CombatInputController.GuardDirection.RIGHT: 0.0,
			CombatInputController.GuardDirection.TOP: -PI * 0.5,
		}[_direction]
		draw_arc(center, radius - 10.0, angle - 0.6, angle + 0.6, 24,
			heavy_color if _is_heavy else highlight_color, 18.0, true)
	elif _finger != -1 and _now() - _start_time >= hold_time:
		draw_arc(center, radius - 10.0, 0.0, TAU, 64, heavy_color, 6.0, true)

	var font := get_theme_default_font()
	var font_size := 20
	var labels := {"L": Vector2(-0.72, 0.0), "R": Vector2(0.72, 0.0), "TOP": Vector2(0.0, -0.72), "GB": Vector2.ZERO}
	for text: String in labels:
		var offset: Vector2 = labels[text] * radius
		draw_string(font, center + offset + Vector2(-40.0, font_size * 0.35), text,
			HORIZONTAL_ALIGNMENT_CENTER, 80.0, font_size, Color(1, 1, 1, 0.8))
