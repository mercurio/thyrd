# ButtonCombo - a Frame consisting of a Button
# 	and an ArrowButton with a drop-down list
#
# PJM 2005-10-06	Based on Poet's SignCombo and SignEntry
#

Tk_Frame construct ButtonCombo

# List of strings for menu.
# When changed, popup menu needs to be invalidated.
#
ButtonCombo slot> values "" {$self slot validvalues 0}

# Is value list valid?
#
ButtonCombo slot validvalues 1

# Is popup up?
#
ButtonCombo slot popupUp 0

# Name of popup widget
#
ButtonCombo slot pup	""

# Command to be executed when the menu is posted
#
ButtonCombo slot postcommand ""

# The maximum menu height, in number of items
#
ButtonCombo slot maxmenuheight 10

# Write-active slot for the image used on the button.
#
ButtonCombo slot> image {} {
	Object safe	[$self slot _btn] configure -image $value
}

# Write-active slot for the helptext used on the button.
#
ButtonCombo slot> helptext {} {
	Object safe	[$self slot _btn] configure -helptext $value
}

# Write-active slot for the command executed by the button.
#
ButtonCombo slot> command {} {
	Object safe	[$self slot _btn] configure -command $value
}

# Write-active slot to set the state of the button and arrow
#
ButtonCombo slot> state disabled {
	Object safe	[$self slot _btn] slot state $value
	Object safe	[$self slot _ab] slot state $value
}

# Build the primary for a ButtonCombo. 
#
ButtonCombo method buildPrimary {} {
    $self destroyPrimary

    set prim [$self as Tk_Frame buildPrimary]

    set stateFormula [format {
		if {[%s slotLength values] > 0} {return normal} else {return disabled}
    } $self]

    set bb [BW_Button construct * $self -layout {-side left} \
		-relief link -borderwidth 1 -padx 1 -pady 1]

	$self slot _btn $bb
	$bb formula state $stateFormula
    $bb slotConstrain state

    set ab [BW_ArrowButton construct * $self -layout {-side right -fill y} \
		-highlightthickness 0 \
		-relief flat -state normal -dir bottom -type button \
		-command "$self popupVMenu $prim"]

    $self slot _ab $ab
	$ab formula state $stateFormula
    $ab slotConstrain state

    return $prim
}

# Construct and pop up the menu of values
#
ButtonCombo method popupVMenu {p} {
    if {![$self slotLength values]} return

	set mw ${p}.popup

	#DEFERRED  want arrow button hit while displayed to drop menu
	if {0 && [winfo exists $mw] && [winfo ismapped $mw]} {
		destroy $mw
		return
	} 

	catch {destroy $mw}

	set m [menu $mw]
	set i 0
	foreach v [$self slot values] {
		$m add command -label $v -command [concat [$self slot command] $i]
		incr i
	}

	set bx [winfo rootx $p]
	set by [winfo rooty $p]

	#set x [expr $bx + [winfo reqwidth $p]]
	set x $bx
	set y [expr $by + [winfo reqheight $p]]

	return [tk_popup $mw $x $y]
}
