# ZoomTable -- a BW_Table that can zoom in and out
#
# PJM 2006-03-17	Begun
#

BW_Table construct ZoomTable

# Animate a zoom in to a cell
#
ZoomTable method zoomIn {i j} {
	set prim [$self slot _primary]
	set wmax [winfo width $prim]
	set hmax [winfo height $prim]

	foreach {x y wmin hmin} [$self bbox $j,$i] break

	$self zoomInStep 10 $i $j $wmin $wmax $hmin $hmax
}

# Do one step in a zoom in, and possibly schedule the
# next step.
#
ZoomTable method zoomInStep {ms i j w wmax h hmax} {
	if {$w > $wmax && $h > $hmax} return

	set tp [$self slot _primary]

	if {$w <= $wmax} {
		set imax [$tp cget -cols]
		set wlist [list $tp width]

		for {set x 0} {$x < $imax} {incr x} {
			if {$x == $i} {
				lappend wlist $x $w
			} else {
				lappend wlist $x default
			}
		}

		eval $wlist
	}

	if {$h <= $hmax} {
		set jmax [$tp cget -rows]
		set hlist [list $tp height]

		for {set y 0} {$y < $jmax} {incr y} {
			if {$y == $j} {
				lappend hlist $y $h
			} else {
				lappend hlist $y default
			}
		}

		eval $hlist
	}

	after $ms [list $self zoomInStep $ms $i $j [incr w] $wmax [incr h] $hmax]
}
