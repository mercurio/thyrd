# Window -- a toplevel window that stores its
# persistent data in thyrdspace.  This object
# also acts as the boss of all Windows. And some
# miscellaneous GUI code is kept here.
#
# PJM 2006-07-20	Begun

MainFrameTool construct Window

## Boss slots (should only be set on Window)

# The cell in thyrdspace that's the root of our data
# (/thyrd/windows). 
#
Window slot twcell	{}		

# True if we're watching twcell
Window slot watching 0

## Individual Window slots

# The cell in thyrdspace that's the root of our data
# (a cell in /thyrd/windows)
#
Window slot winCell {}

# True if this window should attend to reconfiguration
# events. If disabled on Window itself, turns off all
# reconfiguration (handy when the program is exiting,
# else the toolbox closing can cause the /thyrd/windows
# cells to be deleted, creating a thyrdspace file that
# won't load properly).
#
Window slot reconfiguring 1

## Boss methods

# Initialize the Windows described in the thyrdspace.
# If none are present or reopen is 0, open the Thyrd toolbox.
#
Window method initialize {{reopen 1}} {
	poetvar $self twcell

	set p [Path newVolatile "/thyrd/windows"]
	set twcell [$p resolve "" yes]
	$p destruct

	if {$twcell eq ""} {
		UserMsg error "|$self initialize| Unable to find or create /thyrd/windows"
		return
	}

	# Before we start watching /thyrd/windows, open
	# the existing windows or just the toolbox, if empty

	foreach {si sj} [$twcell size] break

	if {!$reopen || ($si < 2 && $sj < 2)} {	;# either atomic or empty grid
		$self openWindow [Window newWindow Toolbox]
	} else {
		foreach {wi wj} [$twcell as CMGrid walk] {
			$self openWindow [$twcell as CMGrid getCell $wi $wj]
		}
	} 

	# Watch for particular events in /thyrd/windows
	$twcell addObserver gainSub $self gainWindow
	$twcell addObserver loseSub $self loseWindow
	$self slot watching 1
}

# Called when /thyrd/windows gains a window cell
#
Window method gainWindow {target event cw i j} {
	if {![$self slot watching]} return

	# we don't care about new frame cells
	if {$i == 0 || $j == 0} return

	$self openWindow $cw
}

# Called when /thyrd/windows loses a window cell
#
Window method loseWindow {target event cw i j} {
	if {![$self slot watching]} return
	 
	# we don't care about losing frame cells
	if {$i == 0 || $j == 0} return

	set win [$cw getAt poetObject 1]
	Object safe $win destruct
}

# Given a grid cell representing a window, construct
# a new window (called on ``Window``)
#
Window method openWindow {cw} {
	set wtype [$cw getAt type]
	switch $wtype {
		""	{return}
		Toolbox {
			ThyrdToolbox construct theThyrdToolbox TkDot
			set win theThyrdToolbox
		}
		CellEditor {
			set win [CellEditor construct * . -view zinc -paramList [$cw subCell! params]]
		}
		CellTextEditor {
			set win [CellEditor construct * . -view tktable -paramList [$cw subCell! params]]
		}
		WaveEditor {
			set win [WaveEditor construct * . -paramList [$cw subCell! params]]
		}
		RestServer {
			set win [RestServer construct * . -paramList [$cw subCell! params]]
		}
		IconEditor {
			set win [IconEditor construct * . -paramList [$cw subCell! params]]
		}
	}

	$win slot winCell $cw

	# We do all this to avoid binding to anything other
	# than the toplevel
	set bc "[$win safeName]-reconfig"
	set bd "[$win safeName]-destroy"
	bind $bc <Configure> [list $win reconfigure]
	bind $bc <Map> [list $win reconfigure]
	bind $bc <Unmap> [list $win reconfigure]
	bind $bd <Destroy> [list $win destroyEvent %W]

	bindtags [$win primary] [list $bd $bc [$win primary] Toplevel all]


	foreach {var handler} {width newWidth  height newHeight  x newXPos  y newYPos visible newVisibility} {
		set $var [$cw watchSub $win $handler $var]
	}

	# setGeometry knows how to handle null values for w, h, etc.
	$win setGeometry $width $height $x $y

	#DEFERRED (is this still true?) update necessary, causes extra redraw  
	# needed in current state of CellZincTable (widgetframe/zincframe overlay)
	update 

	# If it's an editor, render the contents
	switch $wtype {
		RestServer -
		WaveEditor -
		CellTextEditor -
		CellEditor {
			$win refresh
		}
	}

	#DEFERRED what type?
	$cw putAt $win poetObject

	$win setVisibility $visible
}

# Set the visibility of this window
#
Window method setVisibility {visible} {
	if {$visible} {
		$self wm deiconify
		$self raise
	} else {
		$self wm iconify
	}
}

#  Observer handler methods
Window method newWidth {target event} {$self setGeometry [$target get] "" "" ""}
Window method newHeight {target event} {$self setGeometry "" [$target get] "" ""}
Window method newXPos {target event} {$self setGeometry "" "" [$target get] ""}
Window method newYPos {target event} {$self setGeometry "" "" "" [$target get]}
Window method newVisibility {target event} {$self setVisibility [$target get]}

# 
# Schedule a save of the window state (called when a Configure event occurs)
#
Window method reconfigure {} {
	if {![Window slot reconfiguring]} return
	if {![$self slot reconfiguring]} return

	if {[$self slot winCell] eq ""} return

	set a [$self slot saveWinAfter]
	if {$a eq ""} {
		$self slot saveWinAfter [after idle [list Object safe $self saveWindow]]
	}
}

#
# If this window is being destroyed, remove its cell from /thyrd/windows.
# If some subordinate window is being destroyed, ignore it.
#
# We also ignore it at exit, as indicated by ``Window slot reconfiguring``.
#
Window method destroyEvent {win} {
	if {![Window slot reconfiguring]} return

	if {$win ne [$self slot _primary]} return

	poetvar Window twcell

	Window slot watching 0
	$twcell as CMList delete [$self slot winCell]
	$self slot winCell {}
	Window slot watching 1

	$self bind <Destroy> {}
}


# Default parameters for the various window types
#
Window slot _defaults_Toolbox {}
Window slot _defaults_IconEditor [IconEditor slot _defaultParams]
Window slot _defaults_CellEditor [concat [NavBar slot _defaultParams] [EditBar slot _defaultParams] \
	[DisplayControls slot _defaultParams] \
	[CellTable slot _defaultParams] \
	{-showNavBar {1 <boolean>} -showEditBar {1 <boolean>} -showTree {0 <boolean>} -showTriadBar {0 <boolean>}}]

Window slot _defaults_WaveEditor [concat [WaveBar slot _defaultParams] [WaveEditor slot _defaultParams]]
Window slot _defaults_RestServer [RestServer slot _defaultParams]

# DEPRECATED
Window slot _defaults_CellTextEditor [NavBar slot _defaultParams]

# Create a grid cell representing a window and
# put it in /thyrd/windows. If ``Window`` is
# watching /thyrd/windows, this creates a new window.
#
# Options may be given in ``-flag value`` format.
# Flags begining with ``--`` are general window
# options, those with 1 - go in the params subcell.
#
Window method newWindow {type args} {
	poetvar $self twcell

	# General parameters default
	array set types {--visible <boolean> --w <integer> --h <integer> --x <integer> --y  <integer>}
	array set opts {--visible 1 --w "" --h "" --x "" --y ""}

	# defaults for this type
	array set opts [$self slot _defaults_$type]

	# Add in argument list
	array set opts $args

	set cw [Cell new "" Grid]

	$cw putTypeAt $type Core type
	$cw putTypeAt $opts(--w) $types(--w) width
	$cw putTypeAt $opts(--h) $types(--h) height
	$cw putTypeAt $opts(--x) $types(--x) x
	$cw putTypeAt $opts(--y) $types(--y) y
	$cw putTypeAt $opts(--visible) $types(--visible) visible

	set pl [Cell new "" Grid]
	$cw storeSub $pl params 1

	foreach p [array names opts -regexp {^-[^\-].*}] {
		set pp [string range $p 1 end]
		if {[llength $opts($p)] > 1} {
			$pl putTypeAt {*}$opts($p) $pp 
		} else {
			$pl putAt $opts($p) $pp 
		}
	}

	$twcell as CMList appendCell $cw 
	
	return $cw
}

# Using the slot ``winCell``, a grid cell representing 
# this window, save our state (called on children of ``Window``)
#
Window method saveWindow {} {
	set cw [$self slot winCell]
	if {![Object exists $cw]} return

	if {[$self isA ThyrdToolbox]} {
		set type Toolbox
	} elseif {[$self isA CellEditor]} {
		if {[$self slot view] eq "tktable"} {
			set type CellTextEditor
		} else {
			set type CellEditor
		}
	} elseif {[$self isA IconEditor]} {
		set type IconEditor
	} elseif {[$self isA WaveEditor]} {
		set type WaveEditor
	} elseif {[$self isA RestServer]} {
		set type RestServer
	} else {
		UserMsg warning "|$self saveWindow| Window is of unknown type, not saving"
	}

	$cw putAt $type type
		
	foreach {width height x y} [$self getGeometry] break

	switch [$self wm state] {
		normal	{set visible 1}
		iconic	{set visible 0}
		default {set visible 1}
	}

	# Set each of the cells, but ignoring them so we 
	# don't infinitely recurse
	#
	#DEFERRED add types
	#
	foreach {var} {width height x y visible} {
		$cw putAtIgnore $self [set $var] $var
	}

#DEFERRED save sub params here?

	$self slot saveWinAfter ""
}

# 
# Set the geometry to what it already is, unless it's not
# set yet.  This is handy when the contents of the toplevel
# are being rearranged but you don't want the whole window
# to be resized.  A good example is when toolbars are added
# or removed from a MainFrameTool.
#
Window method keepGeometry {} {
	set g [$self wm geometry]

	if {$g != "1x1+0+0"} {$self wm geometry $g}
}

# Set the image for a drag operation.  It will be
# transparent on those systems that support such
# things.
#
Window method dragImage {top im} {
	set c [Colors get transDrag]
	catch {wm attributes $top -transparentcolor $c}
    label ${top}.l -image $im -relief flat \
		-borderwidth 0 -background $c
	pack ${top}.l
}
