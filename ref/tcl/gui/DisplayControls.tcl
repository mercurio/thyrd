### A small control panel for display options toolbar.
###
# PJM	2007-04-09	Begun

Object construct DisplayControls
DisplayControls mixin CellObserver
DisplayControls mixin ParamListOwner
DisplayControls mixin Glommed

# common params used by any window with a DisplayControl
# some of these are currently only accessible via menus
DisplayControls slot _defaultParams {
	-iframe {auto "<choice> auto always never"}
	-jframe {auto "<choice> auto always never"}
	-layout {expand "<choice> expand fixed"}
	-idirection {right "<choice> right down auto"}
	-panels {0 <boolean>}
	-gridpanels {1 <boolean>}
	-defaultGpanel {none {<choice> none table "read-only table"}}
	-defaultCpanel {"by type" {<choice> none "by type" "text entries"}}
}

# Called to set up watching of the cells in the paramList
#
DisplayControls method watchParams {pl} {
	$pl watchSub $self newPath path
	$pl watchSub! $self newIDir idirection
	$pl watchSub! $self newLayout layout
	$pl watchSub! $self newIFrame iframe
	$pl watchSub! $self newJFrame jframe
}

#  Observer handler methods
#
#  These are invoked when the cells are changed externally,
#  we just need to reflect the changes
#
DisplayControls method newIDir {target event} {
	set v [$target get]

	[$self slot _idir_right] slot value $v
	[$self slot _idir_down] slot value $v

	$self syncToIDir
}

DisplayControls method newLayout {target event} {[$self slot _layout] slot value [$target get]}

DisplayControls method newIFrame {target event} {
	[$self slot _iframe_horz] slot value [$target get]
	[$self slot _iframe_vert] slot value [$target get]
}

DisplayControls method newJFrame {target event} {
	[$self slot _jframe_vert] slot value [$target get]
	[$self slot _jframe_horz] slot value [$target get]
}

# We only want to know the path so we can display 
# correctly when idir == auto
#
DisplayControls method newPath {target event} {
	set path [$target get]

	if {![$self pathDelta $path]} return

	$self syncToIDir
}



# Given a parent window, a paramList cell, and a layout string,
# construct the buttons which control the display parameters.
#
# We construct a child object to contain the state and glom it
# onto the parent.
#
DisplayControls method new {mom pl layout} {
	set kid [[$self construct *] glomOnto $mom]

	$kid slot paramList $pl

	set nwCorner [Thyrd getImage idir-auto-right]
	set xoffset [expr 2 + [image width $nwCorner]]
	set yoffset [expr 2 + [image height $nwCorner]]

	set seCorner [Thyrd getImage layout-expand] 
	#set xtotal [expr $xoffset + [image width $seCorner]]
	#set ytotal [expr $xoffset + [image height $seCorner]]
	# this produces a better layout
	set xtotal [expr 4 + $xoffset + [image width $seCorner]]
	set ytotal [expr 4 + $xoffset + [image height $seCorner]]

	set sf [Tk_Frame construct * $mom -borderwidth 0 \
		-width $xtotal -height $ytotal -layout $layout]

	$kid slot _idir_right [IconCycle construct * $sf \
		-values {auto right down} -value [$kid getParam idirection] \
		-images [list $nwCorner \
			[Thyrd getImage idir-right] [Thyrd getImage idir-down]] \
		-helptext " i direction: right, down or auto" \
		-notify "$kid setParam idirection" \
		-layout "place -x 0 -y 0"]

	$kid slot _idir_down [IconCycle construct * $sf \
		-values {auto right down} -value [$kid getParam idirection] \
		-images [list [Thyrd getImage idir-auto-down] \
			[Thyrd getImage idir-right] [Thyrd getImage idir-down]] \
		-helptext " i direction: right, down or auto" \
		-notify "$kid setParam idirection" \
		-layout "place -x 0 -y 0"]

	$kid slot _iframe_horz [IconCycle construct * $sf \
		-values {auto always never} -value [$kid getParam iframe] \
		-images [list [Thyrd getImage iframe-horz-auto] \
			[Thyrd getImage iframe-horz-always] [Thyrd getImage iframe-horz-never]] \
		-helptext " i frame display: always, never or auto" \
		-notify "$kid setParam iframe" \
		-layout "place -x $xoffset -y 0"]

	$kid slot _jframe_horz [IconCycle construct * $sf \
		-values {auto always never} -value [$kid getParam jframe] \
		-images [list [Thyrd getImage jframe-horz-auto] \
			[Thyrd getImage jframe-horz-always] [Thyrd getImage jframe-horz-never]] \
		-helptext " j frame display: always, never or auto" \
		-notify "$kid setParam jframe" \
		-layout "place -x $xoffset -y 0"]

	$kid slot _jframe_vert [IconCycle construct * $sf \
		-values {auto always never} -value [$kid getParam jframe] \
		-images [list [Thyrd getImage jframe-vert-auto] \
			[Thyrd getImage jframe-vert-always] [Thyrd getImage jframe-vert-never]] \
		-helptext " j frame display: always, never or auto" \
		-notify "$kid setParam jframe" \
		-layout "place -x 0 -y $yoffset"]

	$kid slot _iframe_vert [IconCycle construct * $sf \
		-values {auto always never} -value [$kid getParam iframe] \
		-images [list [Thyrd getImage iframe-vert-auto] \
			[Thyrd getImage iframe-vert-always] [Thyrd getImage iframe-vert-never]] \
		-helptext " i frame display: always, never or auto" \
		-notify "$kid setParam iframe" \
		-layout "place -x 0 -y $yoffset"]

	$kid slot _layout [IconCycle construct * $sf \
		-values {expand fixed} -value [$kid getParam layout] \
		-images [list $seCorner \
			[Thyrd getImage layout-fixed] ] \
		-helptext " layout: fixed or expand" \
		-notify "$kid setParam layout" \
		-layout "place -x $xoffset -y $yoffset"]

	$kid watchParams $pl
	$kid syncToIDir

	return $kid
} 

# Sync the display to the idir value, raising the right set of i and j frame
# buttons
#
# If it's auto, we look at the viewCell and mimic it (down of jSize <= 2)
#
DisplayControls method syncToIDir {} {
	set dir [$self getParam idirection] 

	if {$dir eq "auto"} {
		set dir right

		set c [$self viewCell]
		if {[Object exists $c]} {
			foreach {iSize jSize} [$c size] break
			if {$jSize <= 2} {
				set dir down
			}
		}
	}

	switch $dir {
		right {
			[$self slot _idir_right] raise
			[$self slot _iframe_horz] raise
			[$self slot _jframe_vert] raise
		}
		down {
			[$self slot _idir_down] raise
			[$self slot _jframe_horz] raise
			[$self slot _iframe_vert] raise
		}
	}
}
