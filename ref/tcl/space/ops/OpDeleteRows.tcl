### Delete rows from a cell
###
### In: cell j0 j1
### Out: hcell
###
#
# PJM 2007-08-13	Created

Op construct OpDeleteRows

OpDeleteRows slot opcode "delrows"
OpDeleteRows slot caption "delete rows"
OpDeleteRows slot iconlg [Thyrd getImage "op-delrows-lg"]
OpDeleteRows slot iconsm [Thyrd getImage "op-delrows-sm"]
OpDeleteRows slot icongl [Thyrd getImage "op-delrows-gl"]
OpDeleteRows slot in {cell j0 j1}
OpDeleteRows slot out {cell}
OpDeleteRows slot tags {thyrdspace}
OpDeleteRows slot help "Given a cell and starting and ending j indexes, delete that range of rows"
OpDeleteRows slot sidefx ""

# Perform the operation on the given wave
#
OpDeleteRows method doOp {wave} {
	if {![$wave shiftValuesToVars j0 j1]} {
		return -code error
	}

	if {![$wave shiftCellsToVars cell]} {
		return -code error
	}

	$wave saveX

	set unhcell [theSpace copy $cell 0 $j0 endi $j1]
	$unhcell placeInWave $wave

	$cell as CMGrid deleteRows $j0 [- $j1 $j0 -1]

	$wave pushAnchor $unhcell

	return ""
}

# Undo a delete rows operation.  The buffer should be 
# on the stack, the params on the unstack.
#
OpDeleteRows method undoOp {wave} {
	if {![$wave popAnchorToVar buf]} {
		return -code error
	}

	$wave unshiftCellsToVars cell
	$wave unshiftValuesToVars j1 j0

	$cell as CMGrid addRows [- $j0 1] [- $j1 $j0 -1] yes
	[theSpace pasteFrame $buf $cell j $j0] destruct
	[theSpace paste $buf $cell 1 $j0] destruct

	return ""
}
