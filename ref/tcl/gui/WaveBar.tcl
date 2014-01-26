### The control bar for the WaveEditor
###
# PJM	2008-02-04	Begun

Object construct WaveBar
WaveBar mixin CellObserver
WaveBar mixin ParamListOwner
WaveBar mixin Glommed


# common params used by any window with a WaveBar
#
WaveBar slot _defaultParams {-nextwave {0 <boolean>}}

# Called to set up watching of the cells in the paramList
#
WaveBar method watchParams {pl} {
	$pl watchSub! $self newNextWave nextwave
}

#  Observer handler methods
#
WaveBar method newNextWave {target event} {
	set nw [$target get]

	Object safe [$self slot _nextwaveBtn] set [? $nw "down" "up"]
}

# Given a toolbar window (output of MainFrameTool addToolBarSlot)
# and a paramList cell, construct the navigation bar.
#
# The child object is glommed onto the toolbar, so that when the toolbar
# is destroyed so is the WaveBar object.
#
# We also require the client (WaveEditor object we're controlling).
#
WaveBar method new {tb pl client} {
	set kid [[$self construct *] glomOnto $tb]

	$kid slot paramList $pl

	set col 0
		#-lockedbackground [Colors get descendHi] 
	$kid slot _nextwaveBtn [ToggleButton construct * $tb -image [Thyrd getImage nextwave-dim] \
		-onimage [Thyrd getImage nextwave] \
		-helptext "Catch next wave" -command "$kid nextwaveLatch" \
		-layout "grid -padx 2 -column $col -row 0"]

	incr col
	BW_Button construct * $tb -image [Thyrd getImage unselect] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Unselect wave" \
		-layout "grid -padx 2 -column $col -row 0" -command "$client clearSelection"

	incr col
	BW_Button construct * $tb -image [Thyrd getImage refresh] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Refresh display" \
		-layout "grid -padx 2 -column $col -row 0" -command "$client refresh"

	incr col
	BW_Button construct * $tb -image [Thyrd getImage reset] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Reset selected wave" \
		-layout "grid -padx 2 -column $col -row 0" -command "$client resetWave"

	incr col
	$kid slot _padding [Tk_Frame construct * $tb -layout "grid -column $col -row 0"]
	set pad $col

	incr col
	$kid slot _backBtn [BW_Button construct * $tb -image [Thyrd getImage we-back] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Step back" -state disabled \
		-layout "grid -padx 2 -column $col -row 0" -command "$client stepBack"]

if 0 { ;# DEFERRED
	incr col
	$kid slot _subBtn [BW_Button construct * $tb -image [Thyrd getImage we-substep] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Take a microstep in a combinator" -state disabled \
		-layout "grid -padx 2 -column $col -row 0" -command "$client stepSubstep"]
}

	incr col
	$kid slot _fwdBtn [BW_Button construct * $tb -image [Thyrd getImage we-forward] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Step forward" -state disabled \
		-layout "grid -padx 2 -column $col -row 0" -command "$client stepForward"]

	incr col
	$kid slot _finBtn [BW_Button construct * $tb -image [Thyrd getImage we-finish] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Finish wave" -state disabled \
		-layout "grid -padx 2 -column $col -row 0" -command "$client finishUp"]

	grid columnconfigure $tb $pad -weight 1

	$kid watchParams $pl

	return $kid
} 

# The nextwave latch has been changed
#
WaveBar method nextwaveLatch {state} {
	switch $state {
		up {$self setParam nextwave 0}
		down {$self setParam nextwave 1}
		locked {$self setParam nextwave 1}
	}
}

# Set the state of the two forward buttons
#
WaveBar method setFwdButtons {onOff} {
	[$self slot _fwdBtn] slot state [? $onOff normal disabled]
	[$self slot _finBtn] slot state [? $onOff normal disabled]
}

# Set the state of the backward button
#
WaveBar method setBackButton {onOff} {
	[$self slot _backBtn] slot state [? $onOff normal disabled]
}

# Set the state of the microstep button
#
WaveBar method setMicrostepButton {onOff} {
	[$self slot _subBtn] slot state [? $onOff normal disabled]
}
