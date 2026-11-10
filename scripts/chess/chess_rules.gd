class_name ChessRules
extends RefCounted
## Step 4: กติกาการเดินหมากแบบพื้นฐาน
## ยังไม่มี รุก/รุกจน, Castling และ En passant: เกมจบเมื่อ King แพ้การดวลแทน
## ตำแหน่งช่อง: x = คอลัมน์ 0-7 (a-h), y = แถว 0-7 โดยฝ่ายขาวเริ่มที่แถว 0-1

const ORTHOGONAL := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const DIAGONAL := [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
const KNIGHT_JUMPS := [
	Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2),
	Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2),
]


static func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < 8 and cell.y >= 0 and cell.y < 8


## pieces: Dictionary ของ Vector2i -> ChessPiece
static func get_legal_moves(pieces: Dictionary, piece: ChessPiece) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	match piece.type:
		ChessPiece.Type.PAWN:
			_add_pawn_moves(pieces, piece, moves)
		ChessPiece.Type.KNIGHT:
			_add_step_moves(pieces, piece, KNIGHT_JUMPS, moves)
		ChessPiece.Type.BISHOP:
			_add_slide_moves(pieces, piece, DIAGONAL, moves)
		ChessPiece.Type.ROOK:
			_add_slide_moves(pieces, piece, ORTHOGONAL, moves)
		ChessPiece.Type.QUEEN:
			_add_slide_moves(pieces, piece, ORTHOGONAL + DIAGONAL, moves)
		ChessPiece.Type.KING:
			_add_step_moves(pieces, piece, ORTHOGONAL + DIAGONAL, moves)
	return moves


static func _is_friend(pieces: Dictionary, piece: ChessPiece, cell: Vector2i) -> bool:
	var other: ChessPiece = pieces.get(cell)
	return other != null and other.team == piece.team


static func _add_step_moves(pieces: Dictionary, piece: ChessPiece, offsets: Array, moves: Array[Vector2i]) -> void:
	for offset: Vector2i in offsets:
		var cell := piece.board_pos + offset
		if is_inside(cell) and not _is_friend(pieces, piece, cell):
			moves.append(cell)


static func _add_slide_moves(pieces: Dictionary, piece: ChessPiece, directions: Array, moves: Array[Vector2i]) -> void:
	for direction: Vector2i in directions:
		var cell := piece.board_pos + direction
		while is_inside(cell):
			var other: ChessPiece = pieces.get(cell)
			if other == null:
				moves.append(cell)
			else:
				if other.team != piece.team:
					moves.append(cell)
				break
			cell += direction


static func _add_pawn_moves(pieces: Dictionary, piece: ChessPiece, moves: Array[Vector2i]) -> void:
	var forward := 1 if piece.team == ChessPiece.Team.WHITE else -1
	var one_step := piece.board_pos + Vector2i(0, forward)
	if is_inside(one_step) and not pieces.has(one_step):
		moves.append(one_step)
		var two_steps := piece.board_pos + Vector2i(0, forward * 2)
		if not piece.has_moved and is_inside(two_steps) and not pieces.has(two_steps):
			moves.append(two_steps)

	for side in [-1, 1]:
		var diagonal := piece.board_pos + Vector2i(side, forward)
		var other: ChessPiece = pieces.get(diagonal)
		if other != null and other.team != piece.team:
			moves.append(diagonal)
