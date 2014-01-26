# A grid nucleus for a Cell.  A grid is a matrix consisting
# of frame cells (i == 0 || j == 0) and contents cells.
#
# The primary operations for cells in a grid are set, get, and has.
# Each can take either numeric or string indexes for i or j, a string
# index is looked for in the i or j frame and translated into the
# numeric index of the corresponding frame cell.  Set causes new
# frame cells to be created and the whole matrix to be expanded to
# accommodate new contents, as needed.  Get returns the cell at 
# the given coords, or an empty string if there is no cell at that
# location or if the indexes are out of bounds.  Has returns true
# or false, depending on whether the coords map to a cell or not.
#
# A Grid is a Core, the serialization of the matrix is stored
# in the value slot.
#
# Note that Grid does not allow itself to be instantiated without
# an enclosing Cell.
#
# PJM 2005-07-28	Created 
# PJM 2005-10-20	Now derived from Core
# PJM 2006-05-25	walk redone
# PJM 2007-07-17	we no longer enforce complete grids, a grid may have
#					non-existent cells
# PJM 2008-10-31	Added support for import/export
#
# This needs to be preloaded (all Core children do):
::Poet::Preload Thyrd


Core construct Grid
catch {Grid unparent Thing}	;# this object is not persistent, its kids are

# Private slot containing matrix id, made persistent
# by Thing_put{} below.  The matrix id is not persistent,
# but the contents of the matrix are.
#
Grid slot _mat {}

##
## Core API
##
## Note that set and get aren't used except in loading/saving.
## Accessing the contents of the grid is done via setCell/getCell.
##

# How to display this sort of core.
Grid slot displayKey "grid"


# We can't make a grid without a cell, so override new
# to complain if used.
#
Grid method new {args} {
	UserMsg error "|$self new $args| Grids cannot be made without an enclosing cell, use newInCell{} instead"
}

# When we destruct, we destroy all our cells
#
Grid method destruct {} {
	foreach {wi wj} [$self walk full] {
		Object safe [$self getCell $wi $wj] destruct
	}
	$self as [Grid parent] destruct
}

# Set the value, deserializing the matrix
#
Grid method set {value} {
	$self slot value $value
	$self _deserialize

	return $value
}

# Get the value
#
Grid method get {} {
	$self _serialize
	return [$self slot value]
}

# Return true if this core is atomic (not a Grid).
#
Grid method atomic {} {
	return 0
}

# Get the textual representation of this
# core.  Note that we use the contents size,
# not the full size, of the grid.
#
Grid method getText {} {
	set m [$self _getMatrix]

	return "([- [$m columns] 1]x[- [$m rows] 1] grid)"
}

# Print a grid to stdout
#
Grid method print {} {
	set m [$self _getMatrix]

	puts "$self: [$m columns] x [$m rows]"
	$m format 2chan
	puts ""
}

##
## Persistence
##

# Override Thing_put to serialize matrix first.
#
Grid method Thing_put {dir} {
	$self slot value [[$self _getMatrix] serialize]

	return [$self as Thing Thing_put $dir]
}

# Override Thing_postload to deserialize the matrix after
# a grid has been loaded from persistent storage.  Once
# we deserialize the matrix, we visit each cell to cause it
# to be autoloaded.
#
Grid method Thing_postload {} {
	set m [$self _deserialize]

	foreach {wi wj} [$self walk full] {
		set a [$self getCell $wi $wj]
		if {$a ne ""} {$a noop}
	}

	$self _syncFrameArrays $m

	$self as Thing Thing_postload
}

# Export this object as a string that can be written
# to a file with other exported objects.
# Similar to the Thing support, except that we
# assume no autoloading.
#
Grid method export {} {
	$self slot value [[$self _getMatrix] serialize]

	return "[$self serialize]\n$self import"
}

# Called after we've been loaded from an export
# file. Again, no autoloading is available in this
# case, we assume all our components are also in
# the same file. They'll all have been loaded by
# the time the ``doLater`` commands are run, that's
# when we can safely sync the frame arrays.
#
Grid method import {} {
	set m [$self _deserialize]

	Exportable doLater "$self _syncFrameArrays $m"
}

# Deserialize the matrix and return it.
#
#OLD We also guarantee that new matrixes are
# initialized with the zero cell.
#
Grid method _deserialize {} {
	catch {mat_$self destroy}
	return [$self slot _mat [::struct::matrix mat_$self deserialize [$self slot value]]]
}

# Serialize the matrix
#
Grid method _serialize {} {
	$self slot value [[$self _getMatrix] serialize]
}

# Get the matrix id, creating the matrix if necessary.  
#
Grid method _getMatrix {} {
	set m [$self slot _mat]
	if {$m eq ""} {  
		set m [$self _deserialize]
		$self _syncFrameArrays $m
	}

	return $m
}

# Given an index and endi and endj values, substitute for endi
# and endj everywhere and evaluate
#
Grid method _endIJsub {x endi endj} {
	set x [regsub -all {endi} $x $endi]
	set x [regsub -all {endj} $x $endj]
	set x [expr $x]
	return [expr ($x > 0) ? $x : 0]
}


# Iterate over the grid using the variables by outputting a list of
# pairs, meant to be used as:
#
#	``foreach {wi wj} [$grid walk] { ... body ... }
#
# The first argument specifies what portion of the grid should
# be walked, default is the contents. The valid keywords are:
# ``
#	all or full		The complete grid, including the frames
#	contents		All of the contents (i >= 1 && j >= 1)
#	iframe			j = 0
#	jframe			i = 0
#	frame			both frames (0 cell only once)
#
# The second argument should be i or j, indicating the fastest incrementing
# index, with i as the default.  
#
# what is either a single token or a list of 4 expressions: i0 j0 i1 j1.
#
# Split off most of the work to walkmat so that it can be used with
# other matrixes.
#
Grid method walk {args} {
	return [eval $self walkmat [$self _getMatrix] $args]
}

# Workhorse method for ``walk``.  This can be used on
# any ``::struct::matrix`` via ``Grid walkmat $mat $args``
#
# Note that the error message still looks like it comes from walk.
#
Grid method walkmat {m args} {
	set what contents
	set fastest i

	set output [list]

	switch [llength $args] {
		0 {}
		1 { set what [lindex $args 0]}
		2 {
			lassign $args what fastest
		}
		default {
			UserMsg error "|$self walk $args| Invalid arguments to Grid walk (or walkmat)"
		}
	}

	set endi [expr [$m columns] -1]
	set endj [expr [$m rows] -1]

	if {$endi < 0 || $endj < 0} {return ""}

	# Set up i0 j0 and i1 j1 from the given range
	#
	if {[llength $what] == 4} {
		lassign $what i0 j0 i1 j1
	} else {
		switch $what {
			contents {
				set i0 1
				set i1 endi
				set j0 1
				set j1 endj
			}
			iframe {
				set i0 1
				set i1 endi
				set j0 0
				set j1 0
			}
			jframe {
				set i0 0
				set i1 0
				set j0 1
				set j1 endj
			}
			frame {  
				# First zero cell, then the i and j frames
				set wi 0
				set wj 0

				# Note that we don't do the walk below in this case
				if {$fastest eq "i"} {
					return [concat $wi $wj [$self walk iframe] [$self walk jframe]]
				} else {
					return [concat $wi $wj [$self walk jframe] [$self walk iframe]]
				}
			}
			all -
			full {
				set i0 0
				set i1 endi
				set j0 0
				set j1 endj
			}
			default {
				UserMsg error "|$self walk $args| Unrecognized selector $what"
			}
		}
	}

	# Replace the expressions with their values
	#
	set i0 [Grid _endIJsub $i0 $endi $endj]
	set j0 [Grid _endIJsub $j0 $endi $endj]
	set i1 [Grid _endIJsub $i1 $endi $endj]
	set j1 [Grid _endIJsub $j1 $endi $endj]

	# Compute the walk list
	#

	if {$fastest eq "i"} {
		for {set wj $j0} {$wj <= $j1} {incr wj} {
			for {set wi $i0} {$wi <= $i1} {incr wi} {
				lappend output $wi $wj
			}
		}
	} else {
		for {set wi $i0} {$wi <= $i1} {incr wi} {
			for {set wj $j0} {$wj <= $j1} {incr wj} {
				lappend output $wi $wj
			}
		}
	}

	return $output
}

# Sync the frame arrays _iframe and _jframe with
# the contents of the grid frame.  We're provided
# with the matrix name.
#
# We might sync only one frame array.
#
# We also attach observers to resync if the cells
# change. (Note: observers now added by ``_placeCell``)
#
Grid method _syncFrameArrays {m {which "both"}} {
	if {$which eq "both" || $which eq "i"} {
		$self arrayClear _iframe
		foreach {wi wj} [$self walk iframe] {
			set wc [$self getCell $wi $wj]
			set s [Object safe $wc get]
			if {$s ne ""} {
				$self arraySet _iframe $s $wi
			}

		}
	}

	if {$which eq "both" || $which eq "j"} {
		$self arrayClear _jframe
		foreach {wi wj} [$self walk jframe] {
			set wc [$self getCell $wi $wj]
			set s [Object safe $wc get]
			if {$s ne ""} {
				$self arraySet _jframe $s $wj
			}
		}
	}
}

# Called when an i frame cell changes
#
Grid method iFrameChanged {args} {
	$self _syncFrameArrays [$self _getMatrix] i
}

# Called when a j frame cell changes
#
Grid method jFrameChanged {args} {
	$self _syncFrameArrays [$self _getMatrix] j
}

# Called when both frames (or unknown frame) change
#
Grid method framesChanged {} {
	$self _syncFrameArrays [$self _getMatrix] 
}

# Return true if the given frame contains
# values.  We assume _syncFrameArrays has 
# been called since any changes.
#
Grid method hasFrameValues {which} {
	set slotname "_${which}frame"

	return [expr {[$self arraySize $slotname] > 0}]
}

# Return the size in the i and j dimensions, including
# the frame.
#
Grid method size {} {
	set m [$self _getMatrix]
	return [list [$m columns] [$m rows]]
}
	
# Given a i frame index, find the corresponding numerical
# index.  If it's already numerical, just return it.
# Otherwise, return -1 if it's not found.  We assume that
# ``_iframe`` is accurate.
#
# If the index is ``{}``, we return 0.
#
# Use ``_forceIFrame`` to create a frame cell that
# doesn't exist yet.
#
Grid method findIFrame {i} {
	if {$i eq ""} {
		return 0
	} elseif {[string is integer $i]} {
		return $i
	} elseif {[$self arrayHas _iframe $i]} {
		return [$self arrayGet _iframe $i]
	} else {
		return -1
	}
}

# Given a i frame index, find the corresponding numerical
# index.  If it's already numerical, just return it.
# Add the string index if it's not found. We assume that
# ``_iframe`` is accurate.
#
# If the index is ``{}``, we return 0.
#
# This leaves the matrix in an incomplete state, since
# it calls ``_nsetCell``
#
Grid method _forceIFrame {i} {
	set f [$self findIFrame $i]
	if {$f != -1} {return $f}

	set m [$self _getMatrix]
	set ni [$m columns]
	if {$ni < 1} {set ni 1}

	set c [Cell new $i Core]
	$self _nsetCell $c $ni 0 
	$self arraySet _iframe $i $ni

	return $ni
}

# Given a j frame index, find the corresponding numerical
# index.  If it's already numerical, just return it.
# Otherwise, return -1 if it's not found.  We assume that
# ``_jframe`` is accurate.
#
# We're also given the numerical i coord (``ni``).
# If the index is ``{}``, the correct
# value depends on ni (if i > 0, j should be 1).
#
Grid method findJFrame {j {ni 0}} {
	set m [$self _getMatrix]

	if {$j eq ""} {
		if {$ni == 0} {
			return 0
		} else {
			return 1
		}
	} elseif {[string is integer $j]} {
		return $j
	} elseif {[$self arrayHas _jframe $j]} {
		return [$self arrayGet _jframe $j]
	} else {
		return -1
	}
}
	
# Given a j frame index, find the corresponding numerical
# index.  If it's already numerical, just return it.
# Add the string index if it's not found. We assume that
# ``_jframe`` is accurate.
#
# We're also given the numerical i coord (``ni``).
# If the index is ``{}``, the correct
# value depends on ni (if i > 0, j should be 1).
#
# Leaves the matrix incomplete if a new frame cell is made.
#
Grid method _forceJFrame {j {ni 0}} {
	set f [$self findJFrame $j $ni]
	if {$f != -1} {return $f}

	set m [$self _getMatrix]

	set nj [$m rows]
	if {$nj < 1} {set nj 1}
				
	set c [Cell new $j Core]
	$self _nsetCell $c 0 $nj
	$self arraySet _jframe $j $nj

	return $nj
}
	

# Set a cell in the matrix, expanding the matrix as needed.
# The arguments may be integers or strings or a combination.
# If they are strings we look them up in the frame row and/or
# column, or add them if necessary.
#
# We return the numeric coordinates of the cell.
#
Grid method setCell {cell i j} {
	set ni [$self _forceIFrame $i]
	set nj [$self _forceJFrame $j $ni]
			
	set coords [$self _nsetCell $cell $ni $nj]
	# incomplete grids allowable now   $self complete

	return $coords
}

# Get a cell from the matrix.  If the matrix isn't
# big enough, return an empty string.  If one or both
# indexes are strings and they're not present, return
# an empty string.
#
Grid method getCell {i j} {
	set ni [$self findIFrame $i]
	if {$ni < 0} {return ""}

	set nj [$self findJFrame $j $ni]
	if {$nj < 0} {return ""}

	return [$self _ngetCell $ni $nj]
}

# Return true if the given cell is in the matrix,
# false otherwise.
#
Grid method hasCell {i j} {
	return [expr [$self getCell $i $j] ne ""]
}

# Set a cell in the matrix, expanding the matrix as needed,
# given numerical coordinates.  The matrix is left incomplete,
# ``$self _complete`` needs to be called to clean up (if you
# want a complete grid).
#
# If there is a cell already there, we destroy it.
# Note that we also tell the new cell it's at a new location.
#
# We return the coordinates at which the cell was set.
#
# It's possible that the cell is null, in which case we
# just clear that location in the grid.
#
Grid method _nsetCell {cell i {j ""}} {
	if {$j eq ""} {
		set j [expr ($i == 0) ? 0 : 1]
	}

	set m [$self _getMatrix]

	set ni [$m columns]
	set nj [$m rows]

	if {$i >= $ni || $j >= $nj} {
		if {$i >= $ni} {
			$m add columns [expr {$i - $ni + 1}]
		}

		if {$j >= $nj} {
			$m add rows [expr {$j - $nj + 1}]
		}
	} else {
		set oc [$m get cell $i $j]
		if {$oc ne ""} {$oc destruct}
	}

	$self _placeCell $m $cell $i $j

	return [list $i $j]
}


# Scan the matrix, filling in any empty spots with
# new empty cells.  Cleans up after ``_nsetCell``,
# ``_force?Frame``.
#
# Incomplete grids are OK now, so this is now public.
#
Grid method complete {} {
	set m [$self _getMatrix]

	foreach {wi wj} [$self walk full] {
		set wc [$m get cell $wi $wj]
		if {$wc eq ""} {
			$self _placeCell $m [Cell new] $wi $wj
		}
	}
}

# Place a cell in the matrix, given numeric coordinates.
# If it's a frame cell, we attach an observer.  We assume
# there is no cell already located at these coords.
#
# We tell the containing cell to notify its observers that
# it's gained a sub cell.
#
# It's possible that the cell is null, in which case we
# just clear that location in the grid.
#
#
Grid method _placeCell {m c i j} {
	$m set cell $i $j $c
	if {$c eq ""} return

	$c relocate [$self slot container] $i $j

	if {$j == 0 && $i > 0} {$c addObserver write $self iFrameChanged}
	if {$i == 0 && $j > 0} {$c addObserver write $self jFrameChanged}
}

# Get a cell from the matrix.  If the matrix isn't
# big enough, return an empty string.  If the 
# matrix is big enough but there's no cell there,
# return an empty string.
#
# Assumes the coords are numerical, use get{} for normal uses.
#
Grid method _ngetCell {i {j ""}} {
	if {$j eq ""} {
		set j [expr ($i == 0) ? 0 : 1]
	}

	set m [$self _getMatrix]

	set ni [$m columns]
	set nj [$m rows]

	if {$i >= $ni || $j >= $nj} {
		return ""
	}

	set c [$m get cell $i $j]
	
	return $c
}

# Given a list describing a section of the grid,
# set the variables i0 j0 i1 j1 to the coordinate range
# and rangeType to the type, uplevel 1.
#
# If the list is only one element, it must be all,
# contents, iframe, or jframe.
# If the list has 4 elements, it is
# the 4 coordinates specified explicitly.  Otherwise,
# the first word should be ``r(ow)`` or ``c(olumn)``,
# followed by either one or two indices.
#
Grid method range2vars {range} {
	set n [llength $range]

	if {$n == 1} {
		uplevel [list set rangeType $range]
		switch $range {
			all {
				uplevel [list set i0 0]
				uplevel [list set j0 0]
				uplevel [list set i1 endi]
				uplevel [list set j1 endj]
			}
			contents {
				uplevel [list set i0 1]
				uplevel [list set j0 1]
				uplevel [list set i1 endi]
				uplevel [list set j1 endj]
			}
			iframe {
				uplevel [list set i0 1]
				uplevel [list set j0 0]
				uplevel [list set i1 endi]
				uplevel [list set j1 0]
			}
			jframe {
				uplevel [list set i0 0]
				uplevel [list set j0 1]
				uplevel [list set i1 0]
				uplevel [list set j1 endj]
			}
		}
	} elseif {[llength $range] == 4} {
		uplevel [list set rangeType "box"]
		uplevel [list set i0 [lindex $range 0]]
		uplevel [list set j0 [lindex $range 1]]
		uplevel [list set i1 [lindex $range 2]]
		uplevel [list set j1 [lindex $range 3]]
	} else {
		foreach {what a b} $range break

		switch -glob $what {
			c* {
				if {$a eq ""} {UserMsg error "|$self range2vars $args| Usage: column|row a \[b\]"}
				uplevel [list set rangeType "column"]
				uplevel [list set i0 $a]
				uplevel [list set j0 0]
				uplevel [list set j1 endj]

				if {$b eq ""} {
					uplevel [list set i1 $a]
				} else {
					uplevel [list set i1 $b]
				}
			}
			r* {
				if {$a eq ""} {UserMsg error "|$self range2vars $args| Usage: column|row a \[b\]"}
				uplevel [list set rangeType "row"]
				uplevel [list set j0 $a]
				uplevel [list set i0 0]
				uplevel [list set i1 endi]

				if {$b eq ""} {
					uplevel [list set j1 $a]
				} else {
					uplevel [list set j1 $b]
				}
			}
		}
	}
}

# Delete a section of the grid.  The section may be larger
# than the grid, we just ignore out of bound cells.
#
# Columns and rows are indexed starting with 0,
# one number means delete that (column/row),
# two mean delete from start to end inclusive.
#
Grid method delete {args} {
	$self range2vars $args

	set m [$self _getMatrix]
	set mi [$m columns]
	set mj [$m rows]

	foreach {wi wj} [$self walk [list $i0 $j0 $i1 $j1]] {
		if {$wi < $mi && $wj < $mj} {
			Object safe [$m get cell $wi $wj] destruct
			$m set cell $wi $wj ""
		}
	}

	# When we cut out a box, we fill in empty cells
	# When rows or columns are deleted, we reduce
	# the rows or columns of the matrix
	#
	switch -glob $rangeType {
		box {
			# now we leave a hole   $self complete
		}
		c* {
			for {set c $i1} {$c >= $i0} {incr c -1} {
				$m delete column $c
			}

			foreach {wi wj} [$self walk [list $i0 0 endi endj]] {
				set wc [$m get cell $wi $wj]
				if {$wc ne ""} {
					$wc relocate [$self slot container] $wi $wj
				}
			}
		}
		r* {
			for {set r $j1} {$r >= $j0} {incr r -1} {
				$m delete row $r
			}

			foreach {wi wj} [$self walk [list 0 $j0 endi endj]] {
				set wc [$m get cell $wi $wj]
				if {$wc ne ""} {
					$wc relocate [$self slot container] $wi $wj
				}
			}
		}
	} 
}

# Given a range, produce a list of all the subcells in the range
# and below, all the way down. The second argument is the object
# to use for output, we set slots with the cell IDs and 0 as value.
#
Grid method listAllSubs {range out} {
	$self range2vars $range

	foreach {wi wj} [$self walk [list $i0 $j0 $i1 $j1]] {
		set wc [$m get cell $wi $wj]
		if {$wc ne ""} {
			$out slot $wc 0
			if {[!$wc atomic]} {
				[$wc slot core] listAllSubs all $out
			}
		}
	}

	return $out
}

# Add n columns to the grid after column i.  We iterate over the new
# area to place empty cells everywhere. Then we iterate over
# the moved cells to resituate them.
#
# If leaveEmpty is true, don't fill the column (we're about to
# paste something in). If the global option autofill is off, we
# also leave it empty.
#
Grid method addColumns {i {n 1} {leaveEmpty 0}} {
	set m [$self slot _mat]
	if {![Options get autofill]} {
		set leaveEmpty 1
	}

	set nc [$m columns]

	if {$i >= $nc - 1} {
		set i0 $nc
		set i1 [+ $nc $n -1]
		set in 0
		$m add columns $n
	} else {
		set i0 [+ $i 1]
		set i1 [+ $i $n]
		set in [+ $i1 1]

		for {set a 0} {$a < $n} {incr a} {
			$m insert column $i0
		}
	}

	if {!$leaveEmpty} {
		foreach {wi wj} [$self walk [list $i0 0 $i1 endj]] {
			$self _placeCell $m [Cell new] $wi $wj
		}
	}

	if {$in != 0} {
		set gc [$self slot container]
		foreach {wi wj} [$self walk [list $in 0 endi endj]] {
			set c [$m get cell $wi $wj]
			if {$c ne ""} {
				$c relocate $gc $wi $wj
			}
		}
	}

	$self _syncFrameArrays $m i
}

# Add n rows to the grid after row j.  We iterate over the new
# area to place empty cells everywhere. 
#
# If leaveEmpty is true, don't fill the column (we're about to
# paste something in). If the global option autofill is off, we
# also leave it empty.
#
Grid method addRows {j {n 1} {leaveEmpty 0}} {
	set m [$self slot _mat]
	if {![Options get autofill]} {
		set leaveEmpty 1
	}

	set nr [$m rows]

	if {$j >= $nr - 1} {
		set j0 $nr
		set j1 [+ $nr $n -1]
		set jn 0
		$m add rows $n
	} else {
		set j0 [+ $j 1]
		set j1 [+ $j $n]
		set jn [+ $j1 1]

		for {set a 0} {$a < $n} {incr a} {
			$m insert row $j0
		}
	}

	if {!$leaveEmpty} {
		foreach {wi wj} [$self walk [list 0 $j0 endi $j1]] {
			$self _placeCell $m [Cell new] $wi $wj
		}
	}

	if {$jn != 0} {
		set gc [$self slot container]
		foreach {wi wj} [$self walk [list 0 $jn endi endj]] {
			set c [$m get cell $wi $wj]
			if {$c ne ""} {
				$c relocate $gc $wi $wj
			}
		}
	}

	$self _syncFrameArrays $m j
}

# Delete columns starting at i for n columns, deleting
# the cells as we go.  We then relocate those right of
# the deleted area.
#
Grid method deleteColumns {i {n 1}} {
	set i1 [+ $i $n -1]
	foreach {wi wj} [$self walk [list $i 0 $i1 endj]] {
		Object safe [$self getCell $wi $wj] destruct
	}

	set m [$self slot _mat]

	for {set c $i1} {$c >= $i} {incr c -1} {
		$m delete column $c
	}

	set gc [$self slot container]
	foreach {wi wj} [$self walk [list $i 0 endi endj]] {
		set c [$m get cell $wi $wj]
		if {$c ne ""} {
			$c relocate $gc $wi $wj
		}
	}

	$self _syncFrameArrays $m i
}


# Delete rows starting at j for n rows, deleting
# the cells as we go.
#
Grid method deleteRows {j {n 1}} {
	set j1 [+ $j $n -1]
	foreach {wi wj} [$self walk [list 0 $j endi $j1]] {
		Object safe [$self getCell $wi $wj] destruct
	}

	set m [$self slot _mat]

	for {set r $j1} {$r >= $j} {incr r -1} {
		$m delete row $r
	}

	set gc [$self slot container]
	foreach {wi wj} [$self walk [list 0 $j endi endj]] {
		set c [$m get cell $wi $wj]
		if {$c ne ""} {
			$c relocate $gc $wi $wj
		}
	}

	$self _syncFrameArrays $m j
}

# Given a cell or placeholder, return the coords as
# a list.  Ignores ``$self``.
#
Grid method copCoords {cop} {
	set i {}
	set j {}

	if {[Object available $cop]} {
		set i [$cop slot i]
		set j [$cop slot j]
	} else {
		if {![regexp {i(\d*)j(\d*)} $cop -> i j]} {
			UserMsg error "|$self copCoords $cop| $cop is not a placeholder"
		}
	}

	return [list $i $j]
}

# Return either a subcell, or, if it doesn't exist,
# a placeholder consisting of the coords preceeded by
# ``i`` and ``j``.
#
# ``CoP`` refers to Cell or Placeholder.
#
Grid method getCoP {i j} {
	set sc [$self getCell $i $j]
	if {$sc ne ""} {return $sc} else {return "i${i}j${j}"}
}

# Given two placeholders, return the enclosed
# range as four coords.
#
Grid method selRange {s0 s1} {
	regexp {i(\d*)j(\d*)} $s0 -> s0i s0j
	regexp {i(\d*)j(\d*)} $s1 -> s1i s1j
	
	return [list [min $s0i $s1i] [min $s0j $s1j] \
		[max $s0i $s1i] [max $s0j $s1j]]
}
