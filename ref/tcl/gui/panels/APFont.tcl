### A simple panel for viewing an atomic cell via
### a font button
###
# PJM	2008-05-13	Begun

AtomicPanel construct APFont

# Given the parent widget and the cell, construct
# and return the panel
#
APFont method build {mom tool c {opts {}} {w {}} {h {}}} {
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

	set l ${f}.l
	$kid slot label $l

	if {[$self slot ttk]} {
		ttk::button $p -text "Select font" -command [list $kid chooseFont $p]
		ttk::label $l -textvariable [$kid slotVar _value] -font [$kid slot _value]
	} else {
		button $p -text "Select font" -command [list $kid chooseFont $p]
		label $l -textvariable [$kid slotVar _value] -font [$kid slot _value]
	}

	place $p -relwidth .98 -anchor n -relx .5 -rely 0
	place $l -relwidth .98 -anchor s -relx .5 -rely 1
	raise $p

	trace add variable [$kid slotVar _value] write [list $kid show]
	$kid show

	return $f
} 

# Show the current value
#
APFont method show {args} {
	set p [$self slot label]
	set v [$self slot _value]

	if {$v ne ""} {
		$p configure -font $v
	}
}

# Choose a new font
#
APFont method chooseFont {p} {
	set v [$self slot _value]

	set nf [SelectFont .fontdlg[Object anon] -parent $p -font $v]
	if {$nf != "" && $nf != $v} {
		$self slot _value $nf
	}
}
