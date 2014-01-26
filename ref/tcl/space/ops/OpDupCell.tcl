### Duplicate the cell on top of the stack
###
#
# PJM 2009-03-01	Created

Op construct OpDupCell

OpDupCell slot opcode "dupcell"
OpDupCell slot caption "dup cell"
OpDupCell slot iconlg [Thyrd getImage "op-dupcell-lg"]
OpDupCell slot iconsm [Thyrd getImage "op-dupcell-sm"]
OpDupCell slot icongl [Thyrd getImage "op-dupcell-gl"]
OpDupCell slot in {cell}
OpDupCell slot out {cell dup}
OpDupCell slot tags {thyrdspace}
OpDupCell slot help "Given a cell, push a new cell with the same contents"
OpDupCell slot sidefx ""

# Do the operation on the given wave
#
OpDupCell method doOp {wave} {
	if {![$wave shiftCellsToVars cell]} {
		$wave slot error "Unable to shift 1 cell on wave $wave"
		return -code error
	}

	$wave saveX

	
	if {[$cell atomic]} {
		set nc [Cell newInWave $wave [$cell get] [$cell getType]]
	} else {
		set nc [theSpace copy $cell all]
		$nc placeInWave $wave
	}

	$wave pushCell $cell
	$wave pushCell $nc

	return ""
}

# Undo a dup operation. We just destroy the duplicate
#
OpDupCell method undoOp {wave} {
	$wave pop

	return ""
}
