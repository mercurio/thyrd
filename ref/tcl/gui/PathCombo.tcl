# PathCombo - BW_ComboBox displaying a path
#
# PJM 2005-09-08	Begun, based on Poet's ObjectNameCombo
#

BW_ComboBox construct PathCombo
PathCombo mixin PathWidget

# name of object
PathCombo slot> pathName 	""	{$self PathWidget_setEditPath $value}

PathCombo slot notify		""		;# script to call when changed

# Build the primary for an PathCombo
#
PathCombo method buildPrimary {} {
	$self destroyPrimary

	set prim [$self as BW_ComboBox buildPrimary]

	$self slot pathName [$self slot pathName]
	$self slot command "$self PathWidget_cmd"
	$self slot modifycmd "$self PathWidget_cmd"

	$self PathWidget_config

	return $prim
}
