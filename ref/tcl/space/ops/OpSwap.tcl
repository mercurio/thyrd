### The ``swap`` operation
#
# PJM 2008-02-12	Created

Op construct OpSwap

OpSwap slot opcode "swap"
OpSwap slot caption "swap"
OpSwap slot iconlg [Thyrd getImage "op-swap-lg"]
OpSwap slot iconsm [Thyrd getImage "op-swap-sm"]
OpSwap slot icongl [Thyrd getImage "op-swap-gl"]
OpSwap slot in {a b}
OpSwap slot out {b a}
OpSwap slot tags {wave}
OpSwap slot help "Swap the order of the top two items on the stack"
OpSwap slot sidefx "none"

# Perform the operation on the given wave
#
OpSwap method doOp {wave} {
	$wave saveX

	set b [$wave popCell]
	set a [$wave popCell]

	$wave pushCell $b
	$wave pushCell $a

	return ""
}

# Undo by removing the answer and
# restoring the operands
#
OpSwap method undoOp {wave} {
	set b [$wave popCell]
	set a [$wave popCell]

	$wave pushCell $b
	$wave pushCell $a

	return ""
}
