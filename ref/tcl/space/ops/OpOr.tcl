### The ``or`` operation
#
# PJM 2008-02-12	Created
# PJM 2008-12-14	Now derived from OpBinOp

OpBinOp construct OpOr

OpOr slot opcode "|"
OpOr slot caption "or"
OpOr slot iconlg [Thyrd getImage "op-or-lg"]
OpOr slot iconsm [Thyrd getImage "op-or-sm"]
OpOr slot icongl [Thyrd getImage "op-or-gl"]
OpOr slot in {a b}
OpOr slot out {a|b}
OpOr slot tags {logic}
OpOr slot help "Pop two truth values, compare them, and push true if a or b is true."
OpOr slot sidefx "none"

# Given two values, return the answer and a type
#
OpOr method subOp {a b} {
	if {[string is true $a] || [string is true $b]} {
		return [list 1 <boolean>]
	} else {
		return [list 0 <boolean>]
	}
}
