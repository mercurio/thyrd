# A Core representing an integer value.
#
# PJM	2006-05-01	Created
#
# This needs to be preloaded (all Core children do):
::Poet::Preload Thyrd

Core construct Integer
catch {Integer unparent Thing}	;# this object is not persistent, its kids are

##
## Core API
##
