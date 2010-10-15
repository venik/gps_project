clc, clear all ;
sig_length = 1024000*3 ; % signal length
fx = 4092000 ; % input signal frequency
fs = 16368000 ; % sampling frequency
x = sin(2*pi * fx/fs * (0:sig_length-1)) ; % input signal

fx_error = -10 ;
f_nco_base = fx + fx_error ;
data_mixed_I = zeros(sig_length,1) ;
data_mixed_Q = zeros(sig_length,1) ;
data_lpf_I = zeros(sig_length,1) ;
data_lpf_Q = zeros(sig_length,1) ;
data_theta = zeros(sig_length,1) ;
data_lf_theta = zeros(sig_length,1) ; 
data_nco_ctl = zeros(sig_length,1) ; 

nco_ctl = 0 ;
mixer_I1 = 0 ;
mixer_Q1 = 0 ;
lpf_I = 0 ;
lpf_I1 = 0 ;
lpf_Q = 0 ;
lpf_Q1 = 0 ;

% lowpass filter coefs
lpf_b = 0.981 ;
lpf_a = 0.0095 ;

% loop filter constants - tsui related values
ts = 1/fs ;
zu_cl = 0.707 ;             % damping ratio
%zu_cl = 1 ;             % damping ratio
k0k1_cl = 4*pi * 100 ;      % gain
B_cl = 25 ;                 % noise bandwith
omega_cl = 8*zu_cl*B_cl / (4*zu_cl^2 + 1) ;
C1_cl = (1/k0k1_cl) * (8*zu_cl*omega_cl*ts / (4 + 4*zu_cl*omega_cl*ts + (omega_cl*ts)^2) ) ;
C2_cl = (1/k0k1_cl) * (4*(omega_cl*ts)^2   / (4 + 4*zu_cl*omega_cl*ts + (omega_cl*ts)^2) ) ;

% loop filter queues
y_theta_cl = zeros(3,1) ;
x_theta_cl = zeros(3,1) ;


for n=1:sig_length
    nco_sample = exp(j*2*pi*(f_nco_base - nco_ctl)/fs*(n-1)) ;
    mixer_I = x(n)*real(nco_sample) ;
    mixer_Q = x(n)*imag(nco_sample) ;

    % I lowpass filter
    lpf_I = lpf_b*lpf_I1 + lpf_a*mixer_I + lpf_a*mixer_I1 ;
    mixer_I1 = mixer_I ;
    lpf_I1 = lpf_I ;
    
    % Q lowpass filter
    lpf_Q = lpf_b*lpf_Q1 + lpf_a*mixer_Q + lpf_a*mixer_Q1 ;
    mixer_Q1 = mixer_Q ;
    lpf_Q1 = lpf_Q ;
    
    % descriminator
    if lpf_I1==0
        theta = 0 ;
    else
        theta = atan(lpf_Q1/lpf_I1) ;
    end
    
    % loop filter
    x_theta_cl(3) = theta ;
    y_theta_cl(3) = k0k1_cl*(C1_cl+C2_cl)*x_theta_cl(2) - k0k1_cl*C1_cl*x_theta_cl(1) - ...
                (k0k1_cl*(C1_cl+C2_cl) - 2)*y_theta_cl(2) - (1 - k0k1_cl*C1_cl)*y_theta_cl(1) ;
    y_theta_cl(1:2) = y_theta_cl(2:3) ;
    x_theta_cl(1:2) = x_theta_cl(2:3) ;
    
    lf_theta = y_theta_cl(3) ;
    
    nco_ctl = lf_theta * (9) ;    
    
    % collect data
    data_mixed_I(n) = mixer_I ;
    data_mixed_Q(n) = mixer_Q ;
    data_lpf_I(n) = lpf_I ;
    data_lpf_Q(n) = lpf_Q ;
    data_theta(n) = theta ;
    data_lf_theta(n) = lf_theta ;
    data_nco_ctl(n) = nco_ctl ;
    
end

fprintf(' base %f, error %f, adjusted %f \n', fx, fx_error, fx + data_nco_ctl(n));

%figure(1),hold off, plot(data_mixed_Q,'r-'),hold on,plot(data_lpf_Q)
%figure(2), plot(data_theta), grid on
%figure(3), plot(data_lf_theta), grid on
figure(1), plot(data_nco_ctl) ;