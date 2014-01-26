### The ``find`` operation
#
# PJM 2008-10-06	Created

Op construct OpFind

OpFind slot opcode "find"
OpFind slot caption "find"
OpFind slot iconlg [Thyrd getImage "op-find-lg"]
OpFind slot iconsm [Thyrd getImage "op-find-sm"]
OpFind slot icongl [Thyrd getImage "op-find-gl"]
OpFind slot in {aby}
OpFind slot out {g}
OpFind slot tags {thyrdspace}
OpFind slot help "Pop paths off the A, B, and Y stacks and search for all the triads that match, returning a grid of triads"
OpFind slot sidefx "Error if three cells aren't present"

# Perform the operation on the given wave
#
# Each of the A, B, and Y cells should contain paths, cell refs,
# or "*".
#
OpFind method doOp {wave} {
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

	set pa [$a get]
	set pb [$b get]
	set py [$y get]


	set g [Cell new "" Grid]
	foreach t [theSpace findTriads $pa $pb $py] {
		$g append $t TriadCore
	}

	$wave pushAnchor $g

	return ""
}

# Undo a find by destroying the result and
# and restoring the operands
#
OpFind method undoOp {wave} {
	set g [$wave pop unA]
	Object safe $g destruct

	$wave unshiftStack A 1
	$wave unshiftStack B 1
	$wave unshiftStack Y 1

	return ""
}
