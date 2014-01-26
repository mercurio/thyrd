### A cell in ThyrdSpace.  A cell has a nucleus (an object
### derived from Core).  Outside the core
### but inside the cell are the endpoints of triads that
### join this cell with others.
###
### This object has both a construct and a new method, 
### construct is for raw construction (as when loaded
### from persistent storage) and new is for normal use.
###
### Observable events:
###		read				cell being read
###		write				cell just loaded or entirely changed
###		destruct			cell about to destruct or remove core
###		gainSub cell i j	we're a grid and a new subcell's been made
###		loseSub cell i j	we're a grid and a subcell's been lost
###		newPlace			cell moved to a new place
###		xstatus onOff		change in execution status (are we on a Wave's X stack?)
###		paused onOff		change in paused status (are we in the middle of a break?)
###
# PJM 2005-07-23	Created 
# PJM 2005-10-20	Modified to use Core 
# PJM 2005-12-29	Observers added
# PJM 2006-08-03	Mods for new Observer code
# PJM 2006-09-25	setAt arguments changed and renamed to putAt
# PJM 2008-10-30	Cells now create their cores with the same prefix as they were
# PJM 2008-10-31	Added export/import support
# PJM 2009-02-24	Added paused event

Object construct Cell
Cell mixin Exportable

# The core, or nucleus, of this cell
Cell slot core {}
Cell type core Core

# The cell that contains this one, or null if this is
# a free cell or the root cell
#
Cell slot container {}
Cell type container Cell

# The coords where we are located in our container
#
Cell slot i {}
Cell type i <integer>

Cell slot j {}
Cell type j <integer>

# Construct a new cell, making it persistent. 
#
Cell method construct {{child @}} {
	set kid [$self as [Cell parent] construct $child]
	$kid mixin Thing
	$kid mixin Observable

	return $kid
}

# Construct a new cell with a new core having the given
# value.  The type of the core may also be specified. 
#
# A prefix may also be given, default is @ (persistent anon).
#
Cell method new {{value ""} {type Core} {prefix @}} {
	set kid [$self construct $prefix]

	if {[string match <* $type]} {
		Core newInCell $kid $value $type
	} else {
		$type newInCell $kid $value
	}

	return $kid
}

# Construct a new cell with a new core having the given
# value.  The type of the core may also be specified. 
# The container is set to the given wave.
#
# We maintain _waveCells for Wave, but don't bother to
# clean it up, Wave doesn't assume all the cells still
# exist when it destructs.
#
Cell method newInWave {wave {value ""} {type Core}} {
	set kid [$self construct]
	
	if {[string match <* $type]} {
		Core newInCell $kid $value $type
	} else {
		$type newInCell $kid $value
	}

	$kid slot container $wave
	$wave slotAppend _waveCells $kid

	return $kid
}

# Construct a new cell with the same type and value as
# this cell. This only makes sense for atomic cells.
#
Cell method clone {{name @}} {
	set kid [Cell construct $name]

	set value [$self peek]
	set type [$self getType]

	if {[string match <* $type]} {
		Core newInCell $kid $value $type
	} else {
		$type newInCell $kid $value
	}

	return $kid
}

# Override Thing_postload to cause the core to be loaded
# when this cell is.  In this way, loading the root
# causes the entire space to be loaded.
# We also load all the triad maps.
#
Cell method Thing_postload {} {
	[$self slot core] noop

	theSpace loadTriads $self

	$self as Thing Thing_postload
	$self notifyObservers write
}

# Destroy a Cell and our core and maps. 
# We first ask the space to place us nowhere 
# (freeing this cell).
#
Cell method destruct {} {
	$self _unlocate 

	foreach t [theSpace findTriads $self * *] {$t loseCell A}
	foreach t [theSpace findTriads * $self *] {$t loseCell B}
	foreach t [theSpace findTriads * * $self] {$t loseCell Y}

	$self notifyObservers destruct

	Object safe [$self slot core] destruct

	$self as Object destruct
}

# Cause a cell to consider suicide.  If we're
# not in a container and have no triads, we self-destruct.
#
Cell method deject {} {
	if {[$self slot container] ne ""} return

	if {[theSpace findTriads $self * *] ne ""} return
	if {[theSpace findTriads * $self *] ne ""} return
	if {[theSpace findTriads * * $self] ne ""} return

	$self destruct
}

# Clear the core, possibly destroying a grid
# (and all its contents).  We create a new
# empty core of the given type to take its place.
# The new core is returned.
#
Cell method empty {{type Core}} {
	Object safe [$self slot core] destruct

	set x [$type newInCell $self]
	$self notifyObservers empty

	return $x
}

# Set this cell's value.  The cell must be atomic or
# not exist yet.  The type can be provided, in which
# case the type of the cell will be changed to the one
# specified.
#
Cell method set {a {type ""}} {
	set x [$self slot core]
	assert {[Object exists $x]}

	set p [$x parent]
	if {$p eq "Grid"} {
		return -code [UserMsg errorRC "|$self set $a| Cell $self is not atomic, can't set it"] $a
	}
	
	if {$type eq ""} {
		if {![$x validate $a]} {
			return -code [UserMsg errorRC "|$self set $a| Cell $self is of type $p, \"$a\" is not a valid value"] $a
		}
		
		$x set $a
	} elseif {$type eq $p} {
		$x set $a
	} elseif {$p eq "Core" && $type eq [$x type value]} {
		$x set $a
	} else {
		$x destruct
		if {[Object existsAs $type Core]} {
			$type newInCell $self $a
		} else {
			Core newInCell $self $a $type
		}
	}

	$self notifyObservers write
	return $a
}

# Set this cell's value without triggering anything.  
# The cell must exist and be atomic, and we don't change
# the type. We don't even validate.
#
# This may undermine the integrity of cell updates, but
# ParamListOwner uses it effectively.
#
Cell method setSilently {a} {
	set x [$self slot core]
	assert {[Object exists $x]}

	set p [$x parent]
	if {$p eq "Grid"} {
		return -code [UserMsg errorRC "|$self set $a| Cell $self is not atomic, can't set it"] $a
	}
	
	$x set $a
	return $a
}

# Return true if ``a`` is a valid value for this cell
#
Cell method validate {a} {
	set x [$self slot core]
	assert {[Object exists $x]}

	if {[$x atomic]} {
		return [$x validate $a]
	} else {
		return -code [UserMsg errorRC "|$self validate $a| Cell $self is not atomic, validation doesn't make sense"] $a
	}
}

# Get this cell's value.  The cell must be atomic.
#
Cell method get {} {
	set x [$self slot core]
	assert {[Object exists $x]}

	if {[$x atomic]} {
		$self notifyObservers read
		return [$x get]
	} else {
		return -code [UserMsg errorRC "|$self get| Cell $self is not atomic, can't get it"]
	}
}

# Peek at this cell's value, without notifying observers.
# We also don't check for atomicity.
#
Cell method peek {} {
	return [[$self slot core] get]
}

# Return a textual representation of this cell's value. 
# We do not notify the observers.
#
Cell method getText {} {
	set x [$self slot core]
	assert {[Object exists $x]}

	return [$x getText]
}

# Using Poet constraints, tie the value of this cell
# to a slot on an arbitrary Poet object.  Only makes
# sense if we're atomic.
#
# Note that we actually tie the object's slot to our
# core, changing the object's slot.
#
Cell method tieTo {obj slot} {
	set x [$self slot core]
	assert {[Object exists $x]}

	if {[$x atomic]} {
		$obj slotTieTo $slot $x value
	} else {
		return -code [UserMsg errorRC "|$self get| Cell $self is not atomic, can't tie to it"] 
	}
}

# Put a value in the subcell at the given coords.
# If the sub cell doesn't exist, create it with the given
# type.  Note that if no coords are given, 0,0 is referenced.
#
# We don't notify the observers here.  If the sub cell exists,
# it will notify its observers.  ``subCell!`` will do the notifying
# if a new cell is created.
#
# The type may be either a built-in type or a Core descendant.
#
Cell method putTypeAt {value {type Core} {i ""} {j ""}} {
	set x [$self slot core]
	assert {[Object exists $x]}

	if {[string match <*> $type]} {
		set x [[$self subCell! $i $j $value Core yes] slot core]
		$x type value $type
		# Actually, we have to notify here because the type changed
		$self notifyObservers write
	} else {
		$self subCell! $i $j $value $type yes
	}

	return $value
}

# Put a value in the subcell at the given coords.
# If it doesn't exist yet, create a Core cell there.
#
# This is like subCell! with setIt == yes, but
# we don't change the type.
#
Cell method putAt {value  {i ""} {j ""}} {
	set x [$self slot core]
	assert {[Object exists $x]}

	if {[$x atomic]} {
		set x [$self empty Grid]
	} 

	set c [$x getCell $i $j]

	if {$c eq ""} {
		set c [Cell new $value Core]
		$x setCell $c $i $j
	} else {
		$c set $value
	}

	return $value
}

# Get the value of the sub cell at the given coordinates,
# or {} if nothing is there.
#
Cell method getAt {{i ""} {j ""}} {
	set x [$self slot core]
	assert {[Object exists $x]}

	if {[$x atomic]} {return ""}

	set c [$x getCell $i $j]

	if {$c eq ""} {
		return ""
	} else {
		return [$c get]
	}
}

# Get the value of the sub cell at the given coordinates,
# or {} if nothing is there.  Do not trigger notification.
#
Cell method peekAt {{i ""} {j ""}} {
	set x [$self slot core]
	assert {[Object exists $x]}

	if {[$x atomic]} {return ""}

	set c [$x getCell $i $j]

	if {$c eq ""} {
		return ""
	} else {
		return [[$c slot core] get]
	}
}

# Append a value in the subcell, expanding the grid. An
# optional type is given.
#
Cell method append {value {type Core}} {
	set x [$self slot core]
	assert {[Object exists $x]}

	if {[$x atomic]} {
		set i 1
		set j 1
	} else {
		lassign [$x size] i j
		if {$i == 0 && $j == 0} {
			set i 1
			set j 1
		} else {
			incr j -1
		}
	}

	return [$self putTypeAt $value $type $i $j]
}

# Retrieve a subCell in the grid that is
# this cell's core, at the given coordinates.
# If no coords are given, this gets the 0,0 cell.
#
# If the cell's not there, or this is an atomic cell,
# we return {}
#
Cell method subCell {{i ""} {j ""}} {
	set x [$self slot core]
	assert {[Object exists $x]}

	if {[$x atomic]} {return ""}

	return [$x getCell $i $j]
}

# Forcefully retrieve a subCell in the grid that is
# this cell's core, at the given coordinates.
# If no coords are given, this gets the 0,0 cell.
#
# If the cell's not there, we create it.  If this
# is an atomic cell, we make it a grid.
#
# value  and  type  are used to create the cell,
# ignored if the cell is already there
#
# If  setIt  is true, set the value and type of the cell
# even if it existed prior to this method invocation.
#
Cell method subCell! {{i ""} {j ""} {value ""} {type Core} {setIt no}} {
	set x [$self slot core]
	assert {[Object exists $x]}

	if {[$x atomic]} {
		set x [$self empty Grid]
	} 

	set c [$x getCell $i $j]

	if {$c eq ""} {
		set c [Cell new $value $type]
		$x setCell $c $i $j
	} elseif {$setIt} {
		$c setType $type
		$c set $value
	}

	return $c
}

# Store an already-constructed cell in
# this cell's core, at the given coordinates.
#
# If there's already a cell there, we destroy it.
# If this is an atomic cell, we make it a grid.
#
Cell method storeSub {sc i j} {
	set x [$self slot core]
	assert {[Object exists $x]}

	if {[$x atomic]} {
		set x [$self empty Grid]
	} 

	set c [$x getCell $i $j]
	if {$c ne ""} {
		set ni [$x findIFrame $i]
		set nj [$x findJFrame $j $ni]

		$self notifyObservers loseSub $c $ni $nj
		$c destruct
	}

	$x setCell $sc $i $j
}

# Set this cell as the root cell.  This can only
# be done to a new (free) cell.
#
Cell method setAsRoot {} {
	if {[$self slot container] ne ""} {
		UserMsg error "|$self setAsRoot| Already in container [$self slot container]"
	}

	$self slot container "root"
}


# Change this cell's location to a wave. It's an 
# error if it belongs to a grid somewhere.
#
Cell method placeInWave {wave} {
	set ow [$self slot container]
	assert {$ow eq ""}

	$self slot container $wave
	$self notifyObservers newPlace
}

# Change this cell's location, its container and coords.
# If no args are provided, this is now a free
# cell.  Otherwise, a container cell and coords are
# provided.  Or, the container can be a wave.
#
# The root cell is set  using ``setAsRoot``, and we 
# currently disallow relocating the root.
#
Cell method relocate {{where ""} {i ""} {j ""}} {
	if {$where eq ""} {
		set i ""
		set j ""
	} 

	set ow [$self slot container]
	assert {$ow ne "root"}

	set oi [$self slot i]
	set oj [$self slot j]

	if {$oi == $i && $oj == $j && $ow eq $where} return

	if {$ow ne $where} {
		Object safe $ow notifyObservers loseSub $self $oi $oj
	}

	$self slot container $where
	$self slot i $i
	$self slot j $j

	if {$ow ne $where} {
		Object safe $where notifyObservers gainSub $self $i $j
	}

	foreach t [theSpace findTriads $self * *] {$t setCell A $self}
	foreach t [theSpace findTriads * $self *] {$t setCell B $self}
	foreach t [theSpace findTriads * * $self] {$t setCell Y $self}

	$self notifyObservers newPlace
}

# Change this cell's location, its container and coords,
# to nowhere in preparation for its destruction. Specialized
# version of ``relocate`` used by ``destruct``.
#
Cell method _unlocate {} {
	set ow [$self slot container]
	if {$ow eq ""} return

	set oi [$self slot i]
	set oj [$self slot j]

	if {[$ow isA Cell]} {
		$ow notifyObservers loseSub $self $oi $oj
	}

	$self slot container ""
	$self slot i ""
	$self slot j ""
}

# A sub cell is being replaced, either because it
# was deleted or because it moved.  We replace 
# it with a new cell, if one isn't provided 
# we construct it.
# NOT USED 
#
Cell method _subCellReplace {c i j {newc ""}} {
	$self notifyObservers loseSub $c $i $j

	#LEFT OFF HERE really want to delete whole column
	if {$newc eq ""} {set newc [Cell new]}
	
	[$self slot core] setCell $newc $i $j
}

# Return the coordinates of this cell as a list
#
Cell method coords {} {
	return [list [$self slot i] [$self slot j]]
}

# Return true if this cell is atomic 
#
Cell method atomic {} {
	return [[$self slot core] atomic]
}

# Return either this cell (if it's atomic)
# or the 1 1 cell if it isn't.
#
Cell method one {} {
	if {[[$self slot core] atomic]} {
		return $self
	} else {
		return [$self subCell 1 1]
	}
}

# Return true if this cell is free or part
# of a free tree. Wave cells are not free.
#
Cell method isFree {} {
	set cc [$self slot container]

	if {$cc eq ""} {
		return 1
	} elseif {$cc eq "root"} {
		return 0
	} elseif {[Object existsAs $cc Cell]} {
		return [$cc isFree]
	} else {
		return 0
	}
}


# Return this cell's containment path, the sequence of
# cells containing it.  The first cell in the list
# should always be the root of the space (unless we're
# not situated at all).
#
# If we're in a wave, this should just return null
#
Cell method containmentPath {} {
	set cc [$self slot container]

	if {$cc eq ""} {
		return [list]
	} elseif {$cc eq "root"} {
		return [list]
	} elseif {[$cc isA Wave]} {
		return [list]
	} else {
		return [concat [$cc containmentPath] $cc]
	}
}


# Return a better index for this cell relative to
# it's container.  We might just return the i and j
# numerical values, but we use the text from the 
# corresponding frame cells if present.
#
# If we're the root cell (our container is "root")
# we return the null string.  If we have no container,
# the only valid index is our direct name.
#
Cell method betterIndex {} {
	set cc [$self slot container]
	if {$cc eq ""} {return $self}
	if {$cc eq "root"} {return ""}
	if {[$cc isA Wave]} {return $self}

	set i [$self slot i]
	set j [$self slot j]

	if {$i == 0 && $j == 0} {return [list 0]}

	set it [$cc peekAt $i 0]
	set jt [$cc peekAt 0 $j]

	if {$it ne ""} {set i $it}
	if {$jt ne ""} {set j $jt}

	if {$j == 1 && $i != 0} {
		return [list $i]
	} else {
		return [list $i $j]
	}
}

# Return a cell up $n levels in the containment hierarchy,
# or "" if we can't go that far.  Negative $n values
# don't make sense but are treated like 0.  If we're not
# contained by a cell, return "".
#
Cell method uplevel {n} {
	if {$n <= 0} {return $self}

	set c [$self slot container]

	if {$c eq "" || ![Object existsAs $c Cell]} {
		return ""
	}

	if {$n == 1} {
		return $c
	} else {
		return [$c uplevel [expr $n - 1]]
	}
}

# Return the full path to this cell, as a string.
# The default path to a cell is its name.
#
Cell method path {} {
	if {[theSpace isRoot $self]} {return "/"}

	set c [$self slot container]
	if {$c eq "" || ![Object existsAs $c Cell]} {
		return $self
	}

	if {[theSpace isRoot $c]} {
		return "/[$self betterIndex]"
	} else {
		return "[$c path]/[$self betterIndex]"
	}
}

# Return the size of the cell.  If it is atomic,
# the size is 1 x 1, otherwise it's the size of
# the grid.  The size includes the frame cells of
# the grid.  An empty grid is 0 x 0, store something
# in 1 1 and it becomes 2 x 2.
#
Cell method size {} {
	if {[$self atomic]} {
		return [list 1 1]
	} else {
		return [[$self slot core] size]
	}
}

# Return an icon for this cell.
#
Cell method getIcon {} {
	set x [$self slot core]
	assert {[Object exists $x]}

	if {[$x atomic]} {
		set s [$x get] 
		if {$s eq ""} {
			return [Thyrd getImage cell-empty]
		} else {
			return [Thyrd getImage cell-atomic]
		}
	} else {
		return [Thyrd getImage cell-grid]
	}
}

# Return a glyph for this cell.
#
Cell method getGlyph {} {
	set x [$self slot core]
	assert {[Object exists $x]}

	if {[$x atomic]} {
		return [$x getGlyph]
	} else {
		return [Thyrd getImage glyph-grid]
	}
}

# Set up observation of a subcell.  We also return the
# value of the subcell.
#
Cell method watchSub {observer handler {i ""} {j ""}} {
	set sc [$self subCell $i $j]
	$sc addObserver write $observer $handler

	return [$sc get]
}

# Set up observation of a subcell.  We also return the
# value of the subcell and call the handler right now.
#
Cell method watchSub! {observer handler {i ""} {j ""}} {
	set sc [$self subCell $i $j]
	[$sc addObserver write $observer $handler] execute write
	
	return [$sc get]
}

# Store a parameter's new value, without triggering
# an update to an observer.
#
Cell method putAtIgnore {observer value {i ""} {j ""}} {
	set sc [$self subCell! $i $j]
	Observer ignore $observer $sc {$sc set $value}
}

# Get the a cell, given the path as text.  This cell is
# used as the reference cell (if needed).
# We might even make the cell if it doesn't exist.
#
# With an absolute path, this can be called on Cell
# itself, as in 
#``
#	set thyrdroot [Cell goto "/thyrd"]
#``
#
Cell method goto {path {make no}} {
	set p [Path newVolatile $path]

	if {$self eq "Cell"} {
		set ref ""
	} else {
		set ref $self
	}

	set c [$p resolve $ref $make]

	$p destruct
	return $c
}

# Get the type of this cell, either a built-in or a new
# core type.  If ``head`` is true, return only the type id
# if it's a built-in Poet type.
#
Cell method getType {{head 0}} {
	set x [$self slot core]
	if {$x eq ""} {
		return {}
	} 

	set t [$x parent]
	if {$t ne "Core"} {return $t}

	set t [$x type value]
	if {$head} {
		return [lindex $t 0]
	} else {
		return $t
	}
}

# Set the type of this cell, either a built-in or a new
# core type. If the type is already correct, do nothing.
# If we're converting from one Core to another, reuse
# the same Core. We only call ``become`` if we have to.
#
Cell method setType {nt} {
	set ot [$self getType]
	if {$ot eq $nt} return

	set ott [string match <* $ot]
	set ntt [string match <* $nt]

	if {$ott && $ntt} {	
		set x [$self slot core]
		$x type value $nt
		$self notifyObservers write
	} else {
		$self become $nt
	}
}

# Become a new type of cell by reusing the existing value
# but replacing the core.
# 
Cell method become {{type Core}} {
	set oldx [$self slot core]

	if {[string match <* $type]} {
		Core newInCell $self [$oldx slot value] $type
	} else {
		$type newInCell $self [$oldx slot value]
	}
	$oldx destruct

	$self notifyObservers empty
}

# Given another cell, set this cell's value and type to
# be the same.
#
Cell method setFrom {c} {
	$self set [$c peek]
	$self setType [$c getType]
}

# Return true if this cell is of the given type (the core
# has the type as ancestor).  Note that inheritance is
# involved here, so all Cells will be of type Core, even
# if the core is a more specialized type.  ``getType`` might
# be more useful.
#
Cell method isOfCoreType {type} {
	set x [$self slot core]
	if {$x eq ""} {
		return 0
	} else {
		return [$x isA $type]
	}
}

# Return true if the container is the one given
#
Cell method isIn {cc} {
	return [expr {[$self slot container] eq $cc}]
}

# Return true if we're somewhere under the cell given.
#
Cell method isUnder {cc} {
	set mycc [$self slot container]

	while {$mycc ne "" && $mycc ne "root"} {
		if {$mycc eq $cc} {return 1}
		set mycc [$mycc slot container]
	}

	return 0
}

# Return this cell's grid, i, and j, but only
# if the container is a grid.
#
Cell method getGIJ {} {
	set g [$self slot container]
	if {![Object existsAs $g Cell]} {return [list "" "" ""]}

	return [list $g [$self slot i] [$self slot j]]
}

# Print for debugging
#
Cell method print {} {
	set x [$self slot core]
	if {[$x atomic]} {
		set s [$x get]
	} else {
		set s "(grid)"
	}

	puts "$self: [$self slot core] $s"
	puts "  in : [$self slot container] at ([$self slot i],[$self slot j])"
}

# Change our X status. We just send out a notification.
#
Cell method xstatus {onOff} {
	$self notifyObservers xstatus $onOff
}

# Change our paused status. We just send out a notification.
#
Cell method paused {onOff} {
	$self notifyObservers paused $onOff
}
