% test tool. try to create pll and dll

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

delta = 199 ;
x = cos(2*pi*(4092000 + delta)/16368000*(0:length(x_ca16)-1)).' ;
bit_shift = round(abs(rand(1)*(length(x)-1))) ;
x(bit_shift:end)=x(bit_shift:end) * (-1) ;
%x(length(x)/2+1000:end)=x(length(x)/2+1000:end) * (-1) ;
x = x .* x_ca16 ;
%x=x+randn(size(x))*10 ;

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
    
    %fprintf('#PRN: %2d CR: %15.5f, FREQ.:%5.1f, SHIFT_CA:%4d\n',PRN,max_sat(PRN),max_sat_freq(PRN),sat_shift_ca(PRN)) ;
end

% +- 400 Hz in freq bin
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
        
    %fprintf('\t new [%15.5f] FREQ.:%5.1f\n\t old [%15.5f] FREQ.:%5.1f\n', max_bin_freq(k), fr(k), max_sat(PRN), max_sat_freq(PRN, 1)) ;
   
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
        %fprintf('\t %d => %f => %f\n', i, phase(i), phase(i)/2*pi * 180 );
        
        if(abs(phase(i))) > threshold ;
            phase(i) = phase_fix(i) - sign(phase(i))* 2 * pi ;
            %fprintf('\t\t %d => %f => %f\n', i, phase(i), phase(i)/2*pi * 180 );
            
            if(abs(phase(i))) > threshold ;
                phase(i) = phase(i) - sign(phase(i))* pi ;
                %fprintf('\t\t\t %d => %f => %f\n', i, phase(i), phase(i)/2*pi * 180 );
                
                if(abs(phase(i))) > threshold ;
                    phase(i) = phase_fix(i) - sign(phase(i))* 2 * pi ;
                    %fprintf('\t\t\t\t %d => %f => %f\n', i, phase(i), phase(i)/2*pi * 180 );
                end
            end
        end
    end

    dfrq = mean(phase)*1000 / (2*pi) ;
    max_sat_freq(PRN, 3) =  fr(k) + dfrq;
    
    fprintf('\t FREQ.:%5.1f\n', max_sat_freq(PRN, 3)) ;
    
end % for PRN=PRN_range FINE FREQ part

% ====================================================
%                      PLL/DLL
% based on Akos code
% http://sandiaproject.googlecode.com/svn/trunk/Docs/CDs/Utah%202008-09/SiGe/GNSS_SDR/tracking.m
% ====================================================

% filter constants
%       LBW           - Loop noise bandwidth
%       zeta          - Damping ratio
%       k             - Loop gain
%
%       tau1, tau2   - Loop filter coefficients 
LBW = 25 ;
zeta = 0.707 ;
k = 0.25 ;

% Solve natural frequency
Wn = LBW*8*zeta / (4*zeta.^2 + 1);

% solve for t1 & t2
tau1carr = k / (Wn * Wn);
tau2carr = 2.0 * zeta / Wn;

PDIcarr = 0.001;        % ????

%code tracking loop parameters
oldCodeNco   = 0.0;
oldCodeError = 0.0;

%carrier/Costas loop parameters
oldCarrNco   = 0.0;
oldCarrError = 0.0;

carrFreqBasis = max_sat_freq(PRN,3) ;
half_chip_size = 8 ; 

% <<< ===================================== >>>
% prepare data
data = x(sat_shift_ca(PRN): end) ;
ca16 = get_ca_code16(N/16,PRN) ;
ca16_dll = [ca16; ca16; ca16] ;
data_ms = data(1:N) ;               % FIXME - just 1 ms now

% move to baseband - check why peak also on 8000 Hz
local_sig = exp(j*2*pi * max_sat_freq(PRN,3)*ts * (0:N-1)) ;
base_band_sig = data_ms.' .* local_sig ;
I_bb = real(base_band_sig) ;
Q_bb = imag(base_band_sig) ;

% generate 6 outputs of the DLL
% FIXME - check for MAO, we have complex signal
I_E = sum(I_bb' .* ca16_dll(N - half_chip_size:2*N - 1 - half_chip_size)) ;
Q_E = sum(Q_bb' .* ca16_dll(N - half_chip_size:2*N - 1 - half_chip_size)) ;
I_P = sum(I_bb' .* ca16_dll(N:2*N - 1)) ;
Q_P = sum(Q_bb' .* ca16_dll(N:2*N - 1)) ;
I_L = sum(I_bb' .* ca16_dll(N + half_chip_size:2*N - 1 + half_chip_size)) ;
Q_L = sum(Q_bb' .* ca16_dll(N + half_chip_size:2*N - 1 + half_chip_size)) ;

% Implement carrier loop discriminator (phase detector)
carrError = atan(Q_P / I_P) / (2.0 * pi) ;

% Implement carrier loop filter and generate NCO command
carrNco = oldCarrNco + (tau2carr/tau1carr) * (carrError - oldCarrError) + carrError * (PDIcarr/tau1carr);
oldCarrNco   = carrNco;
oldCarrError = carrError;

% Modify carrier freq based on NCO command
carrFreq = carrFreqBasis + carrNco;

% DLL result
codeError = (sqrt(I_E * I_E + Q_E * Q_E) - sqrt(I_L * I_L + Q_L * Q_L)) / ...
    (sqrt(I_E * I_E + Q_E * Q_E) + sqrt(I_L * I_L + Q_L * Q_L));

% Implement code loop filter and generate NCO command
%codeNco = oldCodeNco + (tau2code/tau1code) * ...
%    (codeError - oldCodeError) + codeError * (PDIcode/tau1code);
%oldCodeNco   = codeNco;
%oldCodeError = codeError;

% Modify code freq based on NCO command
%codeFreq = settings.codeFreqBasis - codeNco;


fprintf('done \n') ;