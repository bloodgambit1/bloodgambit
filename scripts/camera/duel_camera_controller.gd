class_name DuelCameraController
extends Camera3D
## Step 3: กล้องข้ามไหล่สำหรับฉากดวล (For Honor Over-The-Shoulder Camera)
## ลอยอยู่หลังไหล่ขวาของผู้เล่นในระยะที่เห็นศัตรูชัดเจน ไม่ถูกตัวละครตัวเองบัง
## - เลื่อนตัวละครเราไปอยู่ทางซ้ายล่างของจอ และโฟกัสศัตรูอยู่กลางจอเต็มตัว
## - รองรับ Scroll Mouse Wheel ซูมเข้า-ออก และปุ่ม V เพื่อสลับไหล่ซ้าย/ขวา

@export var player: Node3D
@export var target: Node3D
## ระยะถอยไปข้างหลังผู้เล่น (สไตล์ For Honor Over-The-Shoulder - เว้นระยะให้เห็นศัตรูชัด)
@export var distance_behind := 3.4
## ระยะเยื้องไปทางขวา (ข้ามไหล่ขวา เพื่อให้ผู้เล่นอยู่ฝั่งซ้ายของจอ และมองเห็นศัตรูตรงกลางเต็มตัว)
@export var shoulder_offset := 1.15
## กล้องสูงระดับเหนือไหล่ มองมุมก้มลงไปยังศัตรูเล็กน้อย
@export var height := 2.05
## จุดที่กล้องมอง: โฟกัสไปที่ศัตรูเป็นหลัก
@export_range(0.0, 1.0) var look_bias := 0.85
@export var look_height := 1.20
## ยิ่งมากกล้องยิ่งตามติด ยิ่งน้อยยิ่งหน่วงนุ่ม
@export var follow_speed := 9.0

var trauma := 0.0
var max_shake_offset := Vector3(0.25, 0.25, 0.15)
var max_shake_rot := Vector3(1.5, 1.5, 3.5)


## เรียกเพื่อให้กล้องสั่นสะเทือนตามระดับ trauma (0.0 - 1.0)
func shake(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


func _ready() -> void:
	fov = 68.0
	if player == null or target == null:
		push_warning("DuelCameraController: ยังไม่ได้ใส่ Player หรือ Target ใน Inspector")
		return
	snap_to_target()


func _unhandled_input(event: InputEvent) -> void:
	if not current:
		return
	# ซูมเข้า/ออกด้วย Mouse Wheel
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance_behind = clampf(distance_behind - 0.25, 2.2, 5.5)
			height = clampf(height - 0.12, 1.5, 3.2)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance_behind = clampf(distance_behind + 0.25, 2.2, 5.5)
			height = clampf(height + 0.12, 1.5, 3.2)
	# ปุ่ม V สลับมุมมองไหล่ซ้าย/ขวา
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_V:
			shoulder_offset = -shoulder_offset


## วางกล้องที่ตำแหน่งข้ามไหล่ทันที ไม่ค่อย ๆ ตาม (ใช้ตอนเริ่มดวลหรือหลังย้ายตัวละคร)
func snap_to_target() -> void:
	global_position = _desired_position()
	_look_at_focus()
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if player == null or target == null:
		return
	global_position = global_position.lerp(_desired_position(), clampf(follow_speed * delta, 0.0, 1.0))
	_look_at_focus()

	# คำนวณแรงสั่นสะเทือน (Trauma Shake)
	if trauma > 0.0:
		trauma = maxf(trauma - delta * 3.5, 0.0)
		var shake_pwr := trauma * trauma
		var offset := Vector3(
			randf_range(-1.0, 1.0) * max_shake_offset.x * shake_pwr,
			randf_range(-1.0, 1.0) * max_shake_offset.y * shake_pwr,
			randf_range(-1.0, 1.0) * max_shake_offset.z * shake_pwr
		)
		global_position += offset
		rotation_degrees.z += randf_range(-1.0, 1.0) * max_shake_rot.z * shake_pwr



func _desired_position() -> Vector3:
	var forward := target.global_position - player.global_position
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = -player.global_basis.z
	forward = forward.normalized()
	var right := forward.cross(Vector3.UP)
	return player.global_position - forward * distance_behind + right * shoulder_offset + Vector3.UP * height


func _look_at_focus() -> void:
	var focus := player.global_position.lerp(target.global_position, look_bias) + Vector3.UP * look_height
	look_at(focus)
