### The ``select Y`` operation
#
# PJM 2007-07-23	Created

Op construct OpY

OpY slot opcode "Y"
OpY slot caption "select Y"
OpY slot iconlg [Thyrd getImage "op-Y-lg"]
OpY slot iconsm [Thyrd getImage "op-Y-sm"]
OpY slot icongl [Thyrd getImage "op-Y-gl"]
OpY slot in {}
OpY slot out {}
OpY slot tags {wave}
OpY slot help "Select Y as the current stack" 
OpY slot sidefx "none"

# Perform the operation on the given wave, saving
# undo info
#
OpY method doOp {wave} {
	$wave saveX

	$wave slot stack Y

	return ""
}

# Undo the operation
#
OpY method undoOp {wave} {
	$wave slot stack Y

	return ""
}
