# ZincTest - a toplevel with a TkZinc canvas, for testing.
#
# PJM 2006-03-24	Begun
#


Window construct ZincTest
ZincTest mixin CellObserver

#ZincTest slot isModified 0			;# true if cell has been modified

# Setup
ZincTest method setup {} {
	puts "Zinc version: [package require Tkzinc]"
}

# Build the primary for a ZincTest
# We pick up _mainframe from MainFrameTool
#
ZincTest method buildPrimary {} {
	$self destroyPrimary

    $self slot menu [format {
        "&Test" all object 1 {
            {command "testTk" {} "Tk widgets" {} -command "%s testTk"}
            {command "testTile" {} "Tile widgets" {} -command "%s testTile"}
            {command "testGlyph" {} "Draw a glyph" {} -command "%s testGlyph"}
            {command "bindings" {} "Set bindings" {} -command "%s bindings"}
            {command "&Close" {} "Close this window" {} -command "%s destruct"}
        }
    } $self $self $self $self $self]

	set prim [$self as MainFrameTool buildPrimary]
	set mf [$self getFrame]

	$self wm withdraw
	$self wm title "ZincTest"

	set zinc [$self slot zinc ${mf}.zinc]
	zinc $zinc -backcolor white -render 1
	pack $zinc -side top -fill both -expand yes

	$self wm deiconify
    update idletasks

	return $prim
}

# Test using Tk widgets. 
#
ZincTest method testTk {} {
	set zinc [$self slot zinc]

	scale $zinc.s1 -orient horizontal -length 284 -from 0 -to 250 -tickinterval 50

	puts [$zinc add window 1 -window $zinc.s1]
}

# Test using Tile widgets. 
#
ZincTest method testTile {} {
	set zinc [$self slot zinc]

	package require gridplus
	gridplus::gridplus entry $zinc.employee -width 8 -state disabled -title Employee {
		{ID	.id + >}
		{Name .name 25}
		{Age .age 3}
		{Salary .salary}
	}

	gridplus::gridplus button $zinc.buttons {
		{Find .find} {Exit .exit}
	}

	gridplus::gridplus layout $zinc.main "
		$zinc.employee
		$zinc.buttons:ew
	"

	#scale $zinc.s1 -orient horizontal -length 284 -from 0 -to 250 -tickinterval 50

	puts [$zinc add window 1 -window $zinc.main]
}

# Test drawing a symbol from a symbol font, anti-aliased
#
ZincTest method testGlyph {} {
	set zinc [$self slot zinc]

	set v "\xF9" 

	$zinc add text 1 \
		-priority 100 -visible 1 \
		-font {{Wingdings 2} 72} -color red \
		-anchor center \
		-text $v
}

# Test out some bindings
#
ZincTest method bindings {} {
	set zinc [$self slot zinc]

    bind $zinc <ButtonPress-1>  "$self press motion %x %y"
    bind $zinc <ButtonPress-3>  "$self press mouseRotate %x %y"
    bind $zinc <ButtonPress-2>  "$self press zoom %x %y"

    bind $zinc <ButtonRelease-1>  "$self release"
    bind $zinc <ButtonRelease-2>  "$self release"
    bind $zinc <ButtonRelease-3>  "$self release"

    $self slot  curX 0
    $self slot  curY 0
    $self slot  curAngle 0
}


ZincTest method press {action x y} {
	set zinc [$self slot zinc]

	$self slot curX $x
	$self slot curY $y
	$self slot curAngle [expr atan2($y, $x)]

	bind $zinc <Motion> "$self $action %x %y"
}

ZincTest method motion {x y} {
	set zinc [$self slot zinc]

	foreach {x1 y1 x2 y2} [$zinc transform 1 \
				   [list $x $y [$self slot curX] [$self slot curY]]] break

	$zinc translate 1 [expr $x1 - $x2] [expr $y1 - $y2]
	$self slot curX $x
	$self slot curY $y
}

ZincTest method zoom {x y} {
	set zinc [$self slot zinc]

	if {$x > [$self slot curX]} {
	    set maxX $x
	} else {
	    set maxX [$self slot curX]
	}

	if {$y > [$self slot curY]} {
	    set maxY $y
	} else {
	    set maxY [$self slot curY]
	}

	if {($maxX == 0) || ($maxY == 0)} {
	    return;
	}

	set sx [expr 1.0 + (double($x - [$self slot curX]) / $maxX)]
	set sy [expr 1.0 + (double($y - [$self slot curY]) / $maxY)]

	$zinc scale 1 $sx $sx
	$self slot curX $x
	$self slot curY $y
	return -code break
}

ZincTest method mouseRotate {x y} {
	set zinc [$self slot zinc]

	set lAngle [expr atan2($y, $x)]

	$zinc rotate 1 [expr $lAngle - [$self slot curAngle]]

	$self slot curAngle  $lAngle
}

ZincTest method release {} {
	set zinc [$self slot zinc]

	bind $zinc <Motion> {}
}
