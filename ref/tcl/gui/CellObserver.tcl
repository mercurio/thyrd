# CellObserver - Additional mixin methods for objects that observe a cell
#
# We maintain the slot _cell with the cell we're editing/viewing,
# given the path as a string.  We also create _path to store
# the Path object.  Neither of these slots should be accessed
# directly, use the methods below.
#
# DEFERRED need to handle cleanup of _path
#
# PJM	2006-01-02	Begun
# PJM	2006-10-06	Added _ocell, which contains the old
#					cell (whether or not the cell changed)
#

Object construct CellObserver

# Called when a new path string is provided.
# Returns true if a new path/cell was set.
#
CellObserver method pathDelta {p} {
	set path [$self slot _path]

	if {$path eq ""} {
		set path [$self slot _path [Path newVolatile $p]]
		$path resolve
	} else {
		if {[$path update] eq $p} {
			return false
		} else {
			$path set $p
			$path resolve
		}
	}

	$self slot _ocell [$self slot _cell]
	if {[$path resolved]} {
		$self slot _cell [$path slot cell]
	} else {
		$self slot _cell ""
	}

	return true
}

# Called when a new cell is being viewed.
# Returns true if it's different than the old
# cell.
#
CellObserver method cellDelta {nc} {
	set c [$self slot _cell]

	if {$nc eq $c} {
		return false
	} else {
		$self slot _ocell $c
		$self slot _cell $nc

		set p [$self slot _path]
		if {$p eq ""} {
			set p [$self slot _path [Path newVolatile]]
		}

		$p fromCell $nc

		return true
	}
}
		

# Return the observed cell
#
CellObserver method viewCell {} {
	return [$self slot _cell]
}


# Return the observed path as text.
#
CellObserver method viewPath {} {
	set p [$self slot _path]
	if {$p eq ""} {
		return ""
	} else {
		return [$p update]
	}
}

# Return the old cell
#
CellObserver method oldCell {} {
	return [$self slot _ocell]
}

