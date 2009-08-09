#!/usr/bin/wish

package require Tix

proc create_nb {w} {

    tixNoteBook $w.n -dynamicgeometry false

    #$w.n add settings -label "Settings" -underline 0
    $w.n add settings -label "Settings" -underline 0 -createcmd "init_settings $w $w.n"
    $w.n add work -label "Work" -underline 0

    #RunSample $frame1 $w

    pack $w.n -side bottom -fill both -expand 1

}

proc init_settings {root_window note_book} {
	##=========================================================
	##	Create rs232 settings string 
	##=========================================================
	#entry $tb(test).f.rs232_e -width 30 -textvar rs232_name -relief sunken 
	#button $tb(test).f.rs232_b -text "Set" -command test_button
    	set w [$note_book subwidget settings]
    	set rbt [frame $w.rbt -borderwidth 1 -relief sunken]
    	set res [frame $w.res -borderwidth 1 -relief sunken]


    	#place $rbt -x 0 -y 0

	label $rbt.rs232_l -text "Port name: "
	entry $rbt.rs232_e -width 10 -textvar rs232_name -border 1

	# results
	label $res.port -text "Unknown"

	#place $rbt.rs232_l -relx 0 -rely 0 -relheight 1 -relwidth 0.5 

    	pack $res -side right -fill both 
    	pack $rbt -side top -fill both

	#$rbt.close configure -state disabled

	#pack $rbt.rs232_l $rbt.rs232_e -side top -padx 5 -pady 5 -fill x
	pack $rbt.rs232_l $rbt.rs232_e -side top -padx 5 -pady 5 -fill x
	pack $res.port

}

#wm title . "Tix Example"

wm withdraw .
set w .app
toplevel $w;
wm transient $w ""
wm geometry $w 640x480

bind $w <Destroy> {
#  puts "NE Zhopa %W"

  if {"%W" == "$w"} {
#    puts "Zhopa %W"

    exit
  }
}

create_nb $w
