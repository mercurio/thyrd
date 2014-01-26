### A simple panel for viewing an atomic cell via
### a spinbox widget
###
###
# PJM	2008-05-13	Begun
# PJM	2008-11-20	Makes sure range is large enough for current value

AtomicPanel construct APSpinbox

APSpinbox slot deferredValidation 1

# Given the parent widget and the cell, construct
# and return the panel
#
APSpinbox method build {mom tool c {opts {}} {w {}} {h {}}} {
	set kid [$self buildFrame $mom $c $w $h]
	$kid slot tool $tool

	set bg [$kid slot _frame]

	array set options {
		-from 	0
		-to		100
		-increment 1
	}

	foreach {o v} $opts {
		switch $o {
			-from	{set options(-from) $v}
			-to		{set options(-to) $v}
			-step	{set options(-increment) $v}
			-fts	{
				if {$v ne ""} {
					set f ""
					set t ""
					set s ""

					lassign $v f t s

					if {$f ne ""} {set options(-from) $f}
					if {$t ne ""} {set options(-to) $t}
					if {$s ne ""} {set options(-increment) $s}
				}
			}
		}
	}

	set val [$c get]
	if {$val ne ""} {
		if {$options(-from) > $val} {set options(-from) $val}
		if {$options(-to) < $val} {set options(-to) $val}
	}

	set p ${bg}.p

	spinbox $p -textvariable [$kid slotVar _value] {*}[array get options]
	
	place $p -relwidth .98 -anchor n -relx .5 -rely 0

	$kid deferValidation 

	return $bg
} 
