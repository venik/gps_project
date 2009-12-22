% /* acx = gpssearch(x,N,PRN,f0, IsRealInput) */
% /* serial search algorithm implementation (slow)*/
% /* x - input signal */
% /* N - correlation length (default: 16368 - 1ms) */
% /* ca_phase - phase of ca code 1..N */
% /* PRN  - sattelite code */
% /* f0 - carrier, KHz (default: 4092 KHz) */
% /* IsRealInput - flag, if true input signal is I only */
% /* Status: almost tested */

function acx = gpssearch(x,N,ca_phase,PRN,f0, IsRealInput)
fd = 16368 ; % /* sampling frequency */
x = x(1:N) ;
ca16 = get_ca_code16((N/16)*2,PRN) ;
%ca16_c = corrx(ca16,ca16,16368) ;
nca_phase = N - ca_phase + 2 ;
x = x.*ca16(nca_phase:nca_phase+N-1) ;
LO_sig = exp(j*2*pi*f0/fd*(0:N-1)) ; 
acx = 0 ;
if IsRealInput
    acx = LO_sig*x ;    
else
    acx = real(LO_sig)*x ;
end
acx = acx*conj(acx) ;
