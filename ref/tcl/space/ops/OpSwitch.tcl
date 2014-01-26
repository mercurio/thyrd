### The ``switch`` operation
###
### Pops a grid off the stack containing a list of programs.
### Each is evaluated and a value is popped off the stack.
### Execution stops when the value is true. The last return
### value is left on the stack, so it will be true if one of
### the programs succeeded, false if they all failed.
###
#
# PJM 2009-03-03	Begun


Op construct OpSwitch

OpSwitch slot opcode "switch"
OpSwitch slot caption "switch"
OpSwitch slot iconlg [Thyrd getImage "op-switch-lg"]
OpSwitch slot iconsm [Thyrd getImage "op-switch-sm"]
OpSwitch slot icongl [Thyrd getImage "op-switch-gl"]
OpSwitch slot in {plist}
OpSwitch slot out {success}
OpSwitch slot tags {combinator}
OpSwitch slot help "Pop a grid containing a list of programs (plist). Evaluate each of the programs in turn, each should leave a return value that's popped off the stack. Stop evaluating programs from the list as soon as one returns a true value. Return the result of the last program evaluated (which will be false if they all failed)."
OpSwitch slot sidefx "Depends on programs provided as input"

# Switch between a list of programs.
#
OpSwitch method doOp {wave} {
	set virgin [$self slot virgin]

	if {$virgin} {
		if {![$wave shiftCellsToVars plist] || [$plist atomic]} {
			$wave slot error "Expected input: a grid containing a list of programs"
			return -code error
		}

		$wave saveX

		set nop [$self construct *]
		$nop slot virgin 0

		$nop slot plist $plist
		$nop slot walk [$plist as CMGrid walk contents]

		set next [$wave getNext]
	} else {
		set nop $self
		set plist [$nop slot plist]
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

	# Queue up next evaluation
				
	set wi [$nop slot wi [$nop slotPop walk]]
	set wj [$nop slot wj [$nop slotPop walk]]

	if {$wi eq "" || $wj eq ""} { ;# failure, we're done
		$wave pushTyped [list 0 <boolean>]
		return $next
	} else {	;# eval next grid
		set wc [[$plist slot core] getCell $wi $wj]
		if {[Object exists $wc]} {
			lappend next $nop [$wave newEnd] [$wc one]
		} else {
			lappend next $nop
		}
	}

	return $next
}

# Undo 
#
OpSwitch method undoOp {wave} {
	return ""
}
