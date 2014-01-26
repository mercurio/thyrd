### The ``modulo`` operation
#
# PJM 2008-02-12	Created
# PJM 2008-12-14	Now derived from OpBinOp

OpBinOp construct OpModulo

OpModulo slot opcode "%"
OpModulo slot caption "modulo"
OpModulo slot iconlg [Thyrd getImage "op-modulo-lg"]
OpModulo slot iconsm [Thyrd getImage "op-modulo-sm"]
OpModulo slot icongl [Thyrd getImage "op-modulo-gl"]
OpModulo slot in {a b}
OpModulo slot out {a%b}
OpModulo slot tags {arithmetic strings}
OpModulo slot help "Pop two numbers and push the remainder when a is divided by b. If the values are strings,
return the tail of a following the rightmost appearance of b."
OpModulo slot sidefx "none"

# Given two values, return the answer and a type
#
OpModulo method subOp {a b} {
	if {[string is integer $a] && [string is integer $b]} {
		return [list [expr $a % $b] <integer>]
	} elseif {[string is double $a] && [string is double $b]} {
		return [list [expr {$a % $b}] <real>]
	} else {
		set i [string last $b $a]
		if {$i == -1} {
			return [list "" <string>]
		} else {
			incr i [string length $b]
			return [list [string range $a $i end <string>]]
		}
	}
}
