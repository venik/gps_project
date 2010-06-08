function pll_gui(varargin)
clc; clear all; clf;

global corr_bahr nco_ctl_plot I_chan_f Q_chan_f mixed_I mixed_Q theta_plot;

DataStruct.time_range = 30 ;
DataStruct.PRN = 0 ;
DataStruct.max_sat_freq = zeros(32,1) ;
DataStruct.sat_shift_ca = zeros(32,1) ;
DataStruct.work_data = zeros(16368 * DataStruct.time_range + 1, 1) ;

hMain = figure(1) ;
set(hMain, 'Name', 'GNSS PLL', 'Position', [100 100 970 850]) ;

set(hMain,'UserData',DataStruct) ;

%uicontrol(hMain, 'Style', 'edit',  )
figPos = get(hMain,'Position') ;
f_width = figPos(3) ;
f_height = figPos(4) ;

% need position 
ui_fs = uicontrol('Style','popupmenu','Position',[670 630 250 50],...
    'String',[' PRN 01 ';' PRN 02 ';' PRN 03 ';' PRN 04 '; ' PRN 05 ';' PRN 06 '; ...
              ' PRN 07 ';' PRN 08 ';' PRN 09 ';' PRN 10 '; ' PRN 11 ';' PRN 12 '; ...
              ' PRN 13 ';' PRN 14 ';' PRN 15 ';' PRN 16 '; ' PRN 17 ';' PRN 18 '; ...
              ' PRN 19 ';' PRN 20 ';' PRN 21 ';' PRN 22 '; ' PRN 23 ';' PRN 24 '; ...
              ' PRN 25 ';' PRN 26 ';' PRN 27 ';' PRN 28 '; ' PRN 29 ';' PRN 30 '; ...
              ' PRN 31 ';' PRN 32 '],'Tag','PRNS','Callback','prn_callback') ;

%uicontrol(hMain, 'Style','edit', 'String','', 'Position', [620 610 250 50], 'Fontsize', 10);

% frames
corr_panel = uipanel('Position',[.005 .57 .65 .43], 'Title', 'Correlation', 'Fontsize' , 14);
buttons_panel = uipanel('Position',[.655 .57 .34 .43], 'Title', 'Management console', 'Fontsize' , 14);
I_chan_panel = uipanel('Position',[.005 .02 .328 .55], 'Title', 'I channel', 'Fontsize' , 14);
Q_chan_panel = uipanel('Position',[.335 .02 .325 .55], 'Title', 'Q channel', 'Fontsize' , 14);
theta_panel  = uipanel('Position',[.662 .02 .333 .55], 'Title', 'PLL out', 'Fontsize' , 14);

% buttons
uicontrol(hMain, 'Style','pushbutton', 'Position', [670 730 250 50], 'String', 'Stage 1', 'Fontsize', 10, 'Callback', 'gui_corr');
uicontrol(hMain, 'Style','pushbutton', 'Position', [670 530 250 50], 'String', 'Stage 2', 'Fontsize', 10, 'Callback', 'gui_pll');

% axes
% Satellite correlation
corr_bahr = axes('Parent', hMain, 'Color', [1 1 1], 'Units', 'points', 'Position', [30 410 350 200], 'Fontsize', 12), ...
            grid on, ylim([1,32]) ;
%pll_bahr = axes('Parent', hMain, 'Color', [1 1 1], 'Units', 'points', 'Position', [30 345 350 20], 'Fontsize', 14);

% first line
I_chan_f = axes('Parent', hMain, 'Color', [1 1 1], 'Units', 'points', 'Position', [30 210 200 120], 'Fontsize', 12), ...
           grid on ;
Q_chan_f = axes('Parent', hMain, 'Color', [1 1 1], 'Units', 'points', 'Position', [270 210 200 120], 'Fontsize', 12),
           grid on ;
nco_ctl_plot = axes('Parent', hMain, 'Color', [1 1 1], 'Units', 'points', 'Position', [510 210 200 120], 'Fontsize', 12), ...
               grid on ;

% second line
mixed_I = axes('Parent', hMain, 'Color', [1 1 1], 'Units', 'points', 'Position', [30 40 200 120], 'Fontsize', 12), ...
          grid on ;
mixed_Q = axes('Parent', hMain, 'Color', [1 1 1], 'Units', 'points', 'Position', [270 40 200 120], 'Fontsize', 12), grid on ;
theta_plot = axes('Parent', hMain, 'Color', [1 1 1], 'Units', 'points', 'Position', [510 40 200 120], 'Fontsize', 12), grid on ;

end