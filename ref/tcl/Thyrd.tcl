#### Thyrd #### Thyrd Visual Programming Environment 

### 
### To start the application, call "Thyrd initialize".
### To close down, call "Thyrd finalize"
###
### The Poet object Thyrd is the store for static knowledge about the system 
### and the gateway to the Sages, which hold persistent knowledge.  
###

#
# PJM 2005-07-01	Created 
# PJM 2005-11-21	Creation of Thyrd namespace, which must precede the
#					sourcing of this file, moved to ../util/Thyrd-namespace.tcl

Object construct Thyrd

Thyrd slot knownDemos {ProtoWidget Tk_Frame Tk_Canvas Ttk_Frame}

Thyrd slot resourceDir $::Thyrd::resourceDir

# The persistent data (have Thing mixed in)
#
Thyrd slot pool ThingPool

# Start up the system.
#
Thyrd method initialize {} {
	if {[info commands ::Thyrd::crash] != ""} return

	$self parseArgs
	set pf [$self slot poolfile]

	if {[file isfile $pf] && [$self isExportFile $pf]} {
		set ans [UserMsg yesno "|$self initialize|The file \"$pf\" appears to be a Thyrd export file, not a Thyrdspace file. Are you sure you want to overwrite it?"]
		if {$ans ne "yes"} {
			exit 0
		} else {
			file remove -force $pf
		}
	}

	Poet preload Thyrd

	ThingPool setFile [$self slot poolfile]
	ThingPool slot writable 1

	# List the tests available
	#
	foreach m [Space methods buildTest*] {
		Thyrd slotAppend knownTests "theSpace $m"
	}

	# not used   Thyrd slotAppend knownTests "theSpace redefaultOps"

	if {![User enter]} {
		UserMsg warning "|Thyrd initialize| Initialization error.
Try setting the THYRD_HOME environment variable"

		return
	}

	# Redefine exit to prevent exiting without saving Things
	#
	rename exit ::Thyrd::crash
	proc exit {{returnCode 0}} {Thyrd finalize $returnCode}

	# Configure Poet so we can use the constraints network properly
	# DEFERRED this may be causing more trouble than it's worth
	# but removing it doesn't work yet
	# NOTE: Removed after Wave rewrite (> v0.1.1). Shouldn't need to
	# be replaced, but kept here just in case.
	#Poet limitConstraints Constrainable

	# Move Poetics toolbox binding
	set oldBinding [bind all <Key-F7>]
	bind all <Key-F7> ""
	bind all <Shift-Key-F7> $oldBinding

	# Call the Fonts, Colors, etc. objects into existence, setting 
	# the attributes used throughout the application
	#
	Fonts
	Colors
	Cursors
	Spans

	# Define the virtual events that can be invoked on any object
	#
	event add <<THYRD_I>> <Button-3>
	event add <<THYRD_TO>> <KeyPress-F2>
	event add <<THYRD_WHO>> <KeyPress-F3>
	event add <<THYRD_WHAT>> <KeyPress-F4>
	event add <<THYRD_WHERE>> <KeyPress-F5>
	event add <<THYRD_ASSIST>> <KeyPress-F6>
	event add <<THYRD_TOOLBOX>> <KeyPress-F7>
	event add <<THYRD_COMMANDS>> <KeyPress-F8>

	# Establish universal bindings for virtual events
	#
	bind all <<THYRD_I>> {tk_popup [[ProtoWidget pathToWidget %W *] popupMenu %W %x %y] %X %Y}
	bind all <<THYRD_TOOLBOX>> "Thyrd showToolbox"
	bind all <<THYRD_COMMANDS>> "Thyrd showTclConsole"

	# Create or find the space
	Space exist

	# If ``openWindows`` is set, open all the
	# previously opened windows, or, if none exist, the
	# toolbox. 
	#
	Window initialize [$self slot openWindows]
}

# Parse the command line arguments
#
Thyrd method parseArgs {} {
	$self slot openWindows 1

	set pf ""

	$self slot args $::argv
	while {[set a [$self slotPop args]] ne ""} {
		switch -- $a {
			-nowindows {$self slot openWindows 0}
			default {set pf $a}
		}
	}
		
	if {$pf eq ""} {
		set reply [UserMsg yesnocancel "Thyrd requires a .3rd file to store Thyrdspace, 
would you like to create a new one? Select 
yes to create a new file, no to open an 
existing file, or cancel to exit."]
		switch $reply {
			yes {
				set pf [tk_getSaveFile -initialdir "." \
					-initialfile "space.3rd" -defaultextension "3rd" -title "Please select a file"]
			}
			no {
				set pf [tk_getOpenFile -initialdir "." -defaultextension "3rd" -title "Please select a file"]
			}
			cancel {exit 1}
		}
	}

	if {$pf eq ""} {
		UserMsg error "|Thyrd parseArgs| Usage: thyrd {-nowindows} <pool>\nExiting"
		exit 1
	}

	$self slot poolfile $pf
}

# Called by our substitute for exit.  Save persistent state
# before exiting.
#
Thyrd method finalize {{returnCode 0}} {
	Window slot reconfiguring 0

	::Thyrd::saveSplash

	theSpace cleanup
	User exit

	::Thyrd::unsplash
#UserMsg warning "About to exit"
	::Thyrd::crash $returnCode
}

# Pop up a Tcl console.  The showConsole proc is set up in ../console.tcl
#
Thyrd method showTclConsole {} {
	showConsole
}

# Create or deiconify the ThyrdToolbox.
#
Thyrd method showToolbox {} {
	if {![Object exists theThyrdToolbox]} {
		ThyrdToolbox construct theThyrdToolbox TkDot
	}

	theThyrdToolbox wm deiconify
	theThyrdToolbox raise
}

# Get a resource from one of the subdirs of the resourceDir, given 
# a list of suffixes.
#
# If the list of suffixes is provided, we return a two-item
# list including the suffix.
#
Thyrd method getResource {dir name {sufs {}}} {
	set rd [file join [Thyrd slot resourceDir] $dir]

	if {[llength $sufs] == 0} {
		set fn [file join $rd $name]
		if {[file exists $fn]} {
			return $fn
		} else {
			UserMsg error "|$self getResource $dir $name $sufs| Can't find resource $name in $rd"
			return ""
		}
	} else {
		foreach t $sufs {
			set fn [file join $rd $name.$t]
			if {[file exists $fn]} {return [list $fn $t]}
		}

		UserMsg error "|$self getResource $dir $name $sufs| Can't find resource $name of any type in $rd"
		return {"" ""}
	}
}	

# Return an image created for a picture file.  We search
# for a set of possible file extensions in the resources/images
# directory.
#
Thyrd method mkImage {name} {
	lassign [$self getResource images $name {png gif ppm xbm xpm}] fn ext
	if {$fn eq ""} {return ""}

	switch $ext {
		xbm {set type bitmap}
		default {set type photo}
	}

	return [image create $type -file $fn]
}

# Return a static image (shared by multiple widgets) given a
# name.  Use  Thyrd mkImage  to cause a new image to be created
# each time you call it, use this method if the image can be shared.
#
Thyrd method getImage {name} {
	if {[$self arrayHas _images $name]} {
		return [$self arrayGet _images $name]
	} else {
		return [$self arraySet _images $name [$self mkImage $name]]
	}
}

# Return the width and height of an image.
#
Thyrd method getImageSize {name} {
	set im [$self getImage $name]
	return [list [image width $im] [image height $im]]
}

# Return an image from an animated file, given an 
# index. We statically allocate all the frames at the
# start, so we know how many there are.
#
Thyrd method getAnim {name n} {
	if {$n eq "" || ![string is integer $n]} {set n 0}

	if {[$self arrayHas _animframe $name,0]} {
		set len [$self arrayGet _animlen $name]
	} else {
		lassign [$self getResource images $name {png gif}] fn ext
		if {$fn eq ""} {return ""}

		set len 0
		while {![catch {image create photo -file $fn -format "$ext -index $len"} im]} {
			$self arraySet _animframe $name,$len $im
			incr len
		}

		$self arraySet _animlen $name $len
	}

	if {$len == 0} {
		return ""
	} else {
		return [$self arrayGet _animframe $name,[expr {$n % $len}]]
	}
}

# Indicate that the program is busy 
#
Thyrd method busy {} {
	. configure -cursor [Cursors get busy]
}

# Indicate that the program is no longer busy 
#
Thyrd method unbusy {} {
	. configure -cursor ""
}

# Return true if the given file is an export file.
# Our criterion is whether it begins with #Thyrd or not.
#
Thyrd method isExportFile {fn} {
	set fp [open $fn]
	set ans [expr {[read $fp 6] eq "#Thyrd"}]
	close $fp

	return $ans
}

# Justify text, from http://wiki.tcl.tk/1774
# Here because there's no where else to put it.
#
Thyrd method justify {text width} {
    for {set result {}} {[string length $text] > $width} {
		set text [string range $text [expr {$brk+1}] end]
		} {
			set brk [string last " " $text $width]
			if {$brk < 0} {set brk $width}
			append result [string range $text 0 $brk] \n
		}

	return $result$text
}
