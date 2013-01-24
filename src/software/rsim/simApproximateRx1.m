%function simApproximateRx1
clc, clear all ;
prn1 = 3 ;
prn2 = 1 ;
delay1 = 5 ;
delay2 = 100 ;
varx1 = 1 ;
varx2 = 2 ;
fs1_range = 2000:100:6000 ;
fd = 16368 ;

pts1 = zeros(size(fs1_range)) ;
pts2 = zeros(size(fs1_range)) ;
pts3 = zeros(size(fs1_range)) ;

n = 1 ;
for fs1 = fs1_range
    
    cosin = cos(2*pi*fs1/fd*(0:17600)) ; cosin = cosin(:) ;
    code1 = get_ca_code16(1100,prn1) ;
    code2 = get_ca_code16(1100,prn2) ;
    
    x = cosin(1+delay1:16371+delay1).*code1(1+delay1:16371+delay1).*code2(1+delay2:16371+delay2) ;
    
    rxx = [x(1:16368)'*x(1:16368), x(1:16368)'*x(1+1:16368+1), x(1:16368)'*x(1+2:16368+2)]/16368 ;

    pts1(n) = rxx(2) ;
    pts2(n) = rxx(3) ;
    
    n = n + 1 ;
    
end

% approximation rx1(tau=1)
tau1_a = (pts1(end)-pts1(1))/(fs1_range(end)-fs1_range(1)) ;
tau1_b = pts1(1) ;
fprintf('rx1(tau=1,w) = %f*(w-%5.1f)+%f\n', tau1_a, fs1_range(1),tau1_b) ;

% approximation rx1(tau=2) (LS-polynomial, second order)
Dw = zeros(length(fs1_range),3) ;
for k=1:length(fs1_range)
    Dw(k,:) = [1, fs1_range(k), fs1_range(k)*fs1_range(k)] ;
end
d = pinv(Dw)*pts2(:) ;
rx1_tau2_approx = d(1) + fs1_range*d(2) + fs1_range.^2*d(3) ;
fprintf('rx1(tau=2,w) = %f+%f*w+%15.12f*w^2\n', d(1), d(2), d(3) ) ;

hold on ;
grid on ;
plot(fs1_range, pts1, 'k-','LineWidth',2) ;
plot(fs1_range, pts2, 'b-','LineWidth',2) ;

plot(fs1_range, tau1_a*(fs1_range-fs1_range(1))+tau1_b, ...
    'LineWidth',2, 'Color',[0.5 0.5 .6]) ;
plot(fs1_range, rx1_tau2_approx, ...
    'LineWidth',2, 'Color',[0.6 0.6 .9]) ;

legend('rx1(\tau=1,\omega)', 'rx1(\tau=2,\omega)','approximation of rx1(\tau=1,\omega)','approximation of rx1(\tau=2,\omega)'),
    title('rx1'),
    xlabel('\omega') ;
    hold off;