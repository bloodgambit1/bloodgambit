class_name FighterSkills
extends Node
## ช่องสกิลของนักสู้ 1 ตัว: ใส่เป็นโหนดลูกชื่อ "Skills" ใต้ FighterController
## ช่อง 0 = Skill 1, ช่อง 1 = Skill 2, ช่อง 2 = Skill 3 (มีแค่ Rook)
## Cooldown นับแยกต่อช่องด้วย SkillCooldowns

signal skill_used(slot: int, skill: Skill)

var skills: Array[Skill] = []
var cooldowns := SkillCooldowns.new()

@onready var fighter: FighterController = get_parent()


func _process(delta: float) -> void:
	cooldowns.tick(delta)


func load_skills(new_skills: Array[Skill]) -> void:
	skills = new_skills
	cooldowns.reset(skills.size())


func try_use(slot: int) -> bool:
	if slot < 0 or slot >= skills.size():
		fighter.log_event("ไม่มีสกิลช่อง %d" % (slot + 1))
		return false

	var skill := skills[slot]
	if not cooldowns.is_ready(slot):
		fighter.log_event("%s ยังติด Cooldown อีก %.1f วินาที" % [skill.display_name, cooldowns.get_remaining(slot)])
		return false
	if not fighter.can_start_skill():
		fighter.log_event("ใช้ %s ไม่ได้ ตอนนี้อยู่ในสถานะ %s" % [skill.display_name, fighter.state_name()])
		return false

	cooldowns.start(slot, skill.cooldown)
	var token := fighter.begin_skill(skill)
	skill_used.emit(slot, skill)
	_run(skill, token)
	return true


func _run(skill: Skill, token: int) -> void:
	await skill.execute(fighter, token)
	fighter.end_skill(token)
