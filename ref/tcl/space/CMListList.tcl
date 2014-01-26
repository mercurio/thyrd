### A cell mask that treats a grid cell as a list of lists
#
# PJM	2008-10-17	Created
#

CellMask construct CMListList

# Get the contents of the cell as a list of lists, in normal
# raster order (j lists of i elements each)
#
CMListList method getListList {} {
	set out [list]

	set x [$self slot core]
	lassign [$x size] si sj
	incr si -1

	for {set j 1} {$j < $sj} {incr j} {
		set row [list]
		foreach {wi wj} [$x walk [list 1 $j $si $j]] {
			lappend row [[$x getCell $wi $wj] get]
		}

		lappend out $row
	}

	return $out
}

# Set the contents of the grid from a list of lists
#
CMListList method setListList {in} {
	set j 1
	
	foreach row $in {
		set i 1
		foreach c $row {
			$self subCell! $i $j $c <string> true
			incr i
		}

		incr j
	}
}
