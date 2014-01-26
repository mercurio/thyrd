### The ``error`` operation
#
# PJM 2007-08-03	Created

Op construct OpError

OpError slot opcode "error"
OpError slot caption "error"
OpError slot iconlg [Thyrd getImage "op-error-lg"]
OpError slot iconsm [Thyrd getImage "op-error-sm"]
OpError slot icongl [Thyrd getImage "op-error-gl"]
OpError slot in {}
OpError slot out {}
OpError slot tags {flow}
OpError slot help "Stop the wave, displaying top of current stack as an error message"
OpError slot sidefx "Terminates wave" 

# Indicate an error
#DEFERRED not implemented yet
#
OpError method doOp {wave} {
	error "OpError"
	return ""
}

# Undo also indicates an error
#
OpError method undoOp {wave} {
	error "OpError"
	return ""
}
