# TypeSelector - ButtonCombo displaying the possible
# types available.
#
# PJM 2008-02-11	Begun
#

ButtonCombo construct TypeSelector

# The Poet types we want to use (not all of the available types)
TypeSelector slot poetTypes [list <string> <boolean> <integer> <real> <color> <choice> <font> <pixels> <script> <variable>]


# Disable write-active slot for the command executed by the button.
#
TypeSelector method command> {com} {
}

# Build the primary
#
TypeSelector method buildPrimary {} {
	set p [$self as ButtonCombo buildPrimary]

	[$self slot _btn] configure -command [list $self select]

	set mw ${p}.popup
	set m [menu $mw]

	foreach t [$self slot poetTypes] {
		$m add command -image [Type getImage $t] -label $t \
			-compound left -command [list $self select $t]
	}

	$m add command -image [Thyrd getImage type-path] -label Path \
		-compound left -command [list $self select Path]

	$m add command -image [Thyrd getImage type-opcode] -label Opcode \
		-compound left -command [list $self select Opcode]

	$m add command -image [Thyrd getImage type-triad] -label Triad \
		-compound left -command [list $self select TriadCore]

	after idle [list $self setSelected <string>]
	return $p
}

# Set selected type
#
TypeSelector method setSelected {t} {
	switch $t {
		Path	{set im [Thyrd getImage type-path]}
		Opcode	{set im [Thyrd getImage type-opcode]}
		TriadCore	{set im [Thyrd getImage type-triad]}
		default {set im [Type getImage $t]}
	}
			
	[[$self slot _btn] primary] configure -image $im
	$self slot selected $t
}

# Select one of the types and trigger command
#
TypeSelector method select {{t {}}} {
	if {$t eq ""} {
		set t [$self slot selected]
	} else {
		$self setSelected $t
	}

	{*}[$self slot command] $t
}

# Pop up the menu of values
#
TypeSelector method popupVMenu {p} {
	set mw ${p}.popup

	set bx [winfo rootx $p]
	set by [winfo rooty $p]

	set x $bx
	set y [expr $by + [winfo reqheight $p]]

	return [tk_popup $mw $x $y]
}
