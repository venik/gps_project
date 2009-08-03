#!/usr/bin/wish

##=========================================================
##
## Description: GUI interface for the GPS-board
##
## Requariments: tcl and iwidgets packedges
##
##
## Developer: Alex Nikiforov nikiforov.al [at] gmail.com
##
##=========================================================

package require Iwidgets

wm title . "GPS-Board management program"

##=========================================================
##	Create a tabnotebook iwidget
##=========================================================
##
iwidgets::tabnotebook .tn \
	-tabpos n \
	-width 450 \
	-height 250 \
	-angle 0 \
	-background #336699 \
	-tabbackground white \
	-foreground white \
	-bevelamount 4 \
	-gap 3 \
	-margin 6 \
	-tabborders 0 \
	-backdrop #666666


##
##	Add some tabs
##
set tb(test) [.tn add -label "Test"]
frame $tb(test).f -bd 2
label $tb(test).f.l -foreground white -font {Helvetica 16 bold}
pack $tb(test).f.l $tb(test).f -expand 1 -fill both

set tb(work) [.tn add -label "Work"]
##=========================================================
##	Create a pushbutton iwidget
##=========================================================
##
iwidgets::pushbutton $tb(test).f.l.pb -text "Test the GPS-board..." -command test_button -defaultring 1 

pack $tb(test).f.l.pb -padx 12 -pady 12
## pack all
pack .tn

#.tn delete 1

##
##	select the second tab (zero based)
##
.tn select 0 


########################################################################
proc test_button {} {
	global tb

	$tb(test).f.l configure -text "The GPS-board is Ok =)" -foreground blue -font {Helvetica 16 bold}

	puts OUCH!!
}
