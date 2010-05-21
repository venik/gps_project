% main script for sattelite signal processing
clc, clear all ;
nDumpSize = 16368*16 ;          % FIXME - we can more 
x = readdump('./data/flush',nDumpSize) ;
%pwelch(x(1:16368),[],[],[],16.368e6) ;
FR = 4092-5:1:4092+5 ; % frequency range kHz
t_offs = 100 ; % /* time offset */
N = 16368 ;   % /* correlation length */
fs = 16368 ;   % /* sampling freq kHz */

max_sat = zeros(32,1) ;
max_fine_sat = zeros(32,1) ;
max_fine_sat_new = zeros(32,1) ;

sat_shift_ca = zeros(32,1) ;
max_sat_freq = zeros(32,1) ;

PRN_range = 3 ;
%PRN_range = 1:32 ;

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
    fprintf('#PRN: %2d, CR: %12.5f, FREQ.:%5.1f, SHIFT_CA:%4d\n',PRN,max_sat(PRN),max_sat_freq(PRN),sat_shift_ca(PRN)) ;
end

fprintf('Fine freq part ===>     \n') ;

% fine freq estimation
work_data = x(t_offs:end) ;
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
   
    %max_bin_freq
    
    % adjust freq in freq bin
    [max_fine_sat(PRN), shift_ca] = max(max_bin_freq) ;
    fr(shift_ca) = max_sat_freq(PRN) + 0.2 * (shift_ca-2) ;
    
    % get rid from possible phase change
    sig = data_5ms.' .* exp(j*2*pi * fr(shift_ca)/fs * (0:5*N-1)) ;
    phase = diff(-angle(sum(reshape(sig, N, 5))));
    phase_fix = phase;
    
    threshold = 2.3*pi/5 ; % FIXME / or \
    
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
    max_fine_sat_new(PRN) = abs( sum(data_5ms(1:N).' .* exp(j*2*pi * fr(shift_ca)/fs * (0:N-1) ) ) ) ;
        
    fprintf('#PRN: %2d CR: [%10.5f] CR+phi: [%10.5f] FREQ %10.5f phase: %f \n', PRN, max_fine_sat(PRN), max_fine_sat_new(PRN), fr(shift_ca), dfrq) ;
   
    % prepare for tracking
    max_sat_freq(PRN) = fr(shift_ca) ;
    
end

fprintf('Results: \n') ;

% plot result
%subplot(3, 1, 1), barh(max_fine_sat_new), xlim([0,11000]), colormap summer, grid on, title('Correlator outputs after fine freq estimation') ;
%subplot(3, 1, 2), barh(max_fine_sat), xlim([0,11000]), colormap summer, grid on, title('Correlator outputs with 400 Hz adjust') ;
%subplot(3, 1, 3), barh(max_sat),colormap summer, grid on, title('Correlator outputs') ;

% costas
sec = 15;
costas_phase = zeros(sec,1) ;
for PRN=PRN_range
    data = work_data(sat_shift_ca(PRN): sat_shift_ca(PRN) + sec*N-1);
    
    for data_step=0:sec-1
        carrier_generator = exp(j*2*pi * max_sat_freq(PRN)/fs * (0:N-1)) ;
        for_descr = data((data_step * N) + 1: (data_step+1)*N ) ;
        
        costas_phase(data_step + 1) = angle(sum(for_descr.' .* carrier_generator)) ;
        dfrq = costas_phase(data_step + 1) / (2*pi) ;
        max_sat_freq(PRN) =  max_sat_freq(PRN) + dfrq ;
    end
end

fprintf('hello\n') ;