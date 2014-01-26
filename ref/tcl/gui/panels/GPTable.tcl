# GPTable -- a control panel for cell containing
# a grid of subcells, consisting of a tablelist.
#
# PJM 2008-02-14	Begun
# PJM 2008-04-01	dragcol mostly implemented, but not useful, so not used

GridPanel construct GPTable

# If true, don't allow any editing
#
GPTable slot readonly	0
GPTable type readonly	<boolean>

# If true, flip table so i goes down instead of across
#
GPTable slot flip		0
GPTable type flip		<boolean>

# If specified, the name of the row or column containing filtering tags
#
GPTable slot filter		""
GPTable type filter		<string>

# If specified, dragging anywhere in a row is like dragging
# from the cell in this column. -1 disables this feature.
#
GPTable slot dragcol	-1
GPTable type dragcol	"<integer> -1"

# If specified, drags are set to FORCE rather than Cell
#
GPTable slot dragforce	0
GPTable type dragforce	<boolean>

# Given the parent widget and the cell, construct
# and return the panel
#
GPTable method build {mom tool c {opts {}} {w {}} {h {}}} {
	set kid [$self construct *]
	$kid slot tool $tool

	foreach {o v} $opts {$kid slot [string range $o 1 end] $v}

	$kid slot _gridCell $c

	array set tblopts {
		-arrowcolor red
		-width 0
		-height 8
		-action default
		-scrollauto xy
		-tableoptions stripe 
		-relief groove
		-selectfirst 0
		-sortfirst 0
	}

	set tblopts(-editstartcommand) [list $kid editStart]
	set tblopts(-editendcommand) [list $kid editEnd]

	if {[$kid slot readonly]} {
		set sopts [list -selecttype row -selectmode browse]
	} else {
		set sopts [list -selecttype cell -selectmode single]
	}

	if {[$kid slot filter] eq ""} {
		set top [set table $mom.[Object safeName [Object anon]]]
	} else {
		set top $mom.[Object safeName [Object anon]]
		ttk::panedwindow $top -orient horizontal

		gridplus::gridplus checkbutton $top.cb -title Filter \
			-padx 3 -scrollauto xy -stretchy 0 -ccmd [list $kid doFilter] \
			[$kid filterCBs $c]
		set table $top.table
		$kid slot _cbs $top.cb

		foreach i [winfo children $top.cb] {
			if {[string match *Label [winfo class $i]]} {
				bind $i <ButtonPress-1> [list $kid doFilterLabelClick [$i cget -text]]
				bind $i <Double-ButtonPress-1> [list $kid doFilterLabelDoubleClick [$i cget -text]]
				bind $i <Enter> [list $i configure -foreground [Colors get labelHilite]]
				bind $i <Leave> [list $i configure -foreground {}]
			}
		}
	}

	gridplus::gridplus tablelist $table {*}[array get tblopts] \
		[$kid header $c]

	set tbl ${table}.tablelist
	$tbl configure -stripebackground [Colors get stripeBG] {*}$sopts

	DragSite::register [$tbl bodypath] -dragevent 1 -draginitcmd [list $kid dragFromTable] 

	$kid glomOnto $top
	$kid slot _tbl $tbl

	$kid fillTable $tbl $c

	if {[$kid slot filter] eq ""} {
		pack $top -expand 1 -fill both
	} else {
		$top add $top.cb -weight 0
		$top add $top.table -weight 1
		pack $top -expand 1 -fill both
	}
	
	return $top
} 

# Return the gridplus configuration for the filter tags on the
# given cell.
#
GPTable method filterCBs {c} {
	set x [$c slot core]
	set f [$self slot filter]

	if {![$self slot flip]} {
		set i [$x findIFrame $f]
		if {$i == -1} {
			UserMsg warning "|$self filterCBs $c| Filter column $f not found in [$c path]"
			return
		}

		set coords [list $i 1 $i endj]
	} else {
		set j [$x findJFrame $f]
		if {$j == -1} {
			UserMsg warning "|$self filterCBs $c| Filter row $f not found in [$c path]"
			return
		}

		set coords [list 1 $j endi $j]
	} 


	foreach {wi wj} [$x walk $coords] {
		set ts [[$x getCell $wi $wj] get]
		foreach t $ts {
			set tags($t) 1
		}
	}

	set ts [$self slot _tags [lsort [array names tags]]]
	set out ""
	foreach t $ts {
		append out "{$t .$t +}\n"
	}

	return $out
}

# The filter selection has changed, hide or unhide the
# correct rows
#
GPTable method doFilter {} {
	global {}
	set flip [$self slot flip]
	set cbs [$self slot _cbs]
	set tbl [$self slot _tbl]

	set gc [$self slot _gridCell]
	lassign [$gc size] si sj

	set x [$gc slot core]

	if {!$flip} {
		set col i
		set row j
		set rows [- $sj 1]
		set fc [$x findIFrame [$self slot filter]]
	} else {
		set col j
		set row i
		set rows [- $si 1]
		set fc [$x findJFrame [$self slot filter]]
	}

	set tc [$self slot filter]

	for {set r 0} {$r < $rows} {incr r} {
		if {!$flip} {
			set ts [[$x getCell $fc [+ $r 1]] get]
		} else {
			set ts [[$x getCell [+ $r 1] $fc] get]
		}

		set hide 1
		foreach t $ts {
			if {[set ($cbs,$t)]} {
				set hide 0
				break
			}
		}

		$tbl rowconfigure [$tbl index k$r] -hide $hide
	}
}

# A click has occured on one of the labels. 
# Make that label the only one selected.
#
GPTable method doFilterLabelClick {which} {
	global {}
	set cbs [$self slot _cbs]
	set tags [$self slot _tags]

	foreach t $tags {
		if {$t eq $which} {
			set ($cbs,$t) 1
		} else {
			set ($cbs,$t) 0
		}
	}

	$self doFilter
} 

# A double click has occured on one of the labels.
# Toggle the labels.
#
GPTable method doFilterLabelDoubleClick {which} {
	global {}
	set cbs [$self slot _cbs]
	set tags [$self slot _tags]

	set x [set ($cbs,$which)]
	set nx [expr !$x]

	foreach t $tags {
		if {$t eq $which} {
			set ($cbs,$t) $nx
		} else {
			set ($cbs,$t) $x
		}
	}

	$self doFilter
} 

# Return the header list as used by gridplus for the given cell
#
GPTable method header {c} {
	set header [list]

	if {![$self slot flip]} {
		if {[$c as CMGrid hasFrameValues j]} {
			lappend header 0 "" left
		}
		
		foreach {wi wj} [$c as CMGrid walk iframe] {
			set t [$c peekAt $wi $wj]
			if {$t eq ""} {
				lappend header 0 "($wi)" left
			} else {
				lappend header 0 $t left
			}
		}
	} else {
		if {[$c as CMGrid hasFrameValues i]} {
			lappend header 0 "" left
		}
			
		foreach {wi wj} [$c as CMGrid walk jframe] {
			set t [$c peekAt $wi $wj]
			if {$t eq ""} {
				lappend header 0 "($wj)" left
			} else {
				lappend header 0 $t left
			}
		}
	}

	return $header
}

# Fill the table from the given cell
#
GPTable method fillTable {tbl c} {
	lassign [$c size] si sj

	if {![$self slot flip]} {
		set col i
		set row j
		set rows [- $sj 1]
	} else {
		set col j
		set row i
		set rows [- $si 1]
	}

	set hasFC [$self slot _hasFirstColumn [$c as CMGrid hasFrameValues $row]]

	for {} {$rows > 0} {incr rows -1} {
		$tbl insert end ""
	}

	if {$hasFC} {
		foreach {wi wj} [$c as CMGrid walk ${row}frame] {
			set t [$c peekAt $wi $wj]
			if {$t eq ""} {
				set t "([set w$row])"
			}

			incr w$row -1
			$tbl cellconfigure [set w$row],[set w$col] -text $t -editable 0 -foreground [Colors get frameFG-str] \
				-selectforeground [Colors get frameFG-str] \
				-background [Colors get ${row}FrameBG]
		}
	}

	foreach {wi wj} [$c as CMGrid walk [list 1 1 endi endj]] {
		set wc [$c subCell $wi $wj]

		incr w$row -1
		if {!$hasFC} {incr w$col -1}

		$self drawCell $tbl $wc [set w$row],[set w$col]
		Object safe $wc addObserver * $self cellEvent
	}
}

# Return the row,column for a subcell. We take the 
# table's sort order into account.
#
GPTable method cell2rc {c tbl} {
	set i [$c slot i]
	set j [$c slot j]

	if {![$self slot flip]} {
		incr j -1
		if {![$self slot _hasFirstColumn]} {incr i -1}

		return [$tbl index k$j],$i
	} else {
		incr i -1
		if {![$self slot _hasFirstColumn]} {incr j -1}

		return [$tbl index k$i],$j
	}
}

# Given a row and column compute the i and j
# and return the cell at that location. This is
# the raw row and column, unaffected by the sort order.
#
GPTable method rc2cell {r c} {
	if {![$self slot flip]} {
		set j [+ $r 1]
		set i $c

		if {![$self slot _hasFirstColumn]} {incr i 1}
	} else {
		set i [+ $r 1]
		set j $c

		if {![$self slot _hasFirstColumn]} {incr j 1}
	}

	return [[$self slot _gridCell] subCell $i $j]
}

# Display the given cell in the table at the coords (in tablelist
# cell index form).
#
GPTable method drawCell {tbl c where} {
	if {$c eq ""} {
		$tbl cellconfigure $where -image [Thyrd getImage empty]
		return
	}

	lassign [$self editWindow $c] ew ed
	if {[$self slot readonly]} {
		set ed 0
	}

	if {$ew ne ""} {
		$tbl cellconfigure $where -text [$c peek] -editwindow $ew -editable $ed
	} else {
		set x [$c slot core]
		switch [$x slot displayKey] {
			value {
				$tbl cellconfigure $where -text [$c peek] -editable $ed
			}
			grid {
				$tbl cellconfigure $where -window [list $self createGridButton $c]
			}
			icon {
				$tbl cellconfigure $where -window [list $self createDraggableIcon $c]
			}
		}
	}
}

# Override destruct to clear out observers
#
GPTable method destruct {} {
	Observer unobserveAll $self
	$self as GridPanel destruct
}


# Update according to the given observer message.  
#
GPTable method cellEvent {target event args} {
	set rc [$self slot _gridCell]
	set rootEvent [string equal $target $rc]
	set tbl [$self slot _tbl]

	switch [lindex $event 0] {
		write {
			if {$rootEvent} {
				#DEFERRED
			} else {
				$self drawCell $tbl $target [$self cell2rc $target $tbl]
			}
		}

		read {
			# DEFERRED handle reads
			return
		}

		empty {
			if {$rootEvent} {
				#DEFERRED
			} else {
				if {$target ne ""} {
					$self drawCell $tbl $target [$self cell2rc $target $tbl]
				}
			}
		}

		destruct {
			if {$rootEvent} {
				#DEFERRED
			} else {
				if {$target ne ""} {
					#DEFERRED
					$target deleteObserver * $self
				}
			}
		}

		gainSub {
			if {$rootEvent} {
				lassign $args subC i j

				#$self renderSub $subC
				#Object safe $subC addObserver * $self cellEvent
			}
		}

		loseSub {
			if {$rootEvent} {
				lassign $args subC i j

				#$self unrenderSub $subC 
				#Object safe $subC deleteObserver * $self
			}
		}

		newPlace {
			if {[$target slot container] eq ""} {
				#$self unrenderSub $target
				#$target deleteObserver * $self
			} else {
				#$self renderRoot
			}
		}

		xstatus {
			#DEFERRED we should handle this--change cell background?
		}

		paused {
			#DEFERRED we should handle this--change cell background?
		}

		default {
			UserMsg error "|$self cellEvent $target $event $args| Unrecognized event message"
		}
	}

	update idletasks
}

# Return the edit window type for a cell of the given type.
# If nothing is returned, the cell type is not editable.
# We also return whether it's editable or not.
#
# DEFERRED not done yet
#
GPTable method editWindow {c} {
	if {$c eq ""} {return ""}

	switch [$c getType yes] {
		<boolean>	{return [list ttk::checkbutton 1]}
		<integer>	{return [list spinbox 1]}
		<real>		{return [list spinbox 1]}
		<choice>	{return [list ttk::combobox 1]}
		<pixels>	{return [list spinbox 1]}
		<color>		{return [list ttk::entry 1]}
		<font>		{return [list ttk::entry 1]}
		<string>	{return [list ttk::entry 1]}
		<variable>	{return [list ttk::entry 1]}
		<script>	{return [list ttk::entry 1]}
		Path		{return [list ttk::entry 1]}
		Opcode		{return [list "" 0]}
		default		{return [list "" 0]}
	}
}

proc setDef {v val} {
	upvar $v vv
	if {$vv eq ""} {set vv $val}
}

# Apply some configuration options to the edit window; if the latter is a
# combobox, the procedure populates it.
#
GPTable method editStart {tbl row col text} {
    set w [$tbl editwinpath]

	set c [$self rc2cell $row $col]
	if {$c eq ""} {return}	

	set ct [$c getType] 
	lassign $ct t t0 t1 t2

	switch $t {
		<boolean>	{}
		<integer>	{
			setDef t0 -2147483648
			setDef t1 2147483647
			setDef t2 1

			$w configure -from $t0 -to $t1 -increment $t2
		}
		<real>	{
			setDef t0 -1.0
			setDef t1 1.0
			setDef t2 0.1

			$w configure -from $t0 -to $t1 -increment $t2
		}
		<choice>	{
			$w configure -values [lrange $ct 1 end]
		}
		<pixels>	{
			setDef t0 0
			setDef t1 4096
			setDef t2 1

			$w configure -from $t0 -to $t1 -increment $t2
		}
		<color>		{}
		<font>		{}
		<string>	{}
		<variable>	{}
		<script>	{}
		Path		{}
		Opcode		{}
		default		{}
	}

    return $text
}

# Perform a final validation of the text contained in the edit window
# and set the corresponding Thyrd cell.
#
GPTable method editEnd {tbl row col text} {
	set c [$self rc2cell $row $col]
	if {$c eq ""} {return}	

	$c set $text

    return $text
}

# Create a button that causes descent into a grid
# when pressed
#
GPTable method createGridButton {cell tbl r c w} {
	set x [$cell slot core]
	lassign [$x size] i j

	ttk::button $w -compound left -image [Thyrd getImage glyph-grid] \
		-text "([- $i 1] x [- $j 1])" -command [list [$self slot tool] jump $cell]
}

# Create a draggable icon widget.  The core of the cell is
# provided along with the tablelist arguments.
#
GPTable method createDraggableIcon {cell tbl r c w} {
	set x [$cell slot core]
	ttk::label $w -image [$x getIcon sm]

	DragSite::register $w -dragevent 1 -draginitcmd [list $self dragInit $cell [$x getGlyph]] 
}

# Called when a drag is initiated from the table.  If
# dragcol is not set, this does nothing.
#
GPTable method dragFromTable {path rx ry topLvl} {
	set dc [$self slot dragcol]
	if {$dc < 0} {return ""}

	set tbl [$self slot _tbl]
	set y [- $ry [winfo rooty $tbl]]
	set r [$tbl containing $y]

	set c [$tbl getcells $r,$dc]
	#DEFERRED this is empty, since there's an icon there.
	# Since dragging on the table causes the selection to
	# change, this doesn't look right anyway. If desired,
	# we'd have to inspect the tablelist cell to infer
	# what Thyrd cell it's representing.
return ""
	Window dragImage $topLvl $im

	if {[$self slot dragforce]} {
		return [list SIGN {copy} [list FORCE-Cell $cell]]
	} else {
		return [list SIGN {copy} [list Cell $cell]]
	}
}


# Called when a drag is initiated from an icon
#
GPTable method dragInit {cell im path x y topLvl} {
	Window dragImage $topLvl $im

	if {[$self slot dragforce]} {
		return [list SIGN {copy} [list FORCE-Cell $cell]]
	} else {
		return [list SIGN {copy} [list Cell $cell]]
	}
}

# Total KLUDGE to get drag and drop working with zinc canvases.
#
# If we recognize that we're dropped over a canvas, tell the 
# CellZincTable.
#
# NOTUSED
#
GPTable method dragEnd {source target op type data result} {
	lassign [winfo pointerxy .] x y
	set p [winfo containing $x $y] 

	if {![regexp {.*frame\.x(.*)\.zf\.z} $p -> obj]} return
	set obj *$obj
	if {![Object existsAs $obj CellZincTable]} return

	$obj dropOn $x $y $type $data
}


