### The ``select A`` operation
#
# PJM 2007-07-23	Created

Op construct OpA

OpA slot opcode "A"
OpA slot caption "select A"
OpA slot iconlg [Thyrd getImage "op-A-lg"]
OpA slot iconsm [Thyrd getImage "op-A-sm"]
OpA slot icongl [Thyrd getImage "op-A-gl"]
OpA slot in {}
OpA slot out {}
OpA slot tags {wave}
OpA slot help "Select A as the current stack" 
OpA slot sidefx "none"

# Perform the operation on the given wave, saving
# undo info
#
OpA method doOp {wave} {
	$wave saveX

	$wave slot stack A

	return ""
}

# Undo the operation
#
OpA method undoOp {wave} {
	$wave slot stack A

	return ""
}
