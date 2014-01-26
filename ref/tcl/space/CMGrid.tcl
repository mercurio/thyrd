### A cell mask that views its cell as a grid
###
#
# PJM	2006-03-30	Created
#
CellMask construct CMGrid

# Return true if it's ok to call CMGrid methods
# on this cell (if it's not atomic)
#
CMGrid method ok {} {
	return [expr {![$self atomic]}]
}


## For each of these methods, call the corresponding
## Grid method on the core if we're not atomic.
## If we are atomic, do nothing.
##
foreach m {setCell getCell hasCell findIFrame findJFrame walk hasFrameValues delete complete} {

	CMGrid method $m {args} [format {
		if {[$self atomic]} return

		eval [$self slot core] %s $args
	} $m]
}

## For each of these methods, delegate to Grid and
## also notify observers.
##
foreach m {addColumns addRows deleteColumns deleteRows} {

	CMGrid method $m {args} [format {
		if {[$self atomic]} return

		eval [$self slot core] %s $args

		$self notifyObservers write
	} $m]
}
