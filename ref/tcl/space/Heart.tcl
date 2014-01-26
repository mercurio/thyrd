### Controller for the heartbeat. This object
### manages /thyrd/heart/beat, which can be used
### in formulas to trigger repeating action.
###
### The heart rate is in beats per second
###
#
# PJM	2008-11-21 Created
#

Object construct Heart
Heart mixin Observer

# Construct the heart table, if it's not there.
# Start watching the rate cell and start beating if
# it's > 0.
#
Heart method initialize {} {
	set hc [theSpace find "/thyrd/heart"]

	if {$hc eq ""} {
		set hc [Cell goto "/thyrd/heart" yes]

		$hc putTypeAt 0 "<integer> 0" beat 
		$hc putTypeAt 0 "<real> 0 30 .1" rate 
		$hc putTypeAt 1 "<real> 0 30 .1" rateAtStart 

		theSpace setAttr /thyrd/heart/beat panel Animation
	}

	set r [$self slot _rate [theSpace find "/thyrd/heart/rate"]]
	$r addObserver write $self beat

	$self slot _beat [theSpace find "/thyrd/heart/beat"]
}

# Take one beat and queue the next, unless the
# rate is 0, in which case we cancel any previous 
# beat.
#
# This is also called when we observe the rate cell
# has changed.
#
Heart method beat {args} {
	set rc [$self slot _rate]
	set rate [$rc get] 

	after cancel [$self slot _after]
	if {$rate != 0} {
		set bc [$self slot _beat]

		$bc set [+ [$bc get] 1]

		set ms [expr int(1000.0 / [$rc get])]
		$self slot _after [after $ms [list $self beat]]
	}
}

# Start beating using the rateAtStart
#
Heart method start {} {
	set rc [$self slot _rate]
	$rc set [[theSpace find "/thyrd/heart/rateAtStart"] get]
}

# Stop beating
#
Heart method stop {} {
	set rc [$self slot _rate]
	$rc set 0
}
