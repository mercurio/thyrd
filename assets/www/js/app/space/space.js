/*
 * The definition of a Thyrd space, which is a
 * PouchDB database.
 *
 * A space contains all the cells (by holding a reference
 * to the root cell) and a TriadMapper that holds all Triads.
 *
 * Observable events:
 *  stats       number of waves or active waves changed
 *  clipboard   the cut/copy/paste clipboard has changed
 *
 * Instantiated as the global Thyrd.space
 */
define([
    'lib/pouchdb.min'
], function(PouchDB) {
    var spaceName = 'testSpace';

    return Thyrd.space = {
        db: null,               // the PouchDB database
        root: null,             // id of the root cell of the space
        triadMapper: null,      // maps cells to triads
        waveMapper: {},         // map from a result cell to the wave that computes it
        undo: [],               // stacks for undo/redo support
        redo: [],
        nWaves: 0,              // number of waves
        nActiveWaves: 0,        // number of active waves
        server: '192.168.2.4',  // couchdb server or equivalent
        port: '3333',           // couchdb port

        /*
         * Reset database and then casue it to exist
         */
        reset: function(callback) {
            var self = this;
            PouchDB.destroy(spaceName, function() { self.exist(callback) });
        },
                
        /*
         * Initialize the space
         */
        exist: function(callback) {
            this.db = new PouchDB(spaceName);

            var self = this;
            this.db.get('root', function(err, resp) {
                if(err && err.error) {
                    self.buildNewSpace(function() {
                        self.db.get('root', function(err, resp) {
                            if(err && err.error) {  // something's wrong
                                alert("Unable to construct new Thyrd space");
                                return;
                            }

                            self._initToRoot(resp, callback);
                        })
                    });
                } else {
                    self._initToRoot(resp, callback);
                }
            });
        },

        /*
         * Initialize to the given root node record
         */
        _initToRoot: function(rootRec, callback) {
            this.root = rootRec.root;
            callback && callback();
        },

        /*
         * Return the remote database URL
         */
        remoteDB: function(space) {
            return 'http://' + this.server + ':' + this.port + '/' + space;
        },

        /*
         * Sync this space with the remote space, continuously, both directions
         */
        syncBoth: function() {
            // mark something as busy
            var self = this;
            var opts = {continuous: true, complete: function() {self.syncComplete()} };

            this.db.replicate.to(this.remoteDB(), opts);
            this.db.replicate.from(this.remoteDB(), opts);
        },

        /*
         * Save the space to the remote DB
         */
        save: function(callback) {
            // mark something as busy
            var self = this;

            this.db.replicate.to(this.remoteDB(spaceName), {
                continuous: false, 
                complete: function() { callback && callback() } 
            });
        },

        /*
         * Save the space to a new remote DB
         */
        saveAs: function(name, callback) {
            // mark something as busy
            var self = this;
            var opts = {continuous: false, complete: function() { callback && callback() } };

            this.db.replicate.to(this.remoteDB(name), opts);
        },

        /*
         * The sync is complete
         */
        syncComplete: function() {
            alert('sync complete');
        },

        /*
         * Build a new space
         */
        buildNewSpace: function(callback) {
            this.db.put({
                _id: 'root',
                contents: 'i exist',
                root: 't3'
            }, function() {
                callback && callback();
            });


            /*
            this.set("/home/tests/table1/alpha english", "one");
            this.set("/home/tests/table1/beta english", "two");
            this.set("/home/tests/table1/gamma english", "three");
            this.set("/home/tests/table1/alpha spanish", "uno");
            this.set("/home/tests/table1/beta spanish", "dos");
            this.set("/home/tests/table1/gamma spanish", "tres");
            this.set("/home/tests/table1/alpha french", "un");
            this.set("/home/tests/table1/beta french", "deux");
            this.set("/home/tests/table1/gamma french", "trois");

            set tri [$self bind "/home/tests/table1" [Cell new "Table"] "/thyrd/ys/panel"]

            $self set "/home/tests/table2/a" "a1"
            $self set "/home/tests/table2/a 2" "a2"
            $self set "/home/tests/table2/b" "b1"
            $self set "/home/tests/table2/b 2" "b2"
            $self set "/home/tests/table2/c" "c1"
            $self set "/home/tests/table2/c 2" "c2"

            $self bind "/home/tests/table2/a" "/home/tests/table1/alpha english" "/thyrd/ys/same"
            $self bind "/home/tests/table2/b" "/home/tests/table1/beta spanish" "/thyrd/ys/same"
            $self bind "/home/tests/table2/c" "/home/tests/table1/gamma french" "/thyrd/ys/same"

            $self set "/home/tests/table3/1 1" "Hello world!" <string>
            $self set "/home/tests/table3/2 1" 10 "<integer> 0 20 2"
            $self set "/home/tests/table3/3 1" 10.0 "<real> 0 20"
            $self set "/home/tests/table3/4 1" 1 <boolean>
            $self set "/home/tests/table3/1 2" 10 <pixels>
            $self set "/home/tests/table3/2 2" alpha "<choice> alpha beta gamma delta epsilon"
            $self set "/home/tests/table3/3 2" #ff00ff <color>
            $self set "/home/tests/table3/4 2" fixed <font>
            $self set "/home/tests/table3/1 3" "fold" Opcode
            $self set "/home/tests/table3/2 3" ::testvar <variable>
            $self set "/home/tests/table3/3 3" "/home/tests/table2/a" Path
            $self set "/home/tests/table3/4 3" $tri TriadCore
            $self set "/home/tests/table3/1 4" {set ::testvar 42
        puts $::testvar
        } <script>

            $self bind "/thyrd 0" [Cell new 100] "/thyrd/ys/width"
            $self bind "/thyrd 0" [Cell new 20] "/thyrd/ys/height"

            $self set "/home/tests/flatland/x triangle" 80 "<real> 0 1000 .5"
            $self set "/home/tests/flatland/y triangle" 60 "<real> 0 1000 .5"
            $self set "/home/tests/flatland/sides triangle" 3 "<integer> 3 50 1"
            $self set "/home/tests/flatland/radius triangle" 50 "<real> 1 200 .5"
            $self set "/home/tests/flatland/rotation triangle" 0 "<real> 0 360 .5"
            $self set "/home/tests/flatland/color triangle" "#ff0000" <color>
            $self set "/home/tests/flatland/alpha triangle" "50" "<integer> 0 100 1"
            $self set "/home/tests/flatland/priority triangle" "50" "<integer> 0 100 1"

            $self set "/home/tests/flatland/x square" 225 "<real> 0 1000 .5"
            $self set "/home/tests/flatland/y square" 60 "<real> 0 1000 .5"
            $self set "/home/tests/flatland/sides square" 4 "<integer> 3 50 1"
            $self set "/home/tests/flatland/radius square" 50 "<real> 1 200 .5"
            $self set "/home/tests/flatland/rotation square" 0 "<real> 0 360 .5"
            $self set "/home/tests/flatland/color square" "#00ff00" <color>
            $self set "/home/tests/flatland/alpha square" "70" "<integer> 0 100 1"
            $self set "/home/tests/flatland/priority square" "55" "<integer> 0 100 1"

            $self set "/home/tests/flatland/x hexagon" 80 "<real> 0 1000 .5"
            $self set "/home/tests/flatland/y hexagon" 180 "<real> 0 1000 .5"
            $self set "/home/tests/flatland/sides hexagon" 6 "<integer> 3 50 1"
            $self set "/home/tests/flatland/radius hexagon" 45 "<real> 1 200 .5"
            $self set "/home/tests/flatland/rotation hexagon" 0 "<real> 0 360 .5"
            $self set "/home/tests/flatland/color hexagon" "#0000ff" <color>
            $self set "/home/tests/flatland/alpha hexagon" "30" "<integer> 0 100 1"
            $self set "/home/tests/flatland/priority hexagon" "30" "<integer> 0 100 1"

            $self set "/home/tests/flatland/x circle" 225 "<real> 0 1000 .5"
            $self set "/home/tests/flatland/y circle" 180 "<real> 0 1000 .5"
            $self set "/home/tests/flatland/sides circle" 32 "<integer> 3 50 1"
            $self set "/home/tests/flatland/radius circle" 50 "<real> 1 200 .5"
            $self set "/home/tests/flatland/rotation circle" 0 "<real> 0 360 .5"
            $self set "/home/tests/flatland/color circle" "#ff00ff" <color>
            $self set "/home/tests/flatland/alpha circle" "40" "<integer> 0 100 1"
            $self set "/home/tests/flatland/priority circle" "150" "<integer> 0 100 1"

            $self setAttr /home/tests/flatland panel Flatland
        */
        }

    }
});

/*

Space mixin Observable


# Cause the space (``theSpace``) to exist, if it doesn't already.
# If the root doesn't exist, we create a new one and
# construct the default space.
#
# If it does exist, we load it.  Same for the triadMaps.
# 
# A lot of persistent object loading occurs here.
#
Space method exist {} {
	if {[catch theSpace]} {
		$self construct theSpace
		theSpace mixin Thing
		theSpace mixin Constrainable

		theSpace slot clipboard ""
	}	


	set tm [theSpace slot triadMapper]
	if {$tm eq ""} {
		theSpace slot triadMapper [TriadMapper new]
	} else {$tm noop}

	set wm [theSpace slot _waveMapper]
	if {$wm eq ""} {
		set wm [Map construct *]
		#$wm mixin Thing
		theSpace slot _waveMapper $wm
	} else {$wm noop}

	set root [theSpace slot root]
	if {$root eq ""} {
		set c [Cell new]
		theSpace slot root $c
		$c setAsRoot
		theSpace defaultSpace
	} else {
		if {[catch {$root noop} err]} {
			set res [UserMsg error "|$self exist| Error when restoring thyrdspace: $err"] 
			if {$res != 0} {
				Thyrd::crash
			}
		}
	}

	Options initialize
	Op makeIndex
	theSpace opsTable
	Heart initialize

	Object safe [theSpace slot wave] destruct
	$self slot wave [Wave newCaptive]

	theSpace scanWaves
}

# Cleanup the space prior to writing to the persistent store.
#
Space method cleanup {} {
	$self setClipboard ""

	foreach w [Wave children] {
		$w destruct
	}
}

# Return true if the given cell is the root of this
# space
#
Space method isRoot {c} {
	return [string equal [$self slot root] $c]
}

# Attach a triad 
#
Space method attachTriad {which t} {
	set tm [$self slot triadMapper]
	assert {[Object exists $tm]}

	$tm attachTriad $which $t
}

# Detach a triad
#
Space method detachTriad {which t} {
	set tm [$self slot triadMapper]
	assert {[Object exists $tm]}

	$tm detachTriad $which $t
}

# Remove a triad completely
#
Space method removeTriad {t} {
	set tm [$self slot triadMapper]
	assert {[Object exists $tm]}

	$tm removeTriad $t
}

# Find triads
#
Space method findTriads {a b y} {
	set tm [$self slot triadMapper]
	assert {[Object exists $tm]}

	return [$tm find $a $b $y]
}

# Given a cell, load the triads for which it is
# the A cell
#
Space method loadTriads {c} {
	set tm [$self slot triadMapper]
	assert {[Object exists $tm]}

	foreach t [$tm find $c * *] {
		$t noop
	}
}

# Set the value of a cell, given the path as text
# and an optional type.
#
Space method set {path value {type Core}} {
	set p [Path newVolatile $path]

	Object safe [$p resolve "" yes] set $value $type

	$p destruct
	return $value
}

# Get the value of a cell, given the path as text
#
Space method get {path} {
	set p [Path newVolatile $path]

	set v [Object safe [$p resolve "" no] get]

	$p destruct
	return $v
}

# Find the cell for a path, given as text. If
# its already a cell just return it.
#
# Optionally create the cell if it doesn't exist
# yet.
#
Space method find {path {create no}} {
	if {[Object existsAs Cell $path]} {return $path}

	set p [Path newVolatile $path]

	set c [$p resolve "" $create]

	$p destruct
	return $c
}

# Create a new Triad binding the three paths given, but
# only if the Triad doesn't already exist.
#
# If the Y is /thyrd/ys/formula or /thyrd/ys/event and it's 
# a new triad and the A and B cells aren't limbo cells, we create a wave.
#
Space method bind {a b y} {
	set ts [$self findTriads $a $b $y]
	set tsl [llength $ts]

	if {$tsl == 0} {
		set t [Triad new $a $b $y]
		set ty [$t cell Y]

		if {![regexp {limbo@.*} [$t cell A]] && ![regexp {limbo@.*} [$t cell B]]} {
			if {$ty eq [$self slot _formulaCell]} {$self _newWave $t formula}
			if {$ty eq [$self slot _eventCell]} {$self _newWave $t event}
		}

		return $t
	} elseif {$tsl == 1} {
		return [lindex $ts 0]
	} else {
		UserMsg error "|$self bind $a $b $y| More than 1 ($tsl) triads binding these cells already exist"
	}
}

# Create a new Triad binding the two paths given
# with the Y /thyrd/ys/formula, and create a
# wave for the new formula.
#
Space method bindFormula {a b} {
	set t [$self bind $a $b "/thyrd/ys/formula"]
	$self _newWave $t formula
	return $t
}

# Create a new Triad binding the two paths given
# with the Y /thyrd/ys/event, and create a
# wave for the new event.
#
Space method bindEvent {a b} {
	set t [$self bind $a $b "/thyrd/ys/event"]
	$self _newWave $t event
	return $t
}

# Cut the given cell(s) into a buffer.  We're given
# the containing cell and the start and end i and j 
# values.
#
Space method cut {gc i0 j0 {i1 ""} {j1 ""}} {
	if {$il eq ""} {set i1 $i0}
	if {$jl eq ""} {set j1 $j0}

	set buf [Cell new "" Grid] 
	
	foreach {wi wj} [$gc as CMGrid walk $i0 $j0 $i1 $j1] {
		set wc [$gc as CMGrid getCell $wi $wj]

		set i [expr {$wi - $i0 + 1}]
		set j [expr {$wj - $j0 + 1}]

		$wc relocate $buf $i $j
	}

	return $buf
}

# Construct the default space, the initial contents of
# Thyrd space in case we're provided with an empty or
# non-existent .3rd file to open.
#
Space method defaultSpace {} {
	$self defaultYs

	$self set "/home" "Start here"
}

# Construct the default Y table
#
Space method defaultYs {} {
	set yc [Cell goto "/thyrd/ys" yes]

	$self addY $yc "event" event.png "" \
		"The first cell of the event trigger by the A cell" Path \
		[list "+0 --" "-- --"]

	$self addY $yc "formula" formula.png "" \
		"The first cell of the formula for the A cell" Path \
		[list "+0 --" "-- --"]

	$self addY $yc "panel" panel.png "" \
		"Name of panel to use for this cell" <string> \
		[list "-- +0" "-- --"]
	
	$self addY $yc "height" height.png [Spans get defaultCellH] \
		"The height of the A cell" <integer> \
		[list "-- +0" "-- --"]

	$self addY $yc "width" width.png [Spans get defaultCellW] \
		"The width of the A cell" <integer> \
		[list "+0 --" "-- --"]
			
	$self addY $yc "same" same.png Core \
		"IsA relationship" <string> \
		[list "+0 --" "-- --"]

}

# Return a list of the Ys currently defined. If
# ``trunc`` is true, return only the tails.
#
Space method listYs {{trunc 0}} {
	set yc [Cell goto "/thyrd/ys" yes]
	set out [list]

	foreach {wi wj} [$yc as CMGrid walk iframe] {
		set t [[$yc as CMGrid getCell $wi $wj] get]
		if {$trunc} {
			lappend out $t
		} else {
			lappend out "/thyrd/ys/$t"
		}
	}

	return [lsort $out]
}

# Given an A cell and an attribute name, find the value
#
Space method getAttr {a attr} {
	set y [Cell goto "/thyrd/ys/$attr"]
	if {$y eq ""} {
		UserMsg error "|$self getAttr $a $attr| Attribute not found in /thyrd/ys"
		return
	}

	# Look for triad on this cell
	set b [$self tryToRelate $a $y]
	if {[set b [$self tryToRelate $a $y]] ne ""} {
		return [$b get]
	}
	
	# Follow route looking for triad
	set r [$y goto "+0 route"]
	if {$r ne "" && ![$r atomic]} {
		foreach p [$r as CMList getList] {
			if {[set b [$self tryToRelate $a $y $p]] ne ""} {
				return [$b get] 
			}
		}
	}

	# Return default value
	set d [$y goto "+0 default"]
	return [$d get]
}

# Given an A cell and an attribute name, see if the attribute
# is set locally on this cell (don't follow route).
#
Space method hasAttr {a attr} {
	set y [Cell goto "/thyrd/ys/$attr"]
	if {$y eq ""} {
		UserMsg error "|$self hasAttr $a $attr| Attribute not found in /thyrd/ys"
		return
	}

	# Look for triad on this cell
	return [expr {[$self tryToRelate $a $y] ne ""}]
}

# Given an A cell and an attribute name, look for a
# local setting of the attribute and remove it.
#
Space method remAttr {a attr} {
	set y [Cell goto "/thyrd/ys/$attr"]
	if {$y eq ""} {
		UserMsg error "$self getAttr $a $attr| Attribute not found in /thyrd/ys"
		return
	}

	# Look for triad on this cell
	set t [[$self slot triadMapper] find $a * $y]
	if {$t eq ""} return 

	set b [$t cell B]
	$t destruct
	Object safe $b deject
}

# Set an attribute given its name and the A cell.  If the
# B cell is already there, we set its value, else we
# create the B cell and the triad.
#
Space method setAttr {a attr value} {
	set y [Cell goto "/thyrd/ys/$attr"]
	if {$y eq ""} {
		UserMsg error "$self getAttr $a $attr| Attribute not found in /thyrd/ys"
		return
	}
	
	set b [$self tryToRelate $a $y]
	
	if {$b eq ""} {
		set t [$y goto "+0 type"]
		
		set b [Cell new $value [$t get]]
		$self bind $a $b $y
	}

	return [$b set $value]
}

# Given an A cell/path and a Y cell/path containing a relation, and
# a (presumably relative) path to try, see if there's a B cell there.
# If there's no path, look just use the A and Y and
# look for the B.
#
# If we follow a path and find the same A cell, return
# failure.
#
Space method tryToRelate {a y {path ""}} {
	set tm [$self slot triadMapper]

	set a [$self find $a]
	set y [$self find $y]

	if {$path eq ""} {
		set b [$tm findB $a $y]
	} else {
		set na [$a goto $path]
		if {$na eq $a} {return ""}

		return [$tm findB $na $y]
	}
}

# Scan the triads for formulas and events and make sure each one
# has an associated wave.  Don't start them yet.
#
# We also set the ``_eventCell`` and ``_formulaCell`` slots here.
#
Space method scanWaves {} {
	set tm [$self slot triadMapper]
	assert {[Object exists $tm]}

	set f [$self slot _formulaCell [$self find "/thyrd/ys/formula"]]
	set e [$self slot _eventCell [$self find "/thyrd/ys/event"]]
	
	set fs [$tm find * * $f]
	$self slot nFormulas [llength $fs]

	set es [$tm find * * $e]
	$self slot nEvents [llength $es]

	$self slot nWaves 0
	$self slot nActiveWaves 0

	foreach t $es {
		$self _newWave $t event
	}

	foreach t $fs {
		$self _newWave $t formula
	}
}

# Given a triad with a Y of /thyrd/ys/formula or 
# /thyrd/ys/event, make a
# new wave, but don't start it yet.
#
# The A cell is the anchor, the B cell is the code.
#
Space method _newWave {t which} {
	set wm [$self slot _waveMapper]

	set ac [$t cell A]
	set cc [$t cell B]
	if {$ac eq "" || $cc eq ""} {return ""}
	if {![Object exists $ac] || ![Object exists $cc]} {return ""}

	set w [$wm getLink $ac]
	if {$w ne "" && ![$w startsAt $cc]} {
		$w destruct
		set w ""
	}

	if {$w eq ""} {
		set w [Wave new $cc $ac $which]
		$wm link $ac $w
	}

	$self slotIncr nWaves
	if {[$w slot state] eq "running"} {
		$self slotIncr nActiveWaves
	}

	$self notifyObservers stats
}

# This is called by the start/stop button
#
Space method start {} {
	$self startWaves
	Heart start
}

# This is called by the start/stop button
#
Space method stop {} {
	Heart stop
	$self stopWaves
}

# Start all the known formula waves (as known to the waveMapper).
# We also do a scan first, to catch any that have been
# recently created.
#
Space method startWaves {} {
	set wm [$self slot _waveMapper]
	assert {[Object exists $wm]}
	Wave slot enable 1

	theSpace scanWaves

	set nw 0
	set naw 0

	foreach rc [$wm links] {
		set w [$wm getLink $rc]
		if {$w ne ""} {
			$w start [$w is event]
		}

		incr nw
		if {[$w slot state] eq "flowing"} {incr naw}
	}

	$self slot nWaves $nw
	$self slot nActiveWaves $naw
	$self notifyObservers stats
}

# Suspend all the known waves (as known to the waveMapper)
#
Space method stopWaves {} {
	set wm [$self slot _waveMapper]
	assert {[Object exists $wm]}
	Wave slot enable 0

	set nw 0
	set naw 0

	foreach rc [$wm links] {
		set w [$wm getLink $rc]
		if {$w ne ""} {
			$w suspend
		}

		incr nw
		if {[$w slot state] eq "flowing"} {incr naw}
	}

	$self slot nWaves $nw
	$self slot nActiveWaves $naw
	$self notifyObservers stats
}


# List all the known waves (as known to the waveMapper)
#
Space method ALTlistWaves {} {
	set wm [$self slot _waveMapper]
	assert {[Object exists $wm]}

	set out [list]

	foreach rc [$wm links] {
		set w [$wm getLink $rc]

		lappend out [list $w $rc [$w slot state]]
	}

	return $out
}

# List all the known waves (as known to the waveMapper)
#
Space method listWaves {} {
	set out [list]

	foreach w [lsort [Wave children]] {
		set s [$w slot start]
		if {[Object exists $s]} {set s [$s path]}
		set r [$w slot result]
		if {[Object exists $r]} {set r [$r path]}
		lappend out [list $w [$w slot state] $s $r]
	}

	return $out
}

## The primitive relations.  We construct the table
## /thyrd/ys where the i axis is the name of the
## relation and the j axis contains the name,
## icon, default, help, type, and a list of the paths comprising
## the inheritance route.
##

# Add a relation to /thyrd/ys.  ``yc`` is the cell /thyrd/ys
#
Space method addY {yc y icon def help type route} {
	$yc putAt $y  $y "name"
	$yc putAt $icon $y "icon"
	$yc putTypeAt $def $type $y "default"
	$yc putAt $help $y "help"
	$yc putAt $type $y "type"
	set n [$yc subCell! $y "route"]
	eval $n as CMRoute setRoute $route
}

# Add an opcode to /thyrd/ops.  ``oc`` is the cell /thyrd/ops
#
Space method _addOp {oc o} {
	$oc putTypeAt [$o slot opcode] Opcode $o "example"
	$oc putAt [$o slot opcode]  $o "opcode"
	$oc putAt [$o slot caption]  $o "caption"
	$oc putAt [$o slot in] $o "in"
	$oc putAt [$o slot out] $o "out"
	$oc putAt [$o slot tags] $o "tags"
	$oc putAt [Thyrd justify [$o slot help] [Spans get linelen]] $o "help"
	$oc putAt [Thyrd justify [$o slot sidefx] [Spans get linelen]] $o "sidefx"
}


# Construct or reconstruct the ops table
#
Space method opsTable {} {
	set oc [Cell goto "/thyrd/ops" yes]

	foreach o [lsort [Op realOps]] {
		$self _addOp $oc $o
	}

	$self setAttr "/thyrd/ops" panel "Table -readonly 1 -flip 1 -filter tags -dragforce 1"
}

# Generate html output for the opcodes currently defined.
# This is meant to be run by hand and not exposed to the end user.
#
# We need a directory to place everything in, including the images.
# The output will be index.html.
#
Space method opsHTML {{dir .}} {
	set pf [Thyrd getResource proto ops.html]

	set html [file join $dir index.html]

	set fp [open $html w]

	::Thyrd::protoHTML $pf head $fp

	foreach o [lsort [Op realOps]] {
		::Thyrd::protoHTML $pf record $fp

		set im [$o slot iconlg]
		$im write [file join $dir ${o}.png] -format png
	}

	::Thyrd::protoHTML $pf tail $fp

	close $fp
}

# Generate json output for the opcodes currently defined.
# This is meant to be run by hand and not exposed to the end user.
#
# The output will be opcodes.json in the given dir.
#
Space method opsJSON {{dir .}} {
	set json [file join $dir opcodes.json]

	set fp [open $json w]

	set out \[

	foreach o [lsort [Op realOps]] {
		append out \{
		append out "'opcode':'[$o slot opcode]',"
		append out "'caption':\"[$o slot caption]\","
		append out "'in':'[$o slot in]',"
		append out "'out':'[$o slot out]',"
		append out "'help':\"[$o slot help]\","
		append out "'sidefx':\"[$o slot sidefx]\","
		append out "'icongl':'[file tail [[$o slot icongl] cget -file]]',"
		append out "'iconsm':'[file tail [[$o slot iconsm] cget -file]]',"
		append out "'iconlg':'[file tail [[$o slot iconlg] cget -file]]',"
		append out "'icon':'[string range [file tail [[$o slot icongl] cget -file]] 0 end-7]',"
		append out "'tags':'[$o slot tags]'"
		append out \},
	}

	append out \]

	puts $fp $out
	close $fp
}

### Editing space ###

# Write the value of a cell via the captive wave,
# so it can be undone.
#
Space method editSet {c v} {
	set w [$self slot wave]

	$w clearFuture

	$w pushCell $c
	$w push $v
	$w execOp OpSet

	if {[$w slot state] eq "error"} {
		UserMsg error "|$w do OpSet| [$w slot error]"
	}

	theSpace setClipboard [$w peekUn]
}

# Set the type of a cell via the captive wave,
# so it can be undone.
#
Space method editSetType {c t} {
	set w [$self slot wave]

	$w clearFuture

	$w pushCell $c
	$w push $t
	$w execOp OpSetType

	if {[$w slot state] eq "error"} {
		UserMsg error "|$w do OpSetType| [$w slot error]"
	}

	theSpace setClipboard [$w peekUn]
}

# Copy a range of cells from a cell into a new holding
# cell, and return it.
#
# We recursively duplicate each of the cells, constructing
# a mapping from old cells to their duplicates and a list
# of all triads attached to the copied cells.  Then we 
# iterate over the triads, making copies that have all three
# corners transformed by the cell map.
#
# The args can be anything known to ``Grid range2vars``, or
# the list ``exactly [sublist]``, where the sublist contains
# exactly those indexes that should be copied.
#
# If the cell is atomic, we return a copy of it in a holding
# cell (at 1 1).  ``args`` are ignored (and should be empty).
#
# We now use _copyFreeCells, originally developed for export.
# A free cell is defined as one not under $cell, so this works
# for copying stuff back from limbo (otherwise unsituated cells
# just stay in limbo).
#
Space method copy {cell args} {
	if {![Object existsAs $cell Cell]} {
		UserMsg error "|$self copy $cell $args|$cell is not a Cell"
	}

	set nc [Cell new "" Grid]
	set clist [DefMap construct *]
	set tlist [Object construct *]

	$self _copyCells $cell $nc $clist $tlist @ {*}$args
	$self _copyFreeCells $cell $clist $tlist

	# Now deal with the triads
	#
	foreach t [$tlist slots] {
		$self bind [$clist get [$t cell A]] [$clist get [$t cell B]] [$clist get [$t cell Y]]
	}

	$clist destruct
	$tlist destruct

	return $nc
}

# The core of the copy operation, split out so it can be
# reused for exporting.
#
Space method _copyCells {cell nc clist tlist prefix args} {
	set ncx [$nc slot core]

	if {[$cell atomic]} {
		$ncx setCell [$self _clone $cell $clist $tlist $prefix] 1 1
	} else {
		set x [$cell slot core]

		if {[llength $args] == 2 && [lindex $args 0] eq "exactly"} {
			foreach {wi wj} [lindex $args 1] {
				set wc [$x getCell $wi $wj]
				if {$wc ne ""} {
					$ncx setCell [$self _clone $wc $clist $tlist $prefix] $wi $wj
				}
			}
		} else {
			Grid range2vars $args

			set ni0 [expr {$i0 == 0 ? 0 : 1}]
			set nj0 [expr {$j0 == 0 ? 0 : 1}]
		
			foreach {wi wj} [$x walk [list $i0 $j0 $i1 $j1]] {
				set wc [$x getCell $wi $wj]
				if {$wc ne ""} {
					$ncx setCell [$self _clone $wc $clist $tlist $prefix] \
						[expr {$wi - $i0 + $ni0}] [expr {$wj - $j0 + $nj0}] 
				}
			}
		}

	}

	$ncx framesChanged
}

# Scan the tlist for new triads and verify all of 
# their corners are in the clist. For any that aren't,
# copy them if they're free and not under $cell (all the cells
# in limbo are free, so we need the isUnder check), otherwise we'll use the
# path. In the course of copying, we may add more triads
# to the tlist. We keep on going until the tlist
# doesn't change.
#
Space method _copyFreeCells {cell clist tlist {prefix @}} {
	while {[$self _scanTList $tlist]} {
		foreach t [$tlist slots] {
			if {[$tlist slot $t]} {
				foreach c [$t cells] {
					if {![$clist hasSlot $c] && [$c isFree] && ![$c isUnder $cell]} {
						 $self _clone $c $clist $tlist $prefix
					}
				}

				$tlist slot $t 0
			}
		}
	}
}

# Scan all the triads in the tlist to see if any are
# new.
#
Space method _scanTList {tlist} {
	foreach s [$tlist slots] {
		if {[$tlist slot $s]} {return 1}
	}

	return 0
}


# Return a clone of a cell, duplicating the core.
# We're provided with two temporary objects,
# one mapping all the cells in this copy operation to
# their clones, and another for triads that need to 
# be duplicated.
# 
# If the cell we're asked to clone doesn't exist, we
# return "".
#
# An optional fourth argument is used as the prefix 
# for the cloned cells.
#
# tlist is treated as a set, we set a slot for each
# triad we find. We set the corresponding value to 1
# to indicate that it's a new setting.
#
Space method _clone {c clist tlist {prefix "@"}} {
	if {$c eq ""} {return ""}

	if {[$c atomic]} {
		set cl [$c clone $prefix]
	} else {
		set x [$c slot core]

		set cl [Cell new "" Grid $prefix]
		set clx [$cl slot core]

		foreach {wi wj} [$x walk all] {
			$clx setCell [$self _clone [$x getCell $wi $wj] $clist $tlist $prefix] $wi $wj
		}

		$clx framesChanged
	}

	$clist slot $c $cl

	set tm [$self slot triadMapper]

	foreach t [concat [$tm find $c * *] [$tm find * $c *] [$tm find * * $c]] {
		$tlist slot $t 1
	}

	return $cl
}


# Copy a range of cell types from a grid cell into a new holding
# cell, and return it. The cell contents and triads are ignored.
#
Space method copyTypes {cell i0 j0 i1 j1} {
	if {![Object existsAs $cell Cell]} {
		UserMsg error "|$self copyTypes $cell $args|$cell is not a Cell"
	}

	if {[$cell atomic]} {
		UserMsg error "|$self copyTypes $cell $args|$cell is not a grid cell"
	} 

	set nc [Cell new "" Grid]
	set ncx [$nc slot core]

	set x [$cell slot core]

	set ni0 [expr {$i0 == 0 ? 0 : 1}]
	set nj0 [expr {$j0 == 0 ? 0 : 1}]

	foreach {wi wj} [$x walk [list $i0 $j0 $i1 $j1]] {
		set wc [$x getCell $wi $wj]
		if {$wc ne ""} {
			$ncx setCell [Cell new "" [$wc getType]] [expr {$wi - $i0 + $ni0}] [expr {$wj - $j0 + $nj0}]
		}
	}

	return $nc
}

# Delete a range of cells from a grid, leaving empty space
#
Space method delete {cell i0 j0 i1 j1} {
	if {![Object existsAs $cell Cell]} {
		UserMsg error "|$self delete $cell $i0 $j0 $i1 $j1|$cell is not a Cell"
	}

	if {[$cell atomic]} {
		UserMsg error "|$self delete $cell $i0 $j0 $i1 $j1|$cell is not a grid cell"
	}

	set x [$cell slot core]
	$x delete $i0 $j0 $i1 $j1
}

# Paste the cells from a holding cell into a grid.  If there are cells
# in the target area, return a copy in another holding cell.  Same if
# the cell is atomic.
#
Space method paste {hcell cell {i 1} {j 1}} {
	if {![Object existsAs $hcell Cell]} {
		UserMsg error "|$self paste $hcell $cell $i $j|$hcell is not a Cell"
	}

	if {![Object existsAs $cell Cell]} {
		UserMsg error "|$self paste $hcell $cell $i $j|$cell is not a Cell"
	}

	if {[$cell atomic]} {
		set unhcell [$self copy $cell]
		set x [$cell empty Grid]
	} else {
		lassign [$hcell size] x y
		set i1 [+ $i $x -2]
		set j1 [+ $j $y -2]

		set unhcell [$self copy $cell $i $j $i1 $j1]

		set x [$cell slot core]
		$x delete $i $j $i1 $j1
	}

	set hx [$hcell slot core]

	set clist [DefMap construct *]
	set tlist [Object construct *]

	foreach {wi wj} [$hx walk contents] {
		set wc [$hx getCell $wi $wj]
		if {$wc ne ""} {
			$x setCell [$self _clone $wc $clist $tlist] [+ $i $wi -1] [+ $j $wj -1]
		}
	}

	$x framesChanged

	$self _copyFreeCells $hcell $clist $tlist

	foreach t [$tlist slots] {
		$self bind [$clist get [$t cell A]] [$clist get [$t cell B]] [$clist get [$t cell Y]]
	}

	$clist destruct
	$tlist destruct

	return $unhcell
}

# Paste the frame cells from a holding cell into a grid.  If there are cells
# in the target area, return a copy in another holding cell.  Same if
# the cell is atomic.
#
Space method pasteFrame {hcell cell which start} {
	if {![Object existsAs $hcell Cell]} {
		UserMsg error "|$self paste $hcell $cell $i $j|$hcell is not a Cell"
	}

	if {![Object existsAs $cell Cell]} {
		UserMsg error "|$self paste $hcell $cell $i $j|$cell is not a Cell"
	}

	set iAxis [? {$which eq "i"}]

	lassign [$hcell size] x y
	if {$iAxis} {
		set n [- $x 1]
	} else {
		set n [- $y 1]
	}

	if {[$cell atomic]} {
		set unhcell [$self copy $cell]
		set x [$cell empty Grid]
	} else {
		set x [$cell slot core]

		if {$iAxis} {
			set unhcell [$self copy $cell $start 0 $n 0]
			$x delete $start 0 $n 0
		} else {
			set unhcell [$self copy $cell 0 $start 0 $n]
			$x delete 0 $start 0 $n
		} 
	}

	set hx [$hcell slot core]

	set clist [DefMap construct *]
	set tlist [Object construct *]

	if {$iAxis} {
		set walk [$hx walk [list $start 0 $n 0]]
	} else {
		set walk [$hx walk [list 0 $start 0 $n]]
	} 

	foreach {wi wj} $walk {
		set wc [$hx getCell $wi $wj]
		if {$wc ne ""} {
			if {$iAxis} {
				$x setCell [$self _clone $wc $clist $tlist] $wi 0
			} else {
				$x setCell [$self _clone $wc $clist $tlist] 0 $wj
			}
		}
	}

	$x framesChanged

	$self _copyFreeCells $hcell $clist $tlist

	foreach t [$tlist slots] {
		$self bind [$clist get [$t cell A]] [$clist get [$t cell B]] [$clist get [$t cell Y]]
	}

	$clist destruct
	$tlist destruct

	return $unhcell
}

# Add an observer of the x events from the captive wave
#
Space method addXObserver {o handler} {
	set w [$self slot wave]

	$w addObserver xevent $o $handler
}

# Do an undo
#
Space method undo {} {
	[$self slot wave] stepBack
}

# Do a redo
#
Space method redo {} {
	[$self slot wave] step
}

## Handle the global cut/paste clipboard

# Set something as the clipboard contents
#
Space method setClipboard {c} {
	$self slot clipboard $c
	$self notifyObservers clipboard
	return $c
}

# Get the clipboard, if there
#
Space method getClipboard {} {
	return [$self slot clipboard]
}

## Import/Export

# Import from a .3rd file, destroying the contents of the cell
#
#DEFERRED we could make this undoable
#
Space method import {cell fn} {
	if {![Object existsAs $cell Cell]} {
		UserMsg error "|$self import $cell $fn|$cell is not a Cell"
		return
	}

	if {![file readable $fn]} {
		UserMsg error "|$self import $cell $fn|Unable to open $fn for reading"
		return
	}

	theSpace slot limbo ""


	if {![Exportable importFile $fn]} return

	set nc [theSpace slot limbo]
	if {$nc eq ""} {
		UserMsg warning "|$self import $cell $fn|Import failed, cell not modified"
		return
	}

	set ans [UserMsg okcancel "|$self import $cell $fn|Remove contents of \"[$cell path]\"? (Can't be undone)"]
	if {$ans ne "ok"} return

	Thyrd busy
	[theSpace pasteFrame $nc $cell i 0] destruct
	[theSpace pasteFrame $nc $cell j 1] destruct
	[theSpace paste $nc $cell] destruct
	Thyrd unbusy

	$nc destruct
	# pick up any free cells in limbo and destroy them
	foreach c [Cell children limbo@*] {$c destruct}

	theSpace slot limbo ""
}

# Export to a .3rd file
# 
# We start by copying the cell hierarchy to a new cell 
# with the prefix "limbo@" on each cell name. We then
# output the cells and commands to make the triads, and destroy
# all the copied cells.
#
Space method export {cell fn} {
	if {![Object existsAs $cell Cell]} {
		UserMsg error "|$self export $cell $fn|$cell is not a Cell"
		return
	}

	if {[catch {open $fn w} out]} {
		UserMsg error "|$self export $cell $fn|Unable to open $fn for writing"
		return
	}

	Thyrd busy

	# The first line is a comment, but it's also the magic
	# cookie identifying this file type
	#
	puts $out "#Thyrd export of \"[$cell path]\""

	# So we know the name of the top of the hierarchy when we
	# import
	#
	set nc [Cell new "" Grid limbo@]
	puts $out "theSpace slot limbo $nc"

	set clist [DefMap construct *]
	set tlist [Object construct *]

	$self _copyCells $cell $nc $clist $tlist limbo@ all
	$self _copyFreeCells $cell $clist $tlist limbo@

 	# Write out all of the limbo objects, which is the clist plus the limbo root
	# This is how we used to do it:
	#
	#	foreach o [lsort -unique [lsearch -all -inline -glob [Object descendants] "limbo@*"]] {
	#		puts $out [$o export]
	#	}
	#
	# Obviously, if there are a lot of objects, this is a bad idea.
	#
	puts $out [$nc export]
	puts $out [[$nc slot core] export]

	foreach oo [$clist slots] {
		set o [$clist slot $oo]
		puts $out [$o export]
		puts $out [[$o slot core] export]
	}

	puts $out "#Triads:"

	# Now deal with the triads. The only references to
	# cells not in clist should be to situated cells outside
	# our hierarchy and are retained as such (by outputing their
	# path).
	#
	foreach t [$tlist slots] {
		lassign [$t cells] a b y
		foreach x {a b y} {
			set c [set $x]
			if {[$clist hasSlot $c]} {
				set $x [$clist get $c]
			} else {
				set $x [$c path]
			}
		}

		puts $out "theSpace bind \"[Object quote $a]\" \"[Object quote $b]\" \"[Object quote $y]\""
	}

	close $out

	$nc destruct
	$clist destruct
	$tlist destruct

	Thyrd unbusy
}

### Testing ###

# Build test space 1
#
Space method buildTest1 {} {
	set r [$self slot root]
	assert {[Object exists $r]}

	$self set "/home/tests/table1/alpha english" "one"
	$self set "/home/tests/table1/beta english" "two"
	$self set "/home/tests/table1/gamma english" "three"
	$self set "/home/tests/table1/alpha spanish" "uno"
	$self set "/home/tests/table1/beta spanish" "dos"
	$self set "/home/tests/table1/gamma spanish" "tres"
	$self set "/home/tests/table1/alpha french" "un"
	$self set "/home/tests/table1/beta french" "deux"
	$self set "/home/tests/table1/gamma french" "trois"

	set tri [$self bind "/home/tests/table1" [Cell new "Table"] "/thyrd/ys/panel"]

	$self set "/home/tests/table2/a" "a1"
	$self set "/home/tests/table2/a 2" "a2"
	$self set "/home/tests/table2/b" "b1"
	$self set "/home/tests/table2/b 2" "b2"
	$self set "/home/tests/table2/c" "c1"
	$self set "/home/tests/table2/c 2" "c2"

	$self bind "/home/tests/table2/a" "/home/tests/table1/alpha english" "/thyrd/ys/same"
	$self bind "/home/tests/table2/b" "/home/tests/table1/beta spanish" "/thyrd/ys/same"
	$self bind "/home/tests/table2/c" "/home/tests/table1/gamma french" "/thyrd/ys/same"

	$self set "/home/tests/table3/1 1" "Hello world!" <string>
	$self set "/home/tests/table3/2 1" 10 "<integer> 0 20 2"
	$self set "/home/tests/table3/3 1" 10.0 "<real> 0 20"
	$self set "/home/tests/table3/4 1" 1 <boolean>
	$self set "/home/tests/table3/1 2" 10 <pixels>
	$self set "/home/tests/table3/2 2" alpha "<choice> alpha beta gamma delta epsilon"
	$self set "/home/tests/table3/3 2" #ff00ff <color>
	$self set "/home/tests/table3/4 2" fixed <font>
	$self set "/home/tests/table3/1 3" "fold" Opcode
	$self set "/home/tests/table3/2 3" ::testvar <variable>
	$self set "/home/tests/table3/3 3" "/home/tests/table2/a" Path
	$self set "/home/tests/table3/4 3" $tri TriadCore
	$self set "/home/tests/table3/1 4" {set ::testvar 42
puts $::testvar
} <script>

	$self bind "/thyrd 0" [Cell new 100] "/thyrd/ys/width"
	$self bind "/thyrd 0" [Cell new 20] "/thyrd/ys/height"

	$self set "/home/tests/flatland/x triangle" 80 "<real> 0 1000 .5"
	$self set "/home/tests/flatland/y triangle" 60 "<real> 0 1000 .5"
	$self set "/home/tests/flatland/sides triangle" 3 "<integer> 3 50 1"
	$self set "/home/tests/flatland/radius triangle" 50 "<real> 1 200 .5"
	$self set "/home/tests/flatland/rotation triangle" 0 "<real> 0 360 .5"
	$self set "/home/tests/flatland/color triangle" "#ff0000" <color>
	$self set "/home/tests/flatland/alpha triangle" "50" "<integer> 0 100 1"
	$self set "/home/tests/flatland/priority triangle" "50" "<integer> 0 100 1"

	$self set "/home/tests/flatland/x square" 225 "<real> 0 1000 .5"
	$self set "/home/tests/flatland/y square" 60 "<real> 0 1000 .5"
	$self set "/home/tests/flatland/sides square" 4 "<integer> 3 50 1"
	$self set "/home/tests/flatland/radius square" 50 "<real> 1 200 .5"
	$self set "/home/tests/flatland/rotation square" 0 "<real> 0 360 .5"
	$self set "/home/tests/flatland/color square" "#00ff00" <color>
	$self set "/home/tests/flatland/alpha square" "70" "<integer> 0 100 1"
	$self set "/home/tests/flatland/priority square" "55" "<integer> 0 100 1"

	$self set "/home/tests/flatland/x hexagon" 80 "<real> 0 1000 .5"
	$self set "/home/tests/flatland/y hexagon" 180 "<real> 0 1000 .5"
	$self set "/home/tests/flatland/sides hexagon" 6 "<integer> 3 50 1"
	$self set "/home/tests/flatland/radius hexagon" 45 "<real> 1 200 .5"
	$self set "/home/tests/flatland/rotation hexagon" 0 "<real> 0 360 .5"
	$self set "/home/tests/flatland/color hexagon" "#0000ff" <color>
	$self set "/home/tests/flatland/alpha hexagon" "30" "<integer> 0 100 1"
	$self set "/home/tests/flatland/priority hexagon" "30" "<integer> 0 100 1"

	$self set "/home/tests/flatland/x circle" 225 "<real> 0 1000 .5"
	$self set "/home/tests/flatland/y circle" 180 "<real> 0 1000 .5"
	$self set "/home/tests/flatland/sides circle" 32 "<integer> 3 50 1"
	$self set "/home/tests/flatland/radius circle" 50 "<real> 1 200 .5"
	$self set "/home/tests/flatland/rotation circle" 0 "<real> 0 360 .5"
	$self set "/home/tests/flatland/color circle" "#ff00ff" <color>
	$self set "/home/tests/flatland/alpha circle" "40" "<integer> 0 100 1"
	$self set "/home/tests/flatland/priority circle" "150" "<integer> 0 100 1"

	$self setAttr /home/tests/flatland panel Flatland
}

# Test programs 1
#
Space method buildTestP1 {} {
	$self set "/home/tests/prog1/cells/result" "" <integer>
	$self set "/home/tests/prog1/code/1" "6" <integer>
	$self set "/home/tests/prog1/code/2" "7" <integer>
	$self set "/home/tests/prog1/code/3" "*" Opcode

	#$self bindFormula "/home/tests/prog1/cells/result" "/home/tests/prog1/code" 
	$self bind "/home/tests/prog1/cells/result" "/home/tests/prog1/code" "/thyrd/ys/formula"

	$self set "/home/tests/prog1a/trigger" "0" <integer>
	$self set "/home/tests/prog1a/code/1" {puts stderr "Triggered at [clock format [clock seconds] -format {%Y%m%d-%H%M%S}]"} <script>
	$self set "/home/tests/prog1a/code/2" "tcl" Opcode
	$self set "/home/tests/prog1a/code/3" "drop" Opcode
	$self set "/home/tests/prog1a/code/4" 0 <integer>
	$self bind "/home/tests/prog1a/trigger" "/home/tests/prog1a/code" "/thyrd/ys/event"
	$self setAttr "/home/tests/prog1a/trigger" panel "Animation -anim pushbtn"
}
*/
