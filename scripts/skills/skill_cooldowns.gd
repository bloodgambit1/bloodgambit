class_name SkillCooldowns
extends RefCounted
## ระบบนับ Cooldown แยกต่อช่องสกิล
## แต่ละช่องมีเวลานับถอยหลังของตัวเอง ใช้สกิลช่อง 1 ไม่กระทบช่อง 2
## เริ่มนับทันทีที่กดใช้สกิล แม้สกิลจะโดนขัดกลางทาง

var _remaining: Array[float] = []
var _durations: Array[float] = []


## ล้างทุกช่องให้พร้อมใช้ (เรียกตอนเปลี่ยนชุดสกิล/เริ่มดวลใหม่)
func reset(slot_count: int) -> void:
	_remaining.resize(slot_count)
	_remaining.fill(0.0)
	_durations.resize(slot_count)
	_durations.fill(0.0)


func start(slot: int, duration: float) -> void:
	_remaining[slot] = duration
	_durations[slot] = duration


func tick(delta: float) -> void:
	for slot in _remaining.size():
		_remaining[slot] = maxf(_remaining[slot] - delta, 0.0)


func is_ready(slot: int) -> bool:
	return get_remaining(slot) <= 0.0


func get_remaining(slot: int) -> float:
	if slot < 0 or slot >= _remaining.size():
		return 0.0
	return _remaining[slot]


## 0 = เพิ่งใช้ไป, 1 = พร้อมใช้ (ไว้ทำหลอด/วงกลม Cooldown บน UI)
func get_progress(slot: int) -> float:
	if slot < 0 or slot >= _durations.size() or _durations[slot] <= 0.0:
		return 1.0
	return 1.0 - _remaining[slot] / _durations[slot]
