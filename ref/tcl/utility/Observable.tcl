# A mixin providing part of the Observer pattern.
#
# PJM 2005-12-29	Created
# PJM 2006-02-12	All slots now private, since Observers are currently transient
# PJM 2006-07-23	Observer rewritten, no longer a mixin 

Mixin construct Observable

# Return the event SetMap in ``_obsEM``,
# creating it if necessary
#
Observable method get_obsEM {} {
	set em [$self slot _obsEM]
	if {$em eq ""} {
		set em [$self slot _obsEM [SetMap construct *]]
		$self addGoodbye lose_obsEm
	}

	return $em
}

# Clean up the event SetMap
#
Observable method lose_obsEM {} {
	Object safe [$self slot _obsEM] destruct
}

# Construct or update an Observer to observe this
# object for the given event (or pattern).  If
# an observer with the same client and event is
# already attached, update the code.
#
# We return the observer, new or not.
#
# When ``notifyObservers`` is called, each client
# will be sent a message of the form:
#``
#  $client $code $target $event $args
#``
# where the target is the Observable and the args are
# those appended to the ``notifyObservers`` message.
#
Observable method addObserver {event client code} {
	set em [$self get_obsEM]

	set obs ""

	$em forEachLinkFrom $event {
		if {[$to slot client] eq $client} {
			$to slot code $code
			set obs $to
		}
	}

	# We didn't find an existing Observer, make one
	if {$obs eq ""} {set obs [Observer new $client $self $event $code]}

	return $obs
}

# Remove client from the list of observers for the given
# event
#
Observable method deleteObserver {event client} {
	set em [$self get_obsEM]

	$em forEachLinkFrom $event {
		if {[$to slot client] eq $client} {
			$to destruct
		}
	}
}

# Delete all observers 
#
Observable method deleteObservers {} {
	set em [$self get_obsEM]

	$em forEachLink {
		foreach to $toList {
			$to destruct
		}
	}
}

# Notify all the observers interested in the given
# event, then all observers interested in all events
#
# Return the number of observers notified.
#
Observable method notifyObservers {event args} {
	set em [$self get_obsEM]
	set os 0

	$em forEachLinkFrom $event {
		eval $to execute $event $args
		incr os
	}
	
	$em forEachLinkFrom * {
		eval $to execute $event $args
		incr os
	}

	return $os
}

# List all the observers interested in the given
# event or event pattern.  If no arg is given,
# list all observers.
#
Observable method listObservers {args} {
	set em [$self get_obsEM]
	set out {}

	if {[llength $args] == 0} {
		$em forEachLink {
			foreach to $toList {
				lappend out [list $from [list [$to slot client] [$to slot code]]]
			}
		}
	} else {
		$em forEachLinkFrom [lindex $args 0] {
			lappend out [list [$to slot client] [$to slot code]]
		}
	}

	return $out
}
