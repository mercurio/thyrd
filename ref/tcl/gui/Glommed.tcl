### Glommed -- an object attached to a widget
### that gets destroyed when the widget is 
### destroyed.
###
# PJM 2007-04-09	Begun (DEFERRED should be part of Poet?)

Mixin construct Glommed

# Glom a Poet object onto an arbitrary Tk widget,
# so that when the widget is destroyed so is the Poet
# object.
#
Glommed method glomOnto {w} {
	$self slot _glommedOnto $w
	bind $w <Destroy> [list $self Glommed_unglomFrom %W]

	return $self
}

# Unglom from a widget by self-destructing if the
# given window name matches our ``_glommedOnto``
#
Glommed method Glommed_unglomFrom {w} {
	if {$w eq [$self slot _glommedOnto]} {$self destruct}
}

