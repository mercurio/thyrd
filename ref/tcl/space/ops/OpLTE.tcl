### The ``less than or equal`` operation
#
# PJM 2008-02-12	Created
# PJM 2008-12-14	Now derived from OpBinOp

OpBinOp construct OpLTE

OpLTE slot opcode "<="
OpLTE slot caption "less or eqaul"
OpLTE slot iconlg [Thyrd getImage "op-lte-lg"]
OpLTE slot iconsm [Thyrd getImage "op-lte-sm"]
OpLTE slot icongl [Thyrd getImage "op-lte-gl"]
OpLTE slot in {a b}
OpLTE slot out {a<=b}
OpLTE slot tags {logic}
OpLTE slot help "Pop two values, compare them, and push true if a is less than or equal to b"
OpLTE slot sidefx "none"

# Given two values, return the answer and a type
#
OpLTE method subOp {a b} {
	if {[string is double $a] && [string is double $b]} {
		return [list [expr {$a <= $b}] <boolean>]
	} else {
		return [list [expr {[string compare $a $b] != 1}] <boolean>]
	}
}
