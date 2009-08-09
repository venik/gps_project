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
    	set w [$note_book subwidget settings]
    	set rbt [frame $w.rbt -borderwidth 1 -relief sunken]
    	set res [frame $w.res -borderwidth 1 -relief sunken]

	label 	$rbt.rs232_l -text "Port name: " -padx 2
	entry 	$rbt.rs232_e -width 40 -textvar rs232_name -border 1
	button 	$rbt.rs232_b -text "Connect" -command exit

	# results
	label $res.port -text "Unconnected" -padx 1

    	pack $res -side right -fill both 
    	pack $rbt -side top -fill both

	#$rbt.close configure -state disabled

	#pack $rbt.rs232_l $rbt.rs232_e -side top -padx 5 -pady 5 -fill x
	pack $rbt.rs232_l -side left -padx 2 -pady 2
	pack $rbt.rs232_e -side left -padx 2 -pady 2 -fill x
	pack $rbt.rs232_b -side right -padx 2 -pady 2

	pack $res.port -padx 2 -pady 8 

}


wm withdraw .
set w .app
toplevel $w;
wm transient $w ""
wm title $w "Tix Example"
wm geometry $w 640x480

bind $w <Destroy> {
#  puts "NE Zhopa %W"

  if {"%W" == "$w"} {
#    puts "Zhopa %W"

    exit
  }
}

create_nb $w
