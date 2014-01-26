# A Core representing a type of a core
#
# PJM	2006-05-01	Created
# PJM	2007-11-26	Renamed from Type, which conflicts with Poet's Type
#
# This needs to be preloaded (all Core children do):
::Poet::Preload Thyrd

Core construct CoreType
catch {CoreType unparent Thing}	;# this object is not persistent, its kids are

##
## Core API
##
