# Cursors
#
# Manage the cursors in use by this application.
# Note: Mac cursors untested.
#
# PJM 2007-12-11	Derived from Fonts.tcl

Object construct Cursors

# Select a cursor scheme.  Note that the default scheme
# is set by calling this method below.
#
Cursors method select {scheme} {
	case $scheme {
		default {
			switch $::tcl_platform(platform) {
				windows {
					$self slot normal ""
					$self slot ns	"size_ns"
					$self slot ew	"size_we"
					$self slot busy "watch"
				}
				unix {
					$self slot normal ""
					$self slot ns	"sb_v_double_arrow"
					$self slot ew	"sb_h_double_arrow"
					$self slot busy "watch"
				}
				macintosh {
					$self slot normal ""
					$self slot ns	"resizeupdown"
					$self slot ew	"resizeleftright"
					$self slot busy "watch"
				}
			}
		}
	}
}

# Get the value of a cursor slot, but complain
# if it's not there.  
#
Cursors method get {c } {
	if {![$self hasSlot $c]} {
		puts stderr "|$self get $c| Cursor $c not defined in Cursors.tcl, substituting {}"
		return {}
	} else {
		return [$self slot $c]
	}
}

Cursors select default
