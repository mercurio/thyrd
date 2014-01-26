### A simple panel for viewing an atomic cell via
### a combobox.
###
# PJM	2008-05-13	Begun

AtomicPanel construct APChoice

# Given the parent widget and the cell, construct
# and return the panel
#
APChoice method build {mom tool c {opts {}} {w {}} {h {}}} {
	set kid [$self buildFrame $mom $c $w $h]
	$kid slot tool $tool

	set f [$kid slot _frame]

	set p ${f}.p

	if {[$self slot ttk]} {
		ttk::combobox $p -textvariable [$kid slotVar _value] -values $opts
	} else {
		combobox $p -textvariable [$kid slotVar _value] -values $opts
	}

	place $p -relwidth .98 -anchor n -relx .5 -rely 0

	return $f
} 

