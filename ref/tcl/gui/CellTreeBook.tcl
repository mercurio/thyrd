# CellTreeBook - BWidget NoteBook full of trees displaying a cell and its
# various relationships to other cells
#
# PJM	2005-09-14	Begun, based on ObjectTreeBook
# PJM	2006-03-17	Triad display begun
#

BW_NoteBook construct CellTreeBook
CellTreeBook mixin CellObserver

# Options that must be specified at creation time
CellTreeBook slot extraOptions {paramList tool}

CellTreeBook slot relationships {A B Y}

#
# Write-active slots
#
CellTreeBook method rootPath> {value} {
	set p [$self slot _primary]
	if {$p == ""} {return}

	$self pathDelta $value

	set c [$self viewCell]
	set ok [expr {$c ne ""}]

	foreach t [$self slot _trees] {
		$t delete [$t nodes root]

		if {$ok} {
			$t insert end root _otree_root_ -text $value -data $value -open 1 \
				-image [$c getIcon]
			$t itemconfigure _otree_root_ -font bold -fill red
			$self getKids $t _otree_root_
			$t slot redraw 1
		}
	}

	$p compute_size
}



# Build the primary for an CellTreeBook
#
CellTreeBook method buildPrimary {} {
	$self destroyPrimary

	set prim [$self as BW_NoteBook buildPrimary]

	foreach r [$self slot relationships] {
		set f [$self insert end $r -text $r]

		set sw [BW_ScrolledWindow construct * $f \
			-relief sunken -borderwidth 2 \
			-layout {-side top -expand yes -fill both}]

		$self slotAppend _trees [set tree [BW_Tree construct * $sw \
			-relief flat -borderwidth 0 -width 15 -highlightthickness 0\
			-redraw 0 -dropenabled 1 -dragenabled 1 -padx 22 \
			-dragevent 1 -deltay 18 \
			-droptypes { CELL {copy {}} TEXT {copy {}} } \
			-layout {-side top -expand yes -fill both}]]

		$tree slot opencmd   "$self showKids $tree 1" 
		$tree slot closecmd  "$self showKids $tree 0"
		$tree slot draginitcmd "$self draginit $tree"
		$tree slot dropcmd "$self drop $tree"
		#$tree slot dropovercmd "$self dropover $tree"
		$tree slot _relationship $r

		$sw setwidget [$tree slot _primary]
	}

	foreach t [$self slot _trees] {
		$t slot redraw 1
	}
	$prim compute_size
	$self raise [$self page 0]

	$self slotOn rootPath >

	return $prim
}

# Called when drag is initiated from a tree
#
CellTreeBook method draginit {tree treePath node topLvl} {
	set o [$tree itemcget $node -data]

	label ${topLvl}.l -image [CoreType getImage [list Object $o]] -relief flat \
		-borderwidth 0 -background white
	pack ${topLvl}.l

	return [list SIGN {copy} [list Object $o]]
}

# Called when a drop is hovering over a tree
#
CellTreeBook method dropover {tree dropPath dragPath where op type data} {
	if {[lindex $where 0] == "node" && [lindex $where 1] == "_otree_root_"} {
		return 1
	} else {return 0}
}

# Called when something is dropped on a tree.
#
CellTreeBook method drop {tree dropPath dragPath where op type data} {
	if {[lindex $where 0] != "node" || [lindex $where 1] != "_otree_root_"} {return 1}

	set o ""
	switch $type {
		SIGN {
			set sText [lindex $data 1]

			switch [lindex $data 0] {
				<null> {set o $sText}
				<string> {set o $sText}
				default {set o [lindex $sText 0]}
			}
		}
		TEXT {
			set o $data
		}
	}

	$self slot rootObj $o
	return 1
}

# Create the children of a node in a tree.  The relationship
# selects how we generate the next level of the hierarchy.
#
# Note that for contents and shell we use slot to access the value,
# so we get {} if an Object doesn't have these slots.
#
CellTreeBook method getKids {tree node} {
return  ;# DEFERRED
	set mom [$tree itemcget $node -data]
	set slotCheck 0
	set ro [$self slot rootObj]

	switch [$tree slot _relationship] {
		descendants {set l [lsort [$mom children]]}
		ancestors	{set l [$mom parents]}
		contents	{set l [$mom slot contents]}
		shells		{set l [$mom slot shell]}
		linksIn		{set l [$self getLinks in $mom] ; set slotCheck 1}
		linksOut	{set l [$self getLinks out $mom] ; set slotCheck 1}
	}

	foreach o $l {
		if {[llength $o] > 1} {
			set im [::Poet::getImage node-link]
		} else {
			if {$slotCheck} {
				if {$o == $ro} {
					set im [CoreType getImage [list Object $o]]
				} else {
					set im [CoreType getImage <slot>]
				}
			} else {
				set im [CoreType getImage [list Object $o]]
			}
		}

		$tree insert end $node [Object anon n] \
			-text		$o	\
			-image		$im \
			-drawcross	allways \
			-data		$o	
	}

	$tree itemconfigure $node -drawcross auto
}

# Get the links for a node in the tree.  If the node is an atom,
# it's either the root, in which case we want to list the slots 
# that have links, or it's a slot on the root object, and we want
# the links.  If it's a two-item list, it's an {object slot} link
# and we return any links it has.
#
CellTreeBook method getLinks {type node} {
	set ll [llength $node]
	set o [$self slot rootObj]

	if {$ll == 1} {
		if {$node == $o} {
			set res {}

			foreach s [$node slots] {
				set ni [$node slotNodeInfo $s]
				if {[llength $ni] != 0} {
					switch $type {
						in	{set nl [lindex $ni 5]}
						out	{set nl [lindex $ni 6]}
					}

					if {$nl > 0} {lappend res $s}
				}
			}

			return $res
		} else {
			switch $type {
				in 	{return [$o slotLinksIn $node]}
				out {return [$o slotLinksOut $node]}
			}
		}
	} else {
		switch $type {
			in 	{return [[lindex $node 0] slotLinksIn [lindex $node 1]]}
			out {return [[lindex $node 0] slotLinksOut [lindex $node 1]]}
		}
	}
}

# Show the children of a node, or unshow them.  on will
# be 1 when we want to start showing, 0 otherwise.
#
CellTreeBook method showKids {tree on node} {
	if {$on && [$tree itemcget $node -drawcross] == "allways"} {
		$self getKids $tree $node
	}
}

# Navigation bar has changed
#
CellTreeBook method navBarEvent {target event args} {
	if {$target eq ""} return

	switch $event {
		nav {
			$self slot rootPath [$target viewPath]
		}
	}
}
