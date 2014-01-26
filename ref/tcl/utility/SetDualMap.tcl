### A map from a pair of object names to sets. 
###
# PJM 2005-11-27	Created 

SetMap construct SetDualMap

# Add $to to the set of objects linked to from $from1
# and $from2
#
SetDualMap method addLink {from1 from2 to} {
	$self as [SetDualMap parent] addLink "$from1+$from2" $to
}

# Retrieve the list of targets from $from1 and $from2.  Return
# the null list if not present.
#
SetDualMap method getLinks {from1 from2} {
	return [$self as [SetDualMap parent] getLinks "$from1+$from2"]
}

# Return 1 if we have links for $from1 and $from2 (including inheritance),
# 0 otherwise.  We both look for the $from index to be present
# and count the number of targets if it is.
#
SetDualMap method hasLinks {from1 from2} {
	return [$self as [SetDualMap parent] hasLinks "$from1+$from2"]
}

# Return the number of links for $from1 and $from2.
#
SetDualMap method nLinks {from1 from2} {
	return [$self as [SetDualMap parent] nLinks "$from1+$from2"]
}

# Unlink a target, do nothing if not a link.  
#
SetDualMap method unlink {from1 from2 to} {
	return [$self as [SetDualMap parent] unlink "$from1+$from2" $to]
}

# Remove all the links from a $from object.  Ask the user
# if it's not a local link, unless the force argument is given
# and is not 0, in which case we proceed with the removal.
#
# Returns 1 if the removal was successful.
#
SetDualMap method removeLinks {from1 from2 {force 0}} {
	return [$self as [SetDualMap parent] removeLinks "$from1+$from2" $force]
}

# For each $from object, execute the script in the level above,
# after setting the variables from and toList above.  This
# iterates over the entire Map.
# DEFERRED
#
SetDualMap method forEachLink {script} {
	foreach f [$self allPubSlots MAP_*] {
		upvar from fup
		upvar toList tup
		set fup [string range $f 4 end]
		set tup [$self slot $f]
		uplevel 1 $script
	}
}

# For the given $from1 and $from2, execute the script in the level above
# on each of the target items, using the variable to above.
#
SetDualMap method forEachLinkFrom {from1 from2 script} {
	set sn "MAP_$from1+$from2"
	set sp [$self findSlot $sn]
	if {$sp eq ""} return

	upvar to tup
	foreach tup [$self slot $sn] {
		uplevel 1 $script
	}
}

# Print for debugging
#
SetDualMap method print {} {
	foreach i [$self allPubSlots MAP_*] {
		regexp {MAP_(.*)\+(.*)} $i -> a b
		puts "$a $b: [$self slot $i]"
	}
}
