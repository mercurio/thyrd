### Pop a cell and push its i and j indexes
#
# PJM 2008-10-16	Created

Op construct OpIndex

OpIndex slot opcode "index"
OpIndex slot caption "index"
OpIndex slot iconlg [Thyrd getImage "op-index-lg"]
OpIndex slot iconsm [Thyrd getImage "op-index-sm"]
OpIndex slot icongl [Thyrd getImage "op-index-gl"]
OpIndex slot in {cell}
OpIndex slot out {i j}
OpIndex slot tags {thyrdspace}
OpIndex slot help "Pop off a cell and push its i and j indexes"
OpIndex slot sidefx "None"

# Perform the operation on the given wave
#
OpIndex method doOp {wave} {
	if {![$wave shiftCellsToVars c]} {
		return -code error "Stack empty"
	}

	$wave saveX

	set ij [$c betterIndex]
	if {[llength $ij] == 1} {
		$wave pushAnchor [Cell newInWave $wave $ij <string>]
		$wave pushAnchor [Cell newInWave $wave $ij <string>]
	} else {
		lassign $ij i j
		$wave pushAnchor [Cell newInWave $wave $i <string>]
		$wave pushAnchor [Cell newInWave $wave $j <string>]
	}

	return ""
}

# Undo a to path by restoring the operands.
#
OpIndex method undoOp {wave} {
	$wave pop
	$wave pop
	$wave unshift 1

	return ""
}
