%function simApproximateRx1
clc, clear all ;
prn1 = 3 ;
prn2 = 1 ;
delay1 = 16 ;
delay2 = 16*5 ;
varx1 = 1 ;
varx2 = 2 ;
fs1_range = 1:100:16368/2 ;
fd = 16368 ;

pts1 = zeros(size(fs1_range)) ;
pts2 = zeros(size(fs1_range)) ;
pts3 = zeros(size(fs1_range)) ;

n = 1 ;
for fs1 = fs1_range
    
    cosin = sqrt(2)*cos(2*pi*fs1/fd*(0:17600)) ; cosin = cosin(:) ;
    code1 = get_ca_code16(1100,prn1) ;
    code2 = get_ca_code16(1100,prn2) ;
    
    x = cosin(1+delay1:16371+delay1).*code1(1+delay1:16371+delay1).*code2(1+delay2:16371+delay2) ;
    
    rxx = [x(1:16368)'*x(1:16368), x(1:16368)'*x(1+1:16368+1), x(1:16368)'*x(1+2:16368+2)]/16368 ;

    pts1(n) = rxx(2) ;
    pts2(n) = rxx(3) ;
    
    n = n + 1 ;
    
end

fprintf('Dx: %f\n', rxx(1)) ;

% approximation rx1(tau=1)
%tau1_a = (pts1(end)-pts1(1))/(fs1_range(end)-fs1_range(1)) ;
%tau1_b = pts1(1) ;
%fprintf('rx1(tau=1,w) = %10.7f*(w-%5.1f)+%f /1000\n', tau1_a*1e3, fs1_range(1),tau1_b*1e3) ;
rx1_tau1_approx = 0.872513935*cos(2*pi*fs1_range/16368*1) ;
rx1_tau2_approx = 0.809847951*cos(2*pi*fs1_range/16368*2) ;

% approximation rx1(tau=2) (LS-polynomial, second order)
Dw = zeros(length(fs1_range),3) ;
for k=1:length(fs1_range)
    Dw(k,:) = [1, fs1_range(k), fs1_range(k)*fs1_range(k)] ;
end
d = pinv(Dw)*pts2(:) ;
%rx1_tau2_approx = d(1) + fs1_range*d(2) + fs1_range.^2*d(3) ;
%fprintf('rx1(tau=2,w) = %f+%f*w+%15.12f*w^2 /1000\n', d(1)*1e3, d(2)*1e3, d(3)*1e3 ) ;

hold on ;
grid on ;
plot(fs1_range, pts1, 'Color',[0.6 0.6 0.6],'LineWidth',2) ;
plot(fs1_range, pts2, 'k-','LineWidth',2) ;

plot(fs1_range(1:3:end), rx1_tau1_approx(1:3:end), ... %tau1_a*(fs1_range-fs1_range(1))+tau1_b, ...
    '-.^','LineWidth',1, 'Color',[0.3 0.3 .8]) ;
plot(fs1_range(1:3:end), rx1_tau2_approx(1:3:end), ...
    '-.+','LineWidth',2, 'Color',[0.3 0.7 .3]) ;

legend('rx1(\tau=1,\omega)', 'rx1(\tau=2,\omega)','approximation of rx1(\tau=1,\omega)','approximation of rx1(\tau=2,\omega)'),
    title('rx1'),
    xlabel('\omega,Hz') ;
    hold off;
set(gca,'FontSize',14) ;
