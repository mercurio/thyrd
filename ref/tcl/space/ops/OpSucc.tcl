### The ``succ`` operation
#
# PJM 2008-02-12	Created

Op construct OpSucc

OpSucc slot opcode "succ"
OpSucc slot caption "successor"
OpSucc slot iconlg [Thyrd getImage "op-succ-lg"]
OpSucc slot iconsm [Thyrd getImage "op-succ-sm"]
OpSucc slot icongl [Thyrd getImage "op-succ-gl"]
OpSucc slot in {a}
OpSucc slot out {a+1}
OpSucc slot tags {arithmetic}
OpSucc slot help "Pop a value and return the next value." 
OpSucc slot sidefx "none"

# Perform the operation on the given wave
#
OpSucc method doOp {wave} {
	$wave shiftValuesToVars a
	$wave saveX

	if {[string is integer $a]} {
		$wave pushTyped [list [+ $a 1] <integer>]
	} elseif {[string is double $a]} {
		$wave pushTyped [list [+ $a 1] <real>]
	} else {
		$wave push $a
	}

	return ""
}

# Undo by removing the answer and
# restoring the operands
#
OpSucc method undoOp {wave} {
	$wave pop
	$wave unshift 1

	return ""
}
