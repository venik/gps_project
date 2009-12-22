% /* acx = gpsacq(x,N,PRN,f0) */
% /* parallel search algorithm implementation */
% /* x - input signal */
% /* N - correlation length (default: 16368 - 1ms) */
% /* PRN  - sattelite code */
% /* f0 - carrier, KHz (default: 4092 KHz) */
% /* IsRealInput - flag, if true input signal is I only */
% /* Status: almost tested */

function acx = gpsacq(x,N,PRN,f0, IsRealInput)
x = x(1:N) ;
fd = 16368 ; % /* sampling frequency */
%x = x-mean(x) ;

LO_sig = exp(j*2*pi*f0/fd*(0:N-1)).' ; 
if IsRealInput
    x = x .* LO_sig ;
else
    x = x .* real(LO_sig) ;
end
X = fft(x) ;
% /* get ca code */
ca16 = get_ca_code16(N/16,PRN) ;
CA16 = fft(ca16) ;
c_CA16 = conj(CA16) ;
CX = X.*c_CA16 ;
cx = ifft(CX) ;
acx = cx.*conj(cx) ;
