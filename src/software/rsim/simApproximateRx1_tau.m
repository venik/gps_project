%function simApproximateRx1(tau)
clc, clear all ;
prn1 = 3 ;
prn2 = 7 ;
delay1 = 16*1 ;
delay2 = 16*10 ;
varx1 = 1 ;
varx2 = 2 ;
fs1 = 1023*2 ;
tau_range = 0:1:20 ;
fd = 16368 ;

rx1 = zeros(size(tau_range)) ;

n = 1 ;
cosin = sqrt(2)*cos(2*pi*fs1/fd*(0:17600)) ; cosin = cosin(:) ;
code1 = get_ca_code16(1100,prn1) ;
code2 = get_ca_code16(1100,prn2) ;
x = cosin(1+delay1:16400+delay1).*code1(1+delay1:16400+delay1).*code2(1+delay2:16400+delay2) ;
    
for tau = tau_range
  
    rx1(n) = x(1:16368)'*x(1+tau:16368+tau)/16368 ;

    n = n + 1 ;
    
end

decay_curve = exp(-tau_range.^2/100) ;

figure(1) ;
hold off ;
plot(tau_range,rx1,'b-+','LineWidth',2) ;
hold on ;
plot(tau_range,decay_curve,'m-+','LineWidth',2,'Color',[.7 0 0]) ;
plot(tau_range,-decay_curve,'m-+','LineWidth',2,'Color',[.7 0 0]) ;
grid on ;

figure(2) ;
r2048 = zeros(2048,1) ;
r2048(1:length(tau_range)) = rx1 ;
psd = fft(r2048) ;
plot((0:1023)/1024*16368/2,abs(psd(1:1024)),'LineWidth',2) ;
grid on ;
xlabel('Frequency') ;
title('PSD')
