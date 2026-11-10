@tool
class_name TouchJoystick
extends Control
## Step 6: จอยสติ๊กเสมือนฝั่งซ้ายจอ (Virtual Joystick) ใช้แทน WASD
## (ชื่อคลาสไม่ใช้ VirtualJoystick เพราะ Godot 4.7 มีโหนดในตัวชื่อนี้อยู่แล้ว)
## แบบลอยตามนิ้ว: แตะตรงไหนในกรอบของโหนดนี้ ฐานจอยจะย้ายไปอยู่ใต้นิ้วตรงนั้น แล้วลากเพื่อเดิน
## รองรับหลายนิ้ว: จำนิ้วที่แตะก่อน (index) ไว้ นิ้วอื่นไปกดปุ่มอื่นได้พร้อมกัน

signal value_changed(value: Vector2)

## รัศมีวงฐาน (พิกเซล) ลากถึงขอบ = เดินเต็มสปีด
@export var radius := 110.0
## ลากน้อยกว่าสัดส่วนนี้ถือว่ายังไม่เดิน (กันนิ้วสั่น)
@export_range(0.0, 0.9) var deadzone := 0.15
## false = ฐานจอยอยู่กับที่ (มุมซ้ายล่างของกรอบ)
@export var floating := true
@export var base_color := Color(1, 1, 1, 0.15)
@export var outline_color := Color(1, 1, 1, 0.4)
@export var knob_color := Color(1, 1, 1, 0.5)
@export var active_knob_color := Color(0.4, 0.8, 1.0, 0.8)

## ค่าที่ส่งออก: x = ขวา(+)/ซ้าย(-), y = เดินหน้า(+)/ถอยหลัง(-) (แบบเดียวกับ WASD)
var output := Vector2.ZERO

var _finger := -1
var _base := Vector2.ZERO
var _knob := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_reset_base)
	_reset_base()


func _gui_input(event: InputEvent) -> void:
	# รับเฉพาะ "การแตะ" (บน PC จะได้จากการคลิกเมาส์ที่ Godot จำลองให้) ไม่สนอีเวนต์เมาส์ กันคำสั่งเบิ้ล
	if event is InputEventScreenTouch:
		if event.pressed and _finger == -1:
			_finger = event.index
			if floating:
				_base = _clamp_inside(event.position)
			_move_knob(event.position)
			accept_event()
		elif not event.pressed and event.index == _finger:
			release()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _finger:
		_move_knob(event.position)
		accept_event()


## ปล่อยจอย (เรียกเองได้ตอนซ่อน UI)
func release() -> void:
	_finger = -1
	_reset_base()
	_set_output(Vector2.ZERO)


func _move_knob(touch_position: Vector2) -> void:
	var offset := (touch_position - _base).limit_length(radius)
	_knob = _base + offset

	var strength := offset.length() / radius
	var value := Vector2.ZERO
	if strength > deadzone:
		value = offset.normalized() * inverse_lerp(deadzone, 1.0, strength)
	# จอ: y บวก = ลง แต่เกม: y บวก = เดินหน้า จึงต้องกลับแกน
	_set_output(Vector2(value.x, -value.y))
	queue_redraw()


func _set_output(value: Vector2) -> void:
	if value != output:
		output = value
		value_changed.emit(value)


func _reset_base() -> void:
	_base = _clamp_inside(Vector2(radius + 60.0, size.y - radius - 60.0))
	_knob = _base
	queue_redraw()


func _clamp_inside(point: Vector2) -> Vector2:
	return Vector2(
		clampf(point.x, radius, maxf(radius, size.x - radius)),
		clampf(point.y, radius, maxf(radius, size.y - radius)))


func _draw() -> void:
	draw_circle(_base, radius, base_color)
	draw_arc(_base, radius, 0.0, TAU, 48, outline_color, 3.0, true)
	draw_circle(_knob, radius * 0.42, active_knob_color if _finger != -1 else knob_color)
