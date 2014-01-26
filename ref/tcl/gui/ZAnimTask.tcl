# Zinc - singleton providing utility methods for
# dealing with TkZinc canvases (the canvas is always
# provided as an argument) and storing info on
# canvases.
#
# PJM 2006-05-24	Begun
# PJM 2008-11-08	Removed stepTime slot, fps is now a param
#

Object construct ZAnimTask

# Create a new ZAnimTask given the canvas, tag, number of steps,
# and interpolation parameters.  If ``andThen`` is provided,
# it's a script to execute after the animation has completed.
#
ZAnimTask method start {zinc what n params {andThen {}}} {
	set kid [$self construct *]

	$kid slot zinc $zinc
	$kid slot what $what
	$kid slot nSteps $n
	$kid slot n $n		;# counter
	$kid slot params $params
	$kid slot andThen $andThen

	$kid slot xform xform[string range $kid 1 end]

	$kid slot sx 1 
	$kid slot sy 1
	$kid slot tx 0
	$kid slot ty 0

	set stepTime [expr {int(1000/[lindex $params 0])}]
	after $stepTime [list $kid step]
}


# Take one step in the animation
#
ZAnimTask method step {} {
	set n [$self slot n]
	set nSteps [$self slot nSteps]
	
	if {$n <= 0} {	;# we're done
		set andThen [$self slot andThen]
		if {$andThen ne ""} {
			uplevel #0 $andThen
		}

		$self destruct
		return
	}

	lassign [$self slot params] fps u1x v1x u2x v2x u1y v1y u2y v2y logV1x logV2x logV1y logV2y

	set xform [$self slot xform]
	set zinc [$self slot zinc]
	set what [$self slot what]

	# the linear interpolation parameter, (0..1]
	set t [expr {($nSteps - $n + 1.) / $nSteps}]
		
	set vx [expr {pow(2.0,[lerp $t $logV1x $logV2x])}]
	set vy [expr {pow(2.0,[lerp $t $logV1y $logV2y])}]

	set fx [expr {($v2x - $v1x) == 0 ? 1 : (($u2x - $u1x) / ($v2x - $v1x))}]
	set fy [expr {($v2y - $v1y) == 0 ? 1 : (($u2y - $u1y) / ($v2y - $v1y))}]

	set ux [expr {$u1x + ($vx - $v1x) * $fx}]
	set uy [expr {$u1y + ($vy - $v1y) * $fy}]

	# Convert (u,v) to (x,y)
	set x [expr $ux / $vx]
	set y [expr $uy / $vy]

	$zinc tsave identity $xform
	$zinc translate $xform [expr 0 - $x] [expr 0 - $y]
	$zinc scale $xform $vx $vy

	eval $zinc tset $what [$zinc tget $xform]

	$self slotIncr n -1

	set stepTime [expr {int(1000/$fps)}]
	after $stepTime [list $self step]
}
