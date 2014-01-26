# Zinc - singleton providing utility methods for
# dealing with TkZinc canvases (the canvas is always
# provided as an argument) and storing info on
# canvases.
#
# PJM 2006-05-24	Begun
#

Object construct Zinc

# Push attributes on an item
#
Zinc method pushConfigure {z item args} {
	foreach {flag value} $args {
		$self slotPush "$z,$item,$flag" [$z itemcget $item $flag]
		$z itemconfigure $item $flag $value
	}
}
	
# Pop attributes on an item
#
Zinc method popConfigure {z item args} {
	foreach flag $args {
		set stack "$z,$item,$flag"
		if {[$self slotLength $stack] > 0} {
			set value [$self slotPop $stack]
			$z itemconfigure $item $flag $value
		}
	}
}

# Return a scaled version of a box of coordinates.
# We choose the smaller of the width/height
# delta to form an even border.
#
Zinc method scalebox {s x0 y0 x1 y1} {
	set w [expr ($x1 - $x0)]
	set w2 [expr $s * $w]
	set dw [expr $w2 - $w]

	set h [expr ($y1 - $y0)]
	set h2 [expr $s * $h]
	set dh [expr $h2 - $h]

	set d [expr ($dh < $dw) ? $dh : $dw]

	return [list [- $x0 $d] [- $y0 $d] [+ $x1 $d] [+ $y1 $d]]
}

# Return an offset version of a box of coordinates.
#
Zinc method offsetbox {args} {
	switch [llength $args] {
		1 {return [list 0 0 0 0]}
		2 {
			set d [lindex $args 0]
			lassign [lindex $args 1] x0 y0 x1 y1
		}
		5 {
			set d [lindex $args 0]
			lassign [lrange $args 1 end] x0 y0 x1 y1
		}
		default {error "Zinc offsetbox assumes 1, 2 or 5 arguments"}
	}

	return [list [- $x0 $d] [- $y0 $d] [+ $x1 $d] [+ $y1 $d]]
}

# Given a rectangle, compute the inside, adding in the pad if
# provided.  If lwpad is provided, it's the linewidth we're going
# to use for the inner box. We look at the linewidth of the rect, 
# half of which is inside.  A list of the coords is returned.
#
Zinc method inside {zinc rect {pad 0} {lwpad 0}} {
	foreach {c0 c1} [$zinc coords $rect] break
	foreach {x0 y0} $c0 break
	foreach {x1 y1} $c1 break

	set lw [$zinc itemcget $rect -linewidth]
	
	set d [expr {(($lw + 1)/2) + $pad + (($lwpad + 1)/2)}]

	return [list [+ $x0 $d] [+ $y0 $d] [- $x1 $d] [- $y1 $d]]
}

# Return an integer version of a box of coordinates.
#
Zinc method integerbox {x0 y0 x1 y1} {
	return [list [int $x0] [int $y0] [int $x1] [int $y1]]
}

# Return a box given width, height, and center
#
Zinc method boxAt {xc yc w h} {
	set w2 [/ $w 2]
	set h2 [/ $h 2]
	return [list [- $xc $w2] [- $yc $h2] [+ $xc $w2] [+ $yc $h2]]
}

# Return an assymetric offset version of a box of coordinates.
#
Zinc method assymoffsetbox {dx dy x0 y0 x1 y1} {
	return [list [- $x0 $dx] [- $y0 $dy] [+ $x1 $dx] [+ $y1 $dy]]
}

# Givan a box (list of x0 y0 x1 y1) return a set of coords
# (list of 2 lists).
Zinc method box2coords {b} {
	foreach {x0 y0 x1 y1} $b break
	return [list [list $x0 $y0] [list $x1 $y1]]
}

# Given an outer box and an inner box, return a curve
# consisting of the outer box with the inner boox subtracted.
# The inner box is assumed to be in one of the corners,
# within the tolerance given.
#
Zinc method notchedBox {obox ibox {tolerance 0}} {
	foreach {ox0 oy0 ox1 oy1} $obox break
	foreach {ix0 iy0 ix1 iy1} $ibox break

	if {[Zinc samePoint $ox0 $oy1 $ix0 $iy1 $tolerance]} {
		return [list $ox0 $oy0 $ox1 $oy0 $ox1 $oy1 $ix1 $oy1 $ix1 $iy0 $ox0 $iy0]
	} elseif {[Zinc samePoint $ox1 $oy1 $ix1 $iy1 $tolerance]} {
		return [list $ox0 $oy0 $ox1 $oy0 $ox1 $iy0 $ix0 $iy0 $ix0 $oy1 $ox0 $oy1]
	} elseif {[Zinc samePoint $ox1 $oy0 $ix1 $iy0 $tolerance]} {
		return [list $ox0 $oy0 $ix0 $oy0 $ix0 $iy1 $ix1 $iy1 $ox1 $oy1 $ox0 $oy1]
	} else {
		return [list $ix1 $oy0 $ox1 $oy0 $ox1 $oy1 $ox0 $oy1 $ox0 $iy1 $ix1 $iy1]
	}
}

# Return true if two points are identical, within the
# given tolerance 
#
Zinc method samePoint {x0 y0 x1 y1 {tolerance 0}} {
	return [expr {abs($x0-$x1) <= $tolerance && abs($y0-$y1) <= $tolerance}]
}

# Given a group of items, lay them out in a horizontal
# row with the given spacing
#
Zinc method layoutHorz {zinc group {spacing 0}} {
	set subs [lsort -integer [$zinc find withtag ${group}.]]
	
	set a ""
	foreach b $subs {
		if {$a ne ""} {
			lassign [$zinc bbox $a] ax0 ay0 ax1 ay1
			lassign [$zinc bbox $b] bx0 by0 bx1 by1

			$zinc translate $b [expr {$ax1 - $bx0 + $spacing}] [expr {$ay0 - $by0}]
		}

		set a $b
	}
}

# Render a row of small buttons in the given group,
# with the given tag list.  The remaining args
# are pairs of the text and color for each button.
#
# We return a list of the ids for the buttons, in order.
#
Zinc method smallButtons {zinc group tags args} {
	foreach {txt color} $args {
		lappend ids [$self drawSmallButton $zinc $group $tags $txt $color]
	}

	$self layoutHorz $zinc $group -1

	return $ids
}

# Draw a small button with the given text and color
#
Zinc method drawSmallButton {zinc group tags txt color} {
    set g [$zinc add group $group -atomic 1 -tags [concat $tags $txt]]

	set borderColor [::tk::Darken $color 150]
	set textColor [::tk::Darken $color 50]

	set t [$zinc add text $g -priority 100 -position {0 0} \
		-text $txt -anchor center -alignment center -font smbtn -color $textColor]

	foreach {x0 y0 x1 y1} [eval Zinc assymoffsetbox 5 2 [$zinc bbox $t]] break

	array set oval {
		-itemtype hippodrome 
	}

	set oval(-coords) [list [list $x0 $y0] [list $x1 $y1]]

	array set borderParams {
		-priority 150
		-filled 0
		-linewidth 1.5
	}

	set borderParams(-linecolor) $borderColor

	array set backParams {
		-priority 50
		-filled 1
	}

	set backParams(-fillcolor) $color

	set oval(-params) [array get borderParams]
	zincGraphics::BuildZincItem $zinc $g [array get oval] border --
	
	set oval(-params) [array get backParams]
	zincGraphics::BuildZincItem $zinc $g [array get oval] back --

	return $g
}

# Render a row of small icon buttons in the given group,
# with the given tag list.  The remaining args are the
# image names for each button.
#
# We return a list of the ids for the buttons, in order.
#
Zinc method smallIconButtons {zinc group tags args} {
	foreach im $args {
		lappend ids [$self drawIcon $im $zinc $group [concat $tags $im]]
	}

	$self layoutHorz $zinc $group -1

	return $ids
}

# Render a box with text in it, floating over the canvas
#
Zinc method infoBox {zinc group msg bg} {
    set g [$zinc add group $group -atomic 1]

	set borderColor [::tk::Darken $bg 150]
	set textColor [::tk::Darken $bg 50]

	set t [$zinc add text $g -priority 100 -position {0 0} \
		-text $msg -anchor center -alignment center -font smbtn -color $textColor]

	foreach {x0 y0 x1 y1} [eval Zinc assymoffsetbox 5 2 [$zinc bbox $t]] break

	array set box {
		-itemtype roundedrectangle 
	}

	set box(-coords) [list [list $x0 $y0] [list $x1 $y1]]

	array set borderParams {
		-priority 150
		-filled 0
		-linewidth 1.5
	}

	set borderParams(-linecolor) $borderColor

	array set backParams {
		-priority 50
		-filled 1
	}

	set backParams(-fillcolor) $bg

	set box(-params) [array get borderParams]
	zincGraphics::BuildZincItem $zinc $g [array get box] border --
	
	set box(-params) [array get backParams]
	zincGraphics::BuildZincItem $zinc $g [array get box] back --

	return $g
}


# Position a halo near another item
#
Zinc method nextTo {zinc ref halo} {
	set w [$zinc cget -width]
	set h [$zinc cget -height]

	foreach {x0 y0 x1 y1} [$zinc bbox $ref] break

	foreach {hx0 hy0 hx1 hy1} [$zinc bbox $halo] break
	set hw [expr {$hx1 - $hx0}]
	set hh [expr {$hy1 - $hy0}]

	set rx $x0
	if {$rx + $hw > $w} {
		set rx [expr {$w - $hw - 1}]
	}

	set ry $y1
	if {$ry + $hh > $h} {
		set ry [expr $y0 - $hh]
	}

	$zinc translate $halo [expr {$rx - $hx0}] [expr {$ry - $hy0}]
}

# Position an item in the lr corner of another
#
Zinc method lowerRightCorner {zinc ref item} {
	set w [$zinc cget -width]
	set h [$zinc cget -height]

	foreach {x0 y0 x1 y1} [$zinc bbox $ref] break

	foreach {ix0 iy0 ix1 iy1} [$zinc bbox $item] break
	set iw [expr {$ix1 - $ix0}]
	set ih [expr {$iy1 - $iy0}]

	set nx [expr $x1 - $iw]
	if {$nx + $iw > $w} {
		set nx [expr {$w - $iw - 1}]
	}

	set ny [expr $y1 - $ih]
	if {$ny + $ih > $h} {
		set ny [expr {$h - $ih - 1}]
	}

	$zinc translate $item [expr {$nx - $ix0}] [expr {$ny - $iy0}]
}

# Draw a glyph
#
Zinc method drawGlyph {which zinc group tags} {
	set g [$zinc add group $group -atomic 1 -tags $tags]

	set im [Thyrd getImage glyph-[string tolower $which]]
	$zinc add icon $g -image $im -composescale 1

	return $g
}

# Return the size of a glyph (width and height)
#
Zinc method sizeOfGlyph {which} {
	set im [Thyrd getImage glyph-[string tolower $which]]
	return [list [image width $im] [image height $im]]
}

# Draw an icon
#
Zinc method drawIcon {which zinc group tags} {
	set g [$zinc add group $group -atomic 1 -tags $tags]

	set im [Thyrd getImage $which]
	$zinc add icon $g -image $im -composescale 1

	return $g
}

# Draw a glyph (vector version)
#
Zinc method OLDdrawGlyph {which zinc group tags} {
	set g [$zinc add group $group -atomic 1 -tags $tags]

set which A
	switch $which {
		A {
			if {![$zinc gname glyphA]} {
				$zinc gname "=axial 0 | \#c16666;100 0 | \#000000;0 100" glyphA
				font create glyphA -family "arial rounded mt bold" -size 20 -weight normal
			}

			set back [$zinc add curve $g {{32.605495 82.215003} {5.5611792 35.580856} {59.469693 35.476865} {32.605495 82.215003}} \
				-priority 50 -filled 1 -closed 1 -linewidth 0 -fillcolor glyphA -capstyle projecting]
			$zinc translate $back 0 -26

			$zinc add curve $g {{5.0909086 9.5454545} {32.272727 54.909091} {58.363637 9.8181821}} \
				-priority 100 -closed 0 -linecolor \#a52e2e -filled 0 -capstyle round -joinstyle round -linewidth 1.5

			$zinc add text $g -position {23.115234 34.384766} -anchor sw -color "\#ffffff;1" \
				-font glyphA -alignment left -text A -priority 150
		}
	}

	return $g
}

# Given a span and a divisor, divide it into that many partitions
# and return the midpoint of each.
#
Zinc method partition {span div} {
	set w [/ $span $div]

	set out [list]
	set x [/ $w 2]
	for {} {$div > 0} {incr div -1} {
		lappend out $x
		set x [+ $x $w]
	}

	return $out
}

# Print a newline-delimited list of the given item(s)' attributes
# and coordinates
# (for debugging)
#
Zinc method pitem {zinc args} {
	foreach i $args {
		puts "$i : [$zinc coords $i] (in [$zinc group $i])"
		foreach alist [$zinc itemconfigure $i] {
			foreach {a b c d e} $alist {}
			puts "$a $e"
		}
	}
}

# Print a list of the given item(s)' tags
# (for debugging)
#
Zinc method ptags {zinc args} {
	foreach x $args {
		foreach i [lsort [$zinc find withtag $x]] {
			puts "$i : [$zinc coords $i] [$zinc gettags $i]"
		}
	}
}

# Get the param represented by the given item.  No error
# is generated if it's not there, null is returned.
#
Zinc method itemParam {zinc item param} {
	set s [lsearch -inline -glob [$zinc gettags $item] "${param}=*"]

	if {$s eq "" || [llength $s] > 1} {return ""}

	set val ""
	regexp "${param}=(.*)" $s -> val

	return $val
}

# Search the item's group hierarchy for something
# with the given param.  Return "" if not found.
#
Zinc method findParam {zinc item param} {
	set ans [$self itemParam $zinc $item $param]
	if {$ans ne ""} {return $ans}

	while {[set g [$zinc group $item]] != $item} {
		set ans [$self itemParam $zinc $g $param]
		if {$ans ne ""} {return $ans}

		set item $g
	}

	return ""
}

# Get the cell represented by the given item
#
Zinc method itemCell {zinc item} {
	set s [lsearch -inline -glob [$zinc gettags $item] "cell=*"]

	if {$s eq "" || [llength $s] > 1} {
		UserMsg error "|$self itemCell $zinc $item| Tag error, found: $s"
		return
	}

	return [string range $s 5 end]
}

# Remove the cell=* tag on this items with the given tag, be silent if error.
#
Zinc method rmCellTag {zinc tag} {
	foreach item [$zinc find withtag $tag] {
		foreach s [lsearch -inline -glob [$zinc gettags $item] "cell=*"] {
			$zinc dtag $item $s
		}
	}
}

# Given a list of ids, return the first one that has the
# given tag or tag pattern.  If none do, return null.
#
Zinc method searchForTag {zinc tagpat ids} {
	foreach i $ids {
		if {[lsearch -glob [$zinc gettags $i] $tagpat] != -1} {return $i}
	}

	return ""
}

# Search the item's group hierarchy for something
# with the given tag.  Return "" if not found.
#
Zinc method findTagUpGroup {zinc tag item} {
	while {[set g [$zinc group $item]] != $item} {
		if {[$zinc hastag $g $tag]} {return $g}

		set item $g
	}

	return ""
}

# Initiate zooming to a bounding box.  This can be a zoom
# in or out.
#
# Uses Furnas' & Bederson's Space-Scale approach
# (scale changes hyperbolically while the panning is linear).
#
# We compute a scale metric and use it to decide
# how many steps to take.
#
Zinc method zoomView {zinc bbox what fps {andThen {}}} {
	foreach {x0 y0 x1 y1} $bbox break

	set w [$zinc cget -width]
	set h [$zinc cget -height]

	set dx [expr $x1 - $x0]
	set dy [expr $y1 - $y0]

	# the x and y zooms
	set zx [expr $w / $dx]
	set zy [expr $h / $dy]

	# Scale metric
	set sm [expr {$zx < 1 ? 1.0/$zx : $zx}]
	set nsteps [limit 4 [expr {int(($sm - 1)*10)}] 10]

	# the new corner point
	set cx [expr $x0]
	set cy [expr $y0]

	# convert to u,v space
	set u1x 0
	set v1x 1.0
	set u2x [expr {$cx * $zx}]
	set v2x $zx

	set u1y 0
	set v1y 1.0
	set u2y [expr {$cy * $zy}]
	set v2y $zy

	set logV1x [expr {log($v1x) / log(2.0)}]
	set logV2x [expr {log($v2x) / log(2.0)}]
	set logV1y [expr {log($v1y) / log(2.0)}]
	set logV2y [expr {log($v2y) / log(2.0)}]

	ZAnimTask start $zinc $what $nsteps [list $fps $u1x $v1x $u2x $v2x $u1y $v1y $u2y $v2y $logV1x $logV2x $logV1y $logV2y] $andThen
}

# Debugging aid
#
Zinc method startDebug {zinc} {
	$zinc bind all <Enter> [list Zinc debugPrintShort $zinc]
}

# Turn off debugging
#
Zinc method endDebug {zinc} {
	$zinc bind all <Enter> ""
}

# Print out info on the current item, or a given item
#
Zinc method debugPrint {zinc {item "current"}} {
	set i [$zinc find withtag $item]
	
	puts stderr "$i [$zinc type $i] ([$zinc bbox $i])"
	puts stderr [join [$zinc itemconfigure $i] \n]
	puts stderr "\n"
}

# Print out info on the current item, or a given item
# short form
#
Zinc method debugPrintShort {zinc {item "current"}} {
	set i [$zinc find withtag $item]
	
	puts stderr "$i [$zinc type $i] ([$zinc bbox $i])"
}

# Print out all the items that have the given tag
#
Zinc method debugTag {zinc tag} {
	foreach i [$zinc find withtag $tag] {
		Zinc debugPrint $zinc $i
	}
}
