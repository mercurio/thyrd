### The ``move to Y`` operation
#
# PJM 2008-09-22	Created

Op construct OpMoveToY

OpMoveToY slot opcode "moveToY"
OpMoveToY slot caption "move to Y"
OpMoveToY slot iconlg [Thyrd getImage "op-movetoY-lg"]
OpMoveToY slot iconsm [Thyrd getImage "op-movetoY-sm"]
OpMoveToY slot icongl [Thyrd getImage "op-movetoY-gl"]
OpMoveToY slot in {x}
OpMoveToY slot out {}
OpMoveToY slot tags {wave}
OpMoveToY slot help "Pop the current stack and push it on stack Y" 
OpMoveToY slot sidefx "Modifies stack Y, unless Y is already the current stack"

# Pop an item and push it on Y
#
OpMoveToY method doOp {wave} {
	$wave saveX

	set a [$wave popCell]

	$wave pushCells Y $a

	return ""
}

# Undo a move to Y op
#
OpMoveToY method undoOp {wave} {
	return ""
}
