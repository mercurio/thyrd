### The ``gte`` operation
#
# PJM 2008-02-12	Created
# PJM 2008-12-14	Now derived from OpBinOp

OpBinOp construct OpGTE

OpGTE slot opcode ">="
OpGTE slot caption "greater or equal"
OpGTE slot iconlg [Thyrd getImage "op-gte-lg"]
OpGTE slot iconsm [Thyrd getImage "op-gte-sm"]
OpGTE slot icongl [Thyrd getImage "op-gte-gl"]
OpGTE slot in {a b}
OpGTE slot out {a>=b}
OpGTE slot tags {logic}
OpGTE slot help "Pop two values, compare them, and push true if a is greater than or equal to b"
OpGTE slot sidefx "none"

# Given two values, return the answer and a type
#
OpGTE method subOp {a b} {
	if {[string is double $a] && [string is double $b]} {
		return [list [expr {$a >= $b}] <boolean>]
	} else {
		return [list [expr {[string compare $a $b] != -1}] <boolean>]
	}
}
