### The ``if`` operation
#
# PJM 2008-02-12	Created

Op construct OpIf

OpIf slot opcode "if"
OpIf slot caption "if then else"
OpIf slot iconlg [Thyrd getImage "op-if-lg"]
OpIf slot iconsm [Thyrd getImage "op-if-sm"]
OpIf slot icongl [Thyrd getImage "op-if-gl"]
OpIf slot in {a (ifTrue) (ifFalse)}
OpIf slot out {}
OpIf slot tags {combinator}
OpIf slot help "If a is true evaluate (ifTrue), else (ifFalse)"
OpIf slot sidefx "depends on quoted code"

# Perform the operation on the given wave
#
OpIf method doOp {wave} {
	$wave shiftCellsToVars truth ifTrue ifFalse
	$wave saveX

	if {![$truth atomic]} {
		$wave slot error "|if in wave $wave| Expecting atomic cell (truth value) 3rd down from top of stack"
		return -code error
	}

	set next [$wave getNext]
	lappend next [$wave newEnd]

	if {[string is true [$truth get]]} {
		lappend next [$ifTrue subCell 1 1]
	} else {
		lappend next [$ifFalse subCell 1 1]
	}

	return $next
}

# Undo an if by removing the answer and
# restoring the operands
#
OpIf method undoOp {wave} {
	$wave pop
	$wave unshift 3

	return ""
}
