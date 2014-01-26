# LatchButton - a Button that latches down until
# released programatically.  It can also be slid 
# over to hold it down until the user releases it.
#
# The command slot should contain a script that
# should be eval'd when the state changes, with
# "up", "down" or "locked" appended.
#
# PJM 2008-01-28	Begun
#

Tk_Frame construct LatchButton

LatchButton slot extraOptions {image helptext command}

LatchButton slot relief ridge
LatchButton slot borderwidth 2

LatchButton slot unlockedbackground [LatchButton slot background]
LatchButton type unlockedbackground <color>

LatchButton slot lockedbackground [LatchButton slot background]
LatchButton type lockedbackground <color>

LatchButton slot threshold 0
LatchButton type threshold <integer>

LatchButton slot lstate up
LatchButton type lstate "<choice> up down locked"

# Build a LatchButton
#
LatchButton method buildPrimary {} {
	set p [$self as Tk_Frame buildPrimary]

	set b [$self slot _btn [BW_Label construct * $p -image [$self slot image] \
		-relief raised -borderwidth 1 \
		-helptext [$self slot helptext] \
		-layout "place -relx 0 -y 0 -anchor nw"]]

	update idletasks ;# otherwise reqwidth and reqheight return 1 if btn is a label instead of a button
	$p configure -width [int [* [winfo reqwidth [$b primary]] 1.5]]
	$p configure -height [+ [winfo reqheight [$b primary]] [* 2 [$self slot borderwidth]]]

	#DEFERRED $p bind <ButtonRelease-1> [list $self _frameClick]

	$b bind <ButtonPress-1> [list $self _beginDrag $b %x %y]
	$b bind <B1-Motion> [list $self _continueDrag $b %x %y]
	$b bind <ButtonRelease-1> [list $self _endDrag $b %x %y]

	$self slot background [$self slot unlockedbackground]

	$self slot lstate up

	return $p
}

# Begin the drag operation on the button
#
LatchButton method _beginDrag {btn x y} {
	$btn slot relief sunken
	
	$self slot _x $x
	$self slot _y $y
}

# Continue the drag operation on the button
#
LatchButton method _continueDrag {btn x y} {
	set t [$self slot threshold]
	poetvar $self _x _y

	if {[$self slot lstate] ne "locked"} {
		if {$x > $_x + $t} {
			$btn slot layout "place -relx 1 -y 0 -anchor ne"
			set s latched
		} else {
			$btn slot layout "place -relx 0 -y 0 -anchor nw"
			set s unlatched
		}
	} else {
		if {$x <= $_x - $t} {
			$btn slot layout "place -relx 0 -y 0 -anchor nw"
			set s unlatched
		} else {
			$btn slot layout "place -relx 1 -y 0 -anchor ne"
			set s latched
		}
	}

	return $s
}

# End the drag operation on the button.  It might not
# have been dragged.
#
LatchButton method _endDrag {btn x y} {
	set com [$self slot command]

	switch [$self _continueDrag $btn $x $y] {
		latched {
			$self slot lstate locked
			$self slot background [$self slot lockedbackground]
			eval {*}$com locked
		} 
		unlatched {
			$self slot background [$self slot unlockedbackground]

			if {[$self slot lstate] eq "up"} {
				$self slot lstate down
				eval {*}$com down
			} else {
				$btn slot relief raised
				$self slot lstate up
				eval {*}$com up
			}
		}
	}
}

# Latch until released by user
#
LatchButton method lock {} {
	poetvar $self _btn

	$_btn slot relief sunken
	$_btn slot layout "place -relx 1 -y 0 -anchor ne"
	$self slot lstate locked
	$self slot background [$self slot lockedbackground]
}

# Return to unlocked state, but don't trigger command
#
LatchButton method unlock {} {
	poetvar $self _btn

	$_btn slot relief raised
	$_btn slot layout "place -relx 0 -y 0 -anchor nw"
	$self slot lstate up
	$self slot background [$self slot unlockedbackground]
}
