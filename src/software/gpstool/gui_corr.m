function gui_corr(varargin)
global corr_bahr ;

hMain = figure(1) ;
DataStruct = get(hMain,'UserData') ;

nDumpSize = 16368 * DataStruct.time_range ;          % FIXME - we can more up to 32ms

%load('./data/x.mat') ;

FR = 4092-5:1:4092+5 ; % frequency range kHz
t_offs = 100 ;     % /* FIXME - time offset */
N = 16368 ;   % /* correlation length */
fs = 16368 ;   % /* sampling freq kHz */
ts = 1/(fs * 1000) ;

max_sat = zeros(32,1) ;
max_fine_sat = zeros(32,1) ;
max_fine_sat_new = zeros(32,1) ;

sat_shift_ca = zeros(32,1) ;
max_sat_freq = zeros(32,1) ;

PRN_range = 1:32 ;
%PRN_range = 3 ;
%PRN_range = 21 ;
%PRN_range = [21,22,23] ;

% ========= generate =======================
 x = readdump('./data/flush',nDumpSize) ;
%   x_ca16 = get_ca_code16(N/16,PRN_range(1)) ;
%   x_ca16 = [x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;
%       x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;
%       x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;
%       x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;
%       x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16] ;
%   x = exp(2*j*pi*4092000/16368000*(0:length(x_ca16)-1)).' ;
% 
% x = sin(2*pi*4092000/16368000*(0:length(x_ca16)-1)).' ;
% x = x.*x_ca16 ;
%x(length(x)/2:end)=x(length(x)/2:end) * (-1) ;
%x=x+randn(size(x))*1 ;
%x = x(150:end) ;
% ========= generate =======================

for PRN=PRN_range
    for f0 = FR
        acx = gpsacq2(x(t_offs:end),N,PRN,f0, 0) ;
        [max_f,shift_ca] = max(acx) ;
        if max_f>max_sat(PRN)
            max_sat(PRN) = max_f ;
            sat_shift_ca(PRN) = shift_ca ;
            max_sat_freq(PRN) = f0 ;
        end
        %plot(acx), grid on, title(sprintf('PRN=%d, F_0=%f',PRN,f0)) ;
        %pause ;
    end
    fprintf('#PRN: %2d, CR: %15.5f, FREQ.:%5.1f, SHIFT_CA:%4d\n',PRN,max_sat(PRN),max_sat_freq(PRN),sat_shift_ca(PRN)) ;
end

axes(corr_bahr)
barh(max_sat), ylim([1,32]), colormap summer, grid on, title('Correlator outputs') ;

DataStruct.max_sat_freq = max_sat_freq ;
DataStruct.sat_shift_ca = sat_shift_ca ;
DataStruct.work_data = x(t_offs:end) ;

set(hMain,'UserData',DataStruct) ;

end