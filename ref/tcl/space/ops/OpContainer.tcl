### The ``container`` operation
#
# PJM 2008-10-15	Created

Op construct OpContainer

OpContainer slot opcode "container"
OpContainer slot caption "container"
OpContainer slot iconlg [Thyrd getImage "op-container-lg"]
OpContainer slot iconsm [Thyrd getImage "op-container-sm"]
OpContainer slot icongl [Thyrd getImage "op-container-gl"]
OpContainer slot in {cell else}
OpContainer slot out {cell}
OpContainer slot tags {thyrdspace}
OpContainer slot help "Pop off a cell and an else clause, and push the container cell of the given cell. If the cell doesn't have a container, evaluate the else clause."
OpContainer slot sidefx "Error if two cells aren't present. Else clause can have side effects."

# Perform the operation on the given wave
#
OpContainer method doOp {wave} {
	if {![$wave shiftCellsToVars c ec]} {
		return -code error "Expecting cell and else clause on stack"
	}

	$wave saveX

	set cc [$c slot container]

	if {$cc eq ""} {
		# eval $ec
		if {[$ec atomic]} {
			$wave pushCell $ec
		} else {
			$wave pushCells X [$ec subCell 1 1]
		}
	} else {
		$wave pushAnchor $cc
	}

	return ""
}

# Undo a follow by restoring the operands.
#
OpContainer method undoOp {wave} {
	$wave pop
	$wave unshift 2

	return ""
}
