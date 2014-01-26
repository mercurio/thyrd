### The ``gt`` operation
#
# PJM 2008-02-12	Created
# PJM 2008-12-14	Now derived from OpBinOp

OpBinOp construct OpGT

OpGT slot opcode ">"
OpGT slot caption "greater than"
OpGT slot iconlg [Thyrd getImage "op-gt-lg"]
OpGT slot iconsm [Thyrd getImage "op-gt-sm"]
OpGT slot icongl [Thyrd getImage "op-gt-gl"]
OpGT slot in {a b}
OpGT slot out {a>b}
OpGT slot tags {logic}
OpGT slot help "Pop two values, compare them, and push true if a is greater than b"
OpGT slot sidefx "none"

# Given two values, return the answer and a type
#
OpGT method subOp {a b} {
	if {[string is double $a] && [string is double $b]} {
		return [list [expr {$a > $b}] <boolean>]
	} else {
		return [list [expr {[string compare $a $b] == 1}] <boolean>]
	}
}
