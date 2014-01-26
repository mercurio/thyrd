### The ``bind`` operation
#
# PJM 2008-10-04	Created

Op construct OpBind

OpBind slot opcode "bind"
OpBind slot caption "bind"
OpBind slot iconlg [Thyrd getImage "op-bind-lg"]
OpBind slot iconsm [Thyrd getImage "op-bind-sm"]
OpBind slot icongl [Thyrd getImage "op-bind-gl"]
OpBind slot in {aby}
OpBind slot out {}
OpBind slot tags {thyrdspace}
OpBind slot help "Pop cells off the A, B, and Y stacks and bind them in a triad"
OpBind slot sidefx "Error if three cells aren't present"

# Perform the operation on the given wave
#
OpBind method doOp {wave} {
	if {![$wave shiftCellFromStackToVar A a]} {
		return -code error "Stack A is empty"
	}

	if {![$wave shiftCellFromStackToVar B b]} {
		return -code error "Stack B is empty"
	}

	if {![$wave shiftCellFromStackToVar Y y]} {
		return -code error "Stack Y is empty"
	}

	$wave saveX

	set t [theSpace bind $a $b $y]
	$wave pushTypedOnStack unA [list $t TriadCore]

	return ""
}

# Undo a bind by unbinding the triad, which should be
# on the unA stack, and restoring the operands
#
OpBind method undoOp {wave} {
	set t [$wave pop unA]
	Object safe $t destruct

	$wave unshiftStack A 1
	$wave unshiftStack B 1
	$wave unshiftStack Y 1

	return ""
}
