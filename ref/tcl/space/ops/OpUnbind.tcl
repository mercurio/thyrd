### The ``unbind`` operation
#
# PJM 2008-10-04	Created

Op construct OpUnbind

OpUnbind slot opcode "unbind"
OpUnbind slot caption "unbind"
OpUnbind slot iconlg [Thyrd getImage "op-unbind-lg"]
OpUnbind slot iconsm [Thyrd getImage "op-unbind-sm"]
OpUnbind slot icongl [Thyrd getImage "op-unbind-gl"]
OpUnbind slot in {t}
OpUnbind slot out {}
OpUnbind slot tags {thyrdspace}
OpUnbind slot help "Pop a cell containing a triad off the current stack and destroy the triad."
OpUnbind slot sidefx "Error if cell popped isn't a triad"

# Perform the operation on the given wave
#
OpUnbind method doOp {wave} {
	set t [$wave pop]
	if {$t eq ""} {
		return -code error "Stack is empty or top is empty cell"
	}

	if {![Object existsAs $t Triad]} {
		return -code error "Cell on top of stack does not contain a triad"
	}

	$wave saveX

	$wave pushOn unA [$t cell A] [$t cell B] [$t cell Y]
	$t destruct

	return ""
}

# Undo an unbind by rebinding the three cells, which
# on the unA stack, and restoring the operand.
#
OpUnbind method undoOp {wave} {
	set y [$wave pop unA]
	set b [$wave pop unA]
	set a [$wave pop unA]

	set t [theSpace bind $a $b $y]

	$wave pushTyped [list $t TriadCore]

	return ""
}
