### Peek two cells and push true if b is under a.
###
#
# PJM 2008-10-15	Created

Op construct OpIsUnder

OpIsUnder slot opcode "isUnder"
OpIsUnder slot caption "is under?"
OpIsUnder slot iconlg [Thyrd getImage "op-isunder-lg"]
OpIsUnder slot iconsm [Thyrd getImage "op-isunder-sm"]
OpIsUnder slot icongl [Thyrd getImage "op-isunder-gl"]
OpIsUnder slot in {grid cell}
OpIsUnder slot out {grid  cell bool}
OpIsUnder slot tags {thyrdspace}
OpIsUnder slot help "Peek a grid cell and a cell, push true if the cell is anywhere under the grid"
OpIsUnder slot sidefx ""

# Do the operation on the given wave
#
OpIsUnder method doOp {wave} {
	set st [$wave slot stack]
	if {[$wave slotLength $st] < 2} {
		return -code error "Unable to peek 2 values on wave $wave"
	}

	$wave saveX
	lassign [$wave slotRange $st 0 1] c g
	
	$wave pushTyped [list [$c isUnder $g] <boolean>]

	return ""
}

# Undo has sub operation. Currently, we just pop the result
#
OpIsUnder method undoOp {wave} {
	$wave pop

	return ""
}
