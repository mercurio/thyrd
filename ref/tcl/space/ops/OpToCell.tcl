### The ``to cell`` operation
###
### ``to cell`` pops a path and pushes the cell it refers to.
### It also causes the wave to watch the cell, so changes
### cause a recalc. And it passes the path cell itself as the
### current cell, and sets the ``make`` option in resolve, to
### have the best shot at actually finding/making a cell.
###
#
# PJM 2008-10-10	Created
# PJM 2008-11-14	Added call to watch 
# PJM 2008-11-15	Added args to resolve 

Op construct OpToCell

OpToCell slot opcode "toCell"
OpToCell slot caption "to cell"
OpToCell slot iconlg [Thyrd getImage "op-tocell-lg"]
OpToCell slot iconsm [Thyrd getImage "op-tocell-sm"]
OpToCell slot icongl [Thyrd getImage "op-tocell-gl"]
OpToCell slot in {path}
OpToCell slot out {cell}
OpToCell slot tags {thyrdspace}
OpToCell slot help "Pop off a cell containing a path and push the corresponding cell. The path cell is used as the current cell for resolving a relative path. An error is generated if we can't make or resolve to a cell."
OpToCell slot sidefx "Possible error."

# Perform the operation on the given wave
#
OpToCell method doOp {wave} {
	if {![$wave shiftCellsToVars p]} {
		$wave slot error "Stack empty"
		return -code error
	}

	set pp [$p slot core]
	if {$pp eq "" || ![Object existsAs $pp Path]} {
		$wave slot error "$p is not a path"
		return -code error
	}

	$wave saveX

	set c [$pp resolve $p 1]

	if {$c eq ""} {
		$wave slot error "Unable to resolve path [$pp slot value]"
		return -code error 
	} else {
		$wave mightWatch $c
		$wave pushAnchor $c
	}

	return ""
}

# Undo a to cell by restoring the operands.
#
OpToCell method undoOp {wave} {
	$wave pop
	$wave unshift 1

	return ""
}
