### A simple panel for viewing an atomic cell via
### a boolean switch
###
# PJM	2008-05-13	Begun

AtomicPanel construct APBoolean

APBoolean slot borderwidth 4

APBoolean slot oncolor	#009600
APBoolean type oncolor	<color>

APBoolean slot offcolor	#535353
APBoolean type offcolor	<color>


# Given the parent widget and the cell, construct
# and return the panel
#
APBoolean method build {mom tool c {opts {}} {w {}} {h {}}} {
	set kid [$self buildFrame $mom $c $w $h]
	$kid slot tool $tool

	set f [$kid slot _frame]

	foreach {o v} $opts {
		switch $o {
			-oncolor {$self slot oncolor $v}
			-offcolor {$self slot offcolor $v}
		}
	}

	bind $f <ButtonPress-1> [list $kid toggle]

	trace add variable [$kid slotVar _value] write [list $kid show]
	$kid show

	return $f
} 

# Toggle the value
#
APBoolean method toggle {} {
	set v [$self slot _value]
	if {$v eq ""} {
		$self slot _value 1
	} else {
		$self slot _value [! $v]
	}
}

# Show the current value
#
APBoolean method show {args} {
	set f [$self slot _frame]
	set v [$self slot _value]

	if {$v ne "" && $v} {
		$f configure -background [$self slot oncolor] -relief sunken
	} else {
		$f configure -background [$self slot offcolor] -relief raised
	}
}
