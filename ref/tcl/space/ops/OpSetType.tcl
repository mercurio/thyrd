### Set the given cell to the given type
###
### In: cell type
### Out: cell
###
#
# PJM 2008-10-23	Old version now named OpRangeSetType

Op construct OpSetType

OpSetType slot opcode "settype"
OpSetType slot caption "set type"
OpSetType slot iconlg [Thyrd getImage "op-settype-lg"]
OpSetType slot iconsm [Thyrd getImage "op-settype-sm"]
OpSetType slot icongl [Thyrd getImage "op-settype-gl"]
OpSetType slot in {cell type}
OpSetType slot out {cell}
OpSetType slot tags {thyrdspace}
OpSetType slot help "Given a cell and a type, change the type of the cell and leave it on the stack."
OpSetType slot sidefx ""

# Set the types of the cell. If this is a bidi
# wave, we copy the type to a holding cell first, but only
# for undo; the holding cell is not left on the active stack.
#
OpSetType method doOp {wave} {
	if {![$wave shiftValuesToVars t]} {
		return -code error
	}

	set cell [$wave peek]
	if {$cell eq ""} {
		return -code error
	}
	$wave saveX

	set bidi [$wave slot bidi]

	# If bidi, push a string cell with the old type on the unstack
	if {$bidi} {
		set uns un[$wave slot stack]
		$wave slotPush $uns [Cell newInWave $wave [$cell getType]]
	}

	$cell setType $t

	return ""
}

# Undo a set type operation.  
#
OpSetType method undoOp {wave} {
	if {![$wave popAnchorToVar buf]} {
		return -code error
	}

	set cell [$wave peek]
	$cell setType [$buf get]
	
	$wave unshiftCellsToVars ty 

	$buf destruct

	return ""
}
