% check equivalence between our and tsui acqusition
clc, clear all ;
nDumpSize = 16368*4 ; 
x = readdump('./data/flush.txt',nDumpSize) ;
%pwelch(x(1:16368),[],[],[],16.368e6) ;
FR = 4092-5:0.5:4092+5 ; % frequency range
t_offs = 10000 ; % /* time offset */
N = 16368 ;   % /* correlation length */
max_sat = zeros(32,1) ;
for PRN=1:32
    for f0 = FR
        acx = gpsacq(x(t_offs:end),N,PRN,f0, 0) ;
        acx2 = gpsacq2(x(t_offs:end),N,PRN,f0, 0) ;
        tsui_acx = tsui_acq(x(t_offs:end),N,PRN,f0*1e3, 0) ;
        fprintf('#PRN: %2d, err: %12.5f\n',PRN,sum((acx-acx2).*conj(acx-acx2))) ;
        fprintf('#PRN: %2d, err: %12.5f\n',PRN,sum((acx2-tsui_acx).*conj(acx2-tsui_acx))) ;
    end
end
