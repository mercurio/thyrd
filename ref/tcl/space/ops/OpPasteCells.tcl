### Paste cells from the given holding cell into a cell at the
### specified coordinates.
###
###
#
# PJM 2007-08-13	Created

Op construct OpPasteCells

OpPasteCells slot opcode "paste"
OpPasteCells slot caption "paste cells"
OpPasteCells slot iconlg [Thyrd getImage "op-paste-lg"]
OpPasteCells slot iconsm [Thyrd getImage "op-paste-sm"]
OpPasteCells slot icongl [Thyrd getImage "op-paste-gl"]
OpPasteCells slot in {hcell cell i0 j0}
OpPasteCells slot out {}
OpPasteCells slot tags {thyrdspace}
OpPasteCells slot help "Given a holding cell, destination cell and starting coordinates, paste the cells from the holding cell to the destination."
OpPasteCells slot sidefx ""

# Paste the cells from a holding cell into the 
# designated cell and coords
#
OpPasteCells method doOp {wave} {
	if {![$wave shiftValuesToVars i0 j0]} {
		return -code error "Unable to shift 2 values on wave $wave"
	}

	if {![$wave shiftCellsToVars hcell cell]} {
		return -code error "Unable to shift 2 cells on wave $wave"
	}

	$wave saveX

	set unhcell [theSpace paste $hcell $cell $i0 $j0]
	$unhcell placeInWave $wave

	$wave ifBiDi pushUnCell $unhcell

	return ""
}

# Unpaste the cells by pasting the contents of the unhcell holding
# cell back in place
#
OpPasteCells method undoOp {wave} {
	$wave unshiftCellsToVars cell hcell unhcell
	$wave unshiftValuesToVars j0 i0

	[theSpace paste $unhcell $cell $i0 $j0] destruct

	return ""
}
