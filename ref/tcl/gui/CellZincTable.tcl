# CellZincTable - a tabular view of a Cell using Zinc
#
# Note: in general, render* methods redraw the entire 
# display or are called from outside, while draw* 
# methods are private and draw/redraw a portion.
#
# A lot of layout is done by first creating empty wall
# rectangles for cells and grids, then filling the wall
# with the rendering.  This also works for redrawing
# something.
#
# To support cells that might not exist yet, a cell= tag
# on items may either be a cell name or a string containing
# the i and j coordinates.
#
# PJM 2006-05-04	Begun
# PJM 2006-07-05	OpenGl rendering causing problems (TkZinc
#					bugzilla entry #61), the ``glrender`` slot
#					now controls whether or not OpenGL is used.
#					With a lot of text, OpenGL seems a lot slower.
# PJM 2006-09-28	Now watches the paramList cells, rather than the navbar
# PJM 2007-03-13	OpenGL rendering seems to be working better
#					with 3.3.4 release of TkZinc.  
# PJM 2007-07-20	Grids with missing cells now OK
# PJM 2007-11-12	Graphics simplification begun, dummies are now empties
# PJM 2007-11-16	Lots of subgroups removed
# PJM 2008-01-25	Improvements to atomic display
# PJM 2008-01-29	Explicit mode buttons removed, now uses latch buttons
# PJM 2008-04-10	Display of X status added
# PJM 2008-10-26	Better bottom margin (triad corners) management
# PJM 2008-11-15	Added ``$self reconfigure`` in a lot of places to assure
#					full redraw (like after a drop)
#

Tk_Frame construct CellZincTable
CellZincTable mixin CellTable
CellZincTable mixin CellObserver

# Options that must be specified at creation time
CellZincTable slot extraOptions {paramList tool}

# Keeps track of scrollbars
CellZincTable slot scrollbarsOn	1
CellZincTable type scrollbarsOn	<boolean>

# Get all the params from our paramList into local slots
#
# DEFERRED get rid of this, and ask only for the params we need
#
CellZincTable method getAllParams {} {
	$self slot mode [$self getParam mode]
	$self slot depth [$self getParam depth]
	$self slot paneling [$self getParam panels]
	$self slot gridpanels [$self getParam gridpanels]
	$self slot defaultGpanel [$self getParam defaultGpanel]
	$self slot defaultCpanel [$self getParam defaultCpanel]
	$self slot iframeViz [$self getParam iframe]
	$self slot jframeViz [$self getParam jframe]
	$self slot gridLayout [$self getParam layout]
	$self slot iDir [$self getParam idirection]
	$self slot selG [$self getParam selectGrid]
	$self slot sel0 [$self getParam select0]
	$self slot sel1 [$self getParam select1]
	$self slot selMode [$self getParam selectMode]
	$self slot showTypes [$self getParam showTypes]
}

# Build the primary for a CellZincTable
#
CellZincTable method buildPrimary {} {
	$self destroyPrimary

	$self getAllParams
	$self slot safetag [$self safeName]
	$self slot glrender 1

	set prim [$self as Tk_Frame buildPrimary]

	set zf [frame ${prim}.zf]
	set wf [frame ${prim}.wf]
	$self slot widgetFrame $wf

	grid $zf -column 1 -row 1 -sticky news
	grid $wf -column 1 -row 1 -sticky news
	grid columnconfigure $prim 1 -weight 1
	grid rowconfigure $prim 1 -weight 1
	lower $wf

	::ttk::scrollbar ${zf}.sx -orient horizontal -command [list ${zf}.z xview]
	::ttk::scrollbar ${zf}.sy -orient vertical -command [list ${zf}.z yview]

	zinc ${zf}.z -render [$self slot glrender] -borderwidth 0 -highlightthickness 0 \
		-lightangle 140 -backcolor [Colors get zBG] \
		-font zfont -tile [Thyrd getImage bg-table]

	# In case GL isn't available, this will detect if we're using it
	$self slot glrender [${zf}.z cget -render]

	DragSite::register ${zf}.z -dragevent 1 -draginitcmd [list $self dragInit]
	DropSite::register ${zf}.z -dropcmd [list $self drop] -dropovercmd [list $self dropOver] \
		-droptypes  {SIGN {copy {}} TEXT {copy {}} }

	grid columnconfigure $zf 1 -weight 1
	grid    rowconfigure $zf 1 -weight 1

	grid ${zf}.z -row 1 -column 1 -sticky nsew
	grid ${zf}.sx -row 2 -column 1 -sticky nsew
	grid ${zf}.sy -row 1 -column 2 -sticky nsew

	set zinc [$self slot zinc ${zf}.z]
	$self slot scrollx ${zf}.sx
	$self slot scrolly ${zf}.sy

	::autoscroll::autoscroll ${zf}.sx
	::autoscroll::autoscroll ${zf}.sy

	# The top-level group, for viewing transformations
	set view [$self slot view [$zinc add group 1 -priority 100]]

	# 2 overlay planes, 3 planes used for zooming
	set controls [$self slot controls [$zinc add group $view -priority 600]]
	set overlay [$self slot overlay [$zinc add group $view -priority 500]]
	set super [$self slot super [$zinc add group $view -priority 150]]
	set norm [$self slot norm [$zinc add group $view -priority 100]]
	set sub [$self slot sub [$zinc add group $view -priority 50]]

	$self slot lensTexture [Thyrd getImage paper-grey]

	set pl [$self slot paramList]
	$self watchParams $pl
	$pl watchSub $self newAFontSize afontsize
	$pl watchSub $self newBottomMargin bottomMargin

	$self drawControls $zinc

	$self setBindings
	$self modeSelect [$self getParam mode]

	return $prim
}

# Change the font size of the atomic text
#
CellZincTable method newAFontSize {target event} {
	poetvar $self zinc

	$zinc itemconfigure atext -font [list [Fonts slot prop] [$target get]]
}

# Reset the view transformation
#
CellZincTable method resetView {} {
	poetvar $self zinc view super sub overlay

	Panel removePanels $zinc

	$zinc treset $view

	$zinc treset $super
	$zinc remove ${super}*

	$zinc treset $sub
	$zinc remove ${sub}*

	$zinc treset $overlay
	$zinc remove ${overlay}*
}

# Set whether the scrollbars are on or off.  If on, they might
# not actually appear because of ::autoscroll.
# 
# If ordered to turn them on, we always configure, to sync up.
# If ordered to turn them off, we don't do anything if they're
# already off.
#
# If we can't find a gridwall at depth 1, we use the size of the
# zinc window.
#
CellZincTable method scrollbars {on} {
	poetvar $self zinc scrollx scrolly

	if {$on} {
		if {[catch {$zinc coords gridwall&&depth=1} coords]} {
			set region [list 0 0 [$zinc cget -width] [$zinc cget -height]]
		} else {
			lassign $coords a b
			set region [concat $a $b]
		}

		$zinc configure -scrollregion $region \
			-xscrollcommand [list $scrollx set] -yscrollcommand [list $scrolly set]

		$self slot scrollbarsOn 1
	} else {
		if {[$self slot scrollbarsOn]} {
			$zinc configure -scrollregion "" -xscrollcommand "" -yscrollcommand ""
			$scrollx set 0 1
			$scrolly set 0 1
			$self slot scrollbarsOn 0
			update idletasks
		}
	}
}
	

# Set the bindings
#
CellZincTable method setBindings {} {
	poetvar $self zinc
	set w [$self slot _primary]

	$self bind <Configure> "$self reconfigure ; $self _updateBMHandle $zinc"
	$self bind <Expose> "$self reconfigure"

	focus [$self slot _primary]

	# Activate text input support from zincText
	zn_TextBindings $zinc

	bind $w <Return> "$self nextLine ; break"
	bind $w <KP_Enter> "$self nextLine ; break"
	bind $w <Down> "$self nextLine ; break"
	bind $w <Up> "$self nextLine -1 ; break"

	bind $w <Home> {%W icursor 0 ; break}
	bind $w <End> {%W icursor end ; break}

	# Disable Poetics menu
	bind $zinc <ButtonPress-3> break

	$self _hiHandles $zinc
	focus $zinc
}

# Set the mode.  We construct the name of the
# methods to call to leave the old mode and 
# enter the new mode
#
CellZincTable method modeSelect {m} {
	poetvar $self zinc
	if {$zinc eq ""} return {}

	poetvar $self mode
	
	$self mode'leave'$mode $zinc

	set mode $m

	$self mode'enter'$mode $zinc
}

# Set the bindings global to all modes.
#
CellZincTable method setGlobalBindings {zinc} {
	$zinc bind selectable <ButtonPress-3> [list $self _cellPopup %W %X %Y %x %y]
	$zinc bind triadList <ButtonPress-3> [list $self _tcellPopup %W %X %Y %x %y]
	$zinc bind textEpilog <KeyPress> [list $self keypress $zinc %k %K %s]

	$self bind <Control-KeyPress> [list $self mode'enter'descendOnce $zinc]
	$self bind <Control-KeyRelease> [list $self mode'leave'descendOnce $zinc]
	$self bind <Alt-KeyPress> [list $self mode'enter'newviewOnce $zinc]
	$self bind <Alt-KeyRelease> [list $self mode'leave'newviewOnce $zinc]

	$zinc bind clickable <Control-KeyPress> [list $self mode'enter'descendOnce $zinc]
	$zinc bind clickable <Control-KeyRelease> [list $self mode'leave'descendOnce $zinc]
	$zinc bind clickable <Alt-KeyPress> [list $self mode'enter'newviewOnce $zinc]
	$zinc bind clickable <Alt-KeyRelease> [list $self mode'leave'newviewOnce $zinc]

	$zinc bind subcell <Shift-Button-1> [list $self navdownEvent %W]
	$zinc bind subcell <Control-Button-1> [list $self newwinEvent %W]

	$zinc itemconfigure text -sensitive 1
}


##
## mode'<enter|leave>'<mode name>
##

# Edit mode enter
#
CellZincTable method mode'enter'edit {zinc} {
	$zinc bind subcell <Enter> [list $self _enterCell $zinc]
	$zinc bind subcell <Leave> [list $self _leaveCell $zinc]

	$zinc bind selectable <Button-1> [list $self _beginSelect $zinc %x %y]
	$zinc bind selectable <B1-Motion> [list $self _continueSelect $zinc %x %y]
	$zinc bind selectable <ButtonRelease-1> [list $self _endSelect $zinc %x %y]


	$self _showSelection $zinc
}
	
# Edit mode leave
#
CellZincTable method mode'leave'edit {zinc} {
	# DEFERRED why?
	#$zinc bind subcell <Enter> ""
	#$zinc bind subcell <Leave> ""

	$zinc bind selectable <Button-1> ""
	$zinc bind selectable <B1-Motion> ""
	$zinc bind selectable <ButtonRelease-1> ""

	$self _unshowSelection $zinc 
}


# Descend mode enter
#
CellZincTable method mode'enter'descendOnce {zinc} {
	poetvar $self glrender
	$self _hiCells $zinc [Colors get descendLo $glrender] [Colors get descendHi $glrender] navdownEvent
}

# Descend mode show leave
#
CellZincTable method mode'leave'descendOnce {zinc} {
	$self _unhiCells $zinc
}

# Descend mode enter
#
CellZincTable method mode'enter'descendHold {zinc} {
	poetvar $self glrender
	$self _hiCells $zinc [Colors get descendLo $glrender] [Colors get descendHi $glrender] navdownEvent
}

# Descend mode show leave
#
CellZincTable method mode'leave'descendHold {zinc} {
	$self _unhiCells $zinc
}

# Newview mode enter
#
CellZincTable method mode'enter'newviewOnce {zinc} {
	poetvar $self glrender
	$self _hiCells $zinc [Colors get newwinLo $glrender] [Colors get newwinHi $glrender] newwinEvent
}
	
# Newview mode leave
#
CellZincTable method mode'leave'newviewOnce {zinc} {
	$self _unhiCells $zinc
}

# Newview mode enter
#
CellZincTable method mode'enter'newviewHold {zinc} {
	poetvar $self glrender
	$self _hiCells $zinc [Colors get newwinLo $glrender] [Colors get newwinHi $glrender] newwinEvent
}
	
# Newview mode leave
#
CellZincTable method mode'leave'newviewHold {zinc} {
	$self _unhiCells $zinc
}

# Internal method shared by modes that highlight cells and
# invoke a handler when they're clicked on.
#
# When a cell is entered, we set the indicator in the window frame to 
# its path.
#
CellZincTable method _hiCells {zinc lo hi handler} {
	poetvar $self glrender

	$zinc bind subcell <Enter> [list $self _enterCell $zinc $lo $hi]
	$zinc bind subcell <Leave> [list $self _leaveCell $zinc $lo]
	$zinc bind subcell <Button-1> [list $self $handler %W]

	if {$glrender} {
		$zinc itemconfigure front -fillcolor $lo
	} else {
		$zinc itemconfigure front -linecolor $lo
	}

	$zinc itemconfigure front -visible 1 -sensitive 1
}

# A cell has been entered, set the path in
# the indicator.  We also highlight the cell if two
# colors are given.
#
# We now assume the color does not have an alpha component
# and add one in when glrender is true.
#
# ``cc`` may be a placeholder
#
CellZincTable method _enterCell {zinc {lo ""} {hi ""}} {
	poetvar $self glrender tool
	set it [$zinc find withtag current]
	set cc [Zinc itemCell $zinc $it]

	$self slot _oldStatus [$tool slot statusIndicator]
	if {[Object exists $cc]} {
		$tool slot statusIndicator "[$cc path] ($cc)"
	} else {
		$tool slot statusIndicator "missing cell at $cc"
	}

	if {$lo ne "" && $hi ne ""} {
		if {$glrender} {
			$zinc itemconfigure front -fillcolor $lo
			$zinc itemconfigure current -fillcolor $hi
		} else {
			$zinc itemconfigure front -linecolor $lo
			$zinc itemconfigure front&&cell=$cc -linecolor $hi
		}
	}
}
	
# A cell has been left, unset the path in
# the indicator.  We also unhighlight the cell if the
# lo color is given.
#
CellZincTable method _leaveCell {zinc {lo ""} } {
	poetvar $self glrender tool
	set it [$zinc find withtag current]
	set cc [Zinc itemCell $zinc $it]

	$tool slot statusIndicator [$self slot _oldStatus]

	if {$lo ne ""} {
		if {$glrender} {
			$zinc itemconfigure current -fillcolor $lo
		} else {
			$zinc itemconfigure front&&cell=$cc -linecolor $lo
		}
	}
}

# Unhighlight cells
#
CellZincTable method _unhiCells {zinc} {
	# DEFERRED why?
	#$zinc bind subcell <Enter> ""
	#$zinc bind subcell <Leave> ""
	$zinc bind subcell <1> ""

	#$zinc itemconfigure front -visible 0 -sensitive 0
	$zinc itemconfigure front -visible 0 -sensitive 1
}

# Set up to highlight and interact with handles
#
CellZincTable method _hiHandles {zinc} {
	$zinc bind whandle <Enter> [list $self _enterHandle $zinc]
	$zinc bind whandle <Leave> [list $self _leaveHandle $zinc]

	$zinc bind hhandle <Enter> [list $self _enterHandle $zinc]
	$zinc bind hhandle <Leave> [list $self _leaveHandle $zinc]

	$zinc bind whandle <ButtonPress-1> "$self dragHandle $zinc 1 %x %y"
	$zinc bind hhandle <ButtonPress-1> "$self dragHandle $zinc 0 %x %y"

	$zinc bind whandle <ButtonPress-3> "$self _handlePopup %W %X %Y 1"
	$zinc bind hhandle <ButtonPress-3> "$self _handlePopup %W %X %Y 0"
}

# Popup a menu on a w or h handle
#
CellZincTable method _handlePopup {path x y isW} {
	poetvar $self zinc
	set h [$zinc find withtag current]
	set c [Zinc itemCell $zinc $h]
	set gc [$c slot container]

	set at [? $isW width height]

	if {![theSpace hasAttr $c $at]} {
		set msg "${at}: unset"
		set needRM 0
	} else {
		set msg "${at}: [theSpace getAttr $c $at]"
		set needRM 1
	}

	set m $path.popupMenu
	catch {destroy $m}

	menu $m -tearoff 0
	$m add command -label $msg \
		-background [Colors get menuHeaderBG] -activebackground [Colors get menuHeaderBG] \
		-foreground [Colors get menuHeaderFG] -activeforeground [Colors get menuHeaderFG]
	$m add separator
	if {$needRM} {
		$m add command -label "Remove $at setting" -command "theSpace remAttr $c $at ; $self renderRoot "
	}
	#$m add command -label "Remove all width settings" -command "$self clearCellSizes $gc width"
	#$m add command -label "Remove all height settings" -command "$self clearCellSizes $gc height"
	$m add command -label "Remove all cell size settings" -command "$self clearCellSizes $gc all"

	tk_popup $m $x $y
}

# Popup a menu on a cell or vacancy.  If it's already up, drop it.
#
CellZincTable method _cellPopup {path mx my x y} {
	poetvar $self zinc
	
	set m $path.popupMenu

	if {[winfo exists $m]} {
		set isUp [winfo ismapped $m]
		catch {destroy $m}
		if {$isUp} {
			$self reconfigure
			return
		}
	}

	set bg [Colors get menuHeaderBG] 
	set fg [Colors get menuHeaderFG] 


	set v [$self getGIJUnder $zinc $x $y]
	if {$v eq ""} return

	lassign $v gc i j
	if {$gc eq ""} return

	menu $m -tearoff 0
	set c [$gc as CMGrid getCell $i $j]

	if {[Object exists $c]} {
		$m add command -label "$c at $i $j in $gc" \
			-background $bg -activebackground $bg \
			-foreground $fg -activeforeground $fg

		set m1 [menu $m.type -tearoff 0]
		set ct [$c getType]

		# Type-specific menu items, most types don't have 'em
		switch $ct {
			Path {
				$m add command -label "Reduce path vs [$c path]" -command [list $self reducePathCell $c]
				$m add command -label "Make path absolute" -command [list $self absolutePathCell $c]
				$m add separator 
			}
		}
				
		$m add cascade -label "Convert from $ct to:" -menu $m1

		foreach t [TypeSelector slot poetTypes] {
			if {$t ne $ct} {
				$m1 add command -compound left -image [Type getImage $t] -label $t -command [list $c become $t]
			}
		}

		foreach {im ty tyo} {path Path Path opcode Opcode Opcode triad Triad TriadCore} {
			if {$ty ne $ct} {
				$m1 add command -compound left -image [Thyrd getImage type-$im] \
					-label $ty -command [list $c become $tyo]
			}
		}
	} else {
		$m add command -label "vacancy at $i $j in $gc" \
			-background $bg -activebackground $bg \
			-foreground $fg -activeforeground $fg

		set m1 [menu $m.type -tearoff 0]
		$m add cascade -label "Make new cell of type:" -menu $m1
		foreach t [TypeSelector slot poetTypes] {
			$m1 add command -label $t -command [list $gc putTypeAt "" $t $i $j]
		}
		$m1 add command -label Path -command [list $gc putTypeAt "" Path $i $j]
		$m1 add command -label Opcode -command [list $gc putTypeAt "" Opcode $i $j]
		$m1 add command -label Triad -command [list $gc putTypeAt "" TriadCore $i $j]
	}

	$m add separator
	$m add command -label "Fill all vacancies" -command "$gc as CMGrid complete"

	tk_popup $m $mx $my
}

# Popup a menu on a cell in a triad list.  If it's already up, drop it.
#
CellZincTable method _tcellPopup {path mx my x y} {
	poetvar $self zinc
	
	set m $path.popupMenu

	if {[winfo exists $m]} {
		set isUp [winfo ismapped $m]
		catch {destroy $m}
		if {$isUp} {
			$self reconfigure
			return
		}
	}

	set bg [Colors get menuHeaderBG] 
	set fg [Colors get menuHeaderFG] 

	set it [$zinc find withtag current]

	# Get the triad from either the item or its container
	set t [Zinc itemParam $zinc $it triad]
	if {$t eq ""} {
		set in [Zinc itemParam $zinc $it containedIn]
		if {$in eq ""} {
			UserMsg warning "|$self _tcellPopup $path $mx $my $x $y|Item $it has no containedIn tag"
			return
		}

		set t [Zinc itemParam $zinc $in triad]
		if {$t eq ""} {
			UserMsg warning "|$self _tcellPopup $path $mx $my $x $y|Can't find triad tag for item $it"
			return
		}
	}

	menu $m -tearoff 0

	$m add command -label "Triad $t" \
		-background $bg -activebackground $bg \
		-foreground $fg -activeforeground $fg

	set m1 [menu $m.corners -tearoff 0]
	$m add cascade -label "Corners:" -menu $m1 \
		-background $bg -activebackground $bg \
		-foreground $fg -activeforeground $fg
	$m1 add command -compound left -image [Thyrd getImage op-A-gl] -label [Object safe [$t cell A] path] \
		-background $bg -activebackground $bg \
		-foreground $fg -activeforeground $fg
	$m1 add command -compound left -image [Thyrd getImage op-B-gl] -label [Object safe [$t cell B] path] \
		-background $bg -activebackground $bg \
		-foreground $fg -activeforeground $fg
	$m1 add command -compound left -image [Thyrd getImage op-Y-gl] -label [Object safe [$t cell Y] path] \
		-background $bg -activebackground $bg \
		-foreground $fg -activeforeground $fg

	$m add command -compound left -image [Thyrd getImage op-unbind-gl] -label "Unbind $t" \
		-command [list $self _unbind $t]

	tk_popup $m $mx $my
}

# Unbind a triad (from the popup menu)
# DEFERRED redrawing the entire display is a little unnecessary
#
CellZincTable method _unbind {t} {
	$t destruct
	$self renderRoot
}

# Given a path cell we're displaying, reduce the path it contains
# vs the path of the cell itself, if possible.
#
CellZincTable method reducePathCell {c} {
	set p [$c slot core]
	if {![Object existsAs $p Path]} return

	set op [Path newVolatile]
	$op fromCell $c

	$p repath
	$p reduceVs $op
	$c notifyObservers write
	$op destruct
}

# Given a path cell we're displaying, make the path it
# contains absolute.
#
CellZincTable method absolutePathCell {c} {
	set p [$c slot core]
	if {![Object existsAs $p Path]} return

	set r [$p resolve $c]
	if {$r eq ""} return

	$c set [$r path]
}

# Clear some or all of the cell sizes for the given grid cell,
# then rerender
#
# DEFERRED  only handle all currently
#
CellZincTable method clearCellSizes {gc {which all}} {
	foreach {wi wj} [$gc as CMGrid walk frame] {
		set wc [$self _getCoP $gc $wi $wj]

		if {[Object exists $wc]} {
			theSpace remAttr $wc width
			theSpace remAttr $wc height
		}
	}

	$self renderRoot
}

# Stop highlighting handles
#
CellZincTable method _unhiHandles {zinc} {
	$zinc bind whandle <Enter> ""
	$zinc bind whandle <Leave> ""

	$zinc bind hhandle <Enter> ""
	$zinc bind hhandle <Leave> ""
}

# Called when a handle is entered
#
CellZincTable method _enterHandle {zinc} {
	set h [$zinc find withtag current]

	set isW [$zinc hastag $h whandle]
	set c [Zinc itemCell $zinc $h]


	if {![Object exists $c]} {
		set color [Colors get zHandlesUnset]
	} else {
		if {$isW} {
			set at width
			set df [Spans get defaultCellW]	;# DEFERRED should we get this from thyrdspace?
		} else {
			set at height
			set df [Spans get defaultCellH]	
		} 

		set a [theSpace getAttr $c $at]
		if {$a == $df || $a == 0} {
			set color [Colors get zHandlesUnset]
		} elseif {$a < 0} {
			set color [Colors get zHandlesExpand]
		} else {
			set color [Colors get zHandlesSet]
		}
	}

	$zinc itemconfigure $h -visible 1 -linecolor $color -fillcolor $color
	$zinc configure -cursor [Cursors get [? $isW ew ns]]

	$self slot hotHandle $h
}

# Called when a handle is left
#
CellZincTable method _leaveHandle {zinc} {
	$zinc configure -cursor ""

	set h [$self slot hotHandle]
	if {$h eq ""} return

	$zinc itemconfigure $h -visible 0
	$self slot hotHandle ""
}

# Begin a drag and drop op from a handle
#
CellZincTable method dragHandle {zinc isW x y} {
	set h [$zinc find withtag current]

	bind $zinc <Motion> "$self moveHandle $zinc $h $isW %x %y $x $y"
	bind $zinc <ButtonRelease-1> "$self dropHandle $zinc $h $isW %x %y $x $y"
}

# Move a handle 
#
CellZincTable method moveHandle {zinc h isW x y xo yo} {
	$zinc treset $h

	if {$isW} {
		$zinc translate $h [- $x $xo] 0
	} else {
		$zinc translate $h 0 [- $y $yo]
	} 
}

# Called when a handle has been released
#
CellZincTable method dropHandle {zinc h isW x y xo yo} {
	if {$isW} {
		set xlate [- $x $xo]
		set at width
	} else {
		set xlate [- $y $yo]
		set at height
	} 
	
	bind $zinc <Motion> {}
	bind $zinc <ButtonRelease-1> {}

	if {$xlate == 0} {
		$zinc treset $h
	} else {
		set c [Zinc itemCell $zinc $h]
		if {![Object exists $c]} {
			set gc [Zinc itemParam $zinc $h gridcell]
			assert {[Object exists $gc]}
			set c [$gc subCell! {*}[Grid copCoords $c]]
		}

		theSpace setAttr $c $at [+ [theSpace getAttr $c $at] $xlate]
		$self renderRoot
	}
}

# Show the executed cells by drawing a box around them, or
# erase the box.
#
CellZincTable method xstatus {c onOff} {
	poetvar $self overlay zinc

	if {$onOff} {
		foreach i [$zinc find withtag cellwall&&cell=$c] {
			set bbox [$zinc bbox $i]
			$zinc add rectangle $overlay [Zinc offsetbox -2 {*}$bbox] -tags [list xframe cell=$c] \
				-priority 20 -linewidth 3 -linecolor [Colors get xFrame]
		}
	} else {
		$zinc remove xframe&&cell=$c
	}
}

# Show the paused cells by drawing a box around them, or
# erase the box.
#
CellZincTable method paused {c onOff} {
	poetvar $self overlay zinc

	if {$onOff} {
		foreach i [$zinc find withtag cellwall&&cell=$c] {
			set bbox [$zinc bbox $i]
			$zinc add rectangle $overlay [Zinc offsetbox -2 {*}$bbox] -tags [list pausedframe cell=$c] \
				-priority 20 -linewidth 3 -linecolor [Colors get pausedFrame]
		}
	} else {
		$zinc remove pausedframe&&cell=$c
	}
}

## Handle the selection
##

# Called when the selection parameters change. 
# In some modes we show the selection.
#
CellZincTable method newSelection {target event} {
	switch [$self slot mode] {
		edit -
		move {$self _showSelection [$self slot zinc]}
	}
}
	

# Show the selected cells by drawing a box around them
#
CellZincTable method _showSelection {zinc} {
	poetvar $self overlay glrender

	set vc [$self viewCell]
	if {$vc eq "" || [$vc atomic]} return

	$self _unshowSelection $zinc

	set selG [$self getParam selectGrid]
	set sel0 [$self getParam select0]
	set sel1 [$self getParam select1]

	if {$sel0 eq "" || $sel1 eq ""} return

	set bbox [$zinc bbox "cellwall && ingrid=$selG && (ij=$sel0 || ij=$sel1)"]
	if {$bbox eq ""} {
		UserMsg warning "|CellZincTable _showSelection| bbox empty ($sel0 $sel1 $selG)"
		return
	}

	lassign $bbox x0 y0 x1 y1
	set rbox [Zinc offsetbox -2 $x0 $y0 $x1 $y1]

	# Draw the frame
	$zinc add rectangle $overlay $rbox -tags [list selectionBox selectable selectionFrame] \
		-priority 10 -linewidth 3 -linecolor [Colors get selectionFrame]

	# Draw the highlighting over all the cells except the first
	# selected cell.  Don't draw it at all for only one cell or
	# if gl is disabled.
	#
	if {$glrender && $sel0 ne $sel1} {
		set ibox [$zinc bbox ij=$sel0] 
		
		$zinc add curve $overlay [Zinc notchedBox $rbox $ibox 2] -tags [list selectionBox selectable selectionBack] \
			-priority 9 -filled 1 -fillcolor [Colors get selectionBG] -linewidth 0 
	}

	# Highlight the frame cells

	lassign [Grid selRange $sel0 $sel1] i0 j0 i1 j1

	for {set i $i0} {$i <= $i1} {incr i} {
		$zinc itemconfigure cellwall&&j=0&&i=$i -fillcolor [Colors get iFrameBGHi]
	}

	for {set j $j0} {$j <= $j1} {incr j} {
		$zinc itemconfigure cellwall&&i=0&&j=$j -fillcolor [Colors get jFrameBGHi]
	}
}

# Erase the box around the selection
#
CellZincTable method _unshowSelection {zinc} {
	$zinc remove selectionBox
	$zinc itemconfigure cellwall&&iframe -fillcolor [Colors get iFrameBG]
	$zinc itemconfigure cellwall&&jframe -fillcolor [Colors get jFrameBG]
	$zinc itemconfigure cellwall&&empty -fillcolor [Colors get emptyBG]
}

# Called when a cell has been clicked on to begin the
# selection.
#
# If we click on the zero cell while there's a selection,
# we clear the selection.
#
CellZincTable method _beginSelect {zinc x y} {
	focus $zinc

	set v [$self getGIJUnder $zinc $x $y]
	if {$v eq ""} return

	lassign $v selG i j
	if {$selG eq ""} return

	lassign [$selG size] mi mj
	incr mi -1
	incr mj -1

	if {$i == 0 && $j == 0} {
		switch [$self getParam selectmode] {
			"" -
			none	{
				set selMode all

				set sel0 "i1j1"
				set sel1 "i${mi}j${mj}"
			} 
			all	-
			iselect -
			jselect -
			range {
				set selMode none

				$self clearSelection
				return
			}
		}
	} elseif {$j == 0} {
		set selMode iselect

		set sel0 "i${i}j1"
		set sel1 "i${i}j${mj}"
	} elseif {$i == 0} {
		set selMode jselect

		set sel0 "i1j${j}"
		set sel1 "i${mi}j${j}"
	} else {
		set selMode range

		set sel0 "i${i}j${j}"
		set sel1 "i${i}j${j}"
	}

	$self slot _sav_selG [$self getParam selectGrid]
	$self slot _sav_sel0 [$self getParam select0]
	$self slot _sav_sel1 [$self getParam select1]

	set c [$selG subCell $i $j]

	$zinc bind all <Escape> [list $self _cancelSelect $zinc]
	if {[$zinc find withtag textEpilog&&cell=$c] ne ""} {
		$zinc focus textEpilog&&cell=$c
		$zinc cursor textEpilog&&cell=$c end
	}

	# Since we're setting all four, ignore and
	# then manually invoke display method
	#
	$self setParamIgnore selectGrid $selG
	$self setParamIgnore select0 $sel0
	$self setParamIgnore select1 $sel1
	$self setParamIgnore selectmode $selMode

	$self _showSelection $zinc
}

# Called while the mouse is being moved after starting
# a selection.
#
CellZincTable method _continueSelect {zinc x y} {
	set m [$self getParam selectmode]
	if {$m eq "all"} return

	set sel1 [$self getParam select1] 
	
	set gij [$self getGIJUnder $zinc $x $y]
	if {$gij eq ""} return

	lassign $gij selG i j

	lassign [$selG size] mi mj
	incr mi -1
	incr mj -1

	switch $m {
		iselect {
		#	set c [$c goto "+0 +*"]
			set j $mj
		}
		jselect {
			#set c [$c goto "+* +0"]
			set i $mi
		}
	} 

	$self setParam select1 "i${i}j${j}"
}

# Called when the mouse is released after starting
# a selection
#
CellZincTable method _endSelect {zinc x y} {
	$self _continueSelect $zinc $x $y

	$zinc bind all <Escape> ""
}

# Called when the escape key is pressed while selecting,
# reverts to old selection
#
CellZincTable method _cancelSelect {zinc} {
	$self setParamIgnore selectGrid [$self slot _sav_selG]
	$self setParamIgnore select0 [$self slot _sav_sel0]
	$self setParam select1 [$self slot _sav_sel1]

	$zinc bind all <Escape> ""
}

# Clear the selection
#
CellZincTable method clearSelection {} {
	$self setParamIgnore selectGrid ""
	$self setParamIgnore select0 ""
	$self setParamIgnore select1 ""
	$self setParam selectmode none
}

##
## Text input
##

# A keypress has occured on a text field. 
#
CellZincTable method keypress {zinc key keysym state} {
	if {$keysym in {Control_L Control_R Alt_L Alt_R Shift_L Shift_R}} return

	set ti [lindex [$zinc focus] 0]

	set c  [Zinc itemCell $zinc $ti]
		
	set halo [$zinc find withtag halo=$c]
	if {$halo eq ""} {
		set halo [$self drawTextHalo $zinc $ti $c]
	}
}

# Draw the text halo
#
CellZincTable method drawTextHalo {zinc ti c} {
	poetvar $self overlay

	set tags halo=$c

	$zinc remove $tags

	set halo [$zinc add group $overlay -tags $tags -priority 500]

	lassign [Zinc smallIconButtons $zinc $halo [concat $tags haloButtons] \
		 "ok" "cancel"] bo bc
	
	$zinc bind $bo <1> [list $self textHalo OK $zinc $ti $halo]
	$zinc bind $ti <KeyPress-F1> [list $self textHalo OK $zinc $ti $halo]
	$zinc bind $bo <3> [list $self allTextHalo ok $zinc]
	$zinc bind $ti <Shift-F1> [list $self allTextHalo ok $zinc]

	$zinc bind $bc <1> [list $self textHalo Cancel $zinc $ti $halo]
	$zinc bind $ti <Escape> [list $self textHalo Cancel $zinc $ti $halo]
	$zinc bind $bc <3> [list $self allTextHalo cancel $zinc]
	$zinc bind $ti <Shift-Escape> [list $self allTextHalo cancel $zinc]

	set bbid [$zinc find withtag cellwall&&cell=$c]
	if {$bbid eq ""} {set bbid $ti}

	Zinc lowerRightCorner $zinc $bbid $halo

	return $halo
}

# A button on the halo around a text cell has been hit
#
CellZincTable method textHalo {what zinc ti halo} {
	set c [string range [lsearch -inline [$zinc gettags $ti] cell=*] 5 end]
	if {$c eq ""} {
		UserMsg error "|$self textHalo $what $zinc $ti $halo| Cell tag not present"
		return
	}

	switch $what {
		OK {
			set v [$zinc itemcget $ti -text]
			if {![$self validateCell $c $v]} {
				UserMsg warning "This cell will not accept a value of $v"
				return
			}
		}
		Cancel {
			$zinc itemconfigure $ti -text [$c get]
		}
	}

	$zinc remove $halo
}

# A button on a halo has been right-clicked, ok or cancel all
# halos
#
CellZincTable method allTextHalo {what zinc} {
	foreach i [$zinc find withtag haloButtons&&$what] {
		eval [$zinc bind $i <1>]
	}
}

# Draw a path info halo
#
CellZincTable method drawPathInfoHalo {zinc ti c} {
	poetvar $self overlay

	set tags info=$c

	$zinc remove $tags

	set halo [$zinc add group $overlay -tags $tags -priority 500]

	set w [$zinc cget -width]
	set h [$zinc cget -height]

	#DEFERRED problem if a cell is displayed more than once on a canvas
	#lassign [$zinc bbox cell=$c] x0 y0 x1 y1
	set bbid [Zinc findTagUpGroup $zinc bbox $ti]
	if {$bbid eq ""} {set bbid $ti}

	set info [Zinc infoBox $zinc $halo [$c path] [Colors get zInfoBG]]
	Zinc nextTo $zinc $bbid $halo

	return $halo
}


# Validate a cell value, setting the new value if it's OK.
#
CellZincTable method validateCell {c new} {
	if {[$c validate $new]} {
		Observer ignore $self $c {theSpace editSet $c $new}
		#Observer ignore $self $c {$c set $new}
		return true
	} else {
		return false
	}
}

# Compute the list of cells to navigate up from ``ac`` to its 
# lowest common container with ``bc``, and then down to ``bc``.
#
# If the two paths hace nothing in common, they don't have
# the same root.
#
CellZincTable method _computeUpDown {ac bc} {
	set ap [Path newVolatile [$ac path]]
	set nap [$ap nSteps]

	set bps [$bc path]
	set bp [Path newVolatile $bps]
	set nbp [$bp nSteps]

	set lcc [Path newVolatile $bps]
	$lcc commonWith $ap
	set nlcc [$lcc nSteps]

	if {$nlcc == 0} {return ""}

	# go up
	set c $ac
	while {$nap > $nlcc} {
		set cc [$c slot container]
		lappend result up $cc
		set c $cc

		incr nap -1
	}

	# go down
	foreach x [$bp slotRange steps $nlcc end] {
		set cc [eval $c subCell $x]
		lappend result down $cc
		set c $cc
	}

	$ap destruct
	$bp destruct
	$lcc destruct

	return $result
}

# Animate navigating to a new path in the given direction of
# motion. 
#
# If ``andThen`` is provided, it is invoked after the
# zoom.  Otherwise, we just trigger a cell write event.
# 
CellZincTable method navTo {nc dir {andThen ""}} {
	$self setParam animate 0
	$self slot simplify 1

	if {$andThen eq ""} {
		set andThen [list $self newCell $nc]
	}

	switch $dir {
		updown {
			set bm [$self getParam bottomMargin]
			$self setParam bottomMargin 0

			set x [$self _computeUpDown [$self oldCell] $nc]
			if {[llength $x] == 0} {
				eval $andThen
			} else {
				set nav [list after 300 $self setParam bottomMargin $bm]
				foreach {c dir} [lreverse $x] {
					set nav [list $self navTo $c $dir [join [list [list $self setParam path [$c path]] $nav] "\n"]]
				}
				
				eval $nav
		 	}
		}
		down {
			poetvar $self zinc view sub tool 

			set oc [$self oldCell]

			$zinc itemconfigure cell=$nc -visible 0

			if {[$nc atomic]} {
				$self renderAtomic $nc $sub
			} else {
				$self renderGrid $nc $sub
			}

			set wz [$zinc cget -width]
			set hz [$zinc cget -height]

			set bbox [$zinc bbox subcell&&cell=$nc]
			if {$bbox eq ""} {
				UserMsg error "|$self navTo $nc $dir $andThen|No subcell for $nc ([Object safe $nc path])"
				return
			}

			lassign $bbox x0 y0 x1 y1

			set sx [expr {($x1 - $x0)/$wz}]
			set sy [expr {($y1 - $y0)/$hz}]

			$zinc scale $sub $sx $sy
			$zinc translate $sub $x0 $y0

			Zinc zoomView $zinc $bbox $view [Spans get downFPS] $andThen
		}
		up {
			# If we're about to panel, just jump
			if {[lindex [$self getGPanel $nc] 0] ne ""} {
				$self slot simplify 0
				#[$self slot tool] jump $nc
				eval $andThen
				return
			}

			poetvar $self zinc view super

			set oc [$self oldCell]
			set uc [$oc slot container]

			$self renderGrid $uc $super

			# the hole in the super plane
			set what "${super}*cellwall&&cell=$oc"

			# if the hole's not there, it's some other rendering
			# (like a grid panel), so we just jump (this is handled
			# above, this code is redundant).
			#
			set bbox [$zinc bbox $what]
			if {$bbox eq ""} {
				$self slot simplify 0
				[$self slot tool] jump $nc
				return
			}

			lassign $bbox x0 y0 x1 y1

			$zinc itemconfigure $what -visible 0

			set wz [$zinc cget -width]
			set hz [$zinc cget -height]


			set sx [expr {$wz/($x1 - $x0)}]
			set sy [expr {$hz/($y1 - $y0)}]

			set tx [expr {0 - $x0}]
			set ty [expr {0 - $y0}]

			$zinc translate $super $tx $ty
			$zinc scale $super $sx $sy

			set bbox [$zinc bbox $super]
			Zinc zoomView $zinc $bbox $view [Spans get upFPS] $andThen
		}
		default {
			eval $andThen
		}
	}
}

# Get the cell under the given x,y coordinates. It's possible
# that no cell will be found.
#
CellZincTable method getCellUnder {zinc x y} {
	lassign [$self getGIJUnder $zinc $x $y] g i j
	if {$g eq ""} {return ""}

	return [$g subCell $i $j]
}

# Get the grid and coords under the given x,y coordinates.  It's
# possible that no cell will be found.
#
# For some reason, calling hastag on $zinc sometimes errors, so
# we catch it.
#
CellZincTable method getGIJUnder {zinc x y} {
	set items [$zinc find overlapping $x $y $x $y]

	foreach item $items {
		if {![catch {$zinc hastag $item "cellwall"} res] && $res} {
			return [list [Zinc itemParam $zinc $item ingrid] \
				[Zinc itemParam $zinc $item i] \
				[Zinc itemParam $zinc $item j]]
		}
	}

	return ""
}

# A cell has been clicked on, navigate down. If 
# its container is not the cell currently being
# viewed, only zoom down to its container.
#
CellZincTable method navdownEvent {zinc} {
	set vc [$self viewCell]
	set tool [$self slot tool] 
	set cc [Zinc itemCell $zinc current]

	if {$vc eq ""} {
		$tool jump $cc
	} elseif {[$vc atomic]} {
		$tool navupdown $cc
	} else {
		set ccc [$cc slot container]
		if {$ccc eq $vc} {
			$tool navdown $cc
		} else {
			$tool navdown $ccc
		}
	}

	set m [$self getParam mode]
	if {$m in {descendOnce newviewOnce}} {
		$self setParam mode edit
	}
}

# A cell has been clicked on, open a new window
#
CellZincTable method newwinEvent {zinc} {
	Window newWindow CellEditor -path [[Zinc itemCell $zinc current] path]

	set m [$self getParam mode]
	if {$m in {descendOnce newviewOnce}} {
		$self setParam mode edit
	}
}

## CellTable API
##

# Unrender 
#
# We delete everything tagged with our safetag
#
CellZincTable method unrender {} {
	poetvar $self zinc overlay

	$zinc remove [$self safetag]
	$zinc remove $overlay*
	$self scrollbars false
}


# Render no cell (viewCell is "")
#
#
CellZincTable method renderNoCell {} {
	poetvar $self zinc norm overlay

	#$self getAllParams
	$zinc remove $norm*
	$zinc remove $overlay*
	$self scrollbars false

	# DEFERRED  maybe we don't want this
	#$self drawNoCell $zinc $norm
}

# Render an atomic cell.  If a view plane is provided,
# render it there, else use the default view plane and
# reset the view.
#
CellZincTable method renderAtomic {c {vp ""}} {
	poetvar $self zinc
	Object safe $c addObserver * $self cellEvent

	$self getAllParams
	$self scrollbars false

	if {$vp eq ""} {
		$self resetView
		set vp [$self slot norm]
	}

	$zinc remove $vp*

	set bm [$self getParam bottomMargin]
	if {$bm == 0} {
		set w [$zinc cget -width]
		set h [$zinc cget -height]
		set cbox [list 0 0 $w $h]
	} else {
		$self drawOuterMembrane $zinc $vp
		set cbox [$self drawBottomMargin $zinc $vp]
	}

	$self drawCore $zinc $vp $c $cbox
	$self modeSelect [$self getParam mode]
}
		

# Prepare for drawing a new grid (different from the
# currently displayed grid).
#
# If this is the very first time this is invoked,
# don't clear the selection.  Otherwise, we're moving
# to a different cell, the selection might not make
# sense.
#
CellZincTable method newGridPrep {} {
	$self slot simplify 0

	if {[$self slot _notFirstRender] eq ""} {
		$self slot _notFirstRender 1
	} else {
		$self clearSelection
	}
}


# Render a grid full of cells.  A view plane may be 
# provided (see ``renderAtomic``).  
#
# We might be rendering a full-grid panel, if paneling
# is on and we're not drawing in a subplane (and there's
# a panel to draw).
#
# We now handle gridpanels and default?panel too.
# If gridpanels is on, the priority is:
#
# ``
#		custom grid panel
# 		default grid panel (as selected)
#		custom cell panels
# 		default cell panel (as selected)
# ``
#
# If gridpanels is off, the priority is:
#
# ``
#		custom cell panels
# 		default cell panel (as selected)
# ``
#
CellZincTable method renderGrid {c {vp ""}} {
	poetvar $self zinc overlay
	Object safe $c addObserver * $self cellEvent

	$self getAllParams

	set norm [$self slot norm]

	if {$vp eq ""} {
		$self resetView
		set vp $norm
	}

	# If we're paneling and it's a grid panel and (vp == norm), 
	# just render the panel and return
	#
	set panel ""
	set wf [$self slot widgetFrame]

	lassign [$self getGPanel $c] panel opts
	if {$panel ne "" && $vp == $norm} {
		catch {destroy {*}[winfo children $wf]}
		$panel buildInFrame $wf [$self slot tool] $c $opts
		raise $wf
		return
	}

	set mode [$self slot mode]
	set depth [$self slot depth]
	set gridLayout [$self getParam layout]

	lower $wf

	switch $gridLayout {
		fixed {$self scrollbars true}
		expand {$self scrollbars false}
	}

	set wz [$zinc cget -width]
	set hz [$zinc cget -height]

	$zinc remove $vp*
	$zinc remove $overlay*

	# If we have a grid panel, we only get here if we're not drawing on norm,
	# in which case we draw a placeholder
	#
	if {$panel ne ""} {
		$zinc add rectangle $vp [list 0 0 $wz $hz] -visible 1 -priority 1000 \
			-filled 1 -fillcolor [Colors get panelBG] \
			-linecolor [Colors get panelBG] -linewidth [Spans get gridWallWidth]
		return
	}

	# Proceed with normal grid rendering
	set bm [$self getParam bottomMargin]
	if {$bm == 0} {
		set gbox [list 0 0 $wz $hz]
	} else {
		$self drawOuterMembrane $zinc $vp
		set gbox [$self drawBottomMargin $zinc $vp]
	}

	# Add rectangle for topmost level and draw it
	$zinc add rectangle $vp $gbox -visible 1 -priority 1000 \
		-filled 0 -linecolor [Colors get zGridWall] -linewidth [Spans get gridWallWidth] \
		-tags [list cell=$c depth=1 gridwall empty]
	$self drawGrid $zinc $vp $c 1

	# Draw remaining levels
	for {set d 2} {$d <= $depth} {incr d} {
		$self drawDeepGrids $zinc $vp $d
	}

	$self setGlobalBindings $zinc
	$self mode'enter'$mode $zinc

	if {$bm == 0 && $gridLayout eq "fixed"} {
		$self scrollbars true
	}
}

# Unrender the given cell, in all views
#
CellZincTable method unrenderSub {c} {
	poetvar $self zinc

	$c deleteObserver * $self

	foreach id [$zinc find withtag cell=$c] {
		if {![catch {$zinc hastag $id "cellwall"} res] && $res} {
			lassign [Grid copCoords $c] i j

			$zinc addtag empty withtag $id 
			$self _updateSubCell $zinc $id "" $i $j
		} else {
			$zinc remove $id
		}
	}
}

# Render or rerender a cell.  There should already
# be at least one thing on the canvas with the cell=$c 
# and cellwall tag, for each we replace everything in its 
# contents with this cell's display.
# If there's no pre-existing cellwall item, do nothing.
#
# If a view plane is provided, we use it, otherwise
# we use the normal plane.
#
# ``c`` may be a cell name or a placeholder.
#
CellZincTable method renderSub {c {vp ""}} {
	if {$c eq ""} return

	poetvar $self zinc 

	lassign [Grid copCoords $c] i j
	if {[Object exists $c]} {
		$c addObserver * $self cellEvent
	}

	if {$vp eq ""} {set vp [$self slot norm]}

	foreach cw [$zinc find withtag $vp*cellwall&&cell=$c] {
		if {[$zinc hastag $cw empty]} {
			$self _drawSubCell $zinc $cw $c $i $j
		} else {
			$self _updateSubCell $zinc $cw $c $i $j
		}
	}
}

# Set the depth 
#
CellZincTable method setDepth {d} {
	poetvar $self zinc depth
	if {$d == $depth} return

	if {$d > $depth} {
		for {incr depth} {$depth <= $d} {incr depth} {
			$self drawDeepGrids $zinc [$self slot norm] $depth
		}
	} else {
		for {} {$depth > $d} {incr depth -1} {
			$self undrawDeepGrids $zinc [$self slot norm] $depth
		}
	}

	set depth $d
}

## 
## Drawing
##

# Given a reference cell, return the adjacent box, with the 
# given width and height, either below or right of the reference.
# Note that we add the grid line width here.
#
CellZincTable method mkAdjBox {zinc rc where w h} {
	lassign [$zinc coords cellwall&&cell=$rc] a b
	lassign $a rx0 ry0
	lassign $b rx1 ry1
	
	if {$where eq "below"} {
		return [list $rx0 [+ $ry1 1] [+ $rx0 $w] [+ $ry1 1 $h] ]
	} else {
		return [list [+ $rx1 1] $ry0 [+ $rx1 1 $w] [+ $ry0 $h] ]
	}
}

# Draw the grids at the given ``depth``, where ``$depth > 1``
# (the topmost grid is drawn in ``renderGrid``). i
# Then go back up in depth and resize everything, if we're in
# a layout mode that needs it (currently only "fixed" mode).
#
CellZincTable method drawDeepGrids {zinc vp d} {
	foreach sg [$zinc find withtag $vp*gridwall&&depth=$d] {
		set c [string range [lsearch -inline [$zinc gettags $sg] cell=*] 5 end]

		$self drawGrid $zinc $vp $c $d
	}

return
	set gl [$self slot gridLayout]
	if {$gl in {fixed}} {
		for {set x [- $d 1]} {$x >= 1} {incr x -1} {
			$self _relayout'$gl $zinc $vp $x
		}
	}
}

# Undraw the grids at the given ``depth``, where ``$depth > 1``
# (the topmost grid is drawn in ``renderGrid``)
#
CellZincTable method undrawDeepGrids {zinc vp d} {
	foreach gw [$zinc find withtag $vp*gridwall&&depth=$d] {
		foreach cw [$zinc find withtag containedIn=$gw] {
			$zinc remove containedIn=$cw
		}

		$zinc remove containedIn=$gw
	}
}

# Draw a grid cell at the given level.  There should already
# be something on the canvas with the cell=$c and gridwall tags, we fill
# it with a grid.  All the contents of the grid are tagged with
# containedIn=<gridwall id> for easy removal.
#
CellZincTable method drawGrid {zinc vp c d} {
	set gw [$zinc find withtag $vp*gridwall&&cell=$c]
	if {$gw eq "" || [llength $gw] > 1} {
		UserMsg error "|$self drawGrid $zinc $c $d| Tag error, found: $gw"
		return
	}

	# Get box from gw and remove contents
	set gbox [Zinc inside $zinc $gw]

	$zinc remove containedIn=$gw

	lassign [$c size] iSize jSize
	if {$iSize == 0 || $jSize == 0} return

	set iDown [$self _computeIDown $jSize]

	set tags [list [$self safetag] containedIn=$gw]

	# Handle the frames and compute the expression
	# that defines left-edge cells
	#
	set drawIFrame [$self shouldDrawFrame i $c $d]
	set drawJFrame [$self shouldDrawFrame j $c $d]

	if {$drawIFrame && $drawJFrame} {
		set subset "full"
		set leftEdgeExp [? $iDown {$wj == 0} {$wi == 0}]
	} elseif {!$drawIFrame && !$drawJFrame} {
		set subset "contents"
		set leftEdgeExp [? $iDown {$wj == 1} {$wi == 1}]
	} elseif {$drawIFrame} {
		set subset [list 1 0 endi endj]
		set leftEdgeExp [? $iDown {$wj == 0} {$wi == 1}]
	} else {
		set subset [list 0 1 endi endj]
		set leftEdgeExp [? $iDown {$wj == 1} {$wi == 0}]
	}

	set iFrameDir [? $iDown "yframe" "xframe"]
	set jFrameDir [? $iDown "xframe" "yframe"]

	# Create the subcell rectangles
	#
	foreach {wi wj} [$c as CMGrid walk $subset] {
		set wc [$self _getCoP $c $wi $wj]

		set ctags "ingrid=$c ij=i${wi}j${wj} i=$wi j=$wj"
		if {$wi == 0} {lappend ctags "jframe"}
		if {$wj == 0} {lappend ctags "iframe"}

				# Note that we only add iFrameDir or jFrameDir for 
				# the 0 0 cell, since that's the only one we want to
				# resize here (to change the size of the frame cells).
				#DEFERRED this line was only in expand code
		if {$wi == 0 && $wj == 0} {lappend ctags $iFrameDir $jFrameDir}

		$zinc add rectangle $vp [list 0 0 10 10] -visible 1 -linewidth [Spans get cellWallWidth] \
			-linecolor [Colors get zCellWall] -filled 1 -fillcolor [Colors get zCellBG] \
			-tags [concat $tags $ctags cell=$wc depth=$d selectable clickable cellwall empty]
	}

	# Invoke the correct layout method
	$self _layout'[$self slot gridLayout] $zinc $gbox $c $subset $leftEdgeExp $iDown $iSize $jSize $drawIFrame $drawJFrame

	# Render the sub cells
	#
	foreach {wi wj} [$c as CMGrid walk $subset] {
		set wc [$self _getCoP $c $wi $wj]
		
		$self renderSub $wc $vp
	}

	# No longer empty
	$zinc dtag $gw empty

	# Draw handles
	$self _drawResizeHandles $zinc $c $gw 1
}

# Layout a grid, fixed mode
#
# Each cell is a fixed width/height, as obtained from the frame cells attributes
#
CellZincTable method _layout'fixed {zinc gbox c subset leftEdgeExp iDown iSize jSize drawIFrame drawJFrame} {
	lassign $gbox gx0 gy0 gx1 gy1
	set cb [Spans get cellWallWidth]

	set wdef [+ [Spans get defaultCellW] $cb $cb]
	set hdef [+ [Spans get defaultCellH] $cb $cb]

	set fastAxis [? $iDown "j" "i"]

	set first 1

	# the walking width and height
	set wwc [+ [Spans get defaultCellW] $cb $cb]
	set hwc [+ [Spans get defaultCellH] $cb $cb]

	foreach {wi wj} [$c as CMGrid walk $subset $fastAxis] {
		set wc [$self _getCoP $c $wi $wj]

		if {[Object exists $wc]} {
			set wwc [+ [theSpace getAttr $wc width] $cb $cb]
			set hwc [+ [theSpace getAttr $wc height] $cb $cb]
		}
			
		if {$first} {
			set first 0
			set cbox [list $gx0 $gy0 [+ $gx0 $wwc] [+ $gy0 $hwc]]
		} else {
			# reference is previous i if leftEdge & iDown or !leftEdge & !iDown
			if {[expr $leftEdgeExp] == $iDown} {
				set rc [$self _getCoP $c [- $wi 1] $wj]
			} else {
				set rc [$self _getCoP $c $wi [- $wj 1]]
			}
			
			# place new cell below if leftEdge, else to the right
			if $leftEdgeExp {
				set cbox [$self mkAdjBox $zinc $rc below $wwc $hwc]
			} else {
				set cbox [$self mkAdjBox $zinc $rc right $wwc $hwc]
			}
		}

		$zinc coords cellwall&&cell=$wc $cbox
	}

	set gwx [+ 1 [lindex $cbox 2]]
	set gwy [+ 1 [lindex $cbox 3]]
	$zinc coords gridwall&&cell=$c [list 0 0 $gwx $gwy]
}

# Layout a grid, expand mode
# Available space evenly distributed, except for frame
#
CellZincTable method _layout'expand {zinc gbox c subset leftEdgeExp iDown iSize jSize drawIFrame drawJFrame} {
	lassign $gbox gx0 gy0 gx1 gy1
	set cb [Spans get cellWallWidth]
	set wdef [+ [Spans get defaultCellW] $cb $cb]
	set hdef [+ [Spans get defaultCellH] $cb $cb]

	set fastAxis [? $iDown "j" "i"]

	set wz [expr {$gx1 - $gx0}]
	set hz [expr {$gy1 - $gy0}]

	if {$iDown} {
		set cw [- $jSize 1]
		set ch [- $iSize 1]

		set drawHFrame $drawJFrame
		set drawWFrame $drawIFrame

		set topFrameExp {$wi == 0}
		set leftFrameExp {$wj == 0}
	} else {
		set cw [- $iSize 1]
		set ch [- $jSize 1]

		set drawHFrame $drawIFrame
		set drawWFrame $drawJFrame

		set topFrameExp {$wj == 0}
		set leftFrameExp {$wi == 0}
	}

	set zc [$c as CMGrid getCell 0 0]
	if {[Object exists $zc]} {
		set wdef [+ [theSpace getAttr $zc width] $cb $cb]
		set hdef [+ [theSpace getAttr $zc height] $cb $cb]
	}

	if {$ch <= 0} {
		set hn $hdef
	} else {
		if {$drawHFrame} {
			set hn [expr {($hz - $hdef - $ch)/$ch}]
		} else {
			set hn [expr {($hz - $ch)/$ch}]
		}
	}

	if {$cw <= 0} {
		set wn $wdef
	} else {
		if {$drawWFrame} {
			set wn [expr {($wz - $wdef - $cw)/$cw}]
		} else {
			set wn [expr {($wz - $cw)/$cw}]
		}
	}

	set first 1

	foreach {wi wj} [$c as CMGrid walk $subset $fastAxis] {
		set wc [$self _getCoP $c $wi $wj]

		if {$wi == 0 && $wj == 0} {
			set bw $wdef
			set bh $hdef
		} elseif $topFrameExp {
			set bw $wn
			set bh $hdef
		} elseif $leftFrameExp {
			set bw $wdef
			set bh $hn
		} else {
			set bw $wn
			set bh $hn
		}

		if {$first} {
			set first 0
			set cbox [list $gx0 $gy0 [expr {$gx0 + $bw}] [expr {$gy0 + $bh}]]
		} else {
			# reference is previous i if leftEdge & iDown or !leftEdge & !iDown
			if {[expr $leftEdgeExp] == $iDown} {
				set rc [$self _getCoP $c [expr $wi - 1] $wj]
			} else {
				set rc [$self _getCoP $c $wi [expr $wj - 1]]
			}
			
			# place new cell below if leftEdge, else to the right
			if $leftEdgeExp {
				set cbox [$self mkAdjBox $zinc $rc below $bw $bh]
			} else {
				set cbox [$self mkAdjBox $zinc $rc right $bw $bh]
			}
		}

		$zinc coords cellwall&&cell=$wc $cbox
	}
}

# Relayout for expanded contents when using the "fixed" layout.
# We're given the depth that needs adjusting, the contained cell
# and its size.
#
CellZincTable method _relayout {zinc vp d c w h} {
	set g [$c slot container]
	set i [$c slot i]
	set j [$c slot j]

	#
}

# Determine if i goes to the right or down.  If the
# option is set to auto, chose down if it would make
# a nice two column or single column display (j is 0 or 1
# for all cells).
#
CellZincTable method _computeIDown {jSize} {
	switch [$self slot iDir] {
		right {return 0}
		down {return 1}
		auto {
			if {$jSize > 2} {
				return 0
			} else {
				return 1
			}
		}
	}
}

# Draw the controls overlay, currently just the bottom margin
# control
#
CellZincTable method drawControls {zinc} {
	set controls [$self slot controls]
	set r [Spans get bmHandleR]
	set wz [$zinc cget -width]
	set lc [Colors get bmHandleLine]

	set g [$zinc add group $controls -tags [list bmHandle bmgroup]]

	$zinc add arc $g [list -$r -$r $r $r] -extent 180 -filled 1 -fillcolor [Colors get bmHandleFill] \
		-linecolor $lc -priority 200 -startangle 270 \
		-tags [list bmHandle bmknob]

	set hw [Spans get bmHandleW]
	$zinc add rectangle $g [list 0 -$hw 10000 $hw] -linewidth 2 \
		-priority 100 -visible 0 \
		-relief roundraised -linecolor $lc -filled 1 -fillcolor $lc \
		-tags [list bmHandle bmbar]

	$zinc itemconfigure bmgroup -alpha 30

	$zinc bind bmknob <Enter> [list $self _enterBMHandle $zinc]
	$zinc bind bmknob <Leave> [list $self _leaveBMHandle $zinc]

	$zinc bind bmknob <ButtonPress-1> "$self dragBMHandle $zinc %x %y"
	#$zinc bind bmknob <ButtonPress-3> "$self _handleBMPopup %W %X %Y 0"

	# Compute the point at which we present the count-only bottom margin
	#
	set mbm [Spans get bmMin]
	set pad [Spans get bmPad]
	$self slot minBottomMargin [expr {$mbm + $pad + $pad + [Spans get omOffset]}]

	$self _updateBMHandle $zinc
}

# A new value for the bottom margin
#
CellZincTable method newBottomMargin {target event} {
	$self _updateBMHandle [$self slot zinc]
	$self renderRoot
}

# Update the bottom margin indicator
#
CellZincTable method _updateBMHandle {zinc} {
	set bm [$self getParam bottomMargin] 
	set hz [$zinc cget -height]

	$zinc treset bmgroup
	$zinc translate bmgroup 0 [- $hz $bm]

	$zinc tsave bmgroup bmxform
}

# Called when the bottom margin handle is entered
#
CellZincTable method _enterBMHandle {zinc} {
	$zinc itemconfigure bmgroup -alpha 80
	$zinc itemconfigure bmbar -visible 1

	$zinc configure -cursor [Cursors get ns]
}

# Called when the bottom margin handle is left
#
CellZincTable method _leaveBMHandle {zinc} {
	$zinc configure -cursor ""

	$zinc itemconfigure bmbar -visible 0
	$zinc itemconfigure bmgroup -alpha 30
}

# Begin a drag and drop op from the bm handle
#
CellZincTable method dragBMHandle {zinc x y} {
	bind $zinc <Motion> "$self moveBMHandle $zinc %x %y $x $y"
	bind $zinc <ButtonRelease-1> "$self dropBMHandle $zinc %x %y $x $y"
	$zinc bind bmknob <Leave> {}
}

# Move the bottomMargin handle 
#
CellZincTable method moveBMHandle {zinc x y xo yo} {
	$zinc trestore bmgroup bmxform

	$zinc translate bmgroup 0 [- $y $yo]
}

# Called when the bm handle has been released
#
CellZincTable method dropBMHandle {zinc x y xo yo} {
	set xlate [- $y $yo]
	
	bind $zinc <Motion> {}
	bind $zinc <ButtonRelease-1> {}
	$zinc bind bmknob <Leave> [list $self _leaveBMHandle $zinc]

	set bm [$self getParam bottomMargin]
	set bm [min [$zinc cget -height] [max [- $bm $xlate] 0]]

	set mbm [$self slot minBottomMargin]
	if {abs($bm - $mbm) <= [Spans get bmTolerance]} {
		set bm $mbm
	} elseif {$bm < $mbm} {
		set bm 0
	}

	$self setParam bottomMargin $bm
}

# Draw the resize handles for rows and columns at the
# given depth.  The cell and gridwall containing the grid 
# that's being resized are provided.
# 
CellZincTable method _drawResizeHandles {zinc gc gw d} {
#DEFERRED only depth 1 for now, maybe permanently?
	if {$d > 1} return

	poetvar $self overlay

	set color [Colors get zHandlesUnset]

	lassign [lindex [$zinc coords $gw] 1] xmax ymax

	foreach cw [$zinc find withtag xframe&&depth=$d] {
		lassign [$zinc coords $cw] a b
		lassign $a x0 y0
		lassign $b x1 y1

		set c [Zinc itemCell $zinc $cw]

		$zinc add rectangle $overlay [Zinc assymoffsetbox 2 0 $x1 $y0 [+ $x1 1] $ymax] -linewidth 2 \
			-priority 1000 -visible 0 \
			-relief roundraised -linecolor $color -filled 1 -fillcolor $color \
			-tags [list cell=$c gridcell=$gc whandle]
	}

	foreach cw [$zinc find withtag yframe&&depth=$d] {
		lassign [$zinc coords $cw] a b
		lassign $a x0 y0
		lassign $b x1 y1

		set c [Zinc itemCell $zinc $cw]

		$zinc add rectangle $overlay [Zinc assymoffsetbox 0 2 $x0 $y1 $xmax [+ $y1 1]] -linewidth 2 \
			-priority 1000 -visible 0 \
			-relief roundraised -linecolor $color -filled 1 -fillcolor $color \
			-tags [list cell=$c gridcell=$gc hhandle]
	}

}

# Return either a subcell, or, if it doesn't exist,
# a placeholder consisting of the coords preceeded by
# ``i`` and ``j``.
#
# ``CoP`` refers to Cell or Placeholder.
#
CellZincTable method _getCoP {c i j} {
	set x [$c slot core]
	return [$x getCoP $i $j]
}

# Undraw a cell as viewed in a grid or other places.
#
CellZincTable method _undrawSubCell {zinc cw} {
	set g [$zinc group $cw]
	$zinc remove containedIn=$cw
}


# Draw a cell as viewed in a grid or other places.
# The zinc id of the cellwall is given, we create the
# front cover, clip group, and core display.
#
# ``c`` may be a cell name or a placeholder.
#
# If we're here, then we're not drawing a grid panel.
# If paneling is on, draw either a specified or default
# cell panel.
#
CellZincTable method _drawSubCell {zinc cw c i j} {
	poetvar $self glrender 

	# Get coords from cw and empty it
	set box [Zinc inside $zinc $cw]
	lassign $box x0 y0 x1 y1

	set g [$zinc group $cw]

	set tooSmall [Spans tooSmall [- $x1 $x0] [- $y1 $y0]]

	$zinc remove containedIn=$cw

	# If empty, nothing else to draw
	if {![Object exists $c]} {
		$self _updateSubCell $zinc $cw $c $i $j
		return
	}

	# No longer empty
	$zinc dtag $cw empty

	set inTriad [$zinc hastag $cw triadList]

	# Get depth and increment
	set d [+ 1 [string range [lsearch -inline [$zinc gettags $cw] depth=*] 6 end]]

	# All our items are tagged with the type of cell
	# (frame vs. content).  We also add "subcell", to indicate we're not
	# part of a single cell display but part of a grid.  We also attach
	# the cell as "cell=<cell Poet object>" so we can easily get back to
	# the model.
	#
	set tags [list [$self safetag] subcell clickable containedIn=$cw cell=$c depth=$d i=$i j=$j]

	if {$inTriad} {
		lappend tags triadList
	} else {
		lappend tags selectable
	}

	if {$i == 0 && $j == 0} {
		lappend tags zero
	} elseif {$j == 0} {
		lappend tags iframe
	} elseif {$i == 0} {
		lappend tags jframe
	} else {
		lappend tags contents
	}

	# If we're rendering (OpenGL) we create a transparent front layer for
	# use in descend mode.  If not, it's a frame.  Either way, it's also
	# the clipping rectangle.
	#
	set cg [$zinc add group $g -tags [concat $tags coregroup]]

	if {$glrender} {
		set front [$zinc add rectangle $cg $box -priority 150 -filled 1 \
			-linewidth 0 -visible 0 -tags [concat $tags front]]
	} else {
		set front [$zinc add rectangle $cg $box -priority 150 -filled 0 \
			-linewidth [Spans get cellHiliteWidth] -linecolor [Colors get descendLo] \
			-visible 0 -tags [concat $tags front]]
	}

	$zinc itemconfigure $cg -clip $front

	# If simplifying, we just draw the border and background.  
	# Otherwise, if paneling is on we attempt to build a Panel, if 
	# that fails we draw the core.
	#
	if {!$tooSmall && ![$self slot simplify]} {

		# turn off paneling if frame cell
		set paneling [$self slot paneling] 
		if {$i == 0 || $j == 0} {set paneling 0}

		# Attempt to build panel, if enabled
		set core ""
		if {$paneling} {
			set panel ""
			set opts ""
			lassign [$self getCPanel $c [$self getParam defaultCpanel]] panel opts
			if {$panel ne ""} {
				set core [$panel buildInZinc $zinc [$self slot tool] $cg $c $opts]
			}
		}

		# If not paneling or no panel returned, draw core
		#
		if {$core eq ""} {
			set x [$c slot core]
			switch [$x slot displayKey] {
				value {
					$zinc add text $cg -tags [concat $tags text textEpilog] \
						-priority 100 -visible 1

					$zinc add icon $cg -tags [concat $tags glyph] \
						-priority 100 -visible 1 -color [Colors get glyphTrans]
				}
				grid {
					set gw [Spans get gridWallWidth]
					$zinc add rectangle $cg [Zinc inside $zinc $cw 1 $gw] -visible 1 -priority 1000 \
						-filled 0 -linecolor [Colors get zGridWall] -linewidth $gw \
						-tags [list containedIn=$cw cell=$c depth=$d gridwall empty]
				}
				icon {
					$zinc add icon $cg -tags [concat $tags icon] \
						-priority 100 -visible 1
				}
			}

		}
	}

	# Now configure the items to match the given cell
	$self _updateSubCell $zinc $cw $c $i $j
}

# Update an already drawn cell as viewed in a grid or other places.
# The zinc id of the cell wall is given.
#
CellZincTable method _updateSubCell {zinc cw c i j} {
	poetvar $self glrender 

	# Get coords and group from cw
	set box [Zinc inside $zinc $cw]
	lassign $box x0 y0 x1 y1

	# Compute positions 
	set xc [expr {($x1 + $x0)/2}]
	set yc [expr {($y1 + $y0)/2}]

	set xt [+ $x0 [Spans get ipadX]]
	set yt [+ $y0 [Spans get ipadY]]

	set cww [- $x1 $x0]
	set cwh [- $y1 $y0]

	# Retrieve cell contents if atomic
	if {![Object exists $c]} {
		set cellType none
	} elseif {[$c atomic]} {
		set cellType atomic
	} else {
		set cellType grid
	}

	set coreAnchor "center"

	set v ""
	set tile ""

	# Configure cellWall by occupation type
	switch $cellType {
		none {
			set relief "flat"
			set borderStyle "dashed"
			set backFilled 1
			set borderLine [Colors get emptyFG]
			set backFill [Colors get emptyBG]
			set glyphOn 0
		}
		atomic {
			set v [$c get]

			set relief "roundraised"
			set borderStyle "simple"
			set backFilled 1
			set glyphOn [$self slot showTypes]
		}
		grid {
			set tile [Thyrd getImage gridtexture]

			set relief "roundsunken"
			set borderStyle "simple"
			set backFilled 1
			set glyphOn 0
		}
	}

	# Configure by position in grid
	if {$cellType ne "none"} {
		if {$i == 0 && $j == 0} {	;# the 0 cell
			set borderLine [Colors get zeroBG]
			set backFill [Colors get zeroBG]

			set coreColor [Colors get zeroFG]
			set corePos [list $xc $yc]

			if {$v eq ""} {
				set coreFont "frame-int"
				set coreSens 0
			} else {
				set coreFont "frame-str"
				set coreSens 1
			}

			set glyphOn 0
		} elseif {$j == 0} {	;# i frame
			set borderLine [Colors get iFrameBG]
			set backFill [Colors get iFrameBG]

			set corePos [list $xc $yc]

			if {$v eq ""} {
				set coreColor [Colors get frameFG-int]
				set coreFont "frame-int"
				set coreSens 0
				set v "$i"
			} else {
				set coreColor [Colors get frameFG-str]
				set coreFont "frame-str"
				set coreSens 1
			}

			set glyphOn 0
		} elseif {$i == 0} {	;# j frame
			set borderLine [Colors get jFrameBG]
			set backFill [Colors get jFrameBG]

			set corePos [list $xc $yc]

			if {$v eq ""} {
				set coreColor [Colors get frameFG-int]
				set coreFont "frame-int"
				set coreSens 0
				set v "$j"
			} else {
				set coreColor [Colors get frameFG-str]
				set coreFont "frame-str"
				set coreSens 1
			}

			set glyphOn 0
		} else {	;# contents
			set coreColor [Colors get cellFG]

			switch $cellType {
				none -
				atomic {
					set relief flat

					set borderLine [Colors get zCellWall]
					set backFill [Colors get cellBG]

					set coreFont "cell"
					set corePos [list $xt $yt] 
					set coreAnchor "nw"
					set coreSens 1
				}
				grid {
					set borderLine [Colors get zGridWall]

					set coreSens 0
				} 
			}
		}
	}

	# Configure by core type
	if {$cellType ne "none"} {
		set x [$c slot core]
		switch [$x slot displayKey] {
			value {
				set core [$zinc find withtag text&&containedIn=$cw]
				if {$core ne ""} {
					$zinc itemconfigure $core -font $coreFont -color $coreColor \
						-position $corePos -anchor $coreAnchor \
						-sensitive $coreSens -text $v
				}

				if {$glyphOn} {
					set glyph [$zinc find withtag glyph&&containedIn=$cw]
					if {$glyph ne ""} {
						$zinc itemconfigure $glyph -image [$c getGlyph] -position [list [- $x1 2] $y1] -anchor se
					}
				}
			}
			grid {
			}
			icon {
				set core [$zinc find withtag icon&&containedIn=$cw]
				if {$core ne ""} {
					set dcw [Spans get defaultCellW]
					if {$cww >= $dcw && $cwh >= $dcw} {
						set im [$x getIcon lg]
						set iconPos [list $xc $y0]
						set iconAnchor n
					} else {
						set im [$x getIcon sm]
							# A little fudge factor, because the fixed layout adds a little border.
							# Might want to remove border later, in which case this +1 should go.
							#
						set iconPos [list $x0 [+ $y0 1]]
						set iconAnchor nw
					}

					$zinc itemconfigure $core -image $im \
						-position $iconPos -anchor $iconAnchor 
				} else { 
					# no core to display, but we still want background color, so we get it from the large icon
					set im [$x getIcon lg]
				}

				set backFill [Colors fromRGB {*}[$im get 0 0]]
			}
		}
	}

	# Set options on cell wall
	if {$tile ne ""} {
		$zinc itemconfigure $cw -filled 1 -tile $tile -fillcolor black -relief $relief \
			-linecolor $borderLine -linestyle $borderStyle
	} else {
		$zinc itemconfigure $cw -filled $backFilled -fillcolor $backFill -relief $relief \
			-linecolor $borderLine -linestyle $borderStyle
	}
}

# 
# Draw the outerMembrane
#
CellZincTable method drawOuterMembrane {zinc group} {
	$zinc remove outerMembrane

	set w [$zinc cget -width]
	set h [$zinc cget -height]

	set tags "outerMembrane"

	lassign [Zinc offsetbox -[Spans get omOffset] 0 0 $w $h] x0 y0 x1 y1

	set g [$zinc add group $group -atomic 1 -tags [concat $tags group]]
	$zinc add rectangle $g [list $x0 $y0 $x1 $y1] -visible 0 -tags [concat $tags bbox dummy]

	array set back {
		-itemtype roundedrectangle
		-radius 8
	}

	array set backParams {
		-filled 1
		-visible 1
		-priority 10
	}

	set backParams(-fillcolor) [Colors get zCellBG] 
	set back(-coords) [list [list $x0 $y0] [list $x1 $y1]]

	set back(-params) [array get backParams]
	zincGraphics::BuildZincItem $zinc $g [array get back] [list outerMembrane back] --
	
	array set border {
		-itemtype roundedrectangle
		-radius 8
	}

	array set borderParams {
		-filled 0
		-linewidth 2
		-priority 11
	}

	set borderParams(-linecolor) [Colors get zOuterMembraneBorder]
	set border(-coords) [list [list $x0 $y0] [list $x1 $y1]]

	set border(-params) [array get borderParams]
	zincGraphics::BuildZincItem $zinc $g [array get border] [list outerMembrane borderline] --
}

#
# Draw the bottom margin of a cell and
# return the box for the core
#
CellZincTable method drawBottomMargin {zinc group} {
	lassign [$zinc coords outerMembrane&&bbox] a b
	lassign $a x0 y0
	lassign $b x1 y1
	set h [$zinc cget -height]

	set bm [$self getParam bottomMargin]
	if {$bm == 0} {	;# shouldn't get called in this case
		return [list $x0 $y0 $x1 $y1]
	}
		
	set mbm [$self slot minBottomMargin]
	set xPad [Spans get bmPad]
	set yPad [Spans get bmPad]
	set hw [Spans get bmHandleW]

	set x [expr $x0 + $xPad]
	set w [expr $x1 - $x0 - 2 * $xPad]

	$self slot _rlist [list]
	set y [expr {$h - $bm + $yPad - $hw}]
	set yy [expr $y1 - $yPad]

	$self _drawTriads $zinc $group A $x $y [set x [expr $x + ($w/3)]] $yy
	$self _drawTriads $zinc $group Y $x $y [set x [expr $x + ($w/3)]] $yy
	$self _drawTriads $zinc $group B $x $y [set x [expr $x + ($w/3)]] $yy

	foreach c [$self slot _rlist] {$self renderSub $c}

	return [list [expr $x0 + $xPad] [expr $y0 + $yPad] [expr $x1 - $xPad] [expr $y - $yPad]]
}

# Draw one set of the triads for this cell, adding subcells to ``_rlist``
# 
CellZincTable method _drawTriads {zinc group which x0 y0 x1 y1} {
	set c [$self viewCell]

	switch $which {
		A {
			set tlist [theSpace findTriads $c * *]
			set corners {1 1 0 0}
		}
		Y {
			set tlist [theSpace findTriads * * $c]
			set corners {0 0 0 0}
		}
		B {
		 	set tlist [theSpace findTriads * $c *]
			set corners {0 0 1 1}
		}
	}

	set ntriads [llength $tlist]
	set tags [list triads which=$which]
	set g [$zinc add group $group -atomic 0 -tags [concat $tags group]]

	# draw background 
	array set back {
		-itemtype roundedrectangle
		-radius 8
	}

	array set backParams {
		-filled 1
		-visible 1
		-priority 50
	}

	set backParams(-fillcolor) [Colors get "zTriadBG_$which"] 
	set backParams(-linecolor) [Colors get "zTriadBG_$which"] 
	set back(-corners) $corners
	set back(-coords) [list [list $x0 $y0] [list $x1 $y1]]

	set back(-params) [array get backParams]
	zincGraphics::BuildZincItem $zinc $g [array get back] [concat $tags back bbox] --

	# draw contents
	set xc [expr {$x0 + ($x1 - $x0)/2}]
	set h [expr {$y1 - $y0}]
	set yc [expr {$y0 + $h/2}]
	set y $y0

	set nc [::tk::Darken [Colors get "zTriadBG_$which"] 65]

	lassign [Zinc sizeOfGlyph $which] gw gh

	if {$h > $gh} {
		set glyph [Zinc drawGlyph $which $zinc $g [concat $tags glyph]]
		$zinc itemconfigure $glyph -priority 75
		set y [expr $y + 3]
		$zinc translate $glyph [+ $x0 3] $y

		$zinc add text $g -position [list [- $x1 5] $y] -text $ntriads \
			-font triad-count-big -color $nc \
			-anchor ne -priority 100 -sensitive 0 -tags [concat $tags text count]

		if {$ntriads > 0 && ($h - $gh) > (2 * [Spans get defaultCellH])} {
			set y [+ $y $gh]
			$self _drawTriadList $zinc $g $which $ntriads $tlist $x0 $y $x1 $y1
		}
	} else {
		$zinc add text $g -position [list $xc $yc] -text $ntriads \
			-font triad-count -color $nc \
			-anchor center -priority 100 -sensitive 0 -tags [concat $tags text count]
	}
}

# Draw a list of triads in the given box.  We just do the 
# layout and then append the cells to be rendered to the _rlist
# slot.
#
CellZincTable method _drawTriadList {zinc group which ntriads tlist x0 y0 x1 y1} {
	set box [Zinc assymoffsetbox -[Spans get ipadX] -[Spans get ipadY] $x0 $y0 $x1 $y1]
	lassign $box x0 y0 x1 y1

	set table [$zinc add group $group -tags [list triadTable which=$which] -priority 100]

	# invisible border, may want to make visible later
	#$zinc add rectangle $table $box -visible 1 -tags bbox

	set dh [Spans get defaultCellH]

	set wz [- $x1 $x0]
	set hz [- $y1 $y0]

	set w [/ $wz 2]
	set h [expr {($hz - $ntriads)/$ntriads}]

	if {$h < $dh} {
		set wontFit 1
		set srH [Spans get srHeight]

		set h $dh

		set nhz [- $hz $srH]
		set n [int [/ $nhz $dh]]

		set ntlist [lrange $tlist 0 $n-1]
	} else {
		set wontFit 0
		set ntlist $tlist
	}

	lassign [Triad others $which] whichL whichR

	# Lay the grid out with groups containing dummy rectangles, filled in by renderSub later.
	# Each cell needing rendering is added to ``_rlist`` and rendered later
	#
	set xl $x0 
	set xr [+ $x0 $w]

	set y $y0

	set index 0
	foreach t $ntlist {
		set cl [$t cell $whichL]
		set cr [$t cell $whichR]

		if {$cl ne ""} {$self slotUnique _rlist $cl}
		if {$cr ne ""} {$self slotUnique _rlist $cr}
		
		set yn [+ $y $h]

		set cbox [list $xl $y $xr $yn]
		$zinc add rectangle $table $cbox -visible 1 -fillcolor [Colors get "zTriadBGlite_$whichL"] \
			-tags [list cellwall triadList triad=$t which=$which cell=$cl depth=1 empty index=$index left]

		set cbox [list $xr $y $x1 $yn]
		$zinc add rectangle $table $cbox -visible 1 -fillcolor [Colors get "zTriadBGlite_$whichR"] \
			-tags [list cellwall triadList triad=$t which=$which cell=$cr depth=1 empty index=$index right]

		set y $yn
		incr index
	}

	if {$wontFit} {
		set y1 [+ $yn $srH]

		$zinc add rectangle $table [list [+ $xl 1] $yn [- $xr 1] $y1] -visible 1 -fillcolor [Colors get scrollRegion] \
			-filled 1 -linewidth 0 -tags upScroll=$which 
	   
		$zinc add icon $table -image [Thyrd getImage sr-up] \
			-composescale 1 -anchor s -position [list [/ [+ $xl $xr] 2]  $y1] -catchevent 0

		$zinc add rectangle $table [list [+ $xr 1] $yn [- $x1 1] $y1] -visible 1 -fillcolor [Colors get scrollRegion] \
			-filled 1 -linewidth 0 -tags downScroll=$which
	   
		$zinc add icon $table -image [Thyrd getImage sr-down] \
			-composescale 1 -anchor s -position [list [/ [+ $xr $x1] 2] $y1] -catchevent 0

		$zinc bind downScroll=$which <ButtonPress-1> [list $self _scrollTriadList $zinc $which $n $n $tlist] 
	}
}

# Scroll a new set of cells into the existing triad list
#
CellZincTable method _scrollTriadList {zinc which start n tlist} {
	set cells [list]
	lassign [Triad others $which] whichL whichR

	for {set i 0} {$i < $n} {incr i} {
		set t [lindex $tlist [+ $start $i]]
		if {$t ne ""} {
			set cl [$t cell $whichL]
			set cr [$t cell $whichR]
		}

		set x [$zinc find withtag triadList&&left&&which=$which&&index=$i]
		Zinc rmCellTag $zinc $x
		$zinc addtag empty withtag $x

		if {$t ne ""} {
			$zinc addtag cell=$cl withtag $x
			lappend cells $cl
		} else {
			$self _undrawSubCell $zinc $x
		}
		
		set x [$zinc find withtag triadList&&right&&which=$which&&index=$i]
		Zinc rmCellTag $zinc $x
		$zinc addtag empty withtag $x

		if {$t ne ""} {
			$zinc addtag cell=$cr withtag $x
			lappend cells $cr
		} else {
			$self _undrawSubCell $zinc $x
		}
	}

	foreach c $cells {$self renderSub $c}

	set ns [max [- $start $n] 0]
	$zinc bind upScroll=$which <ButtonPress-1> [list $self _scrollTriadList $zinc $which $ns $n $tlist] 

	set ns [+ $start $n]
	if {$ns >= [llength $tlist]} {
		$zinc bind downScroll=$which <ButtonPress-1> ""
	} else {
		$zinc bind downScroll=$which <ButtonPress-1> [list $self _scrollTriadList $zinc $which $ns $n $tlist] 
	}
}
	
# Draw the core in the given box
#
CellZincTable method drawCore {zinc vp c box} {
	$zinc remove core

	set tags [list cell=$c core]

	lassign $box x0 y0 x1 y1

	set g [$zinc add group $vp -atomic 1 -tags [concat $tags group]]

	array set back {
		-itemtype roundedrectangle
		-radius 8
	}

	array set backParams {
		-filled 1
		-visible 1
	}

	set backParams(-fillcolor) [Colors get zCoreBG] 
	set back(-coords) [list [list $x0 $y0] [list $x1 $y1]]

	set back(-params) [array get backParams]
	zincGraphics::BuildZincItem $zinc $g [array get back] [concat $tags back] --
	
	array set border {
		-itemtype roundedrectangle
		-radius 8
		-priority 50
	}

	array set borderParams {
		-filled 0
		-linewidth 1.5
		-priority 55
	}

	set borderParams(-linecolor) [Colors get zInnerMembraneBorder]
	set border(-coords) [list [list $x0 $y0] [list $x1 $y1]]

	set border(-params) [array get borderParams]
	zincGraphics::BuildZincItem $zinc $g [array get border] [concat $tags bbox cellwall cell=$c] --

	set t [$zinc add text $vp -position [list [expr {$x0 + 10}] [expr {$y0 + 5}]] \
		-font [list [Fonts slot prop] [$self getParam afontsize]] \
		-priority 100 -text [$c get] -sensitive 1 -tags [concat $tags atext text textEpilog]]

	$zinc focus $t
	$zinc cursor $t end
	focus $zinc
}

# 
# Draw a display indicating no cell was found
#
CellZincTable method drawNoCell {zinc group} {
	set w [$zinc cget -width]
	set h [$zinc cget -height]

	lassign [Zinc offsetbox -5 0 0 $w $h] x0 y0 x1 y1

	set xc [expr $x0 + ($x1 - $x0)/2]
	set yc [expr $y0 + ($y1 - $y0)/2]

	set vp [$self viewPath]
	if {$vp eq ""} {
		set msg ""
	} else {
		set msg "No cell found at path:\n$vp" 
	}

	$zinc add text $group -position [list $xc $yc] -text $msg \
		-sensitive 0 -anchor center -color white -tags [list [$self safetag] text textEpilog]
}

# Return a safetag for this object anded with the remaining arguments
#
CellZincTable method safetag {args} {
	set st [$self slot safetag]

	if {[llength $args] == 0} {
		return $st
	}

	return "${st}&&[join $args &&]"
}

# Called when drag is initiated from a CellZincTable.
# NOTUSED??
#
CellZincTable method draginit {path row col topLvl} {
	set tab [$self slot _table]

	#theThyrdToolbox drag $path [$tab get $row,$col]
	#$path config -cursor dot
	return [list TEXT [list copy] [$tab get $row,$col]]
}

# Called when a drop occurs on a CellZincTable
# NOTUSED??
#
CellZincTable method dropcmd {target src row col op type data} {
	set tab [$self slot _table]

	if {[$self validateCell $col $row [$tab get $row,$col] $data]} {
		$tab set $row,$col $data
	}

	return 1
}

# Should we draw one of the frames?  We're given the
# axis, grid cell and depth we're drawing it at.  The
# slots iframeViz and jframeViz control the visibility.
#
# This version now looks at the depth, so that "always"
# and "never" now apply only to the topmost level.
#
CellZincTable method shouldDrawFrame {which c d} {
	if {$d == 1} {
		switch [$self slot ${which}frameViz] {
			auto {
				return [$c as CMGrid hasFrameValues $which]
			}
			always {
				return 1
			}
			never {
				return 0
			}
		}
	} else {
		return [$c as CMGrid hasFrameValues $which]
	}
}

# Return the panel for a grid cell, if we're paneling
# and grid panels are turned on, using the defaultGpanel param.
# This is smarter than ``getCPanel``, which assumes some
# of the decisions are already made (like whether paneling
# is on). This can be called either to actually get the
# panel or to determine if one is available.
#
# The options to the panel are returned as the
# second item.
#
CellZincTable method getGPanel {c} {
	if {![$self getParam panels]} {return [list "" ""]}
	if {![$self getParam gridpanels]} {return [list "" ""]}

	set panel [theSpace getAttr $c panel]
	if {$panel eq ""} {
		lassign [$c size] iSize jSize
		set flip [$self _computeIDown $jSize]

		switch [$self getParam defaultGpanel] {
			table {
				set panel Table
				set opts [list -flip $flip]
			}
			"read-only table" {
				set panel Table
				set opts [list -readonly 1 -flip $flip]
			}
			default {return [list "" ""]}
		}
	} else {
		set opts [lrange $panel 1 end]
		set panel [lindex $panel 0]
	}

	set p GP$panel
	if {[catch {$p noop}]} {
		UserMsg warning "|$self getGPanel $c| Panel type $p not found in library"
		return [list "" ""]
	}

	return [list $p $opts]
}

# Return the panel for a cell, given the value of the
# defaultCpanel param.  This is for subcell display,
# so if it's a grid we return null.
#
# The options to the panel are returned as the
# second item.
#
CellZincTable method getCPanel {c defC} {
	if {![$c atomic]} {return [list "" ""]}

	set panel [theSpace getAttr $c panel]
	if {$panel eq ""} {
		switch $defC {
			"by type" {
				set ct [$c getType]
				set cth [lindex $ct 0]

				if {[string match <* $cth]} {	;# fill in default params for Poet types
					set cta [Type getParams $ct]
				} else {
					set cta [lrange $ct 1 end]
				}

				switch $cth {
					Core -
					<variable> -
					<string> {
						set panel Entry
						set opts ""
					}
					<boolean> {
						set panel Boolean
						set opts ""
					}
					<choice> {
						set panel Choice
						set opts $cta
					}
					<color> {
						set panel Color
						set opts ""
					}
					<font> {
						set panel Font
						set opts ""
					}
					<integer> {
						set panel Spinbox
						set opts [list -fts $cta]
					}
					<pixels> {
						set panel Spinbox
						set opts [list -fts $cta]
					}
					<real> {
						set panel Scale
						set opts [list -integer 0 -fts $cta -orient auto -ttk 0 -showvalue 0]
					}
					<script> {
						set panel Text
						set opts [list -hilite 1]
					}
					Path {
						set panel Path
						set opts ""
					}
					TriadCore {
						set panel Triad
						set opts ""
					}
					Opcode -
					Grid {
						return [list "" ""]
					}
				}
			}
			"text entries" {
				if {[$c getType 1] in {Grid Opcode}} {
					return [list "" ""]
				}
					
				set panel Entry
				set opts ""
			}
			none {return [list "" ""]}
		}
	} else {
		set opts [lrange $panel 1 end]
		set panel [lindex $panel 0]
	}

	set p AP$panel
	if {[catch {$p noop}]} {
		UserMsg warning "|$self getCPanel $c $defC| Panel type $p not found in library"
		return [list "" ""]
	}

	return [list $p $opts]
}

# Called when dragging is initiated on the canvas
#
CellZincTable method dragInit {path rx ry topLvl} {
	poetvar $self zinc


	set x [- $rx [winfo rootx $zinc]]
	set y [- $ry [winfo rooty $zinc]]

	set c [$self getCellUnder $zinc $x $y]
	if {$c eq ""} {return ""}

	if {[$c isOfCoreType Opcode]} {
		set ids [$zinc find overlapping $x $y $x $y]

		set g ""
		foreach i $ids {
			if {[$zinc hastag $i icon]} {
				set g $i
				break
			}
		}

		if {$g eq ""} return

		set im [$c getGlyph]
	} else {
		set ids [$zinc find overlapping $x $y $x $y]

		set g ""
		foreach i $ids {
			if {[$zinc hastag $i glyph]} {
				set g $i
				break
			}
		}

		if {$g eq ""} return

		set im [$zinc itemcget $g -image]
	}

	Window dragImage $topLvl $im

	return [list SIGN {copy} [list Cell $c]]
}

# Called when a drop operation is over the canvas
#
# DEFERRED we currently accept all drops.
#
CellZincTable method dropOver {target source event rx ry op type data} {
	return 1
}

# Called when something is dropped on the canvas. We pop up
# a menu to determine how to drop.
#
CellZincTable method drop {zinc source rx ry op dtype data} {
	set x [- $rx [winfo rootx $zinc]]
	set y [- $ry [winfo rooty $zinc]]

	lassign [$self getGIJUnder $zinc $x $y] g i j

	# Handle all the drops that don't require a menu popup
	switch $dtype {
		TEXT {
			$self _dropCopy value $data $g $i $j
			$self reconfigure
			return 1
		}
		SIGN {
			lassign $data what src
			switch $what {
				FORCE-Cell {
					$self _dropCopy cell $src $g $i $j
					$self reconfigure
					return 1
				}
				Path {
					$self _dropCopy path-text $src $g $i $j
					$self reconfigure
					return 1
				}
			}
		}
	}

	# If we get here, it should be because we got a SIGN were what == Cell

	set c [$g subCell $i $j]
	if {$c eq ""} {
		set msg "Drop on location $i $j"
	} else {
		set msg "Drop on cell $c at [$c betterIndex]"
	}

	set m $zinc.popupMenu
	catch {destroy $m}

	menu $m -tearoff 0
	$m add command -label $msg \
		-background [Colors get menuHeaderBG] -activebackground [Colors get menuHeaderBG] \
		-foreground [Colors get menuHeaderFG] -activeforeground [Colors get menuHeaderFG]
	$m add separator
	$m add command -label "Copy cell" -command [list $self _dropCopy cell $src $g $i $j]
	$m add command -label "Copy value" -command [list $self _dropCopy value $src $g $i $j]
	$m add command -label "Copy path" -command [list $self _dropCopy path $src $g $i $j]

	set yo [/ [+ [$m yposition 2] [$m yposition 3]] 2]
	tk_popup $m $rx [- $ry $yo]
	return 1
}

# Complete a drop operation
#
# DEFERRED
# Copying a cell or path counts as two undoable ops (set and type).
# Creating a new cell isn't undoable yet.
#
# Note: when we set a type, we also set the value to "" first to
# prevent type errors.
#
CellZincTable method _dropCopy {what src g i j} {
	set c [$g subCell! $i $j]
	switch $what {
		cell {
			theSpace editSet $c ""
			theSpace editSetType $c [$src getType]
			theSpace editSet $c [$src get]
		}
		value {
			theSpace editSet $c [$src get]
		}
		path {
			theSpace editSet $c ""
			theSpace editSetType $c Path
			theSpace editSet $c [$src path]
		}
		path-text {
			theSpace editSet $c ""
			theSpace editSetType $c Path
			theSpace editSet $c $src
		}
	} 


	# Original, pre-undo code
	#		cell {$g subCell! $i $j [$src get] [$src getType] yes}
	#		value {$g subCell! $i $j [$src get] Core yes}
	#		path {$g subCell! $i $j [$src path] Path yes}
	#		path-text {$g subCell! $i $j $src Path yes}
}

# Called when something is dropped on the canvas.
# KLUDGEd version.
#
CellZincTable method dropOn {rx ry type data} {
	poetvar $self zinc

	# assuming type = SIGN data = {Cell <cell>}
	lassign $data dtype cell

	set x [- $rx [winfo rootx $zinc]]
	set y [- $ry [winfo rooty $zinc]]

	set ids [$zinc find overlapping $x $y $x $y]

	set vc [$self viewCell]
	if {[$vc atomic]} {
		if {[Zinc searchForTag $zinc "core" $ids] ne ""} {
			$vc setFrom $cell
		}
	} else {
		set i [Zinc searchForTag $zinc "cell=*" $ids]
		if {$i ne ""} {
			set c [Zinc itemCell $zinc $i]
			if {[$c atomic]} {
				$c setFrom $cell
			}
		}
	}

	return 1
}
