### The ``merge grid`` operation
###
### This should probably be smarter and escape the glue if it appears
### in a grid cell.
#
# PJM 2008-10-17	Created

Op construct OpMergeGrid

OpMergeGrid slot opcode "mergegrid"
OpMergeGrid slot caption "mergegrid"
OpMergeGrid slot iconlg [Thyrd getImage "op-mergegrid-lg"]
OpMergeGrid slot iconsm [Thyrd getImage "op-mergegrid-sm"]
OpMergeGrid slot icongl [Thyrd getImage "op-mergegrid-gl"]
OpMergeGrid slot in {grid iglue jglue}
OpMergeGrid slot out {cell}
OpMergeGrid slot tags {strings}
OpMergeGrid slot help "Pop off a grid cell and two glue strings. Construct a string with each value in the grid joined by the i glue string along the i axis and the j glue string along the j axis, and push that string. The i glue string does not appear at the end of each row but the j glue string does appear at the end of the whole grid."
OpMergeGrid slot sidefx "Error if three cells aren't present. If the grid cell is atomic we just push it."

# Perform the operation on the given wave
#
OpMergeGrid method doOp {wave} {
	if {![$wave shiftCellsToVars g iglue jglue]} {
		return -code error "Expecting 3 cells on stack"
	}

	$wave saveX

	if {[$g atomic]} {
		$wave pushAnchor $g
	} else {
		set s ""
		set ig [$iglue get]
		set jg [$jglue get]
		foreach row [$g as CMListList getListList] {
			append s [join $row $ig]
			append s $jg
		}
		$wave pushTyped [list $s <string>]
	}

	return ""
}

# Undo by restoring the operands.
#
OpMergeGrid method undoOp {wave} {
	$wave pop
	$wave unshift 3

	return ""
}
