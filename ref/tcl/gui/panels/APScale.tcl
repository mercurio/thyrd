### A simple panel for viewing an atomic cell via
### a scale widget, Tk/Tile version.
###
### Note: the integer option doesn't work with Ttk
###
# PJM	2007-04-23	Quick hack to test feasibility
# PJM	2008-05-12	Added options, Tk/Tile via option
# PJM	2008-05-13	Added label, via option
# PJM	2008-11-20	Makes sure range is large enough for current value

AtomicPanel construct APScale

APScale slot deferredValidation 1

APScale slot showLabel	1
APScale type showLabel  <boolean>

# Given the parent widget and the cell, construct
# and return the panel
#
APScale method build {mom tool c {opts {}} {w {}} {h {}}} {
	set kid [$self buildFrame $mom $c $w $h]
	$kid slot tool $tool

	set bg [$kid slot _frame]

	array set options {
		-from 	0
		-to		100
		-resolution 1
		-orient	horizontal
	}

	foreach {o v} $opts {
		switch $o {
			-from	{set options(-from) $v}
			-to		{set options(-to) $v}
			-step	{set options(-resolution) $v}
			-integer	{ 
				set options(-resolution) [? $v 1 0.5]
				set integer $v
			}
			-fts	{
				if {$v ne ""} {
					set f $options(-from)
					set t $options(-to)
					set s $options(-resolution)

					lassign $v f t s

					set options(-from) $f
					set options(-to) $t
					set options(-resolution) $s
				}
			}
			-orient {
				if {$v eq "auto"} {
					set options(-orient) [? {$w > $h} horizontal vertical]
				} else {
					set options(-orient) $v
				}
			}
			-ttk {$self slot ttk $v}
			-label {$self slot showLabel $v}
			-showvalue {set options(-showvalue) $v}
		}
	}

	set val [$c get]
	if {$val ne ""} {
		if {$options(-from) > $val} {set options(-from) $val}
		if {$options(-to) < $val} {set options(-to) $val}
	}

	set p ${bg}.p
	set l ${bg}.l
	set show [$self slot showLabel]

	if {[$self slot ttk]} {
		unset options(-resolution)
		ttk::scale $p -variable [$kid slotVar _value] {*}[array get options]
		if {$show} {
			ttk::label $l -textvariable [$kid slotVar _value]
		}
	} else {
		scale $p -variable [$kid slotVar _value] {*}[array get options]
		if {$show} {
			label $l -textvariable [$kid slotVar _value]
		}
	}

	
	place $p -anchor c -relwidth .9 -relheight .9 -relx .5 -rely .5

	if {$show} {
		#place $l -anchor s -relx .5 -rely 1
		place $l -anchor nw -relx 0 -rely 0
	}


	$kid deferValidation 

	return $bg
} 
