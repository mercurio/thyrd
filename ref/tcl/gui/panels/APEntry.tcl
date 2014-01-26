### A simple panel for viewing an atomic cell via
### a text entry.
###
# PJM	2007-03-19	Begun
# PJM	2007-04-23	Lots of functionality moved to AtomicPanel
# PJM	2008-05-12	Tk/Tile via option

AtomicPanel construct APEntry

# Given the parent widget and the cell, construct
# and return the panel
#
APEntry method build {mom tool c {opts {}} {w {}} {h {}}} {
	set kid [$self buildFrame $mom $c $w $h]
	$kid slot tool $tool

	set f [$kid slot _frame]

	foreach {o v} $opts {
		switch $o {
			-ttk {$self slot ttk $v}
		}
	}

	set p ${f}.p

	if {[$self slot ttk]} {
		ttk::entry $p -textvariable [$kid slotVar _value]
	} else {
		entry $p -textvariable [$kid slotVar _value]
	}

	#place $p -relwidth .9 -relx .05 -relheight .3 -rely .35
	place $p -relwidth .98 -anchor n -relx .5 -rely 0

	return $f
} 

