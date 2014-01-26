### Pop a cell and push its i and j dimensions.
### Atomic cells are 1 x 1, for grid cells we only
###	count the content cells.
#
# PJM 2008-10-16	Created

Op construct OpSize

OpSize slot opcode "size"
OpSize slot caption "size"
OpSize slot iconlg [Thyrd getImage "op-size-lg"]
OpSize slot iconsm [Thyrd getImage "op-size-sm"]
OpSize slot icongl [Thyrd getImage "op-size-gl"]
OpSize slot in {cell}
OpSize slot out {ni nj}
OpSize slot tags {thyrdspace}
OpSize slot help "Pop off a cell and push its i and j dimensions. Atomic cells are 1 x 1."
OpSize slot sidefx "None"

# Perform the operation on the given wave
#
OpSize method doOp {wave} {
	if {![$wave shiftCellsToVars c]} {
		return -code error "Stack empty"
	}

	$wave saveX

	# Get the size, which includes the frame
	lassign [$c size] i j

	# Adjust to exclude frame
	set i [? {$i <= 1} $i [- $i 1]]
	set j [? {$j <= 1} $j [- $j 1]]
	$wave pushAnchor [Cell newInWave $wave $i "<integer> 0"]
	$wave pushAnchor [Cell newInWave $wave $j "<integer> 0"]

	return ""
}

# Undo a to path by restoring the operands.
#
OpSize method undoOp {wave} {
	$wave pop
	$wave pop
	$wave unshift 1

	return ""
}
