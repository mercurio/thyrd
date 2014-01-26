# CellTableBook - BWidget notebook displaying a Cell and its
# various aspects, like nucleus, triads, etc.
#
# PJM 2005-09-01	Begun, derived from Poet's ObjectTableBook
# PJM 2006-02-28	we now observe a NavBar
#

BW_NoteBook construct CellTableBook
CellTableBook mixin Observer

# Options that must be specified at creation time
CellTableBook slot extraOptions {paramList tool}

CellTableBook slot aspects {Text}


# Build the primary for a CellTableBook
#
CellTableBook method buildPrimary {} {
	$self destroyPrimary

	set prim [$self as BW_NoteBook buildPrimary]
	set pl [$self slot paramList]

	set page 0
	foreach a [$self slot aspects] {
		set f [$self insert end $a -text [$self prettify $a]]
		$self raise [$self page $page]

		set t Cell${a}Table
		$self slotAppend _tables [set tab [$t construct * $f -tool [$self slot tool] \
			-paramList $pl -relief flat -borderwidth 0 \
			-layout {-side top -expand yes -fill both}]]

		$tab slot _aspect $a
		incr page
	}

	# currently, the table book doesn't need to do anything 
	# when the path changes (all the sub tables do)
	#$pl watchSub! $self newPath path

	$self raise [$self page 0]

	return $prim
}

# Turn an aspect into a nice looking label by adding spaces 
#
CellTableBook method prettify {txt} {
	regsub -all {[A-Z]} $txt " &" out
	return "[string trim $out]"
}
