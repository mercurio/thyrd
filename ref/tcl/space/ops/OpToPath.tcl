### The ``to path`` operation
#
# PJM 2008-10-10	Created

Op construct OpToPath

OpToPath slot opcode "toPath"
OpToPath slot caption "to path"
OpToPath slot iconlg [Thyrd getImage "op-topath-lg"]
OpToPath slot iconsm [Thyrd getImage "op-topath-sm"]
OpToPath slot icongl [Thyrd getImage "op-topath-gl"]
OpToPath slot in {cell}
OpToPath slot out {path}
OpToPath slot tags {thyrdspace}
OpToPath slot help "Pop off a cell and push a cell containing its path"
OpToPath slot sidefx "None"

# Perform the operation on the given wave
#
OpToPath method doOp {wave} {
	if {![$wave shiftCellsToVars c]} {
		return -code error "Stack empty"
	}

	$wave saveX

	$wave pushAnchor [Cell newInWave $wave [$c path] Path]

	return ""
}

# Undo a to path by restoring the operands.
#
OpToPath method undoOp {wave} {
	$wave pop
	$wave unshift 1

	return ""
}
