### Pick a cell from deep in the stack and copy it to the top
###
#
# PJM 2008-10-17	Created

Op construct OpPick

OpPick slot opcode "pick"
OpPick slot caption "pick from stack"
OpPick slot iconlg [Thyrd getImage "op-pick-lg"]
OpPick slot iconsm [Thyrd getImage "op-pick-sm"]
OpPick slot icongl [Thyrd getImage "op-pick-gl"]
OpPick slot in {n}
OpPick slot out {cell}
OpPick slot tags {wave}
OpPick slot help "Pick the nth item down in the stack and copy it to the top."
OpPick slot sidefx ""

# Do the operation on the given wave
#
OpPick method doOp {wave} {
	if {![$wave shiftValuesToVars n]} {
		return -code error "Missing n value on stack"
	}

	set st [$wave slot stack]
	if {$n >= [$wave slotLength $st]} {
		return -code error "Not enough values on stack"
	}

	$wave saveX

	$wave pushAnchor [$wave slotIndex $st $n]

	return ""
}

# Undo a pick operation. 
#
OpPick method undoOp {wave} {
	$wave pop
	$wave unshift 1

	return ""
}
