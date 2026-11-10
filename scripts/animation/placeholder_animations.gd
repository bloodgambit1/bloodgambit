class_name PlaceholderAnimations
extends RefCounted
## Step 7: สร้างอนิเมชันชั่วคราวให้ตัวแคปซูล (โยก/เอียง/หมุนโหนด "Body") ไว้ทดสอบระบบ
## ก่อนจะมีโมเดลจริงจาก Mixamo พอใส่โมเดลที่มี AnimationPlayer แล้ว FighterAnimator จะไม่ใช้ของพวกนี้อีก

const LIBRARY := "placeholder"

## ชื่อช่องใน FighterAnimator -> ชื่ออนิเมชันชั่วคราว
const DEFAULT_NAMES := {
	"anim_idle": "placeholder/idle",
	"anim_walk_forward": "placeholder/walk_forward",
	"anim_walk_back": "placeholder/walk_back",
	"anim_strafe_left": "placeholder/strafe_left",
	"anim_strafe_right": "placeholder/strafe_right",
	"anim_attack_left": "placeholder/attack_left",
	"anim_attack_right": "placeholder/attack_right",
	"anim_attack_top": "placeholder/attack_top",
	"anim_guard_break": "placeholder/guard_break",
	"anim_skill": "placeholder/skill",
	"anim_hit_react": "placeholder/hit_react",
	"anim_block_impact": "placeholder/block_impact",
	"anim_parry": "placeholder/parry",
	"anim_parry_deflect": "placeholder/parry_deflect",
	"anim_stunned": "placeholder/stunned",
	"anim_death": "placeholder/death",
	"anim_dodge_roll": "placeholder/dodge_roll",
	"anim_dodge_step": "placeholder/dodge_step",
}

const FLIP := 3.1  # เกือบ PI: ใช้ทำท่าหมุนครบรอบโดยจบที่มุม 0 (ไม่หมุนย้อนกลับตอนเปลี่ยนท่า)


## สร้าง AnimationPlayer ใต้ตัวละคร คืนค่า null ถ้าไม่มีโหนด Body ให้ขยับ
static func create(fighter: Node3D) -> AnimationPlayer:
	var body := fighter.get_node_or_null("Body") as Node3D
	if body == null:
		return null
	var rest := body.position
	var library := AnimationLibrary.new()

	var bob := [[0.0, Vector3.ZERO], [0.15, Vector3(0, 0.06, 0)], [0.3, Vector3.ZERO], [0.45, Vector3(0, 0.06, 0)], [0.6, Vector3.ZERO]]
	library.add_animation("idle", _make(1.2, [[0.0, Vector3.ZERO]], [[0.0, Vector3.ZERO], [0.6, Vector3(0, 0.04, 0)], [1.2, Vector3.ZERO]], rest))
	library.add_animation("walk_forward", _make(0.6, [[0.0, Vector3(-0.12, 0, 0)]], bob, rest))
	library.add_animation("walk_back", _make(0.6, [[0.0, Vector3(0.1, 0, 0)]], bob, rest))
	library.add_animation("strafe_left", _make(0.6, [[0.0, Vector3(0, 0, 0.15)]], bob, rest))
	library.add_animation("strafe_right", _make(0.6, [[0.0, Vector3(0, 0, -0.15)]], bob, rest))

	# ท่าฟัน: ง้าง (ถึงวินาที 0.45) -> ฟันออก (0.6) -> คืนท่า (1.0)
	library.add_animation("attack_left", _make(1.0,
		[[0.0, Vector3.ZERO], [0.45, Vector3(0, 0.5, 0.45)], [0.6, Vector3(0, -0.7, -0.6)], [1.0, Vector3.ZERO]], [], rest))
	library.add_animation("attack_right", _make(1.0,
		[[0.0, Vector3.ZERO], [0.45, Vector3(0, -0.5, -0.45)], [0.6, Vector3(0, 0.7, 0.6)], [1.0, Vector3.ZERO]], [], rest))
	library.add_animation("attack_top", _make(1.0,
		[[0.0, Vector3.ZERO], [0.45, Vector3(0.45, 0, 0)], [0.6, Vector3(-0.7, 0, 0)], [1.0, Vector3.ZERO]], [], rest))
	library.add_animation("guard_break", _make(0.6,
		[[0.0, Vector3.ZERO], [0.3, Vector3(-0.5, 0, 0)], [0.6, Vector3.ZERO]],
		[[0.0, Vector3.ZERO], [0.3, Vector3(0, 0, -0.3)], [0.6, Vector3.ZERO]], rest))
	library.add_animation("skill", _make(0.8,
		[[0.0, Vector3.ZERO], [0.399, Vector3(0, -FLIP, 0)], [0.401, Vector3(0, FLIP, 0)], [0.8, Vector3.ZERO]], [], rest))

	# ท่าตอบสนอง
	library.add_animation("hit_react", _make(0.35,
		[[0.0, Vector3.ZERO], [0.08, Vector3(0.5, 0, 0)], [0.35, Vector3.ZERO]],
		[[0.0, Vector3.ZERO], [0.08, Vector3(0, 0, 0.15)], [0.35, Vector3.ZERO]], rest))
	library.add_animation("block_impact", _make(0.25,
		[[0.0, Vector3.ZERO], [0.06, Vector3(0.18, 0, 0)], [0.25, Vector3.ZERO]], [], rest))
	library.add_animation("parry", _make(0.3,
		[[0.0, Vector3.ZERO], [0.1, Vector3(0, -0.6, 0)], [0.3, Vector3.ZERO]], [], rest))
	library.add_animation("parry_deflect", _make(0.35,
		[[0.0, Vector3(0, -0.4, 0)], [0.06, Vector3(-0.35, 0.6, -0.2)], [0.35, Vector3.ZERO]],
		[[0.0, Vector3.ZERO], [0.06, Vector3(0, 0, 0.2)], [0.35, Vector3.ZERO]], rest))
	library.add_animation("stunned", _make(0.8,
		[[0.0, Vector3(0.2, 0, 0)], [0.2, Vector3(0.2, 0, 0.25)], [0.4, Vector3(0.2, 0, 0)], [0.6, Vector3(0.2, 0, -0.25)], [0.8, Vector3(0.2, 0, 0)]], [], rest))
	library.add_animation("death", _make(0.8,
		[[0.0, Vector3.ZERO], [0.6, Vector3(1.4, 0, 0)], [0.8, Vector3(1.4, 0, 0)]],
		[[0.0, Vector3.ZERO], [0.6, Vector3(0, -0.5, 0.4)], [0.8, Vector3(0, -0.5, 0.4)]], rest))

	# หลบ
	library.add_animation("dodge_roll", _make(0.45,
		[[0.0, Vector3.ZERO], [0.224, Vector3(-FLIP, 0, 0)], [0.226, Vector3(FLIP, 0, 0)], [0.45, Vector3.ZERO]],
		[[0.0, Vector3.ZERO], [0.225, Vector3(0, -0.4, 0)], [0.45, Vector3.ZERO]], rest))
	library.add_animation("dodge_step", _make(0.2,
		[[0.0, Vector3.ZERO], [0.1, Vector3(0, 0, 0.25)], [0.2, Vector3.ZERO]],
		[[0.0, Vector3.ZERO], [0.1, Vector3(0, -0.1, 0)], [0.2, Vector3.ZERO]], rest))

	var player := AnimationPlayer.new()
	player.name = "PlaceholderAnimationPlayer"
	# ขยับ "โหนด" ใน physics tick ให้เข้ากับ Physics Interpolation
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	player.add_animation_library(LIBRARY, library)
	fighter.add_child(player)
	return player


## rotations / offsets: [[เวลา, Vector3], ...] (offsets บวกจากตำแหน่งปกติของ Body)
static func _make(length: float, rotations: Array, offsets: Array, rest: Vector3) -> Animation:
	var animation := Animation.new()
	animation.length = length

	var rotation_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(rotation_track, "Body:rotation")
	for key in (rotations if not rotations.is_empty() else [[0.0, Vector3.ZERO]]):
		animation.track_insert_key(rotation_track, key[0], key[1])

	var position_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(position_track, "Body:position")
	for key in (offsets if not offsets.is_empty() else [[0.0, Vector3.ZERO]]):
		animation.track_insert_key(position_track, key[0], rest + key[1])
	return animation
