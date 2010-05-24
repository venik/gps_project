% main script for sattelite signal processing
clc, clear all ;
nDumpSize = 16368*16 ;          % FIXME - we can more up to 32ms
%x = readdump('./data/flush',nDumpSize) ;
%load('./data/x.mat') ;
%pwelch(x(1:16368),[],[],[],16.368e6) ;
FR = 4092-5:1:4092+5 ; % frequency range kHz
t_offs = 100 ; % /* time offset */
N = 16368 ;   % /* correlation length */
fs = 16368 ;   % /* sampling freq kHz */
ts = 1/(fs * 1000) ;

max_sat = zeros(32,1) ;
max_fine_sat = zeros(32,1) ;
max_fine_sat_new = zeros(32,1) ;

sat_shift_ca = zeros(32,1) ;
max_sat_freq = zeros(32,1) ;

%PRN_range = 1:32 ;
PRN_range = 3 ;
%PRN_range = [21,22,23] ;

% ========= generate =======================
x_ca16 = get_ca_code16(N/16,PRN_range(1)) ;
x_ca16 = [x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16] ;
x = sin(2*pi*4092000/16368000*(0:length(x_ca16)-1)).' ;
%x = exp(2*pi*4092100/16368000*(0:length(x_ca16)-1)).' ;
x = x.*x_ca16 ;
%x(length(x)/2:end)=x(length(x)/2:end) * (-1) ;
%x=x+randn(size(x))*1 ;
%x = x(150:end) ;
% ========= generate =======================

for PRN=PRN_range
    for f0 = FR
        acx = gpsacq2(x(t_offs:end),N,PRN,f0, 0) ;
        [max_f,shift_ca] = max(acx) ;
        if max_f>max_sat(PRN)
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
if 0
for PRN=PRN_range
    data_5ms = work_data(sat_shift_ca(PRN): sat_shift_ca(PRN) + 5*N-1);
    ca16 = get_ca_code16(N/16,PRN) ;
    ca16 = [ca16;ca16;ca16;ca16;ca16] ;
    data_5ms =  ca16(:) .* data_5ms ;
    
    %max_fine_sat(PRN) = max_sat(PRN) ;
        
    fr = zeros(3,1) ;
    for i=[1:3]
        fr(i) = max_sat_freq(PRN) - 0.4 + (i - 1) * 0.4 ;		% in kHz 
    end
    
    for i=[1:3]
        local_replica = exp(j*2*pi * fr(i)/fs * (0:N-1)) ;
        max_bin_freq(i) = abs( sum(data_5ms(1:N).' .* local_replica) ) ;
    end
        
    %fprintf('%15.5f, %15.5f, %15.5f\n',max_bin_freq(1)^2,max_bin_freq(2)^2,max_bin_freq(3)^2) ;

    % adjust freq in freq bin
    [max_fine_sat(PRN), shift_ca] = max(max_bin_freq) ;
    fr(shift_ca) = max_sat_freq(PRN) + 0.2 * (shift_ca-2) ;
%end ;

    % get rid from possible phase change
    sig = data_5ms.' .* exp(j*2*pi * fr(shift_ca)/fs * (0:5*N-1)) ;
    phase = diff(-angle(sum(reshape(sig, N, 5))));
    phase_fix = phase;
    
    threshold = 2.3*pi\5 ; % FIXME / or \
    
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
                    
    dfrq = mean(phase) / (2*pi) ;
    fr(shift_ca) = fr(shift_ca) + dfrq ;

    % one more unneded correlation
    max_fine_sat_new(PRN) = abs( sum(data_5ms(1:N).' .* exp(j*2*pi * fr(shift_ca)/fs * (0:N-1))) ) ;
        
    fprintf('#PRN: %2d CR: [%10.5f] CR+phi: [%10.5f] FREQ %10.5f phase: %f \n', PRN, max_fine_sat(PRN), max_fine_sat_new(PRN), fr(shift_ca), dfrq) ;
   
    % prepare for tracking
    max_sat_freq(PRN) = fr(shift_ca) ;
    
end
end

fprintf('Results: \n') ;

% plot result
%subplot(3, 1, 1), barh(max_fine_sat_new), xlim([0,11000]), ylim([1,32]), colormap summer, grid on, title('Correlator outputs after fine freq estimation') ;
%subplot(3, 1, 2), barh(max_fine_sat), xlim([0,11000]), ylim([1,32]), colormap summer, grid on, title('Correlator outputs with 400 Hz adjust') ;
%subplot(3, 1, 3), barh(max_sat), ylim([1,32]), colormap summer, grid on, title('Correlator outputs') ;

% costas & DLL
sec = 15;
chip_length = N/1023;
I_data = zeros(5*N,1);
Q_data = zeros(5*N,1);

% filter constants - tsui related values
zu_cl = 0.707 ;             % damping ratio
k0k1_cl = 4*pi * 100 ;      % gain
B_cl = 50 ;                 % noise bandwith
omega_cl = 8*zu_cl*B_cl / (4*zu_cl^2 + 1) ;
C1_cl = (1/k0k1_cl) * (8*zu_cl*omega_cl*ts / (4 + 4*zu_cl*omega_cl*ts + (omega_cl*ts)^2) ) ;
C2_cl = (1/k0k1_cl) * (4*(omega_cl*ts)^2   / (4 + 4*zu_cl*omega_cl*ts + (omega_cl*ts)^2) ) ;
y_I_cl = zeros(3,1);
x_I_cl = zeros(3,1);
y_Q_cl = zeros(3,1);
x_Q_cl = zeros(3,1);

tmp = zeros(10*N+10,1) ;   % delete me
k = 1 ;                 % delete me too
tmp_I = zeros(10*N+10,1) ;
tmp_Q = zeros(10*N+10,1) ;
tmp_I_f = zeros(10*N+10,1) ;
tmp_Q_f = zeros(10*N+10,1) ;

phi = 0;

for PRN=PRN_range
    %data = work_data(sat_shift_ca(PRN): end);
    data = work_data(1: end);
    ca16 = get_ca_code16(N/16,PRN) ;
    
    max_sat_freq(PRN) = max_sat_freq(PRN)*1000 - 200 ;      % convert kHz => Hz
    
    for data_step=1
        
        data_chip = data(1:10*N) ;
        data_chip = data_chip .* [ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16] ;
        I_data(1:10*N) = real( data_chip ) ;
        Q_data(1:10*N) = real( data_chip ) ;
                   
        x_I_cl(1:2) = I_data(1:2) ;
        x_Q_cl(1:2) = Q_data(1:2) ;
        
        % make 1ms
        for h=3:10*N
                    
            carrier_generator = exp( j*2*pi * (max_sat_freq(PRN)+phi*0.2)*ts * (h-1)) ;
            I_channel = real(carrier_generator) ;
            Q_channel = imag(carrier_generator) ; 

            I_corr = I_channel .* I_data(h);
            Q_corr = Q_channel .* Q_data(h);
            
            tmp_I(k) = I_corr;
            tmp_Q(k) = Q_corr;

            % I channel
            x_I_cl(3) = I_corr ;

            y_I_cl(3) = k0k1_cl*(C1_cl+C2_cl)*x_I_cl(2) - k0k1_cl*C1_cl*x_I_cl(1) - ...
                        (k0k1_cl*(C1_cl+C2_cl) - 2)*y_I_cl(2) - (1 - k0k1_cl*C1_cl)*y_I_cl(1) ;

            y_I_cl(1:2) = y_I_cl(2:3) ;
            x_I_cl(1:2) = x_I_cl(2:3) ;

            % Q channel
            x_Q_cl(3) = Q_corr ;

            y_Q_cl(3) = k0k1_cl*(C1_cl+C2_cl)*x_Q_cl(2) - k0k1_cl*C1_cl*x_Q_cl(1) - ...
                        (k0k1_cl*(C1_cl+C2_cl) - 2)*y_Q_cl(2) - (1 - k0k1_cl*C1_cl)*y_Q_cl(1) ;

            y_Q_cl(1:2) = y_Q_cl(2:3) ;
            x_Q_cl(1:2) = x_Q_cl(2:3) ;
            
            tmp_I_f(k) = y_I_cl(3);
            tmp_Q_f(k) = y_Q_cl(3);
            
            % phase correction
            %phi = y_I_cl(3) + y_Q_cl(3) * j ;
            %phi = angle(phi) / (2*pi);
                        
            phi = atan(y_Q_cl(3)/y_I_cl(3)) / (2*pi) ;
            
            %max_sat_freq(PRN) =  max_sat_freq(PRN) - phi ;

            %fprintf('[%2d] phi = %d\n', f, phi) ;
            tmp(k) = phi;
            k = k+1;
            
        end % for h=1:1023
        
    end % for data_step=1
end

plot(tmp) ;

%fprintf('hello\n') ;