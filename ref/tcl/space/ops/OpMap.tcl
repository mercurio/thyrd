### The ``map`` operation
###
### Pops two grids off the stack, the first is a program
### to be evaluated against each of the cells in the second
### grid. A new grid is produced which contains the results
### from each of the evaluations.
###
#
# PJM 2008-06-03	Begun
# PJM 2009-02-21	Continuable version begun

Op construct OpMap

OpMap slot opcode "map"
OpMap slot caption "map"
OpMap slot iconlg [Thyrd getImage "op-map-lg"]
OpMap slot iconsm [Thyrd getImage "op-map-sm"]
OpMap slot icongl [Thyrd getImage "op-map-gl"]
OpMap slot in {a p}
OpMap slot out {map p on a}
OpMap slot tags {combinator}
OpMap slot help "Pop a grid (a) and a program (p). Evaluate the program with each of the cells of a and return grid b, which contains the results of the evaluations."
OpMap slot sidefx "Depends on program provided as input"

# Perform the operation on the given wave
#
OpMap method doOp {wave} {
	set virgin [$self slot virgin]

	if {$virgin} {
		if {![$wave shiftCellsToVars a prog] || [$a atomic] || [$prog atomic]} {
			$wave slot error "Expected inputs: a (grid) and prog (program)"
			return -code error
		}

		$wave saveX

		set nop [$self construct *]
		$nop slot virgin 0

		$nop slot a $a
		set prog [$nop slot prog [$prog one]]

		set out [$nop slot out [Cell newInWave $wave "" Grid]]

		[theSpace pasteFrame $a $out i 0] destruct
		[theSpace pasteFrame $a $out j 1] destruct

		$nop slot walk [$a as CMGrid walk contents]

		set next [$wave getNext]
	} else {
		set nop $self
		set a [$nop slot a]
		set prog [$nop slot prog]
		set next ""

		set wi [$nop slot wi]
		set wj [$nop slot wj]

		set out [$nop slot out]

		if {$wi ne "" && $wj ne ""} { ;# get result from last eval of $prog
			$out storeSub [$wave popCell] $wi $wj
		}
	}

	# Queue up next eval of $prog
	set wi [$nop slot wi [$nop slotPop walk]]
	set wj [$nop slot wj [$nop slotPop walk]]

	if {$wi eq "" || $wj eq ""} { ;# we're done
		$wave pushAnchor $out
	} else {	
		set wc [[$a slot core] getCell $wi $wj]
		if {[Object exists $wc]} {
			$wave pushCell $wc
			lappend next $nop [$wave newEnd] $prog
		} else {
			lappend next $nop
		}
	}

	return $next
}

# Undo by removing the answer and
# restoring the operands
#
OpMap method undoOp {wave} {
	return ""
}

# Reference, non-continuable version
# Perform the operation on the given wave
#
OpMap method reference-doOp {wave} {
	if {![$wave shiftCellsToVars a prog]} {
		return -code error
	}

	$wave saveX

	set x [$a slot core]
	if {[$x isA Grid]} {
		set out [Cell newInWave $wave "" Grid]

		[theSpace pasteFrame $a $out i 0] destruct
		[theSpace pasteFrame $a $out j 1] destruct

		foreach {wi wj} [$x walk contents] {
			set wc [$x getCell $wi $wj]
			if {[Object exists $wc]} {
				$wave pushCell $wc
				$wave subroutine $prog

				$out storeSub [$wave popCell] $wi $wj
			}
		}

		$wave pushAnchor $out
	} else {
		$wave pushCell $a
		$wave subroutine $prog
	}

	return ""
}
