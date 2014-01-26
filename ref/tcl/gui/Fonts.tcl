# Fonts
#
# Manage the fonts in use by this application.
# Note: Mac fonts untested.
#
# PJM 2005-09-30	Derived from Poet's ColorScheme and code from dna2abc

Object construct Fonts

# Select a font scheme.  Note that the default scheme
# is set by calling this method below.
#
Fonts method select {scheme} {
	case $scheme {
		default {
			switch $::tcl_platform(platform) {
				windows {
					$self slot prop	"Tahoma"
					$self slot nonprop	"Lucida Console"
					$self slot zfont	"Helvetica"

					$self slot sm	11
					$self slot md	13
					$self slot lg	16
					$self slot xl	20
				}
				unix {
					$self slot prop	lucida
					$self slot nonprop	lucidatypewriter

					$self slot sm	10
					$self slot md	12
					$self slot lg	16
					$self slot xl	20
				}
				macintosh {
					$self slot prop	system
					$self slot nonprop	courier

					$self slot sm	10
					$self slot md	12
					$self slot lg	16
					$self slot xl	20
				}
			}
		}
	}

	$self create
}

#DEFERRED rename zfont

# Create the fonts, deleting them just in case this
# has been called before.
#
Fonts method create {} {
	foreach f {frame-int frame-str cell} {
		catch {font delete $i}
	}

#DEFERRED
	#font create frame-int 		-family [$self slot prop] -size [$self slot sm] -slant italic 
	#font create frame-int 		-family [$self slot nonprop] -size [$self slot sm] -weight bold
	font create frame-int 		-family [$self slot nonprop] -size [$self slot sm] -weight bold
	font create frame-str 		-family [$self slot prop] -size [$self slot sm] -weight bold 
	font create cell 		-family [$self slot prop] -size [$self slot sm]
	font create grid 		-family [$self slot prop] -size [$self slot sm] -underline 1
	font create zfont		-family [$self slot zfont] -size [$self slot lg] -weight normal
	font create smbtn		-family [$self slot prop] -size [$self slot sm] -weight bold
	font create triad-count 		-family [$self slot prop] -size [$self slot sm] -weight normal 
	font create triad-count-big 		-family [$self slot prop] -size [$self slot md] -weight normal 
	font create wave 		-family [$self slot prop] -size [$self slot md] -weight normal 
	font create wave-path 	-family [$self slot nonprop] -size [$self slot sm] -weight normal 
	font create wave-label 	-family [$self slot prop] -size [$self slot sm] -weight bold 
	font create flatland 	-family [$self slot prop] -size [$self slot md] -weight normal 
}

Fonts select default
