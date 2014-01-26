### The ``move to A`` operation
#
# PJM 2008-09-22	Created

Op construct OpMoveToA

OpMoveToA slot opcode "moveToA"
OpMoveToA slot caption "move to A"
OpMoveToA slot iconlg [Thyrd getImage "op-movetoA-lg"]
OpMoveToA slot iconsm [Thyrd getImage "op-movetoA-sm"]
OpMoveToA slot icongl [Thyrd getImage "op-movetoA-gl"]
OpMoveToA slot in {x}
OpMoveToA slot out {}
OpMoveToA slot tags {wave}
OpMoveToA slot help "Pop the current stack and push it on stack A" 
OpMoveToA slot sidefx "Modifies stack A, unless A is already the current stack"

# Pop an item and push it on A
#
OpMoveToA method doOp {wave} {
	$wave saveX

	set a [$wave popCell]

	$wave pushCells A $a

	return ""
}

# Undo a move to A op
#
OpMoveToA method undoOp {wave} {
	return ""
}
