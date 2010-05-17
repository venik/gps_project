% main script for sattelite signal processing
clc, clear all ;
nDumpSize = 16368*4 ; 
x = readdump('./data/flush',nDumpSize) ;
%pwelch(x(1:16368),[],[],[],16.368e6) ;
FR = 4092-5:0.5:4092+5 ; % frequency range
t_offs = 10000 ; % /* time offset */
N = 16368 ;   % /* correlation length */
max_sat = zeros(32,1) ;
sat_shift_ca = zeros(32,1) ;
max_sat_freq = zeros(32,1) ;
for PRN=1:32
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
    fprintf('#PRN: %2d, CR: %12.5f, FREQ.:%6f, SHIFT_CA:%4d\n',PRN,max_sat(PRN),max_sat_freq(PRN),sat_shift_ca(PRN)) ;
end
barh(max_sat),colormap summer, grid on, title('Correlator outputs') ;