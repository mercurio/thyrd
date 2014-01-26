### The ``eval`` operation
#
# PJM 2008-02-12	Created
# PJM 2009-02-24	Continuable version (returns next cells)

Op construct OpEval

OpEval slot opcode "eval"
OpEval slot caption "evaluate"
OpEval slot iconlg [Thyrd getImage "op-eval-lg"]
OpEval slot iconsm [Thyrd getImage "op-eval-sm"]
OpEval slot icongl [Thyrd getImage "op-eval-gl"]
OpEval slot in {a}
OpEval slot out {}
OpEval slot tags {combinator}
OpEval slot help "Pop the cell on the top of the stack and evaluate its contents"
OpEval slot sidefx "none"

# Perform the operation on the given wave
#
OpEval method doOp {wave} {
	set c [$wave popCell]
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

# Undo an addition by removing the answer and
# restoring the operands
#
OpEval method undoOp {wave} {
	$wave pop
	$wave unshift 2

	return ""
}
