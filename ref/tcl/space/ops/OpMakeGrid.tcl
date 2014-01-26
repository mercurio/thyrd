### Cut cells from the given range into a holding cell
###
### In: cell i0 j0 i1 j1
### Out: cell
###
#
# PJM 2007-08-13	Created

Op construct OpMakeGrid

OpMakeGrid slot opcode "makeGrid"
OpMakeGrid slot caption "make grid"
OpMakeGrid slot iconlg [Thyrd getImage "op-mkgrid-lg"]
OpMakeGrid slot iconsm [Thyrd getImage "op-mkgrid-sm"]
OpMakeGrid slot icongl [Thyrd getImage "op-mkgrid-gl"]
OpMakeGrid slot in {cell i0 j0 i1 j1}
OpMakeGrid slot out {cell}
OpMakeGrid slot tags {thyrdspace}
OpMakeGrid slot help "Given a cell and starting and ending coordinates, replace the cell at the starting coordinates with a grid containing the range of cells"
OpMakeGrid slot sidefx ""

# Perform the operation on the given wave
#
OpMakeGrid method doOp {wave} {
	if {![$wave shiftValuesToVars i0 j0 i1 j1]} {
		return -code error
	}

	if {![$wave shiftCellsToVars cell]} {
		return -code error
	}

	$wave saveX

	set hcell [theSpace copy $cell $i0 $j0 $i1 $j1]
	$hcell placeInWave $wave

	theSpace delete $cell $i0 $j0 $i1 $j1

	set gc [$cell subCell! $i0 $j0 "" Grid]
	[theSpace paste $hcell $gc 1 1] destruct

	$wave pushAnchor $hcell

	return ""
}

# Undo a makeGrid operation.  The buffer should be 
# on the stack, the params on the unstack.
# We just destroy the buffer and move the params.
#
OpMakeGrid method undoOp {wave} {
	if {![$wave popAnchorToVar hcell]} {
		return -code error
	}

	$wave unshiftCellsToVars cell
	$wave unshiftValuesToVars j1 i1 j0 i0

	[theSpace paste $hcell $cell $i0 $j0] destruct

	return ""
}
