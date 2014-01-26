# A Core representing a Triad.  Internally, a
# triad is the name of the Triad object, but it
# is viewed as its three paths.
# 
# PJM	2008-09-25	Created
#
# This needs to be preloaded (all Core children do):
::Poet::Preload Thyrd

Core construct TriadCore
catch {TriadCore unparent Thing}	;# this object is not persistent, its kids are

##
## Core API
##

# Set the value of this triad
#
TriadCore method set {value} {
	$self slot value $value
	$self type value Triad
}

# Print a triadcore to stdout for debugging
#
TriadCore method print {} {
	set v [$self slot value]
	puts "$self: $v"
	$v print
}

# Validate a string for suitability as a TriadCore.  Must
# be a Triad object, either pre-existing or autoloadable.
#
TriadCore method validate {s} {
	return [? {[Object available $s] && [$s isA Triad]}]
}

# Return the glyph for this core
#
TriadCore method getGlyph {} {
	return [Thyrd getImage type-triad]
}
