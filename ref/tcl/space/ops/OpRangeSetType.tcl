### Set the given range of cells to the given type
###
### In: cell i0 j0 i1 j1 type
### Out: 
###
#
# PJM 2008-02-11	Created
# PJM 2008-10-23	Renamed (used to be OpSetTYpe)

Op construct OpRangeSetType

OpRangeSetType slot opcode "rangesettype"
OpRangeSetType slot caption "range set type"
OpRangeSetType slot iconlg [Thyrd getImage "op-rangesettype-lg"]
OpRangeSetType slot iconsm [Thyrd getImage "op-rangesettype-sm"]
OpRangeSetType slot icongl [Thyrd getImage "op-rangesettype-gl"]
OpRangeSetType slot in {cell i0 j0 i1 j1 type}
OpRangeSetType slot out {}
OpRangeSetType slot tags {thyrdspace}
OpRangeSetType slot help "Given a range of cells (grid cell and starting and ending coordinates), and a type, change the type of the selected cells"
OpRangeSetType slot sidefx ""

# Set the types of the selected cells. If this is a bidi
# wave, we copy the types to a holding cell first, but only
# for undo; the holding cell is not left on the active stack.
#
OpRangeSetType method doOp {wave} {
	if {![$wave shiftValuesToVars i0 j0 i1 j1 t]} {
		return -code error
	}

	if {![$wave shiftCellsToVars cell]} {
		return -code error
	}
	$wave saveX

	set bidi [$wave slot bidi]

	if {$bidi} {
		set hcell [theSpace copyTypes $cell $i0 $j0 $i1 $j1]
		$hcell placeInWave $wave
	}

	set x [$cell slot core]
	foreach {wi wj} [$x walk [list $i0 $j0 $i1 $j1]] {
		set wc [$x getCoP $wi $wj]

		if {![Object exists $wc]} {
			$cell putTypeAt "" $t $wi $wj
		} else {
			$wc setType $t
		}
	}

	if {$bidi} {
		$wave pushAnchor $hcell
	}

	return ""
}

# Undo a set type operation.  The buffer should be 
# on the stack, the params on the unstack. The buffer
# only contains types and is destoryed afterwards.
#
OpRangeSetType method undoOp {wave} {
	if {![$wave popAnchorToVar buf]} {
		return -code error
	}

	$wave unshiftCellsToVars cell
	$wave unshiftValuesToVars t j1 i1 j0 i0 

	set ni0 [expr {$i0 == 0 ? 0 : 1}]
	set nj0 [expr {$j0 == 0 ? 0 : 1}]

	set x [$cell slot core]
	foreach {wi wj} [$x walk [list $i0 $j0 $i1 $j1]] {
		set wc [$x getCoP $wi $wj]

		if {[Object exists $wc]} {
			$wc setType [[$buf subCell [expr {$wi - $i0 + $ni0}] [expr {$wj - $j0 + $nj0}]] getType]
		}
	}

	$buf destruct

	return ""
}
