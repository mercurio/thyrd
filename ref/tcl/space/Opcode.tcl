# A Core representing a Thyrd Operation.  The value
# is the textual opcode, the operation may be cached.
#
# PJM	2007-07-23	Created
#
# This needs to be preloaded (all Core children do):
::Poet::Preload Thyrd

Core construct Opcode
catch {Opcode unparent Thing}	;# this object is not persistent, its kids are

# How to display this sort of core.
Opcode slot displayKey "icon"

# Slot containing the parsed operation 
Opcode slot op {}
Opcode type op Op

# Create a new, non-persistent Opcode for computation
# (not as a Core in a Cell).
#
Opcode method newVolatile {{value ""}} {
	set kid [$self construct *]
	$kid unparent Thing

	$kid set $value

	return $kid
}

##
## Core API
##

# Set the value of this path
#
Opcode method set {value} {
	$self slot value $value
	$self slot op [$self fromString $value]
}

# Print a path to stdout for debugging
#
Opcode method print {} {
	puts "$self: [$self slot value]"
	set o [$self slot op]
	if {$o eq ""} {
		puts "	<unrecognized>"
	} else {
		puts "  [$o print]"
	}
}

# Get the textual representation of this
# core
#
Opcode method getText {} {
	set op [$self slot op]
	if {$op eq ""} {set op Op}

	return [$op slot caption]
}

# Update the value of this opcode (call if the op has been
# manipulated) 
#
Opcode method update {} {
	return [$self slot value [$self toString [$self slot op]]]
}

# Returns true if this is a null (unrecognized) op
#
Opcode method isNull {} {
	expr {[$self slot op] eq ""}
}

# Given an opcode string, return an op
#
Opcode method fromString {opcode} {
	set o [Op lookup $opcode]
	$self slot op $o
	
	return $o
}

# Given an operation, return the opcode
#
Opcode method toString {x} {
	if {[Object exists $x]} {
		return [$x slot opcode]
	} else {
		return ""
	}
}

# Validate a string for suitability as a Opcode
#
Opcode method validate {s} {
	Op arrayHas index $s
}

# Return the icon for this opcode, given the available
# width and height or an explicit specification of
# which size we want.
#
# We only have large and small, so anything smaller than
# large is small.  If only one arg is given, it's ``which``.
#
Opcode method getIcon {w {h ""}} {
	set dcw [Spans get defaultCellW]

	if {$h eq ""} {
		set which $w
	} elseif {$w >= $dcw && $h >= $dcw} {
		set which lg
	} else {
		set which sm
	}

	set op [$self slot op] 
	if {$op eq ""} {set op Op}

	return [$op slot icon$which]
}

# Return the glyph for this opcode
#
Opcode method getGlyph {} {
	set op [$self slot op]
	if {$op eq ""} {
		set op Op
	}

	return [$op slot icongl]
}
