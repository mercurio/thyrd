### The ``move to X`` operation
#
# PJM 2008-09-22	Created

Op construct OpMoveToX

OpMoveToX slot opcode "moveToX"
OpMoveToX slot caption "move to X"
OpMoveToX slot iconlg [Thyrd getImage "op-movetoX-lg"]
OpMoveToX slot iconsm [Thyrd getImage "op-movetoX-sm"]
OpMoveToX slot icongl [Thyrd getImage "op-movetoX-gl"]
OpMoveToX slot in {x}
OpMoveToX slot out {}
OpMoveToX slot tags {wave}
OpMoveToX slot help "Pop the current stack and push it on stack X" 
OpMoveToX slot sidefx "Modifies stack X, unless X is already the current stack"

# Pop an item and push it on X
#
OpMoveToX method doOp {wave} {
	$wave saveX

	set a [$wave popCell]

	$wave pushCells X $a

	return ""
}

# Undo a move to X op
#
OpMoveToX method undoOp {wave} {
	return ""
}
