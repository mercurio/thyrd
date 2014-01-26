### Cut cells from the given range into a holding cell
###
### In: cell i0 j0 i1 j1
### Out: cell
###
#
# PJM 2007-08-13	Created

Op construct OpCutCells

OpCutCells slot opcode "cut"
OpCutCells slot caption "cut cells"
OpCutCells slot iconlg [Thyrd getImage "op-cut-lg"]
OpCutCells slot iconsm [Thyrd getImage "op-cut-sm"]
OpCutCells slot icongl [Thyrd getImage "op-cut-gl"]
OpCutCells slot in {cell i0 j0 i1 j1}
OpCutCells slot out {cell}
OpCutCells slot tags {thyrdspace}
OpCutCells slot help "Given a cell and starting and ending coordinates, cut the range of cells into a new holding cell."
OpCutCells slot sidefx ""

# Perform the operation on the given wave
#
OpCutCells method doOp {wave} {
	if {![$wave shiftValuesToVars i0 j0 i1 j1]} {
		$wave slot error "OpCutCells: 4 coordinates not present on stack"
		return -code error 
	}

	if {![$wave shiftCellsToVars cell]} {
		$wave slot error "OpCutCells: cell not present on stack"
		return -code error
	}

	$wave saveX

	set hcell [theSpace copy $cell $i0 $j0 $i1 $j1]
	$hcell placeInWave $wave
	theSpace delete $cell $i0 $j0 $i1 $j1

	$wave pushAnchor $hcell

	return ""
}

# Undo a cut operation.  The buffer should be 
# on the stack, the params on the unstack.
#
OpCutCells method undoOp {wave} {
	if {![$wave popAnchorToVar buf]} {
		return -code error
	}

	$wave unshiftCellsToVars cell
	$wave unshiftValuesToVars j1 i1 j0 i0

	[theSpace paste $buf $cell $i0 $j0] destruct

	return ""
}
