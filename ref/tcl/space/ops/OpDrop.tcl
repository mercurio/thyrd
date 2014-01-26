### The ``drop`` operation
#
# PJM 2007-07-23	Created
# PJM 2008-10-16	Renamed from pop

Op construct OpDrop

OpDrop slot opcode "drop"
OpDrop slot caption "drop"
OpDrop slot iconlg [Thyrd getImage "op-drop-lg"]
OpDrop slot iconsm [Thyrd getImage "op-drop-sm"]
OpDrop slot icongl [Thyrd getImage "op-drop-gl"]
OpDrop slot in {x}
OpDrop slot out {}
OpDrop slot tags {wave}
OpDrop slot help "Remove the item on the top of the current stack"
OpDrop slot sidefx "none"

# Pop an item and discard it
#
OpDrop method doOp {wave} {
	$wave shiftCellsToVars x
	$wave saveX

	return ""
}

# Undo a drop op
#
OpDrop method undoOp {wave} {
	$wave unshift 1

	return ""
}
