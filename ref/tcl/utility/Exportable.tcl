### A mixin providing import/export support. Export is
### done by writing a serialized version of each object
### to a file, import is done by sourcing the file.
### Unlike with Thing and ThingPool, no autoloading is
### available, we assume that all of this object's components
### are also in the same file and will be explicitly loaded.
###
### If an object mixes in Exportable and also has custom
### Thing_put or Thing_postload methods, it should override
### export and import as well.
###
#
# PJM 2008-10-31	Created

Mixin construct Exportable

# Export this object as a string that can be written
# to a file with other exported objects.
# Similar to the Thing support, except that we
# assume no autoloading.
#
# If ``import`` is implemented for this object,
# we have to output the command to invoke it.
# In this case, the default body of this method
# would be
#``
#	return "[$self serialize]\n$self import"
#``
#
Exportable method export {} {
	return [$self serialize]
}

# Called after we've been loaded from an export
# file. Again, no autoloading is available in this
# case, we assume all our components are also in
# the same file.
#
# If there are any commands that need to be run after
# all objects have been loaded, call ``Exportable doLater``
# on them.
#
Exportable method import {} {
}

# Add a command to the postload queue on this
# object (which should be Exportable itself).
#
Exportable method doLater {com} {
	$self slotAppend _postload $com
}

# Source an import file, then invoke the commands 
# in _postload and clear it out. Return true if
# we succeeded.
#
Exportable method importFile {fn} {
	Thyrd busy
	if {[catch {source $fn}]} {
		Thyrd unbusy
		UserMsg warning "|$self importFile $fn|Reading import file failed"
		return false
	}

	Thyrd busy
	foreach com [$self slot _postload] {
		eval $com
	}

	$self unslot _postload
	Thyrd unbusy

	return true
}
