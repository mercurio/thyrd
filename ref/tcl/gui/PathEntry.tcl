# PathEntry - BW_Entry displaying a path
#
# PJM	2005-09-08	Begun, based on Poet's ObjectNameEntry
#

BW_Entry construct PathEntry
PathEntry mixin PathWidget

# name of object
PathEntry slot> pathName 	"" {$self PathWidget_setEditPath $value}

PathEntry slot notify		""		;# script to call when changed
PathEntry slot type		Object	;# required type of $objName

# Build the primary for a PathEntry
#
PathEntry method buildPrimary {} {
	$self destroyPrimary

	set prim [$self as BW_Entry buildPrimary]

	$self slot pathName [$self slot pathName]
	$self slot command "$self PathWidget_cmd"

	$self PathWidget_config

	return $prim
}

# Set the value and exec notify 
#
PathEntry method set {p} {
	$self PathWidget_setEditPath $p
}
