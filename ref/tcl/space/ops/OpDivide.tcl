### The ``divide`` operation
#
# PJM 2007-07-23	Created
# PJM 2008-12-14	Now derived from OpBinOp

OpBinOp construct OpDivide

OpDivide slot opcode "/"
OpDivide slot caption "divide"
OpDivide slot iconlg [Thyrd getImage "op-divide-lg"]
OpDivide slot iconsm [Thyrd getImage "op-divide-sm"]
OpDivide slot icongl [Thyrd getImage "op-divide-gl"]
OpDivide slot in {a b}
OpDivide slot out {a/b}
OpDivide slot tags {arithmetic strings}
OpDivide slot help "Pop two numbers and push their ratio, or subtract all instances of b from a" 
OpDivide slot sidefx "none"

# Given two values, return the answer and a type
#
OpDivide method subOp {a b} {
	if {[string is integer $a] && [string is integer $b]} {
		return [list [expr $a / $b] <integer>]
	} elseif {[string is double $a] && [string is double $b]} {
		return [list [expr $a / $b] <real>]
	} else {
		return [list [regsub -all $b $a ""] <string>]
	}
}
