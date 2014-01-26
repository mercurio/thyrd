### Look up a subcell and return whether it exists or not.
###
#
# PJM 2008-10-15	Created

Op construct OpHasSub

OpHasSub slot opcode "hassub"
OpHasSub slot caption "has subcell?"
OpHasSub slot iconlg [Thyrd getImage "op-hassub-lg"]
OpHasSub slot iconsm [Thyrd getImage "op-hassub-sm"]
OpHasSub slot icongl [Thyrd getImage "op-hassub-gl"]
OpHasSub slot in {cell i j}
OpHasSub slot out {cell i j bool}
OpHasSub slot tags {thyrdspace}
OpHasSub slot help "Peek a cell and i and j indexes, push true if the cell exists"
OpHasSub slot sidefx ""

# Do the operation on the given wave
#
OpHasSub method doOp {wave} {
	set st [$wave slot stack]
	if {[$wave slotLength $st] < 3} {
		return -code error "Unable to peek 3 values on wave $wave"
	}

	$wave saveX
	lassign [$wave slotRange $st 0 2] j i g

	set c [$g subCell [$i get] [$j get]]
	$wave pushTyped [list [expr {$c ne ""}] <boolean>]

	return ""
}

# Undo has sub operation. Currently, we just pop the result
#
OpHasSub method undoOp {wave} {
	$wave pop

	return ""
}
