### WaveEditor - Tool for viewing and editing waves
#
# PJM 	2008-01-31	Begun
# PJM	2008-03-31	Drag and drop begun, drop on tablelist, drag from canvas
# PJM	2008-06-23	Revisions for new Wave implementation started
# PJM	2010-06-13	Menu option to show/hide wave table added


Window construct WaveEditor
WaveEditor mixin CellObserver
WaveEditor mixin ParamListOwner

# Default values for the params specific to a WaveEditor
WaveEditor slot _defaultParams {	
	-showBar {1 <boolean>}
	-showTable {1 <boolean>}
	-wave "" 
	-maxstack {15 "<integer> 1 100"}
}

# Options that must be specified at creation time
WaveEditor slot extraOptions {paramList}

# The list cell that contains our parameters
#
WaveEditor slot paramList {}
WaveEditor type paramList Cell

# The wave we're editing, gotten from the param ``wave``
#
WaveEditor slot wave {}
WaveEditor type wave Wave

# Which style: old (X unX A unA ...) or new (X A B Y unX unA ...)
WaveEditor slot stacksGrouped 1
WaveEditor type stacksGrouped <boolean>

# Called to set up watching of the cells in the paramList
#
WaveEditor method watchParams {pl} {
	$pl watchSub! $self newSelWave wave
	$pl watchSub! $self newNextWave nextwave
}

# Observer handler
# Invoked when a new wave is created
#
WaveEditor method newWave {{target ""} {event ""} {wave ""}} {
	$self slot _waves [theSpace listWaves]
}

# Observer handler
# ``nextwave`` has changed, either watch or unwatch Wave starts
#
WaveEditor method newNextWave {target event} {
	set nw [$target get]

	if {$nw} {
		Wave addObserver start $self anyStart
	} else {
		Wave deleteObserver start $self
	}
}

# Observer handler
# Invoked when any wave is started. We use this just
# to catch the wave, then we rely on the wave's step notices.
#
# We only watch when nextwave is set, so we don't have to check
# it here. ``Wave step`` relies on the count of observers to
# know if a wave is being watched.
#
WaveEditor method anyStart {{target ""} {event ""} {wave ""}} {
	$self setParam wave $wave
	$self setParam nextwave 0
	Object safe [$self slot _ctrlBar] setFwdButtons 1
	Object safe [$self slot _ctrlBar] setBackButton [$wave isBiDi]
}

# Observer handler
# Invoked when a wave is selected
#
WaveEditor method newSelWave {{target ""} {event ""}} {
	set wave [$target get]

	$self _observe [$target get]
	$self _select $wave
	$self render 
}


# Build the primary for a WaveEditor
# We pick up _mainframe from MainFrameTool
#
WaveEditor method buildPrimary {} {
	$self destroyPrimary

	# Since waves are no longer persistent, we erase the wave
	# param value when constructing a new WaveEditor
	#
	$self setParam wave ""

	$self slot _showBar [$self getParam showBar] 
	$self slot> _showTable [$self getParam showTable] {$self showTable $value}

    $self slot menu [list "&Wave" all object 1]
    $self slotAppend menu [format {
            {command "&Refresh" {} "Refresh display" {} -command "%s render"}
            {command "&Unselect wave" {} "Clear wave selection" {} -command "%s clearSelection"}
            {command "&Next wave" {} "Catch next wave created" {} -command "%s nextWave"}
            {command "R&eset wave" {} "Reset the displayed wave" {} -command "%s resetWave"}
            {command "&Close" {} "Close this window" {} -command "%s destruct"}
        } $self $self $self $self $self]

	$self slotAppend menu "&View" all options 1
	$self slotAppend menu [format {
            {checkbutton "&Control Toolbar" {all option} "Show/hide control toolbar" {} -variable %s}
            {checkbutton "&Wave Table" {all option} "Show/hide wave table" {} -variable %s}
			{command "&Unhilite Waves" {} "Clear highlighting in wave table" {} -command "%s unhilite"}
        } \
      [$self slotVar _showBar] [$self slotVar _showTable] $self \
	]

	set prim [$self as MainFrameTool buildPrimary]
	set mf [$self getFrame]
	set pl [$self slot paramList]
	assert {$pl ne ""}

	$self wm withdraw

	ttk::panedwindow $mf.pw -orient horizontal

	set table [$self slot _table $mf.pw.table]
	$self slot _waves [theSpace listWaves]

	gridplus::gridplus tablelist $table -arrowcolor red -width 0 -height 8 -action single \
		-insertexpr {%1 in {break error confused} || [$self badCell %2 %3]} \
		-insertoptions {{1 -fg red} {1 -selectforeground red}} \
		-scrollauto xy \
		-listvariable [$self slotVar _waves] -command "$self waveTableHit" \
		-tableoptions stripe -relief groove -selectfirst 1 -sortfirst 1 { 
			0 "Wave" left
			0 "State" left
			0 "Start" left
			0 "Result" left
		}

	set tbl ${table}.tablelist
	$tbl configure -stripebackground [Colors get stripeBG]

	DropSite::register [$tbl bodypath] -dropcmd [list $self dropOnTable] \
		-droptypes  {SIGN {copy {}} TEXT {copy {}} }

	ttk::frame $mf.pw.view
	$self buildCanvas $mf.pw.view

	$mf.pw add $mf.pw.table -weight 0
	$mf.pw add $mf.pw.view -weight 1

	pack $mf.pw -fill both -expand 1

	# Construct the control bar using ``addToolBarSlot``,
	# then augment the write method for the _showBar slot.
	#
	$self slot _ctrlBar [WaveBar new [$self addToolBarSlot _showBar [$self slot _showBar]] $pl $self]
	$self methodAppend _showBar> {$self setParam showBar $value}

	Wave addObserver new $self newWave
	Wave addObserver state $self waveState
	theSpace addObserver stats $self newWave
	$self newWave

	$self _select [$self getParam wave]

	$self addResizer

	$self wm deiconify

    update ;# without this, sash won't be set
	$mf.pw sashpos 0 120

	return $prim
}

# Show/unshow the wave table
#
WaveEditor method showTable {x} {
	if {[$self slot _primary] eq ""} return

	set mf [$self getFrame]

	if {$x eq "" || !$x} {
		$mf.pw forget $mf.pw.table
	} else {
		$mf.pw forget $mf.pw.view

		$mf.pw add $mf.pw.table -weight 0
		$mf.pw add $mf.pw.view -weight 1
		update idletasks
		$mf.pw sashpos 0 120
	}
}

# Show/unshow the wave table
#
WaveEditor method OLDshowTable {x} {
	if {$x eq "" || !$x} {
		set s [$self slot _sashpos 0]
	} else {
		set s [$self slot _sashpos 120]
	}

	if {[$self slot _primary] ne ""} {
		set mf [$self getFrame]
		$mf.pw sashpos 0 $s
	}
}

# Return true if any of the args are cells that don't
# exist.  Paths are assumed to exist.
#
WaveEditor method badCell {args} {
	foreach a $args {
		if {[string match @* $a] && [![Object exists $a]} {return 1}
	}

	return 0
}

# Build the canvas, setting ``zinc``, in the given frame. 
#
WaveEditor method buildCanvas {mf} {
	$self slot safetag [$self safeName]
	$self slot glrender 1

	::ttk::scrollbar ${mf}.sx -orient horizontal -command [list ${mf}.z xview]
	::ttk::scrollbar ${mf}.sy -orient vertical -command [list ${mf}.z yview]

	set zinc [$self slot zinc ${mf}.z]
	zinc $zinc -render [$self slot glrender] -borderwidth 0 -highlightthickness 0 \
		-width 390 -height 290 \
		-lightangle 140 -backcolor [Colors get zBG] \
		-font cell -tile [Thyrd getImage bg-wave]

	grid columnconfigure $mf 1 -weight 1
	grid    rowconfigure $mf 1 -weight 1

	grid ${mf}.z -row 1 -column 1 -sticky nsew
	grid ${mf}.sx -row 2 -column 1 -sticky nsew
	grid ${mf}.sy -row 1 -column 2 -sticky nsew

	$self slot scrollx ${mf}.sx
	$self slot scrolly ${mf}.sy

	::autoscroll::autoscroll ${mf}.sx
	::autoscroll::autoscroll ${mf}.sy

	# 1 overlay plane, 1 normal plane, 1 underlay
	set super [$self slot super [$zinc add group 1 -priority 150]]
	set norm [$self slot norm [$zinc add group 1 -priority 100]]
	set sub [$self slot sub [$zinc add group 1 -priority 50]]

	DragSite::register ${mf}.z -dragevent 1 -draginitcmd [list $self dragInit]

	set pl [$self slot paramList]
	$self watchParams $pl

	$self drawWave $zinc
	$self setBindings $zinc

	$self _observe [$self getParam wave]
	$self render 
}

# Set the UI bindings
#
WaveEditor method setBindings {zinc} {
	$zinc bind errorIndicator <1> [list $self _showErrorInfo $zinc 1]
	$zinc bind error <1> [list $self _showErrorInfo $zinc 0]
}

# Show the full error info, or hide it
#
WaveEditor method _showErrorInfo {zinc onOff} {
	if {$onOff} {
		$zinc itemconfigure errorIndicator -visible 0
		$zinc itemconfigure errorBox -visible 1 -sensitive 1
		$zinc itemconfigure error -visible 1 -sensitive 1
	} else {
		$zinc itemconfigure errorIndicator -visible 1
		$zinc itemconfigure errorBox -visible 0 -sensitive 0
		$zinc itemconfigure error -visible 0 -sensitive 0
	}
}

# Draw the items that will be filled in by render 
#
WaveEditor method drawWave {zinc} {
	poetvar $self super norm sub

	set wz [$zinc cget -width]
	set hz [$zinc cget -height]

	set cw [Spans get defaultCellW]
	set ch [Spans get defaultCellH]	

	# Status indicators

	set sx 5
	set sy 5
	set sw 110
	set sh [+ [* $ch 2] 3 20 3 20]

	# draw background 
	array set back {
		-itemtype roundedrectangle
		-radius 10
	}

	array set backParams {
		-filled 1
		-visible 1
	}

	set backParams(-fillcolor) [Colors get wStatusBG] 
	set backParams(-linecolor) [Colors get wStatusEdge] 
	set back(-coords) [list [list $sx $sy] [list [+ $sx $sw] [+ $sy $sh]]]

	set back(-params) [array get backParams]
	zincGraphics::BuildZincItem $zinc $sub [array get back] statusBox --

	set sx [+ $sx 8]
	set sy [+ $sy 5]
	set sxm	$sx

	$zinc add icon $norm -position [list $sx $sy] \
		-image [Thyrd getImage nosub] -tags insubIcon

	lassign [Thyrd getImageSize nosub] iw ih

	$zinc add text $norm -position [list [expr {$sx + ($iw/2)}] [expr {$sy + ($ih/2)}]] \
		-font wave -color [Colors get wStatusText] \
		-anchor c -sensitive 0 -tags subDepth

	set sx [+ $sx 25]
	
	$zinc add icon $norm -position [list $sx $sy] \
		-image [Thyrd getImage bidi] -tags bidiIcon

	set sx [+ $sx 25]

	$zinc add icon $norm -position [list $sx $sy] \
		-image [Thyrd getImage eye] -tags watchIcon

	set sx [+ $sx 22]

	$zinc add text $norm -position [list $sx $sy] \
		-font wave -color [Colors get wStatusText] \
		-anchor nw -sensitive 0 -tags watch

	set sx $sxm
	set sy [+ $sy 22]

	$zinc add icon $norm -position [list $sx $sy] \
		-image [Thyrd getImage wi-confused] -tags stateIcon

	set sx [+ $sx 22]

	$zinc add text $norm -position [list $sx $sy] \
		-font wave -color [Colors get wStatusText] \
		-anchor nw -sensitive 0 -tags state

	set sx $sxm
	set sy [+ $sy 22]

	# The error indicator and overlay
	#
	$zinc add text $norm -position [list $sx $sy] \
		-font wave -color [Colors get wStatusText] \
		-anchor nw -sensitive 1 -tags errorIndicator -visible 0

	$zinc add rectangle $super [list 0 0 0 0] \
		-priority 1 -visible 0 -linewidth 3 -linecolor [Colors get wErrorEdge] \
		-filled 1 -fillcolor [Colors get wErrorBG] \
		-tags errorBox -visible 0 -sensitive 0

	$zinc add text $super -position [list $sx $sy] \
		-priority 100 \
		-font wave -color [Colors get wErrorText] \
		-anchor nw -sensitive 0 -tags error -visible 0

	# Start and anchor cells

	set glrender [$self slot glrender]
	set lw [Spans get cellWallWidth]
	set lc [Colors get zCellWall]
	set fc [Colors get zCellBG]

	set cx [+ $sx $sw 20]
	set cy 10

	$self drawCell $zinc $glrender $norm 100 $lw $lc $fc $cx $cy $cw $ch "start"

	set cy [+ $cy $ch 3]

	set lbl [$zinc add text $norm -position [list $cx $cy] \
		-font wave-label -color [Colors get waveText] \
		-anchor nw -sensitive 0 -text "Start: "]

	lassign [$zinc bbox $lbl] ax0 ay0 ax1 ay1

	$zinc add text $norm -position [list $ax1 $cy] \
		-font wave-path -color [Colors get waveText] \
		-anchor nw -sensitive 0 -tags [list start path]

	set cy [+ $cy 20]

	$self drawCell $zinc $glrender $norm 100 $lw $lc $fc $cx $cy $cw $ch "anchor"

	set cy [+ $cy $ch 3]

	set lbl [$zinc add text $norm -position [list $cx $cy] \
		-font wave-label -color [Colors get waveText] \
		-anchor nw -sensitive 0 -text "Anchor: "]

	lassign [$zinc bbox $lbl] ax0 ay0 ax1 ay1

	$zinc add text $norm -position [list $ax1 $cy] \
		-font wave-path -color [Colors get waveText] \
		-anchor nw -sensitive 0 -tags [list anchor path]

	# Next and previous cells

	set cx [+ $sx $sw 20 300]
	set cy 10

	$self drawCell $zinc $glrender $norm 100 $lw $lc $fc $cx $cy $cw $ch "next"

	set cy [+ $cy $ch 3]

	set lbl [$zinc add text $norm -position [list $cx $cy] \
		-font wave-label -color [Colors get waveText] \
		-anchor nw -sensitive 0 -text "Next: "]

	lassign [$zinc bbox $lbl] ax0 ay0 ax1 ay1

	$zinc add text $norm -position [list $ax1 $cy] \
		-font wave-path -color [Colors get waveText] \
		-anchor nw -sensitive 0 -tags [list next route]

	set cy [+ $cy 20]

	$self drawCell $zinc $glrender $norm 100 $lw $lc $fc $cx $cy $cw $ch "prev"

	set cy [+ $cy $ch 3]

	set lbl [$zinc add text $norm -position [list $cx $cy] \
		-font wave-label -color [Colors get waveText] \
		-anchor nw -sensitive 0 -text "Prev: "]

	lassign [$zinc bbox $lbl] ax0 ay0 ax1 ay1

	$zinc add text $norm -position [list $ax1 $cy] \
		-font wave-path -color [Colors get waveText] \
		-anchor nw -sensitive 0 -tags [list prev route]

	# Stacks
	set x 5
	set y [+ $sh 14]
	set sa [Thyrd getImage stack-arrow] 

	if {[$self slot stacksGrouped]} {
		$self drawStack $zinc $norm $x $y $sa "x" 
		incr y 22
		$self drawStack $zinc $norm $x $y $sa "a" 
		incr y 22
		$self drawStack $zinc $norm $x $y $sa "b" 
		incr y 22
		$self drawStack $zinc $norm $x $y $sa "y" 

		incr y 28
		$self drawStack $zinc $norm $x $y $sa "unx"
		incr y 22
		$self drawStack $zinc $norm $x $y $sa "una"
		incr y 22
		$self drawStack $zinc $norm $x $y $sa "unb"
		incr y 22
		$self drawStack $zinc $norm $x $y $sa "uny"
	} else {
		$self drawStack $zinc $norm $x $y $sa "x" 
		incr y 22
		$self drawStack $zinc $norm $x $y $sa "unx"

		incr y 25
		$self drawStack $zinc $norm $x $y $sa "a" 
		incr y 22
		$self drawStack $zinc $norm $x $y $sa "una"

		incr y 25
		$self drawStack $zinc $norm $x $y $sa "b" 
		incr y 22
		$self drawStack $zinc $norm $x $y $sa "unb"

		incr y 25
		$self drawStack $zinc $norm $x $y $sa "y" 
		incr y 22
		$self drawStack $zinc $norm $x $y $sa "uny"
	}

	$zinc bind stackcell <Enter> [list $self _raiseStackCell $zinc]
	$zinc bind stackcell <Leave> [list $self _lowerStackCell $zinc]
}

# Draw a cell
#
WaveEditor method drawCell {zinc glrender g pri lw lc fc cx cy cw ch tags} {
	set wall [$zinc add rectangle $g [list $cx $cy [+ $cx $cw] [+ $cy $ch]] \
		-priority $pri -visible 1 -linewidth $lw -linecolor $lc \
		-filled 1 -fillcolor $fc \
		-tags [concat cellwall $tags]]

	set box [Zinc inside $zinc $wall]

	# If we're rendering (OpenGL) we create a transparent front layer for
	# use in descend mode.  If not, it's a frame.  Either way, it's also
	# the clipping rectangle.
	#
	set cg [$zinc add group $g -priority $pri -tags [concat $tags coregroup]]

	if {$glrender} {
		set front [$zinc add rectangle $cg $box -priority 150 -filled 1 \
			-fillcolor [Colors get newwinLo 1] \
			-linewidth 0 -linecolor [Colors get selectionFrame] -visible 0 -tags [concat $tags front]]
	} else {
		set front [$zinc add rectangle $cg $box -priority 150 -filled 0 \
			-linewidth [Spans get cellHiliteWidth] -linecolor [Colors get newwinLo] \
			-visible 0 -tags [concat $tags front]]
	}

	$zinc itemconfigure $cg -clip $front

	set cym [- [+ $cy [/ $ch 2]] 1]

	$zinc add icon $cg -position [list [+ $cx 1] $cym] -priority 100 \
		-image [Thyrd getImage empty] -anchor w -tags [concat $tags icon]

	$zinc add text $cg -position [list [+ $cx 22] $cym] -priority 100 \
		-text "" -font cell -anchor w -tags [concat $tags text]
}

# Draw one of the stacks, possibly with an arrow in front
# (if it's not an unstack).  $which is the lowercase version
# of the stack name.
#
WaveEditor method drawStack {zinc g x y arrowImage which} {
	set xi [+ $x 20]
	set yo [+ $y 0]		;# vertical offset for arrow

	if {$which in {a b y x}} {
		$zinc add icon $g -position [list $x $yo] -image $arrowImage \
			-visible 0 -anchor nw -tags [list arrow $which]
	}

	$zinc add icon $g -position [list $xi $y] -anchor nw \
		-image [Thyrd getImage glyph-${which}-sm] 

	set gl [$self slot glrender]
	set lc [Colors get stackCellWall]
	set fc [Colors get stackCellBG]

	set cw [Spans get defaultCellW]
	set ch [Spans get defaultCellH]	

	set x [+ $xi 25]

	set n [$self getParam maxstack]
	for {set i 0} {$i < $n} {incr i} {
		$self drawCell $zinc $gl $g [+ $i 10] 1 $lc $fc $x $y $cw $ch \
			[list i=$i stack=$which stackcell]

		incr x 22
	}
}

# Raise and highlight a stack cell
#
WaveEditor method _raiseStackCell {zinc} {
	set it [$zinc find withtag current]

	set i [Zinc itemParam $zinc $it i]
	set s [Zinc itemParam $zinc $it stack]
	set cc [Zinc itemParam $zinc $it cell]

	if {[Object existsAs $cc Cell]} {
		$self slot statusIndicator [$cc path]
	} elseif {[Object existsAs $cc Op]} {
		$self slot statusIndicator "[$cc slot caption] (continuation, $cc)"
	} else {
		$self slot statusIndicator "missing cell ($cc)"
	}

	$zinc itemconfigure cellwall&&stackcell&&stack=$s&&i=$i -priority 1000 \
		-linewidth [Spans get cellWallWidth] -linecolor [Colors get selectionFrame]

	$zinc itemconfigure front&&stackcell&&stack=$s&&i=$i \
		-visible 1

	$zinc itemconfigure coregroup&&stackcell&&stack=$s&&i=$i -priority 1000
}

# Lower and unhighlight a stack cell
#
WaveEditor method _lowerStackCell {zinc} {
	set it [$zinc find withtag current]

	set s [Zinc itemParam $zinc $it stack]
	set i [Zinc itemParam $zinc $it i]

	$self slot statusIndicator ""

	$zinc itemconfigure cellwall&&stackcell&&stack=$s&&i=$i -priority [+ $i 10] \
		-linewidth 1  -linecolor [Colors get stackCellWall]

	$zinc itemconfigure front&&stackcell&&stack=$s&&i=$i -visible 0 

	$zinc itemconfigure coregroup&&stackcell&&stack=$s&&i=$i -priority [+ $i 10]
}

# Unobserve the last observed wave
#
WaveEditor method _unobserve {} {
	set w [$self slot wave]

	if {[Object exists $w]} {
		$w deleteObserver step $self
		$w deleteObserver destruct $self

		$w slot stepping 0
	}

	Object safe [$self slot _ctrlBar] setFwdButtons 0
	Object safe [$self slot _ctrlBar] setBackButton 0
	$self wm title "WaveEditor"
}

# Observe the given wave
#
WaveEditor method _observe {w} {
	$self _unobserve
	$self slot wave $w

	if {$w ne ""} {
		$w slot stepping 1
		$w addObserver step $self waveStep
		$w addObserver destruct $self waveDestruct
		$self wm title "$w"
	} else {
		$self wm title "WaveEditor"
	} 
}

# Unrender the current wave
#
WaveEditor method unrender {} {
	poetvar $self zinc

	foreach x {start anchor next prev} {
		$zinc itemconfigure ${x}&&icon -visible 0
		$zinc itemconfigure ${x}&&text -visible 0
		$zinc itemconfigure ${x}&&path -text ""
	}

	$zinc itemconfigure insubIcon -visible 0
	$zinc itemconfigure subDepth -text ""
	$zinc itemconfigure bidiIcon -visible 0
	$zinc itemconfigure watchIcon -visible 0
	$zinc itemconfigure watch -text "" 

	$zinc itemconfigure stateIcon -visible 0
	$zinc itemconfigure state -text "" 

	$zinc itemconfigure errorIndicator -visible 0
	$zinc itemconfigure error -visible 0
	$zinc itemconfigure errorBox -visible 0

	$zinc itemconfigure arrow&&a -visible 0
	$zinc itemconfigure arrow&&b -visible 0
	$zinc itemconfigure arrow&&y -visible 0
	$zinc itemconfigure arrow&&x -visible 0

	$zinc itemconfigure stackcell -visible 0
}

# Refresh the display
#
WaveEditor method refresh {} {
	$self render
}

# Render the wave
#
WaveEditor method render {} {
	poetvar $self zinc

	$self unrender
	set cb [$self slot _ctrlBar]

	set w [$self getParam wave]
	if {$w eq ""} {
		if {$cb ne ""} {
			$cb setFwdButtons 0
			$cb setBackButton 0
		}
		return
	}

	set state [$w slot state]
	set bidi [$w isBiDi]
	set subDepth [$w subDepth]

	# we don't change the subroutine icon currently, just change number
	#$zinc itemconfigure insubIcon -image [Thyrd getImage [? {$subDepth > 0} insub nosub]] -visible 1
	$zinc itemconfigure insubIcon -image [Thyrd getImage nosub] -visible 1
	$zinc itemconfigure subDepth -text $subDepth
	$zinc itemconfigure bidiIcon -image [Thyrd getImage [? $bidi bidi notbidi]] -visible 1
	$zinc itemconfigure watchIcon -visible 1
	$zinc itemconfigure watch -text [Observer countObserved $w Cell]

	$zinc itemconfigure stateIcon -image [Thyrd getImage wi-$state] -visible 1
	$zinc itemconfigure state -text $state

	if {$cb ne ""} {
		$cb setFwdButtons [expr {$state eq "break" || ($state ni {suspended end} && [$w slotLength X] > 0)}]
		$cb setBackButton [expr {[$w slotLength unX] > 0}]
	}

	switch $state {
		flowing -
		captive -
		end	{
			set x ""
			set xi ""
			set c [Colors get wStatusText]
		}
		confused -
		error	{
			set x [$w slot error]
			set xi "[string range $x 0 10]..." 
			set c [Colors get wErrorText]
		}
		break	{
			set x ""
			set xi ""
			set c [Colors get wStatusText]
		}
	}

	$zinc itemconfigure errorIndicator -text $xi -color $c -visible 1
	$zinc itemconfigure error -text [::Poet::parseError $x] -color $c
	set bbox [$zinc bbox error]
	if {$bbox ne ""} {
		$zinc coords errorBox [Zinc offsetbox 3 $bbox]
	}

	set ws [$w slot start]
	if {$ws eq ""} {
		set wsp ""
	} else {
		set wsp "[$ws path]"
	}

	set wr [$w slot anchor]
	if {$wr eq ""} {
		set wrp ""
	} else {
		set wrp "[$wr path]"
	}

	$zinc itemconfigure start&&path -text $wsp
	$zinc itemconfigure anchor&&path -text $wrp

	set wn [$w slot next]
	if {$wn eq ""} {
		set wnp ""
	} else {
		set wnp [join [$wn as CMRoute asList] "  "]
	}

	set wp [$w slot prev]
	if {$wp eq ""} {
		set wpp ""
	} else {
		set wpp [join [$wp as CMRoute asList] "  "]
	}

	$zinc itemconfigure next&&route -text $wnp
	$zinc itemconfigure prev&&route -text $wpp

	$zinc itemconfigure arrow&&[string tolower [$w slot stack]] -visible 1

	# draw cells
	foreach {c tag} {ws start wr anchor wn next wp prev} {
		Zinc rmCellTag $zinc $tag

		if {[set $c] eq ""} {
			$zinc itemconfigure ${tag}&&icon -visible 0
			$zinc itemconfigure ${tag}&&text -visible 0
		} else {
			$zinc itemconfigure ${tag}&&icon -image [[set $c] getGlyph] -visible 1
			$zinc itemconfigure ${tag}&&text -text [[set $c] getText] -visible 1

			$zinc addtag cell=[set $c] withtag ${tag}&&icon
			$zinc addtag cell=[set $c] withtag ${tag}&&text
		}
	}

	# draw stacks

	set ms [$self getParam maxstack]

	Zinc rmCellTag $zinc stackcell
	$zinc itemconfigure stackcell -catchevent 0

	foreach {stack s} {A a B b X x Y y unA una unB unb unX unx unY uny} {
		set sl [$w slotLength $stack]
		if {$sl > 0} {
			if {$sl > $ms} {set sl $ms}

			for {set i 0} {$i < $sl} {incr i} {
				set c [$w slotIndex $stack [- $sl $i 1]]

				$zinc addtag cell=$c withtag stack=$s&&i=$i
				$zinc itemconfigure stack=$s&&i=$i -catchevent 1

				$zinc itemconfigure stack=$s&&i=$i&&cellwall -visible 1
				$zinc itemconfigure stack=$s&&i=$i&&coregroup -visible 1
				if {$c eq ""} {
					$zinc itemconfigure stack=$s&&i=$i&&icon -visible 0
					$zinc itemconfigure stack=$s&&i=$i&&text -visible 0
				} elseif {[Object existsAs $c Cell]} {
					$zinc itemconfigure stack=$s&&i=$i&&icon -visible 1 -image [$c getGlyph]
					$zinc itemconfigure stack=$s&&i=$i&&text -visible 1 -text [$c getText]
				} elseif {[Object existsAs $c Op]} {
					$zinc itemconfigure stack=$s&&i=$i&&icon -visible 1 -image [$c getGlyph]
					$zinc itemconfigure stack=$s&&i=$i&&text -visible 1 -text "(continuation)"
				} else {
					$zinc itemconfigure stack=$s&&i=$i&&icon -visible 1 -image [Thyrd getImage type-unknown]
					$zinc itemconfigure stack=$s&&i=$i&&text -visible 1 -text $c
				}
			}
		}
	}
}

# Destroy a WaveEditor, destroying any component objects
#
WaveEditor method destruct {} {
	$self _unobserve
	Observer unobserveAll $self 
	$self as [WaveEditor parent] destruct
}

# When done resizing, make sure to render
#
WaveEditor method resizeEnd {w rx ry} {
	$self as MainFrameTool resizeEnd $w $rx $ry
	# $self render DEFERRED
}

# An entry on the wave table has been selected
# 
WaveEditor method waveTableHit {} {
	set tl [$self slot _table].tablelist

	set i [$tl curselection]

	lassign [$self slotIndex _waves $i] w c s
	$self setParam wave $w
}

# Called when the displayed wave steps
#
WaveEditor method waveStep {target event} {
	$self render
}

# Called when _any_ wave changes state (updates
# the table list of waves)
#
WaveEditor method waveState {target event} {
	$self slot _waves [theSpace listWaves]
}

# Called when the displayed wave destructs
#
WaveEditor method waveDestruct {target event} {
	$self unrender
	$self _unobserve
	$self setParam wave ""
}

# Invoked when the back button is pressed
#
WaveEditor method stepBack {} {
	set w [$self getParam wave]
	if {$w eq ""} return

	after idle [list after 0 $w stepBack]
}

# Invoked when the substep button is pressed
#
WaveEditor method stepSubstep {} {
	set w [$self getParam wave]
	if {$w eq ""} return

	after idle [list after 0 $w step]
}

# Invoked when the forward button is pressed.
# If we're at a breakpoint, we resume flowing.
#
WaveEditor method stepForward {} {
	set w [$self getParam wave]
	if {$w eq ""} return

	$w slot stepping 1
	
	if {[$w slot state] eq "break"} {
		$w slot state flowing
	}

	after idle [list after 0 $w step]
}

# Invoked when the finish button is pressed
#
WaveEditor method finishUp {} {
	set w [$self getParam wave]
	if {$w eq ""} return

	$w slot stepping 0

	if {[$w slot state] eq "break"} {
		$w slot state flowing
	}

	if {[$w slot state] eq "flowing"} {
		after idle [list after 0 $w flow]
	}
}

# Called when something is dropped on the table. We highlight
# those waves that contain the dropped cell, as either 
# a start or anchor.
#
# When we compare to the start, we go up one level on start
# and see if the dropped pathis below there somewhere.
#
WaveEditor method dropOnTable {tbl source rx ry op dtype data} {
	set path ""

	switch $dtype {
		TEXT {
			set path $data
		}
		SIGN {
			lassign $data what src
			switch $what {
				FORCE-Cell {
					catch {set path [$src path]}
				}
				Cell {
					catch {set path [$src path]}
				}
				Path {
					set path $src
				}
			}
		}
	}

	if {$path eq ""} {return 0}

	set pp [Path newVolatile $path]
	if {[catch {$pp resolve} pc] || $pc eq ""} {
		$pp destruct
		return 0
	}

	set op [Path newVolatile]

	set tbl [$self slot _table].tablelist

	set rows [$tbl size]
	for {set row 0} {$row < $rows} {incr row} {
		set s [$tbl cellcget $row,2 -text]
		set r [$tbl cellcget $row,3 -text]

		set hilite 0
		set c ""

		if {$s ne ""} {
			$op set $s
			catch {$op resolve} c
			if {[Object exists $c]} {
				set c [$c slot container]
				set hilite [$pc isUnder $c]
			}
		}

		if {!$hilite && $r ne ""} {
			$op set $r
			catch {$op resolve} c
			if {$c eq $pc} {
				set hilite 1
			}
		}
			
		if {$hilite} {
			$tbl rowconfigure $row -foreground red
		} else {
			$tbl rowconfigure $row -foreground black
		}
	}

	$pp destruct
	$op destruct

	return 1
}

# Called when dragging is initiated on the canvas
#
WaveEditor method dragInit {zinc rx ry topLvl} {
	set x [- $rx [winfo rootx $zinc]]
	set y [- $ry [winfo rooty $zinc]]

	set c [$self getCellUnder $zinc $x $y]
	if {$c eq ""} {return ""}

	set im [$c getGlyph]
	Window dragImage $topLvl $im

	return [list SIGN {copy} [list Cell $c]]
}

# Get the cell under the given x,y coordinates. It's possible
# that no cell will be found.
#
WaveEditor method getCellUnder {zinc x y} {
	set w [$self getParam wave]
	if {$w eq ""} {return ""}
	set items [$zinc find overlapping $x $y $x $y]

	foreach item $items {
		if {[$zinc hastag $item start]} {
			return [$w slot start]
		} elseif {[$zinc hastag $item anchor]} {
			return [$w slot anchor]
		} else {
			set c [Zinc itemParam $zinc $item cell]
			if {$c ne ""} {return $c}
		}
	}

	return ""
}

# Clear the highlighting on the wave table
#
WaveEditor method unhilite {} {
	set tbl [$self slot _table].tablelist

	set rows [$tbl size]
	for {set row 0} {$row < $rows} {incr row} {
		$tbl rowconfigure $row -foreground black
	}
}

# Reset the currently displayed wave
# DEFERRED require confirmation first?
#
WaveEditor method resetWave {} {
	Object safe [$self getParam wave] reset
	$self render
}

# Clear the selection on the wave table
#
WaveEditor method clearSelection {} {
	$self setParam wave ""
	$self unhilite
	$self unrender
}

# Select the given wave (already set as wave param).
# Return 1 if we did it, 0 otherwise.
#
WaveEditor method _select {wave} {
	set tbl [$self slot _table].tablelist

	if {$wave eq ""} {
		$tbl selection clear 0 end
		return 0
	}

	set rows [$tbl size]
	for {set row 0} {$row < $rows} {incr row} {
		set w [$tbl cellcget $row,0 -text]
		if {$w eq $wave} {
			$tbl selection set $row
			return 1
		}
	}

	return 0
}
