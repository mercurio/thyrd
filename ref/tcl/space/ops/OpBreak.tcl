### The ``break`` operation. The first time we
### return a break code, after that we proceed 
### normally.
#
# PJM 2007-08-03	Created
# PJM 2009-02-24	Continuable version

Op construct OpBreak

OpBreak slot opcode "break"
OpBreak slot caption "break"
OpBreak slot iconlg [Thyrd getImage "op-break-lg"]
OpBreak slot iconsm [Thyrd getImage "op-break-sm"]
OpBreak slot icongl [Thyrd getImage "op-break-gl"]
OpBreak slot in {}
OpBreak slot out {}
OpBreak slot tags {flow}
OpBreak slot help "Pause the wave at this cell, allowing the user to inspect it, add code, etc."
OpBreak slot sidefx "Pauses wave" 

# When this op is encountered, signal a breakpoint
#
OpBreak method doOp {wave} {
	set v [$self slot virgin]

	if {$v} {
		$wave saveX

		set nop [$self construct *]
		$nop slot virgin 0
		$nop slot next [$wave getNext]
		set oc [$nop slot opcell [$wave slot currentOp]]

		$oc paused 1
		$wave slot state break

		set next [$wave newEnd]
		lappend next $nop
	} else {
		set oc [$self slot opcell]
		$oc paused 0

		set next [$self slot next]
	}

	return $next
}

# Undo does the same thing
#
OpBreak method undoOp {wave} {
	return -code break
}
