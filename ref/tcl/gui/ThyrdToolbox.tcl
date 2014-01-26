# ThyrdToolbox - The main interface to Thyrd, always available
# via the <<THYRD_TOOLBOX>> action (usually the F7 key).  One of
# these will be instantiated as theThyrdToolbox.
#
# PJM 2000-01-09	Begun (as part of Poetics)
# PJM 2005-07-23	Thyrd toolbox begun.
# PJM 2006-03-16	Drag & Drop will be managed here (theThyrdToolbox holds the
#						data being dragged)
# PJM 2007-07-26	pockets and start/stop button added.
# PJM 2008-04-01	pockets replaced with PathPockets
#


Window construct ThyrdToolbox

ThyrdToolbox slot nPockets 6
ThyrdToolbox type nPockets "<integer> 0 20"

ThyrdToolbox slot running 0
ThyrdToolbox type running <boolean>

# Build the primary for a ThyrdToolbox
#
ThyrdToolbox method buildPrimary {} {
	$self destroyPrimary

	set demoMenus {}
	foreach d [Thyrd slot knownDemos] {
    	append demoMenus [format {
    		{command "%s demo" {} "Call the demo method on %s" {} -command "%s demo"}
			} $d $d $d]
    }

	set testMenus {}
	foreach t [Thyrd slot knownTests] {
    	append testMenus [format {
    		{command "%s" {} "Execute: %s" {} -command "%s"}
			} $t $t $t]
    }

    $self slot menu [format {
        "&Thyrd" all thyrd 1 {
            {command "&Empty pockets" {} "Empty pockets table" {} -command "%s emptyPockets"}
            {command "&Open Opcode table" {} "Open a new cell editor on the opcode table" {} -command "%s openOps"}
            {command "Open &Heart" {} "Open a new cell editor on the heart cell" {} -command "%s openHeart"}
			{separator}
            {command "Hide &toolbox (F7 to recall)" {} "Hide this toolbox window" {} -command "%s hide"}
            {command "&Command console" {} "Open the Tcl command console" {} -command "showConsole"}
            {command "&REST server" {} "Open the REST server monitor" {} -command "%s showRestServer"}
            {command "E&xit" {} "Exit" {} -command "Thyrd finalize"}
            {command "Crash" {} "Crash" {} -command "Thyrd::crash"}
        }
        "&Poet" all poet 1 {
            {command "&Browse objects" {} "Open Poet Object Browser" {} -command "ObjectEditorTool new Thyrd"}
            {command "E&dit code" {} "Open Poet Code Editor" {} -command "CodeEditorTool new"}
			{separator}
        	%s
        }
        "T&ests" all tests 1 {
        	%s
        }
    } $self $self $self $self $self $demoMenus $testMenus]

	set prim [$self as MainFrameTool buildPrimary]
	set mf [$self getFrame]

	$self wm withdraw
	$self wm title "Thyrd"
	#$self wm protocol WM_DELETE_WINDOW "$self hide"
	$self wm protocol WM_DELETE_WINDOW "exit"
	$self wm minsize 160 10

	# sub frames
	set bf [Tk_Frame construct * $mf \
		-layout {-side top -expand 0 -fill y}]
	set pf [Tk_Frame construct * $mf \
		-layout {-side top -expand 1 -fill both}]
	set sf [Tk_Frame construct * $mf \
		-layout {-side top -expand 0 -fill y}]

	# Button bar
	BW_Button construct * $bf -image [Thyrd getImage newTable] \
		-relief link -borderwidth 1 -padx 1 -pady 1 -helptext "Cell editor" \
		-layout {-side left -padx 1} -command "Window newWindow CellEditor"
		
	BW_Button construct * $bf -image [Thyrd getImage newWaveEd] \
		-relief link -borderwidth 1 -padx 1 -pady 1 -helptext "Wave editor" \
		-layout {-side left -padx 1} -command "Window newWindow WaveEditor"
		
	if 0 { ;# DEFERRED crappy editor anyway
	BW_Button construct * $bf -image [Thyrd getImage newIconEd] \
		-relief link -borderwidth 1 -padx 1 -pady 1 -helptext "Icon editor" \
		-layout {-side left -padx 1} -command "Window newWindow IconEditor"
	}
		
	# Pockets
	$self slot _pockets ""
	for {set i 0} {$i < [$self slot nPockets]} {incr i} {
		$self slotAppend _pockets [PathPocket construct * $pf \
			-relief flat -padx 4 \
			-layout {-side top -expand 1 -fill x}]
	}

	# Start/Stop button
	set ss [$self slot _ssBtn [BW_Label construct * $sf -image [Thyrd getImage big-stop-norm] \
		-relief flat -borderwidth 0 -padx 1 -pady 1 -helptext "Start waves" \
		-layout {-side bottom -pady 4}]]

	$ss bind <ButtonRelease-1> [list $self startStop]
	$self startStop 0

	# Stats in status bar
	set st [$self getStatusBar]

	set wi [WaveIndicator construct * $st -layout {grid -row 1 -column 1}]
	$wi attachTo [theSpace slot wave]

	$self slot _stat1 [BW_Label construct * $st -font smbtn -padx 1 -pady 2 -relief flat \
		-borderwidth 0 -text "0 / 0" -helptext "Active waves / Total waves" \
		-layout {grid -row 1 -column 2}]

	$self slot _stat2 [BW_Label construct * $st -font smbtn -padx 1 -pady 2 -relief flat \
		-borderwidth 0 -text "none" -helptext "Cut/Copy/Paste clipboard status" \
		-layout {grid -row 1 -column 3}]

	$self slot _stat2icon [Tk_Label construct * $st -image [Thyrd getImage clipboard] \
		-layout {grid -row 1 -column 4}]

	grid columnconfigure $st 2 -weight 1

	theSpace addObserver stats $self statsChanged
	theSpace addObserver clipboard $self clipboardChanged

	$self statsChanged
	$self clipboardChanged

	$self wm deiconify
    update idletasks
	return $prim
}

# Open the ops table in a new cell editor. Note that
# the ops table already has a panel triad that specifies
# the right panel to use.
#
ThyrdToolbox method openOps {} {
	Window newWindow CellEditor -path "/thyrd/ops" -gridpanels 1 -panels 1 -showNavBar 0 -showEditBar 0
}

# Open the heart cell in a new cell editor.
#
ThyrdToolbox method openHeart {} {
	Window newWindow CellEditor -path "/thyrd/heart" -panels 1 -showNavBar 0 -showEditBar 0 --w 400 --h 120
}

# Open the REST server monitor window
#
ThyrdToolbox method showRestServer {} {
	Window newWindow RestServer -port 33333 -on 0 --w 400 --h 120
}

# The stats have changed, display them
#
ThyrdToolbox method statsChanged {args} {
	set s [$self slot _stat1]

	$s slot text "[theSpace slot nActiveWaves] / [theSpace slot nWaves]"
}

# The clipboard has changed, display info
#
ThyrdToolbox method clipboardChanged {args} {
	set s [$self slot _stat2]
	set si [$self slot _stat2icon]
	set b [theSpace getClipboard]

	if {$b eq ""} {
		$s slot text ""
		$si slot image [Thyrd getImage clipboard-gray]
	} else {
		$si slot image [Thyrd getImage clipboard]

		if {[$b atomic]} {
			$s slot text "$b"
		} else {
			foreach {x y} [$b size] break
			$s slot text "[- $x 1]x[- $y 1]"
		}
	}
}

# Start or stop the wave engine.  If called with no argument, toggle,
# else set the specified state.  We assume that when we're called
# with no argument it's because the button was pressed, so we display
# the "over" image.
#
ThyrdToolbox method startStop {args} {
	if {[llength $args] == 0} {
		set r [expr {![$self slot running]}]
		set im over 
	} else {
		set r [lindex $args 0]
		set im norm 
	}

	set ss [$self slot _ssBtn]

	if {$r} {
		theSpace start

		$ss slot image [Thyrd getImage big-stop-$im]
		$ss bind <Enter> [list $ss slot image [Thyrd getImage big-stop-over]]
		$ss bind <Leave> [list $ss slot image [Thyrd getImage big-stop-norm]]
	} else {
		theSpace stop

		$ss slot image [Thyrd getImage big-start-$im]
		$ss bind <Enter> [list $ss slot image [Thyrd getImage big-start-over]]
		$ss bind <Leave> [list $ss slot image [Thyrd getImage big-start-norm]]
	}

	$self slot running $r
}

# Hide this window.  We can be recalled later by the <<THYRD_TOOLBOX>> event
#
ThyrdToolbox method hide {} {
	$self wm withdraw
}

# Empty the pockets table.
#
ThyrdToolbox method emptyPockets {} {
	foreach e [$self slot _pockets] {
		$e clear
	}
}

# Called when a drag is begun. $w is the
# Tk window the drag is coming from, and 
# $value is the data.
#
ThyrdToolbox method drag {w value} {
	$w config -cursor dot
	$self slot _dragging $value
	$self slot _dragW  $w
}

# Called on release of a drag from a table or label.
#
ThyrdToolbox method drop {x y} {
	if {[$self hasSlot _dragging]} {
		[$self slot _dragW] configure -cursor {}
		set e [winfo containing $x $y]

		switch [winfo class $e] {
			Label {
				$e configure -text [$self slot _dragging]
			}
			Table {
				set x [expr $x - [winfo rootx $e]]
				set y [expr $y - [winfo rooty $e]]
				$e set @$x,$y [$self slot _dragging]
			}
		}

		$self unslot _dragging
	}
}

