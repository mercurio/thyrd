### The ``set`` operation
#
# PJM 2008-10-16	Created

Op construct OpSet

OpSet slot opcode "set"
OpSet slot caption "set"
OpSet slot iconlg [Thyrd getImage "op-set-lg"]
OpSet slot iconsm [Thyrd getImage "op-set-sm"]
OpSet slot icongl [Thyrd getImage "op-set-gl"]
OpSet slot in {cell value}
OpSet slot out {}
OpSet slot tags {thyrdspace}
OpSet slot help "Pop off a cell and a value, and set the cell to the new value."
OpSet slot sidefx "Error if two cells aren't present."

# Perform the operation on the given wave
#
OpSet method doOp {wave} {
	if {![$wave shiftValuesToVars val]} {
		$wave slot error "Expecting cell and value on stack"
		return -code error
	}
	if {![$wave shiftCellsToVars c]} {
		$wave slot error "Expecting cell and value on stack"
		return -code error
	}

	$wave saveX

	$wave pushUnCell [Cell newInWave $wave [$c get] [$c getType]]

	$c set $val

	return ""
}

# Undo a follow by setting the old value back and
# restoring the operands.
#
OpSet method undoOp {wave} {
	$wave popUnstackToVar old
	$wave unshiftCellsToVars vc c

	$c setType [$old getType]
	$c set [$old get]

	$old destruct

	return ""
}
