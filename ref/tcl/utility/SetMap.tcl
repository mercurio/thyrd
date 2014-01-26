### A map from object names to sets.  Very similar
### to Poet's Map but we treat the thing linked to
### as a set rather than a single object.  And the
### type validation was removed.
#
# PJM 2005-11-25	Created 
# PJM 2005-11-27	Derived from Poet's Map

Object construct SetMap

# Add $to to the set of objects linked to from $from.
#
SetMap method addLink {from to} {
	$self slotUnique "MAP_$from" $to
}

# Retrieve the list of targets from $from.  Return
# the null list if $from is not present.
#
SetMap method getLinks {from} {
	set sp [$self findSlot "MAP_$from"]
	if {$sp eq ""} {return [list]}

	return [$sp slot "MAP_$from"]
}

# Return 1 if we have links for $from (including inheritance),
# 0 otherwise.  We both look for the $from index to be present
# and count the number of targets if it is.
#
SetMap method hasLinks {from} {
	set sn "MAP_$from"
	set sp [$self findSlot $sn]
	if {$sp eq ""} {return 0} 

	return [expr [$self slotLength $sn] > 0]
}

# Return the number of links for $from.
#
SetMap method nLinks {from} {
	set sn "MAP_$from"
	set sp [$self findSlot $sn]
	if {$sp eq ""} {return 0} 

	return [$self slotLength $sn]
}

# Unlink a target, do nothing if not a link.  
#
SetMap method unlink {from to} {
	set sn "MAP_$from"
	set sp [$self findSlot $sn]

	if {$sp ne ""} {
		$self slotRemove $sn $to
	}
}

# Remove all the links from a $from object.  Ask the user
# if it's not a local link, unless the force argument is given
# and is not 0, in which case we proceed with the removal.
#
# Returns 1 if the removal was successful.
#
# This is identical to Map's unlink.
#
SetMap method removeLinks {from {force 0}} {
	set sn "MAP_$from"

	while {[set sp [$self findSlot $sn]] != ""} {
		if {$sp == "$self"} {
			$self unslot $sn
			return 1
		} else {
			if {$force != 0} {
				$sp unslot $from
				return 1
			} else {
				switch [UserMsg okcancel "|$self unlink $from| Link $from not local, unlink from ancestor $sp?"] {
					ok {$sp unslot $sn}
					cancel {return 0}
				}
			}
		}
	}

	return 0
}

# For each $from object, execute the script in the level above,
# after setting the variables ``from`` and ``toList`` above.  This
# iterates over the entire Map.
#
SetMap method forEachLink {script} {
	foreach f [$self allPubSlots MAP_*] {
		upvar from fup
		upvar toList tup
		set fup [string range $f 4 end]
		set tup [$self slot $f]
		uplevel 1 $script
	}
}

# For the given $from, execute the script in the level above
# on each of the target items, using the variable ``to`` above.
#
SetMap method forEachLinkFrom {from script} {
	set sn "MAP_$from"
	set sp [$self findSlot $sn]
	if {$sp eq ""} return

	upvar to tup
	foreach tup [$self slot $sn] {
		uplevel 1 $script
	}
}

# Remove all the links for the entire map.
#
SetMap method removeAllLinks {} {
	foreach i [$self allPubSlots MAP_*] {
		$self unslot $i
	}
}

# Print for debugging
#
SetMap method print {} {
	foreach i [$self allPubSlots MAP_*] {
		puts "[string range $i 4 end]: [$self slot $i]"
	}
}
