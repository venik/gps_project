function pll_gui(varargin)
clc; clear all; clf;

global corr_bahr nco_ctl_plot I_chan_f Q_chan_f mixed_I mixed_Q theta_plot;

DataStruct.time_range = 30 ;
DataStruct.max_sat_freq = zeros(32,1) ;
DataStruct.sat_shift_ca = zeros(32,1) ;
DataStruct.work_data = zeros(16368 * DataStruct.time_range + 1, 1) ;

hMain = figure(1) ;
set(hMain, 'Name', 'GNSS PLL', 'Position', [100 150 990 800]) ;

set(hMain,'UserData',DataStruct) ;

%uicontrol(hMain, 'Style', 'edit',  )

% need position 
uicontrol(hMain, 'Style','edit', 'String','', 'Position', [620 610 250 50], 'Fontsize', 10);

% buttons
uicontrol(hMain, 'Style','pushbutton', 'Position', [620 710 250 50], 'String', 'Stage 1', 'Fontsize', 10, 'Callback', 'gui_corr');
uicontrol(hMain, 'Style','pushbutton', 'Position', [620 510 250 50], 'String', 'Stage 2', 'Fontsize', 10, 'Callback', 'gui_pll');

% axes
% Satellite correlation
corr_bahr = axes('Parent', hMain, 'Color', [1 1 1], 'Units', 'points', 'Position', [30 380 350 200], 'Fontsize', 6);
pll_bahr = axes('Parent', hMain, 'Color', [1 1 1], 'Units', 'points', 'Position', [30 345 350 20], 'Fontsize', 6);

% first line
I_chan_f = axes('Parent', hMain, 'Color', [1 1 1], 'Units', 'points', 'Position', [30 200 200 120], 'Fontsize', 6);
Q_chan_f = axes('Parent', hMain, 'Color', [1 1 1], 'Units', 'points', 'Position', [270 200 200 120], 'Fontsize', 6);
nco_ctl_plot = axes('Parent', hMain, 'Color', [1 1 1], 'Units', 'points', 'Position', [510 200 200 120], 'Fontsize', 6);

% second line
mixed_I = axes('Parent', hMain, 'Color', [1 1 1], 'Units', 'points', 'Position', [30 40 200 120], 'Fontsize', 6);
mixed_Q = axes('Parent', hMain, 'Color', [1 1 1], 'Units', 'points', 'Position', [270 40 200 120], 'Fontsize', 6);
theta_plot = axes('Parent', hMain, 'Color', [1 1 1], 'Units', 'points', 'Position', [510 40 200 120], 'Fontsize', 6);

end