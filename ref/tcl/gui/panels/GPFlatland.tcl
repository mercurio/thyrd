# GPFlatland -- a Zinc canvas with polygons on it.
#
# PJM 2008-02-22	Begun
# PJM 2008-04-25	Interactive rotation/translation begun

GridPanel construct GPFlatland

# The pick radius for rotating vs. moving
#
GPFlatland slot pickRadius 15
GPFlatland type pickRadius <integer>

# Given the parent widget and the cell, construct
# and return the panel
#
GPFlatland method build {mom tool c {opts {}} {w {}} {h {}}} {
	set kid [$self construct *]
	$kid slot tool $tool

	foreach {o v} $opts {$kid slot [string range $o 1 end] $v}

	$kid slot _gridCell $c

	set top ${mom}.f
	ttk::frame $top
	::ttk::scrollbar ${top}.sx -orient horizontal -command [list ${top}.z xview]
	::ttk::scrollbar ${top}.sy -orient vertical -command [list ${top}.z yview]

	set zinc [$self slot zinc ${top}.z]
	zinc $zinc -render 1 -borderwidth 0 -highlightthickness 0 \
		-lightangle 140 -font zfont -tile [Thyrd getImage bg-flatland]

	grid columnconfigure $top 1 -weight 1
	grid    rowconfigure $top 1 -weight 1

	grid ${top}.z -row 1 -column 1 -sticky nsew
	grid ${top}.sx -row 2 -column 1 -sticky nsew
	grid ${top}.sy -row 1 -column 2 -sticky nsew

	::autoscroll::autoscroll ${top}.sx
	::autoscroll::autoscroll ${top}.sy

	pack $top -fill both -expand yes

	$kid slot zinc $zinc
	$kid glomOnto $top

	$kid fillFlatland $zinc $c
	$kid setBindings $zinc

	return $top
} 

# Fill the flatland from the given cell
#
GPFlatland method fillFlatland {zinc c} {
	lassign [$c size] si sj

	$c addObserver gainSub $self gainedCell
	$c addObserver loseSub $self lostCell

	$self slot nrows [- $sj 1]

	for {set j 1} {$j < $sj} {incr j} {
		$self fillFromRow $zinc $c $j
	}
}

# Unfill the flatland
#
GPFlatland method unfill {zinc} {
	Observer unobserveAll $self Cell
	$zinc remove 1*
}

# Redraw everything
#
GPFlatland method refill {} {
	poetvar $self zinc

	$self unfill $zinc
	$self fillFlatland $zinc [$self slot _gridCell]
}

# Fill the flatland from the given row. If any of the
# cells are missing, we use a default value.
#
GPFlatland method fillFromRow {zinc c j} {
	set plane 1

	foreach {val def type} {
			name "" <string>
			x 50 <real> 
			y 50 <real> 
			sides 3 <integer> 
			radius 50 <real>
			rotation 0 <real>
			color "#888888" <color>
			alpha 50 "<integer> 0 100"
			priority 1 "<integer> 1 100"
	} {
		if {$val eq "name"} {
			set sc [$c subCell 0 $j]
		} else {
			set sc [$c subCell $val $j]
		}

		if {![Object exists $sc]} {
			set $val $def
		} else {
			set nv [$sc peek]
			if {$nv eq ""} {
				Observer ignore $self $sc {$sc set $def $type}
				set $val $def
			} else {
				set $val [$sc peek]
			}

			$sc addObserver write $self delta-$val
		}
	}

	set fill "${color};${alpha}"
	set tj "j=$j"

	set g [$zinc add group $plane -priority $priority -tags [list $tj movable] -atomic 1]

	zincGraphics::BuildZincItem $zinc $g [list \
		-itemtype polygone	\
		-coords {0 0}		\
		-numsides $sides	\
		-radius $radius		\
		-cornerradius 5		\
		-startangle 90		\
		-params [list 		\
			-closed 1		\
			-filled 1		\
			-fillcolor $fill	\
			-linewidth 2	\
			-linecolor [::tk::Darken $color 50] \
			-priority 1 \
			-tags [list poly $tj]	\
		]	\
	] $tj $name

	zincGraphics::BuildZincItem $zinc $g [list \
		-itemtype text	\
		-coords {0 0}	\
		-params [list	\
			-font flatland		\
			-text $name			\
			-anchor center		\
			-alignment center	\
			-color [::tk::Darken $color 50]	\
			-composerotation 0  \
			-priority 5			\
			-tags [list label $tj] \
		]	\
	] $tj $name

	$zinc rotate poly&&$tj $rotation yes
	$zinc translate $g $x $y yes

	return 1
}

# Unobserve everything on the given row
#
GPFlatland method unobserveRow {c j} {
	Object safe [$c subCell 0 $j]	deleteObserver $self delta-name
	Object safe [$c subCell x $j]	deleteObserver $self delta-x
	Object safe [$c subCell y $j]	deleteObserver $self delta-y
	Object safe [$c subCell sides $j]	deleteObserver $self delta-sides
	Object safe [$c subCell radius $j]	deleteObserver $self delta-radius
	Object safe [$c subCell rotation $j]	deleteObserver $self delta-rotation
	Object safe [$c subCell color $j]	deleteObserver $self delta-color
	Object safe [$c subCell alpha $j]	deleteObserver $self delta-alpha
	Object safe [$c subCell priority $j]	deleteObserver $self delta-priority
}

# Establish the bindings for the given canvas
#
GPFlatland method setBindings {zinc} {
	focus $zinc

	bind $zinc <plus> [list $self viewZoom $zinc up]
	bind $zinc <equal> [list $self viewZoom $zinc up]
	bind $zinc <minus> [list $self viewZoom $zinc down]

	bind $zinc <KeyPress-Up> [list $self viewTranslate $zinc up]
	bind $zinc <KeyPress-Down> [list $self viewTranslate $zinc down]
	bind $zinc <KeyPress-Left> [list $self viewTranslate $zinc left]
	bind $zinc <KeyPress-Right> [list $self viewTranslate $zinc right]

#	bind $zinc <greater> [list $self viewRotate $zinc cw]
#	bind $zinc <less> [list $self viewRotate $zinc ccw]

	bind $zinc <Escape> "$zinc treset 1"

	$zinc bind movable <1> [list $self moveRotStart $zinc %x %y]
	$zinc bind movable <B1-Motion> [list $self moveRotMove $zinc %x %y]
	$zinc bind movable <ButtonRelease> [list $self moveRotStop $zinc %x %y]
}

# Begin a translation or rotation
#
GPFlatland method moveRotStart {zinc x y} {
	lassign [$zinc bbox current] x0 y0 x1 y1

	set xoff [expr {abs($x-(($x1+$x0)/2))}]
	set yoff [expr {abs($y-(($y1+$y0)/2))}]
	set pr [$self slot pickRadius]

	if {$xoff > $pr || $yoff > $pr} {
		$self slot moveMode rotating

		lassign [$zinc transform current 1 {0 0}] xRef yRef
		$self slot previousAngle [zincGraphics::LineAngle [list $x $y] [list $xRef $yRef]]
	} else {
		$self slot moveMode translating
		$self slot dx [- 0 $x]
		$self slot dy [- 0 $y]
	}
	#$zinc raise current
}

# Continue a translation or rotation
#
GPFlatland method moveRotMove {zinc x y} {
	switch [$self slot moveMode] {
		translating {
			poetvar $self dx dy

			$zinc translate current [+ $x $dx] [+ $y $dy]
			set dx [- 0 $x]
			set dy [- 0 $y]
		} 
		rotating {
			poetvar $self previousAngle

			set j [Zinc itemParam $zinc current j]
			lassign [$zinc transform current 1 {0 0}] xRef yRef
			set newAngle [zincGraphics::LineAngle [list $x $y] [list $xRef $yRef]]

			$zinc rotate poly&&j=$j [- $newAngle $previousAngle] yes
			set previousAngle $newAngle
		}
	}
}

# End a translation or rotation
#
GPFlatland method moveRotStop {zinc x y} {
	set j [Zinc itemParam $zinc current j]
	set c [$self slot _gridCell]

	switch [$self slot moveMode] {
		translating {
			$self moveRotMove $zinc $x $y
			lassign [$zinc tget current translation] nx ny
			set xc [$c subCell x $j]
			set yc [$c subCell y $j]
			Observer ignore $self $xc {$xc set $nx}
			Observer ignore $self $yc {$yc set $ny}
		} 
		rotating {
			set r [* [$zinc tget poly&&j=$j rotation] $::Thyrd::rad2deg]
			set rc [$c subCell rotation $j]
			Observer ignore $self $rc {$rc set $r}
		}
	}
}

#GPFlatland logMethods moveRotStart moveRotMove moveRotStop 

# Begin a rotation
#
GPFlatland method startRotatePolygon {zinc x y} {
	variable previousAngle

	foreach {xRef yRef} [$zinc transform [$zinc group current] 1 {0 0}] break
	set previousAngle [zincGraphics::LineAngle [list $x $y] [list $xRef $yRef]]
}

# Continue a rotation
#
GPFlatland method rotatePolygon {zinc x y} {
	variable previousAngle

	set tag [lindex [$zinc itemcget current -tags] 0]
	foreach {xRef yRef} [$zinc transform [$zinc group current] 1 {0 0}] break
	set newAngle [zincGraphics::LineAngle [list $x $y] [list $xRef $yRef]]

	$zinc rotate $tag [zincGraphics::deg2rad [expr $newAngle - $previousAngle]]
	set previousAngle $newAngle
}

# Begin a translation
#
GPFlatland method moveStart {zinc x y} {
	variable dx
	variable dy

	set dx [expr 0 - $x]
	set dy [expr 0 - $y]
	#$zinc raise current
}

# Continue a translation
#
GPFlatland method moveMove {zinc x y} {
	variable dx
	variable dy

	$zinc translate current [expr $x + $dx] [expr $y + $dy]
	set dx [expr 0 - $x]
	set dy [expr 0 - $y]
}

# End a translation
#
GPFlatland method moveStop {zinc x y} {
	$self moveMove $zinc $x $y
}

# Translate the view
#
GPFlatland method viewTranslate {zinc way} {
	set curView 1	

	set dx 0
	set dy 0
	switch -- $way {
	    left {set dx -10}
	    up {set dy -10}
	    right {set dx 10}
	    down {set dy 10}
	}

	$zinc translate $curView $dx $dy
}

# Zoom the view
#
GPFlatland method viewZoom {zinc key} {
	set curView 1 
    set zoomFactor .1

	set scaleRatio [expr {($key eq "up") ? (1 + $zoomFactor) : (1 - $zoomFactor)}]

	lassign [$zinc bbox 1] x0 y0 x1 y1

	set xc [expr {($x1+$x0)/2}]
	set yc [expr {($y1+$y0)/2}]

	$zinc scale $curView $scaleRatio $scaleRatio $xc $yc
}

## Observer API
##
## Observer messages from cells:
##		write				cell just loaded or entirely changed
##		read				cell value read
##		destruct			cell about to destruct
##		empty				Cell has been emptied (new core type)
##		newPlace			we've moved
##		gainSub cell i j	we're a grid and a new subcell's been made
##		loseSub cell i j	we're a grid and a subcell's been lost
##		xstatus onOff       change in execution status (are we on a Wave's X stack?)
##		paused onOff        change in paused status (break cells only, in middle of break)

# A name has changed
#
GPFlatland method delta-name {target event args} {
	poetvar $self zinc

	set gc [$self slot _gridCell]
	set j [$target slot j]

	$zinc itemconfigure label&&j=$j -text [$target peek] 
}

# An X value has changed
#
GPFlatland method delta-x {target event args} {
	poetvar $self zinc

	set gc [$self slot _gridCell]
	set j [$target slot j]

	$zinc translate movable&&j=$j [$target peek] [$gc peekAt y $j] yes
}

# A Y value has changed
#
GPFlatland method delta-y {target event args} {
	poetvar $self zinc

	set gc [$self slot _gridCell]
	set j [$target slot j]

	$zinc translate movable&&j=$j [$gc peekAt x $j] [$target peek] yes
}

# A number of sides has changed. We redo the whole row.
#
GPFlatland method delta-sides {target event args} {
	poetvar $self zinc

	set gc [$self slot _gridCell]
	set j [$target slot j]

	$zinc remove j=$j
	$self fillFromRow $zinc $gc $j
}

# A radius has changed. We redo the whole row.
#
GPFlatland method delta-radius {target event args} {
	poetvar $self zinc

	set gc [$self slot _gridCell]
	set j [$target slot j]

	$zinc remove j=$j
	$self fillFromRow $zinc $gc $j
}

# A rotation has changed
#
GPFlatland method delta-rotation {target event args} {
	poetvar $self zinc

	set gc [$self slot _gridCell]
	set j [$target slot j]

	set r [* [$zinc tget poly&&j=$j rotation] $::Thyrd::rad2deg]

	$zinc treset poly&&j=$j
	$zinc rotate poly&&j=$j [$target peek] yes
}

# A color has changed
#
GPFlatland method delta-color {target event args} {
	poetvar $self zinc

	set gc [$self slot _gridCell]
	set j [$target slot j]

	set color [$target peek]
	set alpha [$gc peekAt alpha $j]
	set line [::tk::Darken $color 50]

	set fill "${color};${alpha}"

	$zinc itemconfigure poly&&j=$j -fillcolor $fill -linecolor $line
	$zinc itemconfigure label&&j=$j -color $line
}

# An alpha has changed
#
GPFlatland method delta-alpha {target event args} {
	poetvar $self zinc

	set gc [$self slot _gridCell]
	set j [$target slot j]

	set color [$gc peekAt color $j]
	set alpha [$target peek]

	set fill "${color};${alpha}"

	$zinc itemconfigure poly&&j=$j -fillcolor $fill 
}

# A priority has changed
#
GPFlatland method delta-priority {target event args} {
	poetvar $self zinc

	set j [$target slot j]

	$zinc itemconfigure movable&&j=$j -priority [$target peek]
}

# We've just lost a cell, see if we should redraw
#
GPFlatland method lostCell {gc event c i j} {
	poetvar $self zinc

	set crows [- [lindex [$gc size] 1] 1]
	if {$crows != [$self slot nrows]} {
		$self unfill $zinc
		$self fillFlatland $zinc [$self slot _gridCell]
	} else {
		$zinc remove j=$j
		$self fillFromRow $zinc $gc $j
	}
}

# We've just gained a cell, see if we should redraw
#
GPFlatland method gainedCell {gc event c i j} {
	poetvar $self zinc

	set crows [- [lindex [$gc size] 1] 1]
	if {$crows != [$self slot nrows]} {
		$self unfill $zinc
		$self fillFlatland $zinc [$self slot _gridCell]
	} else {
		$zinc remove j=$j
		$self fillFromRow $zinc $gc $j
	}
}
