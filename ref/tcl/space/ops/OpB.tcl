### The ``select B`` operation
#
# PJM 2007-07-23	Created

Op construct OpB

OpB slot opcode "B"
OpB slot caption "select B"
OpB slot iconlg [Thyrd getImage "op-B-lg"]
OpB slot iconsm [Thyrd getImage "op-B-sm"]
OpB slot icongl [Thyrd getImage "op-B-gl"]
OpB slot in {}
OpB slot out {}
OpB slot tags {wave}
OpB slot help "Select B as the current stack" 
OpB slot sidefx "none"

# Perform the operation on the given wave, saving
# undo info
#
OpB method doOp {wave} {
	$wave saveX

	$wave slot stack B

	return ""
}

# Undo the operation
#
OpB method undoOp {wave} {
	$wave slot stack B

	return ""
}
