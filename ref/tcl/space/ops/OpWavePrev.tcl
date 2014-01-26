### The ``waveprev`` operation
#
# PJM 2008-10-15	Created

Op construct OpWavePrev

OpWavePrev slot opcode "waveprev"
OpWavePrev slot caption "wave's 'previous' route"
OpWavePrev slot iconlg [Thyrd getImage "op-waveprev-lg"]
OpWavePrev slot iconsm [Thyrd getImage "op-waveprev-sm"]
OpWavePrev slot icongl [Thyrd getImage "op-waveprev-gl"]
OpWavePrev slot in {}
OpWavePrev slot out {prev}
OpWavePrev slot tags {wave}
OpWavePrev slot help "Push this wave's previous route (the route used to get from one cell to the next when running in reverse)."
OpWavePrev slot sidefx "None. Unless you mess with the route, in which case: good luck to you!"

# Push the previous route cell
#
OpWavePrev method doOp {wave} {
	$wave saveX

	$wave pushAnchor [$wave slot prev]

	return ""
}

# Undo a wave prev
#
OpWavePrev method undoOp {wave} {
	$wave pop

	return ""
}
