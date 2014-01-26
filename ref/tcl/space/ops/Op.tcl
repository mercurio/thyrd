### An operation in Thyrdspace.  This is also the
### boss of all operations.
###
#
# PJM 2007-07-23	Created

Object construct Op

# Attributes of an operation
#
Op slot opcode {}
Op type opcode <string>

Op slot caption "unknown"
Op type caption <string>

Op slot iconlg [Thyrd getImage "op-unknown-lg"]
Op type iconlg <image>

Op slot iconsm [Thyrd getImage "op-unknown-sm"]
Op type iconsm <image>

Op slot icongl [Thyrd getImage "op-unknown-gl"]
Op type icongl <image>

Op slot in {}
Op type in <string>

Op slot out {}
Op type out <string>

Op slot tags {}
Op type tags <string>

Op slot help "No help has been written for this operation yet."
Op type help <string>

Op slot sidefx "No side effects help has been written for this operation yet."
Op type sidefx <string>

# This is for continuable ops (most of the combinators). An op
# is virgin the first time it's entered, after that it's a continuation.
# All ops created with ``new`` are virgins, even if their parent isn't.
Op slot virgin 1
Op type virgin <boolean>

# The children of this object that are abstract, and not meant to
# be included in the index.
#
Op slot _abstract [list OpBinOp]

# Make a new transient Op, and make it a virgin
#
Op method new {} {
	set o [$self construct *]

	$o slot virgin 1

	return $o
}

# Construct an index of all operations by opcode,
# destroying the old index if necessary.
# 
# We use ``ThingPool load`` to load any Ops that might
# be available be autoloading, even though it was intended
# for use with persistent objects.
# 
# We also filter out 
#
Op method makeIndex {} {
	$self arrayClear index

	ThingPool load Op?*

	foreach o [Op realOps] {
		$self arraySet index [$o slot opcode] $o
	}
}

# Lookup an opcode in the index, return "" if not found
#
Op method lookup {opcode} {
	$self arrayGet index $opcode
}

# Return a list of all the real (non-abstract) ops
#
Op method realOps {} {
	poetvar $self _abstract
	set out [list]

	foreach o [Op descendants] {
		if {$o ni $_abstract} {
			lappend out $o
		}
	}

	return $out
}

# Return a glyph for this op
#
Op method getGlyph {} {
	return [$self slot icongl]
}

