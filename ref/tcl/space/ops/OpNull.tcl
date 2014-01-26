### The ``is null`` operation
#
# PJM 2008-10-15	Created

Op construct OpNull

OpNull slot opcode "null?"
OpNull slot caption "null?"
OpNull slot iconlg [Thyrd getImage "op-null-lg"]
OpNull slot iconsm [Thyrd getImage "op-null-sm"]
OpNull slot icongl [Thyrd getImage "op-null-gl"]
OpNull slot in {a}
OpNull slot out {a bool}
OpNull slot tags {logic}
OpNull slot help "Peeks at the top value and pushs true if the value is the empty string or 0"
OpNull slot sidefx "none"

# Perform the operation on the given wave
#
OpNull method doOp {wave} {
	set c [$wave peek]
	$wave saveX

	set ans 0
	if {[Object existsAs $c Cell]} {
		set v [$c get]
		if {$v eq "" || $v == 0} {
			set ans 1
		}
	} else {
		set ans 1
	}

	$wave pushTyped [list $ans <boolean>]

	return ""
}

# Undo by removing the answer 
#
OpNull method undoOp {wave} {
	$wave pop

	return ""
}
