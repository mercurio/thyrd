### A simple panel for viewing an atomic cell via
### a color swatch and button
###
# PJM	2008-05-13	Begun

AtomicPanel construct APColor

APColor slot borderwidth 2

# Given the parent widget and the cell, construct
# and return the panel
#
APColor method build {mom tool c {opts {}} {w {}} {h {}}} {
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
		ttk::button $p -textvariable [$kid slotVar _value] -command [list $kid chooseColor $p]
	} else {
		button $p -textvariable [$kid slotVar _value] -command [list $kid chooseColor $p]
	}

	place $p -relwidth .98 -anchor n -relx .5 -rely 0

	trace add variable [$kid slotVar _value] write [list $kid show]
	$kid show

	return $f
} 

# Show the current value
#
APColor method show {args} {
	set f [$self slot _frame]
	set v [$self slot _value]

	if {$v ne ""} {
		$f configure -background $v
	}
}

# Choose a new color
#
APColor method chooseColor {p} {
    ColorMenuBox overrideColors
	set v [$self slot _value]

	if {$v eq ""} {
		set color [SelectColor::menu $p.colorMenu [list below $p]]
	} else {
		set color [SelectColor::menu $p.colorMenu [list below $p] \
			-color $v]
	}

	if {$color ne ""} {
		$self slot _value $color
	}
}
