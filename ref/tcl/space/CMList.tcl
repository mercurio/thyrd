### A cell mask that treats a grid cell as a list
#
# PJM	2006-04-30	Created
#

CellMask construct CMList

# Get the contents of the cell as a list, in normal
# raster order
#
CMList method getList {} {
	set out [list]

	foreach {wi wj} [$self as CMGrid walk] {
		lappend out [[$self as CMGrid getCell $wi $wj] get]
	}

	return $out
}

# Create and append a new cell with the given value and type.
# We grow in the i direction.
#
# The new cell is returned.
#
CMList method append {{val ""} {type Core}} {
	foreach {si sj} [$self size] break;

	# subtract frame
	incr si -1
	incr sj -1

	if {$si <= 0 && $sj <= 0} {
		set si 1
		set sj 1
	} else {
		incr si	
	}

	$self putTypeAt $val $type $si $sj

	return [$self as CMGrid getCell $si $sj]
}

# Given a cell, append it to the Grid
#
# The new cell is returned.
#
CMList method appendCell {c} {
	foreach {si sj} [$self size] break;

	# subtract frame
	incr si -1
	incr sj -1

	if {$si <= 0 && $sj <= 0} {
		set si 1
		set sj 1
	} else {
		incr si	
	}

	$self storeSub $c $si $sj
	return $c
}

# Given one of our data cells, delete its entire
# column.  Do nothing if there's no cell given or
# it's not one of ours.
#
CMList method delete {c} {
	if {$c eq ""} return
	if {[$self atomic]} return
	if {[$c slot container] ne $self} return

	$self as CMGrid delete column [$c slot i]
}
