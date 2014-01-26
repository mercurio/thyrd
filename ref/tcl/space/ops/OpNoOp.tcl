### The ``do nothing`` operation
#
# PJM 2008-04-07	Created

Op construct OpNoOp

OpNoOp slot opcode ""
OpNoOp slot caption "do nothing"
OpNoOp slot iconlg [Thyrd getImage "op-noop-lg"]
OpNoOp slot iconsm [Thyrd getImage "op-noop-sm"]
OpNoOp slot icongl [Thyrd getImage "op-noop-gl"]
OpNoOp slot in {}
OpNoOp slot out {}
OpNoOp slot tags {flow}
OpNoOp slot help "Do nothing"
OpNoOp slot sidefx "none"

# Perform the operation on the given wave, saving
# undo info
#
OpNoOp method doOp {wave} {
	return ""
}

# Undo the operation
#
OpNoOp method undoOp {wave} {
	return ""
}
