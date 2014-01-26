### The ``call`` operation
#
# PJM 2008-10-19	Created

Op construct OpCall

OpCall slot opcode "call"
OpCall slot caption "call"
OpCall slot iconlg [Thyrd getImage "op-call-lg"]
OpCall slot iconsm [Thyrd getImage "op-call-sm"]
OpCall slot icongl [Thyrd getImage "op-call-gl"]
OpCall slot in {path}
OpCall slot out {}
OpCall slot tags {combinator}
OpCall slot help "Pop the path on the top of the stack, go to that cell and evaluate it"
OpCall slot sidefx "none"

# Perform the operation on the given wave
#
OpCall method doOp {wave} {
	if {![$wave shiftCellsToVars p]} {
		$wave slot error "Stack empty (expecting one cell containing a path)"
		return -code error 
	}

	$p setType Path
	set c [[$p slot core] resolve $p]
	if {$c eq ""} {
		$wave slot error "Unable to resolve path [$p get] relative to $p"
		return -code error 
	}

	$wave saveX

	set next [$wave getNext]
	lappend next [$wave newEnd]

	if {[$c atomic]} {
		lappend next $c
	} else {
		lappend next [$c subCell 1 1]
	}

	return $next
}

# Undo 
#
OpCall method undoOp {wave} {
	return ""
}
