### Support for options
###
#
# PJM	2008-12-26	Created
#

Object construct Options
Options mixin Observer

# Construct the options table, if it's not there.
#
Options method initialize {} {
	set oc [theSpace find "/thyrd/options"]

	if {$oc eq ""} {
		set oc [Cell goto "/thyrd/options" yes]

		$oc putTypeAt 0 <boolean> autofill 
		$oc putTypeAt "If true, when adding rows or columns in the cell editor empty cells will be created for all new grid locations" <string> autofill help
	}
}

# Get the value of an option
#
Options method get {opt} {
	set oc [theSpace find "/thyrd/options"]
	return [$oc getAt $opt]
}

# Set the value of an option
#
Options method set {opt value} {
	set oc [theSpace find "/thyrd/options"]
	$oc putAt $value $opt
}
