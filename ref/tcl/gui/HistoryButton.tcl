# HistoryButton - ButtonCombo displaying a history of values
# entered.  We can treat the history as a stack.
#
# PJM 2005-10-06	Based on Poet's tier3-SignHistory
# PJM 2006-03-01	Added stack behavior
#

ButtonCombo construct HistoryButton

# Max entries in history
#
HistoryButton slot max 10

# Add an item to the history, enabling the button
#
HistoryButton method pushHistory {t} {
	$self slotPush values $t

	set n [$self slot max]
	if {$n ne ""} {
		set l [$self slotLength values] 
		if {$l > $n} {
			$self slot values [$self slotRange values [expr $l - $n] end]
		}
	}

	$self slot state normal
}

# Pop an item off the history
#
HistoryButton method popHistory {} {
 	set x [$self slotPop values]

	if {[$self slotLength values] == 0} {
		$self slot state disabled
	}

	return $x
}

# Set the history, erasing the previous state
#
HistoryButton method setHistory {h} {
	$self slot values $h

	$self slot state [expr {([llength $h] == 0) ? "disabled" : "normal"}]
}

# Link to a read-only cell.  We sync to the value of the
# cell once, and augment our ``value>`` method to keep the
# cell up to date.  We do not care about syncing to future
# changes to the cell.
#
HistoryButton method linkToCell {c} {
	$self setHistory [$c get]

	$self method value> {value} [format {
		$self as HistoryButton value> $value
		%1$s set $value
	} $c]
}

# Clear the history
#
HistoryButton method clearHistory {} {
	$self slot values {}
	$self slot state disabled
}
