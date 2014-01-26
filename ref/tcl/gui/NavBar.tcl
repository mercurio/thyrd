### A navigation toolbar.  This widget maintains the common
### state of a cell viewer.  We're a ``CellObserver``, so
### ``viewPath`` and ``viewCell`` can be used to get what
### we're viewing.  We also maintain a slot called ``mode`` 
### containing the currently selected mode.
###
### A NavBar modifies the paramList cells of a CellEditor,
### setting path when a new path is selected.  If we're
### animating, we set animate to 1 and direction to the
### direction of motion.
###
# PJM	2005-10-06	Begun
# PJM	2006-02-28	Observers and other functionality added.
# PJM	2006-06-09	Depth selector added
# PJM	2006-09-29	Modifications for paramList begun.  This
#					object is no longer observable, watch the
#					param cells instead
# PJM	2007-04-04	Panels button added
# PJM 	2007-04-09	DisplayControls added
# PJM	2008-01-29	Mode selector removed and replaced with latch buttons

Object construct NavBar
NavBar mixin CellObserver
NavBar mixin ParamListOwner
NavBar mixin Glommed


# common params used by any window with a NavBar
# DEFERRED should default for panels be 1 in production version?
#
NavBar slot _defaultParams {
	-path / 
	-mode {edit "<choice> edit descendOnce descendHold newviewOnce newviewHold"}
	-depth {1 "<integer> 1 5"}
	-animate {0 <boolean>} 
	-showing {grid "<choice> grid atomic"}
	-afontsize {10 <integer>}
	-direction {jump "<choice> jump down up updown"}
	-histback "" 
	-histfwd ""
}

# Called to set up watching of the cells in the paramList
#
# The cells containing the back and forward history are
# read-only, we get their values from the cell here but
# afterwards only changes to the HistoryButtons matter.
#
NavBar method watchParams {pl} {
	$pl watchSub! $self newPath path
	$pl watchSub! $self newDepth depth
	$pl watchSub! $self newMode mode
	$pl watchSub! $self newPanels panels
	$pl watchSub! $self newShowing showing
	$pl watchSub! $self newAFontSize afontsize

	[$self slot _back] linkToCell [$pl subCell histback]
	[$self slot _fwd] linkToCell [$pl subCell histfwd]
}

#  Observer handler methods
#
#  These are invoked when the cells are changed externally,
#  we just need to reflect the changes
#
NavBar method newPath {target event} {
	set path [$target get]

	if {![$self pathDelta $path]} return

	Object safe [$self slot _entry] configure -text $path
}

NavBar method newMode {target event} {$self showMode [$target get]}
NavBar method newPanels {target event} {[$self slot _panelsBtn] slot value [$target get]}
NavBar method newDepth {target event} {[$self slot _dbox] set [$target get]}
NavBar method newAFontSize {target event} {[$self slot _sbox] set [$target get]}

NavBar method newShowing {target event} {
	if {[$target get] eq "grid"} {
		[$self slot gridPanel] raise
	} else {
		[$self slot atomPanel] raise
	}
}

# Given a toolbar window (output of MainFrameTool addToolBarSlot)
# and a paramList cell, construct the navigation bar.
#
# The child object is glommed onto the toolbar, so that when the toolbar
# is destroyed so is the NavBar object.
#
NavBar method new {tb pl} {
	set kid [[$self construct *] glomOnto $tb]

	$kid slot paramList $pl
	$kid mixin Constrainable

	set col 0
	$kid slot _back [HistoryButton construct * $tb -image [Thyrd getImage back-on] \
		-helptext "Go back" \
		-layout "grid -column $col -row 0" -command "$kid navback"]

	incr col
	$kid slot _fwd [HistoryButton construct * $tb -image [Thyrd getImage forward-on] \
		-helptext "Go forward" \
		-layout "grid -column $col -row 0" -command "$kid navforward"]
	
	incr col
	set up [$kid slot _up [BW_Button construct * $tb -image [Thyrd getImage up-on] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Go up" \
		-layout "grid -padx 2 -column $col -row 0" -command "$kid navup"]]

	$up formula state [list $kid canNavup]
	$up slotConstrain state

	incr col
	$kid slot _descendBtn [LatchButton construct * $tb -image [Thyrd getImage navdown-sm] \
		-helptext "Click causes descend (Shift-click)" -command "$kid descendLatch" \
		-lockedbackground [Colors get descendHi] \
		-layout "grid -padx 2 -column $col -row 0"]

	incr col
	$kid slot _newviewBtn [LatchButton construct * $tb -image [Thyrd getImage newview-sm] \
		-helptext "Click opens new window (Ctrl-click)" -command "$kid newviewLatch" \
		-lockedbackground [Colors get newwinHi] \
		-layout "grid -padx 2 -column $col -row 0"]

	incr col
	$kid slot _home [BW_Button construct * $tb -image [Thyrd getImage home-on] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Go home" \
		-layout "grid -padx 2 -column $col -row 0" -command "$kid home"]

	$kid addHomeMenu
	# The text entry widget takes up the bulk of the width
	# DEFERRED the setting of -text here shouldn't be needed--bug in PathEntry?
	incr col
	$kid slot _entry [PathEntry construct * $tb -pathName [$kid getParam path] \
		-padx 3 -width 40 -text [$kid getParam path] \
		-notify "$kid entryChanged" -layout "grid -column $col -row 0 -sticky ew"]

	grid columnconfigure $tb $col -weight 1

	# mode selector on far right, not in use currently
	if 0 {
		incr col
		set sf [Tk_Frame construct * $tb -padx 2 -pady 2 -borderwidth 2 -relief groove -layout "grid -column $col -row 0"]

		$kid slot _editBtn [BW_Button construct * $sf -image [Thyrd getImage write-on] \
			-relief link -borderwidth 1 -padx 1 -pady 1 \
			-helptext "Edit mode" \
			-layout "grid -column 0 -row 0" -command "$kid setParam mode edit"]

		$kid slot _descendBtn [BW_Button construct * $sf -image [Thyrd getImage navdown-on] \
			-relief link -borderwidth 1 -padx 1 -pady 1 \
			-helptext "Descend mode" \
			-layout "grid -column 1 -row 0" -command "$kid setParam mode descend"]

		$kid slot _moveBtn [BW_Button construct * $sf -image [Thyrd getImage move-on] \
			-relief link -borderwidth 1 -padx 1 -pady 1 \
			-helptext "Move mode" \
			-layout "grid -column 2 -row 0" -command "$kid setParam mode move"]

		$kid slot _newviewBtn [BW_Button construct * $sf -image [Thyrd getImage newview-on] \
			-relief link -borderwidth 1 -padx 1 -pady 1 \
			-helptext "New view mode" \
			-layout "grid -column 3 -row 0" -command "$kid setParam mode newview"]
	}

	# display controls that switch between grid and atomic configurations
	incr col
	set sfg [Tk_Frame construct * $tb -borderwidth 0  -layout "grid -column $col -row 0 -sticky news"]
	set sfa [Tk_Frame construct * $tb -borderwidth 0  -layout "grid -column $col -row 0 -sticky news"]
	#set sfp [Tk_Frame construct * $tb -borderwidth 0  -layout "grid -column $col -row 0 -sticky news"]

	$sfg raise

	$kid slot gridPanel $sfg
	$kid slot atomPanel $sfa
	#$kid slot panelPanel $sfp

	## grid panel

	# depth selector even further right, with panels button underneath
	set sf [Tk_Frame construct * $sfg -borderwidth 0  -layout "grid -column 0 -row 0"]

	set dbox [$kid slot _dbox [spinbox [$sf slot _primary].depth -from 1 -to 5 -increment 1 -width 1 -validate key \
		-vcmd {string is integer %P} -command "$kid setParam depth %s"]]

	grid $dbox -padx 2 -column 0 -row 0

	$kid slot _panelsBtn [IconCycle construct * $sf \
		-values {0 1} -value 0 -notify "$kid setParam panels" \
		-images [list [Thyrd getImage paneling-off] \
			[Thyrd getImage paneling-on]] \
		-helptext "Paneling on/off" \
		-layout "grid -column 0 -row 1"]

	# display control on far right
	DisplayControls new $sfg $pl "grid -column 1 -row 0"

	## atomic panel
	set sbox [$kid slot _sbox [Tk_SpinBox construct * $sfa -increment 1 -width 2 -validate key \
		-vcmd {string is integer %P} -command "$kid setParam afontsize %s" -layout "grid -padx 2 -column 0 -row 0"]]

	$sbox slot to 45
	$sbox slot from 6

	## panel panel
	#DEFERRED  might leave it like it is

	$kid watchParams $pl

	return $kid
} 

# Add the menu to the home button, subsuming the POET menu
#
NavBar method addHomeMenu {} {
	set h [$self slot _home]

	$h method popupMenu {path x y} [format {
		if {[$self hasSlot _popupMenu]} {
			return [$self slot _popupMenu]
		} else {
			set pm [$self as [$self parent] popupMenu $path $x $y]

			$pm insert 0 command -label "Set home" -command "%s setHome"

			$self slot _popupMenu $pm
			return $pm
		}
	} $self]
}

# Called when the entry changes, either by a typed
# path or a drop.
#
NavBar method entryChanged {p} {
	$self setPath jump $p no yes
}

# Set the path, with the given direction reported
# to all the observers.  If ``forceEntry`` is set,
# force the entry widget to display the new text.
# If ``history`` is set, add to the back button
# history.
#
NavBar method setPath {dir p {forceEntry yes} {history yes}} {
	$self slot prevCell [$self viewCell]
	$self slot prevPath [$self viewPath]

	if {[$self pathDelta $p]} {
		$self _newPath $dir $p $forceEntry $history
	}
}

# Set a new path, pathDelta or cellDelta has already been
# called and returned true.  See ``setPath``
#
NavBar method _newPath {dir p {forceEntry yes} {history yes}} {
	$self slot direction $dir
	$self slot pathName $p

	if {$forceEntry} {
		Object safe [$self slot _entry] configure -text $p
	}

	$self setParam direction $dir
	$self setParam animate [expr {$dir != "jump"}]
	$self setParam path $p

	if {$history && [$self slot prevCell] ne ""} {
		Object safe [$self slot _back] pushHistory [$self slot prevPath]
	}
}

# Navigate to a previous path on the backwards stack.  Which
# will be 0 if either the button is pressed or the top item
# is selected from the values stack.
#
NavBar method navback {{which 0}} {
	set back [$self slot _back] 
	set fwd [$self slot _fwd] 

	$fwd pushHistory [$self viewPath]

	# handle every item except the one we're going to view
	for {set i 1} {$i <= $which} {incr i} {
		set p [$back popHistory]
		$fwd pushHistory $p
	}

	$self setPath back [$back popHistory] yes no
}

# Navigate to a previous path on the forwards stack
#
NavBar method navforward {{which 0}} {
	set back [$self slot _back] 
	set fwd [$self slot _fwd] 

	$back pushHistory [$self viewPath]

	# handle every item except the one we're going to view
	for {set i 1} {$i <= $which} {incr i} {
		set p [$fwd popHistory]
		$back pushHistory $p
	}
		
	$self setPath forward [$fwd popHistory] yes no
}
	
# Return the state of the navup button.
#
NavBar method canNavup {} {
	set c [$self viewCell]
	if {$c eq ""} {return disabled}

	set cc [$c slot container]
	if {![Object existsAs $cc Cell]} {return disabled}

	return normal
}

# Navigate up to our container
#
NavBar method navup {} {
	set c [$self viewCell]
	if {$c eq ""} return

	set cc [$c slot container]
	#if {![Object existsAs $cc eq "" || $cc eq "root"} return
	if {![Object existsAs $cc Cell]} return

	$self slot prevCell $c
	$self slot prevPath [$self viewPath]
	
	if {[$self cellDelta $cc]} {
		$self _newPath up [$self viewPath] 
	}
}

# Navigate down to a subcell of what's currently displayed.
# This is not initiated from the navbar, it's called by
# some other event. 
#
NavBar method navdown {sc} {
	set c [$self viewCell]

	$self slot prevCell $c
	$self slot prevPath [$self viewPath]
	
	if {[$self cellDelta $sc]} {
		$self _newPath down [$self viewPath] 
	}
}


# Navigate up to our lowest common container
# and then down to the destination cell.
# Unless it's an uncontained path, in which
# case just jump.
#
NavBar method navupdown {dc} {
	set c [$self viewCell]

	$self slot prevCell $c
	$self slot prevPath [$self viewPath]
	
	if {[$self cellDelta $dc]} {
		$self _newPath updown [$self viewPath] 
	}
}

# Set the home, either to the given string or to the
# currently set path
#
NavBar method setHome {{p ""}} {
	if {$p eq ""} {
		$self slot home [$self viewPath]
	} else {
		$self slot home $p
	}
}

# Go to our home
#
NavBar method home {} {
	$self setPath jump [$self slot home]
}

# Show the given mode
#
NavBar method showMode {m} {
	switch $m {
		edit {
			[$self slot _descendBtn] unlock
			[$self slot _newviewBtn] unlock
		}
		descendOnce {
			[$self slot _newviewBtn] unlock
		}
		descendHold {
			[$self slot _descendBtn] lock
			[$self slot _newviewBtn] unlock
		}
		newviewOnce {
			[$self slot _descendBtn] unlock
		}
		newviewHold {
			[$self slot _newviewBtn] lock
			[$self slot _descendBtn] unlock
		}
	}

	if 0 {		;# mode panel, not used now
		foreach om {edit descend move newview} {
			[$self slot _${om}Btn] slot relief link
		}

		[$self slot _${m}Btn] slot relief sunken
	}
}

# The descend latch has been changed
#
NavBar method descendLatch {state} {
	switch $state {
		up {$self setParam mode edit}
		down {$self setParam mode descendOnce}
		locked {$self setParam mode descendHold}
	}
}

# The newview latch has been changed
#
NavBar method newviewLatch {state} {
	switch $state {
		up {$self setParam mode edit}
		down {$self setParam mode newviewOnce}
		locked {$self setParam mode newviewHold}
	}
}
