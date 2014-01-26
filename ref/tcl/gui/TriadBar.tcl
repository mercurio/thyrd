# A toolbar for forming Triads
#
# PJM	2005-10-06	Begun
# PJM	2007-03-28	Drag and drop added
#

Object construct TriadBar

# Given a toolbar window (output of MainFrameTool addToolBarSlot)
# construct the toolbar buttons
#
TriadBar method build {tb} {
	BW_Button construct * $tb -image [Thyrd getImage triad] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Form triad" \
		-layout {grid -padx 2 -column 0 -row 0} -command "$self triad"

	$self dnd A [Tk_Label construct * $tb -image [Thyrd getImage glyph-a-sm] -layout {grid -column 1 -row 0}]
	set w [$self slot _triadA [PathEntry construct * $tb -background [Colors get zTriadBGlite_A] \
		-layout {grid -sticky ew -column 2 -row 0}]]
	$w PathWidget_validation yes
	$self addMenu $w


	$self dnd Y [Tk_Label construct * $tb -image [Thyrd getImage glyph-y-sm] -layout {grid -column 3 -row 0}]
	set w [$self slot _triadY [PathCombo construct * $tb -background [Colors get zTriadBGlite_Y] \
		-values [theSpace listYs] -helptext "Use list to select one of the pre-defined Ys from /thyrd/ys" \
		-layout {grid -sticky ew -column 4 -row 0}]]

	$w slotAppend values ""
	$w PathWidget_validation yes
	$self addMenu $w

	$self dnd B [Tk_Label construct * $tb -image [Thyrd getImage glyph-b-sm] -layout {grid -column 5 -row 0}]
	set w [$self slot _triadB [PathEntry construct * $tb -background [Colors get zTriadBGlite_B] \
		-layout {grid -sticky ew -column 6 -row 0}]]
	$w PathWidget_validation yes
	$self addMenu $w

	BW_Button construct * $tb -image [Thyrd getImage erase] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Clear entries" \
		-layout {grid -padx 2 -column 7 -row 0} -command "$self erase"

	grid columnconfigure $tb {2 4 6} -weight 1
}

# Add the menu to a PathCombo, subsuming the POET menu
#
TriadBar method addMenu {w} {
	$w method popupMenu {path x y} [format {
		if {[$self hasSlot _popupMenu]} {
			return [$self slot _popupMenu]
		} else {
			set pm [$self as [$self parent] popupMenu $path $x $y]

			$pm insert 0 command -label "Create free cell with this value" -command [list %s makeFreeCell $self]

			$self slot _popupMenu $pm
			return $pm
		}
	} $self]
}

# Given one of the path entries, create a new free cell with
# that value and put the cell's path in the entry.
#
TriadBar method makeFreeCell {w} {
	set v [$w get]
	
	set c [Cell new $v <string>]
	$w set $c
}

# Given a label, set it up for drag and drop as per our needs
#
TriadBar method dnd {which pw} {
	set w [$pw primary]

	DragSite::register $w -dragevent 1 -draginitcmd [list $self dragInit $which]
	DropSite::register $w -dropcmd [list $self drop $which] \
		-droptypes  {SIGN {copy {}} TEXT {copy {}} }
}

# Called when dragging is initiated on a corner label
#
TriadBar method dragInit {which path rx ry topLvl} {
	set w [$self slot _triad$which]
	set p [$w get]

	if {$p eq ""} {return ""}

	if {[Path validate $p]} {
		Window dragImage $topLvl [Thyrd getImage type-path]
		return [list SIGN {copy} [list Path $p]]
	} else {
		Window dragImage $topLvl [Thyrd getImage type-string]
		return [list TEXT {copy} $p]
	}
}

# Called when something is dropped on a corner label.
#
TriadBar method drop {which target source rx ry op dtype data} {
	set w [$self slot _triad$which]

	switch $dtype {
		TEXT {$w set $data}
		SIGN {
			lassign $data what src
			switch $what {
				Cell {$w set [$src path]}
				Path {$w set $src}
			}
		}
	}

	return 1
}

# Clear (erase) the contents of the entries
#
TriadBar method erase {} {
	[$self slot _triadA] set ""
	[$self slot _triadB] set ""
	[$self slot _triadY] setvalue last
}

# Form the triad specified in the toolbar
#
TriadBar method triad {} {
	set a [[$self slot _triadA] get]
	set b [[$self slot _triadB] get]
	set y [[$self slot _triadY] get]

	if {$a eq "" || $b eq "" || $y eq ""} {
		UserMsg warning "|$self triad| All three cell paths must be specified"
		return
	}

	#DEFERRED handle not-paths here?

	theSpace bind $a $b $y
}
