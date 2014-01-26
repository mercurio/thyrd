### RestServer - Tool for monitoring the REST http server
#
# PJM 	2009-10-02	Begun

Window construct RestServer
RestServer mixin ParamListOwner

# Default values for the params specific to a RestServer
RestServer slot _defaultParams {	
	-port {33333 <integer 1025 49151>}
	-on {0 <boolean>}
}

# Options that must be specified at creation time
RestServer slot extraOptions {paramList}

# The list cell that contains our parameters
#
RestServer slot paramList {}
RestServer type paramList Cell

# Server is on
RestServer slot isOn	0
RestServer type isOn	<boolean>

# Packages have been loaded
RestServer slot inited	0
RestServer type inited	<boolean>

# Called to set up watching of the cells in the paramList
#
RestServer method watchParams {pl} {
	$pl watchSub! $self newState port
	$pl watchSub! $self newState on
}

# Observer handler
# The state has changed.
#
RestServer method newState {target event} {
}

# Build the primary for a RestServer
# We pick up _mainframe from MainFrameTool
#
RestServer method buildPrimary {} {
	$self destroyPrimary

    $self slot menu [list "&Server" all object 1]
    $self slotAppend menu [format {
            {command "&Start" {} "Start server" {} -command "%s start"}
            {command "S&top" {} "Stop server" {} -command "%s stop"}
            {command "&Close" {} "Close this window" {} -command "%s destruct"}
        } $self $self $self]

	set prim [$self as MainFrameTool buildPrimary]
	set mf [$self getFrame]
	set pl [$self slot paramList]
	assert {$pl ne ""}

	$self wm withdraw

	set txt ${mf}.txt
	$self slot log $txt

	::ttk::scrollbar ${mf}.sx -orient horizontal -command "$txt xview"
	::ttk::scrollbar ${mf}.sy -orient vertical -command "$txt yview"

	text $txt -xscrollcommand "${mf}.sx set" -yscrollcommand "${mf}.sy set"

	grid columnconfigure $mf 1 -weight 1
	grid    rowconfigure $mf 1 -weight 1

	grid $txt -row 1 -column 1 -sticky nsew
	grid ${mf}.sx -row 2 -column 1 -sticky nsew
	grid ${mf}.sy -row 1 -column 2 -sticky nsew

	$txt tag configure normal -foreground black
	$txt tag configure error -foreground red
	$txt tag configure status -foreground blue
	$txt tag configure data -foreground darkgreen

	$self addResizer
	$self wm title "REST Server"

	$self wm deiconify

	return $prim
}

# Log a message to the text window
#
RestServer method log {msg {tag normal}} {
	set log [$self slot log]

	$log insert end "$msg\n" $tag
	$log see end
}

# Initialize httpd by loading the packages
# (not loaded unless needed). We also define
# the procs
#
RestServer method init {} {
	if {[$self slot inited]} return

	$self log "Loading httpd packages" status

	if {[catch {
		package require html
		package require md5
		package require ncgi
		package require httpd
		package require httpd::version
		package require httpd::threadmgr
		package require httpd::counter
		package require httpd::utils
		package require httpd::url
		#package require httpd::doc_error
	} err]} {
		$self log "Error when loading packages: $err"
		return
	}

	# Log proc needed by httpd
	proc Log {sock reason args} [format {
		%s log "($sock): $reason {*}$args" normal
	} $self]
		
	# We don't use the httpd:doc package, these are
	# substitutes
	proc Doc_Error {sock err} [format {
		%s docError $sock $err
	} $self]

	proc Doc_NotFound {sock} [format {
		%s docNotFound $sock
	} $self]


	$self slot inited 1
}

# Start the server
#
# We also init here, so the packages are only loaded
# if the RestServer window is started.
#
# We attach the ``domain`` method to the prefix ``/3rd``,
# since tclhttpd won't let us attach to ``/``. No other
# prefixes are served by this server.
#
RestServer method start {} {
	$self init
	$self log "Starting server on port [$self getParam port]" status

	$self log [Httpd_Init] normal
	$self log [Counter_Init 60] normal
	$self log [Httpd_Server [$self getParam port]] normal

	Url_PrefixInstall /3rd [list $self domain]
	$self slot prefix /3rd
}

# Stop the server
#
RestServer method stop {} {
	$self log [Httpd_Shutdown] normal
	$self log "Server stopped" status
}

# Destroy a RestServer, destroying any component objects
#
RestServer method destruct {} {
	Observer unobserveAll $self 
	$self stop

	$self as [RestServer parent] destruct
}

# Refresh a RestServer
# DEFERRED maybe clear the text widget and stop/start the server?
#
RestServer method refresh {} {
}

# Not Found handler
#
RestServer method docNotFound {sock} {
	$self log "($sock) Not Found" error
}

# Error handler
#
RestServer method docError {sock err} {
	$self log "($sock) Error: $err" error
}

# Domain handler for all incoming requests
#
# A method called ``handle:code`` is invoked
# where the response code is determined by looking
# at the accept header, except that it can be
# overridden via the ``reply`` field in the query string.
#
RestServer method domain {sock suffix} {
	upvar #0 Httpd$sock data

	$self log "$sock $suffix"
	$self log [parray data] data

	# Parse the URL. We extract the query string ourselves
	# (rather than use $data(query)) to allow embedded ?s
	#
	if {![regexp [$self slot prefix](.*) $data(uri) -> tail]} {
		Httpd_Error $sock 400 "Expected prefix [$self slot prefix] at start of uri"
		return
	}

	if {![regexp {(.*)\?([^?]*)} $tail -> path qs]} {
		set path $tail
		set qs ""
	}

	set path [$self urlToPath $path]

	set query [dict create {*}[Url_DecodeQuery $qs]]

	# If the protocol isn't POST, the cell must already
	# exist. Otherwise, we try to make it.
	#
	if {$data(proto) eq "POST"} {
		if {[catch {theSpace find $path yes} c] || $c eq ""} {
			Httpd_Error $sock 404 "Unable to create cell at $path"
			return
		}
	} else {
		if {[catch {theSpace find $path no} c] || $c eq ""} {
			Httpd_Error $sock 404 "Can't find cell at $path"
			return
		}
	}

	# Use the accept header to determine how to reply
	lassign [$self parseAcceptHeader $data(mime,accept)] mtype code

	# Allow override by reply= or callback= query params
	# If a callback is given, force json
	#	NOTE maybe not?

	if {[dict exists $query callback]} {
		dict set query reply json
	}

	if {[dict exists $query reply]} {
		switch [dict get $query reply] {
			json {
				set mtype application/json
				set code json
			}
			plain {
				set mtype text/plain
				set code plain
			}
			html {
				set mtype text/html
				set code html
			}
			default {
				# all other reply codes are ignored
			}
		}
	}

puts $code
	# Invoke the appropriate responder
	set response [$self handle:$code $c $query]

puts $response
	Httpd_ReturnData $sock $mtype $response
}

# Given a url, turn it into a path. The prefix and query string
# have already been stripped off.
#
# We convert space into %20, | into space, %20 to \space 
# and the rest of the percent codes as per normal usage. 
# So 
# ``
# 		/foo%20bar|12
# ``
# would become
# ``
#		/foo\ bar 12
#
#
RestServer method urlToPath {url} {
	switch -regexp -matchvar match $url {
		/@(.*) {
			return "@[lindex $match 1]"
		}
		@(.*) {
			return "@[lindex $match 1]"
		}
		/(.*) {
			set path "/[lindex $match 1]"
		}
		(.*) {
			set path "/[lindex $match 1]"
		}
	}

	regsub -all { } $path %20 path
	regsub -all {\|} $path " " path
	regsub -all {%20} $path {\\ } path

	# From tclhttpd's Url_Decode, but we don't treat + as space
 	regsub -all {([][$\\])} $path {\\\1} path
 	regsub -all {%([0-9a-fA-F][0-9a-fA-F])} $path  {[format %c 0x\1]} path
 	return [subst $path]
}

# Given the accept header from a request, return
# the type of response we're going to reply with.
#
RestServer method parseAcceptHeader {hdr} {
	set provide {
		text/html			html
		text/plain			plain
		application/json	json
		application/*		html
	}

	# kludge
	if {$hdr eq "*/*"} {return [list application/json json]}


	array set pref [regsub -all {([^;]*);q=([0-9\.]+),*} $hdr {\2 \1 }]

	foreach n [lsort -decreasing -real [array names pref]] {
		set mtlist [split $pref($n) ,] 

		foreach {pat code} $provide {
			set mt [lsearch -glob -inline $mtlist $pat]
			if {$mt ne ""} {return [list $mt $code]}
		}
	}

	return [list text/html html]
}

# Handle a request by returning a JSON representation
# of the cell
#
RestServer method handle:json {cell query} {
	if {[dict exists $query callback]} {
		set out "[dict get $query callback]("
	} else {
		set out ""
	}

	append out \{

	append out "\"cell\":\"${cell}\","

	append out "\"type\":\"[$cell getType]\","

	set x [$cell slot container]
	if {$x eq ""} {set x null}
	append out "\"in\":\"$x\","

	set i [$cell slot i]
	if {$i eq ""} {set i 0}
	append out "\"i\":$i,"

	set j [$cell slot j]
	if {$j eq ""} {set j 0}
	append out "\"j\":$j,"

	if {[$cell atomic]} {
		append out "\"imax\":0,\"jmax\":0,"
		append out "\"value\":[$self jsonize [$cell get]]"
	} else {
		lassign [$cell size] si sj
		append out "\"imax\":[- $si 1],"
		append out "\"jmax\":[- $sj 1],"
		append out "\"value\":\["

		foreach {wi wj} [$cell as CMGrid walk all] {
			set wc [$cell as CMGrid getCell $wi $wj]
			append out "\"$wc\","
		}
		append out "]"
	}

	if {[dict exists $query callback]} {
		append out \})
	} else {
		append out \}
	}

	return $out
}

# Clean up a string for json
#
RestServer method jsonize {data} {
	set data [string map {
				\n \\n
				\t \\t
				\r \\r
				\b \\b
				\f \\f
				\\ \\\\
				\" \\\"
				/ \\/
		} $data
	]

	return "\"$data\""
}

# Handle a request by returning an HTML representation
# of the cell. If it's atomic we just return a div
# of the value, otherwise we return a table.
# The wrap query param controls how we wrap it up,
# the default is to wrap it in a simple html page.
#
RestServer method handle:html {cell query} {
	if {[dict exists $query wrap]} {
		set wrap [dict get $query wrap]
	} else {
		set wrap page
	}

	if {[$cell atomic]} {
		set core "<div class=\"atomic\">[html::quoteFormValue [$cell get]]</div>"
	} else {
		lassign [$cell size] si sj

		set core "<table>\n"
		foreach {wi wj} [$cell as CMGrid walk all] {
			set wc [$cell as CMGrid getCell $wi $wj]

			if {$wi == 0} {append core "<tr>"}

			if {$wc eq ""} {
				append core "<td></td>"
			} elseif {[$wc atomic]} {
				append core "<td><a href=\"[$self slot prefix]/$wc\">[html::quoteFormValue [$wc get]]</a></td>"
			} else {
				append core "<td><a href=\"[$self slot prefix]/$wc\">[html::quoteFormValue $wc]</a></td>"
			}

			if {$wi == $si - 1} {append core "</tr>\n"}
		}

		append core "</table>\n"
	}

	switch $wrap {
		none	-
		naked	{return $core}
		page	-
		default	{
			return "[$self slot htmlproto]<body>$core</body></html>"
		}
	}
}

RestServer slot htmlproto {
	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

	<html>
	  <head>
		<meta http-equiv="content-type" content="text/html; charset=UTF-8">

		<!-- <link type="text/css" rel="stylesheet" href="Thyrd.css"> -->

		<title>Thyrd</title>
    
	<!--	<script type="text/javascript" language="javascript" src="thyrd/thyrd.nocache.js"></script> -->
	  </head>
}


# Handle a request by returning a plain text representation
# of the cell's value.  If it's a grid, return imax, jmax,
# and the matrix in i-major order.
#
RestServer method handle:plain {cell query} {
	if {[$cell atomic]} {
		return [$cell get]
	} else {
		lassign [$cell size] si sj
		set out "[- $si 1] [- $sj 1]\n"

		foreach {wi wj} [$cell as CMGrid walk all] {
			set wc [$cell as CMGrid getCell $wi $wj]

			if {$wc eq ""} {
				append out "\"\""
			} else {
				append out $wc
			}

			if {$wi == $si - 1} {
				append out "\n"
			} else {
				append out " "
			}
		}

		return $out
	}

}
