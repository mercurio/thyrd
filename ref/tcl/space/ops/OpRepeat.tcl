### The ``repeat`` operation
#
# PJM 2008-10-16	Created
# PJM 2009-02-17	Work on continuable version begun

Op construct OpRepeat

OpRepeat slot opcode "repeat"
OpRepeat slot caption "repeat"
OpRepeat slot iconlg [Thyrd getImage "op-repeat-lg"]
OpRepeat slot iconsm [Thyrd getImage "op-repeat-sm"]
OpRepeat slot icongl [Thyrd getImage "op-repeat-gl"]
OpRepeat slot in {p n}
OpRepeat slot out {}
OpRepeat slot tags {combinator}
OpRepeat slot help "Pop a cell p and a value n and evaluate p n times"
OpRepeat slot sidefx "Depends on contents of p"

# Perform the operation on the given wave
#
OpRepeat method doOp {wave} {
	set v [$self slot virgin]

	if {$v} {
		$wave shiftCellsToVars p nc
		$wave saveX

		set n [$nc get]
		set p [$p one]
		set next [$wave getNext]
	} else {
		set n [$self slot n]
		set p [$self slot p]
		set next ""
	}

	# Nothing to do
	if {$n <= 0} {return $next}

	if {$n == 1} { ;# just eval once
		lappend next [$wave newEnd] $p
	} else { ;# not a degenerate case, queue up new op
		if {$v} {
			set nop [$self construct *]
			$nop slot virgin 0
			$nop slot p $p
		} else {
			set nop $self
		}

		$nop slot n [- $n 1]
		lappend next $nop [$wave newEnd] $p
	}

	return $next
}

# Undo
#
OpRepeat method undoOp {wave} {
	return ""
}
