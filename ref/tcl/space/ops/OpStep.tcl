### The ``step`` operation
###
### Pops two grids off the stack, the first is a program
### to be evaluated on each cell in the second grid.
### 
### Note that this is a descendant of OpFold
#
# PJM 2008-06-27	Created

OpFold construct OpStep

OpStep slot opcode "step"
OpStep slot caption "step"
OpStep slot iconlg [Thyrd getImage "op-step-lg"]
OpStep slot iconsm [Thyrd getImage "op-step-sm"]
OpStep slot icongl [Thyrd getImage "op-step-gl"]
OpStep slot in {a p}
OpStep slot out {p applied to each cell in a}
OpStep slot tags {combinator}
OpStep slot help "Pop a grid (a) and a program (p). Evaluate the program with the first cell of a (along with whatever else was on the stack), then with the result and the next cell from a, until the end of a. The final result is pushed on the stack."
OpStep slot sidefx "Depends on program provided as input"

# We want to get one new cell from the input
# grid each time, regardless of what's already on
# the stack, so we indicate that each invocation of
# $p leaves nothing on the stack (more precisely,
# it doesn't leave any cells we want used in the
# next invocation as inputs).
#
OpStep slot pIn 1
OpStep slot pOut 0
