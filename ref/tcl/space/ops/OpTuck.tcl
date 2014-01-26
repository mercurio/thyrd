### Copy the top of the stack and insert it deep in the stack
###
#
# PJM 2008-10-18	Created

Op construct OpTuck

OpTuck slot opcode "tuck"
OpTuck slot caption "tuck"
OpTuck slot iconlg [Thyrd getImage "op-tuck-lg"]
OpTuck slot iconsm [Thyrd getImage "op-tuck-sm"]
OpTuck slot icongl [Thyrd getImage "op-tuck-gl"]
OpTuck slot in {n}
OpTuck slot out {}
OpTuck slot tags {wave}
OpTuck slot help "Pop n, then copy the top of the stack and insert it below the nth item in the stack."
OpTuck slot sidefx ""

# Do the operation on the given wave
#
OpTuck method doOp {wave} {
	if {![$wave shiftValuesToVars n]} {
		return -code error "Missing n value on stack"
	}

	set st [$wave slot stack]
	if {$n >= [$wave slotLength $st]} {
		return -code error "Not enough values on stack"
	}

	$wave saveX

	incr n
	$wave slotInsert $st $n [$wave slotIndex $st 0]
	
	return ""
}

# Undo a tuck operation. 
#
OpTuck method undoOp {wave} {
	$wave unshiftValuesToVars n
	incr n 2

	$wave slotReplace [$wave slot stack] $n $n
	return ""
}
