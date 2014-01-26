### The ``tcl`` operation
#
# PJM 2008-10-16	Created

Op construct OpTcl

OpTcl slot opcode "tcl"
OpTcl slot caption "execute tcl"
OpTcl slot iconlg [Thyrd getImage "op-tcl-lg"]
OpTcl slot iconsm [Thyrd getImage "op-tcl-sm"]
OpTcl slot icongl [Thyrd getImage "op-tcl-gl"]
OpTcl slot in {script}
OpTcl slot out {result}
OpTcl slot tags {strings}
OpTcl slot help "Pop a Tcl script and execute it, pushing the result"
OpTcl slot sidefx "Anything"

# Perform the operation on the given wave
#
OpTcl method doOp {wave} {
	$wave shiftValuesToVars script
	$wave saveX
		
	set result [eval $script]
	$wave pushTyped [list $result <string>]

	return ""
}

# Undo
#
OpTcl method undoOp {wave} {
	$wave unshift 1
	return ""
}
