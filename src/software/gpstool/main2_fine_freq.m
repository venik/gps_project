% main script for sattelite signal processing
clc, clear all ;
nDumpSize = 16368*30 ;          % FIXME - we can more up to 32ms
%load('./data/x.mat') ;
%pwelch(x(1:16368),[],[],[],16.368e6) ;
FR = 4092-5:1:4092+5 ; % frequency range kHz
t_offs = 100 ;     % /* FIXME - time offset */
N = 16368 ;   % /* correlation length */
fs = 16368 ;   % /* sampling freq kHz */
ts = 1/(fs * 1000) ;

max_sat = zeros(32,1) ;
max_fine_sat = zeros(32,1) ;
max_fine_sat_new = zeros(32,1) ;

sat_shift_ca = zeros(32,1) ;
max_sat_freq = zeros(32,1) ;

freq_vals = zeros(32,3) ;
corr_vals = zeros(32,5) ;

%PRN_range = 1:32 ;
%PRN_range = 3 ;
PRN_range = 21 ;
%PRN_range = [21,22,23] ;

% ========= generate =======================
 x = readdump('./data/flush',nDumpSize) ;
%   x_ca16 = get_ca_code16(N/16,PRN_range(1)) ;
%   x_ca16 = [x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;
%       x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;
%       x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;
%       x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;
%       x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16] ;
%   x = exp(2*j*pi*4092000/16368000*(0:length(x_ca16)-1)).' ;

%delta = 150 ;
%x = cos(2*pi*(4092000 + delta)/16368000*(0:length(x_ca16)-1)).' ;
%x(length(x)/2+1000:end)=x(length(x)/2+1000:end) * (-1) ;
%x = x .* x_ca16 ;
%x=x+randn(size(x))*1 ;
%x = x(150:end) ;
% ========= generate =======================

for PRN=PRN_range
    for f0 = FR
        acx = gpsacq2(x(t_offs:end),N,PRN,f0, 0) ;
        [max_f,shift_ca] = max(acx) ;
        if max_f>=max_sat(PRN)
            max_sat(PRN) = max_f ;
            sat_shift_ca(PRN) = shift_ca ;
            max_sat_freq(PRN) = f0 ;
        end
        %plot(acx), grid on, title(sprintf('PRN=%d, F_0=%f',PRN,f0)) ;
        %pause ;
    end
    fprintf('#PRN: %2d, CR: %15.5f, FREQ.:%5.1f, SHIFT_CA:%4d\n',PRN,max_sat(PRN),max_sat_freq(PRN),sat_shift_ca(PRN)) ;
    
end

fprintf('Fine freq part ===>     \n') ;

% fine freq estimation
work_data = x(t_offs:end) ;
if 1
for PRN=PRN_range
    fprintf('#PRN: %2d\n', PRN); 
    
    data_5ms = work_data(sat_shift_ca(PRN) + 1: sat_shift_ca(PRN) + 5*N);
    %data_5ms = work_data(sat_shift_ca(PRN): sat_shift_ca(PRN) + 5*N - 1);     % FIXME show to the MAO plot(data_5ms(2.445e4:2.452e4))
    
    ca16 = get_ca_code16(N/16,PRN) ;
    ca16 = [ca16;ca16;ca16;ca16;ca16] ;
    data_5ms =  ca16 .* data_5ms ;
    
    %max_fine_sat(PRN) = max_sat(PRN) ;
    
    fr = zeros(3,1) ;
    for i=[1:3]
        fr(i) = max_sat_freq(PRN)*1000 - 400 + (i - 1) * 400 ;		% in Hz 
    end

    freq_vals(PRN, 1) = fr(2) ;
    
    for i=[1:3]
        local_replica = exp(j*2*pi * fr(i)*ts * (0:N-1)) ;
        max_bin_freq(i) = abs( sum(data_5ms(1:N).' .* local_replica) )^2 ;
    end
            
    % adjust freq in freq bin
    [max_fine_sat(PRN), shift_ca] = max(max_bin_freq) ;
    %fr(shift_ca) = fr(shift_ca) + 0.2 * (shift_ca - 2) ;    
    
    %fprintf('\t%15.5f, %15.5f, %15.5f\n',max_bin_freq(1)^2,max_bin_freq(2)^2,max_bin_freq(3)^2) ;
    fprintf('\t new [%15.5f] FREQ.:%5.1f\n\t old [%15.5f] FREQ.:%5.1f,\n', max_bin_freq(2), fr(shift_ca), max_sat(PRN), max_sat_freq(PRN)) ;
    
    freq_vals(PRN, 2) =  fr(shift_ca);
    
    % get rid from possible phase change
    sig = data_5ms.' .* exp(j*2*pi * fr(shift_ca)*ts * (0:5*N-1)) ;
    phase = diff(-angle(sum(reshape(sig, N, 5))));
    phase_fix = phase;
    
    threshold = (2.3*pi)/5 ; % FIXME / or \
    
    for i=1:4 ;
        if(abs(phase(i))) > threshold ;
            phase(i) = phase_fix(i) - 2*pi ;
            if(abs(phase(i))) > threshold ;
                phase(i) = phase_fix(i) + 2*pi ;
                %if(abs(phase(i))) > 2.2*pi / 5 ;    % FIXME / or \
                if(abs(phase(i))) > threshold ;
                    phase(i) = phase_fix(i) - pi ;
                    if(abs(phase(i))) > threshold ;
                       phase(i) = phase_fix(i) - 3*pi ;
                       if(abs(phase(i))) > threshold ;
                           phase(i) = phase_fix(i) + pi ;
                       end
                    end
                end
            end
        end
    end
    
    fprintf('\t phase: [%f] [%f] [%f] [%f] \n', phase(1), phase(2), phase(3), phase(4) );
    
    dfrq = mean(phase)*1000 / (2*pi) ;
    fr(shift_ca) = fr(shift_ca) + dfrq ;
    
    if( mean(phase) > threshold ) 
        fprintf('\t\tThats bad dfrg [%d] > threshold \n', dfrq) ;
    end
    
    freq_vals(PRN, 3) =  fr(shift_ca);
    
    % one more unneded correlation
    for k=1:5
        sig = data_5ms(1 + N*(k-1):N*k).' .* exp(j*2*pi * fr(shift_ca)*ts * (0:N-1)) ;
        corr_vals(PRN,k) = abs(sum(sig))^2 ;
        fprintf('\t tmp [%15.5f]\n', corr_vals(PRN, k) ) ;  
        max_fine_sat_new(PRN) = max_fine_sat_new(PRN) + corr_vals(PRN,k);
    end
    max_fine_sat_new(PRN) = max_fine_sat_new(PRN) / 5 ;
       
    fprintf('\t ffe [%15.5f] FREQ.: %5.1f phase: %f \n', max_fine_sat_new(PRN), fr(shift_ca), dfrq) ;
   
    % prepare for tracking
    max_sat_freq(PRN) = fr(shift_ca) ;
    
end
end

fprintf('Results: \n') ;

% plot result
figure(1), subplot(3, 1, 1), barh(max_fine_sat_new), xlim([1,13e7]), ylim([1,32]), colormap summer, grid on, title('Correlator outputs after fine freq estimation') ;
figure(1), subplot(3, 1, 2), barh(max_fine_sat), xlim([1,13e7]), ylim([1,32]), colormap summer, grid on, title('Correlator outputs with 400 Hz adjust') ;
figure(1), subplot(3, 1, 3), barh(max_sat), xlim([1,13e7]), ylim([1,32]), colormap summer, grid on, title('Correlator outputs') ;

figure(2), subplot(2,1,1), plot(freq_vals(PRN, 1:3), '-or'), title('FREQ'), subplot(2,1,2), plot(corr_vals(PRN, 1:5), '-or'), title('Correlation') ;

% ===============================================================
% costas & DLL
time_range = 29*N ;
chip_length = N/1023;
I_data = zeros(time_range,1);
Q_data = zeros(time_range,1);

% filter constants - tsui related values
zu_cl = 0.7 ;             % damping ratio
%zu_cl = 1 ;             % damping ratio
k0k1_cl = 4*pi * 100 ;      % gain
B_cl = 20 ;                 % noise bandwith
omega_cl = 8*zu_cl*B_cl / (4*zu_cl^2 + 1) ;
C1_cl = (1/k0k1_cl) * (8*zu_cl*omega_cl*ts / (4 + 4*zu_cl*omega_cl*ts + (omega_cl*ts)^2) ) ;
C2_cl = (1/k0k1_cl) * (4*(omega_cl*ts)^2   / (4 + 4*zu_cl*omega_cl*ts + (omega_cl*ts)^2) ) ;
nco_ctl = 0 ;
mixer_I1 = 0 ;
mixer_Q1 = 0 ;
lpf_I = 0 ;
lpf_I1 = 0 ;
lpf_Q = 0 ;
lpf_Q1 = 0 ;

data_mixed_I = zeros(time_range,1) ;
data_mixed_Q = zeros(time_range,1) ;
data_lpf_I = zeros(time_range,1) ;
data_lpf_Q = zeros(time_range,1) ;
data_theta = zeros(time_range,1) ;
data_lf_theta = zeros(time_range,1) ; 
data_nco_ctl = zeros(time_range,1) ; 

% lowpass filter coefs
lpf_b = 0.981 ;
lpf_a = 0.0095 ;

if 0
for PRN=PRN_range
    data = work_data(sat_shift_ca(PRN): end);
    ca16 = get_ca_code16(N/16,PRN) ;
    
    %freq_error = 15 ;
    %max_sat_freq(PRN) = max_sat_freq(PRN)*1000 + freq_error;      % convert kHz => Hz
    %fprintf('start with freq\t%10.5f err = %f\n', max_sat_freq(PRN), freq_error) ;
    
    max_sat_freq(PRN) = max_sat_freq(PRN)*1000 ;      % convert kHz => Hz
    fprintf('start with freq\t%10.5f \n', max_sat_freq(PRN)) ;
    
    for data_step=1
        
        data_chip = data(1:time_range);
        data_chip = data_chip .* [ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;
                                  ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16] ;
                            
        I_data(1:time_range) = real( data_chip(1:time_range) ) ;
        Q_data(1:time_range) = real( data_chip(1:time_range) ) ;
        %Q_data(1:time_range) = imag( data_chip ) ;
                   
        % loop filter queues
        y_theta_cl = zeros(3,1) ;
        x_theta_cl = zeros(3,1) ;
        
        % make 1ms
        for h=1:time_range
                    
            nco_sample = exp(j*2*pi*(max_sat_freq(PRN) - nco_ctl)/fs*(h-1)) ;
            mixer_I = I_data(h)*real(nco_sample) ;
            mixer_Q = Q_data(h)*imag(nco_sample) ;
            
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

            nco_ctl = lf_theta * 1000 ;   
            
            % collect data
            data_mixed_I(h) = mixer_I ;
            data_mixed_Q(h) = mixer_Q ;
            data_lpf_I(h) = lpf_I ;
            data_lpf_Q(h) = lpf_Q ;
            data_theta(h) = theta ;
            data_lf_theta(h) = lf_theta ;
            data_nco_ctl(h) = nco_ctl ;

        end % for h=
        
        fprintf('resulted freq\t%10.5f phi = %f\n', max_sat_freq(PRN) - nco_ctl, nco_ctl) ;
        
    end % for data_step=1
end

figure(2), plot(data_nco_ctl) ;
end

%fprintf('hello\n') ;