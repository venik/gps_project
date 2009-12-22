function x = get_sat_signal(N,PRN,f0)
fd = 16*1023 ;
LO_sig = exp(j*2*pi*f0/fd*(0:N-1)).' ; 
ca = get_ca_code16(N/16,PRN) ;
x = real(LO_sig).*ca ;
