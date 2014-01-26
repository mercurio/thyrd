### Panel -- a control panel for a cell in 
### Thyrdspace (atomic or grid).  Panels are
### drawn on top of the zoomable Thyrdspace 
### view (CellZincTable) when not zooming if
### the user hasn't diabled them.
###
### Panel acts as a factory for all panels
### via ``build{}``.
###
### A panel can be any Tk widget, we do not rely 
### on the Poet widget support here.  
###
### The cell we're viewing is accessed via ``viewCell{}``,
### as supported by the CellObserver mixin.
###
# PJM 2007-03-19	Begun

Object construct Panel
Panel mixin Observer
Panel mixin CellObserver
Panel mixin Glommed

# Build a new panel in the given Tk frame.
#
Panel method buildInFrame {f tool c {opts {}}} {
	return [$self build $f $tool $c $opts]
}

# Build a new panel in the given Zinc canvas, inside the
# given tool, covering the given group, editing the given cell.
#
# Now looks to see if the Panel already exists, and
# just returns it.
#
Panel method buildInZinc {zinc tool g c {opts {}}} {
	lassign [$zinc bbox $g] x0 y0 x1 y1

	set p [$self build $zinc $tool $c $opts [- $x1 $x0 -1] [- $y1 $y0 -1]]
	set item [$zinc add window $g -window $p -tags [list "panel" "cell=$c"]]
	$zinc translate $item $x0 $y0

	return $item
}

# Find the given panel in the given zinc canvas.
# We're given the group that should enclose the panel,
# there should either be one there or none.
#
Panel method findInZinc {zinc g c} {
	set item [$zinc find withtag $g*panel&&cell=$c]
	if {$item eq ""} {return ""}

	return [$zinc itemcget $item -window]
}

# Remove all the panels from the given Zinc canvas.
# They should all be tagged "panel".
#
Panel method removePanels {zinc} {
	foreach i [$zinc find withtag "panel"] {
		set w [lindex [$zinc itemconfigure $i -window] end]
		destroy $w
		$zinc remove $i
	}
}

# Build a new panel for the given cell in the given parent
# with the given dimensions
#
# Each child should override this method. Construct any
# Tk/Ttk widget and its contents, then use ``glomOnto`` to
# construct a new Poet object that will be destroyed when
# the widget is destroyed.
#
Panel method build {mom tool c {opts {}} {w {}} {h {}}} {
	if {[$c atomic]} {
		return [APEntry build $mom $tool $c $opts $w $h]
	} else {
		return [GridPanel build $mom $tool $c $opts $w $h]
	}
}
