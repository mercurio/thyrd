### The ``move to B`` operation
#
# PJM 2008-09-22	Created

Op construct OpMoveToB

OpMoveToB slot opcode "moveToB"
OpMoveToB slot caption "move to B"
OpMoveToB slot iconlg [Thyrd getImage "op-movetoB-lg"]
OpMoveToB slot iconsm [Thyrd getImage "op-movetoB-sm"]
OpMoveToB slot icongl [Thyrd getImage "op-movetoB-gl"]
OpMoveToB slot in {x}
OpMoveToB slot out {}
OpMoveToB slot tags {wave}
OpMoveToB slot help "Pop the current stack and push it on stack B" 
OpMoveToB slot sidefx "Modifies stack B, unless B is already the current stack"

# Pop an item and push it on B
#
OpMoveToB method doOp {wave} {
	$wave saveX

	set a [$wave popCell]

	$wave pushCells B $a

	return ""
}

# Undo a move to B op
#
OpMoveToB method undoOp {wave} {
	return ""
}
