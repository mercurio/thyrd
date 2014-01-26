### A cell mask that views its cell as a path
###
#
# PJM	2006-03-30	Created
#
CellMask construct CMPath

# Return true if it's ok to call CMPath methods
# on this cell (if it's not atomic)
#
CMPath method ok {} {
	return [[$self slot core] isA Path]
}


## For each of these methods, call the corresponding
## Grid method on the core if we're not atomic.
## If we are atomic, do nothing.
##
foreach m {resolve followFrom} {
	CMPath method $m {args} [format {
		set x  [$self slot core]
		if {![$x isA Path]} return

		eval $x %s $args
	} $m]
}
