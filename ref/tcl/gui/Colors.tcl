### Manage the colors in use by this application.
#
# PJM 20050930	Derived from Fonts
# PJM 20060511	Anything begining with z is for Zinc, and may have 
#				alpha or other additions

Object construct Colors

# Select a color scheme.  Note that the default scheme
# is set by calling this method below.
#
Colors method select {scheme} {
	case $scheme {
		default {
			$self slot logoBG #3968b9

			# transparent color for dragging, should be acceptable on systems
			# that don't support transparency (i.e., should be whitish)
			$self slot transDrag #fffeff

			$self slot frameFG-int #f2ef68
			$self slot frameFG-str white
			$self slot iFrameBG #46425a
			$self slot jFrameBG #56527a

			$self slot jFrameBGHi [::tk::Darken [$self slot jFrameBG] 150]
			$self slot iFrameBGHi [$self slot jFrameBGHi]

			# color used for panel placeholder when zooming
			# DEFERRED this needs to be tweaked for other UI systems
			switch [tk windowingsystem] {
				win32 {
					$self slot panelBG [::tk::Darken SystemButtonFace 100]
				}
				x11 {
					$self slot panelBG #d9d9d9
				}
				aqua {
					$self slot panelBG [::tk::Darken systemWindowBody 100]
				}
			}
				

			$self slot flashBG #ffe8e9
			$self slot cellFG black
			$self slot cellBG white
			$self slot gridFG #56527a
			$self slot gridBG #00add2
			$self slot zeroFG #cdd6e4
			$self slot zeroBG #3a3753
			$self slot emptyFG "#bebebe;20"
			$self slot emptyBG "#bebebe;10"


			$self slot descendLo #448888
			$self slot descendLo-alt "#448888;20"
			$self slot descendHi #66bbbb
			$self slot descendHi-alt "#66bbbb;50"

			$self slot newwinLo #888844
			$self slot newwinLo-alt "#888844;20"
			$self slot newwinHi #bbbb66
			$self slot newwinHi-alt "#bbbb66;50"

			$self slot selectionFrame	#448844
			$self slot selectionHandle	#77aa77
			$self slot selectionBG "#448844;20"

			# frame around cells on X stack
			$self slot xFrame	#4444FF

			# frame around paused cells
			$self slot pausedFrame	#FF4444

			$self slot okButton #5eec61
			$self slot cancelButton #e96161

			$self slot menuHeaderBG #808080
			$self slot menuHeaderFG white

			$self slot scrollRegion #ffa81e

			$self slot zBG	#cccccc
			$self slot zCoreBG	#ffffff
			$self slot zCellBG	#aaaaaa
			$self slot zEmptyFG [$self slot emptyFG]
			$self slot zEmptyBG [$self slot emptyBG]
			$self slot zCellWall #cccccc
			$self slot zGridWall #425566
			$self slot zOuterMembraneBorder	#222299
			$self slot zInnerMembraneBorder	#222299
			$self slot zCellHighlight #33cccc
			$self slot zTriadBG_A #c6c2e7
			$self slot zTriadBG_B #c5e7c2
			$self slot zTriadBG_Y #e7c2c2
			$self slot zTriadBGlite_A [::tk::Darken [$self slot zTriadBG_A] 150]
			$self slot zTriadBGlite_B [::tk::Darken [$self slot zTriadBG_B] 150]
			$self slot zTriadBGlite_Y [::tk::Darken [$self slot zTriadBG_Y] 150]
			$self slot zInfoBG #999933
			$self slot zHandlesUnset "#c0c0c0;30"
			$self slot zHandlesSet "#e85959;30"
			$self slot zHandlesExpand "#edda54;30"

			$self slot zIconEdBorder #222299
			$self slot zIconEdBorder2 #ef7821
			$self slot zIconEdBG #ffffff
			$self slot zIconEdBG2 #dddddd
			$self slot zIconEdDots [::tk::Darken [$self slot zIconEdBG2] 150]
			$self slot zIconEdIn #565886
			$self slot zIconEdOut #865450

			$self slot wStatusBG "#b3e3f7;30"
			$self slot wStatusEdge "#b3e3f7"
			$self slot wStatusText "#b3e3f7"
			$self slot wErrorText "#ee0000"
			$self slot wErrorEdge "#ee0000"
			$self slot wErrorBG "#eeeeee"

			$self slot waveText #ffff17
			$self slot stackCellWall #000000
			$self slot stackCellBG #dddddd
			$self slot stripeBG #f5f5f5

			$self slot glyphTrans "#000000;20"

			$self slot labelHilite blue
			$self slot editedEntryBG "lightblue"
			$self slot invalidPath "pink"

			$self slot bmHandleFill "lightgreen"
			$self slot bmHandleLine "green"
		}
		render {
			$self slot frameFG #f2ef68
			$self slot iFrameBG #56527a
			$self slot jFrameBG #56527a
			$self slot flashBG #ffe8e9
			$self slot cellFG black
			$self slot cellBG white
			$self slot gridFG #56527a
			$self slot gridBG #6212ba
			$self slot zeroFG #cdd6e4
			$self slot zeroBG #3a3753
			$self slot emptyFG #bebebe
			$self slot emptyBG #bebebe


			$self slot descendLo "#888844;20"
			$self slot descendHi "#bbbb66;50"
			$self slot okButton #5eec61
			$self slot cancelButton #e96161

			$self slot zBG	#cccccc
			$self slot zCoreBG	#ffffff
			$self slot zCellBG	#aaaaaa
			$self slot zEmptyFG "[$self slot emptyFG];80"
			$self slot zEmptyBG "[$self slot emptyBG];80"
			$self slot zGridlines #cccccc
			$self slot zOuterMembraneBorder	"#222299;80"
			$self slot zInnerMembraneBorder	"#222299;80"
			$self slot zCellHighlight "#33cccc;50"
			$self slot zTriadBG_A #aeffaa
			$self slot zTriadBG_B #b0aaff 
			$self slot zTriadBG_Y #ffaaaa
		}
		blueish {
			$self slot frameFG #f2ef68
			$self slot iFrameBG #019ad3
			$self slot jFrameBG #0170d3
			$self slot flashBG #ffe8e9
			$self slot cellFG black
			$self slot cellBG white
			$self slot gridFG #56527a
			$self slot gridBG #6212ba
			$self slot zeroFG #cdd6e4
			$self slot zeroBG #3873df
			$self slot emptyFG #bebebe
			$self slot emptyBG #bebebe
		}
		original {
			$self slot frameFG	white
			$self slot iFrameBG #5E877C
			$self slot jFrameBG #CCB68F
			$self slot flashBG #ffbdbf
			$self slot cellFG black
			$self slot cellBG white
			$self slot gridFG white
			$self slot gridBG #0000CC
			$self slot zeroFG #6b85b2
			$self slot zeroBG #6b85b2
			$self slot emptyFG white
			$self slot emptyBG gray
		}
	}
}

# Get the value of a color slot, but complain
# if it's not there.  
#
# If the alt argument is present and true, return
# ``[Colors get ${c}-alt]``, which usually adds an
# alpha value
#
Colors method get {c {alt 0}} {
	set cerr $c

	if {$alt} {set c "${c}-alt"}

	if {![$self hasSlot $c]} {
		puts stderr "|$self get $cerr $alt| Color $c not defined in Colors.tcl, substituting black"
		return black
	} else {
		return [$self slot $c]
	}
}

# Construct a hex version of a color specified as R G B in
# [0..255].
#
Colors method fromRGB {r g b} {
	return "#[format %02x $r][format %02x $g][format %02x $b]"
}

Colors select default
