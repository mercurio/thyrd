# Singleton object for managing all the cell to triad
# links. 
#
# PJM 2005-11-27	Created 

Object construct TriadMapper


# Construct a new triadMapper, making it persistent.
# We give it 3 SetMaps for mapping from cells to
# triads and 3 SetDualMaps for mapping from edges (pairs of cells) to
# triads.
#
TriadMapper method new {} {
	set kid [$self construct @]
	$kid mixin Thing

	foreach c [Triad corners] {
		[$kid slot by$c [SetMap construct @]] mixin Thing
	}

	foreach e [Triad edges] {
		[$kid slot by$e [SetDualMap construct @]] mixin Thing
	}

	return $kid
}

# Override Thing_postload to cause the maps to be loaded
# when this object is. 
#
TriadMapper method Thing_postload {} {
	foreach c [Triad corners] {
		[$self slot by$c] noop
	}

	foreach e [Triad edges] {
		[$self slot by$e] noop
	}

	$self as Thing Thing_postload
}

# Attach a triad via some associations in this mapper.
# We're given which of the corners has just changed
# and modify all maps that include that corner.
#
TriadMapper method attachTriad {which t} {
	set c [$t cell $which]
	if {$c ne ""} {
		[$self slot by$which] addLink $c $t
	}

	foreach e [Triad edges $which] {
		set c1 [$t cell [string index $e 0]]
		set c2 [$t cell [string index $e 1]]
		if {$c1 ne "" && $c2 ne ""} {
			[$self slot by$e] addLink $c1 $c2 $t
		}
	}
}

# Detach a triad from some associations in this mapper.
# We're given which of the corners is about to change
# and modify all maps that include that corner.
#
TriadMapper method detachTriad {which t} {
	set c [$t cell $which]
	if {$c ne ""} {
		[$self slot by$which] unlink $c $t
	}

	foreach e [Triad edges $which] {
		set c1 [$t cell [string index $e 0]]
		set c2 [$t cell [string index $e 1]]
		if {$c1 ne "" && $c2 ne ""} {
			[$self slot by$e] unlink $c1 $c2 $t
		}
	}
}

# Remove a triad from all associations in this mapper.
#
TriadMapper method removeTriad {t} {
	foreach c [Triad corners] {
		set x [$t cell $c]
		[$self slot by$c] unlink $x $t
	}

	foreach e [Triad edges] {
		set c1 [$t cell [string index $e 0]]
		set c2 [$t cell [string index $e 1]]
		if {$c1 ne "" && $c2 ne ""} {
			[$self slot by$e] unlink $c1 $c2 $t
		}
	}
}

# Find all the triads that match the given 
# cells or paths.  If a corner is specified
# as ``*``, it's a wildcard in the search.
# If no wildcards are given we return the
# triad connecting the three paths, if it
# exists.  
#
# Note that we turn path strings into cells
# for the search, so the different ways in
# which a cell can be referenced don't lead to
# multiple triads with the same cells.
#
# A list of 0 or more triads is returned.
#
TriadMapper method find {a b y} {
	set nStars 0

	if {$a eq "*"} {
		set ca ""
		incr nStars
	} else {
		set pa [Path newVolatile $a]
		set ca [$pa resolve]
		$pa destruct
		if {$ca eq ""} {error "|$self find $a $b $y|$a does not resolve to a cell"}
	}

	if {$b eq "*"} {
		set cb ""
		incr nStars
	} else {
		set pb [Path newVolatile $b]
		set cb [$pb resolve $ca]
		$pb destruct
		if {$cb eq ""} {error "|$self find $a $b $y|$b does not resolve to a cell"}
	}

	if {$y eq "*"} {
		set cy ""
		incr nStars
	} else {
		set py [Path newVolatile $y]
		set cy [$py resolve $ca]
		$py destruct
		if {$cy eq ""} {error "|$self find $a $b $y|$y does not resolve to a cell"}
	}

	switch $nStars {
		0 {
			foreach t [[$self slot byAB] getLinks $ca $cb] {
				if {[$t cell Y] eq $cy} {return [list $t]}
			}

			return [list]
		}
		1 {
			if {$cy eq ""} {
				return [[$self slot byAB] getLinks $ca $cb]
			} elseif {$cb eq ""} {
				return [[$self slot byAY] getLinks $ca $cy]
			} else {
				return [[$self slot byBY] getLinks $cb $cy]
			}
		}
		2 {
			if {$ca ne ""} {
				return [[$self slot byA] getLinks $ca]
			} elseif {$cb ne ""} {
				return [[$self slot byB] getLinks $cb]
			} else {
				return [[$self slot byY] getLinks $cy]
			}
		}
		3 {
			set output [list]
			[$self slot byA] forEachLink {
				set output [concat $output $toList]
			}

			return $output
		}
	}
}

# Handle the specific case of looking for a B cell
# given A and Y
#
TriadMapper method findB {a y} {
	set t [[$self slot byAY] getLinks $a $y]
	assert {[llength $t] <= 1}

	if {$t eq ""} {
		return ""
	} else {
		set b [$t cell B]
		if {[catch $b]} {
			UserMsg warning "|$self findB $a $y| Bogus triad with B = $b found"
		} else {
			return $b
		}

	}
}

# Print for debugging
#
TriadMapper method print {} {
	puts "==TriadMapper $self"

	puts "All known triads:"
	foreach t [lsort [Triad children]] {
		$t print
	}

	foreach c [Triad corners] {
		puts "triads indexed by corner ${c}: "
		[$self slot by$c] print
	}

	foreach e [Triad edges] {
		puts "triads indexed by edge ${e}: "
		[$self slot by$e] print
	}

		
}
