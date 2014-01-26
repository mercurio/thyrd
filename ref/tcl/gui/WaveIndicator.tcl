### WaveIndicator - a Frame consisting of a Label
### and an ArrowButton with a drop-down list, displaying
### and controling the state of a Wave.
###
### The arrow button is now optional.
#
# PJM 2007-11-27	Created, based on ButtonCombo
#

Tk_Frame construct WaveIndicator

# If true, add arrow button, else label pops up menu
WaveIndicator slot addArrow	0
WaveIndicator type addArrow	<boolean>

WaveIndicator slot extraOptions addArrow

# The wave we're monitoring
#
WaveIndicator slot wave ""

# Is popup up?
#
WaveIndicator slot popupUp 0
WaveIndicator type popupUp <boolean>

# Name of popup widget
#
WaveIndicator slot pup	""

# Command to be executed when the menu is posted
#
WaveIndicator slot postcommand ""

# Write-active slot for the image used on the label.
#
WaveIndicator slot> image {} {
	Object safe	[$self slot _lbl] configure -image $value
}

# Write-active slot for the helptext used on the label.
#
WaveIndicator slot> helptext {} {
	Object safe	[$self slot _lbl] configure -helptext $value
}

# Write-active slot to set the state of the button and arrow
#
WaveIndicator slot> state normal {
	Object safe	[$self slot _lbl] slot state $value
	Object safe	[$self slot _ab] slot state $value
}

# Build the primary for a WaveIndicator. 
#
WaveIndicator method buildPrimary {} {
    $self destroyPrimary

    set prim [$self as Tk_Frame buildPrimary]

	if {[$self slot addArrow]} {
		set lbl [BW_Label construct * $self -layout {-side left} \
			-image [$self stateImage ""] \
			-relief flat -borderwidth 1 -padx 1 -pady 1]

		$self slot _lbl $lbl

		set ab [BW_ArrowButton construct * $self -layout {-side right -fill y} \
			-relief flat -state normal -dir bottom -type button \
			-command "$self popupWMenu $prim"]

		$self slot _ab $ab
	} else {
		set lbl [BW_Label construct * $self -layout {-side left} \
			-image [$self stateImage ""] \
			-relief flat -borderwidth 1 -padx 1 -pady 1]

		$lbl bind <ButtonRelease-1> "$self popupWMenu $prim"

		$self slot _lbl $lbl
		$self slot _ab ""
	}

    return $prim
}

# Return the image for a wave's state
#
WaveIndicator method stateImage {w} {
	if {$w eq ""} {
		return [Thyrd getImage wi-none]
	} else {
		return [Thyrd getImage wi-[$w slot state]]
	}
}

# Construct and pop up the menu to operate on the wave
#
WaveIndicator method popupWMenu {p} {
	set mw ${p}.popup
	
	set w [$self slot wave]

	catch {destroy $mw}
	menu $mw -tearoff 0

	if {$w eq ""} {
		$mw add command -label "No wave"
	} else {
		$mw add command -label "Wave ${w} [$w slot state]"
		$mw add separator
		$mw add command -label "Reset" -command "$w reset"
		$mw add command -label "Start" -command "$w start"
		$mw add command -label "Suspend" -command "$w suspend"
		$mw add separator
		$mw add command -label "View" -command "puts \[ $w print \]"
	}

	set bx [winfo rootx $p]
	set by [winfo rooty $p]

	set x $bx
	set y [expr $by + [winfo reqheight $p]]

	return [tk_popup $mw $x $y]
}

# Attach to a Wave
#
WaveIndicator method attachTo {w} {
	set ww [$self slot wave]
	if {$ww ne ""} {
		$ww deleteObserver state $self
	}

	if {$w ne ""} {
		$w addObserver state $self stateDelta
	}

	$self slot wave $w
	$self stateDelta
}

# Respond to a state change in the wave
#
WaveIndicator method stateDelta {args} {
	set w [$self slot wave]
	Object safe [$self slot _lbl] slot image [$self stateImage $w]
}
