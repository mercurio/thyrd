### The ``parse`` operation
###
### This should probably be smarter and escape the glue if it appears
### in a grid cell.
#
# PJM 2008-10-17	Created

Op construct OpParse

OpParse slot opcode "parse"
OpParse slot caption "parse"
OpParse slot iconlg [Thyrd getImage "op-parse-lg"]
OpParse slot iconsm [Thyrd getImage "op-parse-sm"]
OpParse slot icongl [Thyrd getImage "op-parse-gl"]
OpParse slot in {string glue}
OpParse slot out {grid}
OpParse slot tags {strings}
OpParse slot help "Pop off a string and a glue string. Parse the string by spliting it into substrings as delineated by the glue string, and construct a grid containing a list of cells, one fore each substring."
OpParse slot sidefx "Error if two cells aren't present. If string cell is not atomic we just push it."

# Perform the operation on the given wave
#
OpParse method doOp {wave} {
	if {![$wave shiftCellsToVars str glue]} {
		return -code error "Expecting 2 cells on stack"
	}

	$wave saveX

	if {![$str atomic]} {
		$wave pushAnchor $str
	} else {
		set g [Cell newInWave $wave "" Grid]
		foreach ss [split [$str get] [$glue get]] {
			$g as CMList append $ss
		}
		$wave pushAnchor $g
	}

	return ""
}

# Undo a follow by restoring the operands.
#
OpParse method undoOp {wave} {
	$wave pop
	$wave unshift 2

	return ""
}
