#!/usr/bin/wish

package require Iwidgets

wm title . "Tabnotebook Example"

##=========================================================
##	Create a tabnotebook iwidget
##=========================================================
##
iwidgets::tabnotebook .tn \
	-tabpos n \
	-width 350 \
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
foreach t {one two three four} {

	set tb($t) [.tn add -label "Tab [string totitle $t]"]
	frame $tb($t).f \
		-bd 2

	label $tb($t).f.l \
		-text "This is tab $t" \
		-background #336699 \
		-foreground white \
		-font {Helvetica 16 bold}

	pack $tb($t).f.l $tb($t).f \
		-expand 1 \
		-fill both
}

pack .tn

#.tn delete 1

##
##	select the second tab (zero based)
##
.tn select 1
