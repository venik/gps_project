% test tool. try to find initial point for satellite and track it
% through data. main goal - check our parralel algorithm

clc, clear all ;
nDumpSize = 16368*30 ;          % FIXME - we can more up to 32ms

%load('./data/x.mat') ;
%pwelch(x(1:16368),[],[],[],16.368e6) ;

FR = 4092000-5e3:1e3:4092e3+5e3 ; % /* frequency range Hz  */
t_offs = 100 ;                    % /* FIXME - time offset */
N = 16368 ;                       % /* correlation length  */
fs = 16368e3 ;                    % /* sampling freq kHz   */
ts = 1/fs ;

max_sat = zeros(32,1) ;
%max_fine_sat = zeros(32,1) ;
%max_fine_sat_new = zeros(32,1) ;

sat_shift_ca = zeros(32,1) ;
%max_sat_freq = zeros(32,1) ;

%freq_vals = zeros(32,3) ;


%corr_vals_par = zeros(32,5) ;

%PRN_range = 1:32 ;
PRN_range = 16 ;
%PRN_range = 21 ;
%PRN_range = [21,22,23] ;

% ========= generate =======================
if 0
   x_ca16 = get_ca_code16(N/16,PRN_range(1)) ;
   x_ca16 = [x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;
       x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;
       x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;
       x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;
       x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16] ;
   x = exp(2*j*pi*4092000/16368000*(0:length(x_ca16)-1)).' ;

delta = 150 ;
x = cos(2*pi*(4092000 + delta)/16368000*(0:length(x_ca16)-1)).' ;
x(length(x)/2+1000:end)=x(length(x)/2+1000:end) * (-1) ;
x = x .* x_ca16 ;
x=x+randn(size(x))*1 ;

else
    x = readdump('./data/flush',nDumpSize) ;   
end
% ========= generate =======================

for PRN=PRN_range
    for f0 = FR
        acx = gpsacq2(x(t_offs:end),N,PRN,f0, 0) ;
        [max_f,shift_ca] = max(acx) ;
        if max_f>=max_sat(PRN)
            max_sat(PRN) = max_f ;
            sat_shift_ca(PRN) = shift_ca ;
            max_sat_freq(PRN) = f0 ;
        end
        %plot(acx), grid on, title(sprintf('PRN=%d, F_0=%f',PRN,f0)) ;
        %pause ;
    end
    fprintf('#PRN: %2d CR: %15.5f, FREQ.:%5.1f, SHIFT_CA:%4d\n',PRN,max_sat(PRN),max_sat_freq(PRN),sat_shift_ca(PRN)) ;
    
end

% and we know initial point of the signal (shift_ca) try to move window and
% check initial CA point

corr_par_vals = zeros(32,32) ;
shift_ca_par_vals = zeros(32,32) ;

for PRN=PRN_range
    % move to initail point
    x_win = x(t_offs + sat_shift_ca(PRN):end) ;
    
    % move window
    for k = 1:29
        acx = gpsacq2(x_win(1 + (k-1)*N:N*k),N,PRN,max_sat_freq(PRN), 0) ;
        [max_f,shift_ca] = max(acx) ;
        cor_par_vals(PRN, k) = max_f ;
        shift_ca_par_vals(PRN, k) = shift_ca ;
        %fprintf('\t CR: %15.5f, SHIFT_CA:%4d\n', max_f, shift_ca) ;
    end
    fprintf(' \t: done\n');
end
    
%figure(1), subplot(3, 1, 1), barh(max_fine_sat_new), xlim([1,13e7]), ylim([1,32]), colormap summer, grid on, title('Correlator outputs after fine freq estimation') ;
figure(1), barh(max_sat), xlim([1,13e7]), ylim([1,32]), colormap summer, grid on, title('Correlator outputs after fine freq estimation') ;
figure(2), subplot(2,1,1), plot(cor_par_vals(PRN, 1:k)), title('Corr vals'), subplot(2,1,2), plot(shift_ca_par_vals(PRN, 1:k)), title('shift CA');

