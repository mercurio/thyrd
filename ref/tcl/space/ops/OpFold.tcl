### The ``fold`` operation
###
### Pops two grids off the stack, the first is a program
### to be evaluated on successive subsets of the cells in the second
### grid. The accumulated result is produced and left on the stack.
#
# PJM 2008-06-26	Begun
# PJM 2009-02-20	Continuable version begun

Op construct OpFold

OpFold slot opcode "fold"
OpFold slot caption "fold"
OpFold slot iconlg [Thyrd getImage "op-fold-lg"]
OpFold slot iconsm [Thyrd getImage "op-fold-sm"]
OpFold slot icongl [Thyrd getImage "op-fold-gl"]
OpFold slot in {a p}
OpFold slot out {p folded into a}
OpFold slot tags {combinator}
OpFold slot help "Pop a grid (a) and a program (p). Evaluate the program with the first two cells of a, then with the result and the next cell from a, until the end of a. The final result is pushed on the stack."
OpFold slot sidefx "Depends on program provided as input"

# Parameters for various fold operations

# How many stack items will p require
OpFold slot pIn 2
OpFold type pIn <integer>

# How many stack items will p leave behind
OpFold slot pOut 1
OpFold type pOut <integer>

# Index of first value in a to use
OpFold slot si	1
OpFold type si <integer>

OpFold slot sj	1
OpFold type sj <integer>

# Path to use to get to next value
OpFold slot nextRoute [list "+1" "-* +1"]

# Initialize an OpFold, once after it's been
# created. Any child ops can use this as well,
# just set nextRoute statically. Dynamically
# changing the next route is not supported, but
# it could be.
#
OpFold method _init {} {
	set n [$self slot nextRouteCell]
	if {$n ne ""} return
	
    set n [$self slot nextRouteCell [Cell new]]
	$n as CMRoute setRoute {*}[$self slot nextRoute]
}

# Start by gathering the args and creating the new op, and
# retrieving the starting cell.
#
OpFold method doOp {wave} {
	$self _init

	set si [$self slot si]
	set sj [$self slot sj]
	set nr [$self slot nextRouteCell]

	set virgin [$self slot virgin]

	if {$virgin} {
		if {![$wave shiftCellsToVars a prog] || [$a atomic] || [$prog atomic]} {
			$wave slot error "Expected inputs: a (grid) and prog (program)"
			return -code error
		}

		$wave saveX

		set c [$a subCell $si $sj]
		if {$c eq ""} {
			set c [$nr as CMRoute apply $a $si $sj]
			if {$c eq ""} {return ""}
		}

		set nop [$self construct *]
		$nop slot virgin 0

		$nop slot a $a
		set prog [$nop slot prog [$prog one]]

		$nop slot cell $c
		set need [$self slot pIn]

		set next [$wave getNext]
	} else {
		set nop $self
		set c [$nop slot cell]
		if {$c eq ""} {return ""}	;# we're done

		set a [$nop slot a]
		set prog [$nop slot prog]

		set need [- [$self slot pIn] [$self slot pOut]]

		set next ""
	}


	for {} {$need > 0 && $c ne ""} {incr need -1} {
		$wave pushCell $c
			
		set c [$nr as CMRoute apply $c]
	}

	if {$need > 0} {
		$wave slot error "Exhausted grid $a early, needed $need more"
		return -code error 
	}

	$nop slot cell $c

	lappend next $nop [$wave newEnd] $prog
	return $next
}

# Undo by removing the answer and
# restoring the operands
#
OpFold method undoOp {wave} {
	return ""
}

# Reference version, old style
# Initialize an OpFold, once after it's been
# created
#
OpFold method reference_init {} {
	set n [$self slot _next]
	if {$n ne ""} return
	
    set n [$self slot _next [Cell new]]
	$n as CMRoute setRoute {*}[$self slot nextRoute]
}

# Reference version, old style
# Perform the operation on the given wave
#
OpFold method reference-doOp {wave} {
	$self reference_init

	if {![$wave shiftCellsToVars a prog]} {
		return -code error "Need two cells on stack [$wave slot stack]"
	}

	if {[$a atomic]} {
		return -code error "Input 'a' ($a) is not a grid"
	}

	if {[$prog atomic]} {
		return -code error "Input 'prog' ($prog) is not a grid"
	}

	set n [$self slot _next]
	set i [$self slot si]
	set j [$self slot sj]
	set c [$a subCell $i $j]

	if {$c eq ""} {
		set c [$n as CMRoute apply $a $i $j]
		if {$c eq ""} {
			return -code error "No cells found in grid $a"
		}
	}

	$wave saveX

	set in [$self slot pIn]
	set out [$self slot pOut]
	set reload [- $in $out]

	while {$c ne ""} {
		$wave pushCell $c
		incr in -1

		if {$in <= 0} {
			$wave subroutine $prog
			set in $reload
		}
			
		set c [$n as CMRoute apply $c]
	}

	if {$in != $reload} {
		return -code error "Exhausted grid $a early, needed $in more"
	}

	return ""
}
