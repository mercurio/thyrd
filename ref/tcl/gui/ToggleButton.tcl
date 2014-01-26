# ToggleButton - a Button that toggles between up and down.
# Meant to be compatible with LatchButton, so they can be
# used interchangeably.
#
# The command slot should contain a script that
# should be eval'd when the state changes, with
# "up", "down" or "locked" appended. A ToggleButton,
# however, is never locked.
#
# PJM 2008-04-08	Derived from LatchButton
#

BW_Label construct ToggleButton

ToggleButton slot relief	raised
ToggleButton slot borderwidth	1

ToggleButton slot prebuildOptions {image helptext}
ToggleButton slot extraOptions {command onimage}

ToggleButton slot lstate up
ToggleButton type lstate "<choice> up down"

# Build a ToggleButton
#
ToggleButton method buildPrimary {} {
	set p [$self as BW_Label buildPrimary]

	$self slot offimage [$self slot image]
	$self slot lstate up
	bind $p <ButtonRelease-1> [list $self _toggle]

	return $p
}

# Toggle the state of the button and invoke
# the command.
#
ToggleButton method _toggle {} {
	set com [$self slot command]
	set on [$self slot onimage]
	set off [$self slot offimage]

	set nstate [? {[$self slot lstate] eq "up"} down up]

	$self slot lstate $nstate
	$self _show

	eval {*}$com $nstate
}

# Set the toggle button to a given value, without
# triggering the command.
#
ToggleButton method set {x} {
	$self slot lstate $x
	$self _show
}

# Display the current state
#
ToggleButton method _show {} {
	set com [$self slot command]
	set on [$self slot onimage]
	set off [$self slot offimage]

	if {[$self slot lstate] eq "down"} {
		$self slot relief sunken
		if {$on ne ""} {$self slot image $on}
	} else {
		$self slot relief raised
		if {$on ne ""} {$self slot image $off}
	}
}
