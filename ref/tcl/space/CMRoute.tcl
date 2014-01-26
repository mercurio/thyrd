# A cell mask that treats a grid cell as a route, a list of
# paths.
#
# PJM	2006-03-30	Created
#

CellMask construct CMRoute

# Set the route to the given list of path strings
#
CMRoute method setRoute {args} {
	$self empty Grid

	set i 1
	foreach p $args {
		$self putTypeAt $p Path $i
		incr i
	}
}

# Apply the route to a cell or cell loc, attempting to resolve each
# path against the cell until we find another cell.  We
# return the found cell or "". Any empty cells we find
# we ignore, only when we exceed the limits of a grid
# do we return "".
#
# If we're provided with one arg and it's not a cell, return "".
#
CMRoute method apply {args} {
	set largs [llength $args]

	if {$largs == 1} {
		set c $args
		set g ""
		set i ""
		set j ""

		if {![Object existsAs $c Cell]} {return ""}
	} elseif {$largs == 3} {
		set c ""
		lassign $args g i j
	} else {
		return -error "Wrong # of arguments (1 or 3 required)"
	}

	set route [$self as CMGrid walk]
	set ri 0
	set rimax [- [llength $route] 2]

	while 1 {
		set sav [list $c $g $i $j]

		set rc [$self as CMGrid getCell [lindex $route $ri] [lindex $route [+ $ri 1]]]

		if {$c eq ""} {
			lassign [$rc as CMPath followFrom $g $i $j] c g i j
		} else {
			lassign [$rc as CMPath followFrom $c] c g i j
		} 

		if {$c ne ""} {return $c}

		if {$g eq ""} {	;# all nulls returned, exceeded boundaries of a grid
			if {$ri >= $rimax} { ;# no more paths to try
				return ""
			} else { ;# try next path, from where we left off
				incr ri 2
				lassign $sav c g i j
			}
		} else { ;# empty grid location, go back to first path of route
			set ri 0
		}
	}
}

# Return a list describing the route (list of paths)
#
CMRoute method asList {} {
	set out [list]

	foreach {wi wj} [$self as CMGrid walk] {
		set wc [$self as CMGrid getCell $wi $wj]
		if {$wc ne ""} {
			lappend out [$wc get]
		}
	}

	return $out
}
