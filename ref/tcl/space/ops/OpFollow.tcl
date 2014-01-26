### The ``follow path`` operation
#
# PJM 2008-10-10	Created

Op construct OpFollow

OpFollow slot opcode "follow"
OpFollow slot caption "follow path"
OpFollow slot iconlg [Thyrd getImage "op-follow-lg"]
OpFollow slot iconsm [Thyrd getImage "op-follow-sm"]
OpFollow slot icongl [Thyrd getImage "op-follow-gl"]
OpFollow slot in {path1 path2 else}
OpFollow slot out {cell}
OpFollow slot tags {thyrdspace}
OpFollow slot help "Pop off a two parts of a path and an else clause, and follow path2 starting from path1, pushing the resulting cell. If the path doesn't resolve, we evaluate the else clause."
OpFollow slot sidefx "Error if three cells aren't present. Else clause can have side effects."

# Perform the operation on the given wave
#
OpFollow method doOp {wave} {
	if {![$wave shiftCellsToVars p1 p2 ec]} {
		return -code error "Expecting starting path, path, and else clause on stack"
	}

	$wave saveX

	$p1 setType Path
	$p2 setType Path

	set pp1 [$p1 slot core]
	set pp2 [$p2 slot core]

	set cc [$pp1 resolve]
	set c [$pp2 resolve $cc]

	if {$c eq ""} {
		# eval $ec
		if {[$ec atomic]} {
			$wave pushCell $ec
		} else {
			$wave pushCells X [$ec subCell 1 1]
		}
	} else {
		$wave pushAnchor $c
	}

	return ""
}

# Undo a follow by restoring the operands.
#
OpFollow method undoOp {wave} {
	$wave pop
	$wave unshift 3

	return ""
}
