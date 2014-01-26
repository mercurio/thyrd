### Copy cells from the given range into a holding cell
###
#
# PJM 2007-08-13	Created
# PJM 2007-08-31	Revised for bidi

Op construct OpCopyCells

OpCopyCells slot opcode "copy"
OpCopyCells slot caption "copy cells"
OpCopyCells slot iconlg [Thyrd getImage "op-copy-lg"]
OpCopyCells slot iconsm [Thyrd getImage "op-copy-sm"]
OpCopyCells slot icongl [Thyrd getImage "op-copy-gl"]
OpCopyCells slot in {cell i0 j0 i1 j1}
OpCopyCells slot out {cell}
OpCopyCells slot tags {thyrdspace}
OpCopyCells slot help "Given a cell and starting and ending coordinates, copy the range of cells into a new holding cell."
OpCopyCells slot sidefx ""

# Do the operation on the given wave
#
OpCopyCells method doOp {wave} {
	if {![$wave shiftValuesToVars i0 j0 i1 j1]} {
		return -code error "Unable to shift 4 values on wave $wave"
	}

	if {![$wave shiftCellsToVars cell]} {
		return -code error "Unable to shift 1 cell on wave $wave"
	}

	$wave saveX

	set h [theSpace copy $cell $i0 $j0 $i1 $j1]
	$h placeInWave $wave
	$wave pushAnchor $h

	return ""
}

# Undo a copy operation.  The buffer should be 
# on the stack, the params on the unstack.
# We just destroy the buffer and move the params.
#
OpCopyCells method undoOp {wave} {
	if {![$wave popAnchorToVar buf]} {
		return -code error "Unable to pop 1 cell on wave $wave"
	}

	Object safe $buf destruct

	$wave unshift 5

	return ""
}
