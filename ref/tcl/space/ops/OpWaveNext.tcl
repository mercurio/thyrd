### The ``wavenext`` operation
#
# PJM 2008-10-15	Created

Op construct OpWaveNext

OpWaveNext slot opcode "wavenext"
OpWaveNext slot caption "wave's 'next' route"
OpWaveNext slot iconlg [Thyrd getImage "op-wavenext-lg"]
OpWaveNext slot iconsm [Thyrd getImage "op-wavenext-sm"]
OpWaveNext slot icongl [Thyrd getImage "op-wavenext-gl"]
OpWaveNext slot in {}
OpWaveNext slot out {next}
OpWaveNext slot tags {wave}
OpWaveNext slot help "Push this wave's next route (the route used to get from one cell to the next when flowing)."
OpWaveNext slot sidefx "None. Unless you mess with the route, in which case: good luck to you!"

# Push the next route cell
#
OpWaveNext method doOp {wave} {
	$wave saveX

	$wave pushAnchor [$wave slot next]

	return ""
}

# Undo a wave next
#
OpWaveNext method undoOp {wave} {
	$wave pop

	return ""
}
