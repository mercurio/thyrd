### The ``equal`` operation
#
# PJM 2008-02-12	Created
# PJM 2008-12-14	Now derived from OpBinOp

OpBinOp construct OpEqual

OpEqual slot opcode "="
OpEqual slot caption "equal"
OpEqual slot iconlg [Thyrd getImage "op-equal-lg"]
OpEqual slot iconsm [Thyrd getImage "op-equal-sm"]
OpEqual slot icongl [Thyrd getImage "op-equal-gl"]
OpEqual slot in {a b}
OpEqual slot out {a=b}
OpEqual slot tags {logic}
OpEqual slot help "Pop two values and return true if they are the same"
OpEqual slot sidefx "none"

# Given two values, return the answer and a type
#
OpEqual method subOp {a b} {
	if {[string is integer $a] && [string is integer $b]} {
		return [list [expr {$a == $b}] <boolean>]
	} elseif {[string is double $a] && [string is double $b]} {
		return [list [::math::fuzzy teq $a $b] <boolean>]
	} else {
		return [list [expr {$a eq $b}] <boolean>]
	}
}
