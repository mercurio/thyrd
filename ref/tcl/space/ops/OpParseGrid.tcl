### The ``parse grid`` operation
###
### This should probably be smarter and escape the glue if it appears
### in a grid cell.
#
# PJM 2008-10-17	Created

Op construct OpParseGrid

OpParseGrid slot opcode "parsegrid"
OpParseGrid slot caption "parsegrid"
OpParseGrid slot iconlg [Thyrd getImage "op-parsegrid-lg"]
OpParseGrid slot iconsm [Thyrd getImage "op-parsegrid-sm"]
OpParseGrid slot icongl [Thyrd getImage "op-parsegrid-gl"]
OpParseGrid slot in {string iglue jglue}
OpParseGrid slot out {grid}
OpParseGrid slot tags {strings}
OpParseGrid slot help "Pop off a string and two glue strings. Split the string into rows using the jglue and columns using iglue. The i glue string does not appear at the end of each row but the j glue string does appear at the end of the whole grid. The result is a grid cell with each cell containing one parsed element from the string."
OpParseGrid slot sidefx "Error if three cells aren't present. If the string cell is not atomic we just push it."

# Perform the operation on the given wave
#
OpParseGrid method doOp {wave} {
	if {![$wave shiftCellsToVars str iglue jglue]} {
		return -code error "Expecting 3 cells on stack"
	}

	$wave saveX

	if {![$str atomic]} {
		$wave pushAnchor $str
	} else {
		set g [Cell newInWave $wave "" Grid]
		set ig [$iglue get]
		set xx [list]
		foreach row [lrange [split [$str get] [$jglue get]] 0 end-1] {
			lappend xx [split $row $ig]
		}
		$g as CMListList setListList $xx
		$wave pushAnchor $g
	}

	return ""
}

# Undo by restoring the operands.
#
OpParseGrid method undoOp {wave} {
	$wave pop
	$wave unshift 3

	return ""
}
