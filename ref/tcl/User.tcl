# The current User.  At any given time the User has a UserRole
# that defines its behavior, the default UserRole is sufficient
# to demo Thyrd.
#
# PJM 19990523	Total rewrite

Object construct User

# Attempt to enter ThyrdSpace as a User by initializing the
# ThingPool.  Return 1 if successful.
#
# Once the pool is open, we see if the splash screen is up
# (it should be) and use the progress bar to report on loading
# of anonymous Things.
#
User method enter {} {
	if {![ThingPool open]} {
		UserMsg error "|$self enter| Unable to open ThingPool"
	}

	$self slot _role UserRole

	if {[winfo exists $::Thyrd::progressBar]} {
		set ac [ThingPool anonCount]
		if {$ac <= 0} {
			$::Thyrd::progressBar configure -maximum 1
			set ::Thyrd::progressVar 1
		} else {
			$::Thyrd::progressBar configure -maximum $ac
			Thing_AnonCounter method loaded> {value} {set ::Thyrd::progressVar $value}
			Thing_AnonCounter slotOn loaded >
		}
	}

	return 1
}

# Close the ThingPool prior 
# to exiting.
# 
User method exit {} {
	if {[winfo exists $::Thyrd::progressBar]} {
		set ac [ThingPool anonCount]
		if {$ac <= 0} {
			$::Thyrd::progressBar configure -maximum 1
			set ::Thyrd::progressVar 1
		} else {
			$::Thyrd::progressBar configure -maximum $ac
			Thing_AnonCounter method saved> {value} {set ::Thyrd::progressVar $value}
			Thing_AnonCounter slotOn saved >
			Thing_AnonCounter slot saved 0
		}
	}

	ThingPool close

	Thing_AnonCounter slotOff saved >
}
