#!/usr/bin/wish

proc tracep {msg} {
	global log
	puts $log "[clock format [clock seconds] -format {%H:%M:%S}] $msg"
}

proc create_logs {root_window note_book} {
    	set w [$note_book subwidget log_tab]

	#text .txt -width 20 -height 10 -yscrollcommand ".srl_y set" -xscrollcommand ".srl_x set"
	#scrollbar .srl_y -command ".txt yview" -orient v
	#scrollbar .srl_x -command ".txt xview" -orient h
	
    	set logs_f [frame $w.logs_f]
	set logs_win [text $logs_f.logs_win	-width 80 \
						-height 20 \
						-yscrollcommand "$logs_f.scroll_y set" \
						-xscrollcommand "$logs_f.scroll_x set" ]


	#FIXME xscroll dontwork ???
	scrollbar $logs_f.scroll_y -command "$logs_f.logs_win yview" -orient v
	scrollbar $logs_f.scroll_x -command "$logs_f.logs_win xview" -orient h


	place $logs_f -rely 0. -relx .0 -relheight 1 -relwidth 1 
	place $logs_win -rely 0. -relx .0 -relheight 1 -relwidth 1 

	pack $logs_f.scroll_y -side right -fill y
	pack $logs_f.scroll_x -side bottom -fill x

	#tracep "create logs"
}

proc show_logs {root_window note_book} {
	global log

    	set w [$note_book subwidget log_tab]
    	set logs_f	$w.logs_f
    	set logs_win	$logs_f.logs_win

	#tracep "raise logs"
	flush $log
	
	$logs_win configure -state normal

	set fl [open log]
	$logs_win delete 1.0 end
	set buffer [read $fl]
	#puts $buffer
	$logs_win insert insert $buffer\n
	close $fl

	$logs_win configure -state disable

	#puts "=============================================================="
}
