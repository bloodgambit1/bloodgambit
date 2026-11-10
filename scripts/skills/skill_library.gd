class_name SkillLibrary
extends RefCounted
## รวมชุดสกิลของหมากแต่ละชนิด (Pawn, Knight, Bishop, Rook, Queen, King)

const PawnSkills = preload("res://scripts/skills/pieces/pawn_skills.gd")
const KnightSkills = preload("res://scripts/skills/pieces/knight_skills.gd")
const BishopSkills = preload("res://scripts/skills/pieces/bishop_skills.gd")
const RookSkills = preload("res://scripts/skills/pieces/rook_skills.gd")
const QueenSkills = preload("res://scripts/skills/pieces/queen_skills.gd")
const KingSkills = preload("res://scripts/skills/pieces/king_skills.gd")


static func create_for(piece_type: ChessPiece.Type) -> Array[Skill]:
	match piece_type:
		ChessPiece.Type.PAWN:
			return PawnSkills.create()
		ChessPiece.Type.KNIGHT:
			return KnightSkills.create()
		ChessPiece.Type.BISHOP:
			return BishopSkills.create()
		ChessPiece.Type.ROOK:
			return RookSkills.create()
		ChessPiece.Type.QUEEN:
			return QueenSkills.create()
		ChessPiece.Type.KING:
			return KingSkills.create()
	var none: Array[Skill] = []
	return none
