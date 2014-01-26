### A wave travelling through thyrdspace.  Each wave consists of
### three data stacks (A, B, and Y) and a code stack (called X,
### for eXecution). All data on the stacks are Cells, created by and
### belonging to the wave if necessary.  The contents of the X stack 
### may be Opcodes, Cells, or a mixture of both.  
###
### Waves travel through thyrdspace or are captive and used by
### Thyrd itself.  In either case a wave can be bidirectional,
### in which case the stacks unA, unB, unY, and unX are used
### to maintain the info needed to undo an operation.  When
### travelling, execution proceeds in the direction of the
### ``next`` route.  When captive, the owner pushs opcodes
### for execution.  One captive wave is used by the Space
### for undo/redo support.
###
### When a travelling wave is constructed, it is given a starting 
### cell and an anchor cell.  The starting cell should be a grid cell,
### the first (1 1) cell of the grid is the first executed (i.e., the
### grid is unquoted). The anchor cell may be anything and may end up either
### atomic or with a grid. If the wave is a formula, the anchor cell
### is the result. If anything is left on the selected stack when 
### the wave ends, it is popped stored in the anchor cell. Any cells
### accessed during the execution will be watched, when they change
### a recalculation of the result will be queued. If the wave is an
### event, the anchor cell is the input, and the code will be executed
### whenever the input value changes. No other cells will be watched,
### only a change in the input triggers execution. Any leftover value
### is placed back in the anchor cell, so an event can act as a validator.
### It's also possible to ask for the anchor cell via an opcode and 
### modify it directly (or repeatedly).
###
### A cell of type ``Opcode`` causes its contents to be executed, all 
### other cells are pushed onto the currently active stack. Quotation
### is acheived by wrapping code in a Grid.
###
### This object has both a construct and a new method, 
### construct is for raw construction (as when loaded
### from persistent storage) and new is for normal use.
###
### Note that the X and unX stacks are monitored, they should not
### be accessed directly: use pushX, etc.
###
### The Wave object holds a global flag, ``enable``, which, if false,
### causes flowing waves to break and not queue up the next step.  This
### is controlled by the Start/Stop button in the toolbox.
###
### Travelling waves are activated by calling ``start`` and stopped
### via ``suspend``. 
###
### Possible states of a Wave:
### ``
###		flowing		Executing cells forward
###		end			Execution is complete
###		break		Wave paused, waiting for user
###		error		Last op caused an error
###		confused	Shouldn't happen, something's wrong internally
###		captive		not free-flowing, used by undo/redo
### ``
###
### Observer messages from Wave:
### ``
###		new					wave just loaded or entirely changed 
###		start				a wave has started (wave in args)
### ``
###
### Observer messages from Wave children:
### ``
###		step				a step has occurred
###		destruct			wave about to destruct
### 	state 				state has changed 
###		xevent				the status of the X/unX stacks have changed
### ``
#
# PJM 2006-03-30	Created
# PJM 2007-07-23	Complete revision for Opcode 
# PJM 2007-08-01	Mods for endcode begun
# PJM 2007-08-30	Bidirectional waves begun
# PJM 2008-01-31	The contents of the stacks are now all cells, not values
# PJM 2008-04-14	Ebbing not the right approach, instead we take a step back
#					but stay in flowing mode. Ebbing code that remains is
#					vestigial but may we resurrected if we ever want a wave to
#					continuously flow backwards.
# PJM 2008-04-22	Attempt to make Waves constrainable failed disasterously.
#					All wave methods invoked from Op* would have to be designated
#					as side effects.
# PJM 2008-06-06	Work on version that does not use Poet constraints to trigger
#					evaluation begun. Last constraint-based version saved as v0.1.1.
#					Any code having to do with ebbing, or flowing backwards, is also
#					in that version of this file.
# PJM 2008-06-11	Observer-based waves seem to work. Removing persistence from
#					flowing waves (captive waves were always volatile). Since a
#					wave gets reset as soon as an edit takes place, it does seem like
#					making them persist is useful.
# PJM 2008-06-18	Start cell is now required to be a grid, we start with its (1 1)
# PJM 2008-11-23	Added dirty flag
# PJM 2008-11-28	Added _waveCells, managed by Cell newInWave. We don't assume the
#					cells listed in _waveCells exist, we just destroy them if they do.
# PJM 2008-12-17	Revised to implement event waves
# PJM 2008-12-18	We now retain the path to the start and anchor cells we're created
#					with and use them to refind the cells each time we're reset.
# PJM 2009-02-10	substack added. This removed the end parameter from ``flow`` and
#					``step``.
# PJM 2009-02-15	support for continuable ops begun. Phasing out ``subroutine`` in
#					favor of ``startSub``
# PJM 2009-02-16	Operations are now responsible for returning a list of cells to
#					push on the X stack. Most ops return "", but this is the basis
#					of the new combinators implementation.
#

Object construct Wave
Wave mixin Observable

# Master control flag that enables automatic queuing of next step
# in all Waves
#
Wave slot enable 0
Wave type enable <boolean>

# What type of wave this is
#
Wave slot wavetype formula
Wave type wavetype "<choice> captive event formula"

# The current state of the wave. Note that all waves
# cause Wave to trigger a state event, so we just need
# to observe Wave to watch all state changes.
#
Wave slot> state "suspended" {Wave notifyObservers state}
Wave type state "<choice> flowing end break error confused captive"

# The subroutine stack. If empty, we're at the top level,
# otherwise it contains a stack of markers that we're looking
# for (we should only ever find the top item on the substack).
#
Wave slot substack ""

# Indicates whether this wave is bidirectional or not
Wave slot bidi 0
Wave type bidi <boolean>

# Indicates that a change occurred while the wave was
# flowing and it needs to be restarted.
#
Wave slot dirty 0
Wave type dirty <boolean>

# Inhibits setting of the dirty bit
#
Wave slot ignore 0
Wave type ignore <boolean>

# The starting and anchor cells
#
Wave slot start ""
Wave type start Cell
Wave slot anchor ""
Wave type anchor Cell

# A cell containing the route to get to the next cell to be
# executed
#
Wave slot next ""
Wave type next Cell

# A cell containing the route to get to the previous cell to be
# executed.  Should be the opposite of next, but nothing enforces
# that.
#
Wave slot prev ""
Wave type prev Cell

# If true, this wave is being stepped by an observer
# and we should not automatically queue an event for the
# next step.
#
Wave slot stepping 0
Wave type stepping <boolean>

# If true, this wave is being microstepped by an observer
# and we should not automatically queue an event for the
# next step in a subroutine.
#
Wave slot microstepping 0
Wave type microstepping <boolean>

# Construct a new wave, making it persistent. NOTUSED
#
Wave method constructPERSISTENT {{child @}} {
	set kid [$self as [Wave parent] construct $child]
	$kid mixin Thing

	return $kid
}

# Construct a new travelling wave with empty stacks starting at
# the given cell. This does not start it executing,
# that's done by calling ``start``.  
# 
# The start cell is required to be a grid, its ``1`` cell
# is the first executed cell. This unquotes the grid cell.
# It also makes it possible to start with an empty program.
#
# By default, we create a bidirectional wave.
# No longer persistent.
#
# If no anchor cell is provided, we create one that'll get 
# destroyed when the wave gets destroyed.
#
# Note: ``newCaptive`` is used to make captive waves,
# so we assume ``which`` is formula or event here.
#
Wave method new {cc ac {which "formula"} {bidi ""}} {
	if {[$cc atomic]} {
		UserMsg error "|$self new $cc $ac $bidi| Code cell must be a grid (it may be empty)"
		return
	}

	if {$bidi eq ""} {
		set bidi $::THYRD_BIDI_DEFAULT
	}

	set kid [$self construct w*]

	$kid slot wavetype $which

	set n [$kid slot next [Cell new]]
	$n as CMRoute setRoute "+1" "-* +1"

	set p [$kid slot prev [Cell new]]
	$p as CMRoute setRoute "-1" "+* -1"

	$kid slot startPath [$cc path]

	if {$ac eq ""} {
		$kid slot anchorPath ""
	} else {
		$kid slot anchorPath [$ac path]
	}


	$kid slot bidi $bidi
	$kid reset

	Wave notifyObservers new $kid

	return $kid
}

# Construct a new captive wave, as used by CellEditor.
#
# It's possible to make a unidirectional captive wave,
# but that's not the normal usage.
#
Wave method newCaptive {{bidi 1}} {
	set kid [$self construct c*]

	$kid slot bidi $bidi
	$kid slot wavetype captive
	$kid slot state captive
	$kid reset
	Wave notifyObservers new $kid
	return $kid
}

# Override Thing_postload to cause the contents of
# the stacks to be loaded.
#
# NOTUSED no longer persistent
#
Wave method Thing_postload {} {
	foreach s [list A B Y X unA unB unY unX] {
		foreach c [$self slot $s] {
			catch {$c noop}
		}
	}

	[$self slot next] noop
	[$self slot prev] noop

	$self as Thing Thing_postload
	Wave notifyObservers new $self
	$self notifyObservers xevent [$self slotLength X] [$self slotLength unX]
}

# Destroy a Wave 
#
Wave method destruct {} {
	$self notifyObservers destruct

	$self _cleanse

	set ac [$self slot anchor]
	if {[Object exists $ac]} {
		if {[$ac isIn $self]} {$ac destruct}
	}

	Object safe [$self slot next] destruct
	Object safe [$self slot prev] destruct

	# _waveCells lists our cells that might still exist
	foreach c [$self slot _waveCells] {catch {$c destruct}}

	$self as Object destruct
}

# Return true if this wave is of the given type
#
Wave method is {which} {
	return [string match $which [$self slot wavetype]]
}

# Return true if this wave is bidirectional
#
Wave method isBiDi {} {
	return [$self slot bidi]
}

# Execute the given message on self if bidirectional
#
Wave method ifBiDi {args} {
	if {[$self slot bidi]} {
		return [$self {*}$args]
	} else {
		return ""
	}
}

# Enable bidirectional control flow
#
Wave method enableBiDi {} {
	$self slot bidi 1

	$self slot unA [list]
	$self slot unB [list]
	$self slot unY [list]
	$self slot unX [list]
	$self notifyObservers xevent [$self slotLength X] [$self slotLength unX]
}

# Disable undo, or bidirectional control flow
#
Wave method disableUndo {} {
	$self slot bidi 0

	$self _cleanse past
	$self unslot unA
	$self unslot unB
	$self unslot unY
	$self unslot unX
	$self notifyObservers xevent [$self slotLength X] [$self slotLength unX]
}

# Invoked when the wave has run to completion
# 
# If there's no anchor cell, the wave is left alone. If
# there's nothing left on the stack, the anchor cell is
# left alone. 
#
# If this is an event wave and we set the anchor as a
# result, we clear the dirty bit.  Note that, in an
# event wave, the anchor must be atomic and we don't
# set it if the top of the stack isn't.
#
# If the wave got marked as dirty, start it again.
#
# We set ``_ending`` to make sure we don't execute 
# multiple times when invoked from a subroutine.
# ``flow`` clears it.
#
Wave method _end {} {
	if {[$self slot _ending]} return
	$self slot _ending 1

	set state [$self slot state]

	switch $state {
		end {

			set ac [$self slot anchor]
			if {$ac ne ""} {
				set ans [$self popCell]
				if {$ans ne ""} {
					set isEvent [$self is event]

					if {$isEvent} { 
						$self slot ignore 1 
					}

					if {[$ans atomic]} {
						if {![$ac atomic]} {$ac empty}
						$ac setFrom $ans
					} else {
						if {$isEvent} {
							UserMsg warning "|$self end| Top of the stack is not atomic, can't use it to set an event anchor"
						} else {
							$ac empty
							[theSpace pasteFrame $ans $ac i 0] destruct
							[theSpace pasteFrame $ans $ac j 1] destruct
							[theSpace paste $ans $ac] destruct
						}
					}

					if {$isEvent} {
						$self slot dirty 0
						$self slot ignore 0 
					}
				}
			}
		}
		error {
			UserMsg error "|$self end| Error: [$self slot error]"
		}
		break {
			UserMsg error "|$self end| Break: [$self slot error]"
		}
		default {
			UserMsg error "|$self end| $state: [$self slot error]"
		}
	}

	$self notifyObservers step

	if {[$self slot dirty]} {
		$self slot _afterID [after idle [list after 0 $self restart]]
	}
}

# Return true if this wave starts at the given cell.
#
Wave method startsAt {cc} {
	return [expr {$cc eq [$self slot start]}]
}

# Reset a wave to its initial conditions. We assume wavetype
# doesn't get changed anywhere.
#
Wave method reset {} {
	$self _cleanse

	$self slot start [theSpace find [$self slot startPath]]
	set ac [$self slot anchor [theSpace find [$self slot anchorPath]]]
	if {$ac eq ""} {
		$self slot anchor [Cell newInWave $self ""]

	}

	$self slot dirty 0

	$self slot substack [list]

	$self slot A [list]
	$self slot B [list]
	$self slot Y [list]
	$self slot X [list]

	if {[$self slot bidi]} {
		$self slot unA [list]
		$self slot unB [list]
		$self slot unY [list]
		$self slot unX [list]
	} else {
		$self unslot unA
		$self unslot unB
		$self unslot unY
		$self unslot unX
	} 

	$self slot stack A
	$self slot currentOp ""
	$self slot stepping 0
	$self slot error ""
	$self slot _ending 0

	switch [$self slot wavetype] {
		captive {
			$self slot state captive
		} 
		formula {
			$self slot state flowing
			set s [$self slot start]
			if {$s ne ""} {
				$self watch $s
				$self pushX [$s subCell 1]
			}
		}
		event {
			$self slot state flowing
			$self watch [$self slot anchor]

			set s [$self slot start]
			if {$s ne ""} {
				$self pushX [$s subCell 1]
			}
		}
	}

	$self notifyObservers xevent [$self slotLength X] [$self slotLength unX]
}

# Clear out the future (A, B, X, and Y stacks).
# Used by the editbar to clear out the redo when
# the user does something.
#
Wave method clearFuture {} {
	$self _cleanse future

	$self slot A [list]
	$self slot B [list]
	$self slot Y [list]
	$self slot X [list]

	$self slot currentOp ""

	$self notifyObservers xevent [$self slotLength X] [$self slotLength unX]
	$self notifyObservers step
}

# Clean out any buffer cells we might have acquired.
# We're about to destroy the relevant stacks. We can
# clean out the past, the future, or both.
#
# We also clear the x status for any cells left on the
# X stack.
#
# If we're cleansing both, we also unobserve all cells.
#
Wave method _cleanse {{which both}} {
	if {$which eq "both"} {
		Observer unobserveAll $self Cell
	}

	set stacks [list]

	if {$which in {both future}} {
		lappend stacks A B X Y 
		
		foreach c [$self slot X] {
			if {[Object existsAs $c Cell]} {
				$c xstatus 0
				$c paused 0
			}
		}
	}

	if {$which in {both past}} {
		lappend stacks unA unB unX unY
	}

	foreach stack $stacks {
		foreach c [$self slot $stack] {
			$self _freeCell $c
		}
	}
}

# Given a cell, if it belongs to this wave free it.
#
Wave method _freeCell {c} {
	if {[Object exists $c] && [$c slot container] eq $self} {
				$c destruct
	}
}

# Start or restart a wave flowing.  If we're not being watched, take the first step.
#
# If notNow is set, just enter the end state (used when starting event waves).
# Unless we're already dirty, in which case we start up.
#
Wave method start {{notNow 0}} {
	if {$notNow && ![$self slot dirty]} {
		$self slot state end
		return
	}

	$self slot state flowing

	set os [+ [Wave notifyObservers start $self] [$self notifyObservers step]]
	if {$os == 0} {
		$self slot _afterID [after idle [list after 0 $self flow]]
	}
}

# Stop queuing new steps.
#
Wave method suspend {} {
	after cancel [$self slot _afterID]
	$self slot state break
}

# The wave needs to be restarted, mark it as dirty.
# The args are ignored (this is an Observer
# callback). If our state is "end", we queue the
# restart now.
#
# We now use ``ignore`` to allow setting of cells
# without triggering a mark.
#
Wave method markAsDirty {args} {
	if {[$self slot ignore]} return
	if {[$self slot dirty]} return

	$self slot dirty 1

	if {[$self slot state] in {end}} {
		$self slot _afterID [after idle [list after 0 $self restart]]
	}
}

# Restart a wave from scratch
# If the big switch is off, just reset, don't start.
#
Wave method restart {args} {
	$self reset

	if {[Wave slot enable]} {
		$self start
	}
}

# Start observing the given cell. If it's a grid, recurse
# through its contents.
#
Wave method watch {c} {
	if {$c eq ""} return

	if {![$c isA Cell]} return

	if {[$c atomic]} {
		foreach e {write destruct newPlace} {
			$c addObserver $e $self markAsDirty
		}
	} else {
		foreach e {gainSub loseSub destruct newPlace} {
			$c addObserver $e $self markAsDirty
		}

		foreach {wi wj} [$c as CMGrid walk full] {
			set wc [$c as CMGrid getCell $wi $wj]
			if {$wc ne ""} {
				$self watch $wc
			}
		}
	}
}

# Tell this wave that it might want to watch a cell.
# Event waves don't like to watch.
#
Wave method mightWatch {c} {
	if {[$self is event]} return

	$self watch $c
}

set stopHere 0

# Take a step forward by executing the current step and
# pushing the next cell to visit, if we're still flowing.
#
# If ``end`` is provided, it's the Poet name of an end
# marker that we treat as the same as an empty X stack.
# This is how ``subroutine`` works.
#
# The ``end`` parameter has been removed, we now maintain
# a stack of end markers called substack. The end we're
# looking for is the top of the substack.
#
Wave method step {} {
	set state [$self slot state]
	if {$state eq "break"} return

	set cap [$self is captive]
	set end [$self slotPeek substack]

	set x [$self popX]
	$self slot currentOp $x
	if {[$self is formula]} {$self watch $x}

	set next [$self _execute $x 1] 
	set state [$self slot state]

	# If this is a captive wave, flowing means we're OK,
	# go back to captive. Otherwise, let the error state
	# be handled below.
	#
	if {$cap && $state eq "flowing"} {
		set state [$self slot state captive]
		$self notifyObservers step
		return $state
	}

	# Deal with the resulting state, usually by finding the next
	# cells to execute if the op didn't provide us with some.
	#
	switch $state {
		break -
		flowing {
			if {$next ne ""} {
				foreach n $next {$self pushX $n}
			} else {
				while {[$self slotLength X] > 0} { 
					set nX [$self slotPeek X]
					set eos [? {$end ne "" && $end eq $nX}]  ;# end of subroutine
					if {!$eos} break

					set n [[$self slot next] as CMRoute apply $x]
					if {$n ne ""} {
						$self pushX $n
						break
					} else {
						$self popX
						$self slotPop substack
						set end [$self slotPeek substack]
					}
				}

				if {[$self slotLength X] == 0} { ;# X stack empty
					set n [[$self slot next] as CMRoute apply $x]
					if {$n eq ""} {
						$self pushX [Cell newInWave $self end Opcode]
					} else {
						$self pushX $n
					}
				}
			} 
		} 
		error {
			UserMsg error "|$self step $end|Error in wave: [::Poet::parseError [$self slot error]]"
		}
		end {
			$self _end 
		}
	}

	$self notifyObservers step
	return [$self slot state]
}

# Begin executing the given cell as a subroutine. If the op
# doesn't need to do anything with the result, it can use
# this instead of ``subroutine``.
#
# NOTUSED  not quite right any more either
#
Wave method startSub {c} {
	set end [Cell newInWave $self [OpEnd slot opcode] Opcode]
	$self slotPush substack $end
	$self pushX $end
	$self pushX [$c subCell 1 1]
}

# Execute the given cell as a subroutine. This does not return
# until all of the subroutine has executed and is deprecated
# in favor of startSub.
#
# NOTUSED
#
Wave method subroutine {c} {
	set end [Cell newInWave $self [OpEnd slot opcode] Opcode]
	$self slotPush substack $end
	$self pushX $end
	$self pushX [$c subCell 1 1]

	while {[$self peek X] ne $end} {
		switch [$self step] {
			confused -
			error {
				UserMsg error "|$self subroutine $c| Error in subroutine: [$self slot error]"
			}
			break {
				idebug break
			}
		}

		update idletasks
	}

	$self popX
	$self slotPop substack
}

# Take a step backward. We stay in the same state (which should
# be flowing).  
#
Wave method stepBack {} {
	set x [$self slotPop unX]
	$self notifyObservers xevent [$self slotLength X] [$self slotLength unX]
	if {$x eq ""} return

	#set oldx [$self popX]  don't want this for captive, at least

	$self slot currentOp $x
	set next [$self _execute $x 0]
	set state [$self slot state]

	# If this is a captive wave, flowing means we're OK,
	# go back to captive. Otherwise, let the error state
	# be handled below.
	#
	if {[$self is captive] && $state eq "flowing"} {
		$self slot state captive
		$self pushX $x
	} else {
		switch $state {
			flowing {
				$self pushX $x
			}
		}
	}

	$self notifyObservers step
}

# Start taking steps, queuing the next step if we're still
# flowing, unless we're being stepped by an observer or enable is off
#
Wave method flow {} {
	$self slot _ending 0
	set state [$self step]

	if {$state eq "flowing" && [Wave slot enable] && ![$self slot stepping]} {
		$self slot _afterID [after idle [list after 0 $self flow]]
	}
}


# Execute one cell or opcode, returning the next list. We either 
# do or undo the opcode, depending on what direction we're going.
#
# Note: this still supports opcodes, even though everything
# should be a cell now.
#
Wave method _execute {x {forward 1}} {
	set next ""

	if {$x eq ""} {
		$self slot state end
	} elseif {[Object existsAs $x Op]} {
		set next [$self _do $x $forward]
	} elseif {![Object existsAs $x Cell]} {
		$self slot state confused
	} else {
		$self slot state flowing

		switch [$x getType] {
			Grid {
				$self pushCell $x
			}
			Opcode {
				set next [$self _do [[$x slot core] slot op] $forward]
			}
			default {
				$self pushCell $x
			}
		}
	}

#debug "_execute $x returning |$next| in state [$self slot state]"
	return $next
}

# Perform an operation, either forward or backward.
# We set the slot ``state`` and return the list of
# cells to be pushed onto the X stack (the result of
# ``doOp`` or ``undoOp``).
#
Wave method _do {op forward} {
	if {$op eq ""} {
		return [$self slot state confused]
	}

	$self slot error ""
	
	# Invoke operation on this wave and
	# handle TCL_ERROR, TCL_RETURN, and TCL_BREAK
	#
	set res [catch {$op [? $forward doOp undoOp] $self} next opts]

	switch $res {
		1 {
			$self slotAppend error " ([dict get $opts -errorinfo])"
			$self slot state error
		}
		2 {$self slot state end}
		3 {$self slot state break}
	}

	return $next
}

# Execute an op and push it onto the unX stack.
# The op gets put in a cell that belongs
# to this wave. This is used only with the
# captive editing wave.
#
Wave method execOp {op} {
	$self _do $op 1

	$self slotPush unX [Cell newInWave $self [$op slot opcode] Opcode]
	if {[$self slot state] eq "flowing"} {
		$self slot state captive
	}

	$self notifyObservers step
	$self notifyObservers xevent [$self slotLength X] [$self slotLength unX]

	return [$self slot state]
}

# Return the current subroutine depth
#
Wave method subDepth {} {
	return [$self slotLength substack]
}

###
### Methods used by opcodes
###

# Create a new cell containing an end opcode, push it on
# the substack and return it.
#
Wave method newEnd {} {
	set end [Cell newInWave $self [OpEnd slot opcode] Opcode]
	$self slotPush substack $end
	return $end
}

# Return the next cell to execute after the currentOp 
#
Wave method getNext {} {
	return [[$self slot next] as CMRoute apply [$self slot currentOp]]
}

# Push cells on the given stack.  If the stack is
# "", use the selected stack.
#
Wave method pushCells {s args} {
	if {$s eq ""} {set s [$self slot stack]}

	foreach a $args {	
		$self slotPush $s $a
	}

	return $a
}

# Push one cell on the current stack
#
Wave method pushCell {c} {
	$self slotPush [$self slot stack] $c
	return $c
}

# Push one cell on the current unstack
#
Wave method pushUnCell {c} {
	$self slotPush un[$self slot stack] $c
	return $c
}

# Push the anchor cell. If this is an unsituated
# (captive) wave, we do so on the unstack.
#
Wave method pushAnchor {c} {
	if {[$self is captive]} {
		$self slotPush un[$self slot stack] $c
	} else {
		$self slotPush [$self slot stack] $c
	}
	return $c
}

# Pop the anchor cell to a variable. If this is an unsituated
# (captive) wave, we do so from the unstack.
#
# Return 1 if successful.
#
Wave method popAnchorToVar {var} {
	if {[$self is captive]} {
		set stack un[$self slot stack]
	} else {
		set stack [$self slot stack]
	}

	if {[$self slotLength $stack] < 1} {return 0}

	uplevel [list set $var [$self slotPop $stack]]
	
	return 1
}

# Pop a cell from the unstack to a var.
#
Wave method popUnstackToVar {var} {
	set stack un[$self slot stack]

	if {[$self slotLength $stack] < 1} {return 0}

	uplevel [list set $var [$self slotPop $stack]]
	
	return 1
}

# Push one or more values onto the current stack and return 
# the last one.  Each value gets put in a cell that belongs
# to this wave.
#
Wave method push {args} {
	set s [$self slot stack]
	foreach a $args {
		$self slotPush $s [Cell newInWave $self $a]
	}
	return $a
}

# Push one or more integer values onto the current stack and return 
# the last one.  Each value gets put in a cell that belongs
# to this wave.
#
Wave method pushInts {args} {
	set s [$self slot stack]
	foreach a $args {
		$self slotPush $s [Cell newInWave $self $a <integer>]
	}
	return $a
}

# Push one or more real values onto the current stack and return 
# the last one.  Each value gets put in a cell that belongs
# to this wave.
#
Wave method pushReals {args} {
	set s [$self slot stack]
	foreach a $args {
		$self slotPush $s [Cell newInWave $self $a <real>]
	}
	return $a
}

# Push one or more values of the given types onto the current stack 
# and return the last one.  The args should be each be a list containing
# a value and a type. Each value gets put in a cell that belongs
# to this wave.
#
Wave method pushTyped {args} {
	set s [$self slot stack]
	foreach a $args {
		lassign $a v t
		$self slotPush $s [Cell newInWave $self $v $t]
	}
	return $a
}

# Push one or more values of the given types onto the given stack 
# and return the last one.  The args should be each be a list containing
# a value and a type. Each value gets put in a cell that belongs
# to this wave.
#
Wave method pushTypedOnStack {stack args} {
	foreach a $args {
		lassign $a v t
		$self slotPush $stack [Cell newInWave $self $v $t]
	}
	return $a
}

# Push one or more values onto the given stack and return 
# the last one
#
Wave method pushOn {s args} {
	foreach a $args {
		$self slotPush $s [Cell newInWave $self $a]
	}
	return $a
}

# Push one or more ops onto the X stack and return 
# the last one.  Each op gets put in a cell that belongs
# to this wave.
#
Wave method pushOps {args} {
	foreach a $args {
		$self pushX [Cell newInWave $self [$a slot opcode] Opcode]
	}

	return $a
}

# Pop a cell off the given stack.  If the stack
# is not provided, use the selected stack.
#
Wave method popCell {{stack ""}} {
	if {$stack eq ""} {set stack [$self slot stack]}

	set c [$self slotPop $stack]
	return $c
}

# Pop the current stack value and return it.  If
# the containing cell is a wave cell, deallocate it.
#
# If a stack is provided, use that.
#
Wave method pop {{stack ""}} {
	set c [$self popCell $stack]
	if {$c eq ""} {return ""}

	if {[$c atomic]} {
		set v [$c get]
	} else {
		set v ""
	}

	if {[$c isIn $self]} {$c destruct}

	return $v
}

# Given a list of variable names, pop that many
# cells off the given stack and set each of the
# variables in the context above.  The last item 
# on the list is the first thing popped.
#
# Return 1 if successful. If no args are provided,
# it's not an error.
#
Wave method popStackToVars {stack args} {
	if {$stack eq ""} {set stack [$self slot stack]}

	set nv [llength $args]

	if {$nv == 0} {return 1}
	if {$nv > [$self slotLength $stack]} {return 0}

	for {incr nv -1} {$nv >= 0} {incr nv -1} {
		uplevel [list set [lindex $args $nv] [$self pop $stack]]
	}
	
	return 1
}

# Given a list of variable names, pop that many
# cells off the current stack and set each of the
# variables in the context above.  The last item 
# on the list is the first thing popped.
#
# Return 1 if successful. If no args are provided,
# it's not an error.
#
Wave method popCellsToVars {args} {
	set stack [$self slot stack]
	set nv [llength $args]

	if {$nv == 0} {return 1}
	if {$nv > [$self slotLength $stack]} {return 0}

	for {incr nv -1} {$nv >= 0} {incr nv -1} {
		uplevel [list set [lindex $args $nv] [$self slotPop $stack]]
	}
	
	return 1
}

# Given a list of variable names, pop that many
# values off the current stack and set each of the
# variables in the context above.  The last item 
# on the list is the first thing popped.
#
# Return 1 if successful. If no args are provided,
# it's not an error.
#
# If the cell we're popping off belongs to this
# wave, destroy it.
#
Wave method popValuesToVars {args} {
	set stack [$self slot stack]
	set nv [llength $args]

	if {$nv == 0} {return 1}
	if {$nv > [$self slotLength $stack]} {return 0}

	for {incr nv -1} {$nv >= 0} {incr nv -1} {
		set c [$self slotPop $stack]
		uplevel [list set [lindex $args $nv] [$c get]]
		$self _freeCell $c
	}
	
	return 1
}

# Peek at the top of the current stack and return the cell.
#
# If a stack is provided, use that.
#
Wave method peek {{stack ""}} {
	if {$stack eq ""} {set stack [$self slot stack]}
	return [$self slotPeek $stack]
}

# Peek at the top of the current unstack value and return it. 
#
Wave method peekUn {} {
	set stack un[$self slot stack]
	return [$self slotPeek $stack]
}

# Return the unversion of the current stack 
#
Wave method unstack {} {
	return un[$self slot stack]
}

# Pops cells off the stack and pushes them onto the unstack,
# if bidi, copying the values of the cells to variables in the
# level above.
#
Wave method shiftValuesToVars {args} {
	set nv [llength $args]
	if {$nv == 0} {return 1}

	poetvar $self bidi stack
	if {$nv > [$self slotLength $stack]} {return 0}

	set u un$stack

	for {incr nv -1} {$nv >= 0} {incr nv -1} {
		set c  [$self slotPop $stack]
		uplevel [list set [lindex $args $nv] [$c get]]

		if {$bidi} {
			$self slotPush $u $c
		} else {
			if {[$c isIn $self]} {$c destruct}
		}
	}
	
	return 1
}

# Like shiftValuesToVars, but goes from unstack to normal stack
# (must be bidi)
#
Wave method unshiftValuesToVars {args} {
	set nv [llength $args]
	if {$nv == 0} {return 1}

	poetvar $self bidi stack
	set u un$stack

	if {$nv > [$self slotLength $u]} {return 0}

	for {incr nv -1} {$nv >= 0} {incr nv -1} {
		set c  [$self slotPop $u]
		uplevel [list set [lindex $args $nv] [$c get]]

		$self slotPush $stack $c
	}
	
	return 1
}

# Shift n items from the un stack onto the current
# stack
#
Wave method unshift {n} {
	set s [$self slot stack]
	set u un$s

	for {set i 0} {$i < $n} {incr i} {
		$self slotPush $s [$self slotPop $u]
	}
}

# Shift n items from the un version of the given stack onto the 
# given stack
#
Wave method unshiftStack {stack n} {
	set u un$stack

	for {set i 0} {$i < $n} {incr i} {
		$self slotPush $stack [$self slotPop $u]
	}
}

# Like shiftValuesToVars, but the upvars end up with cell ids
# rather than cell contents.
#
Wave method shiftCellsToVars {args} {
	set nv [llength $args]
	if {$nv == 0} {return 1}

	poetvar $self bidi stack
	if {$nv > [$self slotLength $stack]} {return 0}

	set u un$stack

	for {incr nv -1} {$nv >= 0} {incr nv -1} {
		set c  [$self slotPop $stack]
		uplevel [list set [lindex $args $nv] $c]

		if {$bidi} {
			$self slotPush $u $c
		} else {
			if {[$c isIn $self]} {$c destruct}
		}
	}
	
	return 1
}

# Unshift cells from unstack to normal stack, storing
# cell ids (not contents) in upvars.
# (must be bidi)
#
Wave method unshiftCellsToVars {args} {
	set nv [llength $args]
	if {$nv == 0} {return 1}

	poetvar $self stack
	set u un$stack

	if {$nv > [$self slotLength $u]} {return 0}

	for {incr nv -1} {$nv >= 0} {incr nv -1} {
		set c  [$self slotPop $u]
		uplevel [list set [lindex $args $nv] $c]

		$self slotPush $stack $c
	}
	
	return 1
}

# Like shiftCellsToVars, but only one cell is shifted, and
# the stack is specified.
#
Wave method shiftCellFromStackToVar {stack var} {
	poetvar $self bidi 
	if {1 > [$self slotLength $stack]} {return 0}

	set u un$stack

	set c  [$self slotPop $stack]
	uplevel [list set $var $c]

	if {$bidi} {
		$self slotPush $u $c
	} else {
		if {[$c isIn $self]} {$c destruct}
	}
	
	return 1
}

# LIke unshiftCellsToVars, but only one cell is shifted, and
# the stack is specified.
# (must be bidi)
#
Wave method unshiftCellFromStackToVar {stack var} {
	set u un$stack

	if {1 > [$self slotLength $u]} {return 0}

	set c  [$self slotPop $u]
	uplevel [list set $var $c]

	$self slotPush $stack $c
	
	return 1
}

# Save the current op on the unX stack, if bidi, else
# do nothing.
#
Wave method saveX {} {
	set co [$self slot currentOp]
	if {[$self slot bidi] && $co ne ""} {
		$self slotPush unX $co
		$self notifyObservers xevent [$self slotLength X] [$self slotLength unX]
	}
}

# Push something on the X stack and change it's
# x status and send out a notification.
#
Wave method pushX {c} {
	if {[Object existsAs $c Cell]} {
		$c xstatus 1
	}

	$self slotPush X $c
	$self notifyObservers xevent [$self slotLength X] [$self slotLength unX]
	return $c
}

# Pop something off the X stack and change it's
# x status and send out a notification.
#
Wave method popX {} {
	set c [$self slotPop X]

	if {[Object existsAs $c Cell]} {
		$c xstatus 0
		$c paused 0
	}

	$self notifyObservers xevent [$self slotLength X] [$self slotLength unX]
	return $c
}

# Print the state of the wave, for debugging
#
Wave method print {} {
	puts "Wave $self type: [$self slot wavetype] state: [$self slot state]  bidi: [$self slot bidi]  stack: [$self slot stack]  start: [$self slot start]  anchor: [$self slot anchor]"
	puts "  endcode: [$self slot endcode]  error: [$self slot error]"
	puts "  substack: [$self slot substack]"
	puts "  A: [$self slot A]"
	puts "  B: [$self slot B]"
	puts "  Y: [$self slot Y]"
	puts "  X: [$self slot X]"
	puts "  unA: [$self slot unA]"
	puts "  unB: [$self slot unB]"
	puts "  unY: [$self slot unY]"
	puts "  unX: [$self slot unX]"
}
