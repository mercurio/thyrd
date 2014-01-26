# CellTable - Code common to all the Cell*Table views
#
# Make sure this is mixed in before CellObserver, since it
# provides the cellEvent method required by the Observer API.
#
# PJM 2006-05-08	Begun
# PJM 2006-09-08	Observer redesign, cellEvent and navBarEvent
# 					separate
# PJM 2006-09-29	Modifications for paramList
#

Mixin construct CellTable
CellTable mixin ParamListOwner

# If set, draw a simplifed view.  Set during animation, resizing
CellTable slot simplify 0
CellTable type simplify <boolean>

# Options that must be specified at creation time
CellTable slot extraOptions {paramList tool}

# Default values for the params specific to a CellTable
CellTable slot _defaultParams {
	-selectGrid "" 
	-select0 "" 
	-select1 "" 
	-selectmode {none "<choice> none all range iselect jselect"}
	-showTypes 1
	-bottomMargin 0
}

# Called to set up watching of the cells in the paramList
#
CellTable method watchParams {pl} {
	$pl watchSub $self newPath path
	$pl watchSub $self newDepth depth
	$pl watchSub $self newMode mode
	$pl watchSub $self newDisplayParam panels
	$pl watchSub $self newDisplayParam gridpanels
	$pl watchSub $self newDisplayParam defaultGpanel
	$pl watchSub $self newDisplayParam defaultCpanel
	$pl watchSub $self newDisplayParam iframe
	$pl watchSub $self newDisplayParam jframe
	$pl watchSub $self newDisplayParam idirection
	$pl watchSub $self newDisplayParam layout
	$pl watchSub $self newSelection selectGrid
	$pl watchSub $self newSelection select0
	$pl watchSub $self newSelection select1
	$pl watchSub $self newSelection selectmode
	$pl watchSub $self newDisplayParam showTypes
}

#  Observer handler methods
#
CellTable method newPath {target event} {
	set path [$target get]

	if {![$self pathDelta $path]} return

	if {[$self getParam animate]} {
		$self navTo [$self viewCell] [$self getParam direction]
	} else {
		$self cellEvent [$self viewCell] write
	}
}

CellTable method newMode {target event} {$self modeSelect [$target get]}
CellTable method newDepth {target event} {$self setDepth [$target get]}

# Used by any param that just wants to trigger a full redraw when changed
CellTable method newDisplayParam {target event} {$self renderRoot}

CellTable method newSelection {target event} {
	UserMsg error "|CellTable newSelection| Should be overridden by $self ($self parent)"
}

# The bottom margin has changed (redraw for now)
#
CellTable method newBottomMargin {target event} {$self renderRoot}
	
# Attached to navbar UNUSED DEFERRED remove
#CellTable method navEvent {target event} { 
#	$self navTo [$target viewCell] [$target slot direction]
#}

## Observer API
##
## Observer messages from cells:
##		write				cell just loaded or entirely changed
##		read				cell value read
##		destruct			cell about to destruct
##		empty				Cell has been emptied (new core type)
##		newPlace			we've moved
##		gainSub cell i j	we're a grid and a new subcell's been made
##		loseSub cell i j	we're a grid and a subcell's been lost
##		xstatus onOff       change in execution status (are we on a Wave's X stack?)
##		paused onOff        change in paused status (in middle of break)

# Update according to the given observer message.  Note that
# we ignore some cell events if it's not our root cell.
# We also rely on the built-in ignoring provided by Observer/Observable.
#
# The particular table view we're mixed in to must
# provide the rendering methods.
#
CellTable method cellEvent {target event args} {
	set rc [$self viewCell]
	set rootEvent [string equal $target $rc]

	switch [lindex $event 0] {
		write {
			if {$rootEvent} {
				$self newGridPrep
				$self renderRoot 
			} else {
				$self renderSub $target 
			}
		}

		read {
			# DEFERRED handle reads
			return
		}

		empty {
			if {$rootEvent} {
				$self unrender 
				$self newGridPrep
				$self renderRoot 
			} else {
				if {$target ne ""} {
					$self unrenderSub $target
					$self renderSub $target
				}
			}
		}

		destruct {
			if {$rootEvent} {
				$self unrender 
			} else {
				if {$target ne ""} {
					$self unrenderSub $target
					$target deleteObserver * $self
				}
			}
		}

		gainSub {
			if {$rootEvent} {
				lassign $args subC i j

				$self renderSub $subC
				Object safe $subC addObserver * $self cellEvent
			}
		}

		loseSub {
			if {$rootEvent} {
				lassign $args subC i j

				$self unrenderSub $subC 
				Object safe $subC deleteObserver * $self
			}
		}

		newPlace {
			if {[$target slot container] eq ""} {
				$self unrenderSub $target
				$target deleteObserver * $self
			} else {
				$self renderRoot
			}
		}

		xstatus {
			$self xstatus $target $args
		}

		paused {
			$self paused $target $args
		}

		default {
			UserMsg error "|$self cellEvent $target $event $args| Unrecognized event message"
		}
	}

	update idletasks
}

# Navigate to a new cell, the direction of motion is also
# provided.  The default method here does no animation.
# 
CellTable method navTo {cell dir} {
	$self newGridPrep
	$self setParam animate 0
	$self setParam path [$cell path]
}

# Set the root and render it
#
CellTable method newCell {c} {

	$self cellDelta $c
	$self newGridPrep
	$self renderRoot
}

# Render the root (view) cell
#
CellTable method renderRoot {} {
	if {[[$self slot tool] inResize]} return
	#$self slot simplify [[$self slot tool] inResize]

	set c [$self viewCell]

	if {$c eq ""} {
		$self renderNoCell 
	} elseif {[$c atomic]} {
		$self setParam showing atomic
		$self renderAtomic $c
	} else {
		$self setParam showing grid
		$self renderGrid $c
	}

	$self slot renderAfter ""
}

# 
# Schedule a redraw of the view (called when a Configure event occurs)
#
CellTable method reconfigure {} {
	update idletasks	;# without this, the size isn't correct

	set a [$self slot renderAfter]
	if {$a ne ""} {
		after cancel $a
	}
	$self slot renderAfter [after idle [list $self renderRoot]]
}

# Prepare for a new grid drawing (a different cell
# than currently shown).  Should be overriden.
#
CellTable method newGridPrep {} {
	UserMsg warning "|CellTable newGridPrep| This method should be overridden by $self"
}
