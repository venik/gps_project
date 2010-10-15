% /* acx = gpsacq(x,N,PRN,f0)                                       */
% /* parallel search algorithm implementation                       */
% /* x - input signal                                               */
% /* N - correlation length (default: 16368 - 1ms)                  */
% /* PRN  - sattelite code                                          */
% /* f0 - arraya of carriers, Hz (default: 4.093e6-5e3:1e3:4.093e6) */
% /* IsRealInput - flag, if true input signal is I only             */

% /* Status:  developing */

function res = gpsacq3(x,N,PRN,FR, IsRealInput)
x = x(1:N) ;
fd = 16.368e6 ;         % /* sampling frequency in Hz */
%x = x-mean(x) ;

res = zeros(length(FR), 2);

X = fft(x) ;
% /* get ca code */
ca16_based = get_ca_code16(N/16,PRN) ;

for k=1:length(FR)
    LO_sig = exp(j*2*pi*FR(k)/fd*(0:N-1)).' ; 
    
    if IsRealInput
        ca16 = ca16_based .* LO_sig ;
    else
        ca16 = ca16_based .* real(LO_sig) ;
    end

    CA16 = fft(ca16) ;
    c_CA16 = conj(CA16) ;
    CX = X.*c_CA16 ;
    cx = ifft(CX) ;
    acx = cx.*conj(cx) ;
    
    % [ acx, shift_ca ]
    [res(k,1),res(k, 2)] = max(acx) ;

end