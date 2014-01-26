### The ``predecessor`` operation
#
# PJM 2008-02-12	Created

Op construct OpPred

OpPred slot opcode "pred"
OpPred slot caption "predecessor"
OpPred slot iconlg [Thyrd getImage "op-pred-lg"]
OpPred slot iconsm [Thyrd getImage "op-pred-sm"]
OpPred slot icongl [Thyrd getImage "op-pred-gl"]
OpPred slot in {a}
OpPred slot out {a-1}
OpPred slot tags {arithmetic}
OpPred slot help "Pop a value and return the previous value." 
OpPred slot sidefx "none"

# Perform the operation on the given wave
#
OpPred method doOp {wave} {
	$wave shiftValuesToVars a
	$wave saveX

	if {[string is integer $a]} {
		$wave pushTyped [list [- $a 1] <integer>]
	} elseif {[string is double $a]} {
		$wave pushTyped [list [- $a 1] <real>]
	} else {
		$wave push $a
	}

	return ""
}

# Undo by removing the answer and
# restoring the operands
#
OpPred method undoOp {wave} {
	$wave pop
	$wave unshift 1

	return ""
}
