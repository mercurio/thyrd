### Ancestor of the binary operations, requires
### an implementation of ``subOp`` to work.
#
# PJM 2008-12-14	Created

Op construct OpBinOp

# This should not appear anywhere, but if we leave it blank OpNoOp
# doesn't work. 
#
OpBinOp slot opcode "OpBinOp"

# Perform a binary operation on the given wave. If the
# two cells are both atomic, it's just ``subOp``. Otherwise
# we iterate over the two grids, reusing b until a is
# exhausted (the result has the same shape as a). If
# b is atomic, the result is the matrix a binOp'd with
# a constant. If a is atomic but b isn't, the result is
# a scalar resulting from binOp'ing a with b's 1 1 cell.
#
OpBinOp method doOp {wave} {
	if {![$wave shiftCellsToVars ca cb]} {
		$wave slot error "Expected inputs: ca and cb"
		return -code error
	}

	$wave saveX

	set aAtom [$ca atomic] 
	set bAtom [$cb atomic]

	if {$aAtom && $bAtom} {
		$wave pushTyped [$self subOp [$ca get] [$cb get]]
	} elseif {!$aAtom && !$bAtom} {
		set xa [$ca slot core]
		set xb [$cb slot core]

		set wa [$xa walk contents]
		set wb [$xb walk contents]

		set g [Cell newInWave $wave "" Grid]

		set i 0
		set n [expr {[llength $wb] / 2}]

		foreach {wai waj} $wa {
			set ii [* $i 2]
			set wbi [lindex $wb $ii]
			set wbj [lindex $wb [+ $ii 1]]

			lassign [$self subOp [[$xa getCell $wai $waj] get] [[$xb getCell $wbi $wbj] get]] v t
			$g putTypeAt $v $t $wai $waj

			incr i
			if {$i >= $n} {set i 0}
		}
			
		$wave pushAnchor $g
	} elseif {!$aAtom} {
		set xa [$ca slot core]
		set vb [$cb get]

		set wa [$xa walk contents]

		set g [Cell newInWave $wave "" Grid]

		foreach {wai waj} $wa {
			lassign [$self subOp [[$xa getCell $wai $waj] get] $vb] v t
			$g putTypeAt $v $t $wai $waj
		}
			
		$wave pushAnchor $g
	} else {
		$wave pushTyped [$self subOp [$ca get] [$cb getAt 1]]
	}

	return ""
}

# Undo a binOp by removing the answer and
# restoring the operands
#
OpBinOp method undoOp {wave} {
	$wave pop
	$wave unshift 2
	return ""
}
