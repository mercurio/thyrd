### A simple map (we don't use Map) of slots to
### values, if a slot is not present then the mapped
### value defaults to the slot name.  We assume
### all keys are valid slot values.
#
# PJM 2007-08-20	Created

Object construct DefMap

# Get a value given a key (slot name).  Default to the 
# slot name if not present.
#
DefMap method get {key} {
	if {$key eq ""} { 
		return ""
	} elseif {[$self hasSlot $key]} {
		return [$self slot $key]
	} else {
		return $key
	}
}
