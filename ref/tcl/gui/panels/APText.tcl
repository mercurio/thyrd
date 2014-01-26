### A simple panel for viewing an atomic cell via
### a multiline text widget entry.
###
### We don't use the _value slot provided by AtomicPanel.
###
# PJM	2007-04-23	Begun
# PJM	2008-05-13	Added hiliting

AtomicPanel construct APText

APText slot borderwidth 0

APText slot hilite	0
APText type hilite	<boolean>

# Given the parent widget and the cell, construct
# and return the panel
#
# See: ``Panel build``
#
APText method build {mom tool c {opts {}} {w {}} {h {}}} {
	set kid [$self buildFrame $mom $c $w $h]
	$kid slot tool $tool

	set f [$kid slot _frame]

	$kid slotOff value >

	foreach {o v} $opts {
		switch $o {
			-hilite {$self slot hilite $v}
		}
	}

	set t ${f}.t

	text $t 
	place $t -relwidth 1 -relx 0 -relheight 1 -rely 0

	$kid slot _text $t
	$t insert end [$c get]
	$t see 1.0

	if {[$self slot hilite]} {
		CodeEditorText defineTags $t
		CodeEditorText highlightSyntax $t
	}

	bind $t <Any-Key> "$kid modifiedEvent"
	bind $t <Control-X> "$self cut"
	bind $t <Control-C> "$self copy"
	bind $t <Control-V> "$self paste"

	$c addObserver write $kid cellWrite

	return $f
}

# The modified flag has changed, either draw or erase the
# validator
#
APText method modifiedEvent {args} {
	set txt [$self slot _text]

	if {[$self slot hilite]} {
		regexp {([0-9]*)\..*} [$txt index insert] match line
		CodeEditorText highlightSyntax $txt $line $line
	}

	if {[$txt edit modified]} {
		$self drawValidator
	} else {
		$self eraseValidator
	}
}

# The OK button has been hit.  If we successfully
# update the cell, get rid of the buttons.
#
APText method okButton {} {
	poetvar $self _text

	if {[$self validateCell [$_text get 1.0 end]]} {
		$self eraseValidator
		return
	}

	UserMsg warning "This cell will not accept a value of $v"
}

# The Cancel button has been hit, restore the old value.
#
APText method cancelButton {} {
	poetvar $self _text
		
	$_text delete 1.0 end
	$_text insert end [[$self viewCell] get]
	$self eraseValidator
}

# The cell has been written elsewhere
#
APText method cellWrite {target event args} {
	$self cancelButton
}
