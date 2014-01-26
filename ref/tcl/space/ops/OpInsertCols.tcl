### Insert columns into a grid
###
### In: cell i n
### Out: 
###
#
# PJM 2008-01-18	Created

Op construct OpInsertCols

OpInsertCols slot opcode "inscols"
OpInsertCols slot caption "insert columns"
OpInsertCols slot iconlg [Thyrd getImage "op-inscols-lg"]
OpInsertCols slot iconsm [Thyrd getImage "op-inscols-sm"]
OpInsertCols slot icongl [Thyrd getImage "op-inscols-gl"]
OpInsertCols slot in {cell i n}
OpInsertCols slot out {}
OpInsertCols slot tags {thyrdspace}
OpInsertCols slot help "Given a cell and i index, add n columns after the indexed column"
OpInsertCols slot sidefx ""

# Perform the operation on the given wave
#
OpInsertCols method doOp {wave} {
	if {![$wave shiftValuesToVars i n]} {
		return -code error
	}

	if {![$wave shiftCellsToVars cell]} {
		return -code error
	}

	$wave saveX

	$cell as CMGrid addColumns $i $n

	return ""
}

# Undo a insert cols operation.  We just need to
# delete the columns.
#
OpInsertCols method undoOp {wave} {
	$wave unshiftCellsToVars cell
	$wave unshiftValuesToVars n i

	$cell as CMGrid deleteColumns [+ $i 1] $n

	return ""
}
