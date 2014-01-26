### The ``not`` operation
#
# PJM 2008-02-12	Created

Op construct OpNot

OpNot slot opcode "!"
OpNot slot caption "not"
OpNot slot iconlg [Thyrd getImage "op-not-lg"]
OpNot slot iconsm [Thyrd getImage "op-not-sm"]
OpNot slot icongl [Thyrd getImage "op-not-gl"]
OpNot slot in {a}
OpNot slot out {!a}
OpNot slot tags {logic}
OpNot slot help "Pop a truth value and return its negation"
OpNot slot sidefx "none"

# Perform the operation on the given wave
#
OpNot method doOp {wave} {
	$wave shiftValuesToVars a
	$wave saveX

	if {[string is false $a]} {
		$wave pushTyped [list 1 <boolean>]
	} else {
		$wave pushTyped [list 0 <boolean>]
	}

	return ""
}

# Undo by removing the answer and
# restoring the operands
#
OpNot method undoOp {wave} {
	$wave pop
	$wave unshift 1

	return ""
}
