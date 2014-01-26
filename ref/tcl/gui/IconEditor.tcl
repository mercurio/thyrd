# IconEditor - an editor for icons
#
# PJM 2007-09-09	Begun
#


Window construct IconEditor
IconEditor mixin ParamListOwner

IconEditor slot isModified 0			
IconEditor type isModified <boolean>

# Options that must be specified at creation time
IconEditor slot extraOptions {paramList}

# The list cell that contains our parameters
#
IconEditor slot paramList {}

# The parameters and their defaults.  The modelobj is a
# persistent object that stores our state, it's not meant
# to be accessible via ThyrdSpace.
#
IconEditor slot _defaultParams {
	-font {Webdings <font>}
	-size {10 "<integer 4 400"}
	-char {33 "<integer> 1 256"}
	-color {black <color>}
	-modelobj "" 
	-in {0 <integer>}
	-out {0 <integer>}
	-fieldcolor {white <color>}
}

# The number of layers, not meant to be reconfigured
#
IconEditor slot nLayers	5
IconEditor type nLayers "<integer> 1"

# Icon (whole image) and glyph size params
#
IconEditor slot iconSmH [Spans get defaultCellH]
IconEditor slot iconSmW [Spans get defaultCellW]
IconEditor slot iconLgH [Spans get defaultCellW]
IconEditor slot iconLgW [Spans get defaultCellW]

IconEditor slot glyphSmH [- [Spans get defaultCellH] 3]
IconEditor slot glyphSmW [- [Spans get defaultCellH] 3]
IconEditor slot glyphLgH [- [Spans get defaultCellW] 3]
IconEditor slot glyphLgW [- [Spans get defaultCellW] 3]

IconEditor slot nGlyphs	5


# Build the primary for a IconEditor
# We pick up _mainframe from MainFrameTool
#
IconEditor method buildPrimary {} {
	$self destroyPrimary

	$self getAllParams
	set nL [$self slot nLayers]

	# Create or recall the model object
	set mo [$self getParam modelobj]
	if {$mo eq ""} {
		set mo [Object construct ie@]
		$mo mixin Thing
		$self setParam modelobj $mo

		$mo slot selLayer 1

		for {set i 1} {$i <= $nL} {incr i} {
			$mo slot visLayer$i 1
		}

		$mo slot prefix "op-"
		$mo slot caption "caption"
	} else {
		$mo
	}

	$self slot mo $mo

    $self slot menu [list "&Icon" all object 1]
    $self slotAppend menu [format {
            {command "&Refresh" {} "Refresh" {} -command "%s refresh"}
            {command "&Reset" {} "Reset" {} -command "%s setParam char 33"}
            {command "&Choose Font" {} "Select a font" {} -command "%s selectFont"}
			{command "&Import image" {} "Import an image" {} -command "%s import"}
            {command "&Close" {} "Close this window" {} -command "%s destruct"}
        } $self $self $self $self $self]

	set prim [$self as MainFrameTool buildPrimary]
	set mf [$self getFrame]
	set pl [$self slot paramList]
	assert {$pl ne ""}

	$self wm withdraw

	set tb [$self addToolBarSlot _showToolbar 1]

	$self slot glrender 1

	# Compute some sizes
	set zw [* [+ [$self slot nGlyphs] 1] [$self slot iconLgW]]
	set zh [int [* [$self slot iconLgH] 2.1]]

	set zinc [$self slot zinc [zinc ${mf}.z -render [$self slot glrender] -borderwidth 0 -highlightthickness 0 \
		-lightangle 140 -backcolor [Colors get zBG] \
		-font zfont -width $zw -height $zh \
		-tile [Thyrd getImage bg-iconed]]]
		
	grid $zinc -row 0 -column 0 -sticky nw
	grid rowconfigure $mf 0 -weight 0
	grid columnconfigure $mf 0 -weight 0

	set lf [Ttk_Frame construct * $mf -layout {grid -row 0 -column 1 -sticky news}]
	set row 0

	Ttk_Label construct * $lf -text Layers -layout [list grid -row $row -column 0 -columnspan 3]
	incr row

	for {set i $nL} {$i > 0} {incr i -1} {
		Ttk_Checkbutton construct * $lf -layout [list grid -row $row -column 0] \
			-takefocus 0 \
			-variable [$mo slotVar visLayer$i] -command "$self deltaVis"
		Ttk_Label construct * $lf -text $i -layout [list grid -row $row -column 1]
		Ttk_Radiobutton construct * $lf -layout [list grid -row $row -column 2] \
			-takefocus 0 \
			-variable [$mo slotVar selLayer] -value $i -command "$self deltaLayer"

		incr row
	}

	set bf [Ttk_Frame construct * $mf -layout {grid -row 1 -column 0 -columnspan 2 -sticky wns}]

	set nj [- [$self slot nGlyphs] 1]
	Ttk_Button construct * $bf -text "<<" -command "$self jump -$nj" -layout {grid -row 0 -column 0}
	Ttk_Button construct * $bf -text "<" -command "$self jump -1" -layout {grid -row 0 -column 1}
	$self slot charLabel [Ttk_Label construct * $bf -text [$self getParam char]  -justify center -width 6 -layout {grid -row 0 -column 2}]
	Ttk_Button construct * $bf -text ">" -command "$self jump 1" -layout {grid -row 0 -column 3}
	Ttk_Button construct * $bf -text ">>" -command "$self jump $nj" -layout {grid -row 0 -column 4}

	$self slot fontBtn [Ttk_Button construct * $bf -text "Font" -command "$self selectFont" \
		-layout {grid -row 0 -column 5}]
	$self slot sizeScl [Ttk_Scale construct * $bf -orient horizontal -from 6 -to 144 -resolution 1 -layout {grid -row 0 -column 6} \
		-command "$self setSize" -value [$self getParam size]]
	$self slot colorBox [ColorMenuBox construct * $bf -layout {grid -row 0 -column 7} -notify "$self newColor color" \
		-value [$self getParam color]]

	Ttk_Entry construct * $bf -textvariable [$mo slotVar prefix] \
		-layout {grid -row 1 -column 0 -columnspan 3}
	Ttk_Button construct * $bf -text "Generate" -command "$self generate" -layout {grid -row 1 -column 3}
	Ttk_Entry construct * $bf -textvariable [$mo slotVar caption] -layout {grid -row 1 -column 4 -columnspan 3} \
		-validatecommand "$self setCaption %P" -validate all

	Ttk_Label construct * $bf -text "In: " -layout {grid -row 2 -column 0 -sticky e}
	Tk_SpinBox construct * $bf -value [$self getParam in] -from 0 -to 11 -command "$self setParam in %s" \
		-layout {grid -row 2 -column 1 -sticky w} -width 3
	Ttk_Label construct * $bf -text "Out: " -layout {grid -row 2 -column 2 -sticky e}
	Tk_SpinBox construct * $bf -value [$self getParam out] -from 0 -to 11 -command "$self setParam out %s" \
		-layout {grid -row 2 -column 3 -sticky w} -width 3

	Ttk_Label construct * $bf -text "Field: " -layout {grid -row 2 -column 4 -sticky e}
	$self slot fieldcolorBox [ColorMenuBox construct * $bf -layout {grid -row 2 -column 5} \
		-notify "$self newColor fieldcolor" \
		-value [$self getParam fieldcolor]]

	# The top-level group, for viewing transformations
	set view [$self slot view [$zinc add group 1 -priority 100]]

	# 1 overlay plane, nLayers planes used for layering, norm and sub
	set overlay [$self slot overlay [$zinc add group $view -priority 500]]

	set inc [expr {round(200.0/$nL)}]

	for {set i 0} {$i < $nL} {incr i} {
		set p [expr {100 + $i * $inc}]
		$self slot layer[+ $i 1] [$zinc add group $view -priority $p]
	}

	set norm [$self slot norm [$zinc add group $view -priority 75]]
	set sub [$self slot sub [$zinc add group $view -priority 50]]

	$self slot lensTexture [Thyrd getImage paper-grey]

	$self watchParams [$self slot paramList]

	#$self setBindings

	#$self addResizer

	$self render

	$self wm title "IconEditor $self"
	$self wm deiconify

    update idletasks

	return $prim
}

# Set the caption
#
IconEditor method setCaption {str} {
	poetvar $self zinc 

	$zinc itemconfigure largeCaption -text $str
	$zinc itemconfigure smallCaption -text $str

	return 1
}


# The visible layers have just changed, set the
# visibilities
#
IconEditor method deltaVis {} {
	poetvar $self zinc mo 

	for {set i [$self slot nLayers]} {$i > 0} {incr i -1} {
		$zinc itemconfigure [$self slot layer$i] -visible [$mo slot visLayer$i]
	}
}

# Change in the selected layer
#
IconEditor method deltaLayer {} {
}

# A new color has been chosen, set the param,
# but eliminate any color names first
#
IconEditor method newColor {which c} {
	$self setParam $which [::tk::Darken $c 100]
}

# Set the size, it might be real
#
IconEditor method setSize {s} {
	$self setParam size [int $s]
}

# Called to set up watching of the cells in the paramList.
# We don't watch the modelobj, no one should be changing it.
#
IconEditor method watchParams {pl} {
	$pl watchSub $self paramDelta font
	$pl watchSub $self paramDelta size
	$pl watchSub $self paramDelta color
	$pl watchSub $self charDelta char
	$pl watchSub $self arityDelta in
	$pl watchSub $self arityDelta out
	$pl watchSub $self fieldColorDelta fieldcolor
}

#  Observer handler method.  May be called without args.
#
IconEditor method paramDelta {{target ""} {event ""}} {
	poetvar $self zinc

	set s [$zinc find withtag selected]
	set gb [$zinc find withtag glyphBack]


	set color [$self getParam color] 
	set size [$self getParam size] 

	if {$s == $gb} {
		set c [$self getParam char]
		for {set i 0} {$i < [$self slot nGlyphs]} {incr i} {
			$zinc itemconfigure glyph$i \
				-font [list [$self getParam font] $size] \
				-color $color \
				-text [format %c [+ $c $i]]
		}

		[$self slot charLabel] slot text $c
	} else {
		$zinc itemconfigure $s \
			-font [list [$self getParam font] $size] \
			-color $color
	}

	[$self slot colorBox] slot value $color
	[$self slot sizeScl] slot value $size
}

#  The character value has changed, always update the glyphs
#
IconEditor method charDelta {{target ""} {event ""}} {
	poetvar $self zinc

	set c [$self getParam char]
	for {set i 0} {$i < [$self slot nGlyphs]} {incr i} {
		$zinc itemconfigure glyph$i  -text [format %c [+ $c $i]]
	}

	[$self slot charLabel] slot text $c
}

#  One of the arity values have changed
#
IconEditor method arityDelta {{target ""} {event ""}} {
	poetvar $self zinc

	set in [$self getParam in]
	set out [$self getParam out]

	if {$in == 0} {
		$zinc itemconfigure in -visible 0
	} elseif {$in == 11} {
		$zinc itemconfigure in -visible 1 -text [format %c 239]
	} else {
		$zinc itemconfigure in -visible 1 -text [format %c [+ 116 $in]]
	}

	if {$out == 0} {
		$zinc itemconfigure out -visible 0
	} elseif {$out == 11} {
		$zinc itemconfigure out -visible 1 -text [format %c 239]
	} else {
		$zinc itemconfigure out -visible 1 -text [format %c [+ 116 $out]]
	}

}

# The field color has changed
#
IconEditor method fieldColorDelta {{target ""} {event ""}} {
	poetvar $self zinc

	set fc [$self getParam fieldcolor]
	$zinc itemconfigure fields -fillcolor $fc
}

# Select the current font and display it
#
IconEditor method selectFont {} {
	set of [$self getParam font]
	set nf [lindex [SelectFont .fontdlg -parent [$self primary] -font [list $of [$self getParam size]]] 0]

	if {$nf ne "" && $nf ne $of} {
		$self setParam font $nf
	}
}

# Get all the params from our paramList into local slots
#
IconEditor method getAllParams {} {
	$self slot font [$self getParam font]
	$self slot size [$self getParam size]
	$self slot char [$self getParam char]
	$self slot color [$self getParam color]
}

# Go to the next or previous character, or further
#
IconEditor method jump {n} {
	set i [$self getParam char]
	incr i $n
	set i [min [max 0 $i] 65535]

	$self setParam char $i
}

# Render the scene as described by the model object
#
IconEditor method render {} {
	poetvar $self zinc norm
	set mo [$self getParam modelobj]

	$self drawBlank $zinc

	$self paramDelta 
	$self arityDelta

	$self setBindings
}

# Draw the blank display for the current size of the 
# canvas
#
IconEditor method drawBlank {zinc} {
	poetvar $self overlay norm sub mo
	poetvar IconEditor iconSmH iconSmW iconLgH iconLgW glyphSmH glyphSmW glyphLgH glyphLgW nGlyphs

	set w [$zinc cget -width]
	set h [$zinc cget -height]

	$zinc remove blank
	set tags "blank"

	# Draw the large icon box
	array set border {
		-itemtype rectangle
	}

	array set borderParams {
		-filled 0
		-linewidth 1.5
	}

	set bw 3	;# 2 * linewidth
	set x0 [- $w $bw $bw $iconLgW -1]
	set y0 $bw
	set x1 [- $w $bw]
	set y1 [+ $bw $iconLgH $bw -1]

	set borderParams(-linecolor) [Colors get zIconEdBorder]
	set border(-coords) [list [list $x0 $y0] [list $x1 $y1]]

	set border(-params) [array get borderParams]
	zincGraphics::BuildZincItem $zinc $overlay [array get border] largeFrame --

	array set back {
		-itemtype rectangle
	}

	array set backParams {
		-filled 1
		-linewidth 0
	}

	set backParams(-fillcolor) [Colors get zIconEdBG] 
	set back(-coords) [list [list $x0 $y0] [list $x1 $y1]]
	set back(-params) [array get backParams]

	zincGraphics::BuildZincItem $zinc $sub [array get back] largeBack --
	
	# Position caption and arity indicators
	set xt [expr {($x1 + $x0)/2}]
	set yt [- $y1 10]
	$self makeItem [$zinc add text $overlay -tags largeCaption -visible 1 -position [list $xt $yt] -anchor c \
		-font {Tahoma 10} -text [$mo slot caption]]

	$self makeItem [$zinc add text $overlay -tags in -visible 1 -position [list $x0 $y0] -anchor nw \
		-font {{Wingdings 2} 14} -color [Colors get zIconEdIn] -text "u"]

	$self makeItem [$zinc add text $overlay -tags out -visible 1 -position [list [- $x1 1] $y0] -anchor ne \
		-font {{Wingdings 2} 14} -color [Colors get zIconEdOut] -text "u"]

	# Draw the rectangular field, white by default so it's not visible
	#
	foreach {xf0 yf0 xf1 yf1} [Zinc offsetbox -[Spans get iconLgBorder] $x0 $y0 $x1 $y1] break
	set back(-coords) [list [list $xf0 $yf0] [list $xf1 $yf1]]

	set backParams(-fillcolor) [$self getParam fieldcolor]
	set back(-params) [array get backParams]

	zincGraphics::BuildZincItem $zinc $sub [array get back] fields --

	# 
	set y0 [- $h $bw $iconSmH $bw -1]
	set y1 [- $h $bw]

	set border(-coords) [list [list $x0 $y0] [list $x1 $y1]]
	zincGraphics::BuildZincItem $zinc $overlay [array get border] smallFrame --

	set backParams(-fillcolor) [Colors get zIconEdBG] 
	set back(-coords) [list [list $x0 $y0] [list $x1 $y1]]
	set back(-params) [array get backParams]

	zincGraphics::BuildZincItem $zinc $sub [array get back] smallBack --

	set yt [expr {($y1 + $y0)/2}]
	$self makeItem [$zinc add text $overlay -tags smallCaption -visible 1 -position [list $xt $yt] -anchor c \
		-font {Tahoma 8} -text [$mo slot caption]]

	# The field for the small icon
	set back(-coords) [list [list $x0 $y0] [list [+ $x0 [- $y1 $y0]] $y1]]

	set backParams(-fillcolor) [$self getParam fieldcolor]
	set back(-params) [array get backParams]

	zincGraphics::BuildZincItem $zinc $sub [array get back] fields --


	# The glyph backdrop

	set x1 [- $x0 $bw]
	set x0 [+ 0 $bw]
	set y0 [/ $h 2]
	set y1 [- $h $bw]

	$zinc add rectangle $sub [list $x0 $y0 $x1 $y1] -fillcolor [Colors get zIconEdBG2] \
		-tags glyphBack -filled 1

	# Compute dot locations (glyph centers)
	set w [- $x1 $x0]
	set u [/ $w $nGlyphs 2.0]
	set u2 [* $u 2]
	set yc [/ [+ $y0 $y1] 2]

	set i 0
	for {set x [+ $x0 $u]} {$x < $x1} {set x [+ $x $u2]} {
		$zinc add text $norm -tags glyph$i -visible 1 -position [list $x $yc] -anchor c
		incr i
	}

	# Make selection halo, around glyphBack
	$zinc add rectangle $overlay [$zinc bbox glyphBack] -tags "halo" -visible 1 \
		-linewidth 1 -linecolor [Colors get zIconEdBorder2] -filled 0

	$zinc addtag selected withtag glyphBack
}

# Set the bindings
#
IconEditor method setBindings {} {
	poetvar $self zinc
	set w [$self primary]

	#$self bind <Configure> "$self reconfigure"

	bind $zinc <Up> "$self nudge up"
	bind $zinc <Down> "$self nudge down"
	bind $zinc <Left> "$self nudge left"
	bind $zinc <Right> "$self nudge right"

	focus $zinc

	for {set i 0} {$i < [$self slot nGlyphs]} {incr i} {
		$zinc bind glyph$i <ButtonPress-1> "$self dragGlyph %x %y"
	}		

	$zinc bind glyphBack <ButtonPress-1> "$self select glyphBack"
}

# Nudge an item on pixel in the given direction
#
IconEditor method nudge {dir} {
	poetvar $self zinc

	set s [$zinc find withtag selected]
	set b [$zinc find withtag halo]
	set gb [$zinc find withtag glyphBack]

	if {$s == $gb} return

	switch $dir {
		down	{
			$zinc translate $s 0 1
			$zinc translate $b 0 1
		}
		up {
			$zinc translate $s 0 -1
			$zinc translate $b 0 -1
		}
		left	{
			$zinc translate $s -1 0
			$zinc translate $b -1 0
		}
		right	{
			$zinc translate $s 1 0 
			$zinc translate $b 1 0 
		}
	}
}

# Select an item or the glyphs box, set the UI
#
IconEditor method select {c} {
	poetvar $self zinc

	set b [$zinc find withtag halo]

	$zinc dtag selected selected
	$zinc addtag selected withtag $c
		
	$zinc treset $b
	$zinc coords $b [$zinc bbox $c]

	if {$c eq "glyphBack"} {set c glyph0} 

	switch [$zinc type $c] {
		text {
			foreach {f s} [$zinc itemcget $c -font] break
			set color [$zinc itemcget $c -color]

			$self setParam font $f
			$self setParam size $s
			$self setParam color $color
		}
		default {
		}
	}

	focus $zinc
}

# Begin a drag and drop op from a glyph
#
IconEditor method dragGlyph {x y} {
	poetvar $self zinc

	set c [$zinc find withtag current]
	foreach {xc yc} [$zinc coords $c] break

	bind $zinc <Motion> "$self predrag %x %y $c [- $xc $x] [- $yc $y]"
	bind $zinc <ButtonRelease-1> "$self dropGlyph"
}


# First movement of the mouse after clicking on a glyph
#
IconEditor method predrag {x y c xo yo} {
	poetvar $self zinc

	set c [$zinc clone $c]
	for {set i 0} {$i < [$self slot nGlyphs]} {incr i} {
		$zinc dtag $c glyph$i
	}		

	$self makeItem $c

	bind $zinc <Motion> "$self drag %x %y $c $xo $yo"
	bind $zinc <ButtonRelease-1> "$self drop $c"

	$self drag $x $y $c $xo $yo
}

# Make the given tag an item
#
IconEditor method makeItem {c} {
	poetvar $self zinc

	$zinc addtag item withtag $c
	$zinc bind $c <ButtonPress-1> "$self dragItem %x %y"
	$zinc bind $c <Shift-ButtonPress-1> "$self dragGlyph %x %y"
}

# Failed drag operation from glyph, just drop it.  Called
# only if no mouse movement occurred.
#
IconEditor method dropGlyph {} {
	poetvar $self zinc

	bind $zinc <Motion> {}
	bind $zinc <ButtonRelease-1> {}

	$self select glyphBack
}

# Begin a select and possibly drag op from an item
#
IconEditor method dragItem {x y} {
	poetvar $self zinc mo

	set c [$zinc find withtag current]
	$self select $c

	foreach {xc yc} [$zinc coords $c] break

	$self slot moved 0
	bind $zinc <Motion> "$self drag %x %y $c [- $xc $x] [- $yc $y]"
	bind $zinc <ButtonRelease-1> "$self drop $c"
}

# Drag something
#
IconEditor method drag {x y c xo yo} {
	poetvar $self zinc

	$zinc coords $c [list [+ $x $xo] [+ $y $yo]]
}

# Drop something, or at least mouse up
#
IconEditor method drop {c} {
	poetvar $self zinc mo

	bind $zinc <Motion> {}
	bind $zinc <ButtonRelease-1> {}

	$self select $c

	if {![$zinc hastag $c largeCaption] && ![$zinc hastag $c smallCaption]} {
		if {$c in [$zinc find overlapping {*}[$zinc bbox largeBack]]} {
			$zinc chggroup $c [$self slot layer[$mo slot selLayer]]
		} elseif {$c in [$zinc find overlapping {*}[$zinc bbox smallBack]]} {
			$zinc chggroup $c [$self slot layer[$mo slot selLayer]]
		} else {
			$zinc chggroup $c [$self slot norm]
		}
	}
}

# Generate the two icons by doing a screendump and editing
# it
#
IconEditor method generate {} {
	poetvar $self zinc mo 

	set lf [file join [Thyrd slot resourceDir] images "[$mo slot prefix]-lg.gif"]
	set sf [file join [Thyrd slot resourceDir] images "[$mo slot prefix]-sm.gif"]

	set op "Create"
	if {[file exists $lf] || [file exists $sf]} {set op "Overwrite"}

	if {[UserMsg yesno "$op $lf and ${sf}?"] ne "yes"} return

	$zinc itemconfigure halo -visible 0
	update
	image create photo win -format window -data $zinc

	image create photo lgpic -format gif -height [$self slot iconLgH] -width [$self slot iconLgW]
	image create photo smpic -format gif -height [$self slot iconSmH] -width [$self slot iconSmW]

	lgpic copy win -from {*}[Zinc integerbox {*}[Zinc offsetbox -1.5 {*}[$zinc bbox largeBack]]]
	smpic copy win -from {*}[Zinc integerbox {*}[Zinc offsetbox -1.5 {*}[$zinc bbox smallBack]]]

	$self transparent lgpic "#ffffff"
	$self transparent smpic "#ffffff"

	lgpic write $lf -format gif
	smpic write $sf -format gif

	image delete win lgpic smpic

	$zinc itemconfigure halo -visible 1
	update
}

# Replace all the instances of a color with transparency
#
# Ref: http://wiki.tcl.tk/11187
#
IconEditor method transparent {image color} {
	set r -1

	foreach row [$image data] {
		incr r
		set c -1
		foreach col $row {
			incr c
			if {$col eq $color} {$image transparency set $c $r 1}
		}
	}
}

# Import an image file 
#
IconEditor method import {} {
	poetvar $self zinc norm

	set fs [$self slot filesel]
	if {$fs eq ""} {
		set fs [Fileselector construct * -title "Import image file" -dir [file join [Thyrd slot resourceDir] images]]
		$self slot filesel $fs
	}

	set f [$fs getOpen]
	if {$f eq ""} return

	set im [image create photo -file $f]
	$self makeItem [$zinc add icon $norm -image $im -position {10 10}]
}
