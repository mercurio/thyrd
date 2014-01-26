### Manage the styles in use by this application.
#
# PJM	2006-05-24	Derived from Colors

Object construct Styles

# Select a scheme.  Note that the default scheme
# is set by calling this method below.
#
Styles method select {scheme} {
	case $scheme {
		default {
			$self slot ipadX 4
			$self slot ipadY 4
			$self slot defaultCellW 100
			$self slot defaultCellH 30
		}
	}
}

# Get the value of a span slot, but complain
# if it's not there.  
#
Styles method get {c} {
	if {![$self hasSlot $c]} {
		puts stderr "|$self get $c| Style $c not defined in Styles.tcl"
		return ""
	} else {
		return [$self slot  $c]
	}
}

Styles select default
