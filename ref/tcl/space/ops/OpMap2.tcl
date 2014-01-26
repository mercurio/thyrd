### The ``map2`` operation
###
### Pops three grids off the stack, the first is a program
### to be evaluated on each pair of cells taken from the
### two deeper grids. The result is the shape of the deepest
### grid.
###
### Note that the program must return a value to place in the
### resulting grid, even if you're not doing anything with
### the result.
### 
### This could have been written as a descendant of OpMap,
### with a parameter to control how many operand grids to
### expect. It's not clear that more than 2 is practical,
### useful, or interesting.
#
# PJM 2009-03-06	Created

OpMap construct OpMap2

OpMap2 slot opcode "map2"
OpMap2 slot caption "map2"
OpMap2 slot iconlg [Thyrd getImage "op-map2-lg"]
OpMap2 slot iconsm [Thyrd getImage "op-map2-sm"]
OpMap2 slot icongl [Thyrd getImage "op-map2-gl"]
OpMap2 slot in {a b p}
OpMap2 slot out {p applied to the cells in a and b}
OpMap2 slot tags {combinator}
OpMap2 slot help "Pop two grids (a and b) and a program (p). Evaluate the program with each of the cells of a and b and return grid c, which contains the results of the evaluations. The shape of c will be the same as a, the cells from b will be reused if necessary."
OpMap2 slot sidefx "Depends on program provided as input"

# Very similar to OpMap's version
#
OpMap2 method doOp {wave} {
	set virgin [$self slot virgin]

	if {$virgin} {
		if {![$wave shiftCellsToVars a b prog] || [$a atomic] || [$b atomic] || [$prog atomic]} {
			$wave slot error "Expected inputs: a, b (grids) and p (program)"
			return -code error
		}

		$wave saveX

		set nop [$self construct *]
		$nop slot virgin 0

		$nop slot a $a
		$nop slot b $b
		set prog [$nop slot prog [$prog one]]

		set out [$nop slot out [Cell newInWave $wave "" Grid]]

		[theSpace pasteFrame $a $out i 0] destruct
		[theSpace pasteFrame $a $out j 1] destruct

		$nop slot walka [$a as CMGrid walk contents]
		$nop slot walkb [$b as CMGrid walk contents]

		set next [$wave getNext]
	} else {
		set nop $self
		set a [$nop slot a]
		set b [$nop slot b]
		set prog [$nop slot prog]
		set next ""

		set wai [$nop slot wai]
		set waj [$nop slot waj]

		set out [$nop slot out]

		if {$wai ne "" && $waj ne ""} { ;# get result from last eval of $prog
			$out storeSub [$wave popCell] $wai $waj
		}
	}

	# Queue up next eval of $prog
	set wai [$nop slotPop walka]
	set waj [$nop slotPop walka]

	set wbi [$nop slotPop walkb]
	set wbj [$nop slotPop walkb]

	if {$wbi eq "" || $wbj eq ""} {	;# restart b
		$nop slot walkb [$b as CMGrid walk contents]
		set wbi [$nop slotPop walkb]
		set wbj [$nop slotPop walkb]
	}

	if {$wai eq "" || $waj eq ""} { ;# we're done
		$wave pushAnchor $out
	} else {	
		set wac [[$a slot core] getCell $wai $waj]
		set wbc [[$b slot core] getCell $wbi $wbj]

		if {[Object exists $wac] && [Object exists $wbc]} {
			$nop slot wai $wai
			$nop slot waj $waj

			$wave pushCell $wac
			$wave pushCell $wbc
			lappend next $nop [$wave newEnd] $prog
		} else {
			# prevent storage of result, but continue
			$nop slot wai ""
			$nop slot waj ""

			lappend next $nop
		}
	}

	return $next
}

# Undo by removing the answer and
# restoring the operands
#
OpMap2 method undoOp {wave} {
	return ""
}
