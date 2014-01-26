### Get the type of a cell
###
### In: cell 
### Out: cell type
###
#
# PJM 2008-10-15	Created

Op construct OpGetType

OpGetType slot opcode "gettype"
OpGetType slot caption "get type"
OpGetType slot iconlg [Thyrd getImage "op-gettype-lg"]
OpGetType slot iconsm [Thyrd getImage "op-gettype-sm"]
OpGetType slot icongl [Thyrd getImage "op-gettype-gl"]
OpGetType slot in {cell}
OpGetType slot out {cell type}
OpGetType slot tags {thyrdspace}
OpGetType slot help "Peek at the top cell and push it's type"
OpGetType slot sidefx ""

# Get the type of the top cell
#
OpGetType method doOp {wave} {
	set c [$wave peek]
	$wave saveX

	$wave pushTyped [list [$c getType] <string>]

	return ""
}

# Undo a get type operation.
#
OpGetType method undoOp {wave} {
	$wave pop

	return ""
}
