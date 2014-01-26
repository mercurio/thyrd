# A core of a cell.  All cores store a string
# representation of their contents in a slot called
# ``value`` and a pointer to the cell they're in in 
# ``container``.
#
# This is the simplest Core, it just holds a string.
#
# Note that Core and its descendants are factories.
# Use construct to make a new factory (define a new
# type), use newInCell to trigger the factory to make a
# new core for insertion in a cell.  You can also make
# a Core that is not in a cell with new, some cores may
# disallow this.  new* make persistent objects, construct doesn't.
#
# PJM	2005-10-20 Created
# PJM	2006-02-10 newInCell added
#

Object construct Core
Core mixin Constrainable
Core mixin Exportable

# The primary value
#
Core slot value {}
Core type value <string>

# The cell that possesses this core.
#
Core slot container {}
Core type container Cell

# How to display this sort of core.  The
# default is to display the value.
#
Core slot displayKey "value"

# Create a new core of this type.  We may or may not
# be persistent, depending on our name.
#
Core method construct {{child @}} {
	set kid [$self as [Core parent] construct $child]
	if {[regexp {.*@.*} $child]} {
		$kid mixin Thing
	}

	return $kid
}

# Create a new core of this type with the given value
# but without a cell.  Useful for core types that 
# are useful without being in a cell.
#
# If a type is given, use it.
#
Core method new {{value ""} {type <string>}} {
	set kid [$self construct]

	$kid slot container ""
	$kid type value $type
	$kid set $value

	return $kid
}

# Create a new core of this type with the given value
# in the given cell. Note that we also set the 
# core slot in $cell and establish a trace on the core's
# value, if it's atomic.
#
# If a type is given, use it.
#
# We use the same prefix as our owner, so we may or may
# not be persistent. If our owner has no prefix, we
# assume ``*``.
#
Core method newInCell {cell {value ""} {type <string>}} {
	assert {$cell ne "" && [$cell isA Cell]}

	set kid [$self construct [$cell getPrefix *]]

	$kid slot container $cell
	$cell slot core $kid

#DEFERRED this appears to be redundant with the code in Cell set
#	if {[$kid atomic]} {
#		$kid method value> {x} [list $cell notifyObservers write]
#		$kid slotOn value >
#	}

	$kid type value $type
	$kid set $value

	return $kid
}

# Set the value
#
Core method set {value} {
	$self slot value $value
	return $value
}

# Return true if this value is allowed for this type of core.
# Should be overridden.
#
Core method validate {value} {
	return true
}

# Get the value
#
Core method get {} {
	return [$self slot value]
}

# Get the textual representation of this
# core, which by default is the value.
#
Core method getText {} {
	return [$self slot value]
}

# Return true if this is an atomic cell (not a Grid)
#
Core method atomic {} {
	return 1
}

# Print for debugging
#
Core method print {} {
	puts [$self slot value]
}

# Return a list of the available Core types,
# including Core.  Exclude any of the args.
# Core is always first.
#
Core method coreTypes {args} {
	foreach x [concat Core [lsort [Core children {^[^@*]} -regexp]]] {
		if {[lsearch -exact $args $x] == -1} {lappend out $x}
	}

	return $out
}

# Return our atomic type 
#
Core method atomType {} {
	return [$self type value]
}

# Return our atomic type class (no qualifiers)
#
Core method atomType {} {
	return [lindex [$self type value] 0]
}

# Return an image corresponding to our atomic type
#
Core method getGlyph {} {
	return [Type getImage [lindex [$self type value] 0]]
}
