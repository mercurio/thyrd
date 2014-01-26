### A panel for viewing an atomic cell 
### containing a triad via three buttons that navigate
### to the corners of the triad.
###
# PJM	2008-05-13	Begun

AtomicPanel construct APTriad

APTriad slot borderwidth 3
APTriad slot relief groove

# Given the parent widget and the cell, construct
# and return the panel
#
APTriad method build {mom tool c {opts {}} {w {}} {h {}}} {
	set kid [$self buildFrame $mom $c $w $h]
	$kid slot tool $tool

	set f [$kid slot _frame]

	foreach {o v} $opts {
		switch $o {
			-ttk {$self slot ttk $v}
		}
	}

	if {[$self slot ttk]} {
		set mkb ttk::button
	} else {
		set mkb button
	}

	set sf [frame ${f}.sub]

	set pa ${sf}.pa
	$kid slot buttonA $pa
	$mkb $pa -text "" -command [list $kid goto A]

	set pb ${sf}.pb
	$kid slot buttonB $pb
	$mkb $pb -text "" -command [list $kid goto B]

	set py ${sf}.py
	$kid slot buttonY $py
	$mkb $py -text "" -command [list $kid goto Y]

	grid [label ${sf}.la -image [Thyrd getImage glyph-a-sm]] -row 1 -column 1
	grid $pa -row 1 -column 2 -sticky ew

	grid [label ${sf}.lb -image [Thyrd getImage glyph-b-sm]] -row 2 -column 1
	grid $pb -row 2 -column 2 -sticky ew

	grid [label ${sf}.ly -image [Thyrd getImage glyph-y-sm]] -row 3 -column 1
	grid $py -row 3 -column 2 -sticky ew

	grid columnconfigure $sf 2 -weight 1

	place $sf -relwidth .98 -relheight 1 -anchor n -relx .5 -rely 0

	trace add variable [$kid slotVar _value] write [list $kid show]
	$kid show

	return $f
} 

# Show the current triad
#
APTriad method show {args} {
	set t [$self slot _value]

	if {[Object existsAs $t Triad]} {
		[$self slot buttonA] configure -text [$t path A]
		[$self slot buttonB] configure -text [$t path B]
		[$self slot buttonY] configure -text [$t path Y]
	} else {
		[$self slot buttonA] configure -text ""
		[$self slot buttonB] configure -text ""
		[$self slot buttonY] configure -text ""
	}
}

# Go to the specified path
#
APTriad method goto {which} {
	set t [$self slot _value]

	set to ""
	if {[Object existsAs $t Triad]} {
		set to [$t cell $which]
	}

	if {$to ne ""} {
		[$self slot tool] navupdown $to
	}
}
