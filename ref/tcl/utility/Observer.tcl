# Observers used to be a mixin, now they're
# distinct objects containing the state for
# the execution of a command that should occur
# when an Observable changes. 
#
# An Observer consists of the observing client,
# a pattern matching the events it's interested
# in, and the code to execute.  The resulting
# invocation is ``client code target event``.
#
# Note that the only event pattern supported is ``*``
# --it's not clear if more sophisticated patterns
# are worth the effort.
#
# PJM 2005-12-29	Created
# PJM 2006-07-23	No longer a mixin

Object construct Observer


# Construct a new Observer and return it
#
# We also add a goodbye script to the client
# to clean up all Observers.  
#
Observer method new {client target event code} {
	set kid [$self construct *]

	$kid slot client $client
	$kid slot target $target
	$kid slot event $event
	$kid slot code $code

	if {![$client slotContains _obsC $kid]} {
		$client slotAppend _obsC $kid
		$client addGoodbye [list Observer unobserveAll $client]
	}

	[$target get_obsEM] addLink $event $kid

	return $kid
}

# When an Observer is destroyed, remove it from
# the client and target lists
#
Observer method destruct {} {
	Object safe [$self slot client] slotRemove _obsC $self

	set t [$self slot target]
	if {[Object exists $t]} {
		set em [$t slot _obsEM]
		$em unlink [$self slot event] $self
	}

	$self as Object destruct
}

# Invoke an Observer
#
Observer method execute {event args} {
	poetvar $self client target

	if {[$client slotSearch _obs_ignore $target] >= 0} return

	eval $client [$self slot code] $target $event $args
}

# Perform an operation while ignoring a target
#
Observer method ignore {client target op} {
	$client slotAppend _obs_ignore $target

	uplevel $op

	$client slotRemove _obs_ignore $target
}

# Stop observing everything for a client.  If an argument is provided,
# only Observers where the target is a descendant of that object are removed
#
Observer method unobserveAll {client {obj ""}} {
	set x ""

	foreach o [$client slot _obsC] {
		if {[Object exists $o]} {
			set t [$o slot target]

			if {$obj == "" || ![Object exists $t] || [$t isA $obj]} {
				$o destruct
			} else {
				lappend x $o
			}
		}
	}

	$client slot _obsC $x
}

# List all the objects that the client is observing. If an argument is provided,
# only Observers where the target is a descendant of that object are listed.
#
Observer method listObserved {client {obj ""}} {
	set out [list]

	foreach o [$client slot _obsC] {
		if {[Object exists $o]} {
			set t [$o slot target]

			if {$obj == "" || ![Object exists $t] || [$t isA $obj]} {
				lappend out $t [$o slot event] [$o slot code]
			}
		}
	}

	return $out
}

# Count all the objects that the client is observing. If an argument is provided,
# only Observers where the target is a descendant of that object are listed.
#
Observer method countObserved {client {obj ""}} {
	foreach o [$client slot _obsC] {
		if {[Object exists $o]} {
			set t [$o slot target]

			if {$obj == "" || ![Object exists $t] || [$t isA $obj]} {
				set out($t) 1
			}
		}
	}

	return [array size out]
}
