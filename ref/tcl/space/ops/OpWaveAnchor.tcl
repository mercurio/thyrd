### The ``waveanchor`` operation
#
# PJM 2008-10-29	Created
# PJM 2008-12-17	Renamed to anchor (added event waves)

Op construct OpWaveAnchor

OpWaveAnchor slot opcode "waveanchor"
OpWaveAnchor slot caption "wave's 'anchor' cell"
OpWaveAnchor slot iconlg [Thyrd getImage "op-waveanchor-lg"]
OpWaveAnchor slot iconsm [Thyrd getImage "op-waveanchor-sm"]
OpWaveAnchor slot icongl [Thyrd getImage "op-waveanchor-gl"]
OpWaveAnchor slot in {}
OpWaveAnchor slot out {anchor}
OpWaveAnchor slot tags {wave}
OpWaveAnchor slot help "Push the anchor cell for this wave. If there's no anchor cell specified we make one that will be destroyed when the wave destructs."
OpWaveAnchor slot sidefx ""

# Push the anchor cell
#
OpWaveAnchor method doOp {wave} {
	$wave saveX

	set r [$wave slot anchor]
	if {$r eq ""} { ;# note: this should never happen, handled in Wave new
		set r [Cell newInWave $wave ""]
		$wave slot anchor $r
	}

	$wave pushAnchor $r

	return ""
}

# Undo a wave anchor
#
OpWaveAnchor method undoOp {wave} {
	$wave pop

	return ""
}
