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
	-width 640 \
	-height 480 \
	-angle 0 \
	-bevelamount 4 \
	-gap 3 \
	-margin 6 \
	-tabborders 0
#	-tabbackground white \
#	-backdrop #666666 \
#	-foreground white \
#	-background #336699 

##
##	Add some tabs
##
set tb(test) [.tn add -label "Settings"]
frame $tb(test).f -bd 2
#label $tb(test).f.l -foreground white -font {Helvetica 16 bold} -text "helloo"
#pack $tb(test).f.l $tb(test).f -expand 1 -fill both

set tb(work) [.tn add -label "Work"]


##=========================================================
##	Create rs232 settings string 
##=========================================================
##
label $tb(test).f.rs232_l -text "Port name: "
entry $tb(test).f.rs232_e -width 30 -textvar rs232_name -relief sunken 
button $tb(test).f.rs232_b -text "Set" -command test_button

##=========================================================
##	Create a pushbutton iwidget
##=========================================================
##
iwidgets::pushbutton $tb(test).f.pb -text "Test the GPS-board..." -command test_button -defaultring 1 


#place $tb(test).f -x 0 -y 0
#pack $tb(test).f.pb
#pack $tb(test).f.rs232_name
#place $tb(test).f.rs232_l -relx 0.5 -rely 0.5
#place $tb(test).f.rs232_e -relx 0.3 -rely 0.6
#place $tb(test).f.rs232_b -x 120 -y 120 
pack $tb(test).f.rs232_l -side left
pack $tb(test).f.rs232_e -side left
pack $tb(test).f.rs232_b


pack $tb(test).f 
pack .tn
##
##	select the second tab (zero based)
##
.tn select 0 

########################################################################
proc test_button {} {
	global tb

	#$tb(test).f.l configure -text "The GPS-board is Ok =)" -foreground blue -font {Helvetica 16 bold}

	puts OUCH!!
}
