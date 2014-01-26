### The ``subtract`` operation
#
# PJM 2007-07-23	Created
# PJM 2008-12-14	Now derived from OpBinOp

OpBinOp construct OpSubtract

OpSubtract slot opcode "-"
OpSubtract slot caption "subtract"
OpSubtract slot iconlg [Thyrd getImage "op-subtract-lg"]
OpSubtract slot iconsm [Thyrd getImage "op-subtract-sm"]
OpSubtract slot icongl [Thyrd getImage "op-subtract-gl"]
OpSubtract slot in {a b}
OpSubtract slot out {a-b}
OpSubtract slot tags {arithmetic strings}
OpSubtract slot help "Pop two numbers and push their difference, or subtract one string from the other"
OpSubtract slot sidefx "none"

# Given two values, return the answer and a type
#
OpSubtract method subOp {a b} {
	if {[string is integer $a] && [string is integer $b]} {
		return [list [expr $a - $b] <integer>]
	} elseif {[string is double $a] && [string is double $b]} {
		return [list [expr $a - $b] <real>]
	} else {
		return [list [regsub $b $a ""] <string>]
	}
}
