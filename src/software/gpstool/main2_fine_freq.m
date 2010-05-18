% main script for sattelite signal processing
clc, clear all ;
nDumpSize = 16368*7 ; 
x = readdump('./data/flush',nDumpSize) ;
%pwelch(x(1:16368),[],[],[],16.368e6) ;
FR = 4092-5:1:4092+5 ; % frequency range kHz
t_offs = 100 ; % /* time offset */
N = 16368 ;   % /* correlation length */
fs = 16368 ;   % /* sampling freq kHz */
max_sat = zeros(32,1) ;
max_fine_sat = zeros(32,1) ;
sat_shift_ca = zeros(32,1) ;
max_sat_freq = zeros(32,1) ;

PRN_range = 20:22 ;
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
    fprintf('#PRN: %2d, CR: %12.5f, FREQ.:%6f, SHIFT_CA:%4d\n',PRN,max_sat(PRN),max_sat_freq(PRN),sat_shift_ca(PRN)) ;
end

fprintf('Fine freq part ===>     \n') ;

%ca16 = get_ca_code16((N/16)*2,PRN) ;
%nca_phase = N - ca_phase + 2 ;
%x = x.*ca16(nca_phase:nca_phase+N-1) ;
%LO_sig = exp(j*2*pi*f0/fd*(0:N-1)) ; 
%acx = 0 ;
%if IsRealInput
%    acx = LO_sig*x ;    
%else
%    acx = real(LO_sig)*x ;
%end
%acx = acx*conj(acx) ;


% fine freq estimation
work_data = x(t_offs:end) ;
for PRN=PRN_range
    data_5ms = work_data(sat_shift_ca(PRN): sat_shift_ca(PRN) + 5*N-1);
    ca16 = get_ca_code16(N/16,PRN) ;
    data_5ms = data_5ms' .* [ca16' ca16' ca16' ca16' ca16'];

    %max_fine_sat(PRN) = max_sat(PRN) ;
        
    fr = zeros(3,1) ;
    for i=[1:3]
        fr(i) = max_sat_freq(PRN) - 400 + (i - 1) * 400 ;		% in kHz 
    end
    
    for i=[1:3]
        local_replica = exp(-j*2*pi * fr(i)/fs * (0:N-1)) ;         % FIXME - minus
        max_bin_freq(i) = abs( sum(data_5ms(1:N) .* local_replica) ) ;
        
        %max_bin_freq = max(gpsacq2(x(t_offs:end),N,PRN,fr(i), 0)) ;
        %if max_bin_freq > max_fine_sat(PRN)
        %    max_fine_sat(PRN) = max_bin_freq ;
        %    max_sat_freq(PRN) = fr(i) ;
        %    fprintf('\t %2d FREQ: %6f \n', PRN, fr(i) ) ;
        %end

        %fprintf('\t %2d: CR: %12.5f, FREQ.:%6f \n', PRN, max_bin_freq, fr ) ;

    end
   
    max_bin_freq
    
    %[max_f, shift_ca] = max(max_bin_freq) ;
    %fprintf('#PRN: %2d CR: [%12.5f] FREQ %6d \n',PRN, max_f, fr(shift_ca)  ) ;
        
    %fprintf('#PRN: %2d, CR: %12.5f, FREQ.:%6f \n',PRN,max_sat(PRN),max_sat_freq(PRN) ) ;
end

fprintf('Results: \n') ;

%for PRN=1:32
%    effect = max_fine_sat(PRN)/max_sat(PRN) ;
%    if effect > 1
%        fprintf('#PRN: %2d, %3.2f\n',PRN, effect) ;
%    end
%end

% plot result
%barh(max_sat),colormap summer, grid on, title('Correlator outputs') ;
