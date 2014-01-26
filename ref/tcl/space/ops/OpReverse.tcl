### Reverse the order of the top n-1 values on the stack
###
#
# PJM 2008-10-18	Created

Op construct OpReverse

OpReverse slot opcode "reverse"
OpReverse slot caption "reverse"
OpReverse slot iconlg [Thyrd getImage "op-reverse-lg"]
OpReverse slot iconsm [Thyrd getImage "op-reverse-sm"]
OpReverse slot icongl [Thyrd getImage "op-reverse-gl"]
OpReverse slot in {n}
OpReverse slot out {}
OpReverse slot tags {wave}
OpReverse slot help "Reverse the order of the stack, from 0 (top) to n"
OpReverse slot sidefx ""

# Do the operation on the given wave
#
OpReverse method doOp {wave} {
	if {![$wave shiftValuesToVars n]} {
		return -code error "Missing n value on stack"
	}


	set st [$wave slot stack]
	if {$n >= [$wave slotLength $st]} {
		return -code error "Not enough values on stack"
	}

	$wave saveX
	if {$n == 0} return

	set x [lreverse [$wave slotRange $st 0 $n]]
	$wave slotReplace $st 0 $n {*}$x

	return ""
}

# Undo a reverse operation. 
#
OpReverse method undoOp {wave} {
	$wave unshiftValuesToVars n
	if {$n == 0} return

	incr n
	set st [$wave slot stack]
	set x [lreverse [$wave slotRange $st 1 $n]]
	$wave slotReplace $st 1 $n {*}$x

	return ""
}
