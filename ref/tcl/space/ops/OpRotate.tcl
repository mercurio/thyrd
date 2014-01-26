### Rotate the order of the top n-1 values on the stack
###
#
# PJM 2008-10-18	Created

Op construct OpRotate

OpRotate slot opcode "rotate"
OpRotate slot caption "rotate"
OpRotate slot iconlg [Thyrd getImage "op-rotate-lg"]
OpRotate slot iconsm [Thyrd getImage "op-rotate-sm"]
OpRotate slot icongl [Thyrd getImage "op-rotate-gl"]
OpRotate slot in {n}
OpRotate slot out {}
OpRotate slot tags {wave}
OpRotate slot help "Rotate the order of the stack, so that item n is at the top"
OpRotate slot sidefx ""

# Do the operation on the given wave
#
OpRotate method doOp {wave} {
	if {![$wave shiftValuesToVars n]} {
		return -code error "Missing n value on stack"
	}

	set st [$wave slot stack]
	if {$n >= [$wave slotLength $st]} {
		return -code error "Not enough values on stack"
	}

	$wave saveX
	if {$n == 0} return

	set x [$wave slotIndex $st $n]
	$wave slotReplace $st $n $n
	$wave slotPush $st $x

	return ""
}

# Undo a reverse operation. 
#
OpRotate method undoOp {wave} {
	$wave unshiftValuesToVars n
	if {$n == 0} return

	incr n
	set st [$wave slot stack]
	set x [$wave slotIndex $st 1]
	$wave slotReplace $st 1 1
	$wave slotInsert $st $n $x

	return ""
}
