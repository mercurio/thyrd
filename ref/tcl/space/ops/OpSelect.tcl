### The ``select`` operation
###
### Pops two grids off the stack, the first is a program
### to be evaluated against each of the cells in the second
### grid. The program should return a boolean, execution
### stops when the boolean is true. The program may also
### leave stuff deeper on the stack, like a copy of the cell
### that was selected. The result of the operation is a boolean,
### the result of the last evaluation of the test program.
###
#
# PJM 2009-03-03	Begun


Op construct OpSelect

OpSelect slot opcode "select"
OpSelect slot caption "select"
OpSelect slot iconlg [Thyrd getImage "op-select-lg"]
OpSelect slot iconsm [Thyrd getImage "op-select-sm"]
OpSelect slot icongl [Thyrd getImage "op-select-gl"]
OpSelect slot in {a test}
OpSelect slot out {success}
OpSelect slot tags {combinator}
OpSelect slot help "Pop a grid (a) and a program (test). Evaluate the test against each of the cells of the grid, stopping when the test returns a true value. The result of the last evaluation of test is returned, which will be false if it failed for all the cells of a."
OpSelect slot sidefx "Depends on program provided as input"

# Select from a list of cells.
#
OpSelect method doOp {wave} {
	set virgin [$self slot virgin]

	if {$virgin} {
		if {![$wave shiftCellsToVars a test]} {
			$wave slot error "Expected inputs: a (grid) and test (program)"
			return -code error
		}

		if {[$a atomic]} {
			$wave slot error "Input a ($a) should be a grid"
			return -code error
		}

		if {[$test atomic]} {
			$wave slot error "Input test ($test) should be a grid"
			return -code error
		}

		$wave saveX

		set nop [$self construct *]
		$nop slot virgin 0

		$nop slot a $a
		set test [$nop slot test [$test one]]

		$nop slot walk [$a as CMGrid walk contents]

		set next [$wave getNext]
	} else {
		set nop $self
		set a [$nop slot a]
		set test [$nop slot test]
		set next ""

		set wi [$nop slot wi]
		set wj [$nop slot wj]

		if {$wi ne "" && $wj ne ""} { ;# check result from last execution
			set c [$wave peek]
			if {$c ne "" && [$c get]} {	;# success, we're done
				return ""
			} else {
				$wave pop
			}
		}
	}

	# Queue up next test
				
	set wi [$nop slot wi [$nop slotPop walk]]
	set wj [$nop slot wj [$nop slotPop walk]]

	if {$wi eq "" || $wj eq ""} { ;# failure, we're done
		$wave pushTyped [list 0 <boolean>]
		return $next
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

# Undo 
#
OpSelect method undoOp {wave} {
	return ""
}

