class_name MobileControls
extends CanvasLayer
## Step 6: ราก (root) ของ UI มือถือ (scenes/ui/mobile_controls.tscn)
## รวมสัญญาณจากจอยสติ๊ก แผ่นต่อสู้ และปุ่มต่าง ๆ แล้วส่งต่อให้ CombatInputController
## และอัปเดตชื่อ/Cooldown บนปุ่มสกิลตามหมากที่กำลังดวลอยู่

signal guard_requested(direction: CombatInputController.GuardDirection)
signal light_attack_requested(direction: CombatInputController.GuardDirection)
signal heavy_attack_requested(direction: CombatInputController.GuardDirection)
signal guard_break_requested
signal dodge_requested
signal parry_requested
signal skill_requested(slot: int)

## ตัวละครของผู้เล่น (ใช้อ่านชื่อสกิลและ Cooldown มาแสดงบนปุ่ม)
@export var player: FighterController

@onready var joystick: TouchJoystick = %MoveJoystick
@onready var combat_pad: CombatTouchPad = %CombatPad
@onready var dodge_button: TouchActionButton = %DodgeButton
@onready var parry_button: TouchActionButton = %ParryButton
@onready var skill_buttons: Array[TouchActionButton] = [%Skill1Button, %Skill2Button, %Skill3Button]


func _ready() -> void:
	combat_pad.guard_requested.connect(guard_requested.emit)
	combat_pad.light_attack_requested.connect(light_attack_requested.emit)
	combat_pad.heavy_attack_requested.connect(heavy_attack_requested.emit)
	combat_pad.guard_break_requested.connect(guard_break_requested.emit)
	dodge_button.pressed.connect(dodge_requested.emit)
	parry_button.pressed.connect(parry_requested.emit)
	for slot in skill_buttons.size():
		skill_buttons[slot].pressed.connect(skill_requested.emit.bind(slot))


func _process(_delta: float) -> void:
	if visible:
		_update_skill_buttons()


## ค่าจากจอยสติ๊ก (x = ขวา, y = เดินหน้า)
func get_move_vector() -> Vector2:
	return joystick.output if visible else Vector2.ZERO


## แสดง/ซ่อน UI ทั้งหมด (ซ่อนแล้วปล่อยนิ้วที่ค้างอยู่ให้ด้วย)
func set_active(active: bool) -> void:
	visible = active
	if not active and is_node_ready():
		joystick.release()
		combat_pad.cancel()


func _update_skill_buttons() -> void:
	var skills: FighterSkills = player.skills if player != null else null
	for slot in skill_buttons.size():
		var button := skill_buttons[slot]
		var has_skill := skills != null and slot < skills.skills.size()
		button.visible = has_skill
		if not has_skill:
			continue
		var remaining := skills.cooldowns.get_remaining(slot)
		button.text = skills.skills[slot].display_name.split(" ")[0]
		button.cooldown_progress = skills.cooldowns.get_progress(slot)
		button.cooldown_text = "" if remaining <= 0.0 else "%.0f" % ceilf(remaining)
