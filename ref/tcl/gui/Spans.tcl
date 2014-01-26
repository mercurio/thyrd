### Manage the spans (pads, default sizes) in use by this application.
#
# PJM	2006-05-19	Derived from Colors

Object construct Spans

# Select a scheme.  Note that the default scheme
# is set by calling this method below.
#
Spans method select {scheme} {
	switch $scheme {
		default {
			# cell internals, size of small icons
			# (large icons are square)
			$self slot defaultCellW 90
			$self slot defaultCellH 20

			# border around cells in grid
			$self slot gridWallWidth	2
			$self slot cellWallWidth	3
			$self slot cellHiliteWidth [* [$self slot cellWallWidth] 6]

			# Threshold below which we don't render
			$self slot visThreshold 10

			# padding for text
			$self slot ipadX 4
			$self slot ipadY 4

			$self slot iconLgBorder 16

			# For scroll regions used in triad lists, same as height of sr-*.gif + 1
			$self slot srHeight 7

			# outer membrane offset
			$self slot omOffset 3

			# bottomMargin stuff
			$self slot bmHandleR 10
			$self slot bmHandleW 3
			$self slot bmMin 10
			$self slot bmTolerance 10
			$self slot bmPad 5

			# zoom timing
			$self slot downFPS		20
			$self slot upFPS		15

			# length of lines in the help and sidefx fields of the ops table
			$self slot linelen		60
		}
	}
}

# Get the value of a span slot, but complain
# if it's not there.  
#
Spans method get {c} {
	if {![$self hasSlot $c]} {
		puts stderr "|$self get $c| Span $c not defined in Spans.tcl, substituting 0"
		return 0
	} else {
		return [$self slot  $c]
	}
}

# Return true if any of the given values are
# below the visual threshold
#
Spans method tooSmall {args} {
	set t [$self get visThreshold]
	foreach x $args {
		if {$x < $t} {return 1}
	}

	return 0
}


Spans select default
