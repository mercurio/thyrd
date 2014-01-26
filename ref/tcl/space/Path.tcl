# A Core representing a Thyrd path.  Internally, a
# path is a list of the component steps.
# 
# This can also be used seperately from a cell,
# as a means of parsing paths.
#
# A path is a list of lists, each of which has 0, 1, or 2
# items.  A 0-item list is at the beginning of absolute
# paths and at the end of paths whose string representations
# end in /
#
# The string representation of a path consists of the steps
# separated by /s.  Embedded spaces, tabs, and /'s can be
# protected either by enclosing in double quotes or via \s.
# Double quotes or backslashes can be escaped by \s.
# Below are some sample text paths followed by their conversion
# to list format, that list turned back into a string, and that
# string turned back into a list:
#``
# /foo \\bar/"ex\"ample/" bar/"foo bar " b\/az/foo\ bar/
#   {} {foo {\bar}} {ex\"ample/ bar} {{foo bar } b/az} {{foo bar}} {}
#   /foo \\bar/ex\"ample\/ bar/foo\ bar\  b\/az/foo\ bar/
#   {} {foo {\bar}} {ex\"ample/ bar} {{foo bar } b/az} {{foo bar}} {}
# 
# /foo bar/"example/" bar/"foo bar " baz/
#   {} {foo bar} {example/ bar} {{foo bar } baz} {}
#   /foo bar/example\/ bar/foo\ bar\  baz/
#   {} {foo bar} {example/ bar} {{foo bar } baz} {}
# 
# ../foo bar
#   .. {foo bar}
#   ../foo bar
#   .. {foo bar}
# 
# -* -*/foo/bar/
#   {-* -*} foo bar {}
#   -* -*/foo/bar/
#   {-* -*} foo bar {}
# 
# foo\ bar/
#   {{foo bar}} {}
#   foo\ bar/
#   {{foo bar}} {}
#``
# The first step of a path, if it begins with @,
# is simply the Poet object name of a cell.  If there are no more steps,
# it is a direct path (the path and the name of the cell are the same).
# Direct paths are also absolute paths.  
#
# PJM	2005-08-25	Created
# PJM	2005-10-20	Now derived from Core
# PJM	2007-08-21	Paths may have a direct path as first step
#
# This needs to be preloaded (all Core children do):
::Poet::Preload Thyrd

Core construct Path
catch {Path unparent Thing}	;# this object is not persistent, its kids are

# Slot containing the parsed path 
Path slot steps {}

# Slot containing the cell we reference, if we're an absolute path
Path slot cell {}


# Create a new, non-persistent Path for computation
# (not as a Core in a Cell).
#
# Note that new paths are not resolved.
#
Path method newVolatile {{value ""}} {
	set kid [$self construct *]
	catch {$kid unparent Thing}

	$kid slot container ""
	$kid set $value

	return $kid
}

##
## Core API
##

# Set the value of this path. We trim the value,
# since leading or trailing whiespace is meaningless.
#
Path method set {value} {
	set value [string trim $value]
	$self slot value $value
	$self slot steps [$self fromString $value]
	
	$self slot cell {}
}

# Print a path to stdout for debugging
#
Path method print {} {
	puts "$self: [$self slot value]"
	puts "  [join [$self slot steps] \n]"
}


# Update the value of this path (call if the steps have been
# manipulated)
#
Path method update {} {
	return [$self slot value [$self toString [$self slot steps]]]
}

# Returns true if this is a null path
#
Path method isNull {} {
	return [expr [$self slotLength steps] == 0]
}

# Returns number of steps
#
Path method nSteps {} {
	return [$self slotLength steps]
}

# Returns true if this is a direct path
#
# See also the setting of ``s0direct`` in ``followFrom``
#
Path method isDirect {} {
	#expr {[$self slotLength steps] == 1 && [string match "@*" [$self slotIndex steps 0]]}
	#expr {[$self slotLength steps] == 1 && [Object existsAs [$self slotIndex steps 0] Cell]}
	expr {[$self slotLength steps] == 1 && [regexp {^limbo@.*|^@.*} [$self slotIndex steps 0]]}
}

# Returns true if this is an absolute path
#
Path method isAbsolute {} {
	#expr {[$self slotIndex steps 0] eq "" || [string match "@*" [$self slotIndex steps 0]]}
	expr {[$self slotIndex steps 0] eq "" || [regexp {^limbo@.*|^@.*} [$self slotIndex steps 0]]}
}

# Given a path string, return a path (a list of places).  If there's only
# one step, and it begins with @, it's a direct path.
#
# DEFERRED: should the @ be escapable?  Right now, "@1234" should work.
#
Path method fromString {line} {
	if {[string length $line] == 0} {return [list]}
	if {$line eq "/"} {return [list ""]}

	#if {[string match {@*} $line]} {return [list $line]}

	# Protect escaped space, tab, \, ", and / by mapping them to ^A thru ^E
	set forwardMap [list "\\ " \01 "\\	" \02 \\\\ \03  \\" \04  \\/ \05]
	set backwardMap [list \01 " " \02 "	" \03 \\ \04 \" \05 /]

	set line [string map $forwardMap $line]

	# Protect / in quotations.  Splitting on " gives a list
	# where every other entry is in quotes.
	set first 1
	set inQuote 0
	foreach i  [split $line {"}] {
		if {$inQuote % 2} {
			set i [string map [list / \05] $i]
		}

		incr inQuote
			
		if {$first} {
			set t $i
			set first 0
		} else {
			set t $t\"$i
		}
	}

	# Now we can split on / safely and construct the parsed
	# list of steps
	#
	set n 0
	foreach i [split $t /] {
		incr n

		switch [llength $i] {
			0 {lappend out [list]}
			1 {lappend out [list [string map $backwardMap $i]]}
			2 {
				foreach {i j} $i break
				lappend out [list [string map $backwardMap $i] [string map $backwardMap $j]]
			}
			default {
				UserMsg error "|$self fromString $line| Step $n has more than two terms"
			}
		}
	}

	return $out
}

# Given a path list, return a path string.
#
# If the list is one item long and begins with @, it's a 
# direct path.
#
Path method toString {x} {
	set lx [llength $x]
	if {$lx == 0} {
		return ""
	} elseif {$lx == 1} {
		set t [lindex $x 0]
		if {$t eq ""} {return "/"}
		if {[string match {@*} $t]} {return $t}
	}

	set forwardMap [list " " \01 "	" \02 \\ \03 \" \04 / \05]
	set backwardMap [list \01 "\\ " \02 "\\	" \03  \\\\ \04  \\" \05 \\/]

	foreach i $x {
		switch [llength $i] {
			0 {lappend out [list]}
			1 {lappend out [list [string map $forwardMap [lindex $i 0]]]}
			2 {
				foreach {i j} $i break
				lappend out [list [string map $forwardMap $i] [string map $forwardMap $j]]
			}
			default {
				UserMsg error "|$self toString $x| Step $n has more than two terms"
			}
		}
	}

	set out [join $out /]

	return [string map $backwardMap $out]
}

# Validate a string for suitability as an absolute Path.
#
Path method validateAbs {s} {
	return [regexp {@|/.*} $s]
}

# Validate a string for suitability as a Path.  
#DEFERRED 
#
Path method validate {s} {
	return 1
}

# Given a grid cell and i and j indexes, follow this path
# from that starting point and return a quadruple of
# ``cell grid i j`` indicating the new position. If the path is absolute
# we ignore the starting location. If make is yes, we make
# the resulting cell and all its containers.
#
# Not all of ``cell grid i j`` may be returned.
# If the destination is a free cell, just return the cell.
# If there's no cell at the destination, ``cell`` will be
# null and ``grid i j`` will indicate the location.
#
# If i and j are not given, then g is the starting cell.
#
# If we go beyond the limits of a grid and make is not set,
# we return all nulls.
#
Path method followFrom {gOrC {i ""} {j ""} {make no}} {
	set noIndexes [expr {$i eq "" || $j eq ""}]
	if {$noIndexes} {
		set c $gOrC
		if {$c eq ""} {
			set g ""
		} else {
			lassign [$c getGIJ] g i j
		}
	} else {
		set g $gOrC
		set c [$g subCell $i $j]
	}

	set ns [$self slotLength steps]
	if {$ns == 0} {
		return [list $c $g $i $j]
	}

	set s0 [$self slotIndex steps 0]
	#set s0direct [string match "@*" $s0]
	#set s0direct [Object existsAs $s0 Cell]
	set s0direct [regexp {^limbo@.*|^@.*} $s0]
	
	if {$s0direct && $ns == 1} { ;# path is just cell object name
		$s0 noop
		return [concat $s0 [$s0 getGIJ]]
	}

	if {$s0direct} {	;# absolute path starting with direct cell
		set c $s0
		lassign [$c getGIJ] g i j
		set steps [$self slotRange steps 1 end]
	} elseif {$s0 eq ""} { ;# absolute path starting with /
		set c [theSpace slot root]
		set g ""
		set i ""
		set j ""
		set steps [$self slotRange steps 1 end]
	} else { ;# relative path, start at given gOrC
		if {$gOrC eq ""} {
			return -code [UserMsg errorRC \
				"|$self followFrom $gOrC $i $j $make|No current cell provided, unable to resolve relative path"] ""
		}
		set steps [$self slot steps]
	}

	if {$make} {
		set SC subCell!
	} else {
		set SC subCell
	}
	
	# Iterate through the steps. We maintain c, g, i and j throughout
	#
	foreach s $steps {
		lassign [$self parseStep $s] t val
		if {$g ne ""} {
			lassign [$g size] si sj
		} else {
			if {[string match *lat* $t]} {
				# NOTE: this may have to be done elsewhere in this method
				if {!$make} {	
					return [list "" "" "" ""]
				} else {
					return -code [UserMsg errorRC \
					"|$self followFrom $gOrC $i $j $make| Attempt to take lateral step from uncontained cell ($c)"] ""
				}
			}
		}

		switch $t {
			null	{}
			up		{
				if {$g eq ""} {
					return -code [UserMsg errorRC \
					"|$self followFrom $gOrC $i $j $make| Attempt to take upward step from uncontained cell ($c)"] ""
				}
				set c [$c uplevel $val]
				lassign [$c getGIJ] g i j

				if {$g eq ""} {
					set g [theSpace slot root]
				}
			}
			lat1	{
				lassign $val at av

				set i [$self _computeIndex $at $av $si $i]
				if {!$make && $i >= $si} {return [list "" "" "" ""]}
				set c [$g $SC $i $j]
			}
			lat2 	{
				lassign $val at av bt bv

				set i [$self _computeIndex $at $av $si $i]
				if {!$make && $i >= $si} {return [list "" "" "" ""]}

				set j [$self _computeIndex $bt $bv $sj $j]
				if {!$make && $j >= $sj} {return [list "" "" "" ""]}

				set c [$g $SC $i $j]
			}
			grid1 {
				set c [$c $SC $val]
				if {$c eq ""} {return [list "" "" "" ""]}

				lassign [$c getGIJ] g i j
			}
			grid2 {
				lassign $val av bv

				set c [$c $SC $av $bv]
				if {$c eq ""} {return [list "" "" "" ""]}

				lassign [$c getGIJ] g i j
			}
			latgrid {
				lassign $val at av bv
				set i [$self _computeIndex $at $av $si $i]
				if {!$make && $i >= $si} {return [list "" "" "" ""]}

				set c [$g $SC $i $bv]
			}
			gridlat {
				lassign $val av bt bv
				set j [$self _computeIndex $bt $bv $sj $j]
				if {!$make && $j >= $sj} {return [list "" "" "" ""]}
				set c [$g $SC $av $j]
			}
		}	;# end switch

		# Now check that we made a valid step
		if {$c eq "" && $g eq ""} {
			if {!$make} {
				return ""
			} else {
				return -code [UserMsg errorRC "|$self followFrom $gOrC $i $j $make| Unable to create cell with this path"] ""
			}
		}

	}   ;# end foreach s $steps

	return [list $c $g $i $j]
}

# Compute an index given the type and value as parsed above
#
# We used to do this for numerical indexes:
#
#``	set i [::Thyrd::limit 0 [expr {[$cc slot $which] + $v}] [expr $u -1]] ``
#
# but now we just add the value, possibly generating an
# invalid index.
#
# ``i`` will be either the i or j coord of the current cell.
# ``t`` is the type and ``v`` is the value, as parsed. ``s``
# is the size of the containing grid in the specified dimension.
#
Path method _computeIndex {t v s i} {
	if {$t eq "latEnd"} {
		if {$v < 0} {
			set i 1
		} else {
			set i [expr $s - 1]
		}
	} elseif {$t eq "latFrame"} {
		if {$v < 0} {
			set i 0
		} else {
			set i [expr $s]
		}
	} else {
		incr i $v
	}

	return $i
}

# Find the cell this path refers to, possibly making it.  If
# a current cell (cc) is given, we can resolve a relative path,
# else it's an error.  The cell name is returned and stored in
# cell.
# 
# Note that we also make sure the cell exists, in case it's
# waiting to be autoloaded.
#
Path method resolve {{cc ""} {make no}} {
	lassign [$self followFrom $cc "" "" $make] c g i j

	Object safe $c noop  ;# probably not needed, but just in case
	$self slot cell $c
	return $c
}

# Return true if we have been resolved to a cell that
# exists
#
Path method resolved {} {
	set c [$self slot cell]

	if {$c eq ""} {return no}
	
	if {![Object existsAs $c Cell]} {return no}

	return yes
}

# Parse one step in a path, returning a list of
# the type and the parse values
#
Path method parseStep {s} {
	set dim [llength $s]

	if {$dim == 0} {
		return [list null ""]
	}

	if {$dim > 2} {
		return -code [UserMsg errorRC "|$self parseStep $s| Dimensions greater than 2 are not implemented"] [list bogus ""]
	}

	if {$dim == 1} {
		set a [lindex $s 0]
		if {[regexp {^\.+$} $a]} {
			return [list up [expr [string length $a] - 1]]
		} else {
			foreach {at av} [$self parseIndex $a] break
			if {[string match lat* $at]} {
				return [list lat1 [list $at $av]]
			} else {
				return [list grid1 $av]
			}
		}
	} else {		;# 2d
		foreach {at av} [$self parseIndex [lindex $s 0]] break
		foreach {bt bv} [$self parseIndex [lindex $s 1]] break

		if {[string match lat* $at]} {
			if {[string match lat* $bt]} {
				return [list lat2 [list $at $av $bt $bv]]
			} else {
				return [list latgrid [list $at $av $bv]]
			}
		} else {
			if {[string match lat* $bt]} {
				return [list gridlat [list $av $bt $bv]]
			} else {
				return [list grid2 [list $av $bv]]
			}
		}
	}
}

# Parse one index, returning a list of its type and value.
# If it starts with - or + and has only digits, it's a lateral
# index, and we compute the numerical value.
# -* are +* are the spatial limits of the
# contents of the grid (not the frame).  -- is the frame cell in
# that dimension, and ++ is the index after the last cell in 
# that direction (i.e., it's guaranteed to produce an index to
# a cell that does not yet exist in this grid).
# Then we check to see if it's a number, else it's a textual index.
# These are marked as grid indexes.
#
Path method parseIndex {i} { 
	if {[regexp {^[-+]\d+$} $i]} {
		return [list lat [expr 0$i]]
	}

	if {$i eq "--"} {
		return [list latFrame -1]
	}

	if {$i eq "++"} {
		return [list latFrame 1]
	}

	if {$i eq "-*"} {
		return [list latEnd -1]
	}

	if {$i eq "+*"} {
		return [list latEnd 1]
	}

	if {[string is integer $i]} {
		return [list gridNum $i]
	} else {
		return [list gridText $i]
	}
}

# Given a cell, make it our cell and construct an
# absolute path for it (or direct, if it's a loose
# cell).  
#
# We return the path as text.
#
Path method fromCell {c} {
	$self slot value ""

	$self slot cell $c

	set cc [$c slot container]
	if {$cc eq ""} {	;# direct
		$self slot steps $c
		return [$self update]
	} 

	$self slot steps ""

	# iterate over the contained cells
	foreach ci [$c containmentPath] {
		$self slotAppend steps [$ci betterIndex]
	}

	# Handle last container
	$self slotAppend steps [$c betterIndex]

	return [$self update]
}

# Recompute this path from the cell we resolve to.
# This turns direct and relative paths into
# absolute paths, if possible.  It also pretties
# up a path, since ``betterIndex`` is used to 
# set the steps.
#
Path method repath {} {
	set c [$self slot cell]
	if {$c eq ""} return

	$self fromCell $c
}

# Reduce this path vs another path ``op``, if
# possible.  If the only commonality between 
# this path and ``op`` is ``/``, we don't change.
#
# If ``op`` is a direct path, we can't do anything
# (we don't want to change ``op``).  Use ``repath``
# on it first, if desired. 
#
# repath should probably be called on $self before
# reducing, unless you know it's already absolute.
#
Path method reduceVs {op} {
	if {[$op isDirect] || ![$op isAbsolute]} return

	if {[$self isDirect]} return

	set oss [$op slotRange steps 1 end]
	set rss [$self slotRange steps 1 end]

	set n 0
	foreach os $oss rs $rss {
		if {$os eq $rs} {
			incr n
		} else {
			# first difference, do nothing if no matches found
			if {$n == 0} return

			# Start to build new steps list by adding an up reference of appropriate length
			# then add in remaining steps from $rss
			$self slot steps [concat \
				[string repeat "." [expr {[llength $oss] - $n + 1}]] \
				[lrange $rss $n end]]

			break
		}
	}

	$self update
}

# Remove the steps at the end of this path that
# are not in common with ``op``.  Sort of the
# opposite of reduceVs, shares lots of code in common.
# 
# Paths should be absolute (use repath if necessary)
#
Path method commonWith {op} {
	set steps [$self slot steps] 
	$self slot steps ""

	foreach rs $steps os [$op slot steps] {
		if {$os eq $rs} {
			$self slotAppend steps $rs
		} else {
			break
		}
	}

	$self update
}

# Return the glyph for this core
#
Path method getGlyph {} {
	return [Thyrd getImage type-path]
}
