### Get or make the given subcell
###
#
# PJM 2008-10-15	Created

Op construct OpGetSub

OpGetSub slot opcode "getsub"
OpGetSub slot caption "get subcell"
OpGetSub slot iconlg [Thyrd getImage "op-getsub-lg"]
OpGetSub slot iconsm [Thyrd getImage "op-getsub-sm"]
OpGetSub slot icongl [Thyrd getImage "op-getsub-gl"]
OpGetSub slot in {cell i j}
OpGetSub slot out {cell}
OpGetSub slot tags {thyrdspace}
OpGetSub slot help "Given a cell and i and j indexes, retrieve the subcell or make it if it doesn't exist yet"
OpGetSub slot sidefx "Makes input cell a grid if necessary. Generates error if it can't make the subcell."

# Do the operation on the given wave
#
OpGetSub method doOp {wave} {
	if {![$wave shiftValuesToVars i j]} {
		return -code error "Unable to shift 2 values on wave $wave"
	}

	if {![$wave shiftCellsToVars g]} {
		return -code error "Unable to shift 1 cell on wave $wave"
	}

	$wave saveX

	$wave pushAnchor [$g subCell! $i $j]

	return ""
}

# Undo get sub operation. Currently, we just pop the result
# and restore the operands. If we created a cell, we let it live.
#
OpGetSub method undoOp {wave} {
	if {![$wave popAnchorToVar buf]} {
		return -code error "Unable to pop 1 cell on wave $wave"
	}

# Might want to add a boolean indicating we should do this:
#	Object safe $buf destruct

	$wave unshift 3

	return ""
}
