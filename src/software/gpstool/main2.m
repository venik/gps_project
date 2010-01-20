% main script for sattelite signal processing
clc, clear all ;
nDumpSize = 16368*4 ; 
x = readdump('./data/flush.txt',nDumpSize) ;
%pwelch(x(1:16368),[],[],[],16.368e6) ;
FR = 4092-5:0.5:4092+5 ; % frequency range
t_offs = 10000 ; % /* time offset */
N = 16368 ;   % /* correlation length */
for PRN=23
    for f0 = FR
        acx = gpsacq(x(t_offs:end),N,PRN,f0, 0) ;
        plot(acx), grid on, title(sprintf('PRN=%d, F_0=%f',PRN,f0)) ;
        pause ;
    end
end
