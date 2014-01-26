### The ``recurselinear`` operation
###
### Pops four programs off the stack: ``if`` ``then`` ``else1`` ``else2``.
### If ``if`` evaluates true, eval ``then``, else eval ``else1``,
### recurse, and eval ``else2``.
###
#
# PJM 2008-06-30	Begun

OpRecurse construct OpRecurseLinear

OpRecurseLinear slot opcode "linrec"
OpRecurseLinear slot caption "recurselinear"
OpRecurseLinear slot iconlg [Thyrd getImage "op-recurselinear-lg"]
OpRecurseLinear slot iconsm [Thyrd getImage "op-recurselinear-sm"]
OpRecurseLinear slot icongl [Thyrd getImage "op-recurselinear-gl"]
OpRecurseLinear slot in {if then else1 else2}
OpRecurseLinear slot out {linear recursion}
OpRecurseLinear slot tags {combinator}
OpRecurseLinear slot help "Pop four programs: if then else1 else2. If if evaluates true, eval then, else eval else1, recurse, and eval else2."
OpRecurseLinear slot sidefx "Depends on program provided as input"

OpRecurseLinear slot primitive 0
