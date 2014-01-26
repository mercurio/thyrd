### The ``add`` operation
#
# PJM 2007-07-23	Created
# PJM 2008-12-14	Now derived from OpBinOp

OpBinOp construct OpAdd

OpAdd slot opcode "+"
OpAdd slot caption "add"
OpAdd slot iconlg [Thyrd getImage "op-add-lg"]
OpAdd slot iconsm [Thyrd getImage "op-add-sm"]
OpAdd slot icongl [Thyrd getImage "op-add-gl"]
OpAdd slot in {a b}
OpAdd slot out {a+b}
OpAdd slot tags {arithmetic strings}
OpAdd slot help "Pop two numbers and push their sum, or concatenate two strings" 
OpAdd slot sidefx "none"

# Given two values, return the answer and a type
#
OpAdd method subOp {a b} {
	if {[string is integer $a] && [string is integer $b]} {
		return [list [expr $a + $b] <integer>]
	} elseif {[string is double $a] && [string is double $b]} {
		return [list [expr $a + $b] <real>]
	} else {
		return [list "$a$b" <string>]
	}
}
