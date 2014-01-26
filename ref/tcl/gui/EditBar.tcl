### The editing toolbar.  Contains the undo/redo buttons
### and mode-specific editing buttons.
###
###
# PJM	2007-05-07	Begun, derived from NavBar
# PJM	2008-02-11	Added type buttons
# PJM	2008-10-21	Work begun on atomic mode

Object construct EditBar
EditBar mixin CellObserver
EditBar mixin ParamListOwner
EditBar mixin Glommed
EditBar mixin Constrainable

# common params used by any window with an EditBar
EditBar slot _defaultParams {-undo "" -redo ""}

# Called to set up watching of the cells in the paramList
#
# The cells containing the back and forward history are
# read-only, we get their values from the cell here but
# afterwards only changes to the HistoryButtons matter.
#
EditBar method watchParams {pl} {
	$pl watchSub $self newPath path
	$pl watchSub! $self newMode mode
	$pl watchSub $self newSelection selectmode
	$pl watchSub $self newSelection select0
	$pl watchSub $self newSelection select1
	$pl watchSub $self newShowing showing

	# used when the undo/redo buttons were history buttons
	#[$self slot _undo] linkToCell [$pl subCell undo]
	#[$self slot _redo] linkToCell [$pl subCell redo]
}

#  Observer handler methods
#
#  These are invoked when the cells are changed externally,
#  we just need to reflect the changes
#
EditBar method newPath {target event} {
#	set path [$target get]

#	if {![$self pathDelta $path]} return
}

EditBar method newMode {target event} {$self showMode [$target get]}

# Set the local slot selMode so we can trigger constraints
#
EditBar method newSelection {{target {}} {event {}}} {
	$self slot selMode [$self getParam selectmode]
}

# Set the local slot showing so we can trigger constraints
#
EditBar method newShowing {{target {}} {event {}}} {
	$self slot showing [$self getParam showing]
	$self syncPane
}

# Invoked when the X/unX stacks on the captive waves change
#
EditBar method xEvent {{target {}} {event {}} {xlen {}} {unxlen {}}} {
	[$self slot _undo] slot state [? {$unxlen > 0} normal disabled]
	[$self slot _redo] slot state [? {$xlen > 0} normal disabled]
}

# Given a toolbar window (output of MainFrameTool addToolBarSlot)
# and a paramList cell, construct the editing bar.
#
# The child object is glommed onto the toolbar, so that when the toolbar
# is destroyed so is the EditBar object.
#
EditBar method new {tb pl} {
	set kid [[$self construct *] glomOnto $tb]

	$kid mixin Constrainable
	$kid slot paramList $pl
	$kid newSelection	;# sets selMode

	set ebt [$kid slot ebtypes [EditBarTypes construct *]]

	# Define formulas used to control button states below. Not all are used currently.
	set anySel [format {
		? {[%s slot selMode] ne "none"} normal disabled
		} $kid]

	set iSel [format {
		? {[%s slot selMode] eq "iselect"} normal disabled
		} $kid]

	set jSel [format {
		? {[%s slot selMode] eq "jselect"} normal disabled
		} $kid]

	set anySelOrAtomic [format {
		? {[%s slot selMode] ne "none" || [%s slot showing] eq "atomic"} normal disabled
		} $kid $kid]

	set col 0
	set b [$kid slot _undo [BW_Button construct * $tb -image [Thyrd getImage undo] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-state disabled \
		-helptext "Undo" \
		-layout "grid -column $col -row 0" -command "theSpace undo"]]

	incr col
	set b [$kid slot _redo [BW_Button construct * $tb -image [Thyrd getImage redo] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-state disabled \
		-helptext "Redo" \
		-layout "grid -column $col -row 0" -command "theSpace redo"]]
	
	# display controls that switch between grid and atomic/by type configurations
	incr col
	set sfg [$kid slot gridPane [Tk_Frame construct * $tb -borderwidth 0 -layout "grid -column $col -row 0 -sticky news"]]
	$ebt makeFrames $tb $col

	$sfg raise

	set subcol 0
	# panel used when viewing a grid
	set b [$kid slot _cut [BW_Button construct * $sfg -image [Thyrd getImage editcut] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Cut selected cells" \
		-layout "grid -padx 2 -column $subcol -row 0" -command "$kid do cut"]]

	$b formula state $anySel
	$b slotConstrain state

	incr subcol
	set b [$kid slot _copy [BW_Button construct * $sfg -image [Thyrd getImage editcopy] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Copy selected cells" \
		-layout "grid -padx 2 -column $subcol -row 0" -command "$kid do copy"]]

	$b formula state $anySel
	$b slotConstrain state

	incr subcol
	set b [$kid slot _paste [BW_Button construct * $sfg -image [Thyrd getImage editpaste] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Paste into selected cells" \
		-layout "grid -padx 2 -column $subcol -row 0" -command "$kid do paste"]]

	$b formula state [format {
		? {[%s slot selMode] ne "none" && [theSpace slot clipboard] ne ""} normal disabled
		} $kid]
	$b slotConstrain state

	incr subcol
	set b [$kid slot _makeGrid [BW_Button construct * $sfg -image [Thyrd getImage make-grid] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Make cell(s) into grid" \
		-layout "grid -padx 2 -column $subcol -row 0" -command "$kid do makeGrid"]]

	$b formula state $anySel
	$b slotConstrain state

	incr subcol
	set b [$kid slot _insCleft [BW_Button construct * $sfg -image [Thyrd getImage insert-column-left] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Insert column(s) to left of selection" \
		-layout "grid -padx 2 -column $subcol -row 0" -command "$kid do insertLeft"]]

	$b formula state $anySel
	$b slotConstrain state

	incr subcol
	set b [$kid slot _insCright [BW_Button construct * $sfg -image [Thyrd getImage insert-column-right] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Insert column(s) to right of selection" \
		-layout "grid -padx 2 -column $subcol -row 0" -command "$kid do insertRight"]]

	$b formula state $anySel
	$b slotConstrain state

	incr subcol
	set b [$kid slot _delC [BW_Button construct * $sfg -image [Thyrd getImage delete-column] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Delete column(s)" \
		-layout "grid -padx 2 -column $subcol -row 0" -command "$kid do deleteCol"]]

	$b formula state $anySel
	$b slotConstrain state

	incr subcol
	set b [$kid slot _insRabove [BW_Button construct * $sfg -image [Thyrd getImage insert-row-above] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Insert row(s) above selection" \
		-layout "grid -padx 2 -column $subcol -row 0" -command "$kid do insertAbove"]]

	$b formula state $anySel
	$b slotConstrain state

	incr subcol
	set b [$kid slot _insRbelow [BW_Button construct * $sfg -image [Thyrd getImage insert-row-below] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Insert row(s) below selection" \
		-layout "grid -padx 2 -column $subcol -row 0" -command "$kid do insertBelow"]]

	$b formula state $anySel
	$b slotConstrain state

	incr subcol
	set b [$kid slot _delR [BW_Button construct * $sfg -image [Thyrd getImage delete-row] \
		-relief link -borderwidth 1 -padx 1 -pady 1 \
		-helptext "Delete row(s)" \
		-layout "grid -padx 2 -column $subcol -row 0" -command "$kid do deleteRow"]]

	$b formula state $anySel
	$b slotConstrain state

	# end of grid pane

	incr col
	Tk_Frame construct * $tb -layout "grid -column $col -row 0"
	set pad $col

	incr col
	set b [$kid slot _typeSel [TypeSelector construct * $tb \
		-helptext "Set type of selected cells" \
		-layout "grid -column $col -row 0" -command "$kid setType"]]

	$b formula state $anySelOrAtomic
	$b slotConstrain state

	grid columnconfigure $tb $pad -weight 1

	$kid watchParams $pl
	theSpace addXObserver $kid xEvent

	return $kid
} 

# Handle the type set button, handled differently for 
# grid and atomic views.
#
EditBar method setType {ty0} {
	set showing [$self getParam showing]

	if {$showing eq "grid"} {
		$self do setType $ty0
	} else {
		set w [theSpace slot wave]
		set c [theSpace find [$self getParam path]]
		$w pushCell $c
		$w push [[$self slot ebtypes] fullType $ty0]
		$w execOp OpSetType
		if {[$w slot state] eq "error"} {
			UserMsg error "|$w do OpSetType $ty0| [$w slot error]"
		}
		theSpace setClipboard [$w peekUn]
	}
}
	
# Do an edit on a selection of cells
#
EditBar method do {which {arg1 {}}} {
	set sG [$self getParam selectGrid]
	set s0 [$self getParam select0]
	set s1 [$self getParam select1]

	if {$sG eq "" || $s0 eq "" || $s1 eq ""} {
		UserMsg error "|$self do $which| Nothing selected"
		return
	}

	set w [theSpace slot wave]

	$w clearFuture
	lassign [Grid selRange $s0 $s1] i0 j0 i1 j1

	switch $which {
		cut {
			$self clearSelection
			$w pushCell $sG
			$w pushInts $i0 $j0 $i1 $j1
			$w execOp OpCutCells
			if {[$w slot state] eq "error"} {
				UserMsg error "|$w do OpCutCells| [$w slot error]"
			}
			theSpace setClipboard [$w peekUn]
		}
		copy {
			$self clearSelection
			$w pushCell $sG
			$w pushInts $i0 $j0 $i1 $j1
			$w execOp OpCopyCells
			if {[$w slot state] eq "error"} {
				UserMsg error "|$w do OpCopyCells| [$w slot error]"
			}
			theSpace setClipboard [$w peekUn]
		}
		paste {
			$self clearSelection
			set b [theSpace getClipboard]
			if {$b eq ""} {
				UserMsg error "|$self do $which| Clipboard is empty"
			} else {
				$w pushCell $b
				$w pushCell $sG
				$w pushInts $i0 $j0
				$w execOp OpPasteCells
				if {[$w slot state] eq "error"} {
					UserMsg error "|$w do OpPasteCells| [$w slot error]"
				}
			}
		}
		makeGrid {
			$self clearSelection
			$w pushCell $sG
			$w pushInts $i0 $j0 $i1 $j1
			$w execOp OpMakeGrid
			if {[$w slot state] eq "error"} {
				UserMsg error "|$w do OpMakeGrid| [$w slot error]"
			}
			theSpace setClipboard [$w peekUn]
		}
		insertLeft {
			$self clearSelection
			set n [- $i1 $i0 -1]
			$w pushCell $sG
			$w pushInts [- $i0 1] $n
			$w execOp OpInsertCols
			if {[$w slot state] eq "error"} {
				UserMsg error "|$w do OpInsertCols| [$w slot error]"
			}
		}
		insertRight {
			$self clearSelection
			set n [- $i1 $i0 -1]
			$w pushCell $sG
			$w pushInts $i1 $n
			$w execOp OpInsertCols
			if {[$w slot state] eq "error"} {
				UserMsg error "|$w do OpInsertCols| [$w slot error]"
			}
		}
		deleteCol {
			$self clearSelection
			$w pushCell $sG
			$w pushInts $i0 $i1
			$w execOp OpDeleteCols
			if {[$w slot state] eq "error"} {
				UserMsg error "|$w do OpDeleteCols| [$w slot error]"
			}
			theSpace setClipboard [$w peekUn]
		}
		insertAbove {
			$self clearSelection
			set n [- $j1 $j0 -1]
			$w pushCell $sG
			$w pushInts [- $j0 1] $n
			$w execOp OpInsertRows
			if {[$w slot state] eq "error"} {
				UserMsg error "|$w do OpInsertRows| [$w slot error]"
			}
		}
		insertBelow {
			$self clearSelection
			set n [- $j1 $j0 -1]
			$w pushCell $sG
			$w pushInts $j1 $n
			$w execOp OpInsertRows
			if {[$w slot state] eq "error"} {
				UserMsg error "|$w do OpInsertRows| [$w slot error]"
			}
		}
		deleteRow {
			$self clearSelection
			$w pushCell $sG
			$w pushInts $j0 $j1
			$w execOp OpDeleteRows
			if {[$w slot state] eq "error"} {
				UserMsg error "|$w do OpDeleteRows| [$w slot error]"
			}
			theSpace setClipboard [$w peekUn]
		}
		setType {
			$w pushCell $sG
			$w pushInts $i0 $j0 $i1 $j1 
			$w push $arg1
			$w execOp OpRangeSetType
			if {[$w slot state] eq "error"} {
				UserMsg error "|$w do OpRangeSetType $arg1| [$w slot error]"
			}
			theSpace setClipboard [$w peekUn]
		}
	}

}

# Clear the selection
#
EditBar method clearSelection {} {
	$self setParamIgnore selectGrid ""
	$self setParamIgnore select0 ""
	$self setParamIgnore select1 ""
	$self setParam selectmode none
}

# Show the given mode
#
EditBar method showMode {m} {
}

# Sync to the current showing/atomic type
#
EditBar method syncPane {} {
	if {[$self slot showing] eq "grid"} {
		[$self slot gridPane] raise
		[$self slot ebtypes] syncToCell ""
	} else {
		[$self slot gridPane] lower
		$self syncToAtomicType
	}
}

# Sync to the currently displayed atomic cell's
# type
#
EditBar method syncToAtomicType {} {
	set ts [$self slot _typeSel]
	$ts slot state normal

	set c [theSpace find [$self getParam path]]

	$ts setSelected [$c getType true]
	[$self slot ebtypes] syncToCell $c 
}

# Clean up after ourselves
#
EditBar method destruct {} {
	Object safe [$self slot ebtypes] destruct
	$self as Object destruct
}
