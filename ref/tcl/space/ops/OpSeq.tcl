### Generate a sequence of numbers as a list
### in the given cell
###
### In: cell start end inc
### Out: cell
###
#
# PJM 2010-06-12	Created

Op construct OpSeq

OpSeq slot opcode "seq"
OpSeq slot caption "sequence"
OpSeq slot iconlg [Thyrd getImage "op-seq-lg"]
OpSeq slot iconsm [Thyrd getImage "op-seq-sm"]
OpSeq slot icongl [Thyrd getImage "op-seq-gl"]
OpSeq slot in {start end inc}
OpSeq slot out {cell}
OpSeq slot tags {thyrdspace}
OpSeq slot help "Given start, end, and increment values specifying a sequence, generate a new grid cell containing a list of cells representing the sequence"
OpSeq slot sidefx ""

# Perform the operation on the given wave
#
OpSeq method doOp {wave} {
	if {![$wave shiftValuesToVars start end inc]} {
		return -code error
	}

	if {[string is integer $start] && [string is integer $end] && [string is integer $inc]} {
		set ctype "<integer> [min $start $end] [max $start $end] [abs $inc]"
	} elseif {[string is double $start] && [string is double $end] && [string is double $inc]} {
		set ctype "<real> [min $start $end] [max $start $end] [abs $inc]"
	} else {
		$wave slot error "Only integer and real sequences supported"
		return -code error
	}

	if {$inc == 0} {
		$wave slot error "The increment may not be 0"
		return -code error
	}

	$wave saveX

	set nc [Cell newInWave $wave "" Grid]

	$wave pushCell $nc

	if {$inc > 0} {
		for {set x $start} {$x <= $end} {set x [expr {$x + $inc}]} {
			$nc append $x $ctype
		}
	} else {
		for {set x $start} {$x >= $end} {set x [expr {$x + $inc}]} {
			$nc append $x $ctype
		}
	}

	return ""
}

# Undo a sequence generation.
# We just destroy the buffer and move the params.
#
OpSeq method undoOp {wave} {
	$wave pop
	$wave unshiftValuesToVars inc end start

	return ""
}
