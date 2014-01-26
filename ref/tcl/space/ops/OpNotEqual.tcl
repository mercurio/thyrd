### The ``notequal`` operation
#
# PJM 2008-02-12	Created
# PJM 2008-12-14	Now derived from OpBinOp

OpBinOp construct OpNotEqual

OpNotEqual slot opcode "!="
OpNotEqual slot caption "not equal"
OpNotEqual slot iconlg [Thyrd getImage "op-notequal-lg"]
OpNotEqual slot iconsm [Thyrd getImage "op-notequal-sm"]
OpNotEqual slot icongl [Thyrd getImage "op-notequal-gl"]
OpNotEqual slot in {a b}
OpNotEqual slot out {a!=b}
OpNotEqual slot tags {logic}
OpNotEqual slot help "Pop two values, compare them, and push true they are not the same."
OpNotEqual slot sidefx "none"

# Given two values, return the answer and a type
#
OpNotEqual method subOp {a b} {
	if {[string is integer $a] && [string is integer $b]} {
		return [list [expr {$a != $b}] <boolean>]
	} elseif {[string is double $a] && [string is double $b]} {
		return [list [::math::fuzzy tne $a $b] <boolean>]
	} else {
		return [list [expr {$a ne $b}] <boolean>]
	}
}
