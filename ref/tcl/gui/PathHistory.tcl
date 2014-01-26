# PathHistory - PathCombo displaying a history of values
# entered.
#
# PJM 2005-09-08	Begun
#

PathCombo construct PathHistory

# path string
#
PathHistory slot> pathName 	""	{
	$self PathWidget_setEditPath $value
	$self slotUnique values $value
}

