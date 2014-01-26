### The ``filter`` operation
###
### Pops two grids off the stack, the first is a program
### to be evaluated against each of the cells in the second
### grid. A new grid is produced which contains only those
### cells for which the program evaluated to true.
###
#
# PJM 2008-05-20	Begun
# PJM 2008-06-03	First working version
# PJM 2009-02-20	Continuable version begun

Op construct OpFilter

OpFilter slot opcode "filter"
OpFilter slot caption "filter"
OpFilter slot iconlg [Thyrd getImage "op-filter-lg"]
OpFilter slot iconsm [Thyrd getImage "op-filter-sm"]
OpFilter slot icongl [Thyrd getImage "op-filter-gl"]
OpFilter slot in {a t}
OpFilter slot out {b}
OpFilter slot tags {combinator}
OpFilter slot help "Pop a grid (a) and a test (t). Evaluate the test against each of the cells in a and return grid b, which contains only those cells for which the test evaluates to true."
OpFilter slot sidefx "Depends on program provided as input"

# Filter the input grid by evaluating against the test program.
# This will always require multiple invocations, so we set up
# the new op right away.
#
OpFilter method doOp {wave} {
	set virgin [$self slot virgin]

	if {$virgin} {
		if {![$wave shiftCellsToVars a test] || [$a atomic] || [$test atomic]} {
			$wave slot error "Expected inputs: a (grid) and test (program)"
			return -code error
		}

		$wave saveX

		set nop [$self construct *]
		$nop slot virgin 0

		$nop slot a $a
		set test [$nop slot test [$test one]]

		$nop slot good [list]
		$nop slot walk [$a as CMGrid walk contents]

		set next [$wave getNext]
	} else {
		set nop $self
		set a [$nop slot a]
		set test [$nop slot test]
		set next ""

		set wi [$nop slot wi]
		set wj [$nop slot wj]

		if {$wi ne "" && $wj ne ""} { ;# get result from last test
			if {[$wave pop]} {
				$nop slotAppend good $wi $wj
			}
		}
	}

	# Queue up next test
				
	set wi [$nop slot wi [$nop slotPop walk]]
	set wj [$nop slot wj [$nop slotPop walk]]

	if {$wi eq "" || $wj eq ""} { ;# we're done
		set out [theSpace copy $a exactly [$nop slot good]]
		$out placeInWave $wave

		$wave pushAnchor $out
	} else {	;# test one cell, if found, else continue
		set wc [[$a slot core] getCell $wi $wj]
		if {[Object exists $wc]} {
			$wave pushCell $wc
			lappend next $nop [$wave newEnd] $test
		} else {
			lappend next $nop
		}
	}

	return $next
}

# Undo by removing the answer and
# restoring the operands
#
OpFilter method undoOp {wave} {
	return ""
}

# Reference:
# The direct version of the filter op.
# This version allowed a to be an atomic cell, and
# returned a copy if it passed the test, which is 
# a stupid idea.
#
OpFilter method reference-doOp {wave} {
	if {![$wave shiftCellsToVars a test]} {
		return -code error
	}

	$wave saveX

	set x [$a slot core]
	if {[$x isA Grid]} {
		set good [list]

		foreach {wi wj} [$x walk contents] {
			set wc [$x getCell $wi $wj]
			if {[Object exists $wc]} {
				$wave pushCell $wc
				$wave subroutine $test
				if {[$wave pop]} {
					lappend good $wi $wj
				}
			}
		}

		set out [theSpace copy $a exactly $good]
		$out placeInWave $wave
	} else {
		$wave pushCell $a
		$wave subroutine $test
		if {[$wave pop]} {
			set out [Cell newInWave $wave "" Grid]
			[$out slot core] setCell [$a clone] 1 1
		}
	}

	$wave pushAnchor $out

	return ""
}
