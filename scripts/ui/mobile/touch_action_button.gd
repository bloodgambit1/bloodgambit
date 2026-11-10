@tool
class_name TouchActionButton
extends Control
## Step 6: ปุ่มกลมบนจอมือถือ (Dodge / Parry / Skill)
## ต่างจาก Button ปกติของ Godot ตรงที่รับ "การแตะหลายนิ้ว" ได้ เช่น นิ้วซ้ายลากจอยอยู่ แล้วนิ้วขวากดปุ่มนี้
## ทำงานทันทีที่นิ้วแตะ (ไม่รอปล่อย) เพราะ Parry/Dodge ต้องไว

signal pressed

@export var text := "Button":
	set(value):
		text = value
		queue_redraw()
@export var font_size := 20
@export var color := Color(1, 1, 1, 0.2)
@export var pressed_color := Color(1.0, 0.8, 0.3, 0.6)
@export var outline_color := Color(1, 1, 1, 0.45)

## 0 = เพิ่งใช้ (มืดทั้งปุ่ม), 1 = พร้อมใช้
var cooldown_progress := 1.0:
	set(value):
		if not is_equal_approx(value, cooldown_progress):
			cooldown_progress = value
			queue_redraw()
## เลขวินาทีที่เหลือ (ว่าง = พร้อมใช้)
var cooldown_text := "":
	set(value):
		if value != cooldown_text:
			cooldown_text = value
			queue_redraw()

var _finger := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _finger == -1 and event.position.distance_to(size * 0.5) <= _radius():
			_finger = event.index
			pressed.emit()
			queue_redraw()
			accept_event()
		elif not event.pressed and event.index == _finger:
			_finger = -1
			queue_redraw()
			accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_finger = -1


func _radius() -> float:
	return minf(size.x, size.y) * 0.5 - 2.0


func _draw() -> void:
	var center := size * 0.5
	var radius := _radius()
	draw_circle(center, radius, pressed_color if _finger != -1 else color)
	if cooldown_progress < 1.0:
		# ส่วนที่ยังไม่พร้อม: แรเงาเป็นวงกลมเสี้ยวที่หดลงเรื่อย ๆ ตามเวลา
		var sweep := TAU * (1.0 - cooldown_progress)
		draw_arc(center, radius * 0.5, -PI * 0.5, -PI * 0.5 + sweep, 48, Color(0, 0, 0, 0.55), radius, true)
	draw_arc(center, radius, 0.0, TAU, 48, outline_color, 3.0, true)

	var font := get_theme_default_font()
	var text_y := center.y + font_size * 0.35
	if not cooldown_text.is_empty():
		text_y -= font_size * 0.5
		draw_string(font, Vector2(0.0, text_y + font_size * 1.1), cooldown_text,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, Color(1, 0.85, 0.4))
	draw_string(font, Vector2(0.0, text_y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, Color.WHITE)
