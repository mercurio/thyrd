### The ``end`` operation
#
# PJM 2007-07-23	Created

Op construct OpEnd

OpEnd slot opcode "end"
OpEnd slot caption "end"
OpEnd slot iconlg [Thyrd getImage "op-end-lg"]
OpEnd slot iconsm [Thyrd getImage "op-end-sm"]
OpEnd slot icongl [Thyrd getImage "op-end-gl"]
OpEnd slot in a
OpEnd slot out ""
OpEnd slot tags {flow}
OpEnd slot help "End wave, pop the current stack and store it in the result cell"
OpEnd slot sidefx "Terminates wave, sets result" 

# Return a code indicating the end of the wave
#
OpEnd method doOp {wave} {
	return -code return ""
}

# Undo of an end is a noop
#
OpEnd method undoOp {wave} {
	return ""
}
