### The ``lt`` operation
#
# PJM 2008-02-12	Created
# PJM 2008-12-14	Now derived from OpBinOp

OpBinOp construct OpLT

OpLT slot opcode "<"
OpLT slot caption "less than"
OpLT slot iconlg [Thyrd getImage "op-lt-lg"]
OpLT slot iconsm [Thyrd getImage "op-lt-sm"]
OpLT slot icongl [Thyrd getImage "op-lt-gl"]
OpLT slot in {a b}
OpLT slot out {a<b}
OpLT slot tags {logic}
OpLT slot help "Pop two values, compare them, and push true if a is less than b"
OpLT slot sidefx "none"

# Given two values, return the answer and a type
#
OpLT method subOp {a b} {
	if {[string is double $a] && [string is double $b]} {
		return [list [expr {$a < $b}] <boolean>]
	} else {
		return [list [expr {[string compare $a $b] == -1}] <boolean>]
	}
}
