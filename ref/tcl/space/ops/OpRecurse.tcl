### The ``recurse`` operation
###
### Pops two programs off the stack, ``then`` and ``else2``,
### and performs linear recursion with the default ``if``
### and ``else1`` parts.
###
### The default ``if`` part tests integers to see if they're
### 0, and reals to see if they're less than epsilon. Grids
### are tested to see if they're empty. Strings are tested
### to see if they're empty.
###
### The default ``else1`` reduces the value appropriately.
### Integers are decremented, reals are decremented, strings
### are treated like lists and have their heads removed.
### Grids have their first cell removed.
###
### This is the parent of all recursion ops, linear and
### binary recursion are implemented by changing parameters.
### Use linear recursion to have full control over the
### ``if``, ``then``, ``else1``, and ``else2`` parts.
#
# PJM 2008-06-30	Begun
# PJM 2009-02-22	Continuable version begun

Op construct OpRecurse

OpRecurse slot opcode "recurse"
OpRecurse slot caption "recurse"
OpRecurse slot iconlg [Thyrd getImage "op-recurse-lg"]
OpRecurse slot iconsm [Thyrd getImage "op-recurse-sm"]
OpRecurse slot icongl [Thyrd getImage "op-recurse-gl"]
OpRecurse slot in {whennull prog}
OpRecurse slot out {recursion with prog}
OpRecurse slot tags {combinator}
OpRecurse slot help "Pop a whennull value and a program. Recursively apply the program to the value below the ifnull, taking the pred each time and using whennull when the operand is null."
OpRecurse slot sidefx "Depends on program provided as input"

# Parameters for various recursive operations

# How many times to recurse per step
OpRecurse slot rWidth 1
OpRecurse type rWidth "<integer> 1 2"

# How many stack items will p leave behind
OpRecurse slot pOut 1
OpRecurse type pOut <integer>

# Primitive recursion, assume if and else1
OpRecurse slot primitive 1
OpRecurse type primitive <boolean>

# What stage this op is in
OpRecurse slot stage needTest
OpRecurse type stage "<choice> needTest didTest didThen didElse1 needElse2 didElse2"

# Perform the operation on the given wave
#
OpRecurse method doOp {wave} {
	set params [list ifpart then else1 else2]

	set prim [$self slot primitive]
	if {$prim} {
		set paramsNeeded [list then else2]
	} else {
		set paramsNeeded $params
	}

	set virgin [$self slot virgin]

	if {$virgin} {
		if {![$wave shiftCellsToVars {*}$paramsNeeded]} {
			$wave slot error "Need [llength $paramsNeeded] cells on stack [$wave slot stack]"
			return -code error
		}

		foreach i $paramsNeeded {
			if {[[set $i] atomic]} {
				$wave slot error "Input '$i' is not a grid"
				return -code error
			}
		}

		# handle prim here
		if {$prim} {
			set top [$wave peek]
			if {![Object exists $top]} {
				$wave slot error "No value to operate on remains on stack [$wave slot stack]"
				return -code error
			}

			set ty [$top getType yes]
			set ifpart [$self getIfPartFor $ty]
			set else1 [$self getElse1PartFor $ty]

			if {$ifpart eq "" || $else1 eq ""} {
				$wave slot error "No default if or else1 part for type ${ty}, use recurse-linear instead"
				return -code error
			}
		}

		$wave saveX

		set nop [$self construct *]
		$nop slot virgin 0

		$nop slot stage needTest

		foreach i $params {
			$nop slot $i [set $i]
		}

		set next [$wave getNext]
	} else {
		set nop $self

		foreach i $params {
			set $i [$nop slot $i]
		}

		set next ""
	}

	switch [$nop slot stage] {
		needTest {
			$nop slot stage didTest
			lappend next $nop [$wave newEnd] [$ifpart one]
		}
		didTest {
			if {[$wave pop]} {
				$nop slot stage didThen
				lappend next $nop [$wave newEnd] [$then one]
			} else { ;# begin recursion
				$nop slot stage didElse1
				lappend next $nop [$wave newEnd] [$else1 one]
			}
		}
		didThen {return $next}
		didElse1 {
			$nop slot stage needElse2
			lappend next $nop [$wave newEnd] 
			lappend next [Cell newInWave $wave [OpRecurseLinear slot opcode] Opcode] $else2 $else1 $then $ifpart
		}
		needElse2 {
			$nop slot stage didElse2
			lappend next $nop [$wave newEnd] [$else2 one]
		}
		didElse2 {return $next}
	}

	return $next
}

# Given a core type, return an ifpart cell or null if
# none is defined. We memoize this method via grids
# stored in /thyrd/recursion. The user can mess with
# those grids and we'll use them, this code creates
# them only if they don't already exist.
#
OpRecurse method getIfPartFor {ty} {
	set c [theSpace find "/thyrd/recursion/$ty if"]
	if {$c ne ""} {return $c}
	
	switch $ty {
		<integer> {
			theSpace set "/thyrd/recursion/$ty if/1" "dup" Opcode
			theSpace set "/thyrd/recursion/$ty if/2" 0 <integer>
			theSpace set "/thyrd/recursion/$ty if/3" = Opcode
		}
		<real> {
			theSpace set "/thyrd/recursion/$ty if/1" "dup" Opcode
			theSpace set "/thyrd/recursion/$ty if/2" 0 <real>
			theSpace set "/thyrd/recursion/$ty if/3" = Opcode
		}
		<string> {
			theSpace set "/thyrd/recursion/$ty if/1" "dup" Opcode
			theSpace set "/thyrd/recursion/$ty if/2" "" <string>
			theSpace set "/thyrd/recursion/$ty if/3" = Opcode
		}
		Grid {
			theSpace set "/thyrd/recursion/$ty if/1" empty Opcode
		}
	}

	return [theSpace find "/thyrd/recursion/$ty if"]
}

# Given a core type, return an else1 cell or null if
# none is defined. We memoize this method via grids
# stored in /thyrd/recursion. The user can mess with
# those grids and we'll use them, this code creates
# them only if they don't already exist.
#
OpRecurse method getElse1PartFor {ty} {
	set c [theSpace find "/thyrd/recursion/$ty else1"]
	if {$c ne ""} {return $c}
	
	switch $ty {
		<integer> {
			theSpace set "/thyrd/recursion/$ty else1/1" "dup" Opcode
			theSpace set "/thyrd/recursion/$ty else1/2" "pred" Opcode
		}
		<real> {
			theSpace set "/thyrd/recursion/$ty else1/1" "dup" Opcode
			theSpace set "/thyrd/recursion/$ty else1/2" "pred" Opcode
		}
		<string> {
			theSpace set "/thyrd/recursion/$ty else1/1" "dup" Opcode
			theSpace set "/thyrd/recursion/$ty else1/2" "head" Opcode
		}
		Grid {
			theSpace set "/thyrd/recursion/$ty else1/1" "head" Opcode
		}
	}

	return [theSpace find "/thyrd/recursion/$ty else1"]
}


# Undo by removing the answer and
# restoring the operands
#
OpRecurse method undoOp {wave} {
	return ""
}

# Reference, non-continuable version
OpRecurse method reference-doOp {wave} {
	set prim [$self slot primitive]

	if {$prim} {
		set need [list then else2]
	} else {
		set need [list ifpart then else1 else2]
	}

	if {![$wave shiftCellsToVars {*}$need]} {
		return -code error "Need [llength $need] cells on stack [$wave slot stack]"
	}

	foreach i $need {
		if {[[set $i] atomic]} {
			return -code error "Input '$i' is not a grid"
		}
	}

	# handle prim here
	if {$prim} {
		set top [$wave peek]
		if {![Object exists $top]} {
			return -code error "No value to operate on remains on stack [$wave slot stack]"
		}

		set ty [$top getType yes]
		set ifpart [$self getIfPartFor $ty]
		set else1 [$self getElse1PartFor $ty]

		if {$ifpart eq "" || $else1 eq ""} {
			return -code error "No default if or else1 part for type ${ty}, use recurse-linear instead"
		}
	}

	$self _recurse $wave $ifpart $then $else1 $else2

	return ""
}

# Reference, non-continuable version
# Actually do the recursion
#
OpRecurse method _recurse {wave if then else1 else2} {
	$wave subroutine $if

	if {[$wave pop]} {
		$wave subroutine $then
	} else {
		$wave subroutine $else1
		$self _recurse $wave $if $then $else1 $else2
		$wave subroutine $else2
	}
}
