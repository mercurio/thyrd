# A ternary relationship between cells, represented as
# three paths: A, B, and Y.  They can have 
# any meaning, but usually A is the primary, B the secondary, and
# Y the relationship.  Other interpretations might be:
# A = subject, B = object, Y = verb; A = signifier, B =
# signified, Y = interpretant (Piercian semiotics);
# A = sender, B = receiver, Y = message, etc.  This is
# the Thyrd analogue to a pointer in other languages.
#
# Given a cell, we can obtain all the triads that have that
# cell as their A, B, or Y corner, or any corner.  We can also
# start with 2 cells or all 3 specified. 
# 
# A Triad consists of three paths to cells.  The A path should be
# absolute, the others can be relative (they're relative to A).
#
# PJM 2005-08-20	Created 
# PJM 2006-03-17	Revised to use Path more

Object construct Triad
Triad mixin Observable

# The path objects, stored in public slots so they
# persist
#
Triad slot poA {}
Triad slot poB {}
Triad slot poY {}

# Construct a new triad, making it persistent.
#
Triad method construct {{child @}} {
	set kid [$self as [Triad parent] construct $child]
	$kid mixin Thing
	return $kid
}

# Create a new triad given three paths to cells
#
Triad method new {a b y} {
	set kid [$self construct]

	$kid slot poA [Path new]
	$kid slot poB [Path new]
	$kid slot poY [Path new]

	$kid bind $a $b $y

	return $kid
}

# Destruct our persistent Path objects when we 
# go, and remove ourselves from existence.
#
Triad method destruct {} {
	theSpace removeTriad $self

	# DEFERRED  $self unbind    do we need this?
	Object safe [$self slot poA] destruct
	Object safe [$self slot poB] destruct
	Object safe [$self slot poY] destruct

	return [$self as [Triad parent] destruct]
}

# Override Thing_postload to cause the path objects to be loaded
# when this triad is. We also load the cells in the corners.
# This is how free cells end up getting loaded when the root
# of the thyrdspace is loaded.
#
Triad method Thing_postload {} {
	foreach c [Triad corners] {
		set p [$self slot po$c]
		if {$p ne ""} {
			$p noop
			Object safe [$p slot cell] noop
		}
	}

	$self as Thing Thing_postload
	$self notifyObservers write
}

# Set a path string and resolve it to get the cell it points to, 
# making sure the cells involved are kept up to
# date.
#
# If we change the A path, we have to re-resolve the B and Y
# paths if they're relative.
#
Triad method setPath {which path} {
	theSpace detachTriad $which $self

	set po [$self slot po$which]
	$po set $path

	if {[$po isNull]} {return ""}

	if {$which eq "A"} {
		if {![$po isAbsolute]} {
			UserMsg error "|$self resolve $which $path| Path for the A corner of a triad must be absolute"
			return -code error
		}

		set relTo {}
	} else {
		set relTo [$self cell A]
	}

	set c [$po resolve $relTo]
	theSpace attachTriad $which $self

	if {$which eq "A"} {
		if {![[$self slot poB] isAbsolute]} {
			$self setPath B [$self path B]
		}
		if {![[$self slot poY] isAbsolute]} {
			$self setPath Y [$self path Y]
		}
	}

	return $c
}

# One of our cells has just changed, recompute our
# paths.  
#
Triad method setCell {which c} {
	set po [$self slot "po$which"]

	$po fromCell $c
	
	$self reduce
}

# Reduce the detail of this triad by making
# the B and Y paths relative, if possible, 
# via ``Path reduceVs``
#
# If the only commonality between a path and
# A is /, we leave it absolute. 
#
Triad method reduce {} {
	poetvar $self poA poB poY

	$poA repath
	$poB repath
	$poY repath

	$poB reduceVs $poA
	$poY reduceVs $poA
}

# Return a list of the cells in order A, B, Y
#
Triad method cells {} {
	poetvar $self poA poB poY

	return [list [$poA slot cell] [$poB slot cell] [$poY slot cell]]
}

# Get the cell stored in one of the corners
#
Triad method cell {which} {
	set po [$self slot po$which]
	return [$po slot cell]
}

# Get the path string stored in one of the corners
#
Triad method path {which} {
	set po [$self slot po$which]
	return [$po update]
}

# Return the names of the corners
#
Triad method corners {} {
	return [list A Y B]
}

# Return the names of the edges that contain the
# given corner, or all three edges if no corner
# is given
#
Triad method edges {{which ""}} {
	switch -exact $which {
		A {return [list AB AY ]}
		B {return [list AB BY]}
		Y {return [list AY BY]}
		default {return [list AB AY BY]}
	}
}

# Return the other two corner names for a corner.
# 
Triad method others {which} {
	switch $which {
		A {return [list Y B]}
		B {return [list A Y]}
		Y {return [list A B]}
	}
}

# Bind this triad to three cells, some of which
# may be null.  The paths to the cells are provided.
# Note that we have to set pathA first, since the
# other paths might be relative to it.
#
Triad method bind {a b y} {
	$self setPath A $a
	$self setPath B $b
	$self setPath Y $y
}

# Unbind this triad from all three cells.
#
Triad method unbind {} {
	$self setPath A {}
	$self setPath B {}
	$self setPath Y {}
}

# Lose the cell stored in one of the corners.
# Currently, this destroys the triad, but we
# could allow partial triads by changing this.
#
Triad method loseCell {which} {
	$self destruct
}


# Print a triad for debugging
#
Triad method print {} {
	puts "$self:"
	set a [$self cell A]
	set b [$self cell B]
	set y [$self cell Y]

	puts "  [$self path A] ($a [$a path])"
	puts "  [$self path B] ($b [$b path])"
	puts "  [$self path Y] ($y [$y path])"
}
