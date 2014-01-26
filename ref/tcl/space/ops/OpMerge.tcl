### The ``merge`` operation
###
### This should probably be smarter and escape the glue if it appears
### in a grid cell.
#
# PJM 2008-10-16	Created

Op construct OpMerge

OpMerge slot opcode "merge"
OpMerge slot caption "merge"
OpMerge slot iconlg [Thyrd getImage "op-merge-lg"]
OpMerge slot iconsm [Thyrd getImage "op-merge-sm"]
OpMerge slot icongl [Thyrd getImage "op-merge-gl"]
OpMerge slot in {grid glue}
OpMerge slot out {cell}
OpMerge slot tags {strings}
OpMerge slot help "Pop off a grid cell and a glue string. Treating the contents of the grid as a list, construct a string with each value in the list joined by the glue string and push that string. The glue string does not appear at the end."
OpMerge slot sidefx "Error if two cells aren't present. If grid cell is atomic we just push it."

# Perform the operation on the given wave
#
OpMerge method doOp {wave} {
	if {![$wave shiftCellsToVars g glue]} {
		return -code error "Expecting 2 cells on stack"
	}

	$wave saveX

	if {[$g atomic]} {
		$wave pushAnchor $g
	} else {
		$wave pushTyped [list [join [$g as CMList getList] [$glue get]] <string>]
	}

	return ""
}

# Undo a follow by restoring the operands.
#
OpMerge method undoOp {wave} {
	$wave pop
	$wave unshift 2

	return ""
}
