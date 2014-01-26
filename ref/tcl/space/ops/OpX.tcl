### The ``select X`` operation
#
# PJM 2007-07-23	Created

Op construct OpX

OpX slot opcode "X"
OpX slot caption "select X"
OpX slot iconlg [Thyrd getImage "op-X-lg"]
OpX slot iconsm [Thyrd getImage "op-X-sm"]
OpX slot icongl [Thyrd getImage "op-X-gl"]
OpX slot in {}
OpX slot out {}
OpX slot tags {wave}
OpX slot help "Select X as the current stack" 
OpX slot sidefx "none"

# Perform the operation on the given wave, saving
# undo info
#
OpX method doOp {wave} {
	$wave saveX

	$wave slot stack X

	return ""
}

# Undo the operation
#
OpX method undoOp {wave} {
	$wave slot stack X

	return ""
}
