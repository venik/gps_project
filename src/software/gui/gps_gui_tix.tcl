#!/usr/bin/wish

####################################################################################3
#
# Description: GUI for rs232dumper. connect via tcp to the dumper 
#
# Developer: Alex Nikiforov nikiforov.al [at] gmail.com
#
####################################################################################3

package require Tix

source logs.tcl
source network.tcl

proc create_nb {w} {

	tixNoteBook $w.n -dynamicgeometry false

	$w.n add settings -label "Settings" -underline 0 -createcmd "init_settings $w $w.n"
	$w.n add work_tab -label "Work" -underline 0
	$w.n add log_tab -label "Log" -underline 0 -createcmd "create_logs $w $w.n" -raisecmd "show_logs $w $w.n"

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
	
	label 	$rbt.server_name_l -text "Server name: " -padx 2
	entry 	$rbt.server_name_e -width 30 -textvar server_name -border 1
	label 	$rbt.server_port_l -text "Server port: " -padx 2
	entry 	$rbt.server_port_e -width 10 -textvar server_port -border 1

	button 	$rbt.rs232_connect_b -text "Connect" -command "connection_cmd $rbt $res"
	button 	$rbt.rs232_exit_b -text "Exit" -command gui_exit

	# headers 
	label 	$rbt.set_l -text "Settings: " -padx 2 -font {Helvetica 14 bold}
	label 	$rbt.test_l -text "Tests: " -padx 2 -font {Helvetica 14 bold}

	# test labels
	label 	$rbt.rs232_test_l -text "RS232 test  ...................................................................................................... " -padx 2
	label 	$rbt.mem_test_l -text "Memory test  ................................................................................................... " -padx 2
	label 	$rbt.gps_test_l -text "GPS test  ......................................................................................................... " -padx 2

	# results
	label $res.port -text "UNCONNECTED" -padx 1
	label $res.server -text "UNCONNECTED" -padx 1
	label $res.rs232 -text "UNTESTED" -padx 1
	label $res.mem -text "UNTESTED" -padx 1
	label $res.gps -text "UNTESTED" -padx 1

	# ================================================
	# place
	# ================================================
	# frames
   	place $rbt -rely .0 -relx .0 -relheight 1 -relwidth .8 
   	place $res -rely .0 -relx .8 -relheight 1 -relwidth .2 
	
	# headers 
	place $rbt.set_l -relx 0.1 -rely 0
	place $rbt.test_l -relx 0.1 -rely 0.2

	# settings
	place $rbt.server_name_l -relx 0 -rely 0.08
	place $rbt.server_name_e -relx 0.18 -rely 0.08
	place $rbt.server_port_l -relx 0.65 -rely 0.08
	place $rbt.server_port_e -relx 0.82 -rely 0.08

	place $rbt.rs232_l -relx 0 -rely 0.14
	place $rbt.rs232_e -relx 0.15 -rely 0.14
	
	place $rbt.rs232_connect_b -relx 0.8 -rely 0.85
	place $rbt.rs232_exit_b -relx 0.07 -rely 0.85
	
	#tests
	place $rbt.rs232_test_l -relx 0 -rely 0.27 
	place $rbt.mem_test_l -relx 0 -rely 0.32 
	place $rbt.gps_test_l -relx 0 -rely 0.37

	# results
	place $res.server -relx 0.5 -x -50 -rely 0.08
	place $res.port -relx 0.5 -x -50 -rely 0.14
	place $res.rs232 -relx 0.5 -x -37 -rely 0.27
	place $res.mem -relx 0.5 -x -37 -rely 0.32
	place $res.gps -relx 0.5 -x -37 -rely 0.37

	#$rbt.close configure -state disabled
}

proc gui_exit {} {
	global log

	# FIXME - do it more gentle
	close $log

	exit
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

# create log-file
set new_name "/tmp/gps_board_gui.log"
set old_name "/tmp/gps_board_gui.log_old"

if { [file exists "$old_name"] == 1 } {
	file delete "$old_name"
}

if { [file exists "$new_name"] == 1 } {
	file rename "$new_name" "$old_name"
}

set log [open "$new_name" w+];

# Rock&Roll
create_nb $w



