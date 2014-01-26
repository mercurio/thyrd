### A panel for viewing a cell as one of the frames
### from an animated gif or png file.
###
# PJM	2008-11-21	Begun

AtomicPanel construct APAnimation

APAnimation slot borderwidth 0

# Given the parent widget and the cell, construct
# and return the panel
#
APAnimation method build {mom tool c {opts {}} {w {}} {h {}}} {
	set kid [$self buildFrame $mom $c $w $h]
	$kid slot tool $tool

	set f [$kid slot _frame]

	$kid slot anim "tao"
	set sticky ""

	foreach {o v} $opts {
		switch $o {
			-anim {$kid slot anim $v}
			-min {$kid slot min $v}
			-max {$kid slot max $v}
			-sticky {set sticky $v}
		}
	}

	set p ${f}.p

	set im [Thyrd getAnim anim-[$kid slot anim] [$c get]]
	label $p -image $im -borderwidth 0

	if {![$im transparency get 0 0]} {
		$f configure -background [Colors fromRGB {*}[$im get 0 0]]
	}

	place $p -anchor n -relx .5 -rely 0

	bind $f <ButtonPress-1> [list $kid advance]
	bind $p <ButtonPress-1> [list $kid advance]
	bind $f <ButtonPress-3> [list $kid retreat]
	bind $p <ButtonPress-3> [list $kid retreat]
	$kid deferValidation 0

	trace add variable [$kid slotVar _value] write [list $kid show]
	$kid show

	return $f
} 

# Show the current value
#
APAnimation method show {args} {
	set f [$self slot _frame]
	set v [$self slot _value]

	set p ${f}.p

	$p configure -image [Thyrd getAnim anim-[$self slot anim] $v]
}

# Increment the value, but keep it in bounds if provided. We wrap
# around to the min value if max is exceeded and min is provided,
# else we just don't increment.
#
APAnimation method advance {} {
	set v [$self slot _value]
	set max [$self slot max]

	if {$max eq ""} {
		$self slot _value [+ $v 1]
	} else {
		incr v
		if {$v > $max} {
			set min [$self slot min]
			if {$min eq ""} {
				return
			} else {
				$self slot _value $min
			}
		} else {
			$self slot _value $v
		}
	}
}

# Decrement the value, but keep it in bounds if provided. We wrap
# around just like ``advance``.
#
APAnimation method retreat {} {
	set v [$self slot _value]
	set min [$self slot min]

	if {$min eq ""} {
		$self slot _value [- $v 1]
	} else {
		incr v -1

		if {$v < $min} {
			set max [$self slot max]
			if {$max eq ""} {
				return
			} else {
				$self slot _value $min
			}
		} else {
			$self slot _value $v
		}
	}
}
