### Delete columns from a cell
###
### In: cell i0 i1
### Out: hcell
###
#
# PJM 2008-01-18	Created
# PJM 2008-04-18	Revised, undo added

Op construct OpDeleteCols

OpDeleteCols slot opcode "delcols"
OpDeleteCols slot caption "delete columns"
OpDeleteCols slot iconlg [Thyrd getImage "op-delcols-lg"]
OpDeleteCols slot iconsm [Thyrd getImage "op-delcols-sm"]
OpDeleteCols slot icongl [Thyrd getImage "op-delcols-gl"]
OpDeleteCols slot in {cell i0 i1}
OpDeleteCols slot out {cell}
OpDeleteCols slot tags {thyrdspace}
OpDeleteCols slot help "Given a cell and starting and ending i indexes, delete that range of columns"
OpDeleteCols slot sidefx ""

# Perform the operation on the given wave
#
OpDeleteCols method doOp {wave} {
	if {![$wave shiftValuesToVars i0 i1]} {
		return -code error
	}

	if {![$wave shiftCellsToVars cell]} {
		return -code error
	}

	$wave saveX

	set unhcell [theSpace copy $cell $i0 0 $i1 endj]
	$unhcell placeInWave $wave

	$cell as CMGrid deleteColumns $i0 [- $i1 $i0 -1]

	$wave pushAnchor $unhcell

	return ""
}

# Undo a deleteCols operation.  The buffer should be 
# on the stack, the params on the unstack.
# We insert blank columns and then paste in the holding
# cell contents.
#
OpDeleteCols method undoOp {wave} {
	if {![$wave popAnchorToVar buf]} {
		return -code error
	}

	$wave unshiftCellsToVars cell
	$wave unshiftValuesToVars i1 i0

	$cell as CMGrid addColumns [- $i0 1] [- $i1 $i0 -1] yes
	[theSpace pasteFrame $buf $cell i $i0] destruct
	[theSpace paste $buf $cell $i0 1] destruct

	return ""
}
