### The ``and`` operation
#
# PJM 2008-02-12	Created
# PJM 2008-12-14	Now derived from OpBinOp

OpBinOp construct OpAnd

OpAnd slot opcode "&"
OpAnd slot caption "and"
OpAnd slot iconlg [Thyrd getImage "op-and-lg"]
OpAnd slot iconsm [Thyrd getImage "op-and-sm"]
OpAnd slot icongl [Thyrd getImage "op-and-gl"]
OpAnd slot in {a b}
OpAnd slot out {a&b}
OpAnd slot tags {logic}
OpAnd slot help "Pop two booleans and push true if they're both true, false otherwise"
OpAnd slot sidefx "none"

# Given two values, return the answer and a type
#
OpAnd method subOp {a b} {
	if {[string is true $a] && [string is true $b]} {
		return [list 1 <boolean>]
	} else {
		return [list 0 <boolean>]
	}
}
