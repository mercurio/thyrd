### Manage the type-specific panes on the EditBar when 
### viewing an atomic cell.
###
### Supported:
###		<integer> lo hi step
###		<pixels> lo hi step
###		<real> lo hi step
###		<boolean> true false
###		<choice> list ...
###		
###
# PJM	2008-10-21	Begun

Object construct EditBarTypes

# The list of panes, going from the type to an
# internal code. The "other" pane is "oth"
#
EditBarTypes arraySet map <integer>	entry3
EditBarTypes arraySet map <pixels>	entry3
EditBarTypes arraySet map <real>	entry3
EditBarTypes arraySet map <boolean>	entry2
EditBarTypes arraySet map <choice>	entry1


# Make all of the frames inside the given frame with the
# given column
#
EditBarTypes method makeFrames {fr col} {
	Tk_Frame construct $self-oth $fr -borderwidth 0 -layout "grid -column $col -row 0 -sticky news"
	$self build-oth $self-oth

	$self slot lo
	$self slot hi
	$self slot step
	$self slot choices
	$self slot tvalue
	$self slot fvalue

	foreach k [EditBarTypes arrayKeys map] {
		set code [EditBarTypes arrayGet map $k]

		if {![Object exists $self-$code]} {
			Tk_Frame construct $self-$code $fr -borderwidth 0 -layout "grid -column $col -row 0 -sticky news"
			$self build-$code $self-$code
		}
	}
}

# Build the other edit pane
#
EditBarTypes method build-oth {f} {
}

# Build the 3-entry edit pane
#
EditBarTypes method build-entry3 {f} {
	Tk_Label construct * $f -text "Low:" -layout "grid -column 1 -row 0"
	$self slotAppend entries [Tk_Entry construct * $f -textvariable [$self slotVar lo] \
		-layout "grid -column 2 -row 0 -sticky news" \
		-validate all -validatecommand [list $self delta %W %P lo]]

	Tk_Label construct * $f -text "High:" -layout "grid -column 3 -row 0"
	$self slotAppend entries [Tk_Entry construct * $f -textvariable [$self slotVar hi] \
		-layout "grid -column 4 -row 0 -sticky news" \
		-validate all -validatecommand [list $self delta %W %P hi]]

	Tk_Label construct * $f -text "Step:" -layout "grid -column 5 -row 0"
	$self slotAppend entries [Tk_Entry construct * $f -textvariable [$self slotVar step] \
		-layout "grid -column 6 -row 0 -sticky news" \
		-validate all -validatecommand [list $self delta %W %P step]]

	grid columnconfigure [$f primary] {2 4 6} -weight 1
}

# Build the 2-entry edit pane
#
EditBarTypes method build-entry2 {f} {
	Tk_Label construct * $f -text "True:" -layout "grid -column 1 -row 0"
	$self slotAppend entries [Tk_Entry construct * $f -textvariable [$self slotVar tvalue] \
		-layout "grid -column 2 -row 0 -sticky news" \
		-validate all -validatecommand [list $self delta %W %P tvalue]]

	Tk_Label construct * $f -text "False:" -layout "grid -column 3 -row 0"
	$self slotAppend entries [Tk_Entry construct * $f -textvariable [$self slotVar fvalue] \
		-layout "grid -column 4 -row 0 -sticky news" \
		-validate all -validatecommand [list $self delta %W %P fvalue]]

	grid columnconfigure [$f primary] {2 4} -weight 1
}

# Build the 1-entry edit pane
#
EditBarTypes method build-entry1 {f} {
	Tk_Label construct * $f -text "Choices:" -layout "grid -column 1 -row 0"
	$self slotAppend entries [Tk_Entry construct * $f -textvariable [$self slotVar choices] \
		-layout "grid -column 2 -row 0 -sticky news" \
		-validate all -validatecommand [list $self delta %W %P choices]]

	grid columnconfigure [$f primary] 2 -weight 1
}

# Sync to the given cell's type
#
EditBarTypes method syncToCell {c} {
	$self slot cell $c
	if {$c eq ""} return

	set ty [$c getType]
	set ty0 [lindex $ty 0]
	$self slot ty0 $ty0

	if {![EditBarTypes arrayHas map $ty0]} {
		$self-oth raise
	} else {
		switch $ty0 {
			<integer>	-
			<real>		-
			<pixels>	{
				lassign [Type getParams $ty] lo hi step
				$self slot sav-lo [$self slot lo $lo]
				$self slot sav-hi [$self slot hi $hi]
				$self slot sav-step [$self slot step $step]
			}
			<boolean>	{
				lassign [Type getParams $ty] t f
				$self slot sav-tvalue [$self slot tvalue $t]
				$self slot sav-fvalue [$self slot fvalue $f]
			}
			<choice>	{
				$self slot sav-choices [$self slot choices [Type getParams $ty]]
			}
		}

		$self save

		set p [EditBarTypes arrayGet map $ty0]
		$self-$p raise
	}

}

# Save the current pane values, and clear all the backgrounds
#
EditBarTypes method save {} {
	foreach x {lo hi step tvalue fvalue choices} {
		$self slot sav-$x [$self slot $x]
	}

	foreach e [$self slot entries] {
		$e slot background white
	}
}

# 
# One of the fields has changed, change the background to 
# reflect that the type needs to be set.
#
EditBarTypes method delta {e val param} {
	if {$val eq [$self slot sav-$param]} {
		$e configure -background white
	} else {
		$e configure -background [Colors get editedEntryBG]
	}

	return 1
}

# Given a type, return the full type string including
# the parameters. 
# 
# This is only called when we're setting the type, so
# we save the params as well.
#
EditBarTypes method fullType {ty0} {
	$self save

	switch $ty0 {
		<integer>	-
		<real>		-
		<pixels>	{
			return "$ty0 [$self slot lo] [$self slot hi] [$self slot step]"
		}
		<boolean>	{
			return "$ty0 [$self slot tvalue] [$self slot fvalue]"
		}
		<choice>	{
			return "$ty0 [$self slot choices]"
		}
		default {
			return $ty0
		}
	}
}
