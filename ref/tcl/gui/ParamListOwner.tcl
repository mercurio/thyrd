### A mixin for an object that owns a ``paramList`` slot
###
# PJM	2006-09-29	Begun

Mixin construct ParamListOwner

# Set a parameter
#
ParamListOwner method setParam {param value} {
	set pl [$self slot paramList]
	assert {$pl ne ""}

	$pl putAt $value $param
}

# Set a parameter, but ignore it
#
ParamListOwner method setParamIgnore {param value} {
	set pl [$self slot paramList]
	assert {$pl ne ""}

	set c [$pl subCell $param]
	if {$c eq ""} {	;# doesn't exist yet, set it normally
		$pl putAt $value $param
	} else {
		# setSilently causes all observers to ignore it,
		# Observer ignore only applies to $self. setSilently 
		# is probably correct
		#Observer ignore $self $c {$c set $value}
		$c setSilently $value
	}
}

# Trigger a parameter's observers (resetting it to
# it's current value)
#
ParamListOwner method triggerParam {param} {
	set pl [$self slot paramList]
	assert {$pl ne ""}

	set c [$pl subCell $param]
	if {$c eq ""} {	;# doesn't exist yet,
		UserMsg error "|ParamListOwner triggerParam $param| Parameter cell doesn't exist"
	} else {
		$c notifyObservers write
	}
}

# Get a parameter
#
ParamListOwner method getParam {param} {
	set pl [$self slot paramList]
	assert {$pl ne ""}

	return [$pl getAt $param]
}

