# PathWidget - A Mixin that contains methods for drag and
#	drop of the contents of the pathName slot.
#
# We assume our children have slots named pathName, text, and notify.
#
# PJM	2005-09-08	Begun, derived from Poet's ObjectNameWidget
# PJM	2008-11-21	Validation added, not quite working yet
#

Mixin construct PathWidget

# Called in the widget's buildPrimary
#
PathWidget method PathWidget_config {} {
	$self slot dropenabled 1
	$self slot dragenabled 1
	$self slot dragevent 1 
	$self slot droptypes { SIGN {copy {}} TEXT {copy {}} }  

	$self slot draginitcmd "$self PathWidget_draginit"
	$self slot dropcmd "$self PathWidget_drop"
}

# Turn validation on or off
#
PathWidget method PathWidget_validation {x} {
	if {$x} {
		[$self primary] configure -validate key -validatecommand [list $self PathWidget_validate %P]
	} else {
		[$self primary] configure -validate none
	}
}

# Validate after each keypress, and set the background.
# We always accept the input, this just sets the background.
#
PathWidget method PathWidget_validate {v} {
	if {$v eq ""} {
		$self slot background white
		return 1
	}

	if {[Path validateAbs $v]} {
		if {[theSpace find $v] ne ""} {
			$self slot background white
			return 1
		}
	}
		
	$self slot background [Colors get invalidPath]
	return 1
}

# Command attached to significant events on primary
#
PathWidget method PathWidget_cmd {} {
	$self PathWidget_setEditPath [[$self slot _primary] cget -text]
}

# Clear the widget and set the edit object.  We may reset to the old value,
# if the provided value is invalid.
#
PathWidget method PathWidget_setEditPath {p} {
	if {![Path validate $p]} {
		UserMsg warning "|$self PathWidget_setEditPath $p| $p is not a valid path"
		$self slot text [$self slot text]
		return
	}

	$self slot text $p
	set n [$self slot notify]
	if {$n == ""} return

	lappend n $p
	eval $n
}

# Called when drag is initiated from a widget
#
PathWidget method PathWidget_draginit {path x y topLvl} {
	Window dragImage $topLvl [Thyrd getImage type-path]

	return [list SIGN {copy} [list Path [$self slot text]]]
}

# Called when a drop is hovering over an entry
#
PathWidget method PathWidget_dropover {args} {
	return 1
}

# Called when something is dropped on an entry
#
PathWidget method PathWidget_drop {path srcPath event op dtype data} {
	switch $dtype {
		TEXT {$self PathWidget_setEditPath $data}
		SIGN {
			lassign $data what src
			switch $what {
				Cell {$self PathWidget_setEditPath [$src path]}
				Path {$self PathWidget_setEditPath $src}
			}
		}
	}

	return 1
}
