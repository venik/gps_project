% test tool. try to find initial point for satellite and track it
% through data. main goal - check our parralel algorithm

clc, clear all ;
nDumpSize = 16368*30 ;          % FIXME - we can more up to 32ms

%load('./data/x.mat') ;
%pwelch(x(1:16368),[],[],[],16.368e6) ;

FR = 4092000-5e3:1e3:4092e3+5e3 ; % /* frequency range Hz  */
t_offs = 100 ;                    % /* FIXME - time offset */
N = 16368 ;                       % /* correlation length  */
fs = 16368e3 ;                    % /* sampling freq kHz   */
ts = 1/fs ;

max_sat = zeros(32,1) ;
%max_fine_sat = zeros(32,1) ;
%max_fine_sat_new = zeros(32,1) ;

sat_shift_ca = zeros(32,1) ;
max_sat_freq = zeros(32,3) ;

freq_vals = zeros(32,3) ;

%PRN_range = 1:32 ;
%PRN_range = 16 ;
PRN_range = 20 ;
%PRN_range = [21,22,23] ;

% ========= generate =======================
if 1
   x_ca16 = get_ca_code16(N/16,PRN_range(1)) ;
   x_ca16 = [x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;
       x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;
       x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;
       x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;
       x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16;x_ca16] ;
   x = exp(2*j*pi*4092000/16368000*(0:length(x_ca16)-1)).' ;

delta = 101 ;
x = cos(2*pi*(4092000 + delta)/16368000*(0:length(x_ca16)-1)).' ;
x(length(x)/2+1000:end)=x(length(x)/2+1000:end) * (-1) ;
x = x .* x_ca16 ;
x=x+randn(size(x))*10 ;

else
    x = readdump('./data/flush',nDumpSize) ;   
end
% ========= generate =======================

% move to offset
x = x(t_offs:end) ;

% coarse acqusition
for PRN=PRN_range
    acx = gpsacq3(x(1:end),N,PRN,FR, 0) ;
    [max_sat(PRN), k] = max(acx(1:length(FR),1));
    sat_shift_ca(PRN) = acx(k,2) ;
    max_sat_freq(PRN,1) = FR(k) ;
    
    fprintf('#PRN: %2d CR: %15.5f, FREQ.:%5.1f, SHIFT_CA:%4d\n',PRN,max_sat(PRN),max_sat_freq(PRN),sat_shift_ca(PRN)) ;
end

% +- 400 Hz in freq bin
if 1
    
max_bin_freq = zeros(3,1) ;

for PRN=PRN_range
     data_5ms = x(sat_shift_ca(PRN): sat_shift_ca(PRN) + 5*N-1);
    %data_5ms = work_data(sat_shift_ca(PRN): sat_shift_ca(PRN) + 5*N - 1);     % FIXME show to the MAO plot(data_5ms(2.445e4:2.452e4))
    
    ca16 = get_ca_code16(N/16,PRN) ;
    ca16 = [ca16;ca16;ca16;ca16;ca16] ;
    data_5ms =  ca16 .* data_5ms ;
    
    fr = zeros(3,1) ;
    for i=[1:3]
        fr(i) = max_sat_freq(PRN,1) - 400 + (i - 1) * 400 ;		% in Hz 
    end

    freq_vals(PRN, 1) = fr(2) ;
    
    % FIXME
    for i=[1:3]
        local_replica = exp(j*2*pi * fr(i)*ts * (0:N-1)) ;
        max_bin_freq(i) = abs( sum(data_5ms(1:N).' .* local_replica) )^2 ;
    end
    
    % adjust freq in freq bin
    [max_fine_sat(PRN), k] = max(max_bin_freq) ;
        
    fprintf('\t new [%15.5f] FREQ.:%5.1f\n\t old [%15.5f] FREQ.:%5.1f\n', max_bin_freq(k), fr(k), max_sat(PRN), max_sat_freq(PRN, 1)) ;

%x1 = x(t_offs:t_offs+N-1) ;
%LO_sig = exp(j*2*pi*f0/16368*(0:2*N-1)) ; 
%ca16 = get_ca_code16(N/16,20) ;
%ca16 = [ca16;ca16] ;
%ca16 = ca16(:).'.*real(LO_sig) ;
%ca16 = ca16(16368-sca+2:16368-sca+1+16368) ;
%xcr1 = ca16*x1 ;
%fprintf('%12.5f\n',xcr1*conj(xcr1)) ;

if 0
    % ===========================
    %      parallel check  FIXME 
    % ===========================
    acx = gpsacq2(x(sat_shift_ca(PRN):end),N,PRN,fr(2), 0) ;
    [max_f,shift_ca] = max(acx) ;
    cor_par_vals(PRN, k) = max_f ;
    shift_ca_par_vals(PRN, k) = shift_ca ;
    fprintf('\t chk_circ [%15.5f] FREQ.:%5.1f\n\t chk_parr [%15.5f] FREQ.:%5.1f SHIFT_CA:%4d\n', max_bin_freq(2), fr(2), max_f, fr(2), shift_ca) ;
    % ===========================
end
    
    max_sat_freq(PRN,2) =  fr(k);
 
    % ===========================
    % tsui phase magic
    % ===========================
    % get rid from possible phase change
    sig = data_5ms.' .* exp(j*2*pi * max_sat_freq(PRN,2)*ts * (0:5*N-1)) ;
    phase = diff(-angle(sum(reshape(sig, N, 5))));
    phase_fix = phase;

    threshold = (2.3*pi)/5 ; % FIXME / or \

    for i=1:4 ;
        fprintf('\t %d => %f => %f\n', i, phase(i), phase(i)/2*pi * 180 );
        
        if(abs(phase(i))) > threshold ;
            phase(i) = phase_fix(i) - sign(phase(i))* 2 * pi ;
            fprintf('\t\t %d => %f => %f\n', i, phase(i), phase(i)/2*pi * 180 );
            
            if(abs(phase(i))) > threshold ;
                phase(i) = phase(i) - sign(phase(i))* pi ;
                fprintf('\t\t\t %d => %f => %f\n', i, phase(i), phase(i)/2*pi * 180 );
                
                if(abs(phase(i))) > threshold ;
                    phase(i) = phase_fix(i) - sign(phase(i))* 2 * pi ;
                    fprintf('\t\t\t\t %d => %f => %f\n', i, phase(i), phase(i)/2*pi * 180 );
                end
            end
        end
    end

    dfrq = mean(phase)*1000 / (2*pi) ;
    max_sat_freq(PRN, 3) =  fr(k) + dfrq;
    
    fprintf('\t FREQ.:%5.1f\n', max_sat_freq(PRN, 3)) ;
    
end % for PRN=PRN_range FINE FREQ part

end % if 0 of +- 400 Hz

% now we know initial point of the signal (shift_ca) try to move window and
% check initial CA point

corr_par_vals = zeros(32,32) ;
corr_par_vals_2 = zeros(32,32) ;
shift_ca_par_vals = zeros(32,32) ;

for PRN=PRN_range
    % move to initail point
    x_win = x(sat_shift_ca(PRN):end) ;
    f0_1 = max_sat_freq(PRN,2) ;
    
    % move window
    for k = 1:29
        acx = gpsacq2(x_win(1 + (k-1)*N:N*k),N,PRN,f0_1, 0) ;
        [max_f,shift_ca] = max(acx) ;
        cor_par_vals(PRN, k) = max_f ;
        shift_ca_par_vals(PRN, k) = shift_ca ;
        %fprintf('\t CR: %15.5f, SHIFT_CA:%4d\n', max_f, shift_ca) ;
    end
end

for PRN=PRN_range
    % move to initail point
    x_win = x(sat_shift_ca(PRN):end) ;
    f0_2 = max_sat_freq(PRN,3) ;
    
    % move window
    for k = 1:29
        acx = gpsacq2(x_win(1 + (k-1)*N:N*k),N,PRN,f0_2, 0) ;
        [max_f,shift_ca] = max(acx) ;
        cor_par_vals_2(PRN, k) = max_f ;
        %shift_ca_par_vals_2(PRN, k) = shift_ca ;
        %fprintf('\t CR: %15.5f, SHIFT_CA:%4d\n', max_f, shift_ca) ;
    end
    fprintf(' \t: done\n');
end


%figure(1), subplot(3, 1, 1), barh(max_fine_sat_new), xlim([1,13e7]), ylim([1,32]), colormap summer, grid on, title('Correlator outputs after fine freq estimation') ;
%figure(1), barh(max_sat), xlim([1,13e7]), ylim([1,32]), colormap summer, grid on, title('Correlator outputs after fine freq estimation') ;
%figure(2), grid on, subplot(2,1,1), plot(cor_par_vals(PRN, 1:k)), title(['Corr vals   FREQ:' int2str(f0)] ), subplot(2,1,2), plot(shift_ca_par_vals(PRN, 1:k)), title('shift CA');
%figure(2), grid on, plot(cor_par_vals(PRN, 1:k), '-or'), hold on, plot(shift_ca_par_vals(PRN, 1:k), '-xg'), hold off;

figure(2), grid on, subplot(2,1,1), plot(cor_par_vals(PRN, 1:k)), title(['Corr vals   FREQ:' int2str(f0_1)] ), subplot(2,1,2), plot(cor_par_vals_2(PRN, 1:k)), title(['Second ' int2str(f0_2)]);