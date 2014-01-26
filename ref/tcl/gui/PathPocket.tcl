### PathPocket - Frame containing an icon and a
### PathEntry displaying a cell's path and type
#
# PJM 20080401	Based on SignEntry
#

Tk_Frame construct PathPocket
PathPocket mixin PathWidget

PathPocket slot> pathName 	"" {$self PathWidget_setEditPath $value}

# Default appearance of frame
PathPocket slot relief flat
PathPocket slot borderwidth 2

# Build the primary for a PathPocket. 
# SignWidget requires subText and subType.
#
PathPocket method buildPrimary {} {
    $self destroyPrimary

	$self destroyPrimary

    set prim [$self as Tk_Frame buildPrimary]

	$self slot pathName [$self slot pathName]
	$self slot command "$self PathWidget_cmd"

	$self PathWidget_config

    $self slot icon [Tk_Label construct * $self -layout {grid -row 1 -column 1} \
		-image [Thyrd getImage type-blank]]

    $self slot textbox [PathEntry construct * $self \
		-notify [list $self setIcon] \
	    -layout {grid -row 1 -column 2 -sticky ew}]

	grid columnconfigure $prim 2 -weight 1

    return $prim
}

# Set the icon when the path changes
#
PathPocket method setIcon {p} {
	set c [theSpace find $p]
	set icon [$self slot icon]

	if {$c eq ""} {
		$icon slot image [Thyrd getImage type-blank]
	} else {
		$icon slot image [$c getGlyph]
	}
}

# Clear the entry and icon
#
PathPocket method clear {} {
	[$self slot textbox] set ""
}
