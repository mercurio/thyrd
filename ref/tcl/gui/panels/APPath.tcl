### A simple panel for viewing an atomic cell 
### containing a path via a button that navigates
### to the new cell.
###
# PJM	2008-05-13	Begun

AtomicPanel construct APPath

APPath slot borderwidth 3
APPath slot relief groove

# Given the parent widget and the cell, construct
# and return the panel
#
APPath method build {mom tool c {opts {}} {w {}} {h {}}} {
	set kid [$self buildFrame $mom $c $w $h]
	$kid slot tool $tool

	set f [$kid slot _frame]

	foreach {o v} $opts {
		switch $o {
			-ttk {$self slot ttk $v}
		}
	}

	set p ${f}.p
	$kid slot button $p

	if {[$self slot ttk]} {
		ttk::button $p -textvariable [$kid slotVar _value] -command [list $kid goto]
	} else {
		button $p -textvariable [$kid slotVar _value] -command [list $kid goto]
	}

	place $p -relwidth .98 -anchor n -relx .5 -rely 0

	return $f
} 

# Go to the specified path. We use the path cell itself
# as the current cell, if needed for resolution. We also
# make the cell if it doesn't exist yet.
#
APPath method goto {} {
	set v [$self slot _value]
	set c [$self slot _cell]
	set x [$c slot core]

	if {$v ne ""} {
		[$self slot tool] navupdown [$x resolve $c 1]
	}
}
