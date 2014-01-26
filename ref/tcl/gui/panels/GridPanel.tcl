# GridPanel -- a control panel for cell containing
# a grid of subcells.
#
# PJM 2007-03-19	Begun

Panel construct GridPanel

# Given the parent widget and the cell, construct
# and return the panel
#
# See: ``Panel build``
#
GridPanel method build {mom tool c {opts {}} {w {}} {h {}}} {
	set f $mom.[Object safeName [Object anon]]
	$kid slot tool $tool

	set bw 2

	if {$w eq "" || $h eq ""} {
		frame $f -width [expr {$w-$bw}] -height [expr {$h-$bw}] \
			-background grey -relief sunken -borderwidth $bw

		place $f -width $w -height $h
	} else {
		frame $f -background grey -relief sunken -borderwidth $bw
		pack $f -expand 1 -fill both
	}

	set kid [[$self construct *] glomOnto $f]
	
	return $f
} 

