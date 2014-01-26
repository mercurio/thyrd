### Drop a cell from deep in the stack
###
#
# PJM 2008-10-18	Created

Op construct OpNip

OpNip slot opcode "nip"
OpNip slot caption "nip from stack"
OpNip slot iconlg [Thyrd getImage "op-nip-lg"]
OpNip slot iconsm [Thyrd getImage "op-nip-sm"]
OpNip slot icongl [Thyrd getImage "op-nip-gl"]
OpNip slot in {n}
OpNip slot out {}
OpNip slot tags {wave}
OpNip slot help "Drop the nth item down in the stack"
OpNip slot sidefx ""

# Do the operation on the given wave
#
OpNip method doOp {wave} {
	if {![$wave shiftValuesToVars n]} {
		return -code error "Missing n value on stack"
	}

	set st [$wave slot stack]
	if {$n >= [$wave slotLength $st]} {
		return -code error "Not enough values on stack"
	}

	$wave saveX

	$wave ifBiDi pushUnCell [$wave slotIndex $st $n]
	$wave slotReplace $st $n $n

	return ""
}

# Undo a nip operation. 
#
OpNip method undoOp {wave} {
	$wave popUnstackToVar un
	$wave unshiftValuesToVars n
	incr n

	$wave slotInsert [$wave slot stack] $n $un

	return ""
}
