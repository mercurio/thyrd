### The ``dup`` operation
#
# PJM 2008-02-12	Created

Op construct OpDup

OpDup slot opcode "dup"
OpDup slot caption "duplicate"
OpDup slot iconlg [Thyrd getImage "op-dup-lg"]
OpDup slot iconsm [Thyrd getImage "op-dup-sm"]
OpDup slot icongl [Thyrd getImage "op-dup-gl"]
OpDup slot in {a}
OpDup slot out {a a}
OpDup slot tags {wave}
OpDup slot help "Duplicate the top of the stack"
OpDup slot sidefx "none"

# Perform the operation on the given wave
#
OpDup method doOp {wave} {
	set c [$wave popCell]
	$wave saveX

	$wave pushCell $c
	$wave pushCell $c

	return ""
}

# Undo an addition by removing the answer and
# restoring the operands
#
OpDup method undoOp {wave} {
	$wave pop

	return ""
}
