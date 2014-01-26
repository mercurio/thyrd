### Insert rows into a grid
###
### In: cell j n
### Out: 
###
#
# PJM 2008-01-18	Created

Op construct OpInsertRows

OpInsertRows slot opcode "insrows"
OpInsertRows slot caption "insert rows"
OpInsertRows slot iconlg [Thyrd getImage "op-insrows-lg"]
OpInsertRows slot iconsm [Thyrd getImage "op-insrows-sm"]
OpInsertRows slot icongl [Thyrd getImage "op-insrows-gl"]
OpInsertRows slot in {cell j n}
OpInsertRows slot out {}
OpInsertRows slot tags {thyrdspace}
OpInsertRows slot help "Given a cell and j index, insert n rows after row j"
OpInsertRows slot sidefx ""

# Perform the operation on the given wave
#
OpInsertRows method doOp {wave} {
	if {![$wave shiftValuesToVars j n]} {
		return -code error
	}

	if {![$wave shiftCellsToVars cell]} {
		return -code error
	}

	$wave saveX

	$cell as CMGrid addRows $j $n

	return ""
}

# Undo an insert rows operation. We just delete the rows.
#
OpInsertRows method undoOp {wave} {
	$wave unshiftCellsToVars cell
	$wave unshiftValuesToVars n j

	$cell as CMGrid deleteRows [+ $j 1] $n

	return ""
}
