# AtomicPanel -- a control panel for an atomic
# cell.
#
# PJM 2007-03-19	Begun
# PJM 2010-07-01	Supports ok/cancel on all panels at once.
#

Panel construct AtomicPanel

# Defaults

# If true, use ttk instead of tk
AtomicPanel slot ttk	1
AtomicPanel type ttk	<boolean>


AtomicPanel slot borderwidth 1
AtomicPanel slot relief ridge

# Make the frame and do the rest of the
# set up common to all atomic panels.
# We return the child object configured
# with a slot ``_frame`` containing the
# frame and a slot ``_value`` that holds
# the value being edited.
#
# If the width and height are not provided,
# mom is a frame and fill it.
#
AtomicPanel method buildFrame {mom c {w {}} {h {}}} {
	set f $mom.[Object safeName [Object anon]]

	set bw [$self slot borderwidth]

	if {$w eq "" || $h eq ""} {
		frame $f -relief [$self slot relief] -borderwidth $bw
		pack $f -expand 1 -fill both
	} else {
		frame $f -width [expr {$w-$bw}] -height [expr {$h-$bw}] \
			-relief [$self slot relief] -borderwidth $bw

		place $f -width $w -height $h
	}

	set kid [[$self construct *] glomOnto $f]

	$c addObserver write $kid cellWrite
	$c addObserver read $kid cellRead

	$kid slot _frame $f
	$kid slot _cell $c
	$kid slot _value [$c get]

	$kid deferValidation
	$kid slotOn _value >

	return $kid
} 

# Set whether we defer validation or not 
#
AtomicPanel method deferValidation {{x 1}} {
	if {$x} {
		$self method _value> {v} [list $self changedDeferred]
	} else {
		$self method _value> {v} [list $self changedImmediate]
	}
}

## There are two ``changed`` methods, one of them
## should be bound to some event that indicates
## the widget has changed. 
## Both methods ignore their arguments so they
## can be easily used as callbacks.

# ``_value`` has changed, defer validation until
# the ok button is pressed later.  We return 1
# to indicate that it's valid so far.
#
AtomicPanel method changedDeferred {args} {
	if {[$self slot _value] ne [[$self slot _cell] get]} {
		$self drawValidator
	} else {
		$self eraseValidator
	}

	return 1
}

# ``_value`` has changed, validate it now
#
AtomicPanel method changedImmediate {args} {
	if {[$self slot _value] ne [[$self slot _cell] get]} {
		return [$self validateCell]
	} 

	return 1
}

# Validate ``_value`` to see if it can be
# used as a value for our ``_cell``.
#
# If an argument is provided, it's used instead
# of ``_value``
#
AtomicPanel method validateCell {args} {
	set c [$self slot _cell]

	if {[llength $args] == 0} {
		set new [$self slot _value]
	} else {
		set new [lindex $args 0]
	}

	if {[$c validate $new]} {
		Observer ignore $self $c {theSpace editSet $c $new}
		return true
	} else {
		return false
	}
}

# Draw the ok/cancel buttons that trigger or
# cancel validation of ``_value``.
#
AtomicPanel method drawValidator {} {
	set f [$self slot _frame]
	set v ${f}.validator

	if {[winfo exists $v]} {
		#raise $v
		return
	}

	#frame $v -borderwidth 2 -relief ridge
	#button ${v}.ok -image [Thyrd getImage ok] -command [list $self okButton]
	#button ${v}.cancel -image [Thyrd getImage cancel] -command [list $self cancelButton]

	frame $v -borderwidth 0 -background ""
	label ${v}.ok -image [Thyrd getImage ok] -borderwidth 0
	label ${v}.cancel -image [Thyrd getImage cancel] -borderwidth 0


	bind ${v}.ok <ButtonRelease-1> [list $self okButton]
	bind ${v}.ok <ButtonRelease-3> [list $self okAll $v]

	bind ${v}.cancel <ButtonRelease-1> [list $self cancelButton]
	bind ${v}.cancel <ButtonRelease-3> [list $self cancelAll $v]

	bindtags ${v}.ok [list ${v}.ok]
	bindtags ${v}.cancel [list ${v}.cancel]

	grid ${v}.ok ${v}.cancel
	place $v -anchor se -relx 1 -rely 1
	raise $v
}

# Ok all the ok buttons. Given one validator,
# find all the validators that belong to the
# same window and trigger their <1> binding.
#
AtomicPanel method okAll {v} {
	set z [winfo parent [winfo parent $v]]

	foreach i [winfo children $z] {
		foreach j [winfo children $i] {
			if {[string match *validator $j]} {
				eval [bind ${j}.ok <ButtonRelease-1>]
			}
		}
	}
}

# Cancel all the cacnel buttons. Given one validator,
# find all the validators that belong to the
# same window and trigger their <1> binding.
#
AtomicPanel method cancelAll {v} {
	set z [winfo parent [winfo parent $v]]

	foreach i [winfo children $z] {
		foreach j [winfo children $i] {
			if {[string match *validator $j]} {
				eval [bind ${j}.cancel <ButtonRelease-1>]
			}
		}
	}
}

# Erase the ok/cancel buttons
#
AtomicPanel method eraseValidator {} {
	destroy [$self slot _frame].validator
}

# The OK button has been hit.  If we successfully
# update the cell, get rid of the buttons.
#
AtomicPanel method okButton {} {
	if {[$self validateCell]} {
		$self eraseValidator
		return
	}

	UserMsg warning "This cell will not accept a value of $v"
}

# The Cancel button has been hit, restore the old value.
#
AtomicPanel method cancelButton {} {
	$self slotSuspend _value [[$self slot _cell] get]
	$self eraseValidator
}

# Called when the cell is changed
#
AtomicPanel method cellWrite {target event args} {
	set rc [$self viewCell]
	set rootEvent [string equal $target $rc]

	if {$rootEvent} {
		$self slot _value [$rc get]
	} else {
		UserMsg warning "|$self cellEvent $target $event $args| Not root event, this shouldn't happen (rc = $rc)"
	}
}

# Called when the cell is read
#
AtomicPanel method cellRead {target event args} {
}
