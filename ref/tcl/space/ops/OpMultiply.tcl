### The ``multiply`` operation
#
# PJM 2007-07-23	Created
# PJM 2008-12-14	Now derived from OpBinOp

OpBinOp construct OpMultiply

OpMultiply slot opcode "*"
OpMultiply slot caption "multiply"
OpMultiply slot iconlg [Thyrd getImage "op-multiply-lg"]
OpMultiply slot iconsm [Thyrd getImage "op-multiply-sm"]
OpMultiply slot icongl [Thyrd getImage "op-multiply-gl"]
OpMultiply slot in {a b}
OpMultiply slot out {a*b}
OpMultiply slot tags {arithmetic}
OpMultiply slot help "Pop two numbers and push their product"
OpMultiply slot sidefx "Halts wave if not two numbers"

# Given two values, return the answer and a type
#
OpMultiply method subOp {a b} {
	if {[string is integer $a] && [string is integer $b]} {
		return [list [expr $a * $b] <integer>]
	} elseif {[string is double $a] && [string is double $b]} {
		return [list [expr $a * $b] <real>]
	} else {
		return -code error "Can't multiply $a and $b"
	}
}
