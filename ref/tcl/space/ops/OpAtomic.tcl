### The ``is atomic`` operation
#
# PJM 2008-10-15	Created

Op construct OpAtomic

OpAtomic slot opcode "atomic?"
OpAtomic slot caption "cell is atomic?"
OpAtomic slot iconlg [Thyrd getImage "op-atomic-lg"]
OpAtomic slot iconsm [Thyrd getImage "op-atomic-sm"]
OpAtomic slot icongl [Thyrd getImage "op-atomic-gl"]
OpAtomic slot in {c}
OpAtomic slot out {c bool}
OpAtomic slot tags {thyrdspace}
OpAtomic slot help "Peeks at the top cell and pushs true if the cell is atomic (not a grid)"
OpAtomic slot sidefx "none"

# Perform the operation on the given wave
#
OpAtomic method doOp {wave} {
	set c [$wave peek]
	$wave saveX

	$wave pushTyped [list [$c atomic] <boolean>]

	return ""
}

# Undo by removing the answer 
#
OpAtomic method undoOp {wave} {
	$wave pop

	return ""
}
