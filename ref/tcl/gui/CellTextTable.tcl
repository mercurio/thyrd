# CellTextTable - Scrolled ZoomTable displaying the frame and contents of a cell as text
#
# PJM 2005-09-01	Begun, derived from ObjectSlotTable
# PJM 2006-02-28	Now an observer of a NavBar
# PJM 2006-05-08	Code common to all table views moved to CellTable
#

BW_ScrolledWindow construct CellTextTable
CellTextTable mixin CellTable
CellTextTable mixin CellObserver

# Override BW_ScrolledWindow defaults
CellTextTable slot relief sunken
CellTextTable slot borderwidth 2


# Build the primary for a CellTextTable, then start watching
# the parameter cells
#
CellTextTable method buildPrimary {} {
	$self destroyPrimary

	$self slot prebuildOptions ""	;# not needed by BW_Scrolled_Window
	set prim [$self as BW_ScrolledWindow buildPrimary]

	set tab [$self slot _table [ZoomTable construct * $self -rows 0 -cols 0 \
		-titlerows 0 -cache 1 -rowheight -18 -ipadx 4 -ipady 2\
		-colwidth 20 -flashmode 0 -flashtime 2 \
		-dragenabled 1 -dragevent 1 -draginitcmd "$self draginit" \
		-dropenabled 1 -dropcmd "$self dropcmd" \
		-highlightcolor black -highlightbackground #ECFCEC -invertselected 0 \
		-validate 1 -validatecommand "$self validateCell %c %r %s %S" \
		-selecttype cell -selectmode single -background white]]
	
	$tab slot tool [$self slot tool]

	$tab tag configure sel -foreground black -background #ECFCEC

	$tab tag configure flash -background [Colors get flashBG]

	$tab tag configure iFrame-int -relief flat -foreground [Colors get frameFG] -background [Colors get iFrameBG] \
		-justify center -anchor c -state disabled -font frame-int

	$tab tag configure jFrame-int -relief flat -foreground [Colors get frameFG] -background [Colors get jFrameBG] \
		-justify center -anchor c -state disabled -font frame-int

	$tab tag configure iFrame-str -relief raised -foreground [Colors get frameFG] -background [Colors get iFrameBG] \
		-justify center -anchor c -state disabled -font frame-str

	$tab tag configure jFrame-str -relief raised -foreground [Colors get frameFG] -background [Colors get jFrameBG] \
		-justify center -anchor c -state disabled -font frame-str

	$tab tag configure atom -foreground [Colors get cellFG] -background [Colors get cellBG] \
		-justify left -anchor nw -state normal -font cell -multiline 1

	$tab tag configure zero-int -foreground [Colors get zeroFG] -background [Colors get zeroBG] \
		-justify center -anchor c -state disabled -font frame-int

	$tab tag configure zero-str -foreground [Colors get zeroFG] -background [Colors get zeroBG] \
		-justify center -anchor c -state disabled -font frame-str

	$tab tag configure grid -relief sunken -background [Colors get gridBG] \
		-justify center -anchor c -state disabled -image [Thyrd getImage big-grid]

	$tab tag configure empty -foreground [Colors get emptyFG] -background [Colors get emptyBG] \
		-justify left -anchor nw -state disabled -font cell -multiline 1

	$tab bind <Return> "$self nextLine ; break"
	$tab bind <KP_Enter> "$self nextLine ; break"
	$tab bind <Down> "$self nextLine ; break"
	$tab bind <Up> "$self nextLine -1 ; break"

	$tab bind <Home> {%W icursor 0 ; break}
	$tab bind <End> {%W icursor end ; break}

	$self setwidget [$tab slot _primary]


	$tab modeBind edit <1> {}
	$tab modeBind newview <1> {continue}
	$tab modeBind move <1> {continue}
	$tab modeBind descend <1> {
		%Z navdownEvent %W %x %y
		break
	}

	$self watchParams [$self slot paramList]

	return $prim
}


# A navigation down event
#
CellTextTable method navdownEvent {w x y} {
	set c [$self viewCell]
	set c [$c subCell [$w index @$x,$y col] [$w index @$x,$y row]]

	Object safe [$self slot tool] navdown $c
}

# Go to the next line, setting the slot in the current cell.
# The current cell may be displaying an inherited slot, in which
# case we prompt to see if it should be set on the editCell. 
#
CellTextTable method nextLine {{offset 1}} {
	set tab [$self slot _table]
	set tp [$tab slot _primary]
	set r [$tp index active row]
	set c [$tp index active col]

if 0 {  ;# DEFERRED
	set o [$self viewCell]
	set oldvalue [$tab get $r,$c]
	set slotname [$tab get $r,[expr $c - 1]]
	set slottype [$o type $slotname]

	set newvalue [$tp curvalue]

	if {[$self slot typeSafe] && ![CoreType validate $newvalue $slottype]} {
		UserMsg warning "\"$newvalue\" can't be interpreted as type $slottype"
		$tp curvalue $oldvalue
		return
	}

	set doIt 1

	if {[$self slot showAllSlots]} {
		set slotobj [$tab get $r,1]
		if {$slotobj != $o} {
			set reply [UserMsg yesno "Slot $slotname is inherited from $slotobj.  Set new value on $o?"]
			if {$reply == "yes"} {
				$self fillRow $r $o $slotname
			} else {set doIt 0}
		}
	}

	if {$doIt} {$o slot $slotname $newvalue}
}

	# Advance to next line
	$tp activate [incr r $offset],$c
	$tp icursor end
	$tp see active
}

## CellTable API
##

# Unrender (delete all the rows of the table)
#
CellTextTable method unrender {} {
	set tab [$self slot _table]
	set tp [$tab slot _primary]

	$tab delete rows 0 [expr [$tp index end row] + 1]
}

# Render no cell (viewCell is "")
#
CellTextTable method renderNoCell {} {
	set tab [$self slot _table]
	set tp [$tab slot _primary]

	$tp configure -cols 1 -rows 1 -colstretchmode last -rowstretchmode last
	$tab set 0,0 ""
	$tp tag cell empty 0,0
}

# Render an atomic cell
#
CellTextTable method renderAtomic {c} {
	Object safe $c addObserver * $self cellEvent

	set tab [$self slot _table]
	set tp [$tab slot _primary]

	$tp configure -cols 1 -rows 1 -colstretchmode last -rowstretchmode last
	$tab set 0,0 [$c get]
	$tp tag cell atom 0,0
}
		
# Render a grid full of cells
#
CellTextTable method renderGrid {c} {
	Object safe $c addObserver * $self cellEvent

	set tab [$self slot _table]
	set tp [$tab slot _primary]

	foreach {iSize jSize} [$c size] break

	if {$iSize == 0 || $jSize == 0} return

	$tp configure -cols $iSize -rows $jSize -colstretchmode unset -rowstretchmode unset
	$tp height 0 2
	$tp width 0 10

	foreach {wi wj} [$c as CMGrid walk full] {
		set wc [$c as CMGrid getCell $wi $wj]

		$self renderSub $wc 
	}
}

# Unrender a grid cell
#
CellTextTable method unrenderSub {c} {
	$self renderSub "" -ij [$c coords]
}

# Render one grid cell, possibly expanding the table.
# If the table is not provided we use the default
#
# Options:
#	-ij		coords, needed if $c eq ""
#
CellTextTable method renderSub {c args} {
	array set opts $args
	Object safe $c addObserver * $self cellEvent

	if {[info exists opts(-ij)]} {
		foreach {i j} $opts(-ij) break
	} else {
		foreach {i j} [$c coords] break
	}

	set tab [$self slot _table]
	set tp [$tab slot _primary]

	set ti [$tp cget -cols]
	set tj [$tp cget -rows]
	
	set newi [expr {$ti <= $i} ? [expr $i - $ti + 1] : 0]
	set newj [expr {$tj <= $j} ? [expr $j - $tj + 1] : 0]

	if {$newi || $newj} {
		if {$newi} {$tp insert cols $ti $newi}
		if {$newj} {$tp insert rows $tj $newj}

		# DEFERRED   tag new cells empty
	}

	# Now render the cell at $j,$i

	if {$c eq ""} {
		$tp tag cell empty $j,$i
		$tab set $j,$i ""
		return
	}


	if {[$c atomic]} {
		set v [$c get]
	} else {
		set z [$c getAt 0]
		if {$z eq ""} {
			set v ""
		} else {
			set v [$z get]
		}
	}

	if {$i == 0 && $j == 0} {
		if {$v eq ""} {
			$tp tag cell zero-int $j,$i
			$tab set $j,$i 0
		} else {
			$tp tag cell zero-str $j,$i
			$tab set $j,$i $v
		}
	} elseif {$j == 0} {	
		if {$v eq ""} {
			$tp tag cell iFrame-int $j,$i
			$tab set $j,$i $i
		} else {
			$tp tag cell iFrame-str $j,$i
			$tab set $j,$i $v
		}
	} elseif {$i == 0} {
		if {$v eq ""} {
			$tp tag cell jFrame-int $j,$i
			$tab set $j,$i $j
		} else {
			$tp tag cell jFrame-str $j,$i
			$tab set $j,$i $v
		}
	} else {
		if {[$c atomic]} {
			$tp tag cell atom $j,$i
		} else {
			$tp tag cell grid $j,$i
		} 
		$tab set $j,$i $v
	}
}

# Validate a new cell value.  We're given the i and j coordinates
# and the old and new values.  If it's OK, we set the cell, which
# should cause it to be updated in all other displays.
#
CellTextTable method validateCell {i j old new} {
	set c [$self viewCell]

	if {[$c atomic]} {
		if {$i != 0 || $j != 0} {
			UserMsg error "|$self validateCell $i $j ...| View cell is atomic, i and j should be 0"
			return
		}
	} else {
		set c [$c subCell $i $j]
		if {$c eq ""} {
			UserMsg error "|$self validateCell $i $j ...| Subcell to cell $c can't be found"
			return
		}
	}

	if {[$c validate $new]} {
		Observer ignore $self $c {$c set $new}
		return true
	} else {
		return false
	}
}

# Called when drag is initiated from a CellTextTable.
#
CellTextTable method draginit {path row col topLvl} {
	set tab [$self slot _table]

	#theThyrdToolbox drag $path [$tab get $row,$col]
	#$path config -cursor dot
	return [list TEXT [list copy] [$tab get $row,$col]]
}

# Called when a drop occurs on a CellTextTable
#
CellTextTable method dropcmd {target src row col op type data} {
	set tab [$self slot _table]

	if {[$self validateCell $col $row [$tab get $row,$col] $data]} {
		$tab set $row,$col $data
	}

	return 1
}

### From tier3, here as examples:

# Fill row r with the slot {o s}.  We find the CoreType object
# and ask it if an embedded window should be created for
# editing this slot.
#
CellTextTable method fillRow {r o s} {
	set tab [$self slot _table]
	set tp [$tab slot _primary]
	set eo [$self slot editCell]

	set e [TypeSlot encodeCellSlot $o $s]

	set ty [$o type $s]
	if {$ty == ""} {
		set to TypeNull
		set ty [set ta [$to slot tag]]
	} else {
		set to [CoreType getTypeCell $ty]
		if {$to == ""} {
			set to [lindex {TypeCellect TypeNull} [string match <*> $ty]]
		}
		set ta [$to slot tag]
	}

	set val [$o slot $s]
	if {[string match "*\n*" $val]} {set val <multiline>}

	if {[$self slot showAllSlots]} {
		$tp set row $r,0 [list $e $o $s $val $ta]

		$tp tag cell $e $r,0 

		if {$o == $eo} {
			$tp tag cell slot-name-lo $r,1 
			$tp tag cell slot-name-lo $r,2 
			set vTag slot-value
		} else {
			$tp tag cell slot-name-in $r,1 
			$tp tag cell slot-name-in $r,2 
			set vTag slot-inherited
		}

		set vCol 3
		set tCol 4
	} else {
		$tp set row $r,0 [list $e $s $val $ta]

		$tp tag cell $e $r,0 
		$tp tag cell slot-name-lo $r,1 

		set vCol 2
		set tCol 3
		set vTag slot-value
	}

	
	if {$o == $eo} {
		set ce [$to cellEditor $tab $ty]
		if {$ce != ""} {
			$ce SignCell_setCellSlot $eo $s
			$tp window configure ${r},${vCol} -window [$ce slot _primary] -sticky news
		} else {
			$tp tag cell $vTag ${r},${vCol} 
		}
	} else {
		set ce [SignCellCover construct * $tab $o $eo $s "$self fillRow $r $eo $s"]
		$tp window configure ${r},${vCol} -window [$ce slot _primary] -sticky news
	} 

	$tp tag cell type-$ta  ${r},${tCol} 
}

# Called only on an all-slots table, when the current inherited
# slot is being edited and thus becoming local.  The user has already
# approved it. A new cellEditor will be created.
#
CellTextTable method localizeRow {tab r {to ""}} {
	set eo [$self slot editCell]
	$tab set $r,1 $eo
 	set tp [$tab slot _primary] 
 	$tp tag cell slot-value $r,3

	if {$ce != ""} {
		$tp window configure ${r},3 -window [$ce slot _primary] -sticky news
	}
}

# Called when a trace happens on the slot dimension of the object
# we're editing.  We're called with the true array name of the 
# object's slot dimension, the slot, and the op.  If necessary,
# we create a new row in the table.
#
# If the op is u, the editCell is being deleted and we need to 
# detach from it.
#
CellTextTable method slotDimChange {arrayName slot op} {
	if {$op == "u"} {
		$self setEditCell ""
		return
	}

	set tp [[$self slot _table] slot _primary]
	set i [$self slotSearch _slotList $slot -exact]

	if {$i == -1} {
		set i [$self slotInsertSorted _slotList $slot]
		$tp see $i,0

		if {[$self slotLength _slotList] == [expr $i + 1]} {
			$tp insert rows $i 1
			$self fillRow $i [$self slot editCell] $slot
		} else {
			$tp insert rows $i -1
			$self fillRow $i [$self slot editCell] $slot
		}
	} else {
		$tp see $i,0
		switch $op {
			w	{
				$tp set $i,[expr [$self slot showAllSlots] + 2] [set ::${arrayName}($slot)]
			}
			u {
				$tp delete rows $i 1
				$self slotRemove _slotList $slot
			}
		}
	}
}

# Return the list of selected slots
#
CellTextTable method getSelected {} {
	set tab [$self slot _table]
	if {$tab == ""} return {}

	set res {}
	foreach i [$tab curselection] {
		regexp (.*),(.*) $i junk r c
		if {$c == 0} {
			lappend res [$tab get $r,1]
		}
	}

	return $res
}

# Set the mode
#
CellTextTable method modeSelect {m} {
	set tab [$self slot _table]
	$tab modeSelect $m
}

# Set the depth (ignored)
#
CellTextTable method setDepth {d} {
}
